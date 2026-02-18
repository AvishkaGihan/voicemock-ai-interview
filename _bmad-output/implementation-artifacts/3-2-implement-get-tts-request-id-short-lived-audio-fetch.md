# Story 3.2: Implement `GET /tts/{request_id}` (short-lived audio fetch)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As the mobile app,
I want to fetch TTS audio by request id,
So that playback is decoupled from the JSON response.

## Acceptance Criteria

1. **Given** a `tts_audio_url` is provided in the `POST /turn` response
   **When** the app calls `GET /tts/{request_id}`
   **Then** the backend returns audio bytes with `Content-Type: audio/mpeg`
   **And** the response includes `X-Request-ID` header

2. **Given** a valid `request_id` with cached audio
   **When** the endpoint is called
   **Then** audio bytes are returned as a streaming response
   **And** the response status code is 200

3. **Given** a `request_id` whose audio has expired (TTL exceeded)
   **When** the endpoint is called
   **Then** the backend returns a 404 error in the standard envelope format
   **And** `error.stage` is `"tts"`, `error.code` is `"tts_audio_not_found"`, `error.retryable` is `false`

4. **Given** a `request_id` that was never cached (invalid/unknown)
   **When** the endpoint is called
   **Then** the backend returns a 404 error in the standard envelope format
   **And** `error.stage` is `"tts"`, `error.code` is `"tts_audio_not_found"`, `error.retryable` is `false`

5. **Given** the endpoint is called
   **When** the response is constructed
   **Then** `X-Request-ID` is present in response headers (from middleware)
   **And** the endpoint is registered at `/tts/{request_id}` path

6. **Given** the `session_token` is required for protected endpoints
   **When** the app calls `GET /tts/{request_id}`
   **Then** the endpoint requires `Authorization: Bearer <session_token>` header
   **And** invalid/missing tokens return 401 with envelope-wrapped error

7. **Given** the audio is available only for a short-lived window
   **When** audio is fetched within the TTL (default 5 min)
   **Then** the audio is returned successfully
   **And** after TTL expiration, subsequent requests return 404

## Tasks / Subtasks

### Task 1: Create `GET /tts/{request_id}` route (AC: #1, #2, #3, #4, #5)

- [x] 1.1 Create `services/api/src/api/routes/tts.py`:
  - `router = APIRouter(tags=["TTS Audio"])`
  - Route: `GET /tts/{request_id}`
  - Inject `TTSCache` via `Depends(get_tts_cache)`
  - Inject `RequestContext` via `Depends(get_request_context)`
  - Call `tts_cache.get(request_id)`:
    - If `None`: return 404 envelope error (`tts_audio_not_found` or `tts_audio_expired`)
    - If bytes: return `Response(content=audio_bytes, media_type="audio/mpeg")`
- [x] 1.2 Add appropriate response model documentation in the route decorator for OpenAPI
- [x] 1.3 Add logging: log `request_id` lookup (info on success, warning on miss)

### Task 2: Add session token authentication (AC: #6)

- [x] 2.1 Add `Authorization` header dependency to the TTS route:
  - Inject `SessionTokenService` via `Depends(get_token_service)`
  - Accept `authorization: str = Header(...)` parameter
  - Parse `Bearer <token>` format
  - Verify token via `token_service.verify(token)`
  - On invalid/missing token: raise `HTTPException(401)` with envelope error
  - **Follow the exact same auth pattern used in `turn.py`**
- [x] 2.2 Ensure 401 errors include `X-Request-ID` and envelope format

### Task 3: Register TTS route in main app (AC: #5)

- [x] 3.1 Update `services/api/src/main.py`:
  - Import `tts` from `src.api.routes`
  - Add `app.include_router(tts.router, prefix="/tts", tags=["TTS Audio"])`
- [x] 3.2 Update `services/api/src/api/routes/__init__.py` to export `tts` module (if applicable)

### Task 4: Write unit tests (AC: #1–#7)

- [x] 4.1 Create `services/api/tests/unit/test_tts_route.py`:
  - Test: valid `request_id` → returns 200 with `audio/mpeg` content
  - Test: missing `request_id` → returns 404 with `tts_audio_not_found`
  - Test: expired `request_id` → returns 404 with `tts_audio_expired`
  - Test: response includes `X-Request-ID` header
  - Test: missing auth header → returns 401
  - Test: invalid auth token → returns 401
  - Test: valid auth token → proceeds to fetch audio
  - Test: content-type is `audio/mpeg` for successful responses
- [x] 4.2 Verify all existing tests still pass (regression check)
  - Run: `cd services/api && python -m pytest tests/ -v`

### Task 5: Update routes `__init__.py` export (AC: #5)

- [x] 5.1 Check `services/api/src/api/routes/__init__.py` and add `tts` import if needed for consistency with `health`, `session`, `turn` imports

## Dev Notes

### Existing Infrastructure (ALREADY BUILT — leverage, don't rebuild)

**`TTSCache`** (`services/api/src/services/tts_cache.py`):

- Already has `get(request_id: str) -> bytes | None` — returns audio bytes or `None` if expired/missing
- Already has lazy cleanup on `get()` — expired entries are removed when accessed
- Thread-safe with `threading.Lock`
- Singleton via `get_tts_cache()` in `shared_services.py`
- **No changes needed to TTSCache** — this story only consumes it

**`shared_services.py`** (`services/api/src/api/dependencies/shared_services.py`):

- Already has `get_tts_cache()` singleton dependency — ready to inject
- Already has `get_session_store()` and `get_token_service()` — use same pattern for auth

**`main.py`** (`services/api/src/main.py`):

- Already imports and registers `health`, `session`, `turn` routers
- Pattern: `app.include_router(tts.router, prefix="/tts", tags=["TTS Audio"])`
- Request ID middleware already adds `X-Request-ID` to all responses

**`turn.py` auth pattern** (`services/api/src/api/routes/turn.py`):

- Authenticates via `authorization: str = Header(...)` parameter
- Parses `Bearer <token>` and calls `token_service.verify(token)`
- Extracts `session_id` from verified claims
- **FOLLOW THIS EXACT PATTERN for token verification on GET /tts**

**`TurnResponseData`** (`services/api/src/api/models/turn_models.py`):

- Already returns `tts_audio_url` like `"/tts/{request_id}"` — the client will call this endpoint

### What Needs to Be Built

This story is about **serving cached TTS audio via a dedicated endpoint**:

1. **`tts.py` route** — New route file at `services/api/src/api/routes/tts.py` with `GET /tts/{request_id}`
2. **Route registration** — Register the TTS router in `main.py`
3. **Token auth** — Add session token verification (same pattern as `turn.py`)
4. **Error handling** — Return 404 with envelope errors for missing/expired audio
5. **Tests** — Unit tests for the new endpoint

### Architecture-Mandated Patterns

From architecture.md:

- **Route location:** `services/api/src/api/routes/tts.py` — MUST go here
- **Endpoint:** `GET /tts/{request_id}` — serves audio bytes from in-memory cache
- **Response:** Audio bytes with `Content-Type: audio/mpeg` (NOT wrapped in JSON envelope)
- **Error format:** `{ "data": null, "error": { "stage": "tts", "code": "...", "message_safe": "...", "retryable": false }, "request_id": "..." }` — errors ARE wrapped in envelope
- **Auth:** `Authorization: Bearer <session_token>` required (architecture mandates token on all protected endpoints)
- **`X-Request-ID`:** Echoed in response headers via middleware (already handled globally)
- **JSON fields:** `snake_case` — `request_id`, `tts_audio_not_found`
- **Backend project organization:** routes in `api/routes/`, models in `api/models/`, services in `services/`, providers in `providers/`

### Response Format Clarification

- **Success (200):** Raw audio bytes — NOT JSON. `Content-Type: audio/mpeg`. Client uses `just_audio` to play directly.
- **Error (404/401):** Standard JSON envelope: `{ "data": null, "error": {...}, "request_id": "..." }`
- **This is intentional:** audio endpoints return raw bytes on success, but use the standard error format for failures. This follows the architecture's note: "All **non-audio** JSON responses use a consistent wrapper."

### UX Specifications (from ux-design-specification.md)

- **Speaking state:** Mobile app transitions to "Speaking" when audio playback begins after fetching from this endpoint
- **No overlap:** Never play TTS while recording; single playback queue (enforced by mobile `InterviewCubit`)
- **Graceful degradation:** If TTS fetch fails (404 expired), the client still shows `assistant_text` as readable text
- **Voice-first, not voice-only:** `assistant_text` is always visible; audio is an enhancement

### Previous Story Learnings (from Story 3.1)

- **TTSCache is already tested and working** — 8 unit tests for cache operations (store, get, expired, cleanup)
- **`process_turn()` now accepts `tts_cache` parameter** — TTS audio is stored in cache keyed by `request_id`
- **TTS audio format is MP3** — `Content-Type: audio/mpeg` (Deepgram Aura returns MP3 by default)
- **`tts_audio_url` is a relative path** like `/tts/{request_id}` — client prepends base URL
- **TTL default is 300 seconds (5 minutes)** — configurable via `settings.tts_cache_ttl_seconds`
- **Thread-safe cache** — uses `threading.Lock`; safe for concurrent requests
- **Error hierarchy follows pattern:** `stage`, `code`, `retryable` fields on all errors
- **80-char line length:** Python follows PEP 8 (79-char limit), be mindful in route code
- **Test patterns:** Use `pytest-asyncio` for async tests; mock TTSCache in tests
- **Feature branches:** Use pattern `feature/story-3-2-short-description`
- **Conventional commits:** `feat:`, `fix:`, `test:` prefixes

### Git Intelligence (Recent Commits)

```
afe1c1c Merge pull request - Story 3.1 TTS generation
d1d33cb feat(interview): pass InterviewCubit to DiagnosticsPage during navigation
403addf docs: Add sprint status tracking and Epic 2 retrospective documents
3368853 Merge pull request #19 from AvishkaGihan/feature/2-8-handle-interruptions
621ad02 feat(mobile/interview): handle audio focus interruptions during recording
```

Key observations:

- Story 3.1 (TTS generation + caching) is DONE — this story picks up where 3.1 left off
- The `TTSCache`, `DeepgramTTSProvider`, and orchestrator TTS integration are all in place
- Feature branch naming: `feature/story-3-2-get-tts-audio-fetch`
- Commit convention: `feat:`, `fix:`, `test:` prefixes used consistently

### Critical Naming Conventions

- **File names:** `snake_case` — `tts.py` (route file)
- **Function names:** `snake_case` — `fetch_tts_audio()`
- **Error codes:** `tts_audio_not_found`, `tts_audio_expired`
- **Route registration:** prefix `/tts`, tag `TTS Audio`
- **Test file:** `test_tts_route.py` in `services/api/tests/unit/`

### File Inventory

**Files to create:**

- `services/api/src/api/routes/tts.py` — GET /tts/{request_id} endpoint

**Files to create (tests):**

- `services/api/tests/unit/test_tts_route.py` — TTS route unit tests

**Files to modify:**

- `services/api/src/main.py` — Register TTS router
- `services/api/src/api/routes/__init__.py` — Export TTS route module (if needed)

**Files to validate (likely NO changes):**

- `services/api/src/services/tts_cache.py` — Already built, no changes needed
- `services/api/src/api/dependencies/shared_services.py` — Already has `get_tts_cache()`
- `services/api/requirements.txt` — No new deps needed
- `services/api/src/api/models/turn_models.py` — Already has `tts_audio_url` field

### Gotchas / Anti-Patterns to Avoid

1. **DO NOT wrap successful audio response in JSON envelope** — Success returns raw audio bytes with `Content-Type: audio/mpeg`. Only errors use the JSON envelope.

2. **DO NOT skip token authentication** — Architecture mandates `Authorization: Bearer <session_token>` on all protected endpoints. `GET /tts/{request_id}` is protected.

3. **DO NOT create a new cache or modify TTSCache** — The cache is already built and tested. This story only READS from it via `tts_cache.get(request_id)`.

4. **DO NOT add new pip dependencies** — Everything needed is already in `requirements.txt`. FastAPI's `Response` class handles raw byte responses natively.

5. **DO NOT use `StreamingResponse` for small audio** — For MVP, the audio is small enough (typically < 1MB) that a plain `Response(content=bytes, media_type="audio/mpeg")` is sufficient. Avoid premature optimization with streaming.

6. **DO NOT persist or log audio bytes** — Return them from cache and forget. No disk writes, no base64 encoding in logs.

7. **DO NOT differentiate between "never cached" and "expired"** — `TTSCache.get()` returns `None` for both cases. Use `tts_audio_not_found` as the error code (the client doesn't need to know why it's missing).

8. **DO NOT forget to register the router** — `main.py` must include `app.include_router(tts.router, prefix="/tts", tags=["TTS Audio"])` and the import must be added.

9. **DO NOT use a different auth pattern than `turn.py`** — Follow the existing `Header(...)` + `token_service.verify()` pattern exactly.

10. **DO NOT return headers like `Content-Length` manually** — FastAPI/Starlette handles this automatically.

### Project Structure Notes

- `tts.py` goes in `services/api/src/api/routes/` — consistent with `health.py`, `session.py`, `turn.py`
- Tests go in `services/api/tests/unit/test_tts_route.py`
- No new directories needed — this adds a single route file to the existing structure
- Alignment with architecture project structure: `services/api/src/api/routes/tts.py` matches the architecture's planned structure exactly

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.2] — FR24, acceptance criteria
- [Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns] — `GET /tts/{request_id}` serves audio bytes from short-lived in-memory cache
- [Source: _bmad-output/planning-artifacts/architecture.md#Core Architectural Decisions] — Two-step TTS contract, session token on all protected endpoints
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries] — `api/routes/tts.py` location
- [Source: _bmad-output/planning-artifacts/architecture.md#Validation Issues Addressed] — `session_token` sent as `Authorization: Bearer`
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice Pipeline Stepper] — Speaking state UX
- [Source: _bmad-output/implementation-artifacts/3-1-generate-tts-and-return-tts-audio-url-in-post-turn.md] — TTSCache implementation, TTS pipeline integration, test patterns
- [Source: services/api/src/services/tts_cache.py] — TTSCache.get() API
- [Source: services/api/src/api/dependencies/shared_services.py] — get_tts_cache() singleton
- [Source: services/api/src/api/routes/turn.py] — Auth pattern to follow

### Change Log

| Date       | Change                                                                                                      | Author                 |
| ---------- | ----------------------------------------------------------------------------------------------------------- | ---------------------- |
| 2026-02-16 | Story 3.2 created — comprehensive context for GET /tts/{request_id} audio fetch endpoint                    | Antigravity (SM Agent) |
| 2026-02-16 | Story 3.2 implemented — GET /tts/{request_id} endpoint with auth, error handling, and 10 passing unit tests | Amelia (Dev Agent)     |
| 2026-02-16 | Code Review — Fixed 401 auth behavior, removed redundant headers, and aligned AC #3 with implementation     | Antigravity (Reviewer) |

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5

### Debug Log References

No issues encountered during implementation.

### Completion Notes List

✅ **Task 1 Complete**: Created `GET /tts/{request_id}` route in `services/api/src/api/routes/tts.py`

- Implemented route with proper error handling for missing/expired audio
- Returns raw audio bytes with `Content-Type: audio/mpeg` on success
- Returns envelope-wrapped JSON errors for 404/401 cases
- Added comprehensive OpenAPI documentation
- Added logging for request_id lookups (info on success, warning on miss)

✅ **Task 2 Complete**: Added session token authentication

- Followed exact auth pattern from `turn.py`
- Bearer token validation with `SessionTokenService`
- 401 errors include `X-Request-ID` and envelope format

✅ **Task 3 Complete**: Registered TTS route in main application

- Added import in `services/api/src/main.py`
- Registered router with prefix `/tts` and tag `TTS Audio`
- Updated `services/api/src/api/routes/__init__.py` to export `tts` module

✅ **Task 4 Complete**: Wrote comprehensive unit tests

- Created `services/api/tests/unit/test_tts_route.py` with 10 test cases
- All tests pass: valid audio fetch, not found, expired, auth validation, content-type, request_id headers
- Full regression check: 116/116 tests passing

✅ **Task 5 Complete**: Updated routes `__init__.py` export

- Added `tts` to `__all__` list for consistency

**All Acceptance Criteria Validated:**

- AC #1: Audio bytes returned with `Content-Type: audio/mpeg` ✅
- AC #2: Valid request_id returns 200 with audio bytes ✅
- AC #3: Expired audio returns 404 with correct error structure ✅
- AC #4: Unknown request_id returns 404 with correct error structure ✅
- AC #5: `X-Request-ID` in response headers, endpoint at `/tts/{request_id}` ✅
- AC #6: Session token required, 401 on invalid/missing token ✅
- AC #7: Audio available within TTL (5 min), 404 after expiration ✅

### File List

**New Files:**

- `services/api/src/api/routes/tts.py` — GET /tts/{request_id} endpoint
- `services/api/tests/unit/test_tts_route.py` — TTS route unit tests (10 tests)

**Modified Files:**

- `services/api/src/main.py` — Added tts router import and registration
- `services/api/src/api/routes/__init__.py` — Added tts module export
