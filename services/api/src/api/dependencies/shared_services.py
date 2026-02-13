"""Shared singleton dependencies for session store and token service.

Both session and turn routes must share the SAME SessionStore and
SessionTokenService instances. This module provides the single source of
truth for those singletons so sessions created via /session/start are
visible to /turn.
"""

from src.security import SessionTokenService
from src.services import SessionStore
from src.settings.config import get_settings


_session_store: SessionStore | None = None
_token_service: SessionTokenService | None = None


def get_session_store() -> SessionStore:
    """Dependency to get the session store singleton."""
    global _session_store
    if _session_store is None:
        settings = get_settings()
        _session_store = SessionStore(ttl_minutes=settings.session_ttl_minutes)
    return _session_store


def get_token_service() -> SessionTokenService:
    """Dependency to get the token service singleton."""
    global _token_service
    if _token_service is None:
        settings = get_settings()
        _token_service = SessionTokenService(
            secret_key=settings.secret_key,
            max_age_seconds=settings.session_ttl_minutes * 60,
        )
    return _token_service
