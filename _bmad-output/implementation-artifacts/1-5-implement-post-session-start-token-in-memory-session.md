# Story 1.5: Implement `POST /session/start` (token + in-memory session)

Status: done

## Story

As a user,
I want to start a new interview session,
So that I can begin the interview loop.

## Acceptance Criteria

1. **Given** I provide role, interview type, difficulty, and desired question count (or accept defaults)
   **When** the app calls `POST /session/start`
   **Then** the backend creates a server-authoritative in-memory session with TTL
   **And** the response contains a new `session_id` and `session_token`

2. **Given** a session is created
   **When** the backend returns the response
   **Then** the response also includes an opening prompt text for the session
   **And** no audio is returned in this epic

3. **Given** the request body is malformed or missing required fields
   **When** the backend validates the request
   **Then** it returns a 422 error in the standard envelope format with `stage: "unknown"` and `retryable: false`

4. **Given** a session is created
   **When** the backend returns the response
   **Then** the response follows the architecture-mandated envelope pattern `{data, error, request_id}`
   **And** the `X-Request-ID` header matches the body `request_id`

## Tasks / Subtasks

- [x] **Task 1: Create session request/response models** (AC: #1, #2, #4)
  - [x] Create `src/api/models/session_models.py` with Pydantic models
  - [x] Define `SessionStartRequest` with fields: `role` (str), `interview_type` (str), `difficulty` (str, enum), `question_count` (int, default 5)
  - [x] Define `SessionData` with fields: `session_id` (str), `session_token` (str), `opening_prompt` (str)
  - [x] Create type alias `SessionStartResponse = ApiEnvelope[SessionData]`
  - [x] Export models from `src/api/models/__init__.py`

- [x] **Task 2: Create domain models for session state** (AC: #1)
  - [x] Create `src/domain/session_state.py` with `SessionState` dataclass/model
  - [x] Define fields: `session_id`, `role`, `interview_type`, `difficulty`, `question_count`, `created_at`, `last_activity_at`, `turn_count`, `asked_questions` (list), `status` (enum: active/completed/expired)
  - [x] Create `src/domain/stages.py` with stage enum if not exists (verify architecture compliance)
  - [x] Export from `src/domain/__init__.py`

- [x] **Task 3: Implement session token service** (AC: #1)
  - [x] Create `src/security/session_token.py`
  - [x] Implement `SessionTokenService` class using `itsdangerous` (Serializer with TimestampSigner)
  - [x] Implement `generate_token(session_id: str) -> str` method
  - [x] Implement `verify_token(token: str) -> Optional[str]` method (returns session_id or None if invalid/expired)
  - [x] Use `SECRET_KEY` from settings (add to `Settings` class if not present)
  - [x] Configure token expiry (default: 60 minutes matching session TTL)
  - [x] Export from `src/security/__init__.py`

- [x] **Task 4: Implement in-memory session store** (AC: #1)
  - [x] Create `src/services/session_store.py`
  - [x] Implement `SessionStore` class with dict-based storage
  - [x] Implement `create_session(request: SessionStartRequest) -> SessionState` method
  - [x] Implement `get_session(session_id: str) -> Optional[SessionState]` method
  - [x] Implement `update_session(session_id: str, **updates) -> Optional[SessionState]` method
  - [x] Implement `delete_session(session_id: str) -> bool` method
  - [x] Implement TTL cleanup: add `cleanup_expired_sessions()` method (60 min idle default)
  - [x] Add thread-safe access using `threading.Lock` or async-safe equivalent
  - [x] Export from `src/services/__init__.py`

- [x] **Task 5: Create opening prompt generator** (AC: #2)
  - [x] Create `src/services/prompt_generator.py`
  - [x] Implement `generate_opening_prompt(role: str, interview_type: str, difficulty: str) -> str`
  - [x] Create template-based prompts that adapt to role/type/difficulty
  - [x] Keep prompts warm, professional, and anxiety-reducing (per UX spec)
  - [x] Export from `src/services/__init__.py`

- [x] **Task 6: Implement session start route** (AC: #1, #2, #3, #4)
  - [x] Create `src/api/routes/session.py`
  - [x] Implement `POST /session/start` endpoint
  - [x] Inject `RequestContext` dependency for request_id
  - [x] Parse and validate `SessionStartRequest` (Pydantic handles 422 automatically via global handler)
  - [x] Call `SessionStore.create_session()` to create session
  - [x] Call `SessionTokenService.generate_token()` to create token
  - [x] Call `generate_opening_prompt()` to create opening text
  - [x] Return `SessionStartResponse` with envelope format
  - [x] Add OpenAPI documentation with response examples

- [x] **Task 7: Register route and update settings** (AC: #1, #3)
  - [x] Add router to `main.py` with prefix `/session`
  - [x] Update `Settings` class with `SECRET_KEY` (required, no default for security)
  - [x] Update `Settings` class with `SESSION_TTL_MINUTES` (default: 60)
  - [x] Update `.env.example` with new environment variables

- [x] **Task 8: Write unit tests for session token service** (AC: #1)
  - [x] Create `tests/unit/test_session_token.py`
  - [x] Test token generation returns valid string
  - [x] Test token verification returns session_id for valid token
  - [x] Test token verification returns None for invalid token
  - [x] Test token verification returns None for expired token (mock time)
  - [x] Test tokens are unique per generation

- [x] **Task 9: Write unit tests for session store** (AC: #1)
  - [x] Create `tests/unit/test_session_store.py`
  - [x] Test create_session generates unique session_id
  - [x] Test get_session returns created session
  - [x] Test get_session returns None for unknown session_id
  - [x] Test update_session updates last_activity_at
  - [x] Test delete_session removes session
  - [x] Test cleanup_expired_sessions removes stale sessions

- [x] **Task 10: Write integration tests for session start endpoint** (AC: #1, #2, #3, #4)
  - [x] Create `tests/integration/test_session_start.py`
  - [x] Test POST /session/start returns 200 with valid request
  - [x] Test response follows envelope format with `data`, `error`, `request_id`
  - [x] Test response data contains `session_id`, `session_token`, `opening_prompt`
  - [x] Test `session_id` is valid UUID format
  - [x] Test `session_token` is non-empty string
  - [x] Test `opening_prompt` is non-empty and contextually relevant
  - [x] Test `X-Request-ID` header matches body `request_id`
  - [x] Test 422 returned for missing required fields
  - [x] Test 422 returned for invalid difficulty value
  - [x] Test 422 response follows envelope format with stage-aware error

## Dev Notes

### Implements FRs

- **FR1:** User can start a new interview session
- **FR6:** System can introduce the session with an opening prompt

### Background Context

This story establishes the **session management foundation** for all turn-based endpoints. The session is **server-authoritative**: the backend owns session state, issues tokens, and validates them on subsequent requests. This is a critical security pattern that prevents client-side session forgery.

**Important Architecture Decisions:**

- **Guest-only MVP:** No user authentication; sessions are anonymous
- **In-memory storage:** Single backend instance assumption; session loss on restart is acceptable for MVP
- **Token-based security:** All protected endpoints (future `POST /turn`, `GET /tts/{request_id}`) will require `Authorization: Bearer <session_token>`

### Architecture Compliance (MUST FOLLOW)

#### Response Envelope Pattern (Architecture-Mandated)

All JSON endpoints MUST return responses in this format (established in Story 1.4):

```json
{
  "data": {
    "session_id": "uuid-string",
    "session_token": "signed-token-string",
    "opening_prompt": "Welcome! Let's practice..."
  },
  "error": null,
  "request_id": "uuid-string"
}
```

#### Session Start Request Format

```json
{
  "role": "Software Engineer",
  "interview_type": "behavioral",
  "difficulty": "medium",
  "question_count": 5
}
```

#### Token Transport Pattern (Architecture-Mandated)

- `session_token` is sent as `Authorization: Bearer <session_token>` on all protected endpoints
- `session_id` is sent as a request body field (or multipart form field for `POST /turn`)

#### Session State Model

```python
@dataclass
class SessionState:
    session_id: str
    role: str
    interview_type: str
    difficulty: str  # "easy" | "medium" | "hard"
    question_count: int
    created_at: datetime
    last_activity_at: datetime
    turn_count: int = 0
    asked_questions: list[str] = field(default_factory=list)
    status: str = "active"  # "active" | "completed" | "expired"
```

#### Token Implementation (Architecture-Mandated)

From architecture.md:

- Use `itsdangerous 2.2.0` with signed opaque token including `{session_id, iat, exp}`
- Alternative (if needed): JWT HS256 via `PyJWT 2.10.1`

```python
from itsdangerous import URLSafeTimedSerializer

class SessionTokenService:
    def __init__(self, secret_key: str, max_age: int = 3600):
        self.serializer = URLSafeTimedSerializer(secret_key)
        self.max_age = max_age

    def generate_token(self, session_id: str) -> str:
        return self.serializer.dumps({"session_id": session_id})

    def verify_token(self, token: str) -> Optional[str]:
        try:
            data = self.serializer.loads(token, max_age=self.max_age)
            return data.get("session_id")
        except Exception:
            return None
```

#### File Locations (Architecture-Mandated)

```
services/api/src/
├── api/
│   ├── models/
│   │   ├── __init__.py            # MODIFY - add exports
│   │   └── session_models.py      # NEW - SessionStartRequest, SessionData
│   └── routes/
│       └── session.py             # NEW - POST /session/start
├── domain/
│   ├── __init__.py                # MODIFY - add exports
│   ├── session_state.py           # NEW - SessionState dataclass
│   └── stages.py                  # NEW/VERIFY - Stage enum
├── services/
│   ├── __init__.py                # MODIFY - add exports
│   ├── session_store.py           # NEW - in-memory session storage
│   └── prompt_generator.py        # NEW - opening prompt generation
├── security/
│   ├── __init__.py                # MODIFY - add exports
│   └── session_token.py           # NEW - token generation/verification
├── settings/
│   └── config.py                  # MODIFY - add SECRET_KEY, SESSION_TTL
└── main.py                        # MODIFY - register /session router
```

### Technical Requirements (MUST FOLLOW)

#### Python Dependencies (PINNED)

From `requirements.txt`:

- `fastapi==0.128.0`
- `pydantic==2.12.5`
- `itsdangerous==2.2.0` (add to requirements.txt if not present)

#### Pydantic Model Patterns

```python
from pydantic import BaseModel, Field
from typing import Literal

class SessionStartRequest(BaseModel):
    """Request body for starting a new interview session."""
    role: str = Field(..., min_length=1, max_length=100, description="Target job role")
    interview_type: str = Field(..., min_length=1, max_length=50, description="Interview type")
    difficulty: Literal["easy", "medium", "hard"] = Field(..., description="Interview difficulty")
    question_count: int = Field(default=5, ge=1, le=10, description="Number of questions")

class SessionData(BaseModel):
    """Response data for session start."""
    session_id: str = Field(..., description="Unique session identifier")
    session_token: str = Field(..., description="Bearer token for session authentication")
    opening_prompt: str = Field(..., description="Opening prompt text to display")
```

#### Opening Prompt Guidelines (UX-Mandated)

Per UX spec, opening prompts should be:

- **Warm and professional:** "Welcome! Let's practice for your interview."
- **Anxiety-reducing:** Avoid pressure language
- **Contextual:** Reference the role/type when appropriate

Example templates:

```python
OPENING_PROMPTS = {
    "behavioral": "Great choice practicing behavioral questions for {role}! I'll ask you about past experiences. Take your time with each answer.",
    "technical": "Let's work through some technical scenarios for {role}. Focus on explaining your thought process clearly.",
    "default": "Welcome! I'm here to help you practice for your {role} interview. Ready when you are."
}
```

### Previous Story Intelligence (Story 1.4)

#### What Already Exists

- `ApiEnvelope[T]` generic response wrapper with mutual exclusion validator
- `ApiError` model with stage-aware error fields
- Request ID middleware populating `request.state.request_id`
- `RequestContext` dependency for injecting request_id
- Global exception handlers for 404/405/422 forcing envelope format
- `Settings` class with basic app configuration
- Health endpoint demonstrating the envelope pattern

#### Key Patterns Established

- All routes return `ApiEnvelope[DataModel]` response type
- Inject `RequestContext` via Depends() for request_id
- Use Pydantic for all request/response validation
- Global exception handlers ensure envelope compliance

#### Dependencies Already Installed

- `fastapi==0.128.0` ✓
- `pydantic==2.12.5` ✓
- `pytest==8.3.5` ✓
- `pytest-asyncio==0.24.0` ✓
- `httpx==0.28.1` ✓

#### Dependencies to ADD

- `itsdangerous==2.2.0` (for session token signing)

### Anti-Patterns to AVOID

- ❌ Do NOT store tokens in session state (tokens are stateless; only session_id matters)
- ❌ Do NOT hardcode the secret key - MUST come from environment variable
- ❌ Do NOT return raw exceptions - wrap in envelope format
- ❌ Do NOT use client-provided session IDs - server generates all IDs
- ❌ Do NOT skip token expiry - tokens must have matching TTL with sessions
- ❌ Do NOT use `Dict[str, Any]` for session storage - use typed dataclass
- ❌ Do NOT forget thread safety - use locks or async-safe patterns
- ❌ Do NOT persist to disk in MVP - in-memory only per architecture

### Testing Standards

- **Framework:** `pytest` with `pytest-asyncio`
- **HTTP Client:** `httpx` with `TestClient`
- **Test Location:** `services/api/tests/unit/` and `services/api/tests/integration/`
- **Coverage:** Test all acceptance criteria + edge cases
- **Naming:** Test functions follow `test_<what>_<condition>_<expected>` pattern

#### Test Environment Setup

```python
# tests/conftest.py - add SECRET_KEY for tests
import os
os.environ.setdefault("SECRET_KEY", "test-secret-key-do-not-use-in-production")

@pytest.fixture
def secret_key():
    return "test-secret-key-do-not-use-in-production"
```

#### Integration Test Example

```python
@pytest.mark.asyncio
async def test_session_start_returns_valid_response():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/session/start", json={
            "role": "Software Engineer",
            "interview_type": "behavioral",
            "difficulty": "medium",
            "question_count": 5
        })
        assert response.status_code == 200
        data = response.json()

        # Envelope format
        assert "data" in data
        assert "error" in data
        assert "request_id" in data
        assert data["error"] is None

        # Session data
        session_data = data["data"]
        assert "session_id" in session_data
        assert "session_token" in session_data
        assert "opening_prompt" in session_data

        # UUID format validation
        import uuid
        uuid.UUID(session_data["session_id"])  # Raises if invalid

        # Token is non-empty
        assert len(session_data["session_token"]) > 0

        # X-Request-ID header matches
        assert response.headers.get("X-Request-ID") == data["request_id"]
```

### Project Structure Notes

- This story establishes the **session management pattern** used by all subsequent turn-based endpoints
- The `SessionStore` will be extended in future stories for turn tracking and transcript storage
- The `SessionTokenService` will be used in a dependency to protect `POST /turn` and `GET /tts/{request_id}`
- The token verification pattern established here becomes a FastAPI dependency for auth

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.5] - acceptance criteria
- [Source: _bmad-output/planning-artifacts/architecture.md#Authentication & Security] - token mechanism
- [Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns] - session start contract
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture] - session retention and artifacts
- [Source: _bmad-output/planning-artifacts/architecture.md#Validation Issues Addressed] - credential transport rules
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Core User Experience] - opening prompt tone
- [Source: _bmad-output/implementation-artifacts/1-4-backend-baseline-health-endpoint.md] - envelope pattern implementation

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5

### Debug Log References

N/A

### Completion Notes List

- ✅ Implemented POST /session/start endpoint with full session management
- ✅ Created SessionTokenService using itsdangerous for secure token signing/verification
- ✅ Implemented thread-safe SessionStore with TTL management
- ✅ Created opening prompt generator with contextual templates
- ✅ All 45 tests pass (24 unit + 21 integration)
- ✅ All acceptance criteria satisfied
- ✅ Envelope pattern compliance maintained
- ✅ Architecture specifications followed

### Change Log

- 2026-02-03: Story 1.5 completed - Session start endpoint implementation with token-based authentication

### File List

- services/api/src/api/models/session_models.py (NEW)
- services/api/src/api/models/**init**.py (MODIFIED)
- services/api/src/api/routes/session.py (NEW)
- services/api/src/domain/session_state.py (NEW)
- services/api/src/domain/stages.py (NEW)
- services/api/src/domain/**init**.py (MODIFIED)
- services/api/src/security/session_token.py (NEW)
- services/api/src/security/**init**.py (MODIFIED)
- services/api/src/services/session_store.py (NEW)
- services/api/src/services/prompt_generator.py (NEW)
- services/api/src/services/**init**.py (MODIFIED)
- services/api/src/settings/config.py (MODIFIED)
- services/api/src/main.py (MODIFIED)
- services/api/requirements.txt (MODIFIED)
- services/api/.env.example (MODIFIED)
- services/api/tests/conftest.py (NEW)
- services/api/tests/unit/test_session_token.py (NEW)
- services/api/tests/unit/test_session_store.py (NEW)
- services/api/tests/integration/test_session_start.py (NEW)
- services/api/tests/unit/test_session_models.py (NEW)

### Change Log

- 2026-02-03: Story 1.5 completed - Session start endpoint implementation with token-based authentication
- 2026-02-03: Code Review fixes - Thread safety improvements, validation tests, and linting

