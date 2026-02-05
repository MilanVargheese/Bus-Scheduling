"""
Scheduling API Endpoint
Consumes prediction output and returns a deterministic daily schedule.
"""
from typing import List, Optional, Any, Dict
import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.ml.scheduler import SchedulerConfig, generate_schedule
from app.utils.logging import log_event

router = APIRouter(prefix="/schedule", tags=["Scheduling"])
logger = logging.getLogger(__name__)


class QuantilePrediction(BaseModel):
    quantile: str
    values: List[float]


class PredictionPayload(BaseModel):
    predictions: List[QuantilePrediction]
    metadata: Optional[Dict[str, Any]] = None


class ScheduleRequest(BaseModel):
    prediction_output: PredictionPayload
    capacity: int = Field(..., gt=0)
    base_headway_minutes: int = Field(15, gt=0)
    standing_ratio: float = Field(0.20, ge=0.0)
    low_load_threshold: float = Field(0.50, ge=0.0)
    low_headway_multiplier: float = Field(1.50, ge=1.0)
    trip_ids: Optional[List[str]] = None
    timestamps: Optional[List[str]] = None


@router.post("", response_model=None)
async def schedule(request: ScheduleRequest):
    """
    Generate a deterministic bus schedule from prediction output.

    Input expects prediction output with quantiles (mean, p10, p50, p90, p99)
    and a bus capacity. Uses p90 for scheduling decisions.
    """
    try:
        log_event(logger, "info", "schedule_request_received")
        config = SchedulerConfig(
            base_headway_minutes=request.base_headway_minutes,
            standing_ratio=request.standing_ratio,
            low_load_threshold=request.low_load_threshold,
            low_headway_multiplier=request.low_headway_multiplier,
        )
        payload = (
            request.prediction_output.model_dump()
            if hasattr(request.prediction_output, "model_dump")
            else request.prediction_output.dict()
        )
        log_event(
            logger,
            "info",
            "schedule_generation_started",
            capacity=request.capacity,
        )
        result = generate_schedule(
            prediction_payload=payload,
            capacity=request.capacity,
            config=config,
            trip_ids=request.trip_ids,
            timestamps=request.timestamps,
        )
        log_event(
            logger,
            "info",
            "schedule_generation_complete",
            total_trips=result.get("summary", {}).get("total_trips"),
            total_buses=result.get("summary", {}).get("total_buses"),
        )
        return result
    except ValueError as e:
        log_event(logger, "warning", "schedule_validation_failed", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        log_event(logger, "exception", "schedule_failed", error=str(e))
        raise HTTPException(
            status_code=500,
            detail={"stage": "scheduling", "message": "Scheduling failed"},
        )
