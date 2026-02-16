"""Tests for POST /turn route."""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
from datetime import datetime, timezone

from src.api.dependencies import RequestContext
from src.services.orchestrator import TurnResult, TurnProcessingError


@pytest.fixture
def mock_app():
    """Create a test FastAPI app with turn route."""
    from fastapi import FastAPI
    from src.api.routes.turn import router

    app = FastAPI()
    app.include_router(router, prefix="/turn")

    # Override the get_request_context dependency
    def override_get_request_context():
        return RequestContext(request_id="test-request-id")

    from src.api.dependencies import get_request_context

    app.dependency_overrides[get_request_context] = override_get_request_context

    return app


@pytest.fixture
def client(mock_app):
    """Create test client."""
    return TestClient(mock_app)


@pytest.fixture
def mock_session():
    """Mock session state."""
    session = Mock()
    session.session_id = "test-session-123"
    session.turn_count = 0
    session.last_activity_at = datetime.now(timezone.utc)
    session.role = "candidate"
    session.interview_type = "technical"
    session.difficulty = "medium"
    session.asked_questions = []
    session.question_count = 5
    session.status = "active"
    return session


@pytest.fixture
def mock_turn_result():
    """Mock turn result from orchestrator."""
    return TurnResult(
        transcript="I would approach this problem by breaking it down.",
        timings={"stt_ms": 820.5, "llm_ms": 150.3, "total_ms": 940.8},
        assistant_text=None,
        tts_audio_url=None,
    )


def test_submit_turn_success(client, mock_session, mock_turn_result, mock_app):
    """Test successful turn submission with multipart upload."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        return mock_turn_result

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200
        json_resp = response.json()

        assert (
            json_resp["data"]["transcript"]
            == "I would approach this problem by breaking it down."
        )
        assert json_resp["data"]["assistant_text"] is None
        assert json_resp["data"]["tts_audio_url"] is None

        # AC #1: Validate all four timing keys are present
        assert "upload_ms" in json_resp["data"]["timings"]
        assert "stt_ms" in json_resp["data"]["timings"]
        assert "llm_ms" in json_resp["data"]["timings"]
        assert "total_ms" in json_resp["data"]["timings"]

        assert json_resp["error"] is None
        assert "request_id" in json_resp

        # Verify session update called
        mock_store.update_session.assert_called_once()
        call_args = mock_store.update_session.call_args
        assert call_args[0][0] == "test-session-123"
        assert "turn_count" in call_args[1]
        assert "last_activity_at" in call_args[1]


def test_submit_turn_invalid_token(client, mock_app):
    """Test error when session token is invalid."""
    from src.api.dependencies.shared_services import get_token_service

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = None

    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
    data = {"session_id": "test-session-123"}
    headers = {"Authorization": "Bearer invalid_token"}

    response = client.post("/turn", files=files, data=data, headers=headers)

    assert (
        response.status_code == 200
    )  # Returns API envelope with error, not HTTP error
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "upload"
    assert json_resp["error"]["code"] == "invalid_token"
    assert json_resp["error"]["retryable"] is False


def test_submit_turn_session_not_found(client, mock_app):
    """Test error when session doesn't exist in store."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = None

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
    data = {"session_id": "test-session-123"}
    headers = {"Authorization": "Bearer test_token"}

    response = client.post("/turn", files=files, data=data, headers=headers)

    assert response.status_code == 200  # Returns API envelope with error
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "upload"
    assert json_resp["error"]["code"] == "session_not_found"


def test_submit_turn_empty_audio_file(client, mock_session, mock_app):
    """Test error when audio file is empty."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    files = {"audio": ("test.webm", b"", "audio/webm")}  # Empty audio
    data = {"session_id": "test-session-123"}
    headers = {"Authorization": "Bearer test_token"}

    response = client.post("/turn", files=files, data=data, headers=headers)

    assert response.status_code == 200  # Returns API envelope with error
    json_resp = response.json()
    assert json_resp["data"] is None
    assert json_resp["error"]["stage"] == "upload"
    assert json_resp["error"]["code"] == "invalid_audio"


def test_submit_turn_stt_error(client, mock_session, mock_app):
    """Test error propagation from STT provider."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn_error(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        raise TurnProcessingError(
            message="STT timeout",
            message_safe="Transcription timed out. Please try again.",
            stage="stt",
            code="stt_timeout",
            retryable=True,
        )

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn_error):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200  # Returns API envelope with error
        json_resp = response.json()
        assert json_resp["data"] is None
        assert json_resp["error"]["stage"] == "stt"
        assert json_resp["error"]["code"] == "stt_timeout"
        assert json_resp["error"]["retryable"] is True
        assert "request_id" in json_resp


def test_submit_turn_stt_rate_limit_error(client, mock_session, mock_app):
    """Test STT rate limit error returns correct error envelope."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn_error(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        raise TurnProcessingError(
            message="Rate limit exceeded",
            message_safe="Too many requests. Please try again shortly.",
            stage="stt",
            code="stt_rate_limit",
            retryable=True,
            request_id=request_id,
        )

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn_error):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200
        json_resp = response.json()
        assert json_resp["data"] is None
        assert json_resp["error"]["stage"] == "stt"
        assert json_resp["error"]["code"] == "stt_rate_limit"
        assert json_resp["error"]["retryable"] is True
        assert json_resp["request_id"] == "test-request-id"


def test_submit_turn_llm_rate_limit_error(client, mock_session, mock_app):
    """Test LLM rate limit error returns correct error envelope."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn_error(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        raise TurnProcessingError(
            message="LLM rate limit exceeded",
            message_safe="Failed to generate follow-up question. Please try again.",
            stage="llm",
            code="llm_rate_limit",
            retryable=True,
            request_id=request_id,
        )

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn_error):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200
        json_resp = response.json()
        assert json_resp["data"] is None
        assert json_resp["error"]["stage"] == "llm"
        assert json_resp["error"]["code"] == "llm_rate_limit"
        assert json_resp["error"]["retryable"] is True
        assert json_resp["request_id"] == "test-request-id"


def test_submit_turn_llm_content_filter_error(client, mock_session, mock_app):
    """Test LLM content filter error returns correct error envelope."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn_error(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        raise TurnProcessingError(
            message="Content blocked by policy",
            message_safe="Failed to generate follow-up question. Please try again.",
            stage="llm",
            code="llm_content_filter",
            retryable=False,
            request_id=request_id,
        )

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn_error):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200
        json_resp = response.json()
        assert json_resp["data"] is None
        assert json_resp["error"]["stage"] == "llm"
        assert json_resp["error"]["code"] == "llm_content_filter"
        assert json_resp["error"]["retryable"] is False
        assert json_resp["request_id"] == "test-request-id"


def test_submit_turn_empty_transcript_error(client, mock_session, mock_app):
    """Test STT empty transcript error returns correct retryable flag."""
    from src.api.dependencies.shared_services import (
        get_session_store,
        get_token_service,
    )

    mock_store = Mock()
    mock_store.get_session.return_value = mock_session

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "test-session-123"

    async def mock_process_turn_error(
        audio_bytes,
        mime_type,
        session,
        role,
        interview_type,
        difficulty,
        asked_questions,
        question_count,
        tts_cache,
        transcript=None,
        request_id=None,
    ):
        raise TurnProcessingError(
            message="Empty transcript",
            message_safe="We couldn't hear anything. Please try again.",
            stage="stt",
            code="stt_empty_transcript",
            retryable=False,  # User should re-record
            request_id=request_id,
        )

    mock_app.dependency_overrides[get_session_store] = lambda: mock_store
    mock_app.dependency_overrides[get_token_service] = lambda: mock_token_service

    with patch("src.api.routes.turn.process_turn", new=mock_process_turn_error):
        files = {"audio": ("test.webm", b"fake_audio_data", "audio/webm")}
        data = {"session_id": "test-session-123"}
        headers = {"Authorization": "Bearer test_token"}

        response = client.post("/turn", files=files, data=data, headers=headers)

        assert response.status_code == 200
        json_resp = response.json()
        assert json_resp["data"] is None
        assert json_resp["error"]["stage"] == "stt"
        assert json_resp["error"]["code"] == "stt_empty_transcript"
        assert json_resp["error"]["retryable"] is False  # Should NOT be retryable
        assert json_resp["request_id"] == "test-request-id"
