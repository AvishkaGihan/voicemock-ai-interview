"""Tests for turn orchestrator service."""

import pytest
from unittest.mock import AsyncMock, patch
from dataclasses import dataclass
from datetime import datetime, timezone

from src.services.orchestrator import (
    process_turn,
    TurnProcessingError,
)
from src.providers.stt_deepgram import (
    EmptyTranscriptError,
    STTAuthError,
    STTProviderError,
    STTTimeoutError,
    STTRateLimitError,
)
from src.providers.tts_deepgram import (
    TTSAuthError,
    TTSTimeoutError,
)
from src.providers.llm_groq import LLMError, LLMResponse
from unittest.mock import Mock


@pytest.fixture
def mock_tts_cache():
    """Mock TTS cache for testing."""
    cache = Mock()
    cache.store = Mock()
    cache.get = Mock(return_value=None)
    return cache


@dataclass
class MockSessionState:
    """Mock session state for testing."""

    session_id: str
    turn_count: int
    last_activity_at: datetime


@pytest.mark.asyncio
async def test_process_turn_success(mock_tts_cache):
    """Test successful turn processing with STT."""
    # Mock STT provider
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = (
        "I would approach this by breaking it down."
    )

    # Mock session state
    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    audio_bytes = b"fake_audio"
    mime_type = "audio/webm"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Next question"

    mock_tts = AsyncMock()
    mock_tts.synthesize.return_value = b"fake_mp3_audio"

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider", return_value=mock_tts
    ):
        result = await process_turn(
            audio_bytes,
            mime_type,
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            [],
            5,
            mock_tts_cache,
        )

    assert result.transcript == "I would approach this by breaking it down."
    assert "stt_ms" in result.timings
    assert "total_ms" in result.timings
    assert result.timings["stt_ms"] >= 0
    assert result.timings["total_ms"] >= result.timings["stt_ms"]

    # Verify session state updated
    assert session.turn_count == 1

    # Verify STT was called correctly
    mock_stt.transcribe_audio.assert_called_once_with(audio_bytes, mime_type)


@pytest.mark.asyncio
async def test_process_turn_empty_transcript_error(mock_tts_cache):
    """Test turn processing with empty transcript error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = EmptyTranscriptError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=2,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"silent_audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "stt"
    assert error.code == "stt_empty_transcript"
    assert error.retryable is False  # User should re-record
    assert "couldn't hear" in error.message_safe

    # Session turn_count should NOT increment on error
    assert session.turn_count == 2


@pytest.mark.asyncio
async def test_process_turn_stt_auth_error(mock_tts_cache):
    """Test turn processing with STT authentication error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = STTAuthError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=1,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "stt"
    assert error.code == "stt_auth_error"
    assert error.retryable is False


@pytest.mark.asyncio
async def test_process_turn_stt_provider_error(mock_tts_cache):
    """Test turn processing with STT provider error (5xx)."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = STTProviderError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "stt"
    assert error.code == "stt_provider_error"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_stt_timeout_error(mock_tts_cache):
    """Test turn processing with STT timeout."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = STTTimeoutError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "stt"
    assert error.code == "stt_timeout"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_captures_timing(mock_tts_cache):
    """Test that timing measurements are captured accurately."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Next question"

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        result = await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            [],
            5,
            mock_tts_cache,
        )

    # Verify timing structure
    assert "stt_ms" in result.timings
    assert "total_ms" in result.timings
    assert isinstance(result.timings["stt_ms"], float)
    assert isinstance(result.timings["total_ms"], float)
    assert result.timings["total_ms"] >= result.timings["stt_ms"]


@pytest.mark.asyncio
async def test_process_turn_updates_session_state(mock_tts_cache):
    """Test that session state is updated correctly."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Next question"

    initial_time = datetime(2026, 2, 12, 10, 0, 0, tzinfo=timezone.utc)
    session = MockSessionState(
        session_id="test-session",
        turn_count=5,
        last_activity_at=initial_time,
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            [],
            5,
            mock_tts_cache,
        )

    # Verify turn count incremented
    assert session.turn_count == 6

    # Verify last_activity_at updated (should be after initial_time)
    assert session.last_activity_at > initial_time


@pytest.mark.asyncio
async def test_process_turn_with_llm_success(mock_tts_cache):
    """Test successful turn processing with STT and LLM integration."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "I have 5 years of Python experience."

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "What databases have you worked with?"

    session = MockSessionState(
        session_id="test-session",
        turn_count=1,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        result = await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            ["Tell me about yourself."],
            5,
            mock_tts_cache,
        )

    assert result.transcript == "I have 5 years of Python experience."
    assert result.assistant_text == "What databases have you worked with?"
    assert "stt_ms" in result.timings
    assert "llm_ms" in result.timings
    assert "total_ms" in result.timings
    assert result.timings["llm_ms"] >= 0

    # Verify LLM was called with correct parameters
    mock_llm.generate_follow_up.assert_called_once_with(
        transcript="I have 5 years of Python experience.",
        role="backend developer",
        interview_type="technical interview",
        difficulty="mid-level",
        asked_questions=["Tell me about yourself."],
        question_number=2,
        total_questions=5,
    )


from src.api.models.turn_models import CoachingFeedback, CoachingDimension

@pytest.mark.asyncio
async def test_process_turn_propagates_structured_coaching_feedback(mock_tts_cache):
    """Test coaching feedback is carried from LLMResponse into TurnResult."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "I have 5 years of Python experience."

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = LLMResponse(
        follow_up_question="What databases have you worked with?",
        coaching_feedback=CoachingFeedback(
            dimensions=[
                CoachingDimension(
                    label="Clarity",
                    score=4,
                    tip="Lead with one concise point.",
                ),
                CoachingDimension(
                    label="Relevance",
                    score=5,
                    tip="Tie examples to the role.",
                ),
                CoachingDimension(
                    label="Structure",
                    score=4,
                    tip="Use problem-action-result.",
                ),
                CoachingDimension(
                    label="Filler Words",
                    score=3,
                    tip="Pause instead of fillers.",
                ),
            ],
            summary_tip="Open with your strongest example, then support it with one metric.",
        ),
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=1,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        result = await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            ["Tell me about yourself."],
            5,
            mock_tts_cache,
        )

    assert result.assistant_text == "What databases have you worked with?"
    assert result.coaching_feedback is not None
    assert result.coaching_feedback.dimensions[0].label == "Clarity"


@pytest.mark.asyncio
async def test_process_turn_llm_timeout_error(mock_tts_cache):
    """Test turn processing with LLM timeout."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.side_effect = LLMError(
        message="LLM request timed out",
        code="llm_timeout",
        retryable=True,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "llm_timeout"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_llm_error(mock_tts_cache):
    """Test turn processing with LLM error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.side_effect = LLMError(
        message="LLM API error",
        code="llm_provider_error",
        retryable=True,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "llm_provider_error"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_llm_timing_captured(mock_tts_cache):
    """Test that LLM timing is captured accurately."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Follow-up question"

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        result = await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            [],
            5,
            mock_tts_cache,
        )

    # Verify LLM timing is captured
    assert "llm_ms" in result.timings
    assert isinstance(result.timings["llm_ms"], float)
    assert result.timings["llm_ms"] >= 0
    assert (
        result.timings["total_ms"]
        >= result.timings["stt_ms"] + result.timings["llm_ms"]
    )


@pytest.mark.asyncio
async def test_process_turn_stt_rate_limit_error(mock_tts_cache):
    """Test turn processing with STT rate limit error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = STTRateLimitError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "stt"
    assert error.code == "stt_rate_limit"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_llm_rate_limit_error(mock_tts_cache):
    """Test turn processing with LLM rate limit error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.side_effect = LLMError(
        message="Rate limit exceeded",
        code="llm_rate_limit",
        retryable=True,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "llm_rate_limit"
    assert error.retryable is True


@pytest.mark.asyncio
async def test_process_turn_llm_content_filter_error(mock_tts_cache):
    """Test turn processing with LLM content filter error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.side_effect = LLMError(
        message="Content blocked by policy",
        code="llm_content_filter",
        retryable=False,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider",
        return_value=Mock(synthesize=AsyncMock(return_value=b"audio")),
    ):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "llm_content_filter"
    assert error.retryable is False


@pytest.mark.asyncio
async def test_process_turn_request_id_propagation(mock_tts_cache):
    """Test that request_id is propagated through error handling."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.side_effect = STTTimeoutError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    test_request_id = "test-request-123"

    with patch("src.services.orchestrator.get_stt_provider", return_value=mock_stt):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
                request_id=test_request_id,
            )

    error = exc_info.value
    assert error.request_id == test_request_id


@pytest.mark.asyncio
async def test_process_turn_request_id_in_llm_error(mock_tts_cache):
    """Test that request_id is included in LLM errors."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.side_effect = LLMError(
        message="LLM timeout",
        code="llm_timeout",
        retryable=True,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    test_request_id = "test-request-456"

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch("src.services.orchestrator.get_llm_provider", return_value=mock_llm):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
                request_id=test_request_id,
            )

    error = exc_info.value
    assert error.request_id == test_request_id
    assert error.stage == "llm"
    assert error.code == "llm_timeout"


@pytest.mark.asyncio
async def test_process_turn_tts_retryable_error(mock_tts_cache):
    """Test turn processing with retryable TTS error (graceful degradation)."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Follow-up question"

    # Mock TTS to raise retryable error
    mock_tts = AsyncMock()
    mock_tts.synthesize.side_effect = TTSTimeoutError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider", return_value=mock_tts
    ):
        result = await process_turn(
            b"audio",
            "audio/webm",
            session,
            "backend developer",
            "technical interview",
            "mid-level",
            [],
            5,
            mock_tts_cache,
        )

    # Should succeed but with no audio URL
    assert result.transcript == "Test transcript"
    assert result.assistant_text == "Follow-up question"
    assert result.tts_audio_url is None
    assert "tts_ms" in result.timings
    # assert result.timings["tts_ms"] == 0.0  # Or close to it, depending on implementation

    # Verify session still updated
    assert session.turn_count == 1


@pytest.mark.asyncio
async def test_process_turn_tts_non_retryable_error(mock_tts_cache):
    """Test turn processing with non-retryable TTS error."""
    mock_stt = AsyncMock()
    mock_stt.transcribe_audio.return_value = "Test transcript"

    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = "Follow-up question"

    # Mock TTS to raise non-retryable error
    mock_tts = AsyncMock()
    mock_tts.synthesize.side_effect = TTSAuthError()

    session = MockSessionState(
        session_id="test-session",
        turn_count=0,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch(
        "src.services.orchestrator.get_stt_provider", return_value=mock_stt
    ), patch(
        "src.services.orchestrator.get_llm_provider", return_value=mock_llm
    ), patch(
        "src.services.orchestrator.get_tts_provider", return_value=mock_tts
    ):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                b"audio",
                "audio/webm",
                session,
                "backend developer",
                "technical interview",
                "mid-level",
                [],
                5,
                mock_tts_cache,
            )

    error = exc_info.value
    assert error.stage == "tts"
    assert error.code == "tts_auth_error"
    assert error.retryable is False
