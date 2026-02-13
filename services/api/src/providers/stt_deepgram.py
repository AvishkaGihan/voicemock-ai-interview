"""Deepgram speech-to-text provider."""

import httpx


class STTError(Exception):
    """Base exception for STT provider errors."""

    def __init__(self, message: str, stage: str, code: str, retryable: bool):
        super().__init__(message)
        self.stage = stage
        self.code = code
        self.retryable = retryable


class EmptyTranscriptError(STTError):
    """Empty transcript returned from STT provider."""

    def __init__(self):
        super().__init__(
            message="We couldn't hear anything. Please try again.",
            stage="stt",
            code="stt_empty_transcript",
            retryable=True,
        )


class STTAuthError(STTError):
    """Authentication error with STT provider (401/403)."""

    def __init__(self, message: str = "STT authentication failed"):
        super().__init__(
            message=message,
            stage="stt",
            code="stt_auth_error",
            retryable=False,
        )


class STTBadRequestError(STTError):
    """Bad request error from STT provider (4xx)."""

    def __init__(self, message: str = "Invalid audio or request parameters"):
        super().__init__(
            message=message,
            stage="stt",
            code="stt_bad_request",
            retryable=False,
        )


class STTProviderError(STTError):
    """Server error from STT provider (5xx)."""

    def __init__(self, message: str = "STT provider is unavailable"):
        super().__init__(
            message=message,
            stage="stt",
            code="stt_provider_error",
            retryable=True,
        )


class STTTimeoutError(STTError):
    """Timeout error during STT request."""

    def __init__(self, message: str = "Transcription timed out. Please try again."):
        super().__init__(
            message=message,
            stage="stt",
            code="stt_timeout",
            retryable=True,
        )


class DeepgramSTTProvider:
    """Deepgram Nova-2 speech-to-text provider.

    Uses Deepgram's pre-recorded audio API with the Nova-2 model.
    """

    def __init__(self, api_key: str, timeout_seconds: int = 30):
        """Initialize Deepgram STT provider.

        Args:
            api_key: Deepgram API key
            timeout_seconds: Timeout for transcription requests (default: 30s)
        """
        self._api_key = api_key
        self._timeout = timeout_seconds
        self._base_url = "https://api.deepgram.com/v1/listen"

    async def transcribe_audio(self, audio_bytes: bytes, mime_type: str) -> str:
        """Transcribe audio bytes using Deepgram Nova-2.

        Args:
            audio_bytes: Raw audio data to transcribe
            mime_type: MIME type of the audio (e.g., 'audio/webm', 'audio/wav')

        Returns:
            Transcript text

        Raises:
            EmptyTranscriptError: If transcript is empty or whitespace-only
            STTAuthError: If authentication fails (401/403)
            STTBadRequestError: If request is invalid (4xx)
            STTProviderError: If provider has server error (5xx)
            STTTimeoutError: If request times out
        """
        headers = {
            "Authorization": f"Token {self._api_key}",
            "Content-Type": mime_type,
        }
        params = {
            "model": "nova-2",
            "smart_format": "true",
            "punctuate": "true",
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    self._base_url,
                    headers=headers,
                    params=params,
                    content=audio_bytes,
                    timeout=self._timeout,
                )
                response.raise_for_status()

                data = response.json()
                transcript = data["results"]["channels"][0]["alternatives"][0][
                    "transcript"
                ]

                if not transcript or not transcript.strip():
                    raise EmptyTranscriptError()

                return transcript

        except httpx.TimeoutException:
            raise STTTimeoutError()

        except httpx.HTTPStatusError as e:
            status_code = e.response.status_code

            if status_code in (401, 403):
                raise STTAuthError()
            elif 400 <= status_code < 500:
                raise STTBadRequestError()
            else:  # 5xx
                raise STTProviderError()
