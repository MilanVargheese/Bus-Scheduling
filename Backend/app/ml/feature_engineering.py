"""
Feature Engineering Module
Handles time-series feature generation for bus demand prediction
"""
import pandas as pd
import numpy as np
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


def validate_dataframe(df, required_columns):
    """Validate input DataFrame"""
    if df is None or df.empty:
        raise ValueError("DataFrame is empty")
    
    missing_cols = set(required_columns) - set(df.columns)
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")
    
    logger.info(f"✓ DataFrame validated: {len(df)} rows, columns: {list(df.columns)}")


def clean_timestamps(df, timestamp_col="timestamp"):
    """Parse and clean timestamp column"""
    try:
        df[timestamp_col] = pd.to_datetime(df[timestamp_col], errors='coerce')
        
        # Remove invalid timestamps
        invalid_count = df[timestamp_col].isna().sum()
        if invalid_count > 0:
            logger.warning(f"⚠ Removed {invalid_count} invalid timestamps")
            df = df.dropna(subset=[timestamp_col])
        
        if df.empty:
            raise ValueError("No valid timestamps found in data")
        
        logger.info(f"✓ Timestamps cleaned: {df[timestamp_col].min()} to {df[timestamp_col].max()}")
        return df
    
    except Exception as e:
        logger.error(f"✗ Timestamp parsing failed: {e}")
        raise ValueError(f"Invalid timestamp format: {e}")


def sort_by_time(df, timestamp_col="timestamp"):
    """Sort DataFrame by timestamp"""
    df = df.sort_values(timestamp_col).reset_index(drop=True)
    logger.info("✓ Data sorted by timestamp")
    return df


def remove_duplicates(df, timestamp_col="timestamp"):
    """Remove duplicate timestamps (keep first occurrence)"""
    initial_count = len(df)
    df = df.drop_duplicates(subset=[timestamp_col], keep='first')
    removed = initial_count - len(df)
    
    if removed > 0:
        logger.warning(f"⚠ Removed {removed} duplicate timestamps")
    
    return df


def fill_missing_hours(df, timestamp_col="timestamp", demand_col="demand"):
    """Fill missing hours in time series with interpolation"""
    if df.empty:
        return df
    
    df = df.sort_values(timestamp_col).reset_index(drop=True)
    
    # Create complete hourly range
    start_time = df[timestamp_col].min()
    end_time = df[timestamp_col].max()
    
    # Round to hour
    start_time = start_time.floor('h')
    end_time = end_time.ceil('h')
    
    full_range = pd.date_range(start=start_time, end=end_time, freq='h')
    full_df = pd.DataFrame({timestamp_col: full_range})
    
    # Merge with original data
    df_complete = full_df.merge(df, on=timestamp_col, how='left')
    
    # Count missing hours
    missing_count = df_complete[demand_col].isna().sum()
    
    if missing_count > 0:
        # Interpolate missing demand values
        df_complete[demand_col] = df_complete[demand_col].interpolate(method='linear', limit_direction='both')
        
        # Fill any remaining NaNs with forward/backward fill
        df_complete[demand_col] = df_complete[demand_col].fillna(method='ffill').fillna(method='bfill')
        
        # If still NaN, fill with median
        if df_complete[demand_col].isna().any():
            median_val = df_complete[demand_col].median()
            df_complete[demand_col] = df_complete[demand_col].fillna(median_val)
        
        logger.info(f"✓ Filled {missing_count} missing hours with interpolation")
    
    logger.info(f"✓ Complete hourly series: {len(df_complete)} rows")
    return df_complete


def create_time_features(df, timestamp_col="timestamp"):
    """Generate time-based features"""
    df['hour'] = df[timestamp_col].dt.hour
    df['minute'] = df[timestamp_col].dt.minute
    df['dayofweek'] = df[timestamp_col].dt.dayofweek
    df['day'] = df[timestamp_col].dt.day
    df['month'] = df[timestamp_col].dt.month
    df['is_weekend'] = (df['dayofweek'] >= 5).astype(int)
    
    logger.info("✓ Time features created: hour, minute, dayofweek, day, month, is_weekend")
    return df


def create_lag_features(df, target_col="demand", lags=[1, 2, 3, 7, 14, 21, 30]):
    """Create lag features"""
    for lag in lags:
        df[f'lag_{lag}'] = df[target_col].shift(lag)
    
    logger.info(f"✓ Lag features created: {lags}")
    return df


def create_rolling_features(df, target_col="demand", windows=[3, 7, 14, 21, 30]):
    """Create rolling window features"""
    for window in windows:
        df[f'rolling_mean_{window}'] = df[target_col].rolling(window=window, min_periods=1).mean()
        df[f'rolling_std_{window}'] = df[target_col].rolling(window=window, min_periods=1).std()
    
    logger.info(f"✓ Rolling features created: windows={windows}")
    return df


def create_domain_features(df, timestamp_col="timestamp", target_col="demand"):
    """Create bus/pilgrimage-specific domain features"""
    # Default capacity (this should be provided in input CSV, but we'll default it)
    df['capacity'] = 50  # Default bus capacity
    
    # Peak season indicators (example: summer months and religious holidays)
    # Ramadan and Hajj periods (these are examples - adjust for your domain)
    df['is_peak_season'] = ((df[timestamp_col].dt.month.isin([6, 7, 8, 12]))).astype(int)
    
    # Days into season (cyclical)
    df['days_into_season'] = df[timestamp_col].dt.dayofyear % 90
    
    # Pilgrimage-related features (simplified)
    # These are placeholder calculations - adjust based on actual pilgrimage calendar
    df['days_since_last_pilgrimage'] = (df[timestamp_col].dt.dayofyear % 365)
    df['days_until_next_pilgrimage'] = 365 - (df[timestamp_col].dt.dayofyear % 365)
    
    logger.info("✓ Domain features created: capacity, peak season, pilgrimage indicators")
    return df


def handle_missing_values(df, strategy='drop'):
    """Handle missing values in features"""
    initial_count = len(df)
    
    if strategy == 'drop':
        df = df.dropna()
        removed = initial_count - len(df)
        if removed > 0:
            logger.info(f"✓ Removed {removed} rows with NaN values")
    elif strategy == 'fill':
        df = df.fillna(method='ffill').fillna(method='bfill').fillna(0)
        logger.info("✓ Filled NaN values")
    
    return df


def build_features(df, config=None):
    """
    Main feature engineering pipeline
    
    Args:
        df: Input DataFrame with 'timestamp' and 'demand' columns
        config: Feature configuration dict (optional)
    
    Returns:
        DataFrame with all engineered features
    """
    logger.info("=" * 60)
    logger.info("Starting feature engineering pipeline")
    logger.info("=" * 60)
    
    if config is None:
        from app.ml.loader import feature_config
        config = feature_config
    
    # Get column names from config
    timestamp_col = config.get("timestamp_column", "timestamp")
    target_col = config.get("target_column", "demand")
    required_cols = config.get("required_csv_columns", [timestamp_col, target_col])
    
    # Validation
    validate_dataframe(df, required_cols)
    
    # Clean timestamps
    df = clean_timestamps(df, timestamp_col)
    
    # Sort by time
    df = sort_by_time(df, timestamp_col)
    
    # Remove duplicates
    df = remove_duplicates(df, timestamp_col)
    
    # Fill missing hours
    df = fill_missing_hours(df, timestamp_col, target_col)
    
    # Create features
    df = create_time_features(df, timestamp_col)
    df = create_lag_features(df, target_col, lags=[1, 2, 3, 7, 14, 21, 30])
    df = create_rolling_features(df, target_col, windows=[3, 7, 14, 21, 30])
    df = create_domain_features(df, timestamp_col, target_col)
    
    # Handle NaN values from lag/rolling operations
    df = handle_missing_values(df, strategy='drop')
    
    if df.empty:
        raise ValueError("No data remaining after feature engineering")
    
    logger.info(f"✓ Feature engineering complete: {len(df)} rows, {len(df.columns)} columns")
    logger.info(f"  Columns: {list(df.columns)}")
    logger.info("=" * 60)
    
    return df
