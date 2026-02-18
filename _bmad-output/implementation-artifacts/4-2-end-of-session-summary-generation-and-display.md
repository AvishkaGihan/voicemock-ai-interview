# Story 4.2: End-of-Session Summary Generation and Display

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want an end-of-session summary across the whole interview,
So that I can reflect on strengths and what to improve.

## Implements

FR30 (Generate end-of-session summary), FR31 (View summary after session ends)

## Acceptance Criteria (ACs)

### AC 1: Backend stores per-turn data for summary aggregation

**Given** a session with multiple completed turns
**When** a turn is processed through the STT → LLM → TTS pipeline
**Then** the backend stores minimum per-turn data (transcript, assistant_text, coaching_feedback) in the session state
**And** this data is available for aggregation when the session ends

### AC 2: Backend generates a structured session summary on the final turn

**Given** the session reaches the configured question count (i.e., `is_complete = True`)
**When** the final turn is processed
**Then** the backend generates a structured session summary derived from all turn data
**And** the summary includes: `overall_assessment` (2-3 sentences), `strengths` (list of 1-3 items), `improvements` (list of 1-3 items), and `average_scores` (per rubric dimension average)
**And** the summary is returned as a `session_summary` field in the final turn response

### AC 3: Summary is returned in the turn response envelope

**Given** the final turn response includes `is_complete: true`
**When** the response is serialized
**Then** the JSON payload includes a `session_summary` object (or `null` if generation fails)
**And** the response follows the existing `{data, error, request_id}` envelope pattern
**And** non-final turns always return `session_summary: null`

### AC 4: Android app displays the summary in a dedicated view

**Given** the session ends and the cubit transitions to `InterviewSessionComplete`
**When** the summary data is available
**Then** the app displays the summary in an enhanced `SessionCompleteCard` with:

- Overall assessment text (prominent)
- Strengths listed with success styling
- Improvements listed with coaching tone
- Average rubric scores with visual indicators
- "Back to Home" and "Start New Session" actions

### AC 5: Graceful degradation when summary generation fails

**Given** the LLM fails to generate a valid summary (e.g., timeout, parse error)
**When** the response is returned
**Then** the session still completes normally (`is_complete: true`)
**And** `session_summary` is `null`
**And** the mobile app shows a basic completion card without summary data (current behavior)

## Tasks

- [x] Task 1: Add per-turn history storage to session state (Backend)

**Files to modify:**

- `services/api/src/domain/session_state.py`
- `services/api/src/services/session_store.py`

**Details:**

- Add a `TurnRecord` dataclass to `session_state.py` with fields:
  - `turn_number: int`
  - `transcript: str`
  - `assistant_text: str`
  - `coaching_feedback: dict | None` — serialized coaching feedback (store as dict for flexibility)
- Add `turn_history: list[TurnRecord] = field(default_factory=list)` to `SessionState`
- Update `SessionStore._deep_copy_session()` to deep-copy the `turn_history` list (create new `TurnRecord` instances, not shallow copies)
- **Do NOT change the session_store interface** (create/get/update/delete) — turn history is appended via `update_session`

- [x] Task 2: Append turn data to session history after each turn (Backend)

**Files to modify:**

- `services/api/src/services/orchestrator.py`
- `services/api/src/api/routes/turn.py`

**Details:**

- In `turn.py`, after `process_turn()` succeeds and before building the response, use `session_store.update_session()` to append the current turn's data to the session's `turn_history`
- Create a `TurnRecord` from the `TurnResult` fields: `transcript`, `assistant_text`, and `coaching_feedback` (serialize `CoachingFeedback` to dict via `.model_dump()` if not None)
- **Important:** The `turn_history` append must happen in the route, not in the orchestrator, because the orchestrator doesn't have access to the session store

- [x] Task 3: Define session summary response models (Backend)

**Files to create/modify:**

- `services/api/src/api/models/turn_models.py`

**Details:**

- Add a `SessionSummary` Pydantic model with fields:
  - `overall_assessment: str` — 2-3 sentence overall review (≤ 60 words)
  - `strengths: list[str]` — 1-3 concrete strengths (each ≤ 20 words)
  - `improvements: list[str]` — 1-3 concrete improvements (each ≤ 20 words)
  - `average_scores: dict[str, float]` — per-dimension average scores (e.g., `{"clarity": 3.5, "relevance": 4.0, ...}`)
- Add `session_summary: SessionSummary | None = None` field to `TurnResponseData`
- Use `snake_case` for all JSON field names (architecture mandate)

- [x] Task 4: Implement summary generation in LLM provider (Backend)

**Files to modify:**

- `services/api/src/providers/llm_groq.py`

**Details:**

- Add a `generate_session_summary()` method to `GroqLLMProvider` that:
  - Takes `turn_history: list[dict]` (list of turn records with transcript, assistant_text, coaching_feedback)
  - Takes `role: str`, `interview_type: str`, `difficulty: str`
  - Builds a system prompt requesting a JSON summary with structure matching `SessionSummary`
  - Parses the LLM response as JSON; if parsing fails, returns `None` (graceful degradation — AC 5)
  - Uses the same Groq client and error handling patterns as `generate_follow_up()`
- Calculate `average_scores` from per-turn coaching feedback dimensions (don't ask the LLM to compute averages — compute them deterministically in Python)
- **Important:** The summary prompt should reference the rubric dimensions from `RUBRIC_DIMENSIONS` constant for consistency
- **Token budget:** Summary generation may require more tokens (~500-600). Use same `max_tokens` setting (400) and increase only if needed — the summary should be concise by design

- [x] Task 5: Trigger summary generation on final turn (Backend)

**Files to modify:**

- `services/api/src/services/orchestrator.py`
- `services/api/src/api/routes/turn.py`

**Details:**

- Update `TurnResult` dataclass to include `session_summary: dict | None = None`
- In the orchestrator `process_turn()`, after the LLM step: if `is_complete` flag is true (session reached question count), call `generate_session_summary()` on the LLM provider
- Pass the session's `turn_history` (retrieved from session store) to the summary generation method
- Compute `average_scores` from accumulated coaching feedback in `turn_history` (not from the LLM)
- If summary generation fails, catch the exception, log it, and set `session_summary = None` (never fail the entire turn due to summary failure)
- In `turn.py`, map `TurnResult.session_summary` to `TurnResponseData.session_summary`

- [x] Task 6: Add session summary model to mobile client (Mobile)

**Files to modify:**

- `apps/mobile/lib/core/models/turn_models.dart`
- `apps/mobile/lib/core/models/turn_models.g.dart` (auto-generated — run `build_runner`)

**Details:**

- Add `SessionSummary` class with fields: `overallAssessment` (String), `strengths` (List<String>), `improvements` (List<String>), `averageScores` (Map<String, double>)
- Annotate with `@JsonSerializable()` and `@JsonKey(name: 'snake_case_name')` for each field
- Add `sessionSummary` field (nullable) to `TurnResponseData`, annotated with `@JsonKey(name: 'session_summary')`
- Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart`

- [x] Task 7: Carry session summary through interview state (Mobile)

**Files to modify:**

- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`

**Details:**

- Add `sessionSummary` (type `SessionSummary?`) to `InterviewSessionComplete` state
- Update `InterviewSessionComplete`'s `props` list for Equatable comparison
- In `interview_cubit.dart`, update the transition to `InterviewSessionComplete` (currently in `_handleTurnResponse` and `onSpeakingComplete`) to extract `sessionSummary` from the turn response and pass it to the state
- **Key:** The `InterviewSessionComplete` state is emitted when `isComplete == true`. The summary data must be carried from the turn response through to this final state.

- [x] Task 8: Enhance session complete card with summary data (Mobile)

**Files to modify:**

- `apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart`

**Details:**

- Update `SessionCompleteCard` to accept `SessionSummary?` parameter
- When `sessionSummary` is not null, render:
  - **Overall assessment section:** prominent text block with the assessment
  - **Strengths section:** bulleted list with success icon (✓) and green accent (`#1E9E6A`)
  - **Improvements section:** bulleted list with growth icon (↑) and secondary accent (`#27B39B`)
  - **Average scores section:** horizontal row of score indicators per dimension (label + score badge)
- When `sessionSummary` is null, preserve the current simple completion message (AC 5)
- Keep the design consistent with the Calm Ocean theme (UX spec §Design System)
- Follow the UX principle: "Coach with kindness and precision" — improvements should be framed as growth opportunities, not failures
- Maintain existing "Back to Home" and "Start New Session" actions

- [x] Task 9: Add unit tests for session summary (Backend)

**Files to create/modify:**

- `services/api/tests/unit/test_session_summary.py` (new)
- `services/api/tests/unit/test_turn_models.py` (extend)
- `services/api/tests/unit/test_orchestrator.py` (extend)

**Details:**

- Test `SessionSummary` Pydantic model validation (field constraints, word limits)
- Test `TurnResponseData` serializes correctly with/without `session_summary`
- Test `generate_session_summary()` returns valid JSON with expected structure (mock Groq client)
- Test graceful fallback when LLM returns non-JSON or malformed summary output (returns None)
- Test `average_scores` calculation from turn history with coaching feedback
- Test that `turn_history` is correctly appended and deep-copied in `SessionStore`
- Test that the final turn response includes `session_summary` when `is_complete` is true
- Test that non-final turn responses have `session_summary: null`

- [x] Task 10: Add widget tests for session summary display (Mobile)

**Files to create/modify:**

- `apps/mobile/test/features/interview/presentation/widgets/session_summary_test.dart` (new)
- `apps/mobile/test/core/models/turn_models_test.dart` (extend)

**Details:**

- Test that `SessionCompleteCard` renders summary content when `sessionSummary` is provided
- Test overall assessment is displayed prominently
- Test strengths are rendered with success styling
- Test improvements are rendered with coaching tone
- Test average scores are displayed with dimension labels
- Test graceful degradation: card renders basic completion when `sessionSummary` is null
- Test `SessionSummary` deserialization from JSON with `@JsonKey` mappings

## Dev Notes

### Architecture Alignment

- **API Contract:** `POST /turn` response envelope remains `{data, error, request_id}`. The `session_summary` field is nested inside `data`, alongside existing `coaching_feedback`. No new endpoints required — the summary is returned inline with the final turn response.
- **Alternative considered (and rejected for MVP):** A separate `POST /session/end` or `GET /session/{id}/summary` endpoint. This was flagged in the Epic 3 retrospective. For MVP, inline delivery is simpler and avoids an extra round-trip. The endpoint approach can be added post-MVP if session history/replay is needed.
- **Naming:** All backend JSON uses `snake_case` (architecture §Naming Conventions). Mobile uses `@JsonKey` annotations for mapping.
- **Response Envelope:** Consistent with wrapped JSON responses (`{data, error, request_id}`) — architecture mandate.
- **Error Handling:** Summary generation failures are non-blocking. The LLM may fail to produce structured output — graceful fallback to `null` session_summary (no TurnProcessingError raised). The session still completes normally.

### Session State Expansion

The current `SessionState` (`session_state.py`) only stores `asked_questions: list[str]`. For summary generation, we need per-turn transcript + assistant_text + coaching_feedback. This is stored as a `turn_history` list of `TurnRecord` dataclasses.

**Key concern:** Memory usage. Each `TurnRecord` stores ~500-1000 characters of text. For a 10-question session, this is trivial (~10KB). No memory optimization needed for MVP.

### LLM Summary Generation Strategy

- **Prompt structure:** Send the full `turn_history` (question/answer/coaching for each turn) and ask the LLM to synthesize an overall assessment, strengths, and improvements.
- **Average scores:** Computed deterministically in Python (not by the LLM). Sum all per-turn coaching dimension scores and divide by count. This ensures accuracy and avoids LLM hallucination on numbers.
- **Fallback:** If the LLM fails or returns unparseable JSON, `session_summary = None` and the session completes normally.
- **Token budget:** The input context (turn history) may be large for 10-question sessions. Groq's Llama 3.3 supports 128K context, so this is not a concern.

### UX Alignment

- **"Coach with kindness and precision"** — improvements must be supportive, not judgmental (UX spec §Emotional Design Principles)
- **End-of-session summary components are Phase 3** in the UX component roadmap (UX spec §Implementation Roadmap)
- **"Make progress feel real"** — highlight wins first, then improvements framed as growth (UX spec §Micro-Emotions)
- **The completion moment should spark "accomplished + energized"** — wins highlighted, improvements prioritized, next steps clear (UX spec §Emotional Journey Mapping)
- **Summary is "short and skimmable"** — avoid paragraphs; use structured sections with bullets

### Epic 3 Retrospective Action Items (Addressed)

| Action Item                           | How Addressed                                                                              |
| :------------------------------------ | :----------------------------------------------------------------------------------------- |
| Implement `/session/end` Endpoint     | Deferred for MVP — summary delivered inline with final turn response (simpler)             |
| Design "Session Summary" UI           | AC 4 + Task 8 — enhanced `SessionCompleteCard` with structured summary sections            |
| Finalize LLM Prompt for Rubric        | Already addressed in Story 4.1 (rubric is established)                                     |
| Define "Clarity & Relevance" Criteria | Already addressed in Story 4.1 (4 dimensions: Clarity, Relevance, Structure, Filler Words) |

### State Machine Impact

The core state machine (`Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready`) is **unchanged**. The `InterviewSessionComplete` state gains a `sessionSummary` field but no new states or transitions are added. The session completion detection (`is_complete` flag) already exists.

### Key Risks

1. **LLM summary quality:** The LLM might produce vague or unhelpful summaries. Accept "good enough" for MVP and iterate on the prompt.
2. **Turn history depth:** For longer sessions (10+ questions), the turn history may be large. Groq's 128K context window handles this easily, but monitor prompt size.
3. **Average score edge case:** If no turns have coaching feedback (all were `null` due to parse failures), `average_scores` should be an empty dict, not cause a division-by-zero error.

### Dependencies

- **Upstream:** Story 4.1 complete (done ✅). Per-turn coaching feedback is operational and the `CoachingFeedback` model exists.
- **Downstream:** Story 4.3 (recommended next actions) will extend the `SessionSummary` model. Ensure the structure is extensible.
- **No new packages required** on either backend or mobile.

### Project Structure Notes

- All backend changes follow the established pattern: models in `api/models/`, logic in `services/` and `providers/`, domain in `domain/`
- Mobile changes follow feature-first VGV structure: models in `core/models/`, state in `features/interview/presentation/cubit/`, widgets in `features/interview/presentation/widgets/`
- No new files except test files and potentially new models — consistent with existing conventions

### References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 4, Story 4.2
- [architecture.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — API contract, session state, naming, response envelope
- [ux-design-specification.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — Session summary components (Phase 3), coaching tone, completion moment design
- [epic-3-retrospective.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/epic-3-retrospective.md) — Action items for Epic 4 (session/end, summary UI)
- [4-1-coaching-rubric-feedback-returned-in-turn-response.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/4-1-coaching-rubric-feedback-returned-in-turn-response.md) — Previous story learnings, data model patterns
- [session_state.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/domain/session_state.py) — Current session state (no turn history)
- [session_store.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/services/session_store.py) — Current session store (deep-copy pattern)
- [orchestrator.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/services/orchestrator.py) — Current pipeline (no summary)
- [llm_groq.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/providers/llm_groq.py) — Current LLM provider (coaching rubric)
- [turn_models.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/api/models/turn_models.py) — Backend response model
- [turn_models.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/core/models/turn_models.dart) — Mobile response model
- [interview_state.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart) — State definitions (InterviewSessionComplete)
- [interview_cubit.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart) — State machine logic
- [session_complete_card.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart) — Current session complete card (placeholder)

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- `pytest tests/unit/test_session_store.py tests/unit/test_turn_models.py tests/unit/test_turn_route.py tests/unit/test_orchestrator.py tests/unit/test_llm_groq.py tests/unit/test_session_summary.py` → 63 passed
- `flutter test test/core/models/turn_models_test.dart test/features/interview/presentation/widgets/session_summary_test.dart test/features/interview/presentation/cubit/interview_cubit_test.dart test/features/interview/presentation/view/interview_view_test.dart` → passed
- `pytest` (full backend suite) → 136 passed
- `flutter test` (full mobile suite) → 408 passed, 1 skipped

### Completion Notes List

- Implemented `TurnRecord` and `turn_history` storage/deep copy in session domain/store for per-turn summary aggregation.
- Added backend `SessionSummary` model and `session_summary` field in `TurnResponseData` with snake_case API contract preserved.
- Implemented `GroqLLMProvider.generate_session_summary()` with deterministic `average_scores` calculation from rubric dimensions and graceful fallback to `None`.
- Wired final-turn summary generation in orchestrator and route mapping to response envelope; non-final turns keep `session_summary: null`.
- Added mobile `SessionSummary` JSON model, state propagation through `InterviewTranscriptReview`/`InterviewSessionComplete`, and view wiring.
- Enhanced `SessionCompleteCard` to render overall assessment, strengths, improvements, and average score chips when summary exists; fallback completion UI remains intact.
- Added backend/mobile tests covering model validation, summary generation/fallback, session-history deep-copy, route response behavior, state propagation, and summary widget rendering.

### File List

- `_bmad-output/implementation-artifacts/4-2-end-of-session-summary-generation-and-display.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `services/api/src/domain/session_state.py`
- `services/api/src/services/session_store.py`
- `services/api/src/api/models/turn_models.py`
- `services/api/src/api/models/__init__.py`
- `services/api/src/providers/llm_groq.py`
- `services/api/src/services/orchestrator.py`
- `services/api/src/api/routes/turn.py`
- `services/api/tests/unit/test_session_store.py`
- `services/api/tests/unit/test_turn_models.py`
- `services/api/tests/unit/test_turn_route.py`
- `services/api/tests/unit/test_orchestrator.py`
- `services/api/tests/unit/test_llm_groq.py`
- `services/api/tests/unit/test_session_summary.py`
- `apps/mobile/lib/core/models/turn_models.dart`
- `apps/mobile/lib/core/models/turn_models.g.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`
- `apps/mobile/lib/features/interview/presentation/view/interview_view.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart`
- `apps/mobile/test/core/models/turn_models_test.dart`
- `apps/mobile/test/features/interview/presentation/widgets/session_summary_test.dart`
- `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart`
- `apps/mobile/test/features/interview/presentation/view/interview_view_test.dart`
