"""
Inspect the scaler to understand expected features
"""
import pickle
import json
from pathlib import Path

# Load scaler
scaler_path = Path(__file__).parent / "app" / "ml" / "Assets" / "minmax_scaler.pkl"
config_path = Path(__file__).parent / "app" / "ml" / "Assets" / "feature_config.json"

with open(scaler_path, 'rb') as f:
    scaler = pickle.load(f)

with open(config_path, 'r') as f:
    config = json.load(f)

print("=" * 80)
print("Scaler Information")
print("=" * 80)
print(f"Scaler type: {type(scaler)}")
print(f"Number of features: {scaler.n_features_in_}")
print(f"Feature names: {getattr(scaler, 'feature_names_in_', 'Not available')}")
print(f"Data min: {scaler.data_min_[:5]}... (showing first 5)")
print(f"Data max: {scaler.data_max_[:5]}... (showing first 5)")

print("\n" + "=" * 80)
print("Feature Config")
print("=" * 80)
print(json.dumps(config, indent=2))

print("\n" + "=" * 80)
print("Analysis")
print("=" * 80)
print(f"Config expects: {len(config['feature_columns'])} features")
print(f"Scaler expects: {scaler.n_features_in_} features")
print(f"Match: {len(config['feature_columns']) == scaler.n_features_in_}")
