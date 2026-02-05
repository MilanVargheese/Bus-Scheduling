"""
Bus Demand Prediction API
FastAPI application for real-time bus demand forecasting
"""
import os
import logging
import json

# CPU-optimized defaults (can be overridden by environment variables)
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("TF_NUM_INTRAOP_THREADS", "1")
os.environ.setdefault("TF_NUM_INTEROP_THREADS", "1")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.health import router as health_router
from app.api.predict import router as predict_router
from app.api.schedule import router as schedule_router
from app.api.v1.predict import router as predict_v1_router
from app.api.v1.schedule import router as schedule_v1_router
from app.api.v1.predict_schedule import router as predict_schedule_v1_router

# Configure logging
class JsonLogFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


handler = logging.StreamHandler()
handler.setFormatter(JsonLogFormatter())

root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)
root_logger.handlers = [handler]
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Bus Demand Prediction API",
    description="LSTM-based quantile regression for bus passenger demand forecasting",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for web/mobile frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health_router)
app.include_router(predict_router)
app.include_router(schedule_router)
app.include_router(predict_v1_router)
app.include_router(schedule_v1_router)
app.include_router(predict_schedule_v1_router)

@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    logger.info("=" * 60)
    logger.info("🚀 Bus Demand Prediction API Starting...")
    logger.info("=" * 60)
    logger.info("API Documentation: http://localhost:8000/docs")
    logger.info("=" * 60)
    try:
        from app.ml.loader import get_model, get_scaler, get_feature_config
        get_feature_config()
        get_scaler()
        get_model()
        logger.info("✓ ML assets preloaded")
    except Exception as e:
        logger.exception("ML asset preload failed", exc_info=e)

@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("=" * 60)
    logger.info("🛑 Bus Demand Prediction API Shutting Down...")
    logger.info("=" * 60)
