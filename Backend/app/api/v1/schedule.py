"""
Versioned scheduling API (v1).
"""
from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException

from app.api.schemas import ScheduleRequestV1, ScheduleResponseV1, ApiMetadata
from app.ml.scheduler import SchedulerConfig, generate_schedule
from app.utils.logging import log_event

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/v1/schedule", tags=["Scheduling", "v1"])


@router.post("", response_model=ScheduleResponseV1)
async def schedule_v1(request: ScheduleRequestV1):
    """
    Generate a deterministic bus schedule from prediction output (v1).
    Returns schedule, metadata, and warnings.
    """
    try:
        log_event(logger, "info", "schedule_v1_request_received")
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
        result = generate_schedule(
            prediction_payload=payload,
            capacity=request.capacity,
            config=config,
            trip_ids=request.trip_ids,
            timestamps=request.timestamps,
        )
        metadata = ApiMetadata(api_version="v1")
        response = ScheduleResponseV1(
            schedule=result.get("schedule", []),
            summary=result.get("summary", {}),
            parameters=result.get("parameters", {}),
            rules=result.get("rules", []),
            metadata=metadata,
            warnings=[],
        )
        log_event(logger, "info", "schedule_v1_request_completed")
        return response
    except ValueError as e:
        log_event(logger, "warning", "schedule_validation_failed", error=str(e))
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        log_event(logger, "exception", "schedule_failed", error=str(e))
        raise HTTPException(
            status_code=500,
            detail={"stage": "scheduling", "message": "Scheduling failed"},
        )
