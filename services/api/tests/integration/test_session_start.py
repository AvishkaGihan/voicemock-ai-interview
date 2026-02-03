"""Integration tests for POST /session/start endpoint."""

import pytest
import uuid
from httpx import AsyncClient, ASGITransport

from src.main import app


@pytest.mark.asyncio
async def test_session_start_returns_200_with_valid_request():
    """Test that POST /session/start returns 200 with valid request."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Software Engineer",
                "interview_type": "behavioral",
                "difficulty": "medium",
                "question_count": 5,
            },
        )

        assert response.status_code == 200


@pytest.mark.asyncio
async def test_session_start_response_follows_envelope_format():
    """Test that response follows ApiEnvelope format."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Product Manager",
                "interview_type": "technical",
                "difficulty": "hard",
                "question_count": 3,
            },
        )

        data = response.json()

        # Envelope format
        assert "data" in data
        assert "error" in data
        assert "request_id" in data
        assert data["error"] is None


@pytest.mark.asyncio
async def test_session_start_response_contains_required_fields():
    """Test that response data contains session_id, session_token, opening_prompt."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Data Scientist",
                "interview_type": "behavioral",
                "difficulty": "easy",
                "question_count": 7,
            },
        )

        data = response.json()
        session_data = data["data"]

        assert "session_id" in session_data
        assert "session_token" in session_data
        assert "opening_prompt" in session_data


@pytest.mark.asyncio
async def test_session_id_is_valid_uuid_format():
    """Test that session_id is a valid UUID string."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "DevOps Engineer",
                "interview_type": "technical",
                "difficulty": "medium",
                "question_count": 5,
            },
        )

        data = response.json()
        session_id = data["data"]["session_id"]

        # Should not raise exception if valid UUID
        uuid.UUID(session_id)


@pytest.mark.asyncio
async def test_session_token_is_non_empty_string():
    """Test that session_token is a non-empty string."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Backend Developer",
                "interview_type": "behavioral",
                "difficulty": "easy",
                "question_count": 4,
            },
        )

        data = response.json()
        session_token = data["data"]["session_token"]

        assert isinstance(session_token, str)
        assert len(session_token) > 0


@pytest.mark.asyncio
async def test_opening_prompt_is_contextually_relevant():
    """Test that opening_prompt is non-empty and contains role reference."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Frontend Developer",
                "interview_type": "behavioral",
                "difficulty": "medium",
                "question_count": 5,
            },
        )

        data = response.json()
        opening_prompt = data["data"]["opening_prompt"]

        assert isinstance(opening_prompt, str)
        assert len(opening_prompt) > 0
        assert "Frontend Developer" in opening_prompt


@pytest.mark.asyncio
async def test_request_id_header_matches_body():
    """Test that X-Request-ID header matches the request_id in body."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "QA Engineer",
                "interview_type": "technical",
                "difficulty": "hard",
                "question_count": 6,
            },
        )

        data = response.json()
        request_id = data["request_id"]
        header_request_id = response.headers.get("X-Request-ID")

        assert header_request_id == request_id


@pytest.mark.asyncio
async def test_422_returned_for_missing_required_fields():
    """Test that 422 is returned when required fields are missing."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Software Engineer",
                # Missing interview_type and difficulty
            },
        )

        assert response.status_code == 422


@pytest.mark.asyncio
async def test_422_returned_for_invalid_difficulty_value():
    """Test that 422 is returned for invalid difficulty value."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "Software Engineer",
                "interview_type": "behavioral",
                "difficulty": "invalid",  # Not in ["easy", "medium", "hard"]
                "question_count": 5,
            },
        )

        assert response.status_code == 422


@pytest.mark.asyncio
async def test_422_response_follows_envelope_format():
    """Test that 422 error response follows envelope format with stage-aware error."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.post(
            "/session/start",
            json={
                "role": "",  # Empty string violates min_length=1
                "interview_type": "behavioral",
                "difficulty": "medium",
            },
        )

        assert response.status_code == 422
        data = response.json()

        # Envelope format
        assert "data" in data
        assert "error" in data
        assert "request_id" in data
        assert data["data"] is None

        # Error structure
        error = data["error"]
        assert "stage" in error
        assert "code" in error
        assert "message_safe" in error
        assert "retryable" in error
        assert error["stage"] == "unknown"
        assert error["retryable"] is False
