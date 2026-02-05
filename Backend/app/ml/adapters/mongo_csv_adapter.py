"""
Adapter for MongoDB-exported ticketing CSVs.
Transforms raw ticket records into model-ready time-series features.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

import pandas as pd

from app.ml.feature_engineering import build_features, handle_missing_values
from app.ml.loader import get_feature_config


def _require_columns(df: pd.DataFrame, columns: list[str]) -> None:
    missing = set(columns) - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")


def _coerce_numeric(series: pd.Series, column_name: str) -> pd.Series:
    numeric = pd.to_numeric(series, errors="coerce")
    if numeric.isna().any():
        count = int(numeric.isna().sum())
        raise ValueError(f"Non-numeric values in '{column_name}': {count} rows")
    return numeric


def aggregate_hourly_tickets(
    df: pd.DataFrame,
    timestamp_col: str,
    count_col: str,
    timezone: Optional[str] = None,
) -> pd.DataFrame:
    """
    Aggregate raw ticket records to hourly counts.

    - Parses timestamps
    - Floors to hour
    - Sums counts per hour
    """
    _require_columns(df, [timestamp_col, count_col])

    timestamps = pd.to_datetime(df[timestamp_col], errors="coerce")
    if timestamps.isna().any():
        invalid = int(timestamps.isna().sum())
        raise ValueError(f"Invalid timestamps in '{timestamp_col}': {invalid} rows")

    if timezone:
        timestamps = timestamps.dt.tz_localize(timezone, ambiguous="NaT", nonexistent="NaT")
        if timestamps.isna().any():
            invalid = int(timestamps.isna().sum())
            raise ValueError(f"Ambiguous timestamps in '{timestamp_col}': {invalid} rows")
        timestamps = timestamps.dt.tz_convert(timezone)

    counts = _coerce_numeric(df[count_col], count_col)

    hourly_df = pd.DataFrame({
        timestamp_col: timestamps.dt.floor("h"),
        count_col: counts,
    })

    hourly_df = (
        hourly_df
        .groupby(timestamp_col, as_index=False)[count_col]
        .sum()
        .sort_values(timestamp_col)
        .reset_index(drop=True)
    )

    return hourly_df


def aggregate_hourly_demand(
    df: pd.DataFrame,
    config: Optional[Dict[str, Any]] = None,
    timestamp_col: Optional[str] = None,
    count_col: str = "ticket_count",
    timezone: Optional[str] = None,
) -> pd.DataFrame:
    """
    Aggregate raw ticket records into hourly demand with standard column names.

    Returns a DataFrame with columns: timestamp, demand
    """
    cfg = config or get_feature_config()
    ts_col = timestamp_col or cfg.get("timestamp_column", "timestamp")
    target_col = cfg.get("target_column", "demand")

    if ts_col not in df.columns and timestamp_col is None:
        for candidate in ("created_at", "timestamp", "date"):
            if candidate in df.columns:
                ts_col = candidate
                break

    if count_col not in df.columns:
        for candidate in ("ticket_count", "total"):
            if candidate in df.columns:
                count_col = candidate
                break

    hourly_df = aggregate_hourly_tickets(
        df=df,
        timestamp_col=ts_col,
        count_col=count_col,
        timezone=timezone,
    )

    hourly_df = hourly_df.rename(columns={count_col: target_col})
    if ts_col != "timestamp":
        hourly_df = hourly_df.rename(columns={ts_col: "timestamp"})
    return hourly_df


def mongo_csv_to_features(
    df: pd.DataFrame,
    config: Optional[Dict[str, Any]] = None,
    timestamp_col: Optional[str] = None,
    count_col: str = "ticket_count",
    timezone: Optional[str] = None,
    return_full_features: bool = False,
) -> pd.DataFrame:
    """
    Transform MongoDB-exported ticketing data into model-ready features.

    Steps:
    - Aggregate tickets per hour
    - Fill missing hours, sort chronologically
    - Generate lag/rolling features identical to training pipeline

    Returns:
    - DataFrame with feature columns (or full features if requested)
    """
    cfg = config or get_feature_config()
    ts_col = timestamp_col or cfg.get("timestamp_column", "timestamp")
    target_col = cfg.get("target_column", "demand")

    hourly_df = aggregate_hourly_tickets(
        df=df,
        timestamp_col=ts_col,
        count_col=count_col,
        timezone=timezone,
    )

    hourly_df = hourly_df.rename(columns={count_col: target_col})

    features_df = build_features(hourly_df, cfg)

    # Ensure the same NaN handling as training
    features_df = handle_missing_values(features_df, strategy="drop")

    if return_full_features:
        return features_df

    feature_columns = cfg.get("feature_columns")
    if not feature_columns:
        raise ValueError("feature_columns not found in feature_config")

    return features_df[feature_columns]
