"""
Deterministic scheduling module
Rule-based bus scheduling engine using quantile demand predictions.
"""
from __future__ import annotations

from dataclasses import dataclass
from math import ceil
from typing import Dict, List, Optional, Any
import logging

from app.utils.logging import log_event

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SchedulerConfig:
    """Configuration for scheduling rules."""
    base_headway_minutes: int = 15
    standing_ratio: float = 0.20
    low_load_threshold: float = 0.50
    low_headway_multiplier: float = 1.50


def _extract_quantile_values(prediction_payload: Dict[str, Any], quantile: str) -> List[float]:
    predictions = prediction_payload.get("predictions", [])
    for item in predictions:
        if item.get("quantile") == quantile:
            return list(item.get("values", []))
    raise ValueError(f"Quantile '{quantile}' not found in predictions")


def _validate_lengths(values: List[float], trip_ids: Optional[List[str]], timestamps: Optional[List[str]]):
    if trip_ids is not None and len(trip_ids) != len(values):
        raise ValueError("trip_ids length does not match predictions length")
    if timestamps is not None and len(timestamps) != len(values):
        raise ValueError("timestamps length does not match predictions length")


def _validate_current_buses(values: List[float], current_buses: Optional[List[int]]):
    if current_buses is not None and len(current_buses) != len(values):
        raise ValueError("current_buses length does not match predictions length")


def _safe_float(value: Any) -> float:
    try:
        v = float(value)
    except (TypeError, ValueError):
        return 0.0
    return max(v, 0.0)


def generate_schedule(
    prediction_payload: Dict[str, Any],
    capacity: int,
    config: Optional[SchedulerConfig] = None,
    trip_ids: Optional[List[str]] = None,
    timestamps: Optional[List[str]] = None,
    current_buses: Optional[List[int]] = None,
) -> Dict[str, Any]:
    """
    Generate a deterministic operational schedule from quantile predictions.

    Rules (deterministic):
    - Load factor = p50 / capacity
    - Moderate overload: allow standing up to (standing_ratio * capacity)
    - Severe overload: add extra buses to satisfy p50 within standing limits
    - Low demand: increase headway (never cancel a trip)
    """
    log_event(logger, "info", "schedule_engine_start", capacity=capacity)

    if capacity <= 0:
        raise ValueError("capacity must be a positive integer")

    cfg = config or SchedulerConfig()
    p50_values = _extract_quantile_values(prediction_payload, "p50")
    _validate_lengths(p50_values, trip_ids, timestamps)
    _validate_current_buses(p50_values, current_buses)

    schedule: List[Dict[str, Any]] = []
    total_buses = 0
    extra_buses = 0
    trips_with_standing = 0
    trips_low_demand = 0
    load_factors: List[float] = []
    current_load_factors: List[float] = []
    current_total_buses = 0
    current_overload_trips = 0
    optimized_overload_trips = 0

    max_capacity_per_bus = capacity * (1.0 + cfg.standing_ratio)

    for idx, raw_value in enumerate(p50_values):
        demand = _safe_float(raw_value)
        load_factor = demand / capacity
        load_factors.append(load_factor)

        if load_factor > 1.0:
            optimized_overload_trips += 1

        headway_multiplier = 1.0
        if load_factor < cfg.low_load_threshold:
            headway_multiplier = cfg.low_headway_multiplier
            trips_low_demand += 1

        standing_allowed = False
        buses_required = 1
        rationale: List[str] = [
            f"Load factor (p50/capacity) = {load_factor:.3f}",
            f"Capacity={capacity}, p50={demand:.2f}",
        ]

        if load_factor <= 1.0:
            rationale.append("Load within seated capacity: no extra buses")
        elif load_factor <= (1.0 + cfg.standing_ratio):
            standing_allowed = True
            trips_with_standing += 1
            rationale.append(
                "Moderate overload: standing passengers allowed within policy"
            )
        else:
            buses_required = max(1, ceil(demand / max_capacity_per_bus))
            standing_allowed = True
            extra_buses += (buses_required - 1)
            trips_with_standing += 1
            rationale.append(
                "Severe overload: adding extra buses to meet p90 demand"
            )

        expected_load_per_bus = demand / buses_required if buses_required else 0.0
        expected_seated_load_factor = expected_load_per_bus / capacity
        expected_standing = max(0.0, expected_load_per_bus - capacity)

        schedule_item = {
            "trip_index": idx,
            "trip_id": trip_ids[idx] if trip_ids is not None else None,
            "timestamp": timestamps[idx] if timestamps is not None else None,
            "p90_demand": round(demand, 4),
            "load_factor": round(load_factor, 4),
            "buses_assigned": buses_required,
            "extra_buses": max(0, buses_required - 1),
            "current_buses": None,
            "delta_buses": None,
            "current_load_factor": None,
            "standing_allowed": standing_allowed,
            "expected_standing_per_bus": round(expected_standing, 4),
            "expected_load_per_bus": round(expected_load_per_bus, 4),
            "expected_seated_load_factor": round(expected_seated_load_factor, 4),
            "base_headway_minutes": cfg.base_headway_minutes,
            "headway_multiplier": round(headway_multiplier, 2),
            "adjusted_headway_minutes": round(
                cfg.base_headway_minutes * headway_multiplier, 2
            ),
            "rationale": rationale,
        }

        if current_buses is not None:
            current_value = max(0, int(current_buses[idx]))
            current_total_buses += current_value
            current_lf = demand / (capacity * current_value) if current_value > 0 else 0.0
            current_load_factors.append(current_lf)
            if current_lf > 1.0:
                current_overload_trips += 1
            schedule_item["current_buses"] = current_value
            schedule_item["delta_buses"] = buses_required - current_value
            schedule_item["current_load_factor"] = round(current_lf, 4)

        total_buses += buses_required
        schedule.append(schedule_item)

    avg_load_factor = sum(load_factors) / len(load_factors) if load_factors else 0.0
    current_avg_load_factor = (
        sum(current_load_factors) / len(current_load_factors)
        if current_load_factors
        else None
    )

    result = {
        "schedule": schedule,
        "summary": {
            "total_trips": len(schedule),
            "total_buses": total_buses,
            "extra_buses_added": extra_buses,
            "trips_with_standing": trips_with_standing,
            "trips_low_demand": trips_low_demand,
            "avg_load_factor": round(avg_load_factor, 4),
            "current_total_buses": current_total_buses if current_buses is not None else None,
            "delta_total_buses": (
                total_buses - current_total_buses
                if current_buses is not None
                else None
            ),
            "current_avg_load_factor": (
                round(current_avg_load_factor, 4)
                if current_avg_load_factor is not None
                else None
            ),
            "current_overload_trips": (
                current_overload_trips if current_buses is not None else None
            ),
            "optimized_overload_trips": (
                optimized_overload_trips if current_buses is not None else None
            ),
        },
        "parameters": {
            "capacity": capacity,
            "base_headway_minutes": cfg.base_headway_minutes,
            "standing_ratio": cfg.standing_ratio,
            "low_load_threshold": cfg.low_load_threshold,
            "low_headway_multiplier": cfg.low_headway_multiplier,
        },
        "rules": [
            "Load factor = p50 / capacity",
            "Moderate overload: allow standing up to standing_ratio * capacity",
            "Severe overload: add buses until p50 fits within standing limits",
            "Low demand: increase headway, never cancel trips",
        ],
    }

    log_event(
        logger,
        "info",
        "schedule_engine_complete",
        total_trips=result["summary"]["total_trips"],
        total_buses=result["summary"]["total_buses"],
        extra_buses_added=result["summary"]["extra_buses_added"],
    )

    return result
