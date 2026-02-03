# Response Envelope - VoiceMock AI Interview Coach

This document defines the standard JSON response envelope used by all API endpoints.

## Envelope Structure

**All API responses use this envelope:**

```json
{
  "data": <payload | null>,
  "error": <error_object | null>,
  "request_id": "<uuid>"
}
```

## Fields

| Field       | Type              | Description                                        |
|-------------|-------------------|----------------------------------------------------|
| data        | object \| null    | Success payload; null on error                     |
| error       | object \| null    | Error details; null on success                     |
| request_id  | string            | Unique request ID (matches X-Request-ID header)   |

## Success Response

On success, `data` contains the response payload and `error` is null.

```json
{
  "data": {
    "session_id": "sess_abc123",
    "token": "eyJhbGciOi..."
  },
  "error": null,
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Error Response

On error, `error` contains details and `data` is null.

```json
{
  "data": null,
  "error": {
    "code": "stt_transcription_failed",
    "stage": "stt",
    "message": "Could not transcribe audio. Please try speaking more clearly.",
    "details": {
      "confidence": 0.3,
      "duration_ms": 1500
    }
  },
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Error Object Structure

| Field    | Type           | Required | Description                                 |
|----------|----------------|----------|---------------------------------------------|
| code     | string         | Yes      | Machine-readable error code                 |
| stage    | string         | Yes      | Processing stage (upload/stt/llm/tts/unknown) |
| message  | string         | Yes      | Human-readable error message                |
| details  | object \| null | No       | Additional error context                    |

## Client Implementation

### Dart Example

```dart
class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final String requestId;

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;
}

class ApiError {
  final String code;
  final String stage;
  final String message;
  final Map<String, dynamic>? details;

  bool get isRetryable => [
    'rate_limited',
    'timeout',
    'provider_error'
  ].any(code.contains);
}
```

### Python Example

```python
from pydantic import BaseModel
from typing import Optional, TypeVar, Generic

T = TypeVar('T')

class ApiError(BaseModel):
    code: str
    stage: str
    message: str
    details: Optional[dict] = None

class ApiResponse(BaseModel, Generic[T]):
    data: Optional[T]
    error: Optional[ApiError]
    request_id: str
```

## Invariants

1. **Exactly one is populated**: Either `data` OR `error`, never both, never neither
2. **request_id is always present**: Even on errors
3. **HTTP status matches error**: 4xx/5xx on error, 2xx on success
