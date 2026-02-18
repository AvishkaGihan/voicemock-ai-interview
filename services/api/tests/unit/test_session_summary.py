"""Unit tests for session summary generation and calculations."""

import pytest
from unittest.mock import AsyncMock, Mock, patch

from src.providers.llm_groq import GroqLLMProvider


@pytest.mark.asyncio
async def test_generate_session_summary_success_returns_structured_payload():
    """Provider should return structured summary when JSON is valid."""
    mock_completion = Mock()
    mock_completion.choices = [
        Mock(
            message=Mock(
                content=(
                    '{"overall_assessment":"Strong clarity and flow.",'
                    '"strengths":["Clear examples"],'
                    '"improvements":["Use more metrics"],'
                    '"average_scores":{}}'
                )
            )
        )
    ]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(api_key="test_key")
        result = await provider.generate_session_summary(
            turn_history=[
                {
                    "turn_number": 1,
                    "transcript": "I built an API.",
                    "assistant_text": "How did you test it?",
                    "coaching_feedback": {
                        "dimensions": [
                            {"label": "Clarity", "score": 4, "tip": "Good"},
                            {"label": "Relevance", "score": 5, "tip": "Strong"},
                        ]
                    },
                }
            ],
            role="backend developer",
            interview_type="technical",
            difficulty="medium",
        )

        assert result is not None
        assert result["overall_assessment"] == "Strong clarity and flow."
        assert result["average_scores"]["clarity"] == 4.0
        assert result["average_scores"]["relevance"] == 5.0


@pytest.mark.asyncio
async def test_generate_session_summary_returns_none_on_malformed_json():
    """Provider should gracefully return None on malformed JSON output."""
    mock_completion = Mock()
    mock_completion.choices = [Mock(message=Mock(content="not-json"))]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(api_key="test_key")
        result = await provider.generate_session_summary(
            turn_history=[],
            role="backend developer",
            interview_type="technical",
            difficulty="medium",
        )

        assert result is None


@pytest.mark.asyncio
async def test_generate_session_summary_average_scores_empty_when_no_feedback():
    """Average scores should be empty when no coaching feedback dimensions exist."""
    mock_completion = Mock()
    mock_completion.choices = [
        Mock(
            message=Mock(
                content=(
                    '{"overall_assessment":"Good finish.",'
                    '"strengths":["Composure"],'
                    '"improvements":["Add detail"],'
                    '"average_scores":{}}'
                )
            )
        )
    ]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(api_key="test_key")
        result = await provider.generate_session_summary(
            turn_history=[
                {
                    "turn_number": 1,
                    "transcript": "Answer",
                    "assistant_text": "Thanks",
                    "coaching_feedback": None,
                }
            ],
            role="backend developer",
            interview_type="technical",
            difficulty="medium",
        )

        assert result is not None
        assert result["average_scores"] == {}
