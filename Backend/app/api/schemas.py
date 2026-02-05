"""
Shared API schemas for versioned endpoints.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class WarningMessage(BaseModel):
    code: str
    message: str


class ApiMetadata(BaseModel):
    api_version: str
    model_version: Optional[str] = None
    num_predictions: Optional[int] = None
    quantiles: Optional[List[str]] = None


class QuantileSeries(BaseModel):
    quantile: str
    values: List[float]


class ConfidenceBounds(BaseModel):
    lower_quantile: str
    upper_quantile: str
    lower: List[float]
    upper: List[float]


class PredictResponseV1(BaseModel):
    predictions: List[QuantileSeries]
    confidence_bounds: List[ConfidenceBounds]
    metadata: ApiMetadata
    warnings: List[WarningMessage] = Field(default_factory=list)


class QuantilePrediction(BaseModel):
    quantile: str
    values: List[float]


class PredictionPayload(BaseModel):
    predictions: List[QuantilePrediction]
    metadata: Optional[Dict[str, Any]] = None


class ScheduleRequestV1(BaseModel):
    prediction_output: PredictionPayload
    capacity: int = Field(..., gt=0)
    base_headway_minutes: int = Field(15, gt=0)
    standing_ratio: float = Field(0.20, ge=0.0)
    low_load_threshold: float = Field(0.50, ge=0.0)
    low_headway_multiplier: float = Field(1.50, ge=1.0)
    trip_ids: Optional[List[str]] = None
    timestamps: Optional[List[str]] = None


class ScheduleItem(BaseModel):
    trip_index: int
    trip_id: Optional[str]
    timestamp: Optional[str]
    p90_demand: float
    load_factor: float
    buses_assigned: int
    extra_buses: int
    current_buses: Optional[int] = None
    delta_buses: Optional[int] = None
    current_load_factor: Optional[float] = None
    standing_allowed: bool
    expected_standing_per_bus: float
    expected_load_per_bus: float
    expected_seated_load_factor: float
    base_headway_minutes: int
    headway_multiplier: float
    adjusted_headway_minutes: float
    rationale: List[str]


class ScheduleSummary(BaseModel):
    total_trips: int
    total_buses: int
    extra_buses_added: int
    trips_with_standing: int
    trips_low_demand: int
    avg_load_factor: float
    current_total_buses: Optional[int] = None
    delta_total_buses: Optional[int] = None
    current_avg_load_factor: Optional[float] = None
    current_overload_trips: Optional[int] = None
    optimized_overload_trips: Optional[int] = None


class ScheduleParameters(BaseModel):
    capacity: int
    base_headway_minutes: int
    standing_ratio: float
    low_load_threshold: float
    low_headway_multiplier: float


class ScheduleResponseV1(BaseModel):
    schedule: List[ScheduleItem]
    summary: ScheduleSummary
    parameters: ScheduleParameters
    rules: List[str]
    metadata: ApiMetadata
    warnings: List[WarningMessage] = Field(default_factory=list)
