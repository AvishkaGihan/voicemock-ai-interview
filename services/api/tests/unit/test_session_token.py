"""Unit tests for session token service."""

import time

from src.security.session_token import SessionTokenService


def test_generate_token_returns_valid_string(secret_key):
    """Test that token generation returns a non-empty string."""
    service = SessionTokenService(secret_key=secret_key, max_age_seconds=3600)
    session_id = "test-session-id-123"

    token = service.generate_token(session_id)

    assert isinstance(token, str)
    assert len(token) > 0


def test_verify_token_returns_session_id_for_valid_token(secret_key):
    """Test that token verification returns the correct session_id for valid tokens."""
    service = SessionTokenService(secret_key=secret_key, max_age_seconds=3600)
    session_id = "test-session-id-456"

    token = service.generate_token(session_id)
    result = service.verify_token(token)

    assert result == session_id


def test_verify_token_returns_none_for_invalid_token(secret_key):
    """Test that token verification returns None for invalid tokens."""
    service = SessionTokenService(secret_key=secret_key, max_age_seconds=3600)

    # Invalid token string
    result = service.verify_token("invalid-token-string")

    assert result is None


def test_verify_token_returns_none_for_expired_token(secret_key):
    """Test that token verification returns None for expired tokens."""
    service = SessionTokenService(secret_key=secret_key, max_age_seconds=1)
    session_id = "test-session-id-789"

    token = service.generate_token(session_id)

    # Wait for token to expire (1 second + buffer)
    time.sleep(2)

    result = service.verify_token(token)

    assert result is None


def test_tokens_are_unique_per_generation(secret_key):
    """Test that each token generation produces a unique token.

    Note: itsdangerous TimestampSigner may produce identical tokens within
    the same second if the payload is identical. This is expected behavior
    as the timestamp component has 1-second granularity.
    """
    service = SessionTokenService(secret_key=secret_key, max_age_seconds=3600)
    session_id = "test-session-id-unique"

    # Generate two tokens with sufficient time delay to ensure timestamp difference
    token1 = service.generate_token(session_id)
    time.sleep(1.1)  # Wait for timestamp to change (1+ second)
    token2 = service.generate_token(session_id)

    # Tokens should be different due to timestamp
    assert token1 != token2


def test_verify_token_with_wrong_secret_key(secret_key):
    """Test that tokens signed with one key cannot be verified with another."""
    service1 = SessionTokenService(secret_key=secret_key, max_age_seconds=3600)
    service2 = SessionTokenService(
        secret_key="different-secret-key", max_age_seconds=3600
    )

    session_id = "test-session-id-secret"
    token = service1.generate_token(session_id)

    # Verification with different key should fail
    result = service2.verify_token(token)
    assert result is None
