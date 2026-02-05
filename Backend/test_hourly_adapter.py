import json

import pandas as pd

from app.ml.adapters.mongo_csv_adapter import aggregate_hourly_demand
from app.ml.preprocess import preprocess_input
from app.ml.validators import validate_raw_input

# Load raw ticket CSV (Mongo export)
df = pd.read_csv("tickets_2026-01-15.csv")

print("RAW INPUT")
print(df.head())
print("Rows:", len(df))

# Run adapter
hourly_df = aggregate_hourly_demand(
    df,
    timestamp_col="created_at",
    count_col="total",
)

print("\nAGGREGATED OUTPUT")
print(hourly_df.head(10))
print("Rows:", len(hourly_df))

# Basic sanity checks
assert "timestamp" in hourly_df.columns
assert "demand" in hourly_df.columns
assert hourly_df["timestamp"].is_monotonic_increasing
assert hourly_df["demand"].min() >= 0

print("\n✅ Hourly demand adapter working correctly")

# LEVEL 2: Verify validator passes on aggregated output
with open("app/ml/Assets/feature_config.json", encoding="utf-8") as f:
    config = json.load(f)

validate_raw_input(hourly_df, config)

print("✅ Validator accepted hourly demand data")

# LEVEL 3: Run preprocessing only (NO MODEL)
X = preprocess_input(hourly_df)

numeric_shape = X["numeric_input"].shape
day_shape = X["day_of_week_input"].shape
print("Preprocessed numeric_input shape:", numeric_shape)
print("Preprocessed day_of_week_input shape:", day_shape)
