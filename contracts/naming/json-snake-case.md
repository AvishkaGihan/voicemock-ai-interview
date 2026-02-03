# JSON Naming Convention - VoiceMock AI Interview Coach

This document defines the JSON naming conventions for all API request and response bodies.

## Rule: snake_case

**All JSON field names MUST use `snake_case`.**

### ✅ Correct

```json
{
  "session_id": "sess_abc123",
  "job_type": "Backend Engineer",
  "focus_area": "System Design",
  "created_at": "2024-01-15T10:30:00Z",
  "turn_count": 5,
  "is_active": true
}
```

### ❌ Incorrect

```json
{
  "sessionId": "sess_abc123",      // camelCase
  "JobType": "Backend Engineer",    // PascalCase
  "focus-area": "System Design",    // kebab-case
  "CreatedAt": "2024-01-15T10:30:00Z"
}
```

## Rationale

1. **Python backend compatibility**: Python uses snake_case by default
2. **Pydantic serialization**: Works natively without alias configuration
3. **Consistency**: Single convention across all endpoints
4. **Industry standard**: Common in REST APIs

## Client Responsibility

Mobile clients (Flutter/Dart) should:
1. Use `JsonKey` annotations to map snake_case to Dart conventions
2. Configure json_serializable to handle case conversion
3. Or use snake_case in Dart models for simplicity

### Flutter Example

```dart
@JsonSerializable()
class Session {
  @JsonKey(name: 'session_id')
  final String sessionId;

  @JsonKey(name: 'job_type')
  final String jobType;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
}
```

## Nested Objects

Nested objects also follow snake_case:

```json
{
  "session_info": {
    "session_id": "sess_abc123",
    "turn_history": [
      {
        "turn_number": 1,
        "user_transcript": "...",
        "ai_response": "..."
      }
    ]
  }
}
```
