"""Turn-related Pydantic models for request/response validation."""

from pydantic import BaseModel, Field

from src.api.models.envelope import ApiEnvelope


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
