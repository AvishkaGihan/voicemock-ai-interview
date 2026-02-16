"""Tests for GET /tts/{request_id} route."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock

from src.api.dependencies import RequestContext


@pytest.fixture
def mock_app():
    """Create a test FastAPI app with TTS route."""
    import uuid
    from fastapi import FastAPI, Request
    from src.api.routes.tts import router

    app = FastAPI()

    @app.middleware("http")
    async def add_request_id(request: Request, call_next):
        request_id = "test-request-id-tts"  # Use fixed ID for testing
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    app.include_router(router, prefix="/tts")

    # Override the get_request_context dependency
    def override_get_request_context():
        return RequestContext(request_id="test-request-id-tts")

    from src.api.dependencies import get_request_context

    app.dependency_overrides[get_request_context] = override_get_request_context

    return app


@pytest.fixture
def client(mock_app):
    """Create test client."""
    return TestClient(mock_app)


@pytest.fixture
def mock_audio_bytes():
    """Mock audio bytes for successful cache retrieval."""
    # Simulate a small MP3 audio file (not real MP3, just bytes)
    return b"fake_mp3_audio_data_" * 100  # ~2KB of fake audio


def test_fetch_tts_audio_success(client, mock_audio_bytes, mock_app):
    """Test successful TTS audio fetch with valid request_id and token.

    AC #1, #2: Valid request_id with cached audio returns 200 with audio/mpeg.
    AC #5: Response includes X-Request-ID header.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = mock_audio_bytes

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/test-request-id", headers=headers)

    assert response.status_code == 200
    assert response.headers["content-type"] == "audio/mpeg"
    assert response.content == mock_audio_bytes
    assert "X-Request-ID" in response.headers
    assert response.headers["X-Request-ID"] == "test-request-id-tts"

    # Verify cache was queried
    mock_tts_cache.get.assert_called_once_with("test-request-id")


def test_fetch_tts_audio_not_found(client, mock_app):
    """Test 404 error when request_id is not in cache (missing/expired).

    AC #3, #4: request_id not found or expired returns 404 with
    tts_audio_not_found error code.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = None  # Simulates not found/expired

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/unknown-request-id", headers=headers)

    assert response.status_code == 404
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "tts"
    assert json_resp["error"]["code"] == "tts_audio_not_found"
    assert json_resp["error"]["message_safe"] == "TTS audio not found or has expired"
    assert json_resp["error"]["retryable"] is False
    assert json_resp["request_id"] == "test-request-id-tts"


def test_fetch_tts_audio_expired(client, mock_app):
    """Test 404 error when request_id audio has expired (TTL exceeded).

    AC #3, #7: Audio expired after TTL returns 404 with tts_audio_not_found.
    Note: TTSCache.get() returns None for both missing and expired entries.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = None  # Expired entries return None

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/expired-request-id", headers=headers)

    assert response.status_code == 404
    json_resp = response.json()
    assert json_resp["error"]["code"] == "tts_audio_not_found"
    assert json_resp["error"]["stage"] == "tts"


def test_fetch_tts_audio_missing_auth_header(client, mock_app):
    """Test 401 error when Authorization header is missing.

    AC #6: Missing token returns 401 with envelope-wrapped error.
    """
    # No Authorization header provided
    response = client.get("/tts/some-request-id")

    assert response.status_code == 401
    json_resp = response.json()
    assert json_resp["error"]["code"] == "invalid_token"
    assert json_resp["error"]["message_safe"] == "Missing authorization header"


def test_fetch_tts_audio_invalid_auth_format(client, mock_app):
    """Test 401 error when Authorization header format is invalid.

    AC #6: Invalid auth header format returns 401.
    """
    headers = {"Authorization": "InvalidFormat token_here"}
    response = client.get("/tts/some-request-id", headers=headers)

    assert response.status_code == 401
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "tts"
    assert json_resp["error"]["code"] == "invalid_token"
    assert "Invalid authorization header format" in json_resp["error"]["message_safe"]
    assert json_resp["error"]["retryable"] is False


def test_fetch_tts_audio_invalid_token(client, mock_app):
    """Test 401 error when session token is invalid or expired.

    AC #6: Invalid/expired token returns 401 with envelope error.
    """
    from src.api.dependencies.shared_services import get_token_service

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = None  # Token verification fails

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    headers = {"Authorization": "Bearer invalid_or_expired_token"}
    response = client.get("/tts/some-request-id", headers=headers)

    assert response.status_code == 401
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "tts"
    assert json_resp["error"]["code"] == "invalid_token"
    assert "Session token is invalid or expired" in json_resp["error"]["message_safe"]
    assert json_resp["error"]["retryable"] is False


def test_fetch_tts_audio_valid_token_proceeds(client, mock_audio_bytes, mock_app):
    """Test that valid token allows audio fetch to proceed.

    AC #6: Valid auth token → proceeds to fetch audio from cache.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"  # Valid token

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = mock_audio_bytes

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/valid-request-id", headers=headers)

    assert response.status_code == 200
    assert response.content == mock_audio_bytes

    # Verify token was verified and cache was accessed
    mock_token_service.verify_token.assert_called_once_with("valid_token")
    mock_tts_cache.get.assert_called_once_with("valid-request-id")


def test_fetch_tts_audio_content_type_audio_mpeg(client, mock_audio_bytes, mock_app):
    """Test that successful responses have Content-Type: audio/mpeg.

    AC #1, #7: Successful audio fetch returns audio/mpeg content type.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = mock_audio_bytes

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/test-request-id", headers=headers)

    assert response.status_code == 200
    assert response.headers["content-type"] == "audio/mpeg"


def test_fetch_tts_audio_error_responses_include_request_id(client, mock_app):
    """Test that error responses include X-Request-ID header.

    AC #5: All responses (success and error) include X-Request-ID.
    """
    from src.api.dependencies.shared_services import (
        get_token_service,
        get_tts_cache,
    )

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.get.return_value = None  # Not found

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service
    mock_app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    headers = {"Authorization": "Bearer valid_token"}
    response = client.get("/tts/missing-id", headers=headers)

    assert response.status_code == 404
    assert "X-Request-ID" in response.headers
    assert response.headers["X-Request-ID"] == "test-request-id-tts"
    json_resp = response.json()
    assert json_resp["request_id"] == "test-request-id-tts"


def test_fetch_tts_audio_401_includes_envelope_format(client, mock_app):
    """Test that 401 errors use standard envelope format.

    AC #6: 401 errors include X-Request-ID and envelope format.
    """
    from src.api.dependencies.shared_services import get_token_service

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = None

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    headers = {"Authorization": "Bearer invalid_token"}
    response = client.get("/tts/some-id", headers=headers)

    assert response.status_code == 401
    json_resp = response.json()

    # Verify envelope structure
    assert "data" in json_resp
    assert json_resp["data"] is None
    assert "error" in json_resp
    assert json_resp["error"] is not None
    assert "stage" in json_resp["error"]
    assert "code" in json_resp["error"]
    assert "message_safe" in json_resp["error"]
    assert "retryable" in json_resp["error"]
    assert "request_id" in json_resp
    assert "X-Request-ID" in response.headers
