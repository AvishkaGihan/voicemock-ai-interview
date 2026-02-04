"""Integration tests for the health endpoint.

Tests verify that /healthz:
- Returns 200 status code
- Follows envelope format with data, error, request_id
- Returns data.status as "ok"
- Returns error as null
- Returns valid UUID request_id
- Has X-Request-ID header matching body request_id
"""

import uuid
import pytest
from httpx import AsyncClient, ASGITransport

from src.main import app


@pytest.mark.asyncio
async def test_healthz_returns_200_status_code():
    """Test that /healthz returns 200 status code."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    assert response.status_code == 200


@pytest.mark.asyncio
async def test_healthz_follows_envelope_format():
    """Test response follows envelope format with data, error, request_id."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    data = response.json()

    # Verify all three required envelope fields are present
    assert "data" in data, "Response must include 'data' field"
    assert "error" in data, "Response must include 'error' field"
    assert "request_id" in data, "Response must include 'request_id' field"


@pytest.mark.asyncio
async def test_healthz_data_status_equals_ok():
    """Test data.status equals 'ok'."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    data = response.json()

    assert data["data"] is not None, "data should not be null for success response"
    assert data["data"]["status"] == "ok", "data.status should be 'ok'"


@pytest.mark.asyncio
async def test_healthz_error_is_null():
    """Test error is null for successful response."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    data = response.json()

    assert data["error"] is None, "error should be null for success response"


@pytest.mark.asyncio
async def test_healthz_request_id_is_valid_uuid():
    """Test request_id is a valid UUID."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    data = response.json()
    request_id = data["request_id"]

    # Verify it's a valid UUID by parsing it
    try:
        parsed_uuid = uuid.UUID(request_id)
        assert str(parsed_uuid) == request_id
    except ValueError:
        pytest.fail(f"request_id '{request_id}' is not a valid UUID")


@pytest.mark.asyncio
async def test_healthz_header_matches_body_request_id():
    """Test X-Request-ID header matches body request_id."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    # Get request_id from both header and body
    header_request_id = response.headers.get("X-Request-ID")
    body_request_id = response.json()["request_id"]

    assert header_request_id is not None, "X-Request-ID header should be present"
    assert header_request_id == body_request_id, (
        f"Header X-Request-ID '{header_request_id}' should match "
        f"body request_id '{body_request_id}'"
    )


@pytest.mark.asyncio
async def test_healthz_consistent_request_id_format():
    """Test that request_id follows UUID v4 format (36 chars with hyphens)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    request_id = response.json()["request_id"]

    # UUID format: 8-4-4-4-12 = 36 characters with 4 hyphens
    assert len(request_id) == 36, f"request_id should be 36 chars, got {len(request_id)}"
    assert request_id.count("-") == 4, "request_id should have 4 hyphens (UUID format)"


@pytest.mark.asyncio
async def test_healthz_content_type_is_json():
    """Test that response Content-Type is application/json."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")

    content_type = response.headers.get("content-type", "")
    assert "application/json" in content_type, (
        f"Content-Type should be application/json, got '{content_type}'"
    )
