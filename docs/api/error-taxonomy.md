# Error Taxonomy - VoiceMock AI Interview Coach

This document provides detailed guidance on error handling across the VoiceMock system.

## Overview

VoiceMock uses a stage-based error taxonomy that enables:
1. **Clear debugging**: Know exactly where failures occur
2. **Appropriate retries**: Client knows what's retriable
3. **User-friendly messaging**: Actionable error messages
4. **Observability**: Errors can be tracked per-stage

## Error Response Format

All errors follow the [Response Envelope](../../contracts/naming/response-envelope.md) pattern:

```json
{
  "data": null,
  "error": {
    "code": "stt_audio_unclear",
    "stage": "stt",
    "message": "We couldn't hear you clearly. Please try speaking louder or moving to a quieter area.",
    "details": {
      "confidence": 0.25,
      "duration_ms": 3200,
      "retry_allowed": true
    }
  },
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Stages

See [API Stages](../../contracts/api/stages.md) for the full list.

## Error Categories

### Client Errors (4xx)

Errors caused by the client that should not be retried without changes:

| HTTP | Category | Examples |
|------|----------|----------|
| 400  | Bad Request | Missing required fields, invalid JSON |
| 401  | Unauthorized | Missing/invalid session token |
| 404  | Not Found | Session not found |
| 413  | Payload Too Large | Audio file exceeds limit |
| 422  | Unprocessable | Audio unclear, context too long |
| 429  | Rate Limited | Too many requests |

### Server Errors (5xx)

Errors caused by server/provider issues that may be retriable:

| HTTP | Category | Examples |
|------|----------|----------|
| 500  | Internal Error | Unexpected exceptions |
| 502  | Provider Error | Third-party API failure |
| 503  | Unavailable | Service temporarily down |
| 504  | Timeout | Processing took too long |

## Retry Strategy

### Retriable Errors

The client should implement exponential backoff for:
- `429` Rate Limited: Wait for `Retry-After` header
- `502` Provider Error: Wait 1-5 seconds
- `503` Unavailable: Wait 5-30 seconds
- `504` Timeout: Wait 2-10 seconds

```dart
// Flutter retry example
Future<T> withRetry<T>(Future<T> Function() action) async {
  int attempt = 0;
  while (attempt < 3) {
    try {
      return await action();
    } on RetriableError catch (e) {
      attempt++;
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
  }
  throw MaxRetriesExceeded();
}
```

### Non-Retriable Errors

Do NOT retry:
- `400` Bad Request
- `401` Unauthorized
- `404` Not Found
- `413` Payload Too Large
- `422` Unprocessable (unless user takes action)

## User-Facing Messages

Always provide user-friendly messages. The `message` field is designed for display.

### Good Messages

- "We couldn't hear you clearly. Please try speaking louder."
- "The interview session has expired. Please start a new session."
- "Our servers are busy. Please try again in a moment."

### Bad Messages (avoid)

- "Error 500"
- "NullPointerException at line 42"
- "STT_TRANSCRIPTION_FAILED"

## Logging Requirements

All errors should be logged with:
1. `request_id` - For tracing
2. `stage` - For metrics per stage
3. `code` - For categorization
4. `timestamp` - For timeline
5. `user_context` - Session ID, turn number (if available)

```python
logger.error(
    "Turn processing failed",
    extra={
        "request_id": request_id,
        "stage": "stt",
        "code": "stt_transcription_failed",
        "session_id": session_id,
        "turn_number": turn_number,
    }
)
```

## Client Implementation

See error handling implementations:
- Flutter: `lib/core/http/error_handler.dart` (future story)
- Backend: `src/api/dependencies/error_handler.py` (future story)
