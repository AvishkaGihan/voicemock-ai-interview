"""Pytest configuration for API tests."""

import os
import pytest

# Set test environment variables before importing any application code
os.environ.setdefault("SECRET_KEY", "test-secret-key-do-not-use-in-production-32chars")
os.environ.setdefault("SESSION_TTL_MINUTES", "60")


@pytest.fixture
def secret_key() -> str:
    """Provide test secret key."""
    return "test-secret-key-do-not-use-in-production-32chars"


@pytest.fixture
def session_ttl_minutes() -> int:
    """Provide test session TTL."""
    return 60
