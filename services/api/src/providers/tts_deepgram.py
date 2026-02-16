"""Deepgram text-to-speech provider."""

import httpx


class TTSError(Exception):
    """Base exception for TTS provider errors."""

    def __init__(self, message: str, stage: str, code: str, retryable: bool):
        super().__init__(message)
        self.stage = stage
        self.code = code
        self.retryable = retryable


class TTSAuthError(TTSError):
    """Authentication error with TTS provider (401/403)."""

    def __init__(self, message: str = "TTS authentication failed"):
        super().__init__(
            message=message,
            stage="tts",
            code="tts_auth_error",
            retryable=False,
        )


class TTSBadRequestError(TTSError):
    """Bad request error from TTS provider (4xx)."""

    def __init__(self, message: str = "Invalid text or request parameters"):
        super().__init__(
            message=message,
            stage="tts",
            code="tts_bad_request",
            retryable=False,
        )


class TTSProviderError(TTSError):
    """Server error from TTS provider (5xx)."""

    def __init__(self, message: str = "TTS provider is unavailable"):
        super().__init__(
            message=message,
            stage="tts",
            code="tts_provider_error",
            retryable=True,
        )


class TTSTimeoutError(TTSError):
    """Timeout error during TTS request."""

    def __init__(self, message: str = "TTS generation timed out. Please try again."):
        super().__init__(
            message=message,
            stage="tts",
            code="tts_timeout",
            retryable=True,
        )


class TTSRateLimitError(TTSError):
    """Rate limit error from TTS provider (429)."""

    def __init__(
        self,
        message: str = "Too many requests. Please try again shortly.",
    ):
        super().__init__(
            message=message,
            stage="tts",
            code="tts_rate_limit",
            retryable=True,
        )


class DeepgramTTSProvider:
    """Deepgram Aura-2 text-to-speech provider.

    Uses Deepgram's Aura-2 TTS API with ultra-low latency.
    """

    def __init__(
        self,
        api_key: str,
        timeout_seconds: int = 30,
        model: str = "aura-2-thalia-en",
    ):
        """Initialize Deepgram TTS provider.

        Args:
            api_key: Deepgram API key
            timeout_seconds: Timeout for TTS requests (default: 30s)
            model: Deepgram voice model (default: aura-2-thalia-en)
        """
        self._api_key = api_key
        self._timeout = timeout_seconds
        self._model = model
        self._base_url = "https://api.deepgram.com/v1/speak"

    async def synthesize(self, text: str) -> bytes:
        """Synthesize text to audio using Deepgram Aura-2.

        Args:
            text: Text to synthesize to speech

        Returns:
            Raw audio bytes (MP3 format)

        Raises:
            TTSAuthError: If authentication fails (401/403)
            TTSRateLimitError: If rate limit is exceeded (429)
            TTSBadRequestError: If request is invalid (4xx)
            TTSProviderError: If provider has server error (5xx)
            TTSTimeoutError: If request times out
        """
        headers = {
            "Authorization": f"Token {self._api_key}",
            "Content-Type": "application/json",
        }
        params = {
            "model": self._model,
            "encoding": "mp3",
        }
        payload = {"text": text}

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self._base_url,
                    headers=headers,
                    params=params,
                    json=payload,
                    timeout=self._timeout,
                )
                response.raise_for_status()

                # Response body is raw audio bytes
                return response.content

        except httpx.TimeoutException:
            raise TTSTimeoutError()

        except httpx.HTTPStatusError as e:
            status_code = e.response.status_code

            if status_code in (401, 403):
                raise TTSAuthError()
            elif status_code == 429:
                raise TTSRateLimitError()
            elif 400 <= status_code < 500:
                raise TTSBadRequestError()
            else:  # 5xx
                raise TTSProviderError()
