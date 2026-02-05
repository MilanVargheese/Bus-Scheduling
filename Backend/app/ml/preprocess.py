"""
Preprocessing Module
Handles data validation, feature scaling, and sequence generation for LSTM model
"""
print("STEP 2: PREPROCESS START", flush=True)
import numpy as np
import logging
from app.ml.validators import validate_raw_input
from app.ml.feature_engineering import build_features
from app.ml.loader import get_scaler, get_feature_config

logger = logging.getLogger(__name__)


def validate_input_shape(df, config):
    """Validate that DataFrame has enough rows for sequence generation"""
    min_rows = config.get("min_rows_required", config["sequence_length"] + 7)
    
    if len(df) < min_rows:
        raise ValueError(
            f"Insufficient data: {len(df)} rows provided, "
            f"but {min_rows} rows required (sequence_length={config['sequence_length']} + lag/rolling windows)"
        )
    
    logger.info(f"✓ Input validation passed: {len(df)} rows (minimum: {min_rows})")


def validate_features(df, expected_features):
    """Validate that all expected features are present"""
    missing_features = set(expected_features) - set(df.columns)
    
    if missing_features:
        raise ValueError(f"Missing required features: {missing_features}")
    
    logger.info(f"✓ All {len(expected_features)} required features present")


def scale_features(X, scaler):
    """Apply MinMaxScaler to features"""
    try:
        X_scaled = scaler.transform(X)
        logger.info(f"✓ Features scaled: shape={X_scaled.shape}")
        return X_scaled
    except Exception as e:
        logger.error(f"✗ Scaling failed: {e}")
        raise ValueError(f"Feature scaling failed: {e}")


def create_sequences(X_scaled, sequence_length):
    """
    Create LSTM input sequences
    
    Args:
        X_scaled: Scaled feature array (rows x features)
        sequence_length: Number of timesteps per sequence
    
    Returns:
        3D numpy array (samples x timesteps x features)
    """
    sequences = []
    
    # Generate overlapping sequences
    for i in range(len(X_scaled) - sequence_length + 1):
        seq = X_scaled[i:i + sequence_length]
        sequences.append(seq)
    
    sequences = np.array(sequences)
    logger.info(f"✓ Created {len(sequences)} sequences: shape={sequences.shape}")
    
    return sequences


def preprocess_input(df):
    """
    Main preprocessing pipeline
    
    Args:
        df: Input DataFrame with 'timestamp' and 'demand' columns
    
    Returns:
        3D numpy array ready for LSTM model (samples, timesteps, features)
    """
    logger.info("=" * 60)
    logger.info("Starting preprocessing pipeline")
    logger.info("=" * 60)
    
    # Load configuration and scaler
    config = get_feature_config()
    scaler = get_scaler()
    
    sequence_length = config["sequence_length"]
    feature_columns = config["feature_columns"]
    
    # Strict raw input validation (before feature engineering)
    validate_raw_input(df, config)

    # Validate input length
    validate_input_shape(df, config)
    
    # Build features
    features_df = build_features(df, config)
    
    # Validate features
    validate_features(features_df, feature_columns)
    
    # Extract feature columns in correct order
    X = features_df[feature_columns].values
    logger.info(f"✓ Extracted features: shape={X.shape}")

    # Prepare categorical sequence input (day of week)
    day_of_week_values = features_df["dayofweek"].astype(int).values
    
    # Check for NaN or Inf
    if np.isnan(X).any() or np.isinf(X).any():
        nan_count = np.isnan(X).sum()
        inf_count = np.isinf(X).sum()
        raise ValueError(f"Invalid values detected: {nan_count} NaN, {inf_count} Inf")
    
    # Scale features
    X_scaled = scale_features(X, scaler)

    # Append unscaled categorical numeric features expected by the model
    extra_numeric = features_df[["dayofweek", "is_weekend"]].values
    X_scaled = np.concatenate([X_scaled, extra_numeric], axis=1)
    logger.info(f"✓ Appended categorical numeric features: shape={X_scaled.shape}")
    
    # Create sequences
    sequences = create_sequences(X_scaled, sequence_length)
    day_of_week_sequences = create_sequences(
        day_of_week_values.reshape(-1, 1),
        sequence_length,
    ).squeeze(-1)
    
    if len(sequences) == 0:
        raise ValueError(
            f"No sequences generated. Need at least {sequence_length} rows after feature engineering."
        )
    
    # Build model inputs
    zeros = np.zeros(day_of_week_sequences.shape, dtype=np.int32)
    model_inputs = {
        "destination_input": zeros,
        "bus_type_input": zeros,
        "day_of_week_input": day_of_week_sequences.astype(np.int32),
        "numeric_input": sequences,
    }

    logger.info("✓ Preprocessing complete: model inputs prepared")
    logger.info(f"  - Samples: {sequences.shape[0]}")
    logger.info(f"  - Timesteps: {sequences.shape[1]}")
    logger.info(f"  - Numeric features: {sequences.shape[2]}")
    logger.info(f"  - Day-of-week input shape: {day_of_week_sequences.shape}")
    logger.info("=" * 60)

    return model_inputs
