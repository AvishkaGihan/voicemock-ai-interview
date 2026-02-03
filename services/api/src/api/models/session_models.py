"""Session-related Pydantic models for request/response validation."""

from pydantic import BaseModel, Field
from typing import Literal

from src.api.models.envelope import ApiEnvelope


class SessionStartRequest(BaseModel):
    """Request body for starting a new interview session."""

    role: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Target job role (e.g., 'Software Engineer')",
        examples=["Software Engineer", "Product Manager"],
    )
    interview_type: str = Field(
        ...,
        min_length=1,
        max_length=50,
        description="Type of interview (e.g., 'behavioral', 'technical')",
        examples=["behavioral", "technical"],
    )
    difficulty: Literal["easy", "medium", "hard"] = Field(
        ..., description="Interview difficulty level"
    )
    question_count: int = Field(
        default=5,
        ge=1,
        le=10,
        description="Number of questions to include in the session",
    )


class SessionData(BaseModel):
    """Response data for session start."""

    session_id: str = Field(..., description="Unique session identifier (UUID)")
    session_token: str = Field(
        ..., description="Bearer token for session authentication"
    )
    opening_prompt: str = Field(
        ..., description="Opening prompt text to display to the user"
    )


# Type alias for the complete session start response with envelope
SessionStartResponse = ApiEnvelope[SessionData]
