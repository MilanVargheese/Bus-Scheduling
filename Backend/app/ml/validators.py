"""
Input validation utilities for prediction pipeline.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional

import pandas as pd


@dataclass
class InputValidationError(ValueError):
    """Raised when strict input validation fails."""
    errors: List[str]

    def __str__(self) -> str:  # pragma: no cover - defensive
        return "\n".join(self.errors)


def _get_config_value(config: Dict[str, Any], key: str, default: Any) -> Any:
    value = config.get(key, default)
    return value if value is not None else default


def _validate_required_columns(df: pd.DataFrame, required_columns: Iterable[str], errors: List[str]):
    missing_cols = set(required_columns) - set(df.columns)
    if missing_cols:
        errors.append(f"Missing required columns: {sorted(missing_cols)}")


def _validate_min_rows(df: pd.DataFrame, min_rows: int, errors: List[str]):
    if len(df) < min_rows:
        errors.append(
            f"Insufficient rows: {len(df)} provided, minimum required is {min_rows}"
        )


def _validate_numeric_ranges(
    df: pd.DataFrame,
    numeric_ranges: Dict[str, Dict[str, Optional[float]]],
    errors: List[str],
):
    for column, bounds in numeric_ranges.items():
        if column not in df.columns:
            continue
        series = pd.to_numeric(df[column], errors="coerce")
        if series.isna().any():
            invalid_count = int(series.isna().sum())
            errors.append(f"Non-numeric values in '{column}': {invalid_count} rows")
            continue
        min_val = bounds.get("min", None)
        max_val = bounds.get("max", None)
        if min_val is not None and (series < min_val).any():
            errors.append(f"Values below {min_val} found in '{column}'")
        if max_val is not None and (series > max_val).any():
            errors.append(f"Values above {max_val} found in '{column}'")


def _validate_categorical_domains(
    df: pd.DataFrame,
    categorical_domains: Dict[str, List[Any]],
    errors: List[str],
):
    for column, allowed in categorical_domains.items():
        if column not in df.columns:
            continue
        invalid_values = set(df[column].dropna().unique()) - set(allowed)
        if invalid_values:
            sample = sorted(list(invalid_values))[:5]
            errors.append(
                f"Invalid categorical values in '{column}': {sample} (allowed: {allowed})"
            )


def validate_raw_input(df: pd.DataFrame, config: Dict[str, Any]) -> None:
    """
    Validate raw CSV input before preprocessing.

    Enforces:
    - required columns
    - minimum sequence length
    - numeric ranges
    - categorical domains
    """
    errors: List[str] = []

    required_columns = _get_config_value(config, "required_csv_columns", ["demand"])
    target_col = _get_config_value(config, "target_column", "demand")
    min_rows_required = _get_config_value(
        config,
        "min_rows_required",
        _get_config_value(config, "sequence_length", 24) + 7,
    )

    _validate_required_columns(df, required_columns, errors)
    _validate_min_rows(df, min_rows_required, errors)

    numeric_ranges = _get_config_value(config, "numeric_ranges", {target_col: {"min": 0.0}})
    _validate_numeric_ranges(df, numeric_ranges, errors)

    categorical_domains = _get_config_value(config, "categorical_domains", {})
    _validate_categorical_domains(df, categorical_domains, errors)

    if errors:
        raise InputValidationError(errors)
