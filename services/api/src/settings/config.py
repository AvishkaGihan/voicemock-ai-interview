"""Application settings configuration.

This module provides application configuration via pydantic-settings,
allowing settings to be loaded from environment variables and .env files.
"""

from functools import lru_cache

from pydantic import Field
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
        secret_key: Secret key for session token signing (REQUIRED, no default)
        session_ttl_minutes: Session time-to-live in minutes (default: 60)
        deepgram_api_key: Deepgram API key for STT (REQUIRED at runtime for /turn)
        stt_timeout_seconds: Timeout for STT requests in seconds (default: 30)
        groq_api_key: Groq API key for LLM (REQUIRED at runtime for /turn)
        llm_model: Groq model to use (default: llama-3.3-70b-versatile)
        llm_timeout_seconds: Timeout for LLM requests in seconds (default: 30)
        llm_max_tokens: Maximum tokens for LLM response (default: 400)
        tts_timeout_seconds: Timeout for TTS requests in seconds (default: 30)
        tts_model: Deepgram Aura voice model (default: aura-2-thalia-en)
        tts_cache_ttl_seconds: TTL for cached TTS audio (default: 300 = 5 min)
    """

    app_name: str = "VoiceMock AI Interview Coach API"
    version: str = "0.1.0"
    debug: bool = False
    secret_key: str = Field(default="", min_length=1)  # REQUIRED - must be non-empty
    session_ttl_minutes: int = 60
    deepgram_api_key: str = Field(default="")  # REQUIRED at runtime for /turn endpoint
    stt_timeout_seconds: int = 30
    groq_api_key: str = Field(default="")  # REQUIRED at runtime for /turn endpoint
    llm_model: str = "llama-3.3-70b-versatile"
    llm_timeout_seconds: int = 30
    llm_max_tokens: int = 400
    tts_timeout_seconds: int = 30
    tts_model: str = "aura-2-thalia-en"
    tts_cache_ttl_seconds: int = 300

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
