# Bus Demand Prediction API - Backend

Production-ready FastAPI backend for bus demand forecasting using LSTM quantile regression.

## 🚀 Features

- **Robust Preprocessing Pipeline**: Automatic timestamp cleaning, missing hour filling, and feature generation
- **Comprehensive Validation**: Input validation at every stage with detailed error messages
- **Production Logging**: Full visibility into pipeline execution and errors
- **Error Handling**: Graceful error handling with informative HTTP responses
- **CORS Support**: Ready for web and mobile frontend integration
- **Quantile Predictions**: Returns mean, p10, p50, p90, p99 forecasts

## 📋 Requirements

- Python 3.13.9
- Virtual environment at `../.venv/`
- Dependencies in `requirements.txt`

## 🔧 Installation

1. Activate virtual environment:

```bash
../.venv/Scripts/activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

## 🏃 Running the Server

```bash
# From Backend directory
uvicorn app.main:app --reload
```

## Deployment-safe settings

This backend is configured for predictable memory use:

- Lazy model loading (first request triggers load).
- Single-worker inference recommended to avoid duplicate model memory.
- CPU-optimized defaults via environment variables.

Example environment variables (see .env.example):

- TF_CPP_MIN_LOG_LEVEL=2
- TF_ENABLE_ONEDNN_OPTS=0
- OMP_NUM_THREADS=1
- TF_NUM_INTRAOP_THREADS=1
- TF_NUM_INTEROP_THREADS=1

## Docker (optional)

Build:

```bash
docker build -t bus-demand-api .
```

Run:

```bash
docker run -p 8000:8000 bus-demand-api
```

The API will be available at:

- **API Base**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 📊 API Endpoints

### Health Check

```bash
GET /health
```

Returns: `{"status": "ok"}`

### Predict

```bash
POST /predict
Content-Type: multipart/form-data
Body: file=<csv_file>
```

**CSV Format Requirements:**

- Columns: `timestamp`, `demand`
- `timestamp`: Hourly datetime (e.g., "2024-01-01 00:00:00")
- `demand`: Numeric passenger count
- Minimum: 31 rows (for lag/rolling features)

**Response:**

```json
{
  "predictions": [
    {
      "quantile": "mean",
      "values": [45.2, 52.1, ...]
    },
    {
      "quantile": "p10",
      "values": [35.1, 42.3, ...]
    },
    ...
  ],
  "metadata": {
    "num_predictions": 100,
    "quantiles": ["mean", "p10", "p50", "p90", "p99"]
  }
}
```

## 🧪 Testing

### Generate Sample Data

```bash
python generate_sample_data.py
```

This creates `sample_bus_data.csv` with 7 days of hourly synthetic data.

### Test with cURL

```bash
curl -X POST "http://localhost:8000/predict" \
  -F "file=@sample_bus_data.csv"
```

### Test with Python

```python
import requests

url = "http://localhost:8000/predict"
files = {"file": open("sample_bus_data.csv", "rb")}
response = requests.post(url, files=files)
print(response.json())
```

## 🗂️ Project Structure

```
Backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI application
│   ├── api/
│   │   ├── __init__.py
│   │   ├── health.py              # Health check endpoint
│   │   └── predict.py             # Prediction endpoint
│   └── ml/
│       ├── __init__.py
│       ├── loader.py              # Model/scaler loading
│       ├── feature_engineering.py # Feature generation
│       ├── preprocess.py          # Preprocessing pipeline
│       └── Assets/
│           ├── feature_config.json
│           ├── minmax_scaler.pkl
│           ├── label_encoders.pkl
│           └── multiscale_best_model.keras
├── requirements.txt
├── generate_sample_data.py
└── README.md
```

## 🔍 Pipeline Flow

1. **Upload CSV** → Validate file type and size
2. **Parse CSV** → Load into pandas DataFrame
3. **Validate Data** → Check columns and row count
4. **Clean Timestamps** → Parse and remove invalid dates
5. **Sort & Deduplicate** → Order by time, remove duplicates
6. **Fill Missing Hours** → Interpolate gaps in time series
7. **Feature Engineering** → Generate time, lag, and rolling features
8. **Scale Features** → Apply MinMaxScaler
9. **Create Sequences** → Build LSTM input (24 timesteps)
10. **Model Inference** → Predict quantiles
11. **Format Response** → Return structured JSON

## 📝 Logging

All pipeline stages log to console with color-coded symbols:

- ✓ Success
- ⚠ Warning
- ✗ Error
- 🚀 Startup
- 📥 Request
- 🔮 Inference

## ⚙️ Configuration

Edit `app/ml/Assets/feature_config.json`:

```json
{
  "sequence_length": 24,
  "num_features": 8,
  "feature_columns": [
    "demand",
    "lag_1",
    "lag_2",
    "lag_3",
    "rolling_mean_3",
    "rolling_mean_7",
    "hour",
    "dayofweek"
  ],
  "required_csv_columns": ["timestamp", "demand"],
  "timestamp_column": "timestamp",
  "target_column": "demand",
  "min_rows_required": 31
}
```

## 🐛 Troubleshooting

### 500 Error on /predict

Check terminal logs for detailed error messages:

- Data validation errors → Check CSV format
- Preprocessing errors → Verify timestamp format
- Model errors → Check model file integrity

### Module Not Found

Ensure you're running from the `Backend` directory:

```bash
cd Backend
uvicorn app.main:app --reload
```

### Scaler Version Warning

Warnings about scikit-learn version mismatch are non-critical but can be fixed by:

```bash
pip install scikit-learn==1.6.1  # Match training version
```

## 🔒 Production Considerations

1. **CORS**: Update `allow_origins` in `main.py` with your frontend domains
2. **File Size Limits**: Adjust max file size in `predict.py` if needed
3. **Rate Limiting**: Add rate limiting middleware for production
4. **Authentication**: Implement API key or JWT authentication
5. **Monitoring**: Add application performance monitoring (APM)
6. **Logging**: Configure proper log aggregation (ELK, CloudWatch, etc.)

## 📞 Support

For issues or questions, check:

1. Terminal logs for detailed error traces
2. API documentation at `/docs`
3. Sample data generator for valid input format

---

**Version**: 1.0.0  
**Last Updated**: February 2026
