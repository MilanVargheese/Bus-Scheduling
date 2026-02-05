"""
Generate Sample Test Data for Bus Demand Prediction
Creates a CSV file with hourly bus demand data for testing
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def generate_sample_data(
    start_date="2024-01-01",
    num_days=7,
    output_file="sample_bus_data.csv"
):
    """
    Generate synthetic bus demand data
    
    Args:
        start_date: Start date (YYYY-MM-DD)
        num_days: Number of days to generate
        output_file: Output CSV filename
    """
    # Generate hourly timestamps
    start = pd.to_datetime(start_date)
    timestamps = [start + timedelta(hours=i) for i in range(num_days * 24)]
    
    # Generate synthetic demand with patterns
    demand = []
    for ts in timestamps:
        hour = ts.hour
        day_of_week = ts.dayofweek
        
        # Base demand
        base = 50
        
        # Hour pattern (morning and evening peaks)
        if 7 <= hour <= 9:
            base += 40  # Morning peak
        elif 17 <= hour <= 19:
            base += 50  # Evening peak
        elif 0 <= hour <= 5:
            base -= 30  # Night low
        
        # Weekday vs weekend
        if day_of_week >= 5:  # Weekend
            base -= 20
        
        # Add random noise
        noise = np.random.normal(0, 10)
        value = max(10, base + noise)  # Minimum 10 passengers
        
        demand.append(round(value, 2))
    
    # Create DataFrame
    df = pd.DataFrame({
        'timestamp': timestamps,
        'demand': demand
    })
    
    # Save to CSV
    df.to_csv(output_file, index=False)
    print(f"✓ Generated {len(df)} rows of sample data")
    print(f"✓ Saved to: {output_file}")
    print(f"\nFirst few rows:")
    print(df.head(10))
    print(f"\nLast few rows:")
    print(df.tail(10))
    
    return df

if __name__ == "__main__":
    # Generate 7 days of hourly data
    generate_sample_data(
        start_date="2024-01-01",
        num_days=7,
        output_file="sample_bus_data.csv"
    )
