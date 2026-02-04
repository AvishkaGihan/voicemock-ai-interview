"""Unit tests for API envelope and error models."""

import pytest
from pydantic import ValidationError


class TestApiEnvelope:
    """Tests for ApiEnvelope model."""

    def test_success_envelope_serialization(self):
        """Test ApiEnvelope serialization with success response."""
        from src.api.models.envelope import ApiEnvelope

        envelope = ApiEnvelope(
            data={"status": "ok"},
            error=None,
            request_id="test-request-id-123"
        )

        result = envelope.model_dump()

        assert result["data"] == {"status": "ok"}
        assert result["error"] is None
        assert result["request_id"] == "test-request-id-123"

    def test_error_envelope_serialization(self):
        """Test ApiEnvelope serialization with error response."""
        from src.api.models.envelope import ApiEnvelope
        from src.api.models.error_models import ApiError

        error = ApiError(
            stage="unknown",
            code="test_error",
            message_safe="A test error occurred",
            retryable=True,
            details={"key": "value"}
        )

        envelope = ApiEnvelope(
            data=None,
            error=error,
            request_id="error-request-id-456"
        )

        result = envelope.model_dump()

        assert result["data"] is None
        assert result["error"]["stage"] == "unknown"
        assert result["error"]["code"] == "test_error"
        assert result["error"]["message_safe"] == "A test error occurred"
        assert result["error"]["retryable"] is True
        assert result["error"]["details"] == {"key": "value"}
        assert result["request_id"] == "error-request-id-456"

    def test_envelope_json_uses_snake_case(self):
        """Verify JSON output uses snake_case field naming."""
        from src.api.models.envelope import ApiEnvelope

        envelope = ApiEnvelope(
            data={"test_key": "test_value"},
            error=None,
            request_id="snake-case-test-id"
        )

        json_str = envelope.model_dump_json()

        assert "request_id" in json_str
        assert "requestId" not in json_str  # Ensure no camelCase
        assert "test_key" in json_str


class TestApiError:
    """Tests for ApiError model."""

    def test_api_error_all_required_fields(self):
        """Test ApiError model with all required fields."""
        from src.api.models.error_models import ApiError

        error = ApiError(
            stage="upload",
            code="file_too_large",
            message_safe="The uploaded file is too large",
            retryable=False,
            details={"max_size": "10MB", "actual_size": "15MB"}
        )

        assert error.stage == "upload"
        assert error.code == "file_too_large"
        assert error.message_safe == "The uploaded file is too large"
        assert error.retryable is False
        assert error.details == {"max_size": "10MB", "actual_size": "15MB"}

    def test_api_error_valid_stages(self):
        """Test that ApiError only accepts valid stage values."""
        from src.api.models.error_models import ApiError

        valid_stages = ["upload", "stt", "llm", "tts", "unknown"]

        for stage in valid_stages:
            error = ApiError(
                stage=stage,
                code="test",
                message_safe="Test",
                retryable=True
            )
            assert error.stage == stage

    def test_api_error_invalid_stage_rejected(self):
        """Test that ApiError rejects invalid stage values."""
        from src.api.models.error_models import ApiError

        with pytest.raises(ValidationError):
            ApiError(
                stage="invalid_stage",
                code="test",
                message_safe="Test",
                retryable=True
            )

    def test_api_error_details_optional(self):
        """Test that details field is optional and defaults to None."""
        from src.api.models.error_models import ApiError

        error = ApiError(
            stage="llm",
            code="rate_limited",
            message_safe="Too many requests",
            retryable=True
        )

        assert error.details is None

    def test_api_error_json_uses_snake_case(self):
        """Verify ApiError JSON output uses snake_case field naming."""
        from src.api.models.error_models import ApiError

        error = ApiError(
            stage="tts",
            code="synthesis_failed",
            message_safe="Voice synthesis failed",
            retryable=True,
            details={"voice_id": "en-US-1"}
        )

        json_str = error.model_dump_json()

        assert "message_safe" in json_str
        assert "messageSafe" not in json_str  # Ensure no camelCase
        assert "voice_id" in json_str
