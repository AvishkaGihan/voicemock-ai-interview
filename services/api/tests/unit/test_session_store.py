"""Unit tests for session store."""

import pytest
from datetime import datetime, timedelta, timezone

from src.api.models.session_models import SessionStartRequest
from src.services.session_store import SessionStore


@pytest.fixture
def session_store():
    """Create a fresh session store for each test."""
    return SessionStore(ttl_minutes=60)


@pytest.fixture
def sample_request():
    """Create a sample session start request."""
    return SessionStartRequest(
        role="Software Engineer",
        interview_type="behavioral",
        difficulty="medium",
        question_count=5,
    )


def test_create_session_generates_unique_session_id(session_store, sample_request):
    """Test that create_session generates a unique session_id."""
    session1 = session_store.create_session(sample_request)
    session2 = session_store.create_session(sample_request)

    assert session1.session_id != session2.session_id
    assert len(session1.session_id) > 0
    assert len(session2.session_id) > 0


def test_get_session_returns_created_session(session_store, sample_request):
    """Test that get_session returns the session that was created."""
    created_session = session_store.create_session(sample_request)

    retrieved_session = session_store.get_session(created_session.session_id)

    assert retrieved_session is not None
    assert retrieved_session.session_id == created_session.session_id
    assert retrieved_session.role == sample_request.role
    assert retrieved_session.interview_type == sample_request.interview_type
    assert retrieved_session.difficulty == sample_request.difficulty
    assert retrieved_session.question_count == sample_request.question_count


def test_get_session_returns_none_for_unknown_session_id(session_store):
    """Test that get_session returns None for a non-existent session_id."""
    result = session_store.get_session("non-existent-id-12345")

    assert result is None


def test_update_session_updates_last_activity_at(session_store, sample_request):
    """Test that update_session automatically updates last_activity_at."""
    session = session_store.create_session(sample_request)
    original_last_activity = session.last_activity_at

    # Small delay to ensure timestamp difference
    import time

    time.sleep(0.1)

    # Update with turn_count
    updated_session = session_store.update_session(session.session_id, turn_count=1)

    assert updated_session is not None
    assert updated_session.turn_count == 1
    assert updated_session.last_activity_at > original_last_activity


def test_update_session_modifies_fields(session_store, sample_request):
    """Test that update_session can modify session fields."""
    session = session_store.create_session(sample_request)

    updated = session_store.update_session(
        session.session_id,
        status="completed",
        turn_count=5,
        asked_questions=["Q1", "Q2", "Q3"],
    )

    assert updated is not None
    assert updated.status == "completed"
    assert updated.turn_count == 5
    assert updated.asked_questions == ["Q1", "Q2", "Q3"]


def test_update_session_returns_none_for_unknown_id(session_store):
    """Test that update_session returns None for non-existent session."""
    result = session_store.update_session("non-existent-id", turn_count=1)

    assert result is None


def test_delete_session_removes_session(session_store, sample_request):
    """Test that delete_session removes the session."""
    session = session_store.create_session(sample_request)

    # Delete the session
    deleted = session_store.delete_session(session.session_id)
    assert deleted is True

    # Verify it's gone
    result = session_store.get_session(session.session_id)
    assert result is None


def test_delete_session_returns_false_for_unknown_id(session_store):
    """Test that delete_session returns False for non-existent session."""
    result = session_store.delete_session("non-existent-id")

    assert result is False


def test_cleanup_expired_sessions_removes_stale_sessions(session_store, sample_request):
    """Test that cleanup_expired_sessions removes sessions exceeding TTL."""
    # Create a session
    session = session_store.create_session(sample_request)

    # Manually modify last_activity_at to simulate expiry
    # (TTL is 60 minutes, so set to 61 minutes ago)
    expired_time = datetime.now(timezone.utc) - timedelta(minutes=61)
    session_store.update_session(session.session_id, last_activity_at=expired_time)

    # Run cleanup
    cleaned_count = session_store.cleanup_expired_sessions()

    assert cleaned_count == 1
    assert session_store.get_session(session.session_id) is None


def test_cleanup_expired_sessions_preserves_active_sessions(
    session_store, sample_request
):
    """Test that cleanup does not remove active sessions."""
    session = session_store.create_session(sample_request)

    # Run cleanup immediately (session is fresh)
    cleaned_count = session_store.cleanup_expired_sessions()

    assert cleaned_count == 0
    assert session_store.get_session(session.session_id) is not None
