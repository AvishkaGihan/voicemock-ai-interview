"""Standard API response envelope model.

This module defines the ApiEnvelope generic model that wraps all API responses
in a consistent format with data, error, and request_id fields.
"""

from typing import Generic, Optional, TypeVar

from pydantic import BaseModel, Field

from src.api.models.error_models import ApiError

T = TypeVar("T")


class ApiEnvelope(BaseModel, Generic[T]):
    """Standard API response envelope.

    All JSON endpoints MUST return responses in this format to ensure
    consistent client-side handling and proper error correlation via request_id.

    Attributes:
        data: The response payload (null on error)
        error: Error details if request failed (null on success)
        request_id: Unique identifier for request tracing and debugging
    """

    data: Optional[T] = Field(
        default=None,
        description="Response payload, null if error",
    )
    error: Optional[ApiError] = Field(
        default=None,
        description="Error details, null if success",
    )
    request_id: str = Field(
        ...,
        description="Unique request identifier for tracing",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "data": {"status": "ok"},
                    "error": None,
                    "request_id": "550e8400-e29b-41d4-a716-446655440000",
                }
            ]
        }
    }

    from pydantic import model_validator

    @model_validator(mode="after")
    def check_data_or_error(self) -> "ApiEnvelope":
        """Validate that either data OR error is present, but not both."""
        if self.data is not None and self.error is not None:
            # In some rare cases we might want partial data with error, but
            # for this strict envelope pattern, we enforce exclusivity.
            raise ValueError("Cannot have both 'data' and 'error' populated")

        # Optionally ensure at least one is provided?
        # Actually, void success response might have data=None and error=None.
        # But usually 'data' would be {} or similar.
        # Let's keep it simple: just checking conflict.

        return self
