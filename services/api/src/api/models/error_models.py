"""Stage-aware error model for API responses.

This module defines the ApiError model that follows the architecture-mandated
error object format with stage-aware error taxonomy.
"""

from typing import Optional

from pydantic import BaseModel, Field


class ApiError(BaseModel):
    """Stage-aware error model for API responses.

    All API errors must include a stage to indicate where in the pipeline
    the error occurred, enabling proper client-side error handling and
    debugging support.

    Attributes:
        stage: Pipeline stage where error occurred (upload|stt|llm|tts|unknown)
        code: Machine-readable error code for programmatic handling
        message_safe: User-safe error message suitable for display
        retryable: Whether the operation can be retried
        details: Optional additional debug information
    """

    stage: str = Field(
        ...,
        pattern=r"^(upload|stt|llm|tts|unknown)$",
        description="Pipeline stage where error occurred",
    )
    code: str = Field(
        ...,
        description="Machine-readable error code",
    )
    message_safe: str = Field(
        ...,
        description="User-safe error message",
    )
    retryable: bool = Field(
        ...,
        description="Whether operation can be retried",
    )
    details: Optional[dict] = Field(
        default=None,
        description="Additional debug info",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "stage": "upload",
                    "code": "file_too_large",
                    "message_safe": "The uploaded file exceeds the size limit",
                    "retryable": False,
                    "details": {"max_size_mb": 10},
                }
            ]
        }
    }
