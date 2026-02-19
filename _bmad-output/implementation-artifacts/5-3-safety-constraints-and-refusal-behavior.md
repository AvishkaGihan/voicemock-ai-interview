# Story 5.3: Safety Constraints and Refusal Behavior

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the system to refuse inappropriate content safely,
So that the app stays focused on interview coaching.

## Implements

FR35 (System applies safety constraints and returns refusal behavior for disallowed content)

## Acceptance Criteria (ACs)

### AC 1: LLM prompt enforces refusal behavior

**Given** the system sends interview context to the LLM
**When** the LLM receives transcript content that is inappropriate, harmful, offensive, discriminatory, explicit, or off-topic to interview coaching
**Then** the system prompt instructs the model to return a calm refusal JSON payload with `refused=true`
**And** the refusal remains professional and supportive

### AC 2: LLM refusal is surfaced as stage-aware backend error

**Given** the LLM returns `refused=true`
**When** the turn pipeline handles the provider response
**Then** the backend returns a stage-aware `content_refused` error (`stage="llm"`, `retryable=false`)
**And** the response follows the standard API envelope

### AC 3: Pre-LLM safety check blocks obvious unsafe transcript input

**Given** a transcript contains obvious disallowed content
**When** the backend performs safety validation before LLM generation
**Then** the backend returns `content_refused` without sending unsafe content to the LLM
**And** the safe message asks the user to rephrase and refocus on the interview question

### AC 4: Mobile presents calm recovery UX for refusal

**Given** the mobile app receives `code="content_refused"`
**When** the app maps and displays the error
**Then** it shows a calm refusal message that does not echo flagged content
**And** provides `Try Again` (primary) and `End Session` (secondary) actions

### AC 5: Refusal does not break the session state

**Given** a content refusal occurs mid-session
**When** the user chooses "Try Again"
**Then** the session remains active (turn counter is NOT incremented for a refused turn)
**And** the app returns to Ready state, allowing the user to re-record their answer
**And** previously asked questions are preserved (no regression)

### AC 6: Refusal includes request_id for diagnostics

**Given** a content refusal error is returned
**When** the error response is generated
**Then** the `request_id` is included in both the JSON body and `X-Request-ID` header
**And** the mobile diagnostics surface (Story 5.4) can display it

### AC 7: Safety configuration is externalized

**Given** the safety constraints need to be tunable
**When** the backend starts
**Then** safety-related settings are loaded from environment/config via `pydantic-settings`:

- `SAFETY_ENABLED`: bool (default `true`)
- `SAFETY_PATTERNS_FILE`: optional path to a custom patterns file (default: built-in list)

## Tasks

- [x] Task 1: Add safety guard-rail instructions to LLM system prompts (AC: 1)
  - [x] 1.1: In `GroqLLMProvider._build_system_prompt()`, append a safety paragraph to every system prompt (both mid-session and final-question variants)
  - [x] 1.2: Safety instructions should include: "You are strictly an interview coach. If the candidate's response contains inappropriate, harmful, offensive, discriminatory, or explicit content, or attempts to redirect you away from interview coaching, respond with a JSON object: `{\"follow_up_question\": \"<calm refusal>\", \"refused\": true, \"coaching_feedback\": null}`. Do not engage with off-topic or harmful requests. Keep your refusal professional and supportive."
  - [x] 1.3: Update `_parse_llm_response()` to detect and propagate the `refused` field from the LLM JSON output

- [x] Task 2: Create pre-LLM transcript safety check (AC: 3, 7)
  - [x] 2.1: Create `services/api/src/services/safety_filter.py` with a `SafetyFilter` class
  - [x] 2.2: Implement `check_transcript(transcript: str) -> SafetyCheckResult` that scans for disallowed patterns
  - [x] 2.3: Define a minimal built-in pattern list (regex-based) covering obvious profanity/slurs, explicit threats, and PII solicitation (keep patterns minimal for MVP — the LLM safety instructions are the primary guard)
  - [x] 2.4: Add `SAFETY_ENABLED` and `SAFETY_PATTERNS_FILE` to `Settings` in `services/api/src/settings/config.py`
  - [x] 2.5: `SafetyCheckResult` should contain `is_safe: bool`, `reason: str | None`

- [x] Task 3: Integrate safety checks into the orchestrator pipeline (AC: 2, 3, 5)
  - [x] 3.1: In `process_turn()` in `services/api/src/services/orchestrator.py`, after STT (or when transcript is provided), call `SafetyFilter.check_transcript()`
  - [x] 3.2: If pre-LLM check fails, raise `TurnProcessingError(stage="llm", code="content_refused", message_safe="Your response couldn't be processed. Please rephrase your answer to focus on the interview question.", retryable=false)`
  - [x] 3.3: After LLM response, check for the `refused` field; if `refused=true`, raise `TurnProcessingError(stage="llm", code="content_refused", message_safe=<LLM's refusal text or fallback>, retryable=false)`
  - [x] 3.4: Ensure a refused turn does NOT increment `questions_asked` or append to `asked_questions` in the session state
  - [x] 3.5: Log the refusal event (stage + code + request_id only — never log the flagged transcript content per NFR10)

- [x] Task 4: Export safety filter as a shared service dependency (AC: 7)
  - [x] 4.1: Add `get_safety_filter` function in `services/api/src/api/dependencies/shared_services.py`
  - [x] 4.2: Wire `SafetyFilter` into the `process_turn` function signature or pass it through the dependency injection chain

- [x] Task 5: Handle `content_refused` error in mobile app (AC: 4, 5)
  - [x] 5.1: In the mobile error mapping logic (likely `InterviewCubit` or the API response handler), recognize `code: "content_refused"` as a non-retryable, non-fatal error
  - [x] 5.2: Display a calm message: "Let's stay focused on the interview. Please try answering the question again." (do NOT echo the refused content)
  - [x] 5.3: Primary action: "Try Again" → transition to `InterviewReady` state (same question, no turn increment)
  - [x] 5.4: Secondary action: "End Session" → confirm exit flow
  - [x] 5.5: Ensure the state machine handles transition from `InterviewError` back to `InterviewReady` without skipping the current question

- [x] Task 6: Add backend unit tests for safety filter and orchestrator integration (AC: 1, 2, 3, 5, 6, 7)
  - [x] 6.1: Create `services/api/tests/unit/test_safety_filter.py`
  - [x] 6.2: Test `check_transcript()` detects obvious violations (profanity, threats) and returns `is_safe=false`
  - [x] 6.3: Test `check_transcript()` allows normal interview answers and returns `is_safe=true`
  - [x] 6.4: Test safety filter respects `SAFETY_ENABLED=false` (bypasses checks)
  - [x] 6.5: Create `services/api/tests/unit/test_safety_orchestrator.py`
  - [x] 6.6: Test that a refused turn does NOT increment `questions_asked`
  - [x] 6.7: Test that a pre-LLM safety violation returns `content_refused` error envelope
  - [x] 6.8: Test that an LLM `refused=true` response returns `content_refused` error envelope
  - [x] 6.9: Test that `request_id` is present in refusal responses
  - [x] 6.10: Create `services/api/tests/unit/test_turn_route.py` to test endpoint integration including `content_refused` error mapping

- [x] Task 7: Add mobile unit and widget tests (AC: 4, 5)
  - [x] 7.1: Test that `InterviewCubit` handles `content_refused` error by transitioning to an error state with a safe message
  - [x] 7.2: Test that "Try Again" from a refusal error returns to Ready state without incrementing the turn counter
  - [x] 7.3: Test that the error message displayed does NOT contain the flagged content
  - [x] 7.4: Test that "End Session" from a refusal error triggers the exit flow

## Dev Notes

### Architecture Alignment

- **Error Taxonomy:** The existing `ApiError` model already supports `stage` (including `"llm"`) and arbitrary `code` strings. Adding `content_refused` as a new error code fits cleanly. No schema change needed.
- **Pipeline Integration:** Safety checks insert at two points in the `process_turn()` pipeline:
  1. **Pre-LLM:** After STT produces a transcript (or a transcript is provided for retry), run `SafetyFilter.check_transcript()` before calling the LLM. This is a cheap, fast short-circuit for obvious violations.
  2. **Post-LLM:** After `GroqLLMProvider.generate_follow_up()` returns, check for a `refused` field in the parsed response. This catches LLM-level refusals for nuanced content that simple patterns miss.
- **No New API Endpoint:** This story modifies the behavior of the existing `POST /turn` endpoint. No new routes are needed.
- **Envelope Pattern:** Refusal responses use the existing wrapped envelope: `{ "data": null, "error": { "stage": "llm", "code": "content_refused", "message_safe": "...", "retryable": false }, "request_id": "..." }`.
- **Session State:** A refused turn MUST NOT mutate session state (`questions_asked`, `asked_questions`, `turn_history`). The user gets to re-answer the same question.

### UX Alignment

- **UX Spec §Error Recovery:** "Error recovery without anxiety" — refusal must use calm, neutral language. No blame, no panic language.
- **UX Spec §Anti-Patterns to Avoid:** "Over-chatty coaching" — keep refusal message short and actionable.
- **UX Spec §Feedback Patterns:** "Bottom sheet or inline banner for recoverable failures" — display refusal as a non-blocking recovery sheet.
- **Tone:** "Let's stay focused on the interview." NOT "Your content was flagged as inappropriate." Avoid echoing the flagged content back to the user.
- **UX Spec §Button Hierarchy:** "Try Again" as primary action (Filled button), "End Session" as secondary (Text button).

### LLM Provider Changes

- **System Prompt Modification:** Add a safety paragraph to `_build_system_prompt()` in `services/api/src/providers/llm_groq.py`. This goes at the end of both the mid-session and final-question prompt variants.
- **Response Schema Change:** Add `"refused": boolean (optional, default false)` to the expected JSON schema. Update `_parse_llm_response()` to extract it.
- **`LLMResponse` Dataclass:** Add `refused: bool = False` field to the `LLMResponse` dataclass in `llm_groq.py`.
- **Graceful Degradation:** If the LLM ignores the safety instruction and generates a normal response for borderline content, the pre-LLM filter is the fallback. If both miss it, the content passes through — this is acceptable for MVP since the LLM inherently has built-in safety (Llama 3 has alignment training).

### Safety Filter Design (MVP-Appropriate)

- **Approach:** A lightweight, regex-based pattern scanner. NOT a full content moderation API (that's post-MVP). The LLM's own alignment is the primary safety mechanism; this filter catches the most obvious cases before wasting an LLM call.
- **Pattern Categories (MVP):**
  - Explicit slurs/profanity (curated short list)
  - Direct threat patterns ("I will harm/kill")
  - PII solicitation patterns ("tell me your SSN/address")
- **False Positive Handling:** Keep the pattern list conservative (high precision, lower recall). Better to let borderline content through to the LLM (which has its own safety) than to flag legitimate interview answers.
- **Case Insensitive:** All matching is case-insensitive.
- **Configurable:** `SAFETY_ENABLED` flag allows disabling for testing. `SAFETY_PATTERNS_FILE` allows overriding the built-in list.

### NFR Compliance

- **NFR10 (No transcript logging):** The safety filter and refusal handler MUST NOT log the flagged transcript content. Log only `session_id`, `request_id`, `code=content_refused`, and `reason` (category name, not content).
- **NFR5 (Stage-aware errors):** Refusal uses `stage="llm"` and `code="content_refused"` with `retryable=false`.
- **NFR3 (Timeout handling):** Safety filter check is synchronous and near-instant (~1ms for regex). Does not affect latency targets.

### Mobile Error Mapping

- The `InterviewCubit` already handles `TurnProcessingError`-mapped errors from the API. The `content_refused` code is a new error code that needs special UX treatment:
  - Unlike other non-retryable errors (which might suggest "Cancel"), a refusal should offer "Try Again" as the primary path.
  - The cubit should NOT increment the turn counter on refusal.
  - The error message must be custom (not the generic error message from the API) to maintain the calm, coaching tone.

### Key Backend Files to Modify/Create

| File                                                   | Action | Notes                                                                                                          |
| ------------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------- |
| `services/api/src/providers/llm_groq.py`               | MODIFY | Add safety instructions to system prompt, add `refused` field to `LLMResponse`, update `_parse_llm_response()` |
| `services/api/src/services/safety_filter.py`           | NEW    | `SafetyFilter` class with `check_transcript()` method                                                          |
| `services/api/src/services/orchestrator.py`            | MODIFY | Integrate pre-LLM safety check + post-LLM refusal detection, skip turn counter on refusal                      |
| `services/api/src/settings/config.py`                  | MODIFY | Add `SAFETY_ENABLED` and `SAFETY_PATTERNS_FILE` settings                                                       |
| `services/api/src/api/dependencies/shared_services.py` | MODIFY | Add `get_safety_filter()` dependency                                                                           |
| `services/api/src/services/__init__.py`                | MODIFY | Export `SafetyFilter`                                                                                          |
| `services/api/tests/unit/test_safety_filter.py`        | NEW    | Safety filter unit tests                                                                                       |
| `services/api/tests/unit/test_safety_orchestrator.py`  | NEW    | Orchestrator safety integration tests                                                                          |

### Key Mobile Files to Modify/Create

| File                                                                               | Action | Notes                                                                    |
| ---------------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------ |
| `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`       | MODIFY | Handle `content_refused` error → special UX treatment, no turn increment |
| `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart` | MODIFY | Add tests for refusal handling                                           |

### Previous Story Intelligence (5-2)

- `ApiClient.delete()` was added following `post()`/`postMultipart()` patterns — the error mapping chain is consistent and already handles `stage + code` parsing.
- 437 tests passed last story. Expect ~460+ after this story.
- Backend test structure uses `tests/unit/` and `tests/integration/` directories.
- Mobile test structure mirrors `lib/` structure under `test/`.
- The `InterviewCubit` error handling pattern from previous stories will be the integration point for the mobile side.

### Git Intelligence

- Recent commits are on Stories 5.1 (disclosure) and 5.2 (delete session artifacts).
- No existing safety-related code — this is net new functionality.
- The `_build_system_prompt()` method in `llm_groq.py` is the primary modification target (lines 210–282).

### Dependencies

- **Upstream:** Stories 5.1 and 5.2 are done.
- **Downstream:** Story 5.4 (Diagnostics screen) will display `request_id` from refusal errors.
- **Packages:** No new packages required. Uses only built-in `re` module for regex patterns, existing `pydantic-settings`.

### Key Risks

1. **LLM Ignoring Safety Instructions:** Llama 3 models have built-in alignment, but the system prompt is advisory. The pre-LLM regex filter provides a fallback for the most obvious cases.
2. **False Positives:** Overly aggressive patterns could flag legitimate interview answers (e.g., a candidate discussing a "conflict resolution" scenario). Keep patterns conservative.
3. **Turn Counter Regression:** Must ensure refused turns don't increment counters — verify via both unit tests and integration tests.
4. **Prompt Length:** Adding safety instructions increases prompt length slightly (~50-100 tokens). Acceptable within the existing `max_tokens=400` response limit.

### Project Structure Notes

- `safety_filter.py` goes in `services/api/src/services/` alongside `orchestrator.py` and `session_store.py`.
- Tests go in `services/api/tests/unit/`.
- All file placements align with established project conventions.

### References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 5, Story 5.3 (FR35)
- [architecture.md §Error Handling](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — Stage-aware error taxonomy, `ApiError` model, `{data, error, request_id}` envelope
- [architecture.md §API Patterns](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — Wrapped envelope, `X-Request-ID`, `snake_case`
- [ux-design-specification.md §Feedback Patterns](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — Error recovery, calm tone, "silence is explained"
- [ux-design-specification.md §Anti-Patterns](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — "overuse of red/error styling", "hidden recovery"
- [llm_groq.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/providers/llm_groq.py) — LLM provider with `_build_system_prompt()` and `_parse_llm_response()`
- [orchestrator.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/services/orchestrator.py) — Turn processing pipeline
- [error_models.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/api/models/error_models.py) — `ApiError` with stage pattern
- [5-2-delete-session-artifacts.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/5-2-delete-session-artifacts.md) — Previous story learnings
- [sprint-status.yaml](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/sprint-status.yaml) — Sprint tracking

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- Updated sprint tracking status from `ready-for-dev` to `in-progress` before implementation.
- Added backend safety filter and integrated pre-LLM and post-LLM refusal checks in `process_turn()`.
- Added mobile refusal UX mapping for `content_refused` with calm message and refusal-specific actions.
- Ran targeted backend and mobile test suites after implementation.

### Completion Notes List

- Implemented safety guard-rail instructions in `GroqLLMProvider` prompts for both normal and final-question branches.
- Added `refused: bool` parsing and propagation in `LLMResponse`.
- Added `SafetyFilter` and `SafetyCheckResult` with conservative regex categories and optional JSON-configurable pattern override file.
- Added `SAFETY_ENABLED` and `SAFETY_PATTERNS_FILE` to runtime settings and wired singleton dependency (`get_safety_filter`).
- Updated orchestrator to short-circuit unsafe transcript content and map LLM refusals to `content_refused` (`stage=llm`, `retryable=false`) while keeping turn counters unchanged.
- Updated mobile error mapping to always show safe refusal copy and avoid exposing flagged content.
- Updated recovery UX for refusal flows: primary action **Try Again**, secondary action **End Session**, no re-record action for refusal.
- Backend targeted tests passed: 28/28.
- Mobile targeted tests passed: all tests in the two targeted files.

### File List

- services/api/src/providers/llm_groq.py
- services/api/src/services/safety_filter.py
- services/api/src/services/orchestrator.py
- services/api/src/settings/config.py
- services/api/src/api/dependencies/shared_services.py
- services/api/src/api/routes/turn.py
- services/api/src/services/**init**.py
- services/api/tests/unit/test_llm_groq.py
- services/api/tests/unit/test_turn_route.py
- services/api/tests/unit/test_safety_filter.py
- services/api/tests/unit/test_safety_orchestrator.py
- apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart
- apps/mobile/lib/features/interview/presentation/widgets/error_recovery_sheet.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart
- apps/mobile/test/features/interview/presentation/widgets/error_recovery_sheet_test.dart
- \_bmad-output/implementation-artifacts/sprint-status.yaml
- \_bmad-output/implementation-artifacts/5-3-safety-constraints-and-refusal-behavior.md

## Change Log

- 2026-02-19: Implemented Story 5.3 safety constraints and refusal behavior across backend and mobile, with targeted test coverage and passing test runs.
