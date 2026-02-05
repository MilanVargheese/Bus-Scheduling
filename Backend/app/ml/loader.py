"""
ML Model Loader Module
Handles loading of TensorFlow model, scalers, and configuration
"""
import os
import json
import pickle
import logging
import threading
import tempfile
import zipfile
from pathlib import Path

import keras

logger = logging.getLogger(__name__)

# Paths
BASE_DIR = Path(__file__).parent
ASSETS_DIR = BASE_DIR / "Assets"
MODEL_PATH = ASSETS_DIR / "multiscale_best_model.keras"
SCALER_PATH = ASSETS_DIR / "minmax_scaler.pkl"
LABEL_ENCODER_PATH = ASSETS_DIR / "label_encoders.pkl"
CONFIG_PATH = ASSETS_DIR / "feature_config.json"

# Global variables for lazy loading
_model = None
_scaler = None
_label_encoders = None
_feature_config = None
_load_lock = threading.Lock()


def load_feature_config():
    """Load feature configuration JSON"""
    global _feature_config
    if _feature_config is None:
        with _load_lock:
            if _feature_config is None:
                try:
                    with open(CONFIG_PATH, 'r') as f:
                        _feature_config = json.load(f)
                    logger.info(f"✓ Loaded feature config: {CONFIG_PATH}")
                    logger.info(f"  - Sequence length: {_feature_config['sequence_length']}")
                    logger.info(f"  - Features: {len(_feature_config['feature_columns'])}")
                except Exception as e:
                    logger.error(f"✗ Failed to load feature config: {e}")
                    raise
    return _feature_config


def load_scaler():
    """Load MinMaxScaler"""
    global _scaler
    if _scaler is None:
        with _load_lock:
            if _scaler is None:
                try:
                    with open(SCALER_PATH, 'rb') as f:
                        _scaler = pickle.load(f)
                    logger.info(f"✓ Loaded scaler: {SCALER_PATH}")
                except Exception as e:
                    logger.error(f"✗ Failed to load scaler: {e}")
                    raise
    return _scaler


def load_label_encoders():
    """Load label encoders (if used)"""
    global _label_encoders
    if _label_encoders is None and LABEL_ENCODER_PATH.exists():
        with _load_lock:
            if _label_encoders is None and LABEL_ENCODER_PATH.exists():
                try:
                    with open(LABEL_ENCODER_PATH, 'rb') as f:
                        _label_encoders = pickle.load(f)
                    logger.info(f"✓ Loaded label encoders: {LABEL_ENCODER_PATH}")
                except Exception as e:
                    logger.warning(f"⚠ Could not load label encoders: {e}")
                    _label_encoders = {}
    return _label_encoders


def load_model():
    """Load TensorFlow/Keras model"""
    global _model
    if _model is None:
        with _load_lock:
            if _model is None:
                try:
                    def _select_last_timestep(z):
                        return z[:, -1, :]

                    with zipfile.ZipFile(MODEL_PATH, "r") as zf:
                        model_config = json.loads(zf.read("config.json").decode("utf-8"))
                        weights_bytes = zf.read("model.weights.h5")

                    # Remove compile config to avoid custom loss deserialization
                    model_config["compile_config"] = None

                    # Replace Lambda layer code with a named function reference
                    layers = model_config.get("config", {}).get("layers", [])
                    for layer in layers:
                        if layer.get("class_name") == "Lambda":
                            layer["config"]["function"] = {
                                "module": "builtins",
                                "class_name": "function",
                                "config": "select_last_timestep",
                                "registered_name": "function",
                            }

                    _model = keras.saving.deserialize_keras_object(
                        model_config,
                        custom_objects={"select_last_timestep": _select_last_timestep},
                    )

                    temp_path = None
                    try:
                        with tempfile.NamedTemporaryFile(suffix=".weights.h5", delete=False) as tmp:
                            tmp.write(weights_bytes)
                            temp_path = tmp.name
                        keras.saving.load_weights(_model, temp_path)
                    finally:
                        if temp_path and os.path.exists(temp_path):
                            os.unlink(temp_path)

                    logger.info(f"✓ Loaded model: {MODEL_PATH}")
                    logger.info(f"  - Input shape: {_model.input_shape}")
                    logger.info(f"  - Output shape: {_model.output_shape}")
                except Exception as e:
                    logger.error(f"✗ Failed to load model: {e}")
                    raise
    return _model


def get_model():
    """Get loaded model (lazy loading)"""
    return load_model()


def get_scaler():
    """Get loaded scaler (lazy loading)"""
    return load_scaler()


def get_label_encoders():
    """Get loaded label encoders (lazy loading)"""
    return load_label_encoders()


def get_feature_config():
    """Get feature configuration (lazy loading)"""
    return load_feature_config()


logger.info("=" * 60)
logger.info("ML Assets ready (lazy loading enabled)")
logger.info("=" * 60)

# Backwards-compatible alias for test scripts
model = get_model()
