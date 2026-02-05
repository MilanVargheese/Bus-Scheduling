"""
Structured logging helpers.
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict


def log_event(
    logger: logging.Logger,
    level: str,
    event: str,
    **fields: Dict[str, Any],
) -> None:
    """
    Emit structured JSON logs with a consistent schema.
    """
    payload = {"event": event, **fields}
    message = json.dumps(payload, default=str, ensure_ascii=False)
    level_lower = level.lower()

    if level_lower == "debug":
        logger.debug(message)
    elif level_lower == "warning":
        logger.warning(message)
    elif level_lower == "error":
        logger.error(message)
    elif level_lower == "exception":
        logger.exception(message)
    else:
        logger.info(message)
