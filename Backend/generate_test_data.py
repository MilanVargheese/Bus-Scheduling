"""
Generate test CSV data for bus demand prediction
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def generate_test_csv(output_path="test_input.csv", num_hours=50):
    """
    Generate synthetic bus demand data
    
    Args:
        output_path: Path to save CSV file
        num_hours: Number of hourly records to generate (minimum 31)
    """
    if num_hours < 31:
        print(f"Warning: Generating {num_hours} rows, but 31+ recommended for proper testing")
    
    # Start time
    start_time = datetime(2024, 1, 1, 0, 0, 0)
    
    # Generate timestamps
    timestamps = [start_time + timedelta(hours=i) for i in range(num_hours)]
    
    # Generate synthetic demand data with realistic patterns
    demands = []
    for ts in timestamps:
        hour = ts.hour
        day_of_week = ts.weekday()
        
        # Base demand
        base = 100
        
        # Hour pattern (rush hours have higher demand)
        if 7 <= hour <= 9 or 17 <= hour <= 19:
            hour_factor = 1.5  # Rush hour
        elif 22 <= hour or hour <= 5:
            hour_factor = 0.3  # Night time
        else:
            hour_factor = 1.0
        
        # Weekend pattern (lower demand)
        weekend_factor = 0.7 if day_of_week >= 5 else 1.0
        
        # Add some randomness
        noise = np.random.normal(0, 10)
        
        demand = base * hour_factor * weekend_factor + noise
        demand = max(0, demand)  # Ensure non-negative
        demands.append(demand)
    
    # Create DataFrame
    df = pd.DataFrame({
        'timestamp': timestamps,
        'demand': demands
    })
    
    # Save to CSV
    df.to_csv(output_path, index=False)
    print(f"✓ Generated {len(df)} rows of test data")
    print(f"✓ Saved to: {output_path}")
    print(f"\nFirst few rows:")
    print(df.head())
    print(f"\nLast few rows:")
    print(df.tail())
    print(f"\nDemand stats:")
    print(df['demand'].describe())

if __name__ == "__main__":
    # Generate test data with enough rows (need 54+ for lag_30)
    generate_test_csv("test_input.csv", num_hours=80)
    
    # Also generate a minimal valid file
    generate_test_csv("test_input_minimal.csv", num_hours=54)
    
    # Generate a larger file for better testing
    generate_test_csv("test_input_large.csv", num_hours=168)  # 1 week
