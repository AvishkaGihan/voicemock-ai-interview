"""Tests for Deepgram TTS provider."""

import pytest
from unittest.mock import Mock, AsyncMock, patch
import httpx

from src.providers.tts_deepgram import (
    DeepgramTTSProvider,
    TTSAuthError,
    TTSBadRequestError,
    TTSProviderError,
    TTSTimeoutError,
    TTSRateLimitError,
)


@pytest.mark.asyncio
async def test_synthesize_success():
    """Test successful TTS synthesis with Deepgram."""
    provider = DeepgramTTSProvider(
        api_key="test_key",
        timeout_seconds=30,
        model="aura-2-thalia-en",
    )
    text = "Hello, how can I help you today?"
    fake_audio_bytes = b"fake_mp3_audio_data"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.content = fake_audio_bytes
        mock_response.raise_for_status = Mock()
        mock_client.post = AsyncMock(return_value=mock_response)

        audio_bytes = await provider.synthesize(text)

        assert audio_bytes == fake_audio_bytes

        # Verify HTTP call
        mock_client.post.assert_called_once()
        call_args = mock_client.post.call_args
        assert call_args[0][0] == "https://api.deepgram.com/v1/speak"
        assert call_args[1]["headers"]["Authorization"] == "Token test_key"
        assert call_args[1]["headers"]["Content-Type"] == "application/json"
        assert call_args[1]["params"]["model"] == "aura-2-thalia-en"
        assert call_args[1]["params"]["encoding"] == "mp3"
        assert call_args[1]["json"] == {"text": text}
        assert call_args[1]["timeout"] == 30


@pytest.mark.asyncio
async def test_synthesize_auth_error():
    """Test 401/403 responses raise TTSAuthError."""
    provider = DeepgramTTSProvider(api_key="invalid_key")
    text = "Test text"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 401
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Unauthorized", request=Mock(), response=mock_response
        )

        with pytest.raises(TTSAuthError) as exc_info:
            await provider.synthesize(text)

        assert not exc_info.value.retryable
        assert exc_info.value.stage == "tts"
        assert exc_info.value.code == "tts_auth_error"


@pytest.mark.asyncio
async def test_synthesize_rate_limit_error():
    """Test 429 response raises TTSRateLimitError."""
    provider = DeepgramTTSProvider(api_key="test_key")
    text = "Test text"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 429
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Too Many Requests", request=Mock(), response=mock_response
        )

        with pytest.raises(TTSRateLimitError) as exc_info:
            await provider.synthesize(text)

        assert exc_info.value.retryable
        assert exc_info.value.stage == "tts"
        assert exc_info.value.code == "tts_rate_limit"


@pytest.mark.asyncio
async def test_synthesize_bad_request_error():
    """Test 4xx (non-auth, non-rate-limit) responses raise TTSBadRequestError."""
    provider = DeepgramTTSProvider(api_key="test_key")
    text = "Test text"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 400
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Bad Request", request=Mock(), response=mock_response
        )

        with pytest.raises(TTSBadRequestError) as exc_info:
            await provider.synthesize(text)

        assert not exc_info.value.retryable
        assert exc_info.value.stage == "tts"
        assert exc_info.value.code == "tts_bad_request"


@pytest.mark.asyncio
async def test_synthesize_server_error():
    """Test 5xx responses raise TTSProviderError."""
    provider = DeepgramTTSProvider(api_key="test_key")
    text = "Test text"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.status_code = 503
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_response.raise_for_status.side_effect = httpx.HTTPStatusError(
            "Service Unavailable", request=Mock(), response=mock_response
        )

        with pytest.raises(TTSProviderError) as exc_info:
            await provider.synthesize(text)

        assert exc_info.value.retryable
        assert exc_info.value.stage == "tts"
        assert exc_info.value.code == "tts_provider_error"


@pytest.mark.asyncio
async def test_synthesize_timeout():
    """Test timeout raises TTSTimeoutError."""
    provider = DeepgramTTSProvider(api_key="test_key", timeout_seconds=1)
    text = "Test text"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_client.post = AsyncMock(side_effect=httpx.TimeoutException("Timeout"))

        with pytest.raises(TTSTimeoutError) as exc_info:
            await provider.synthesize(text)

        assert exc_info.value.retryable
        assert exc_info.value.stage == "tts"
        assert exc_info.value.code == "tts_timeout"


@pytest.mark.asyncio
async def test_synthesize_correct_headers_and_payload():
    """Test that correct headers and payload are sent to Deepgram."""
    provider = DeepgramTTSProvider(
        api_key="my_secret_key",
        timeout_seconds=15,
        model="aura-2-helios-en",
    )
    text = "This is a test message."
    fake_audio = b"audio_bytes"

    with patch("httpx.AsyncClient") as mock_client_class:
        mock_client = AsyncMock()
        mock_client_class.return_value.__aenter__.return_value = mock_client

        mock_response = Mock()
        mock_response.content = fake_audio
        mock_response.raise_for_status = Mock()
        mock_client.post = AsyncMock(return_value=mock_response)

        await provider.synthesize(text)

        # Verify all request details
        call_args = mock_client.post.call_args
        assert call_args[1]["headers"]["Authorization"] == "Token my_secret_key"
        assert call_args[1]["headers"]["Content-Type"] == "application/json"
        assert call_args[1]["params"]["model"] == "aura-2-helios-en"
        assert call_args[1]["params"]["encoding"] == "mp3"
        assert call_args[1]["json"]["text"] == text
        assert call_args[1]["timeout"] == 15
