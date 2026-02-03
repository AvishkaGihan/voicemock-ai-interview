"""Health check response models.

This module defines the Pydantic models for health check endpoint responses.
"""

from typing import Literal

from pydantic import BaseModel, Field

from src.api.models.envelope import ApiEnvelope


class HealthData(BaseModel):
    """Health check response data.

    Attributes:
        status: Health status indicator, always "ok" when service is healthy
    """

    status: Literal["ok"] = Field(
        default="ok",
        description="Service health status",
    )


# Type alias for health endpoint response
HealthResponse = ApiEnvelope[HealthData]
