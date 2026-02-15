"""Tests for Deepgram STT provider."""

import pytest
from unittest.mock import Mock, AsyncMock, patch
import httpx

from src.providers.stt_deepgram import (
    DeepgramSTTProvider,
    EmptyTranscriptError,
    STTAuthError,
    STTBadRequestError,
    STTProviderError,
    STTTimeoutError,
)


@pytest.mark.asyncio
async def test_transcribe_audio_success():
    """Test successful transcription with Deepgram."""
    provider = DeepgramSTTProvider(api_key="test_key", timeout_seconds=30)
    audio_bytes = b"fake_audio_data"
    mime_type = "audio/webm"

    mock_response_data = {
        "results": {
            "channels": [
                {
                    "alternatives": [
                        {
                            "transcript": "I would approach this problem by breaking it down."
                        }
                    ]
                }
            ]
        }
    }

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.json.return_value = mock_response_data
        mock_response.raise_for_status = Mock()
        mock_client.post = AsyncMock(return_value=mock_response)

        transcript = await provider.transcribe_audio(audio_bytes, mime_type)

        assert transcript == "I would approach this problem by breaking it down."

        # Verify HTTP call
        mock_client.post.assert_called_once()
        call_args = mock_client.post.call_args
        assert call_args[0][0] == "https://api.deepgram.com/v1/listen"
        assert call_args[1]["headers"]["Authorization"] == "Token test_key"
        assert call_args[1]["headers"]["Content-Type"] == mime_type
        assert call_args[1]["params"]["model"] == "nova-2"
        assert call_args[1]["content"] == audio_bytes
        assert call_args[1]["timeout"] == 30


@pytest.mark.asyncio
async def test_transcribe_audio_empty_transcript():
    """Test empty transcript raises EmptyTranscriptError."""
    provider = DeepgramSTTProvider(api_key="test_key")
    audio_bytes = b"silent_audio"
    mime_type = "audio/webm"

    mock_response_data = {
        "results": {"channels": [{"alternatives": [{"transcript": ""}]}]}
    }

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.json.return_value = mock_response_data
        mock_response.raise_for_status = Mock()
        mock_client.post = AsyncMock(return_value=mock_response)

        with pytest.raises(EmptyTranscriptError):
            await provider.transcribe_audio(audio_bytes, mime_type)


@pytest.mark.asyncio
async def test_transcribe_audio_whitespace_only_transcript():
    """Test whitespace-only transcript raises EmptyTranscriptError."""
    provider = DeepgramSTTProvider(api_key="test_key")
    audio_bytes = b"silent_audio"
    mime_type = "audio/webm"

    mock_response_data = {
        "results": {"channels": [{"alternatives": [{"transcript": "   "}]}]}
    }

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.json.return_value = mock_response_data
        mock_response.raise_for_status = Mock()
        mock_client.post = AsyncMock(return_value=mock_response)

        with pytest.raises(EmptyTranscriptError):
            await provider.transcribe_audio(audio_bytes, mime_type)


@pytest.mark.asyncio
async def test_transcribe_audio_auth_error():
    """Test 401/403 responses raise STTAuthError."""
    provider = DeepgramSTTProvider(api_key="invalid_key")
    audio_bytes = b"audio"
    mime_type = "audio/webm"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 401
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Unauthorized", request=Mock(), response=mock_response
        )

        with pytest.raises(STTAuthError) as exc_info:
            await provider.transcribe_audio(audio_bytes, mime_type)

        assert not exc_info.value.retryable


@pytest.mark.asyncio
async def test_transcribe_audio_bad_request_error():
    """Test 4xx (non-auth) responses raise STTBadRequestError."""
    provider = DeepgramSTTProvider(api_key="test_key")
    audio_bytes = b"invalid_audio"
    mime_type = "audio/webm"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 400
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Bad Request", request=Mock(), response=mock_response
        )

        with pytest.raises(STTBadRequestError) as exc_info:
            await provider.transcribe_audio(audio_bytes, mime_type)

        assert not exc_info.value.retryable


@pytest.mark.asyncio
async def test_transcribe_audio_server_error():
    """Test 5xx responses raise STTProviderError."""
    provider = DeepgramSTTProvider(api_key="test_key")
    audio_bytes = b"audio"
    mime_type = "audio/webm"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 503
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Service Unavailable", request=Mock(), response=mock_response
        )

        with pytest.raises(STTProviderError) as exc_info:
            await provider.transcribe_audio(audio_bytes, mime_type)

        assert exc_info.value.retryable


@pytest.mark.asyncio
async def test_transcribe_audio_timeout():
    """Test timeout raises STTTimeoutError."""
    provider = DeepgramSTTProvider(api_key="test_key", timeout_seconds=1)
    audio_bytes = b"audio"
    mime_type = "audio/webm"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_client.post = AsyncMock(side_effect=httpx.TimeoutException("Timeout"))

        with pytest.raises(STTTimeoutError) as exc_info:
            await provider.transcribe_audio(audio_bytes, mime_type)

        assert exc_info.value.retryable
