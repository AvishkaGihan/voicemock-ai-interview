"""Turn orchestration service.

Orchestrates the turn processing pipeline: STT → LLM → TTS.

Error Codes by Stage:
=====================

Upload stage:
- file_too_large: Audio file exceeds size limit (non-retryable)
- invalid_audio: Invalid audio format or empty file (non-retryable)
- upload_timeout: Upload took too long (retryable)

STT stage:
- stt_timeout: Transcription request timed out (retryable)
- stt_provider_error: STT service unavailable or server error (retryable)
- stt_empty_transcript: No speech detected in audio (non-retryable, user should re-record)
- stt_rate_limit: Too many requests to STT service (retryable)
- stt_auth_error: STT authentication failed (non-retryable)
- stt_bad_request: Invalid audio format or parameters (non-retryable)

LLM stage:
- llm_timeout: LLM request timed out (retryable)
- llm_provider_error: LLM service unavailable or server error (retryable)
- llm_rate_limit: Too many requests to LLM service (retryable)
- llm_content_filter: Response blocked by content policy (non-retryable)
- null_response: LLM returned null content (non-retryable)
- empty_response: LLM returned empty response (non-retryable)

TTS stage:
- tts_timeout: TTS request timed out (retryable)
- tts_provider_error: TTS service unavailable or server error (retryable)
- tts_rate_limit: Too many requests to TTS service (retryable)
- tts_auth_error: TTS authentication failed (non-retryable)
- tts_bad_request: Invalid text or parameters (non-retryable)
"""

import logging
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from src.providers.stt_deepgram import (
    DeepgramSTTProvider,
    STTError,
)
from src.providers.llm_groq import GroqLLMProvider, LLMError
from src.providers.tts_deepgram import (
    DeepgramTTSProvider,
    TTSError,
    TTSAuthError,
    TTSBadRequestError,
)
from src.settings.config import get_settings

logger = logging.getLogger(__name__)


@dataclass
class TurnResult:
    """Result of processing a turn.

    Contains the transcript, assistant response text, TTS audio URL,
    and timing information for each pipeline stage.
    """

    transcript: str
    timings: dict[str, float]
    assistant_text: str | None = None
    tts_audio_url: str | None = None


class TurnProcessingError(Exception):
    """Error during turn processing with stage-aware details."""

    def __init__(
        self,
        message: str,
        message_safe: str,
        stage: str,
        code: str,
        retryable: bool,
        request_id: str | None = None,
    ):
        super().__init__(message)
        self.message_safe = message_safe
        self.stage = stage
        self.code = code
        self.retryable = retryable
        self.request_id = request_id


def get_stt_provider() -> DeepgramSTTProvider:
    """Get STT provider instance with settings."""
    settings = get_settings()
    return DeepgramSTTProvider(
        api_key=settings.deepgram_api_key,
        timeout_seconds=settings.stt_timeout_seconds,
    )


def get_llm_provider() -> GroqLLMProvider:
    """Get LLM provider instance with settings."""
    settings = get_settings()
    return GroqLLMProvider(
        api_key=settings.groq_api_key,
        model=settings.llm_model,
        timeout_seconds=settings.llm_timeout_seconds,
        max_tokens=settings.llm_max_tokens,
    )


def get_tts_provider() -> DeepgramTTSProvider:
    """Get TTS provider instance with settings."""
    settings = get_settings()
    return DeepgramTTSProvider(
        api_key=settings.deepgram_api_key,
        timeout_seconds=settings.tts_timeout_seconds,
        model=settings.tts_model,
    )


async def process_turn(
    audio_bytes: bytes | None,
    mime_type: str | None,
    session: Any,  # SessionState type
    role: str,
    interview_type: str,
    difficulty: str,
    asked_questions: list[str],
    question_count: int,
    tts_cache: Any,  # TTSCache instance
    transcript: str | None = None,
    request_id: str | None = None,
) -> TurnResult:
    """Process a turn through the STT → LLM → TTS pipeline.

    Args:
        audio_bytes: Raw audio data to transcribe
        mime_type: MIME type of the audio
        session: Active session state (for updating turn_count and last_activity_at)
        role: Interview role (e.g., "Software Engineer")
        interview_type: Interview type (e.g., "Behavioral", "Technical")
        difficulty: Difficulty level (e.g., "Entry", "Mid", "Senior")
        asked_questions: List of previously asked questions (to avoid repeats)
        question_count: Total configured questions for the session
        tts_cache: TTSCache instance for storing generated audio
        transcript: Optional transcript (skips STT if provided)
        request_id: Request ID for error tracing and TTS cache key (optional)

    Returns:
        TurnResult with transcript, assistant text, TTS audio URL, and timings

    Raises:
        TurnProcessingError: If STT, LLM, or non-retryable TTS errors occur
    """
    start_time = time.perf_counter()

    try:
        if transcript:
            # Skip STT if transcript provided (retry flow)
            stt_ms = 0.0
        else:
            # STT processing
            if not audio_bytes or not mime_type:
                raise TurnProcessingError(
                    message="Audio is required when no transcript provided",
                    message_safe="Audio missing for transcription",
                    stage="upload",
                    code="invalid_audio",
                    retryable=False,
                    request_id=request_id,
                )

            stt_provider = get_stt_provider()
            stt_start = time.perf_counter()
            transcript = await stt_provider.transcribe_audio(audio_bytes, mime_type)
            stt_end = time.perf_counter()

            stt_ms = (stt_end - stt_start) * 1000

        # LLM processing
        llm_provider = get_llm_provider()
        llm_start = time.perf_counter()
        assistant_text = await llm_provider.generate_follow_up(
            transcript=transcript,
            role=role,
            interview_type=interview_type,
            difficulty=difficulty,
            asked_questions=asked_questions,
            question_number=session.turn_count + 1,  # 1-indexed
            total_questions=question_count,
        )
        llm_end = time.perf_counter()

        llm_ms = (llm_end - llm_start) * 1000

        # TTS processing (with graceful degradation)
        tts_audio_url = None
        tts_ms = 0.0

        try:
            tts_provider = get_tts_provider()
            tts_start = time.perf_counter()
            audio_bytes_result = await tts_provider.synthesize(assistant_text)
            tts_end = time.perf_counter()

            tts_ms = (tts_end - tts_start) * 1000

            # Store in cache and set URL
            if request_id:
                tts_cache.store(request_id, audio_bytes_result)
                tts_audio_url = f"/tts/{request_id}"

        except (TTSAuthError, TTSBadRequestError) as e:
            # Non-retryable TTS errors: propagate as TurnProcessingError
            raise TurnProcessingError(
                message=str(e),
                message_safe="TTS generation failed",
                stage=e.stage,
                code=e.code,
                retryable=e.retryable,
                request_id=request_id,
            ) from e

        except TTSError as e:
            # Retryable TTS errors: log and degrade gracefully
            logger.warning(
                f"TTS generation failed (retryable): {e.code} - {str(e)} "
                f"(request_id={request_id})"
            )
            # tts_audio_url remains None (graceful degradation)

        # Update session state
        session.turn_count += 1
        session.last_activity_at = datetime.now(timezone.utc)

        # Calculate total time
        end_time = time.perf_counter()
        total_ms = (end_time - start_time) * 1000

        timings = {
            "stt_ms": stt_ms,
            "llm_ms": llm_ms,
            "tts_ms": tts_ms,
            "total_ms": total_ms,
        }

        return TurnResult(
            transcript=transcript,
            timings=timings,
            assistant_text=assistant_text,
            tts_audio_url=tts_audio_url,
        )

    except STTError as e:
        # Wrap STT provider errors into TurnProcessingError
        raise TurnProcessingError(
            message=str(e),
            message_safe=e.args[0] if e.args else "Transcription failed",
            stage=e.stage,
            code=e.code,
            retryable=e.retryable,
            request_id=request_id,
        ) from e

    except LLMError as e:
        # Wrap LLM provider errors into TurnProcessingError
        raise TurnProcessingError(
            message=str(e),
            message_safe="Failed to generate follow-up question. Please try again.",
            stage=e.stage,
            code=e.code,
            retryable=e.retryable,
            request_id=request_id,
        ) from e
