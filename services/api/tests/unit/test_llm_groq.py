"""Tests for Groq LLM provider."""

import pytest
from unittest.mock import Mock, AsyncMock, patch

from src.providers.llm_groq import (
    GroqLLMProvider,
    LLMError,
)


@pytest.mark.asyncio
async def test_generate_follow_up_success():
    """Test successful follow-up question generation."""
    mock_completion = Mock()
    mock_completion.choices = [
        Mock(
            message=Mock(
                content="What programming languages are you most comfortable with?"
            )
        )
    ]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        result = await provider.generate_follow_up(
            transcript="I have experience with Python and Java.",
            role="backend developer",
            interview_type="technical interview",
            difficulty="mid-level",
            asked_questions=["Tell me about yourself."],
            question_number=2,
            total_questions=5,
        )

        assert result == "What programming languages are you most comfortable with?"

        # Verify LLM call
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        assert call_args[1]["model"] == "llama-3.3-70b-versatile"
        assert call_args[1]["max_tokens"] == 256
        assert call_args[1]["temperature"] == 0.7
        assert len(call_args[1]["messages"]) == 2  # system + user


@pytest.mark.asyncio
async def test_generate_follow_up_last_question():
    """Test final acknowledgment generation for the last question."""
    mock_completion = Mock()
    mock_completion.choices = [
        Mock(
            message=Mock(
                content="Great work today! Thanks for sharing your experience."
            )
        )
    ]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        result = await provider.generate_follow_up(
            transcript="I prefer using microservices architecture.",
            role="backend developer",
            interview_type="technical interview",
            difficulty="mid-level",
            asked_questions=[
                "Tell me about yourself.",
                "What is your experience with Python?",
                "How do you handle REST APIs?",
                "Describe your database experience.",
                "What is your preferred architecture?",
            ],
            question_number=6,
            total_questions=5,
        )

        assert result == "Great work today! Thanks for sharing your experience."

        # Verify system prompt is different for last question (is_last_question=True)
        # In the fixed implementation, this happens when question_number > total_questions
        # (e.g. we are generating the response AFTER the 5th question was answered)
        mock_client.chat.completions.create.assert_called_once()
        call_args = mock_client.chat.completions.create.call_args
        system_message = call_args[1]["messages"][0]["content"]
        assert "FINAL" in system_message
        assert "acknowledgment" in system_message.lower()
        assert "Do NOT ask another question" in system_message


@pytest.mark.asyncio
async def test_generate_follow_up_timeout_error():
    """Test timeout raises LLMError with 'llm_timeout' code."""
    from groq import APITimeoutError

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(
            side_effect=APITimeoutError(request=Mock())
        )

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        with pytest.raises(LLMError) as exc_info:
            await provider.generate_follow_up(
                transcript="I have experience with Python.",
                role="backend developer",
                interview_type="technical interview",
                difficulty="mid-level",
                asked_questions=["Tell me about yourself."],
                question_number=2,
                total_questions=5,
            )

        assert exc_info.value.stage == "llm"
        assert exc_info.value.code == "llm_timeout"
        assert exc_info.value.retryable is True


@pytest.mark.asyncio
async def test_generate_follow_up_api_error():
    """Test API error raises LLMError with 'provider_error' code."""
    from groq import APIError

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(
            side_effect=APIError(
                message="Rate limit exceeded",
                request=Mock(),
                body=None,
            )
        )

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        with pytest.raises(LLMError) as exc_info:
            await provider.generate_follow_up(
                transcript="I have experience with Python.",
                role="backend developer",
                interview_type="technical interview",
                difficulty="mid-level",
                asked_questions=["Tell me about yourself."],
                question_number=2,
                total_questions=5,
            )

        assert exc_info.value.stage == "llm"
        assert exc_info.value.code == "llm_provider_error"
        assert exc_info.value.retryable is True


@pytest.mark.asyncio
async def test_generate_follow_up_empty_response():
    """Test empty LLM response raises LLMError."""
    mock_completion = Mock()
    mock_completion.choices = [Mock(message=Mock(content=""))]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        with pytest.raises(LLMError) as exc_info:
            await provider.generate_follow_up(
                transcript="I have experience with Python.",
                role="backend developer",
                interview_type="technical interview",
                difficulty="mid-level",
                asked_questions=["Tell me about yourself."],
                question_number=2,
                total_questions=5,
            )

        assert exc_info.value.stage == "llm"
        assert "empty" in str(exc_info.value).lower()


@pytest.mark.asyncio
async def test_generate_follow_up_avoids_repeating_questions():
    """Test that asked questions are included in user prompt."""
    mock_completion = Mock()
    mock_completion.choices = [
        Mock(message=Mock(content="What is your experience with databases?"))
    ]

    asked = [
        "Tell me about yourself.",
        "What programming languages do you know?",
        "Describe your experience with REST APIs.",
    ]

    with patch("src.providers.llm_groq.AsyncGroq") as mock_groq_class:
        mock_client = AsyncMock()
        mock_groq_class.return_value = mock_client
        mock_client.chat.completions.create = AsyncMock(return_value=mock_completion)

        provider = GroqLLMProvider(
            api_key="test_key",
            model="llama-3.3-70b-versatile",
            timeout_seconds=30,
            max_tokens=256,
        )

        result = await provider.generate_follow_up(
            transcript="I have 5 years of experience.",
            role="backend developer",
            interview_type="technical interview",
            difficulty="mid-level",
            asked_questions=asked,
            question_number=4,
            total_questions=5,
        )

        assert result == "What is your experience with databases?"

        # Verify asked questions are in the system prompt
        call_args = mock_client.chat.completions.create.call_args
        system_message = call_args[1]["messages"][0]["content"]
        for question in asked:
            assert question in system_message
