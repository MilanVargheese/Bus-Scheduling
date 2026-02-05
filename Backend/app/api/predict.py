"""
Prediction API Endpoint
Handles bus demand prediction requests with robust error handling
"""
from fastapi import APIRouter, UploadFile, HTTPException, File
from fastapi.responses import JSONResponse
import pandas as pd
import numpy as np
import logging
from io import StringIO
from app.ml.preprocess import preprocess_input
from app.ml.validators import InputValidationError
from app.ml.loader import get_model
from app.utils.logging import log_event

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/predict", tags=["Prediction"])


class PredictionError(Exception):
    """Custom exception for prediction errors"""
    pass


def _get_sample_count(model_inputs) -> int:
    if isinstance(model_inputs, dict):
        first = next(iter(model_inputs.values()))
        return len(first)
    if isinstance(model_inputs, (list, tuple)) and model_inputs:
        return len(model_inputs[0])
    return len(model_inputs)


def _get_numeric_shape(model_inputs):
    if isinstance(model_inputs, dict):
        numeric = model_inputs.get("numeric_input")
        return getattr(numeric, "shape", None)
    return getattr(model_inputs, "shape", None)


def validate_csv_file(file: UploadFile):
    """Validate uploaded file"""
    if not file.filename.endswith('.csv'):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only CSV files are accepted."
        )
    
    if file.size and file.size > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 10MB."
        )


def parse_csv(file_content: bytes) -> pd.DataFrame:
    """Parse CSV content into DataFrame"""
    try:
        df = pd.read_csv(StringIO(file_content.decode('utf-8')))
        
        if df.empty:
            raise ValueError("CSV file is empty")
        
        log_event(
            logger,
            "info",
            "csv_parsed",
            rows=len(df),
            columns=list(df.columns),
        )
        return df
    
    except UnicodeDecodeError:
        raise HTTPException(
            status_code=400,
            detail="Invalid file encoding. Please use UTF-8 encoding."
        )
    except pd.errors.EmptyDataError:
        raise HTTPException(
            status_code=400,
            detail="CSV file is empty or invalid."
        )
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Failed to parse CSV: {str(e)}"
        )


def format_predictions(predictions, num_samples):
    """Format model predictions into structured response"""
    try:
        # Handle different output formats
        if isinstance(predictions, list):
            # Multiple outputs (quantile regression)
            return {
                "predictions": [
                    {
                        "quantile": "mean",
                        "values": predictions[0].flatten().tolist()
                    },
                    {
                        "quantile": "p10",
                        "values": predictions[1].flatten().tolist()
                    },
                    {
                        "quantile": "p50",
                        "values": predictions[2].flatten().tolist()
                    },
                    {
                        "quantile": "p90",
                        "values": predictions[3].flatten().tolist()
                    },
                    {
                        "quantile": "p99",
                        "values": predictions[4].flatten().tolist()
                    }
                ],
                "metadata": {
                    "num_predictions": num_samples,
                    "quantiles": ["mean", "p10", "p50", "p90", "p99"]
                }
            }
        else:
            # Single output
            return {
                "predictions": [
                    {
                        "quantile": "mean",
                        "values": predictions.flatten().tolist()
                    }
                ],
                "metadata": {
                    "num_predictions": num_samples,
                    "quantiles": ["mean"]
                }
            }
    
    except Exception as e:
        log_event(logger, "exception", "format_predictions_failed", error=str(e))
        raise PredictionError(f"Failed to format predictions: {str(e)}")


@router.post("", response_model=None)
async def predict(file: UploadFile = File(...)):
    """
    Predict bus demand from uploaded CSV file
    
    Expected CSV format:
    - Columns: timestamp, demand
    - timestamp: hourly datetime values (e.g., "2024-01-01 00:00:00")
    - demand: numeric values (bus passenger count)
    - Minimum rows: 31 (for lag and rolling features)
    
    Returns:
    - predictions: List of quantile predictions (mean, p10, p50, p90, p99)
    - metadata: Prediction information
    """
    log_event(
        logger,
        "info",
        "prediction_request_received",
        filename=file.filename,
        content_type=file.content_type,
    )
    
    try:
        # 1. Validate file
        validate_csv_file(file)
        log_event(logger, "info", "file_validated", filename=file.filename)
        
        # 2. Read file content
        file_content = await file.read()
        log_event(logger, "info", "file_read", bytes=len(file_content))
        
        # 3. Parse CSV
        df = parse_csv(file_content)
        
        # 4. Preprocess data
        try:
            X = preprocess_input(df)
            sample_count = _get_sample_count(X)
            numeric_shape = _get_numeric_shape(X) or [None, None, None]
            log_event(
                logger,
                "info",
                "preprocess_complete",
                samples=sample_count,
                timesteps=numeric_shape[1] if len(numeric_shape) > 1 else None,
                features=numeric_shape[2] if len(numeric_shape) > 2 else None,
            )
        except InputValidationError as e:
            log_event(logger, "warning", "input_validation_failed", errors=e.errors)
            raise HTTPException(
                status_code=422,
                detail={"stage": "validation", "errors": e.errors}
            )
        except ValueError as e:
            log_event(logger, "warning", "preprocess_validation_failed", error=str(e))
            raise HTTPException(
                status_code=400,
                detail={"stage": "preprocess", "message": str(e)}
            )
        except Exception as e:
            log_event(logger, "exception", "preprocess_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "preprocess", "message": "Preprocessing failed"}
            )
        
        # 5. Load model
        try:
            model = get_model()
            log_event(logger, "info", "model_loaded")
        except Exception as e:
            log_event(logger, "exception", "model_load_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "model_load", "message": "Model loading failed"}
            )
        
        # 6. Make predictions
        try:
            log_event(logger, "info", "inference_started", samples=sample_count)
            predictions = model.predict(X, verbose=0)
            log_event(logger, "info", "inference_complete")
            
            # Log prediction shapes
            if isinstance(predictions, list):
                log_event(logger, "info", "inference_outputs", outputs=len(predictions))
                for i, pred in enumerate(predictions):
                    log_event(
                        logger,
                        "info",
                        "inference_output_shape",
                        output_index=i,
                        shape=getattr(pred, "shape", None),
                    )
            else:
                log_event(
                    logger,
                    "info",
                    "inference_output_shape",
                    shape=getattr(predictions, "shape", None),
                )
        
        except Exception as e:
            log_event(logger, "exception", "inference_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "inference", "message": "Model inference failed"}
            )
        
        # 7. Format response
        try:
            response = format_predictions(predictions, sample_count)
            log_event(
                logger,
                "info",
                "response_formatted",
                quantiles=len(response.get("predictions", [])),
            )
        except PredictionError as e:
            raise HTTPException(status_code=500, detail=str(e))
        
        log_event(logger, "info", "prediction_request_completed")
        
        return JSONResponse(content=response, status_code=200)
    
    except HTTPException as e:
        log_event(logger, "warning", "http_exception", status_code=e.status_code, detail=e.detail)
        raise
    
    except Exception as e:
        log_event(logger, "exception", "unexpected_error", error=str(e))
        
        raise HTTPException(
            status_code=500,
            detail={"stage": "unknown", "message": "Internal server error"}
        )
