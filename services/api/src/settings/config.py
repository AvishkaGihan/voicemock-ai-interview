"""Application settings configuration.

This module provides application configuration via pydantic-settings,
allowing settings to be loaded from environment variables and .env files.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables.

    Settings can be configured via:
    - Environment variables
    - .env file in the project root
    - Default values defined here

    Attributes:
        app_name: The application name for display/logging
        version: Current API version string
        debug: Enable debug mode (more verbose logging, etc.)
    """

    app_name: str = "VoiceMock AI Interview Coach API"
    version: str = "0.1.0"
    debug: bool = False

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


@lru_cache
def get_settings() -> Settings:
    """Get cached application settings.

    Uses lru_cache to ensure settings are only loaded once per process,
    improving performance and ensuring consistency.

    Returns:
        Settings: The application settings instance
    """
    return Settings()
