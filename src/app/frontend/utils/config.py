"""config"""
import os
from enum import Enum
from typing import Optional

from .logger import logger

DEFAULT_MAP = {
    "ENCODING": "utf-8",
    "HTTP_ATTEMPTS": "3",
    "HTTP_TIMEOUT": "6",
    "HTTP_CLIENT_EXTERNAL_TIMEOUT" : "6",
    "HTTP_CLIENT_INTERNAL_TIMEOUT" : "3",
    "MAX_RETRY_DNS_VALIDATION": "3",
}


class RequestType(Enum):
    """Simple enum class to represent the type of request that
    is possible to make against Vault"""
    LIST = "LIST"
    GET = "GET"
    SIGN = "SIGN"
    REVOKE = "REVOKE"
    LOGIN = "LOGIN"

class Config:
    """class Config"""

    def __init__(self):  # pragma: no cover
        logger.debug("[config.__init__]")

    @staticmethod
    def get_env(env_var_name: str) -> str:
        """returns the environment variable as a string"""
        logger.debug("[config.get_env]: %s used", env_var_name)
        return os.environ[env_var_name]

    @staticmethod
    def get_optional_env(env_var_name: str) -> Optional[str]:
        """returns the environment variable as a Optional[str]"""
        logger.debug("[config.get_optional_env]: %s used", env_var_name)
        return os.getenv(env_var_name)

    @staticmethod
    def get_defaulted_env(env_var_name: str) -> Optional[str]:
        """returns the environment variable as a Optional[str]"""
        logger.debug("[config.get_defaulted_env]: %s used", env_var_name)
        env = Config.get_optional_env(env_var_name)
        if not env and env_var_name in DEFAULT_MAP:
            return DEFAULT_MAP[env_var_name]
        return env