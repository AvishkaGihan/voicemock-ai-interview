# Story 5.4 — Diagnostics Screen: request_id, Timings, Last Error

**Epic:** 5 — Transparency, Security & Polish
**Status:** review
**Priority:** Medium
**Points:** 5

---

## Description

Provide a hidden diagnostics screen that displays per-turn timing metrics, request IDs, and the last error summary. This enables developers and testers to troubleshoot API latency issues, correlate backend logs via request IDs, and inspect error context without needing external tools.

> **Implemented So Far:** Significant diagnostics infrastructure already exists (models, widgets, page skeleton, router route, cubit integration). This story focuses on wiring the navigation paths, filling data gaps (TTS timing, session ID display, "Clear Diagnostics" action), and writing comprehensive tests to validate the feature end-to-end.

---

## Acceptance Criteria

### AC-1: Diagnostics Screen Accessible from Settings

- **Given** the user is on the Settings page
- **When** they tap a "Diagnostics" list tile
- **Then** the DiagnosticsPage opens, displaying session data from the current/last interview cubit

### AC-2: Diagnostics Screen Accessible from Interview (Debug)

- **Given** the user is in an active interview session
- **When** they access diagnostics (e.g., via Settings gear icon → Diagnostics tile, or via a debug gesture TBD)
- **Then** the DiagnosticsPage opens with live timing data from the active InterviewCubit

### AC-3: Session ID Displayed

- **Given** the DiagnosticsPage is open with data
- **When** the user views the page header
- **Then** the session ID is displayed prominently and is copyable to clipboard

### AC-4: Per-Turn Timing Records

- **Given** the user has completed one or more turns in the current session
- **When** they open DiagnosticsPage
- **Then** each turn shows: turn number, request ID (tap to copy), upload time, STT time, LLM time, total time — all in milliseconds

### AC-5: Last Error Summary

- **Given** an error occurred during the session
- **When** the user opens DiagnosticsPage
- **Then** an error summary card is shown at the top, displaying: error stage (e.g., "STT", "LLM"), request ID (tap to copy)

### AC-6: Empty State

- **Given** the user opens DiagnosticsPage with no turn data
- **When** the page renders
- **Then** a calm empty state is shown with icon and hint text ("No timing data yet — Complete a turn to see timing metrics")

### AC-7: TTS Timing Support

- **Given** TTS processing time is available from the backend response
- **When** a turn record is created
- **Then** TTS timing is captured in the `TurnTimingRecord` and displayed alongside other stage timings

### AC-8: Clear Diagnostics Action

- **Given** the user is on the DiagnosticsPage with data
- **When** they tap a "Clear Diagnostics" button (or equivalent action)
- **Then** all timing records and error metadata are cleared, and the page returns to the empty state

### AC-9: Request IDs Are Copyable

- **Given** any request ID is displayed (in timing rows or error summary)
- **When** the user taps on it
- **Then** the request ID is copied to clipboard with a confirmation snackbar

### AC-10: Off by Default

- **Given** the diagnostics feature
- **Then** it is not visible to the user unless accessed via a deliberate navigation path (Settings → Diagnostics) or debug mode

---

## Tasks

### Task 1: Add Diagnostics Navigation Tile to Settings Page

**File:** `apps/mobile/lib/features/settings/presentation/view/settings_page.dart`

- Add a new "Diagnostics" section or list tile below existing items
- Tile icon: `Icons.analytics_outlined`
- Tile subtitle: "View timing metrics & error info"
- On tap: Navigate to `/diagnostics` route, passing the `InterviewCubit` instance if available
- The tile should only be visible when there is an active/recent `InterviewCubit` in the widget tree (use `context.read<InterviewCubit>()` with a try-catch or `.tryRead()` pattern)

### Task 2: Add Session ID Display to DiagnosticsPage

**File:** `apps/mobile/lib/features/diagnostics/presentation/view/diagnostics_page.dart`

- Display the session ID from `SessionDiagnostics.sessionId` in the app bar subtitle or a header card
- Make the session ID tappable-to-copy (consistent with request ID copy pattern)
- Use monospace font for the ID value

### Task 3: Add TTS Timing to TurnTimingRecord

**File:** `apps/mobile/lib/core/models/turn_timing_record.dart`

- Add an optional `ttsMs` field (type `double?`) to `TurnTimingRecord`
- Update `props`, `copyWith`, and constructor
- Update all call-sites where `TurnTimingRecord` is created (in `InterviewCubit.submitTurn` and `InterviewCubit.retryLLM`) to pass `ttsMs` from `response.data.timings['tts_ms']`

### Task 4: Display TTS Timing in TimingRow Widget

**File:** `apps/mobile/lib/features/diagnostics/presentation/widgets/timing_row.dart`

- Add a `_TimingChip` for TTS timing (`record.ttsMs`) alongside the existing Upload, STT, LLM chips
- Keep conditional rendering consistent: only show if `record.ttsMs != null`

### Task 5: Add "Clear Diagnostics" Action

**Files:**

- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart` — Add a `clearDiagnostics()` method that resets `_diagnostics` to a fresh `SessionDiagnostics(sessionId: _sessionId)`
- `apps/mobile/lib/features/diagnostics/presentation/view/diagnostics_page.dart` — Add a "Clear" icon button in the AppBar actions that calls `cubit.clearDiagnostics()` and triggers a rebuild

### Task 6: Ensure Diagnostics Page Uses BlocBuilder for Reactivity

**File:** `apps/mobile/lib/features/diagnostics/presentation/view/diagnostics_page.dart`

- Currently the page reads diagnostics once via `cubit.diagnostics` in `build()`. This won't update live.
- If live updates are desired during an active interview, consider using a `BlocBuilder` or `BlocListener` pattern. However, since diagnostics is read on page entry, the current approach may be acceptable for MVP.
- **Decision:** Keep the current read-once pattern for MVP. The page snapshots diagnostics when opened.

### Task 7: Write Unit Tests

**Files:**

- `apps/mobile/test/core/models/turn_timing_record_test.dart` — Test `ttsMs` field in constructor, `props`, and `copyWith`
- `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_diagnostics_test.dart` — Test `clearDiagnostics()` method, verify diagnostics accumulation across turns, and error recording
- `apps/mobile/test/features/diagnostics/presentation/view/diagnostics_page_test.dart` — Widget tests for: empty state rendering, timing rows display, error summary card, session ID display, copy-to-clipboard interactions

### Task 8: Write Widget Tests for Settings Diagnostics Tile

**File:** `apps/mobile/test/features/settings/presentation/view/settings_page_diagnostics_test.dart`

- Test that the Diagnostics tile appears when an InterviewCubit is available in the tree
- Test that tapping the tile navigates to `/diagnostics`
- Test that the tile does not appear when no InterviewCubit is available

---

## Dev Notes

### Existing Infrastructure (Already Built)

The following files already exist and are functional — Story 5.4 extends and wires them together:

| File                                                                    | What It Does                                                                        |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `lib/core/models/session_diagnostics.dart`                              | Session-level diagnostics accumulator with `addTurn()` and `recordError()`          |
| `lib/core/models/turn_timing_record.dart`                               | Per-turn timing model (upload, STT, LLM, total)                                     |
| `lib/features/diagnostics/presentation/view/diagnostics_page.dart`      | Page with empty state + list view of timing rows + error card                       |
| `lib/features/diagnostics/presentation/widgets/error_summary_card.dart` | Error card with request ID copy-to-clipboard                                        |
| `lib/features/diagnostics/presentation/widgets/timing_row.dart`         | Per-turn card with timing chips + request ID copy                                   |
| `lib/app/router.dart`                                                   | `/diagnostics` route already registered, accepts `InterviewCubit` via `state.extra` |

### Cubit Integration (Already Built)

- `InterviewCubit._diagnostics` is initialized in the constructor with `SessionDiagnostics(sessionId: sessionId)`
- `InterviewCubit.diagnostics` getter exposes it publicly
- `submitTurn()` creates `TurnTimingRecord` from `response.data.timings` and calls `_diagnostics.addTurn()`
- `retryLLM()` also creates timing records and updates diagnostics
- `handleError()` calls `_diagnostics.recordError()` for failures with stage + request ID

### What Needs to Be Added

1. **Navigation wiring** — Settings page → `/diagnostics` with cubit passthrough
2. **Session ID display** — Show `diagnostics.sessionId` prominently on DiagnosticsPage
3. **TTS timing** — Add `ttsMs` field to `TurnTimingRecord` + wire from response + display in `TimingRow`
4. **Clear action** — `clearDiagnostics()` on cubit + clear button on page
5. **Comprehensive tests** — Unit and widget tests covering all acceptance criteria

### Architecture Compliance

- **State Management:** Uses existing `flutter_bloc` cubit pattern. No new cubits needed.
- **Navigation:** Uses existing `go_router` configuration. Diagnostics route already exists.
- **Styling:** Follow existing Calm Ocean theme tokens (`VoiceMockColors`, `VoiceMockTypography`). Note: current diagnostics widgets use inline `Color()` values — a polish pass could align them with theme tokens, but is not required for this story.
- **Clipboard:** Use `Clipboard.setData()` + `SnackBar` confirmation (pattern already established in `ErrorSummaryCard` and `TimingRow`).

### UX Design Compliance

- **Hidden by default:** Diagnostics is accessed via Settings only, not surfaced in the main interview flow (per UX spec § Privacy & Data Defaults)
- **Copyable request IDs:** All request IDs are tappable to copy (per UX spec: "If a request ID is shown to the user, it must be copyable")
- **Empty state:** Calm, non-alarming empty state with icon + hint text (consistent with UX Loading/Empty patterns)
- **Debug labeling:** Settings tile should clearly indicate this is a debug/diagnostic feature, per: "If debug/diagnostics mode is enabled, label it clearly and keep it off by default"

### Dependencies

- **Story 5.3** (Safety Constraints) — Completed. The `content_refused` error flow records error metadata in diagnostics via `handleError()`.
- **No backend changes required** — All timing data (`upload_ms`, `stt_ms`, `llm_ms`, `tts_ms`, `total_ms`) is already available in the `/turn` response envelope.

### API Contract Reference

The `/turn` endpoint response includes:

```json
{
  "data": {
    "timings": {
      "upload_ms": 120.5,
      "stt_ms": 340.2,
      "llm_ms": 890.1,
      "tts_ms": 250.0,
      "total_ms": 1600.8
    }
  },
  "request_id": "req_abc123",
  "error": null
}
```

### Testing Strategy

- **Unit tests:** `TurnTimingRecord` (ttsMs field), `InterviewCubit.clearDiagnostics()`
- **Widget tests:** DiagnosticsPage (empty state, data display, copy actions), Settings tile (visibility, navigation)
- **Existing tests:** Review and update `diagnostics_page_test.dart`, `session_diagnostics_test.dart`, `interview_cubit_diagnostics_test.dart` if they need changes for new fields/methods

### Risks & Mitigations

| Risk                                                                       | Mitigation                                                 |
| -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Cubit may not be available when navigating from Settings (interview ended) | Try-catch or null-safe read; show empty state gracefully   |
| TTS timing may not be present in all backend responses                     | `ttsMs` is optional (`double?`); conditionally render chip |
| Theme inconsistency (inline colors vs theme tokens)                        | Acceptable for MVP; track as tech debt for polish pass     |

---

## Story Progress

| Task                             | Status                       |
| -------------------------------- | ---------------------------- |
| Task 1: Settings Navigation Tile | [x]                          |
| Task 2: Session ID Display       | [x]                          |
| Task 3: TTS Timing in Model      | [x]                          |
| Task 4: TTS Timing in Widget     | [x]                          |
| Task 5: Clear Diagnostics Action | [x]                          |
| Task 6: Reactivity Decision      | [x] (Keep read-once for MVP) |
| Task 7: Unit Tests               | [x]                          |
| Task 8: Widget Tests             | [x]                          |

---

## Dev Agent Record

### Debug Log

- Implemented diagnostics access from Settings using safe `InterviewCubit` lookup from widget tree and route push with `extra` cubit payload.
- Extended diagnostics model and cubit mapping for `tts_ms` propagation (`submitTurn` and `retryLLM` call paths).
- Added diagnostics page enhancements: session ID header with copy action, clear diagnostics app bar action, and empty-state consistency.
- Added TTS chip rendering in timing rows with conditional display.
- Completed analyzer and test quality gates (`flutter analyze`, targeted tests, and full test suite).

### Completion Notes

- ✅ AC-1/AC-2: Diagnostics is reachable from Settings when `InterviewCubit` is available and routes to `/diagnostics` with cubit context.
- ✅ AC-3: Session ID now renders in diagnostics header and is copyable with snackbar confirmation.
- ✅ AC-4/AC-7: Per-turn records include upload/STT/LLM/total plus optional TTS timing in UI.
- ✅ AC-5/AC-6/AC-9: Existing error summary, empty-state behavior, and request ID copy interactions are covered and validated.
- ✅ AC-8: Added `InterviewCubit.clearDiagnostics()` and wired diagnostics clear action in page app bar.
- ✅ AC-10: Diagnostics remains off by default from primary flow and exposed via deliberate path in Settings.
- ✅ Validation: targeted tests pass (20/20), full suite passes (457/457), analyzer passes cleanly.

## File List

- apps/mobile/lib/core/models/turn_timing_record.dart
- apps/mobile/lib/features/settings/presentation/view/settings_page.dart
- apps/mobile/lib/features/diagnostics/presentation/view/diagnostics_page.dart
- apps/mobile/lib/features/diagnostics/presentation/widgets/timing_row.dart
- apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart
- apps/mobile/test/core/models/turn_timing_record_test.dart
- apps/mobile/test/features/diagnostics/presentation/view/diagnostics_page_test.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_diagnostics_test.dart
- apps/mobile/test/features/settings/presentation/view/settings_page_diagnostics_test.dart
- \_bmad-output/implementation-artifacts/sprint-status.yaml
- \_bmad-output/implementation-artifacts/5-4-diagnostics-screen-request-id-timings-last-error.md

## Change Log

- 2026-02-19: Implemented Story 5.4 diagnostics completion (settings navigation, session ID copy UX, TTS timing capture/display, clear diagnostics action) and added comprehensive unit/widget coverage.
- 2026-02-19: [AI-Review] Refactored `TurnTimingRecord` to use factory constructor, improved `SettingsPage` and `DiagnosticsPage` state access safety, and applied theme tokens to diagnostics widgets. Verified with tests.

## Status

done
