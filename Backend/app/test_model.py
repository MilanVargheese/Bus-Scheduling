# app/test_model.py

import pandas as pd
from app.ml.feature_engineering import build_features

df = pd.read_csv("tickets_2026-01-15.csv")

# IMPORTANT: map correct timestamp column
df["timestamp"] = df["created_at"]

features = build_features(df)
print(features.head())
print(features.shape)
