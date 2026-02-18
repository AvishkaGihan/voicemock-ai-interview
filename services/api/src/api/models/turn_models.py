"""Turn-related Pydantic models for request/response validation."""

from __future__ import annotations

import re

from pydantic import BaseModel, Field
from pydantic import field_validator

from src.api.models.envelope import ApiEnvelope


def _word_count(text: str) -> int:
    return len(re.findall(r"\S+", text.strip()))


class CoachingDimension(BaseModel):
    """Single rubric dimension in coaching feedback."""

    label: str = Field(..., description="Rubric dimension label")
    score: int = Field(..., ge=1, le=5, description="Score from 1 to 5")
    tip: str = Field(..., description="Actionable short tip (<= 25 words)")

    @field_validator("tip")
    @classmethod
    def validate_tip_length(cls, value: str) -> str:
        if _word_count(value) > 25:
            raise ValueError("tip must be 25 words or fewer")
        return value


class CoachingFeedback(BaseModel):
    """Structured coaching feedback aligned to rubric dimensions."""

    dimensions: list[CoachingDimension] = Field(
        ..., description="List of rubric dimension scores and tips"
    )
    summary_tip: str = Field(..., description="One-sentence summary tip (<= 30 words)")

    @field_validator("summary_tip")
    @classmethod
    def validate_summary_tip_length(cls, value: str) -> str:
        if _word_count(value) > 30:
            raise ValueError("summary_tip must be 30 words or fewer")
        return value


class TurnResponseData(BaseModel):
    """Response data for a turn submission.

    Represents the result of processing a user's audio answer through
    the turn pipeline (STT → LLM → TTS).
    """

    transcript: str = Field(
        ...,
        description="Speech-to-text transcription of the user's answer",
        examples=[
            "I would approach this problem by breaking it down into smaller parts."
        ],
    )

    assistant_text: str | None = Field(
        default=None,
        description="LLM-generated follow-up question or response",
        examples=["That's a good start. Can you elaborate on your approach?"],
    )

    tts_audio_url: str | None = Field(
        default=None,
        description="URL to fetch TTS audio of assistant_text",
        examples=["/tts/550e8400-e29b-41d4-a716-446655440000"],
    )

    coaching_feedback: CoachingFeedback | None = Field(
        default=None,
        description="Structured per-turn coaching feedback aligned to rubric",
    )

    timings: dict[str, float] = Field(
        ...,
        description="Pipeline stage timings in milliseconds",
        examples=[
            {"upload_ms": 120.5, "stt_ms": 820.3, "llm_ms": 1200.0, "total_ms": 2140.8}
        ],
    )

    is_complete: bool = Field(
        default=False,
        description="Whether this was the final turn (session complete)",
        examples=[False, True],
    )

    question_number: int = Field(
        ...,
        description="Current question number (1-indexed)",
        examples=[1, 2, 3, 5],
    )

    total_questions: int = Field(
        ...,
        description="Total configured questions for the session",
        examples=[3, 5, 10],
    )


# Type alias for the complete turn response with envelope
TurnResponse = ApiEnvelope[TurnResponseData]
