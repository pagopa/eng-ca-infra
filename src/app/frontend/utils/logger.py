"""logger"""
import logging
import os

# initialize logger
logger = logging.getLogger()
logger.setLevel(
    logging.DEBUG if os.getenv("DEBUG") == "True" else logging.INFO
)
