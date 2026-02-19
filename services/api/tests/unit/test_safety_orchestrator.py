"""Safety integration tests for turn orchestrator."""

from dataclasses import dataclass
from datetime import datetime, timezone
from unittest.mock import AsyncMock, Mock, patch

import pytest

from src.providers.llm_groq import LLMResponse
from src.services.orchestrator import TurnProcessingError, process_turn
from src.services.safety_filter import SafetyFilter


@dataclass
class MockSessionState:
    """Mock session state for testing."""

    session_id: str
    turn_count: int
    last_activity_at: datetime


@pytest.fixture
def mock_tts_cache() -> Mock:
    """Mock TTS cache for testing."""
    cache = Mock()
    cache.store = Mock()
    return cache


@pytest.mark.asyncio
async def test_pre_llm_safety_violation_returns_content_refused(
    mock_tts_cache: Mock,
) -> None:
    """Pre-LLM safety failure short-circuits with content_refused."""
    session = MockSessionState(
        session_id="test-session",
        turn_count=2,
        last_activity_at=datetime.now(timezone.utc),
    )

    with pytest.raises(TurnProcessingError) as exc_info:
        await process_turn(
            audio_bytes=None,
            mime_type=None,
            session=session,
            role="backend developer",
            interview_type="technical interview",
            difficulty="mid-level",
            asked_questions=[],
            question_count=5,
            tts_cache=mock_tts_cache,
            safety_filter=SafetyFilter(enabled=True),
            transcript="I will kill this person",
            request_id="req-safety-1",
        )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "content_refused"
    assert error.retryable is False
    assert error.request_id == "req-safety-1"
    assert session.turn_count == 2


@pytest.mark.asyncio
async def test_llm_refusal_returns_content_refused_and_does_not_increment_turn(
    mock_tts_cache: Mock,
) -> None:
    """LLM refused=true should surface as content_refused without turn mutation."""
    mock_llm = AsyncMock()
    mock_llm.generate_follow_up.return_value = LLMResponse(
        follow_up_question="Let's stay focused on the interview.",
        coaching_feedback=None,
        refused=True,
    )

    session = MockSessionState(
        session_id="test-session",
        turn_count=3,
        last_activity_at=datetime.now(timezone.utc),
    )

    with patch("src.services.orchestrator.get_llm_provider", return_value=mock_llm):
        with pytest.raises(TurnProcessingError) as exc_info:
            await process_turn(
                audio_bytes=None,
                mime_type=None,
                session=session,
                role="backend developer",
                interview_type="technical interview",
                difficulty="mid-level",
                asked_questions=[],
                question_count=5,
                tts_cache=mock_tts_cache,
                safety_filter=SafetyFilter(enabled=False),
                transcript="off-topic response",
                request_id="req-safety-2",
            )

    error = exc_info.value
    assert error.stage == "llm"
    assert error.code == "content_refused"
    assert error.retryable is False
    assert error.request_id == "req-safety-2"
    assert error.message_safe.startswith("Let's stay focused")
    assert session.turn_count == 3
