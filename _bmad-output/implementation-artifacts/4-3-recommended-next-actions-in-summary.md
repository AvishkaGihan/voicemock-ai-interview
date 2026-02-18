# Story 4.3: Recommended Next Actions in Summary

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want recommended next actions after my session,
So that I know exactly what to practice next.

## Implements

FR32 (System can provide recommended next actions, e.g., "try answering with STAR")

## Acceptance Criteria (ACs)

### AC 1: Backend generates recommended actions tied to session performance

**Given** a session summary is being generated on the final turn
**When** the LLM produces the summary output
**Then** the summary includes a `recommended_actions` field containing 2-4 concrete, actionable next steps
**And** each action is tied to the candidate's actual performance (not generic advice)
**And** each action is 25 words or fewer

### AC 2: Recommended actions reference rubric weaknesses

**Given** the session has per-turn coaching feedback with rubric scores
**When** recommended actions are generated
**Then** at least one action references the lowest-scoring rubric dimension(s)
**And** actions use specific techniques (e.g., "Try structuring answers with the STAR method", "Practice reducing filler words by pausing before speaking")

### AC 3: SessionSummary model includes recommended_actions field

**Given** the `SessionSummary` model exists (backend and mobile)
**When** the model is extended
**Then** a `recommended_actions` field (list of strings, 2-4 items) is added
**And** non-final turns continue to return `session_summary: null`
**And** backward compatibility is maintained (the field defaults to an empty list if missing)

### AC 4: Android app displays recommended actions in the session complete view

**Given** the session ends and the summary includes recommended actions
**When** the summary is displayed
**Then** recommended actions are shown in a distinct, visually prominent section below improvements
**And** each action is presented as a tappable/focusable card or list item with an action icon (→ or similar)
**And** the section header reads "What to Practice Next" or equivalent coaching-friendly label

### AC 5: Graceful degradation when recommended actions are absent

**Given** the LLM fails to generate recommended actions or the field is missing
**When** the summary is displayed
**Then** the summary renders normally without the recommended actions section
**And** no crash or empty section is visible

## Tasks

- [x] Task 1: Extend `SessionSummary` backend model with `recommended_actions` (AC: 3)
  - [x] 1.1: Add `recommended_actions: list[str]` field to `SessionSummary` in `turn_models.py` with `min_length=2, max_length=4` and per-item word limit ≤ 25
  - [x] 1.2: Add `@field_validator` for `recommended_actions` to enforce per-item word count
  - [x] 1.3: Verify existing model validation tests still pass (backward compat check)

- [x] Task 2: Update LLM session summary prompt to include recommended actions (AC: 1, 2)
  - [x] 2.1: Update `_build_session_summary_prompt()` in `llm_groq.py` to request `recommended_actions` in the JSON schema
  - [x] 2.2: Instruct the LLM to tie actions to the weakest rubric dimensions and use specific techniques
  - [x] 2.3: Update `generate_session_summary()` to validate `recommended_actions` in the parsed output
  - [x] 2.4: If `recommended_actions` is missing from LLM output, default to an empty list (graceful fallback)

- [x] Task 3: Extend mobile `SessionSummary` model with `recommendedActions` (AC: 3)
  - [x] 3.1: Add `recommendedActions` field (`List<String>`) to `SessionSummary` in `turn_models.dart` with `@JsonKey(name: 'recommended_actions', defaultValue: <String>[])`
  - [x] 3.2: Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart`

- [x] Task 4: Display recommended actions in `SessionCompleteCard` (AC: 4)
  - [x] 4.1: Add a "What to Practice Next" section to `SessionCompleteCard` below the improvements section
  - [x] 4.2: Render each recommended action as a styled row with an action icon (→) and the action text
  - [x] 4.3: Use accent color `#27B39B` (coaching) or a distinct action color for the section
  - [x] 4.4: Conditionally hide the section when `recommendedActions` is empty (AC: 5)

- [x] Task 5: Add backend unit tests for recommended actions (AC: 1, 2, 3, 5)
  - [x] 5.1: Test `SessionSummary` validates `recommended_actions` field constraints (2-4 items, ≤ 25 words each)
  - [x] 5.2: Test `SessionSummary` accepts a model without `recommended_actions` (backward compat — field has default)
  - [x] 5.3: Test `generate_session_summary()` includes `recommended_actions` when LLM output is valid
  - [x] 5.4: Test graceful fallback: LLM output missing `recommended_actions` → defaults to `[]`
  - [x] 5.5: Test that the session summary prompt mentions rubric dimensions for targeting actions

- [x] Task 6: Add mobile tests for recommended actions (AC: 4, 5)
  - [x] 6.1: Test `SessionSummary` deserialization with `recommended_actions` field present
  - [x] 6.2: Test `SessionSummary` deserialization when `recommended_actions` is missing (defaults to empty list)
  - [x] 6.3: Test `SessionCompleteCard` renders "What to Practice Next" section when actions are provided
  - [x] 6.4: Test `SessionCompleteCard` hides actions section when list is empty

## Dev Notes

### Architecture Alignment

- **API Contract:** No new endpoints. The `recommended_actions` field is added to the existing `SessionSummary` model, which is already nested inside `TurnResponseData.session_summary`. The response envelope `{data, error, request_id}` is unchanged.
- **Naming:** `recommended_actions` (snake_case) on backend, `recommendedActions` (camelCase) on mobile with `@JsonKey(name: 'recommended_actions')` — consistent with all existing fields.
- **Backward Compatibility:** The new field has a default value (`[]` on mobile, `Field(default_factory=list)` on backend), so existing clients that don't send/receive the field will work without breaking.

### Extending SessionSummary (as noted in Story 4-2)

Story 4-2 explicitly documented: "Story 4.3 (recommended next actions) will extend the `SessionSummary` model. Ensure the structure is extensible." The current `SessionSummary` model has 4 fields; we add a 5th (`recommended_actions`). This is a non-breaking additive change.

### LLM Prompt Strategy

- The existing `_build_session_summary_prompt()` already sends the full turn history and rubric dimensions to the LLM.
- For recommended actions, instruct the LLM to:
  1. Identify the 2 weakest rubric dimensions from `average_scores`
  2. Generate 2-4 specific, actionable recommendations targeting those areas
  3. Each recommendation should reference a concrete technique (e.g., "STAR method", "pause instead of using filler words", "lead with the most relevant experience")
- **Average scores are computed deterministically** (not by the LLM), so the LLM can reference them for targeting actions.
- The prompt should explicitly instruct: "Do NOT give generic advice. Tie each action to the candidate's actual interview performance."

### UX Alignment

- **"Coach with kindness and precision"** — recommended actions should feel motivating, not prescriptive (UX spec §Emotional Design Principles)
- **"Make progress feel real"** — concrete actions give the user a clear path forward (UX spec §Micro-Emotions)
- **"Short and skimmable"** — each action ≤ 25 words; 2-4 actions total; no paragraphs
- **Action framing:** Use active verbs ("Try…", "Practice…", "Focus on…") rather than passive critique
- The "What to Practice Next" section should feel like a natural extension of the summary flow: Assessment → Strengths → Improvements → What to Practice Next

### State Machine Impact

No state machine changes. The `InterviewSessionComplete` state already carries `sessionSummary`. The `recommendedActions` field is nested inside `SessionSummary` — no new state variants or transitions needed.

### Key Risks

1. **LLM may generate generic actions:** Mitigated by explicit prompt instructions to reference actual performance data and specific techniques. Accept "good enough" for MVP.
2. **LLM may omit `recommended_actions` key:** Mitigated by defaulting to `[]` if absent — the summary still renders without the section.
3. **Word count validation failures:** If the LLM exceeds 25 words on an action, Pydantic validation will reject the entire summary. This is acceptable (graceful fallback to `null` summary) but could be relaxed if it causes issues in practice.

### Dependencies

- **Upstream:** Story 4.2 complete (done ✅). `SessionSummary` model, `generate_session_summary()`, `SessionCompleteCard` with summary rendering all exist.
- **Downstream:** Epic 4 retrospective (optional). No further stories depend on this.
- **No new packages required** on either backend or mobile.

### Previous Story Intelligence (4-2)

- `SessionSummary` backend model is at `services/api/src/api/models/turn_models.py` (line 48)
- `SessionSummary` mobile model is at `apps/mobile/lib/core/models/turn_models.dart` (line 58)
- `generate_session_summary()` is at `services/api/src/providers/llm_groq.py` (line 280)
- `_build_session_summary_prompt()` is at `services/api/src/providers/llm_groq.py` (line 337)
- `SessionCompleteCard` is at `apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart`
- `InterviewSessionComplete` state already carries `sessionSummary` via `interview_state.dart` (line 269)
- Backend tests: `test_session_summary.py`, `test_turn_models.py`, `test_orchestrator.py`, `test_llm_groq.py`
- Mobile tests: `session_summary_test.dart`, `turn_models_test.dart`, `interview_cubit_test.dart`
- **Pattern from 4-2:** `average_scores` was computed deterministically in Python, not by the LLM. Follow the same principle — don't ask the LLM to determine which dimensions are weakest; compute it from `average_scores` dict and pass to the prompt.

### Git Intelligence

Recent commits are on Epic 4 implementation (stories 4.1 and 4.2):

- Coaching rubric feedback implementation (4.1)
- Session summary generation and display (4.2)
- All backend and mobile tests passing (136 backend, 408+ mobile)

### Project Structure Notes

- All backend changes follow established patterns: models in `api/models/`, provider logic in `providers/`, tests in `tests/unit/`
- Mobile changes follow VGV feature-first structure: models in `core/models/`, widgets in `features/interview/presentation/widgets/`
- No new files needed except potentially new test functions in existing test files

### References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 4, Story 4.3 (FR32)
- [architecture.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — API contract, naming conventions, response envelope
- [4-2-end-of-session-summary-generation-and-display.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/4-2-end-of-session-summary-generation-and-display.md) — Previous story learnings, SessionSummary extensibility note
- [turn_models.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/api/models/turn_models.py) — Backend SessionSummary model
- [turn_models.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/core/models/turn_models.dart) — Mobile SessionSummary model
- [llm_groq.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/providers/llm_groq.py) — LLM provider with summary generation
- [session_complete_card.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart) — Session complete card UI
- [interview_state.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart) — InterviewSessionComplete state
- [sprint-status.yaml](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/sprint-status.yaml) — Sprint tracking

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.6 (GitHub Copilot)

### Debug Log References

No blockers encountered. Build runner warning about `defaultValue: <String>[]` vs constructor default is benign — `@JsonKey.defaultValue` handles missing JSON keys correctly during deserialization.

### Completion Notes List

- ✅ Task 1: `recommended_actions: list[str]` added to `SessionSummary` (backend) with `Field(default_factory=list)`. `@field_validator` enforces 0 or 2-4 items, each ≤ 25 words. Empty list (default) passes validation — backward compatible.
- ✅ Task 2: `_build_session_summary_prompt()` updated to include `recommended_actions` in the JSON schema string. Weakest 2 dimensions computed deterministically from `average_scores` via `sorted()` and passed to the LLM prompt. `generate_session_summary()` uses `setdefault("recommended_actions", [])` for graceful fallback when the LLM omits the key.
- ✅ Task 3: `recommendedActions: List<String>` added to `SessionSummary` in Dart with `@JsonKey(name: 'recommended_actions', defaultValue: <String>[])` and default constructor value `const <String>[]`. build_runner regenerated `.g.dart` successfully.
- ✅ Task 4: "What to Practice Next" section added to `SessionCompleteCard` between Improvements and Average Scores. Each action rendered as a `Row` with `Icons.arrow_forward` in `VoiceMockColors.secondary` (#27B39B). Section hidden when `recommendedActions.isEmpty`.
- ✅ Task 5: 9 new backend tests added — 7 in `test_turn_models.py` (5.1–5.2 coverage), 3 in `test_session_summary.py` (5.3–5.5 coverage). All 146 backend tests pass.
- ✅ Task 6: 3 new model tests (6.1–6.2 + serialize) in `turn_models_test.dart`, 2 widget tests (6.3–6.4) in `session_summary_test.dart`. All 413 mobile tests pass.
- Backward-compat verified: existing `SessionSummary` construction without `recommended_actions` returns `[]` on both backend and mobile.

### File List

**Backend:**

- `services/api/src/api/models/turn_models.py` — added `recommended_actions` field and `validate_recommended_actions` validator to `SessionSummary`
- `services/api/src/providers/llm_groq.py` — updated `_build_session_summary_prompt()` with `recommended_actions` schema + weakest-dimension targeting; added `setdefault` fallback in `generate_session_summary()`
- `services/api/tests/unit/test_turn_models.py` — added 7 new tests for `recommended_actions` constraints (5.1, 5.2)
- `services/api/tests/unit/test_session_summary.py` — added 3 new tests for generate_session_summary (5.3, 5.4, 5.5)

**Mobile:**

- `apps/mobile/lib/core/models/turn_models.dart` — added `recommendedActions` field to `SessionSummary`
- `apps/mobile/lib/core/models/turn_models.g.dart` — regenerated by build_runner
- `apps/mobile/lib/features/interview/presentation/widgets/session_complete_card.dart` — added "What to Practice Next" section (Tasks 4.1–4.4)
- `apps/mobile/test/core/models/turn_models_test.dart` — added 3 new tests for `recommendedActions` deserialization (6.1, 6.2)
- `apps/mobile/test/features/interview/presentation/widgets/session_summary_test.dart` — added 2 new widget tests for "What to Practice Next" section (6.3, 6.4)

**Planning:**

- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status updated: `ready-for-dev` → `in-progress` → `review`
- `_bmad-output/implementation-artifacts/4-3-recommended-next-actions-in-summary.md` — story file (this file)

### Change Log

- 2026-02-18: Implemented Story 4.3 — Recommended Next Actions in Summary. Added `recommended_actions` field to `SessionSummary` (backend + mobile), updated LLM prompt to target weakest rubric dimensions, rendered "What to Practice Next" section in `SessionCompleteCard`. 9 backend tests + 5 mobile tests added. Backend: 146/146 pass. Mobile: 413/413 pass.
