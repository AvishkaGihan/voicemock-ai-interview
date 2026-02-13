"""Turn orchestration service.

Orchestrates the turn processing pipeline: STT → (LLM → TTS deferred).
"""

import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from src.providers.stt_deepgram import (
    DeepgramSTTProvider,
    STTError,
)
from src.settings.config import get_settings


@dataclass
class TurnResult:
    """Result of processing a turn.

    Contains the transcript, timings, and placeholders for future
    LLM and TTS integration (Stories 2.5 and 3.1).
    """

    transcript: str
    timings: dict[str, float]
    assistant_text: str | None = None  # Populated in Story 2.5
    tts_audio_url: str | None = None  # Populated in Story 3.1


class TurnProcessingError(Exception):
    """Error during turn processing with stage-aware details."""

    def __init__(
        self,
        message: str,
        message_safe: str,
        stage: str,
        code: str,
        retryable: bool,
    ):
        super().__init__(message)
        self.message_safe = message_safe
        self.stage = stage
        self.code = code
        self.retryable = retryable


def get_stt_provider() -> DeepgramSTTProvider:
    """Get STT provider instance with settings."""
    settings = get_settings()
    return DeepgramSTTProvider(
        api_key=settings.deepgram_api_key,
        timeout_seconds=settings.stt_timeout_seconds,
    )


async def process_turn(
    audio_bytes: bytes,
    mime_type: str,
    session: Any,  # SessionState type
) -> TurnResult:
    """Process a turn through the STT pipeline.

    Args:
        audio_bytes: Raw audio data to transcribe
        mime_type: MIME type of the audio
        session: Active session state (for updating turn_count and last_activity_at)

    Returns:
        TurnResult with transcript and timings

    Raises:
        TurnProcessingError: If STT or processing fails
    """
    start_time = time.perf_counter()

    try:
        # STT processing
        stt_provider = get_stt_provider()
        stt_start = time.perf_counter()
        transcript = await stt_provider.transcribe_audio(audio_bytes, mime_type)
        stt_end = time.perf_counter()

        stt_ms = (stt_end - stt_start) * 1000

        # Update session state
        session.turn_count += 1
        session.last_activity_at = datetime.now(timezone.utc)

        # Calculate total time
        end_time = time.perf_counter()
        total_ms = (end_time - start_time) * 1000

        timings = {
            "stt_ms": stt_ms,
            "total_ms": total_ms,
        }

        return TurnResult(
            transcript=transcript,
            timings=timings,
            assistant_text=None,  # Story 2.5
            tts_audio_url=None,  # Story 3.1
        )

    except STTError as e:
        # Wrap STT provider errors into TurnProcessingError
        raise TurnProcessingError(
            message=str(e),
            message_safe=e.args[0] if e.args else "Transcription failed",
            stage=e.stage,
            code=e.code,
            retryable=e.retryable,
        ) from e
