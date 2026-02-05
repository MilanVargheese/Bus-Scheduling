import numpy as np
from app.ml.loader import model
from app.ml.preprocess import preprocess_input
from app.ml.adapters.mongo_csv_adapter import aggregate_hourly_demand
import pandas as pd

# Load raw ticket CSV
df = pd.read_csv("tickets_2026-01-15.csv")

# Aggregate → preprocess
hourly_df = aggregate_hourly_demand(df)
inputs = preprocess_input(hourly_df)

print("Model inputs:")
for k, v in inputs.items():
    print(k, v.shape)

# Run inference
preds = model.predict(inputs)

print("\nRaw model output:")
for i, p in enumerate(preds):
    print(f"Output[{i}] shape:", p.shape)

print("\n✅ Model inference successful")
