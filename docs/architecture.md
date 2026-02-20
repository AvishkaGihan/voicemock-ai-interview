---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
  - docs/voicemock-prd-brief.md
  - _bmad-output/planning-artifacts/prd.validation-report.md
  - _bmad-output/planning-artifacts/ux.validation-report.md
workflowType: 'architecture'
project_name: 'voicemock-ai-interview'
user_name: 'AvishkaGihan'
date: '2026-01-27'
lastStep: 8
status: 'complete'
completedAt: '2026-01-27'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (architectural implications):**

- Voice interview session flow with deterministic turn-taking: Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready
- Push-to-talk audio capture with strict concurrency rules (never record while speaking; never overlap TTS)
- Transcript “trust layer” after each turn (show transcript, allow retry/re-record)
- Follow-up question generation based on the user’s last answer (session state must persist across turns)
- End-of-session coaching summary across the whole session (needs per-turn data aggregation)
- Error recovery UX that is stage-aware (upload/STT/LLM/TTS) and always provides Retry/Cancel + a request ID
- Admin/demo diagnostics view (request IDs, provider selection, per-stage timing metrics, last error)

**Non-Functional Requirements (architecture shapers):**

- Conversational latency targets (P50 < 3s, P95 < 5s end-of-user-speech → start-of-system-speech)
- Resilience: no “stuck thinking”; timeouts + explicit user actions when thresholds exceeded
- Privacy-by-default: minimize persistence of raw audio; encrypt in transit; avoid sensitive logging; provide delete controls
- Accessibility: voice-first but not voice-only (all spoken output has text equivalents; semantic labels; AA-minded)
- Cost efficiency: configurable providers and usage limits to preserve free-tier demo viability

**Scale & Complexity:**

- Primary domain: Mobile app + API backend orchestration
- Complexity level: Medium
- Estimated architectural components: ~7–9
  - Mobile UI + audio capture/playback + state machine
  - Backend API (session/turn endpoints)
  - Orchestrator pipeline (STT → LLM → TTS)
  - Provider adapters (STT/LLM/TTS abstraction)
  - Storage for minimal session artifacts (transcript/summary; audio optional/off by default)
  - Observability (request IDs, timing metrics, structured logs)
  - Configuration (provider selection, limits, debug mode)

### Technical Constraints & Dependencies

- Third-party AI services for STT/LLM/TTS (provider abstraction needed to swap vendors and control cost/latency)
- Strict turn-taking rules to prevent overlapping audio and confusing UI states
- Mobile permission and interruption handling (mic permission, audio focus, backgrounding/calls)
- Network variability (must degrade gracefully with actionable recovery)

### Cross-Cutting Concerns Identified

- State machine correctness (single source of truth across UI + backend turn lifecycle)
- Latency instrumentation and end-to-end tracing (per-stage timings tied to request IDs)
- Privacy/data minimization and retention defaults (esp. raw audio)
- Error taxonomy aligned to UX (stage-specific failure states + deterministic retries)
- Accessibility/text alternatives for all voice output
- Cost controls (rate limits, provider fallback strategy, usage caps)

## Starter Template Evaluation

### Primary Technology Domain

- Mobile-first: Flutter (Android-first MVP)
- Backend orchestration: FastAPI (Python) deployed via Docker on Render.com
- Data/Auth: guest-only; ephemeral sessions; no database in MVP
- AI providers (speed stack): Deepgram Nova-2 (STT), Groq Llama 3 (LLM), Deepgram Aura (TTS)

### Starter Options Considered (Mobile)

**Option A: Official Flutter template (minimal, least opinionated)**

- Initialization command:

```bash
flutter create --platforms=android voicemock
```

- Strengths: minimal baseline; easiest to tailor for low-level audio capture/playback, permissions, and audio-focus rules.
- Trade-offs: requires us to choose and enforce project structure, state management, DI, linting, and testing conventions.

**Option B: Very Good Flutter App (structured foundation)**

- Tooling verified (Jan 2026): `very_good_cli 0.28.0`
- Initialization commands:

```bash
dart pub global activate very_good_cli
very_good create flutter_app voicemock --org com.voicemock --desc "VoiceMock AI Interview Coach"
```

- Strengths: strong defaults for structure, linting, and testing; reduces architectural drift while iterating on audio latency.
- Trade-offs: more opinionated than the official template (we must align our state machine and audio layer to its structure).

### Starter Options Considered (Backend)

**Option A: Render FastAPI example (reference for platform conventions)**

- Render’s current guidance uses:
  - Build: `pip install -r requirements.txt`
  - Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
- Strengths: matches Render’s expectations (especially `$PORT`).
- Trade-offs: guide targets Render’s native Python runtime; we still want Docker parity.

**Option B: Full-stack FastAPI template (rejected for MVP)**

- Trade-offs: forces Postgres/auth/admin/frontend concerns that conflict with guest-only + no-DB MVP.

**Option C: Minimal FastAPI skeleton + Dockerfile (purpose-built for MVP)**

- Versions verified (Jan 2026):
  - FastAPI `0.128.0`
  - Uvicorn `0.40.0`
  - Pydantic `2.12.5`
  - Deepgram SDK `5.3.1`
  - Groq SDK `1.0.0`
- Strengths: aligns with low-latency orchestration and ephemeral session storage; minimal moving parts.
- Trade-offs: we must explicitly add observability (request IDs + timing metrics), structured error taxonomy, and tight timeouts.

### Selected Starter(s)

**Mobile Starter: Very Good Flutter App**

- Rationale: provides a consistent, testable structure while we focus on Android audio performance and the deterministic state machine.
- Initialization command:

```bash
dart pub global activate very_good_cli
very_good create flutter_app voicemock --org com.voicemock --desc "VoiceMock AI Interview Coach"
```

**Backend Starter: Minimal FastAPI + Docker (Render-compatible)**

- Rationale: avoids unwanted DB/auth scaffolding; optimizes for low-latency request orchestration and “wow factor” demo flow.
- Runtime contract (Render): bind to `$PORT` and `0.0.0.0`.
- Start command (container entrypoint):

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**

- Session state model: guest-only, server-authoritative in-memory sessions with TTL (hybrid client/server)
- Session security: server-issued session token required on all turn requests
- Turn API contract: two-step per turn (JSON response + short-lived TTS fetch URL)
- Mobile state machine: explicit interview flow state machine implemented with `flutter_bloc`
- Deployment assumption: single backend instance (required for in-memory session store MVP)

**Important Decisions (Shape Architecture):**

- Rate limiting strategy: FastAPI/Starlette rate limiting via `slowapi 0.1.9` (memory backend in MVP)
- Settings management: `pydantic-settings 2.12.0` for environment configuration
- Optional tracing path: OpenTelemetry (`opentelemetry-sdk 1.39.1`, `opentelemetry-instrumentation-fastapi 0.60b1`, `opentelemetry-exporter-otlp 1.39.1`)

**Deferred Decisions (Post-MVP):**

- Database (sessions, transcripts, summaries) and any migration strategy
- Real authentication (login) and authorization roles
- Multi-instance scaling (would require shared session store like Redis)
- Streaming architecture (SSE/WebSocket) for partial STT/LLM/TTS
- Canonical JSON naming conventions and client/server DTO mapping rules (handled in Step 5 patterns)

### Data Architecture

- **Storage approach:** Hybrid (server authoritative in-memory session store with client `session_id`)
- **Session identifier:** server-generated UUID returned by `POST /session/start`
- **Session retention:** TTL-based expiration (default: 60 minutes idle)
- **Artifacts stored (MVP, in-memory):** per-turn transcript, assistant text, per-stage timings, last error, end-of-session summary
- **Audio retention:** no persistence of raw audio by default; only transient upload handling
- **Validation strategy:** Pydantic models for request/response + internal `SessionState` and `TurnState` models

### Authentication & Security

- **Auth model:** guest-only with server-issued session token
- **Token requirement:** all turn endpoints require `session_id` + `session_token`
- **Token mechanism (MVP default):** signed opaque token (e.g., `itsdangerous 2.2.0`) including `{session_id, iat, exp}`
  - Alternative supported if desired: JWT HS256 (`PyJWT 2.10.1`)
- **Abuse controls:**
  - Rate limit high-cost endpoints (turn, TTS) via `slowapi 0.1.9`
  - Constrain request sizes (max audio upload size) and strict timeouts per pipeline stage
  - Log redaction: never log raw audio; minimize transcript logging; include request IDs for support

### API & Communication Patterns

- **API style:** REST over HTTPS, documented via FastAPI OpenAPI
- **Turn contract:** Option 2 (two-step)
  - `POST /session/start` → `{session_id, session_token}`
  - `POST /turn` (multipart upload via `python-multipart 0.0.22`) → JSON:
    - `transcript`, `assistant_text`, `request_id`, `timings`, `tts_audio_url`
  - `GET /tts/{request_id}` → serves audio bytes from short-lived in-memory cache
- **Error handling standard (stage-aware, UX-aligned):**
  - `{ error: { stage, code, message_safe, retryable, request_id } }`
  - Every error response must include `request_id`
- **Observability contract:** return per-stage timings in the turn response; log timing + error metadata keyed by `request_id`

### Frontend Architecture

- **State management:** `flutter_bloc 9.1.1` (aligns with Very Good Flutter App conventions)
- **Routing:** `go_router 17.0.1`
- **Interview flow state machine:** single source of truth for:
  - Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready (+ Error)
  - Strict concurrency: never record while speaking; never overlap TTS
- **Audio stack (versions previously verified):**
  - Recording: `record 6.1.2`
  - Playback: `just_audio 0.10.5`
  - Audio focus/interruptions: `audio_session 0.2.2`

### Infrastructure & Deployment

- **Hosting:** Render.com
- **Deployment:** Docker-based, `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Runtime topology (MVP):** single instance
  - Rationale: in-memory sessions and in-memory TTS cache
  - Implication: session loss on restart is acceptable in MVP
- **Environment configuration:** `pydantic-settings 2.12.0` for provider keys, timeouts, limits, debug flags
- **Monitoring/logging:** structured logs with request ID + timing metrics; optional OpenTelemetry path as above

### Decision Impact Analysis

**Implementation Sequence:**

- Define API contracts + error taxonomy + request ID propagation
- Implement server session store (TTL) + token issuance/verification
- Implement `POST /turn` orchestration pipeline (STT → LLM → TTS) with strict timeouts
- Implement TTS cache + `GET /tts/{request_id}`
- Implement Flutter interview state machine (Cubit/Bloc) enforcing no-overlap audio rules
- Add rate limiting + payload limits + logging/redaction

**Cross-Component Dependencies:**

- Mobile and backend must share the same lifecycle semantics for session/turn IDs and error `stage` values
- Two-step TTS fetch requires the mobile app to treat audio playback as an explicit “Speaking” stage driven by `tts_audio_url`
- Single-instance constraint must be maintained until a shared session store is introduced

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 5 areas where AI agents could make different choices and break integration

- API field naming + response envelopes
- Error taxonomy + pipeline stage mapping
- Request ID propagation + logging correlation
- Flutter feature structure + Cubit state machine conventions
- Endpoint naming + payload contracts (multipart vs JSON)

### Naming Patterns

**API Naming Conventions:**

- Endpoints use REST nouns and `snake_case` path segments.
- Recommended endpoints:
  - `POST /session/start`
  - `POST /turn`
  - `GET /tts/{request_id}`
- Headers:
  - Server MUST generate and return `X-Request-ID` on every response (success and error).

**JSON Field Naming Conventions (Backend):**

- All JSON fields are `snake_case`.
- IDs are `*_id` (e.g., `session_id`, `request_id`, `turn_id` if added later).
- Booleans are true/false JSON booleans.
- Timestamps (if returned) use ISO-8601 strings in UTC (e.g., `2026-01-27T12:34:56Z`).

**Code Naming Conventions (Flutter):**

- Dart identifiers follow standard lowerCamelCase.
- Feature folder names use `snake_case` to match VGV conventions where applicable.
- Cubit naming:
  - `InterviewCubit`
  - `InterviewState` variants represent the state machine stages.

### Structure Patterns

**Backend Project Organization (FastAPI):**

- Separate orchestration from provider integrations:
  - `api/` (routes + request/response models)
  - `services/` (orchestrator pipeline: STT → LLM → TTS)
  - `providers/` (Deepgram/Groq adapters)
  - `domain/` (session/turn state models)
  - `observability/` (request id middleware, timers, logging redaction)

**Flutter Project Organization (Very Good Flutter App):**

- Feature-first structure:
  - `lib/features/interview/` is the primary vertical slice for the MVP
  - Inside each feature, use “presentation/domain/data” separation when helpful, but keep it pragmatic
- Place state machine in feature layer:
  - `lib/features/interview/presentation/cubit/interview_cubit.dart`
  - `lib/features/interview/presentation/cubit/interview_state.dart`

### Format Patterns

**API Response Formats (Wrapped):**

- All non-audio JSON responses use a consistent wrapper:
  - Success:
    - `{ "data": <payload>, "error": null, "request_id": "<id>" }`
  - Error:
    - `{ "data": null, "error": <error_obj>, "request_id": "<id>" }`

**Turn Response Payload (inside `data`):**

- `transcript` (string)
- `assistant_text` (string)
- `tts_audio_url` (string URL, short-lived)
- `timings` (object of stage timings; `snake_case` fields)
  - Example keys: `upload_ms`, `stt_ms`, `llm_ms`, `tts_ms`, `total_ms`

**Error Object Format (inside `error`):**

- `stage`: one of `upload | stt | llm | tts | unknown`
- `code`: stable machine string (e.g., `stt_timeout`, `provider_error`, `invalid_audio`)
- `message_safe`: user-safe message (no secrets/provider dumps)
- `retryable`: boolean
- `details` (optional): non-sensitive structured metadata for debugging

### Communication Patterns

**Request ID & Correlation Rules:**

- Backend MUST:
  - Generate `X-Request-ID` per request if missing
  - Echo `X-Request-ID` in response headers
  - Include `request_id` in the JSON wrapper body
  - Log `request_id`, `session_id`, `stage`, `code`, and timings
- Client MAY:
  - Display `request_id` in error UI and include it in “report issue” UX

**State Management Patterns (Interview Flow):**

- Single source of truth: `InterviewCubit` owns the interview state machine:
  - Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready (+ Error)
- Hard constraints enforced in Cubit transitions:
  - Never record while in Speaking
  - Never play TTS while in Recording
- UI must render solely from Cubit state; no parallel local “bool flags” that can drift.

### Process Patterns

**Error Handling Patterns:**

- Stage-aware errors must map 1:1 to UX retry points:
  - Upload errors retry upload
  - STT errors retry transcription or re-record
  - LLM errors retry generation (optionally re-use transcript)
  - TTS errors retry synthesis (optionally re-use assistant_text)
- Always show the `request_id` in error UI and logs.

**Loading State Patterns:**

- Each non-idle stage is considered a loading state with a specific UI copy:
  - Uploading: progress/“Uploading…”
  - Transcribing: “Transcribing…”
  - Thinking: “Thinking…”
  - Speaking: playback controls/visualizer
- Never show a generic spinner without stage context.

### Enforcement Guidelines

**All AI Agents MUST:**

- Use `snake_case` for all backend JSON fields and timing keys.
- Use wrapped JSON responses with `{data, error, request_id}` on all JSON endpoints.
- Ensure `X-Request-ID` is present on every response and echoed into JSON wrapper body.
- Implement interview flow using `InterviewCubit` with explicit state variants and strict no-overlap rules.
- Keep Flutter structure feature-first and place state machine under the interview feature.

### Pattern Examples

**Good Examples:**

- Success response:
  - `{ "data": { "transcript": "...", "assistant_text": "...", "tts_audio_url": "...", "timings": { "stt_ms": 820 } }, "error": null, "request_id": "..." }`
- Error response:
  - `{ "data": null, "error": { "stage": "stt", "code": "stt_timeout", "message_safe": "Transcription timed out. Please try again.", "retryable": true }, "request_id": "..." }`

**Anti-Patterns:**

- Mixing `camelCase` and `snake_case` in backend responses
- Returning raw provider exception strings to clients
- Client generating request IDs or displaying “unknown error” without a stage
- Flutter UI managing “isRecording” booleans outside the Cubit state machine

## Project Structure & Boundaries

### Complete Project Directory Structure

```
voicemock-ai-interview/
├── README.md
├── .gitignore
├── .editorconfig
├── .env.example
├── docs/
│   ├── voicemock-prd-brief.md
│   ├── api/
│   │   ├── openapi.snapshot.yaml
│   │   ├── examples/
│   │   │   ├── session_start.response.json
│   │   │   ├── turn.response.success.json
│   │   │   └── turn.response.error.json
│   │   └── error-taxonomy.md
│   ├── architecture/
│   │   └── decision-log.md
│   └── runbooks/
│       ├── render-deploy.md
│       └── troubleshooting.md
├── contracts/
│   ├── api/
│   │   ├── stages.md
│   │   ├── codes.md
│   │   └── headers.md
│   └── naming/
│       ├── json-snake-case.md
│       └── response-envelope.md
├── apps/
│   └── mobile/
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       ├── android/
│       ├── assets/
│       │   ├── images/
│       │   └── audio/
│       ├── lib/
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   └── view/
│       │   │       └── app_view.dart
│       │   ├── bootstrap.dart
│       │   ├── main_development.dart
│       │   ├── main_production.dart
│       │   ├── core/
│       │   │   ├── http/
│       │   │   │   ├── api_client.dart
│       │   │   │   ├── request_id_interceptor.dart
│       │   │   │   └── api_errors.dart
│       │   │   ├── audio/
│       │   │   │   ├── recording_service.dart
│       │   │   │   ├── playback_service.dart
│       │   │   │   └── audio_session_service.dart
│       │   │   ├── models/
│       │   │   │   ├── api_envelope.dart
│       │   │   │   ├── session_models.dart
│       │   │   │   └── turn_models.dart
│       │   │   └── logging/
│       │   │       └── redacted_logger.dart
│       │   └── features/
│       │       └── interview/
│       │           ├── data/
│       │           │   ├── interview_repository.dart
│       │           │   └── dto/
│       │           │       ├── session_start_dto.dart
│       │           │       └── turn_dto.dart
│       │           ├── domain/
│       │           │   ├── interview_stage.dart
│       │           │   └── interview_failure.dart
│       │           └── presentation/
│       │               ├── cubit/
│       │               │   ├── interview_cubit.dart
│       │               │   └── interview_state.dart
│       │               ├── view/
│       │               │   ├── interview_page.dart
│       │               │   └── interview_view.dart
│       │               └── widgets/
│       │                   ├── push_to_talk_button.dart
│       │                   ├── transcript_trust_layer.dart
│       │                   └── speaking_player.dart
│       └── test/
│           ├── core/
│           └── features/
│               └── interview/
├── services/
│   └── api/
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── requirements.txt
│       ├── .env.example
│       ├── src/
│       │   ├── main.py
│       │   ├── api/
│       │   │   ├── routes/
│       │   │   │   ├── health.py
│       │   │   │   ├── session.py
│       │   │   │   ├── turn.py
│       │   │   │   └── tts.py
│       │   │   ├── models/
│       │   │   │   ├── envelope.py
│       │   │   │   ├── session_models.py
│       │   │   │   ├── turn_models.py
│       │   │   │   └── error_models.py
│       │   │   └── dependencies/
│       │   │       └── request_context.py
│       │   ├── domain/
│       │   │   ├── session_state.py
│       │   │   ├── turn_state.py
│       │   │   └── stages.py
│       │   ├── services/
│       │   │   ├── orchestrator.py
│       │   │   ├── session_store.py
│       │   │   └── tts_cache.py
│       │   ├── providers/
│       │   │   ├── stt_deepgram.py
│       │   │   ├── llm_groq.py
│       │   │   └── tts_deepgram.py
│       │   ├── observability/
│       │   │   ├── request_id_middleware.py
│       │   │   ├── timing.py
│       │   │   └── logging.py
│       │   ├── security/
│       │   │   ├── session_token.py
│       │   │   └── rate_limit.py
│       │   └── settings/
│       │       └── config.py
│       └── tests/
│           ├── unit/
│           └── integration/
├── .github/
│   └── workflows/
│       ├── mobile_ci.yml
│       └── api_ci.yml
└── _bmad-output/
    ├── planning-artifacts/
    └── implementation-artifacts/
```

### Architectural Boundaries

**API Boundaries:**

- Public REST API lives in `services/api/src/api/routes/`
  - `session.py`: session start + token issuance
  - `turn.py`: multipart upload + orchestration entrypoint
  - `tts.py`: short-lived audio fetch endpoint
  - `health.py`: `/healthz` and basic diagnostics
- Request/response schema lives in `services/api/src/api/models/`
- No business logic in route handlers beyond input validation + wiring

**Component Boundaries (Mobile):**

- Feature-first modules live under `apps/mobile/lib/features/`
- Interview state machine lives ONLY in:
  - `apps/mobile/lib/features/interview/presentation/cubit/`
- Audio IO lives ONLY in:
  - `apps/mobile/lib/core/audio/`
- Networking + envelope parsing lives ONLY in:
  - `apps/mobile/lib/core/http/`

**Service Boundaries (Backend):**

- `services/api/src/services/` owns orchestration and state mutation
- `services/api/src/providers/` owns vendor SDK calls (Deepgram/Groq)
- `services/api/src/security/` owns token verification and rate limiting integration
- `services/api/src/observability/` owns request ID + timing + logging/redaction
- `services/api/src/domain/` owns canonical stage enums and state structures

### Requirements to Structure Mapping

**FR Category: Deterministic interview flow + strict audio concurrency**

- Mobile:
  - `apps/mobile/lib/features/interview/presentation/cubit/` (state machine + guards)
  - `apps/mobile/lib/core/audio/` (record/playback/audio focus)
- Backend:
  - `services/api/src/services/orchestrator.py` (pipeline sequencing + timeouts)

**FR Category: Transcript trust layer (review + retry/re-record)**

- Mobile:
  - `apps/mobile/lib/features/interview/presentation/widgets/transcript_trust_layer.dart`
  - `apps/mobile/lib/features/interview/presentation/view/`
- Backend:
  - `services/api/src/services/session_store.py` (stores transcript per turn)

**FR Category: Follow-up question generation**

- Backend:
  - `services/api/src/providers/llm_groq.py`
  - `services/api/src/services/orchestrator.py`

**FR Category: End-of-session coaching summary**

- Backend:
  - `services/api/src/services/session_store.py` (turn aggregation)
  - `services/api/src/services/orchestrator.py` (summary generation call)

**FR Category: Error recovery UX (stage-aware, retryable, request ID)**

- Backend:
  - `services/api/src/api/models/error_models.py` (stage-aware contract)
  - `services/api/src/observability/request_id_middleware.py`
- Mobile:
  - `apps/mobile/lib/core/http/api_errors.dart` (maps error contract to UI)
  - `apps/mobile/lib/features/interview/domain/interview_failure.dart`

**FR Category: Admin/demo diagnostics view**

- Backend:
  - `services/api/src/api/routes/health.py` (health + minimal diagnostics)
  - `services/api/src/observability/timing.py` (durations)
- Mobile:
  - Add `apps/mobile/lib/features/diagnostics/` later (post-MVP or MVP-lite)

### Integration Points

**Internal Communication:**

- Mobile ↔ Backend via REST:
  - `POST /session/start`
  - `POST /turn` (multipart audio upload)
  - `GET /tts/{request_id}`

**External Integrations:**

- Deepgram STT: `services/api/src/providers/stt_deepgram.py`
- Groq LLM: `services/api/src/providers/llm_groq.py`
- Deepgram TTS: `services/api/src/providers/tts_deepgram.py`

**Data Flow:**

- Mobile records audio → `POST /turn` upload → backend orchestrates STT→LLM→TTS → returns wrapped JSON (`tts_audio_url`) → mobile fetches audio → plays audio → returns to Ready

### File Organization Patterns

**Configuration Files:**

- Root `.env.example` documents required env vars at the system level
- Backend-specific `.env.example` under `services/api/` for Render/Docker parity
- Mobile env handled via compile-time flavors/build-time config (kept out of Git)

**Test Organization:**

- Mobile tests under `apps/mobile/test/` feature-first
- Backend tests under `services/api/tests/` split into `unit/` and `integration/`

### Development Workflow Integration

**Development Server Structure:**

- Backend runs from `services/api/` (Docker or local venv)
- Mobile runs from `apps/mobile/` (Flutter)

**Build/Deploy Structure:**

- Render deploy targets `services/api/` Dockerfile
- CI runs mobile and api workflows independently (but within the monorepo)

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**

- Flutter (VGV + `flutter_bloc` + `go_router`) aligns with deterministic state-machine requirements and the two-step TTS fetch.
- FastAPI + Docker on Render aligns with single-instance MVP assumptions and in-memory session/TTS caches.
- Provider stack (Deepgram STT/TTS + Groq LLM) is coherent with the orchestrator pipeline pattern.

**Pattern Consistency:**

- `snake_case` + wrapped envelope + `X-Request-ID` rules are clear enough to prevent most integration drift.
- Clarification required to eliminate ambiguity: all JSON endpoints always return `{data, error, request_id}`, and the stage-aware error object is nested under the wrapper’s `error` field.

**Structure Alignment:**

- Monorepo layout supports the chosen boundaries (`apps/mobile` vs `services/api`) and keeps shared semantics in `contracts/` + `docs/`.
- Backend separation (routes/services/providers/domain/security/observability) matches the decisions and encourages clean implementations.

### Requirements Coverage Validation ✅

**Epic/Feature Coverage:**

- Deterministic flow + strict audio concurrency: covered by `InterviewCubit` state machine + audio module boundaries.
- Transcript trust layer: explicitly supported by UI widgets and the in-memory session store.
- Follow-up question generation + end-of-session coaching summary: supported via orchestrator + per-session turn aggregation.
- Stage-aware error recovery + request IDs: supported via error taxonomy + request ID rules and client mapping.
- Admin/demo diagnostics view: minimally supported (health + timing + request IDs); dedicated diagnostics feature can be added later.

**Non-Functional Requirements Coverage:**

- Latency targets: addressed via per-stage timings; enforceable defaults (timeouts) still need to be pinned down.
- Resilience (no “stuck thinking”): addressed conceptually (timeouts + explicit user actions); implementers should codify timeouts and cancellation paths.
- Privacy-by-default: supported (no raw audio persistence by default; redacted logs; minimal transcript logging).
- Cost controls: supported by rate limiting + payload limits + provider selection hooks (final cap defaults remain to be specified).

### Implementation Readiness Validation ✅

**Decision Completeness:**

- Most critical decisions are documented strongly enough to guide multiple agents.
- Remaining implementation-risk is mainly where “defaults” could diverge (timeout values, payload limits) and where credential transport must be consistent.

**Structure Completeness:**

- Directory structure is specific and maps requirements to code locations.
- Integration points are clearly named: `POST /session/start`, `POST /turn`, `GET /tts/{request_id}`.

**Pattern Completeness:**

- Response envelope + stage-aware errors + request IDs form a strong contract.
- Remaining drift points are resolved by explicitly locking credential transport, TTLs, and timeout defaults.

### Gap Analysis Results

**Critical Gaps (confirm before implementation):**

1. **Session credential transport**: define exactly where `session_id` + `session_token` are sent for multipart and TTS fetch.
2. **Envelope precedence**: explicitly state wrapper is always used and error is always nested at `error`.

**Important Gaps (reduce churn):**

- Default timeout policy per pipeline stage + total request timeout behavior.
- Explicit TTLs for TTS cache and `tts_audio_url` validity window.
- Payload limits (max audio upload size/duration) to constrain abuse and cost.

### Validation Issues Addressed

To eliminate drift, adopt these defaults:

- `session_token` is sent as `Authorization: Bearer <session_token>` on all protected endpoints (`POST /turn`, `GET /tts/{request_id}`).
- `session_id` is sent as a multipart form field `session_id` on `POST /turn`.
- All JSON endpoints return `{ "data": ..., "error": ..., "request_id": ... }`; the stage-aware error object is always the wrapper’s `error`.

### Architecture Completeness Checklist

**✅ Requirements Analysis**

- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**✅ Architectural Decisions**

- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed (timings + instrumentation path)

**✅ Implementation Patterns**

- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**✅ Project Structure**

- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

## Architecture Completion & Handoff

### What We Finalized

- Guest-only MVP with server-authoritative in-memory sessions (TTL) and a server-issued session token.
- Two-step turn contract: `POST /turn` returns JSON (text + `tts_audio_url`), audio fetched separately via `GET /tts/{request_id}`.
- Strict mobile interview state machine implemented via `InterviewCubit` (`flutter_bloc`) with no-overlap audio rules.
- Consistency rules: `snake_case`, wrapped JSON responses `{data, error, request_id}`, server-generated `X-Request-ID` echoed in headers and body.
- Monorepo structure and clear module boundaries across mobile and API.

### Next Steps (Recommended)

- Run **Check Implementation Readiness (IR)** to ensure PRD + UX + Architecture are fully aligned before implementation.
  - Command: `IR` (Architect)
- Optional: Run **Validate Architecture (VA)** for a second-pass validation report.
  - Command: `VA` (Architect)

If you want, the next practical step after IR is to start implementation by scaffolding the monorepo folders and generating the FastAPI + Flutter skeletons consistent with this document.
