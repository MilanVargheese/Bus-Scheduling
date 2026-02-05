"""
Orchestration API (v1): predict + schedule.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional
import logging
import io

import pandas as pd

from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse, StreamingResponse

from app.api.predict import validate_csv_file, parse_csv, format_predictions, PredictionError
from app.api.schemas import (
    PredictResponseV1,
    WarningMessage,
    ConfidenceBounds,
    ApiMetadata,
    PredictionPayload,
    ScheduleResponseV1,
)
from app.api.v1.predict import _build_confidence_bounds
from app.ml.adapters.mongo_csv_adapter import aggregate_hourly_demand
from app.ml.preprocess import preprocess_input
from app.ml.validators import InputValidationError
from app.ml.loader import get_model, get_feature_config
from app.ml.feature_engineering import build_features
from app.ml.scheduler import SchedulerConfig, generate_schedule
from app.utils.logging import log_event

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/predict-schedule", tags=["Prediction", "Scheduling", "v1"])


def _get_sample_count(model_inputs: Any) -> int:
    if isinstance(model_inputs, dict):
        first = next(iter(model_inputs.values()))
        return len(first)
    if isinstance(model_inputs, (list, tuple)) and model_inputs:
        return len(model_inputs[0])
    return len(model_inputs)


def _extract_p50(predictions: List[Dict[str, Any]]) -> Dict[str, Any]:
    for item in predictions:
        if item.get("quantile") == "p50":
            return item
    raise ValueError("p50 quantile not found in prediction output")


@router.post("")
async def predict_schedule_v1(
    file: UploadFile = File(...),
    schedule_file: Optional[UploadFile] = File(None),
    capacity: int = 50,
    base_headway_minutes: int = 15,
    standing_ratio: float = 0.15,
    low_load_threshold: float = 0.50,
    low_headway_multiplier: float = 1.50,
    current_buses: Optional[str] = None,
    output: str = Query("json", enum=["json", "csv"]),
):
    """
    Orchestrate prediction + scheduling from uploaded CSV (v1).
    Returns prediction output and optimized schedule in one response.
    """
    log_event(logger, "info", "predict_schedule_v1_request_received", filename=file.filename)

    try:
        validate_csv_file(file)
        file_content = await file.read()
        log_event(logger, "info", "file_read", bytes=len(file_content))

        df = parse_csv(file_content)

        schedule_df: Optional[pd.DataFrame] = None
        if schedule_file is not None:
            try:
                schedule_df = pd.read_csv(schedule_file.file)
            except Exception as e:
                raise HTTPException(
                    status_code=400,
                    detail={"stage": "csv", "message": str(e)},
                )

            required_cols = {"hour", "current_buses"}
            if not required_cols.issubset(set(schedule_df.columns)):
                raise HTTPException(
                    status_code=400,
                    detail={
                        "stage": "csv",
                        "message": "schedule CSV must include columns: hour,current_buses",
                    },
                )

            schedule_df = schedule_df[list(required_cols)]
            schedule_df["hour"] = pd.to_datetime(
                schedule_df["hour"], errors="coerce"
            ).dt.floor("h")
            if schedule_df["hour"].isna().any():
                raise HTTPException(
                    status_code=400,
                    detail={
                        "stage": "csv",
                        "message": "Invalid hour values in schedule CSV",
                    },
                )
            schedule_df["current_buses"] = pd.to_numeric(
                schedule_df["current_buses"], errors="coerce"
            )
            if schedule_df["current_buses"].isna().any():
                raise HTTPException(
                    status_code=400,
                    detail={
                        "stage": "csv",
                        "message": "current_buses must be numeric",
                    },
                )
            if (schedule_df["current_buses"] < 0).any():
                raise HTTPException(
                    status_code=400,
                    detail={
                        "stage": "csv",
                        "message": "current_buses must be >= 0",
                    },
                )

        if "demand" not in df.columns:
            try:
                df = aggregate_hourly_demand(df)
                log_event(logger, "info", "adapter_aggregation_complete", rows=len(df))
            except Exception as e:
                log_event(logger, "warning", "adapter_aggregation_failed", error=str(e))
                raise HTTPException(
                    status_code=400,
                    detail={"stage": "aggregation", "message": str(e)},
                )

        try:
            X = preprocess_input(df)
            sample_count = _get_sample_count(X)
            log_event(logger, "info", "preprocess_complete", samples=sample_count)
        except InputValidationError as e:
            log_event(logger, "warning", "input_validation_failed", errors=e.errors)
            raise HTTPException(
                status_code=400,
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
            predictions_raw = model.predict(X, verbose=0)
        except Exception as e:
            log_event(logger, "exception", "inference_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "inference", "message": "Model inference failed"},
            )

        try:
            formatted = format_predictions(predictions_raw, sample_count)
        except PredictionError as e:
            raise HTTPException(status_code=500, detail=str(e))

        confidence_bounds, prediction_warnings = _build_confidence_bounds(
            formatted.get("predictions", [])
        )
        prediction_metadata = ApiMetadata(
            api_version="v1",
            num_predictions=formatted.get("metadata", {}).get("num_predictions"),
            quantiles=formatted.get("metadata", {}).get("quantiles"),
        )

        prediction_response = PredictResponseV1(
            predictions=formatted.get("predictions", []),
            confidence_bounds=confidence_bounds,
            metadata=prediction_metadata,
            warnings=prediction_warnings,
        )

        try:
            p50 = _extract_p50(formatted.get("predictions", []))
        except ValueError as e:
            log_event(logger, "warning", "p50_missing", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "format", "message": str(e)},
            )

        try:
            current_buses_list: Optional[List[int]] = None
            if current_buses:
                current_buses_list = [
                    int(value)
                    for value in current_buses.split(",")
                    if value.strip()
                ]
            elif schedule_df is not None and not schedule_df.empty:
                current_buses_list = (
                    schedule_df["current_buses"].astype(int).tolist()
                )

            timestamps: Optional[List[str]] = None
            try:
                cfg = get_feature_config()
                if schedule_df is not None and not schedule_df.empty:
                    if len(schedule_df) != sample_count:
                        raise ValueError(
                            "schedule CSV row count does not match predictions length"
                        )
                    timestamps = schedule_df["hour"].dt.strftime("%Y-%m-%d %H:%M:%S").tolist()
                else:
                    features_df = build_features(df, cfg)
                    seq_len = cfg.get("sequence_length", 1)
                    if len(features_df) >= seq_len:
                        ts_series = features_df["timestamp"].iloc[seq_len - 1 :]
                        if len(ts_series) == sample_count:
                            timestamps = ts_series.astype(str).tolist()
            except Exception:
                timestamps = None

            schedule_config = SchedulerConfig(
                base_headway_minutes=base_headway_minutes,
                standing_ratio=standing_ratio,
                low_load_threshold=low_load_threshold,
                low_headway_multiplier=low_headway_multiplier,
            )
            schedule_payload = PredictionPayload(predictions=[p50])
            result = generate_schedule(
                prediction_payload=(
                    schedule_payload.model_dump()
                    if hasattr(schedule_payload, "model_dump")
                    else schedule_payload.dict()
                ),
                capacity=capacity,
                config=schedule_config,
                trip_ids=None,
                timestamps=timestamps,
                current_buses=current_buses_list,
            )
            schedule_response = ScheduleResponseV1(
                schedule=result.get("schedule", []),
                summary=result.get("summary", {}),
                parameters=result.get("parameters", {}),
                rules=result.get("rules", []),
                metadata=ApiMetadata(api_version="v1"),
                warnings=[],
            )
        except ValueError as e:
            log_event(logger, "warning", "schedule_validation_failed", error=str(e))
            raise HTTPException(
                status_code=400,
                detail={"stage": "scheduling", "message": str(e)},
            )
        except Exception as e:
            log_event(logger, "exception", "schedule_failed", error=str(e))
            raise HTTPException(
                status_code=500,
                detail={"stage": "scheduling", "message": "Scheduling failed"},
            )

        orchestrator_metadata = {
            "api_version": "v1",
            "orchestration": "predict+schedule",
        }

        warnings: List[Dict[str, str]] = []
        refined_schedule: List[Dict[str, Any]] = []
        refined_summary: Dict[str, Any] = {}

        if schedule_df is None:
            warnings.append(
                {
                    "code": "refined_schedule_disabled",
                    "message": "Refined schedule disabled: upload schedule CSV with current_buses column",
                }
            )
        else:
            schedule_output = result.get("schedule", [])
            if len(schedule_output) != len(schedule_df):
                raise HTTPException(
                    status_code=400,
                    detail={
                        "stage": "scheduling",
                        "message": "schedule CSV row count does not match schedule output",
                    },
                )

            total_added = 0
            total_removed = 0
            peak_overload = 0
            for idx, trip in enumerate(schedule_output):
                optimized_buses = trip.get("buses_assigned", 0)
                current_value = int(schedule_df["current_buses"].iloc[idx])
                delta = int(optimized_buses) - current_value
                if delta > 0:
                    total_added += delta
                elif delta < 0:
                    total_removed += abs(delta)
                if (trip.get("load_factor") or 0) > 1.0:
                    peak_overload += 1

                refined_schedule.append(
                    {
                        "hour": schedule_df["hour"].iloc[idx].strftime("%Y-%m-%d %H:%M:%S"),
                        "current_buses": current_value,
                        "optimized_buses": optimized_buses,
                        "delta": delta,
                    }
                )

            refined_summary = {
                "total_hours": len(schedule_output),
                "total_added_buses": total_added,
                "total_removed_buses": total_removed,
                "peak_overload_hours": peak_overload,
            }

        response_payload = {
            "predictions": (
                prediction_response.model_dump()
                if hasattr(prediction_response, "model_dump")
                else prediction_response.dict()
            ),
            "schedule": (
                schedule_response.model_dump()
                if hasattr(schedule_response, "model_dump")
                else schedule_response.dict()
            ),
            "refined_schedule": refined_schedule,
            "refined_summary": refined_summary,
            "metadata": orchestrator_metadata,
            "warnings": warnings,
        }

        log_event(
            logger,
            "info",
            "predict_schedule_v1_request_completed",
            schedule_length=len(result.get("schedule", [])),
        )
        if output == "csv":
            schedule_output = result.get("schedule", [])
            if schedule_df is None or schedule_df.empty:
                schedule_df = pd.DataFrame(schedule_output)
            else:
                if len(schedule_df) != len(schedule_output):
                    raise HTTPException(
                        status_code=400,
                        detail={
                            "stage": "csv",
                            "message": "schedule CSV row count does not match schedule output",
                        },
                    )
                schedule_df["buses_assigned"] = [
                    trip.get("buses_assigned") for trip in schedule_output
                ]
                schedule_df["extra_buses"] = [
                    trip.get("extra_buses") for trip in schedule_output
                ]
                schedule_df["load_factor"] = [
                    trip.get("load_factor") for trip in schedule_output
                ]

            csv_buffer = io.StringIO()
            schedule_df.to_csv(csv_buffer, index=False)
            csv_buffer.seek(0)
            return StreamingResponse(
                csv_buffer,
                media_type="text/csv",
                headers={
                    "Content-Disposition": "attachment; filename=refined_schedule.csv"
                },
            )

        return JSONResponse(content=response_payload, status_code=200)

    except HTTPException as e:
        log_event(logger, "warning", "http_exception", status_code=e.status_code, detail=e.detail)
        raise

    except Exception as e:
        log_event(logger, "exception", "unexpected_error", error=str(e))
        raise HTTPException(
            status_code=500,
            detail={"stage": "unknown", "message": "Internal server error"},
        )
