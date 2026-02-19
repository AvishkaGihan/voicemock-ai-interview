"""Tests for DELETE /session/{session_id} route."""

from unittest.mock import Mock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.dependencies import RequestContext, get_request_context
from src.api.dependencies.shared_services import (
    get_session_store,
    get_token_service,
    get_tts_cache,
)
from src.api.routes.session import router


@pytest.fixture
def app() -> FastAPI:
    app = FastAPI()
    app.include_router(router, prefix="/session")

    def override_get_request_context() -> RequestContext:
        return RequestContext(request_id="test-request-id")

    app.dependency_overrides[get_request_context] = override_get_request_context
    return app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


def test_delete_session_success_returns_deleted_true(client: TestClient, app: FastAPI):
    mock_store = Mock()
    mock_store.delete_session.return_value = True

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "session-123"

    mock_tts_cache = Mock()
    mock_tts_cache.cleanup.return_value = 1

    mock_background_tasks = Mock()

    app.dependency_overrides[get_session_store] = lambda: mock_store
    app.dependency_overrides[get_token_service] = lambda: mock_token_service
    app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache
    # Note: We can't easily override BackgroundTasks as it's a direct parameter.
    # However, for unit testing the logic, we can inspect the response and store interaction.
    # To properly test BackgroundTasks with TestClient, we rely on FastAPI's handling.
    # But for mocking, we check if cleanup was NOT called synchronously.

    response = client.delete(
        "/session/session-123",
        headers={"Authorization": "Bearer valid-token"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["data"] == {"deleted": True}
    assert body["error"] is None
    assert body["request_id"] == "test-request-id"

    mock_store.delete_session.assert_called_once_with("session-123")
    # TestClient executes background tasks, so cleanup IS called
    mock_tts_cache.cleanup.assert_called_once()


def test_delete_session_not_found_returns_404(client: TestClient, app: FastAPI):
    mock_store = Mock()
    mock_store.delete_session.return_value = False

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "missing-session"

    mock_tts_cache = Mock()

    app.dependency_overrides[get_session_store] = lambda: mock_store
    app.dependency_overrides[get_token_service] = lambda: mock_token_service
    app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    response = client.delete(
        "/session/missing-session",
        headers={"Authorization": "Bearer valid-token"},
    )

    assert response.status_code == 404
    body = response.json()
    assert body["data"] is None
    assert body["error"]["stage"] == "unknown"
    assert body["error"]["code"] == "session_not_found"
    assert body["error"]["message_safe"] == "Session not found or already deleted."
    assert body["request_id"] == "test-request-id"


def test_delete_session_unauthorized_returns_401(client: TestClient, app: FastAPI):
    mock_store = Mock()
    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = None
    mock_tts_cache = Mock()

    app.dependency_overrides[get_session_store] = lambda: mock_store
    app.dependency_overrides[get_token_service] = lambda: mock_token_service
    app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    response = client.delete(
        "/session/session-123",
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert response.status_code == 401
    body = response.json()
    assert body["data"] is None
    assert body["error"]["code"] == "invalid_token"
    assert body["request_id"] == "test-request-id"


def test_delete_session_removes_session_data_from_store(
    client: TestClient, app: FastAPI
):
    store_data = {"session-abc": {"transcript": "hello"}}

    class StoreStub:
        def delete_session(self, session_id: str) -> bool:
            if session_id in store_data:
                del store_data[session_id]
                return True
            return False

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "session-abc"

    mock_tts_cache = Mock()
    app.dependency_overrides[get_session_store] = lambda: StoreStub()
    app.dependency_overrides[get_token_service] = lambda: mock_token_service
    app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    response = client.delete(
        "/session/session-abc",
        headers={"Authorization": "Bearer valid-token"},
    )

    assert response.status_code == 200
    assert "session-abc" not in store_data


def test_delete_session_includes_x_request_id_header():
    from src.main import create_app

    app = create_app()
    client = TestClient(app)

    mock_store = Mock()
    mock_store.delete_session.return_value = True

    mock_token_service = Mock()
    mock_token_service.verify_token.return_value = "session-123"

    mock_tts_cache = Mock()

    app.dependency_overrides[get_session_store] = lambda: mock_store
    app.dependency_overrides[get_token_service] = lambda: mock_token_service
    app.dependency_overrides[get_tts_cache] = lambda: mock_tts_cache

    response = client.delete(
        "/session/session-123",
        headers={"Authorization": "Bearer valid-token"},
    )

    assert response.headers.get("x-request-id") is not None
