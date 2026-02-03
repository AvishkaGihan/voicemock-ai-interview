# Error Codes - VoiceMock AI Interview Coach

This document defines the standard error codes used throughout the API.
Codes follow the pattern: `{stage}_{error_type}`.

## Error Code Taxonomy

### Upload Stage (`upload_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| upload_invalid_format       | 400         | Audio format not supported            |
| upload_file_too_large       | 413         | File exceeds size limit               |
| upload_missing_file         | 400         | No audio file in request              |
| upload_validation_failed    | 400         | Audio file validation failed          |

### STT Stage (`stt_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| stt_transcription_failed    | 500         | Speech-to-text processing failed      |
| stt_audio_unclear           | 422         | Audio too quiet or unclear            |
| stt_language_unsupported    | 422         | Detected language not supported       |
| stt_provider_error          | 502         | STT provider returned error           |
| stt_timeout                 | 504         | STT processing timed out              |

### LLM Stage (`llm_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| llm_generation_failed       | 500         | LLM response generation failed        |
| llm_rate_limited            | 429         | Rate limit exceeded                   |
| llm_context_too_long        | 422         | Conversation context too long         |
| llm_provider_error          | 502         | LLM provider returned error           |
| llm_timeout                 | 504         | LLM processing timed out              |
| llm_safety_filtered         | 422         | Response filtered by safety policy    |

### TTS Stage (`tts_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| tts_synthesis_failed        | 500         | Text-to-speech synthesis failed       |
| tts_voice_unavailable       | 503         | Selected voice not available          |
| tts_provider_error          | 502         | TTS provider returned error           |
| tts_timeout                 | 504         | TTS processing timed out              |

### Session (`session_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| session_not_found           | 404         | Session does not exist                |
| session_expired             | 410         | Session has expired                   |
| session_invalid             | 400         | Invalid session data                  |
| session_max_turns           | 422         | Maximum turns reached                 |

### General (`general_*`)

| Code                        | HTTP Status | Description                           |
|-----------------------------|-------------|---------------------------------------|
| general_internal_error      | 500         | Unexpected internal error             |
| general_validation_error    | 400         | Request validation failed             |
| general_unauthorized        | 401         | Authentication required               |
| general_forbidden           | 403         | Insufficient permissions              |
| general_not_implemented     | 501         | Feature not implemented               |

## Client Handling Recommendations

1. **Retriable errors:** `*_rate_limited`, `*_timeout`, `*_provider_error`
2. **Non-retriable errors:** `*_invalid_format`, `*_too_large`, `*_validation_*`
3. **User action needed:** `stt_audio_unclear`, `session_expired`
