# Story 4.1: Coaching Rubric Feedback Returned in Turn Response

## Status: done

## Story

As a user,
I want coaching feedback aligned to a simple rubric,
So that I can improve with actionable guidance.

## Implements

FR19 (Structured coaching feedback), FR20 (Rubric-based assessment)

## Acceptance Criteria (ACs)

### AC 1: Backend returns structured coaching feedback in turn response

**Given** a turn is processed through the STT → LLM → TTS pipeline
**When** the backend generates the assistant follow-up response
**Then** the turn response also includes a `coaching_feedback` object with structured fields aligned to the rubric
**And** the `coaching_feedback` is `null` on error or when the LLM fails to parse structured output

### AC 2: Coaching rubric covers clarity, structure, and filler words

**Given** a successful turn
**When** the coaching feedback is generated
**Then** each rubric dimension (e.g., `clarity`, `relevance`, `structure`, `filler_words`) has:

- A short label (the dimension name)
- A score (1–5 integer)
- A brief tip (≤ 25 words)
  **And** the overall feedback includes a `summary_tip` (one sentence, ≤ 30 words) highlighting the most impactful improvement

### AC 3: Feedback is short and skimmable by default

**Given** the coaching feedback object is returned
**When** the mobile app receives the response
**Then** the feedback is displayed as a compact card below the transcript or response text
**And** each dimension is shown as a labelled score + short tip (not a paragraph)
**And** the summary tip is visually prominent

### AC 4: Mobile state carries coaching feedback through the turn lifecycle

**Given** the turn response includes `coaching_feedback`
**When** the cubit transitions from Thinking → Speaking → Ready
**Then** the coaching feedback is preserved in the relevant states and accessible for display in the Turn Card component

### AC 5: Graceful degradation when coaching feedback is absent

**Given** the LLM fails to parse structured feedback or the field is `null`
**When** the response is returned
**Then** the turn proceeds normally without coaching feedback (no error, no empty card)
**And** the turn card hides the coaching section entirely

## Tasks

- [x] Task 1: Define structured coaching feedback response models (Backend)

**Files to modify:**

- `services/api/src/api/models/turn_models.py`

**Details:**

- Add a `CoachingDimension` Pydantic model with fields:
  - `label: str` — rubric dimension name (e.g., "Clarity", "Relevance")
  - `score: int` — integer 1–5
  - `tip: str` — actionable tip (≤ 25 words)
- Add a `CoachingFeedback` Pydantic model with fields:
  - `dimensions: list[CoachingDimension]` — list of scored dimensions
  - `summary_tip: str` — one-sentence top improvement (≤ 30 words)
- Add `coaching_feedback: CoachingFeedback | None = None` field to `TurnResponseData`
- Use `snake_case` for all JSON field names (architecture mandate)

- [x] Task 2: Update LLM provider to generate structured coaching feedback (Backend)

**Files to modify:**

- `services/api/src/providers/llm_groq.py`

**Details:**

- Modify `generate_follow_up()` to return a structured object (not just a string) containing:
  - `follow_up_question: str` — the existing question text
  - `coaching_feedback: dict | None` — the structured rubric feedback
- Update the system prompt to instruct the LLM to return a JSON object with the question/response and coaching dimensions
- Parse the LLM output as JSON; if parsing fails, fall back to using the raw text as `follow_up_question` with `coaching_feedback = None` (graceful degradation — AC 5)
- Update the return type: consider returning a dataclass/NamedTuple like `LLMResponse(question_text: str, coaching_feedback: CoachingFeedback | None)`
- **Rubric dimensions for MVP:** Clarity, Relevance, Structure, Filler Words
- **Important:** Keep `max_tokens` increase modest — the new structured output fits within ~350–400 tokens. Update default from 256 to 400.

- [x] Task 3: Update orchestrator to carry coaching feedback (Backend)

**Files to modify:**

- `services/api/src/services/orchestrator.py`

**Details:**

- Update `TurnResult` dataclass to include `coaching_feedback: dict | None = None`
- After LLM processing, extract coaching feedback from the `LLMResponse` and pass it into `TurnResult`
- No changes to timing/error logic — coaching feedback is a passive data field

- [x] Task 4: Update turn route to include coaching feedback in response (Backend)

**Files to modify:**

- `services/api/src/api/routes/turn.py`

**Details:**

- Map `TurnResult.coaching_feedback` to `TurnResponseData.coaching_feedback` when constructing the response
- Ensure the field serializes as `null` (not omitted) when absent, for consistent envelope shape

- [x] Task 5: Add coaching feedback model to mobile client (Mobile)

**Files to modify:**

- `apps/mobile/lib/core/models/turn_models.dart`
- `apps/mobile/lib/core/models/turn_models.g.dart` (auto-generated — run `build_runner`)

**Details:**

- Add `CoachingDimension` class with `label`, `score`, `tip` fields
- Add `CoachingFeedback` class with `dimensions` (list of `CoachingDimension`), `summaryTip`
- Add `coachingFeedback` field (nullable) to `TurnResponseData`, annotated with `@JsonKey(name: 'coaching_feedback')`
- Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `turn_models.g.dart`

- [x] Task 6: Carry coaching feedback through interview state (Mobile)

**Files to modify:**

- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`

**Details:**

- Add `coachingFeedback` (type `CoachingFeedback?`) to `InterviewTranscriptReview`, `InterviewThinking`, `InterviewSpeaking`, and `InterviewReady` states
- Update `_handleTurnResponse` to extract `coachingFeedback` from `TurnResponseData` and carry it through state transitions
- Update `onResponseReady` and `onSpeakingComplete` to preserve `coachingFeedback`
- Add `coachingFeedback` to each state's `props` list for Equatable comparison

- [x] Task 7: Display coaching feedback in Turn Card (Mobile)

**Files to modify:**

- `apps/mobile/lib/features/interview/presentation/widgets/turn_card.dart`

**Details:**

- Add a `CoachingFeedbackCard` widget (or inline section) that:
  - Shows the `summary_tip` prominently (bold, slightly larger text)
  - Lists each dimension as: `[Label] [Score/5] — tip`
  - Uses the secondary accent color (`#27B39B`) for score badges
  - Hides entirely when `coachingFeedback` is `null` (AC 5)
- Place the coaching section below the AI response text and above playback controls
- Keep the design consistent with the Calm Ocean theme (UX spec §Design System, §Component Strategy Phase 3)

- [x] Task 8: Add unit tests for coaching feedback (Backend)

**Files to create/modify:**

- `services/api/tests/test_coaching_feedback.py` (new)
- `services/api/tests/test_turn.py` (extend)

**Details:**

- Test `CoachingFeedback` and `CoachingDimension` Pydantic model validation
- Test LLM prompt returns valid JSON with coaching dimensions (mock Groq client)
- Test graceful fallback when LLM returns non-JSON or malformed coaching output
- Test that `TurnResponseData` serializes correctly with/without `coaching_feedback`

- [x] Task 9: Add widget tests for coaching feedback display (Mobile)

**Files to create/modify:**

- `apps/mobile/test/features/interview/presentation/widgets/coaching_feedback_test.dart` (new)

**Details:**

- Test coaching card renders all dimensions with labels, scores, and tips
- Test coaching card renders `summary_tip` prominently
- Test coaching card is hidden when `coachingFeedback` is `null`
- Test state transitions preserve coaching feedback data

## Dev Notes

### Architecture Alignment

- **API Contract:** `POST /turn` response envelope remains `{data, error, request_id}`. The `coaching_feedback` field is nested inside `data`. No new endpoints required.
- **Naming:** All backend JSON uses `snake_case` (architecture §Naming Conventions). Mobile uses `@JsonKey` annotations for mapping.
- **Response Envelope:** Consistent with wrapped JSON responses (`{data, error, request_id}`) — architecture mandate.
- **Error Handling:** Coaching feedback failures are non-blocking. The LLM may fail to produce structured output — graceful fallback to `null` coaching_feedback (no TurnProcessingError raised).

### LLM Prompt Strategy

The current system prompt in `llm_groq.py` (`_build_system_prompt`) instructs the LLM to output **only** the question text. This must change to:

1. Request a JSON object containing both the question and coaching dimensions
2. Define the coaching rubric (Clarity, Relevance, Structure, Filler Words) in the system prompt
3. Use a 1–5 scoring scale per dimension
4. Keep tips concise (≤ 25 words each)

**Fallback:** If `json.loads()` fails on the LLM output, treat the entire output as the `follow_up_question` text and set `coaching_feedback = None`. This is critical for resilience.

### UX Alignment

- **"Coach with kindness and precision"** — tips must be supportive, not judgmental (UX spec §Emotional Design Principles)
- **"Feedback layering"** — immediate micro-feedback (1 key tip via `summary_tip`) + deeper summary at end (Story 4.2) — UX spec §Transferable UX Patterns
- **"Short and skimmable"** — no paragraphs in the coaching card; scores + one-liners only
- **Phase 3 Component Strategy** — coaching feedback card is called out explicitly as a Phase 3 component in UX spec §Implementation Roadmap

### Epic 3 Retrospective Action Items (Addressed)

| Action Item                           | How Addressed                                                          |
| :------------------------------------ | :--------------------------------------------------------------------- |
| Finalize LLM Prompt for Rubric        | Task 2 — prompt updated with 4-dimension rubric                        |
| Define "Clarity & Relevance" Criteria | AC 2 — dimensions defined: Clarity, Relevance, Structure, Filler Words |

### State Machine Impact

The core state machine (`Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready`) is **unchanged**. Coaching feedback is a passive data field carried through existing states. No new states or transitions are added.

### Key Risks

1. **LLM output reliability:** The LLM may not consistently return valid JSON. The graceful fallback (Task 2) mitigates this. Monitor in diagnostics for parse-failure rates.
2. **Token budget:** Structured output (question + 4 dimensions + tips) requires more tokens than a question alone. Increase `max_tokens` from 256 → 400 — still well within Groq's limits and latency budget.
3. **Prompt engineering iteration:** The rubric prompt may require tuning to get consistently useful tips. Accept "good enough" for MVP and iterate.

### Dependencies

- **Upstream:** Epic 3 complete (done ✅). The full voice turn loop is operational.
- **Downstream:** Story 4.2 (end-of-session summary) will aggregate per-turn coaching feedback. Ensure the data structure is extensible.
- **No new packages required** on either backend or mobile.

## References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 4, Story 4.1
- [architecture.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — API contract, naming, response envelope
- [ux-design-specification.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — Coaching tone, feedback patterns, component roadmap
- [epic-3-retrospective.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/epic-3-retrospective.md) — Action items for Epic 4
- [orchestrator.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/services/orchestrator.py) — Current pipeline (no coaching)
- [llm_groq.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/providers/llm_groq.py) — Current system prompt (question-only)
- [turn_models.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/api/models/turn_models.py) — Backend response model
- [turn_models.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/core/models/turn_models.dart) — Mobile response model
- [interview_state.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart) — State definitions
- [interview_cubit.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart) — State machine logic
- [3-4-playback-controls-pause-stop-replay.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/3-4-playback-controls-pause-stop-replay.md) — Previous story learnings

## Dev Agent Record

### Debug Log

- Implemented structured coaching models in backend and mobile response contracts.
- Added resilient JSON parsing/fallback in Groq provider using `LLMResponse`.
- Carried `coaching_feedback` through orchestrator, route response mapping, and mobile interview states.
- Added coaching feedback UI section in `TurnCard` with summary tip, rubric rows, and accent score badges.
- Regenerated Dart serializers with `dart run build_runner build --delete-conflicting-outputs`.

### Completion Notes

- Completed Tasks 1-9 and validated acceptance criteria AC1-AC5.
- Backend regression suite passed: `pytest` in `services/api` (124 passed).
- Mobile regression suite passed: `flutter test` in `apps/mobile` (all passed).
- Graceful degradation verified: malformed/non-JSON LLM output maps to `coaching_feedback = null` with normal turn flow.

## File List

- `_bmad-output/implementation-artifacts/4-1-coaching-rubric-feedback-returned-in-turn-response.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `services/api/src/api/models/turn_models.py`
- `services/api/src/api/models/__init__.py`
- `services/api/src/providers/llm_groq.py`
- `services/api/src/services/orchestrator.py`
- `services/api/src/api/routes/turn.py`
- `services/api/src/settings/config.py`
- `services/api/tests/unit/test_coaching_feedback.py`
- `services/api/tests/unit/test_turn_models.py`
- `services/api/tests/unit/test_llm_groq.py`
- `services/api/tests/unit/test_orchestrator.py`
- `services/api/tests/unit/test_turn_route.py`
- `apps/mobile/lib/core/models/turn_models.dart`
- `apps/mobile/lib/core/models/turn_models.g.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/turn_card.dart`
- `apps/mobile/lib/features/interview/presentation/view/interview_view.dart`
- `apps/mobile/test/core/models/turn_models_test.dart`
- `apps/mobile/test/features/interview/presentation/widgets/turn_card_test.dart`
- `apps/mobile/test/features/interview/presentation/widgets/coaching_feedback_test.dart`

## Change Log

- 2026-02-18: Implemented Story 4.1 coaching feedback end-to-end (backend models/provider/orchestrator/route, mobile models/state/ui), added automated tests, and validated with full backend/mobile regression suites.

## Code Review

### Findings & Fixes

- **[RESOLVED] Hardcoded Rubric in System Prompt (Maintainability)**
  - Problem: Rubric dimensions were hardcoded strings in `llm_groq.py`.
  - Fix: Extracted to `RUBRIC_DIMENSIONS` constant and updated prompt generation logic. Verified with tests.

- **[RESOLVED] Lack of Text Overflow Handling in Mobile UI (Resilience)**
  - Problem: Tip text in `turn_card.dart` lacked overflow protection.
  - Fix: Added `maxLines: 3` and `TextOverflow.ellipsis`. Verified with widget tests.

- **[RESOLVED] Redundant Type Conversion in Orchestrator (Type Safety)**
  - Problem: `TurnResult` used `dict` for coaching feedback instead of the model.
  - Fix: Updated `TurnResult` and `LLMResponse` to use `CoachingFeedback` model. Updated tests to match.

### Verification status

- **Automated Tests:** All backend and mobile tests passed.
- **Manual Verification:** Not required (covered by automated tests and previous verification).
- **Status:** Approved & Merged.
