"""
Versioned prediction API (v1).
"""
from __future__ import annotations

from typing import List, Dict, Any
import logging

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse

from app.api.schemas import PredictResponseV1, WarningMessage, ConfidenceBounds, ApiMetadata
from app.api.predict import validate_csv_file, parse_csv, format_predictions, PredictionError
from app.ml.preprocess import preprocess_input
from app.ml.adapters.mongo_csv_adapter import aggregate_hourly_demand
from app.ml.validators import InputValidationError
from app.ml.loader import get_model
from app.utils.logging import log_event

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/predict", tags=["Prediction", "v1"])


def _get_sample_count(model_inputs: Any) -> int:
    if isinstance(model_inputs, dict):
        first = next(iter(model_inputs.values()))
        return len(first)
    if isinstance(model_inputs, (list, tuple)) and model_inputs:
        return len(model_inputs[0])
    return len(model_inputs)


def _build_confidence_bounds(
    predictions: List[Dict[str, Any]],
) -> tuple[List[ConfidenceBounds], List[WarningMessage]]:
    quantile_map = {item.get("quantile"): item.get("values") for item in predictions}
    warnings: List[WarningMessage] = []

    lower = quantile_map.get("p10")
    upper = quantile_map.get("p90")
    if lower is None or upper is None:
        warnings.append(
            WarningMessage(
                code="missing_confidence_bounds",
                message="p10/p90 not available; confidence bounds omitted",
            )
        )
        return [], warnings

    return [
        ConfidenceBounds(
            lower_quantile="p10",
            upper_quantile="p90",
            lower=lower,
            upper=upper,
        )
    ], warnings


@router.post("", response_model=PredictResponseV1)
async def predict_v1(file: UploadFile = File(...)):
    """
    Predict bus demand from uploaded CSV file (v1).
    Returns quantiles, confidence bounds, metadata, and warnings.
    """
    log_event(logger, "info", "prediction_v1_request_received", filename=file.filename)
    print("STEP 1: FILE RECEIVED", flush=True)

    try:
        validate_csv_file(file)

        file_content = await file.read()
        log_event(logger, "info", "file_read", bytes=len(file_content))

        df = parse_csv(file_content)

        if "demand" not in df.columns:
            try:
                df = aggregate_hourly_demand(df)
                log_event(logger, "info", "adapter_aggregation_complete", rows=len(df))
            except Exception as e:
                log_event(logger, "warning", "adapter_aggregation_failed", error=str(e))
                raise HTTPException(
                    status_code=422,
                    detail={"stage": "aggregation", "message": str(e)},
                )

        try:
            X = preprocess_input(df)
            sample_count = _get_sample_count(X)
            log_event(logger, "info", "preprocess_complete", samples=sample_count)
        except InputValidationError as e:
            log_event(logger, "warning", "input_validation_failed", errors=e.errors)
            raise HTTPException(
                status_code=422,
                detail={"stage": "validation", "errors": e.errors},
            )
        except ValueError as e:
            log_event(logger, "warning", "preprocess_validation_failed", error=str(e))
            raise HTTPException(
                status_code=400,
                detail={"stage": "preprocess", "message": str(e)},
            )

        try:
            model = get_model()
        except Exception as e:
            log_event(logger, "exception", "model_load_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "model_load", "message": "Model loading failed"},
            )

        try:
            print("STEP 3: MODEL PREDICT START", flush=True)
            predictions = model.predict(X, verbose=0)
        except Exception as e:
            log_event(logger, "exception", "inference_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "inference", "message": "Model inference failed"},
            )

        try:
            formatted = format_predictions(predictions, sample_count)
        except PredictionError as e:
            raise HTTPException(status_code=500, detail=str(e))

        confidence_bounds, warnings = _build_confidence_bounds(formatted.get("predictions", []))
        metadata = ApiMetadata(
            api_version="v1",
            num_predictions=formatted.get("metadata", {}).get("num_predictions"),
            quantiles=formatted.get("metadata", {}).get("quantiles"),
        )

        response = PredictResponseV1(
            predictions=formatted.get("predictions", []),
            confidence_bounds=confidence_bounds,
            metadata=metadata,
            warnings=warnings,
        )

        log_event(logger, "info", "prediction_v1_request_completed")
        payload = response.model_dump() if hasattr(response, "model_dump") else response.dict()
        return JSONResponse(content=payload, status_code=200)

    except HTTPException as e:
        log_event(logger, "warning", "http_exception", status_code=e.status_code, detail=e.detail)
        raise

    except Exception as e:
        log_event(logger, "exception", "unexpected_error", error=str(e))
        raise HTTPException(
            status_code=500,
            detail={"stage": "unknown", "message": "Internal server error"},
        )
