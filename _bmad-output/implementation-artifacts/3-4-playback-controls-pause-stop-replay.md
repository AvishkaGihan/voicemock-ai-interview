# Story 3.4: Playback controls (pause/stop/replay)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to pause, stop, or replay the last interviewer response,
So that I can listen carefully.

## Acceptance Criteria

1. **Given** the AI response is playing (Speaking state with non-empty `ttsAudioUrl`)
   **When** I tap the "Stop" control
   **Then** playback stops immediately
   **And** the cubit transitions from Speaking → Ready (next question)
   **And** the `responseText` remains visible in the turn card

2. **Given** the AI response is playing (Speaking state)
   **When** I tap the "Pause" control
   **Then** playback pauses at the current position
   **And** the UI shows a "Resume" control in place of "Pause"
   **And** the cubit remains in Speaking state (no premature transition)

3. **Given** playback is paused
   **When** I tap the "Resume" control
   **Then** playback resumes from the paused position
   **And** the UI reverts to showing the "Pause" control

4. **Given** the AI response has finished playing or was stopped
   **When** the user is in Ready state with the last `ttsAudioUrl` still available
   **Then** a "Replay" control is visible in the turn card
   **And** tapping "Replay" re-fetches and re-plays the last response audio
   **And** the cubit transitions from Ready → Speaking for the duration of replay

5. **Given** the user replays the last response
   **When** replay completes or the user stops it
   **Then** the cubit transitions back to Ready (same question)
   **And** the Hold-to-Talk button re-enables

6. **Given** playback controls (pause/stop/replay) are rendered
   **When** accessibility tools inspect them
   **Then** each control has a descriptive semantic label (e.g., "Pause coach audio", "Stop coach audio", "Replay last response")
   **And** minimum 44dp tap targets are met

7. **Given** the `ttsAudioUrl` has expired (>5 min TTL)
   **When** the user taps "Replay"
   **Then** the app shows a non-alarming inline message ("Response audio expired")
   **And** stays in Ready state (no crash, no error sheet)

## Tasks / Subtasks

### Task 1: Add `pause()` and `resume()` to `PlaybackService` (AC: #2, #3)

- [x] 1.1 Add `Future<void> pause()` method to `PlaybackService`:
  - Call `_audioPlayer.pause()` — `just_audio` preserves seek position
  - Guard: no-op if `!_enabled` or player is null
- [x] 1.2 Add `Future<void> resume()` method to `PlaybackService`:
  - Call `_audioPlayer.play()` — resumes from paused position
  - Guard: no-op if `!_enabled` or player is null
- [x] 1.3 Add `bool get isPaused` getter:
  - Returns `true` when `_audioPlayer?.playing == false` and `processingState` is not `idle`/`completed`
- [x] 1.4 Extend `PlaybackEvent` sealed class — add `PlaybackPaused`:
  - `final class PlaybackPaused extends PlaybackEvent { const PlaybackPaused(); }`
  - Emit `PlaybackPaused()` in `pause()` method
  - Emit `PlaybackPlaying()` in `resume()` method
- [x] 1.5 Update `PlaybackService.noop()` — `pause()` and `resume()` should be no-ops in noop mode
- [x] 1.6 Export remains unchanged — `playback_service.dart` already exported from `audio.dart`

### Task 2: Add `replay()` capability to `PlaybackService` (AC: #4, #5, #7)

- [x] 2.1 Add `Future<void> replay(String url, {String? bearerToken})`:
  - Delegates to existing `playUrl()` (replay = stop + re-play the same URL)
  - This is a convenience alias for clarity; `playUrl()` already calls `stop()` first
  - **Note:** Replay is just calling `playUrl()` again with the same TTS URL; no separate implementation needed

### Task 3: Add playback control methods to `InterviewCubit` (AC: #1–#5)

- [x] 3.1 Add `void pausePlayback()` method:
  - Guard: only valid from `InterviewSpeaking` state
  - Call `_playbackService.pause()`
  - Emit `InterviewSpeaking` with an `isPaused: true` field (see Task 4)
- [x] 3.2 Add `void resumePlayback()` method:
  - Guard: only valid from `InterviewSpeaking` state with `isPaused == true`
  - Call `_playbackService.resume()`
  - Emit `InterviewSpeaking` with `isPaused: false`
- [x] 3.3 Add `void stopPlayback()` method:
  - Guard: only valid from `InterviewSpeaking` state
  - Call `_playbackService.stop()`
  - Call existing `onSpeakingComplete()` to transition Speaking → Ready
- [x] 3.4 Add `void replayLastResponse()` method:
  - Guard: only valid from `InterviewReady` state where `_lastTtsAudioUrl` is non-empty
  - Transition to `InterviewSpeaking` state (re-use existing `onResponseReady()` flow)
  - Call `_startPlayback(_lastTtsAudioUrl)` to play the audio again
  - On completion/error: return to Ready (same question, no advancement)
- [x] 3.5 Add private field `String _lastTtsAudioUrl = ''` to `InterviewCubit`:
  - Set this in `_startPlayback()` to remember the last-played TTS URL
  - Clear this on `cancel()` or session complete
- [x] 3.6 Add private field `String _lastResponseText = ''`:
  - Set alongside `_lastTtsAudioUrl` in `onResponseReady()`
  - Used to reconstruct `InterviewSpeaking` state during replay
- [x] 3.7 Modify `_startPlayback()` error handling for replay:
  - On 404 error during replay (expired URL): transition to Ready state with inline message
  - Distinguish between initial playback error (existing behavior) and replay error (non-alarming)
- [x] 3.8 Add `bool get canReplay` getter:
  - Returns `true` when state is `InterviewReady` and `_lastTtsAudioUrl.isNotEmpty`

### Task 4: Add `isPaused` field to `InterviewSpeaking` state (AC: #2, #3)

- [x] 4.1 Add `final bool isPaused` field to `InterviewSpeaking` class:
  - Default: `false`
  - Add to `props` list for Equatable
  - This is the ONLY state class change — keep it minimal
- [x] 4.2 Update `InterviewSpeaking` constructor to accept optional `isPaused` parameter

### Task 5: Add `lastTtsAudioUrl` field to `InterviewReady` state (AC: #4)

- [x] 5.1 Add `final String lastTtsAudioUrl` field to `InterviewReady` class:
  - Default: `''`
  - Add to `props` list for Equatable
  - Used by the view to show/hide the "Replay" control
- [x] 5.2 Update `onSpeakingComplete()` to pass `lastTtsAudioUrl` when transitioning to Ready

### Task 6: Build `PlaybackControlBar` widget (AC: #1, #2, #3, #6)

- [x] 6.1 Create `apps/mobile/lib/features/interview/presentation/widgets/playback_control_bar.dart`:
  - A row of icon buttons: Pause/Resume (toggle) | Stop
  - Accept: `isPaused` (bool), `onPause`, `onResume`, `onStop` callbacks
  - Material 3 IconButton with Filled Tonal style
  - Semantic labels: "Pause coach audio", "Resume coach audio", "Stop coach audio"
  - Minimum 44dp touch targets (already default for Material 3 IconButton)
- [x] 6.2 Style using Calm Ocean design tokens:
  - Secondary accent for controls during Speaking state
  - Subtle container background to visually group controls
- [x] 6.3 Export from `apps/mobile/lib/features/interview/presentation/widgets/widgets.dart`

### Task 7: Add "Replay" button to `TurnCard` (AC: #4, #5, #6, #7)

- [x] 7.1 Add optional `onReplay` callback to `TurnCard` widget:
  - When provided (non-null), render a secondary "Replay" button beneath the response text
  - Icon: `Icons.replay` + label "Replay response"
  - Outlined button style (secondary action per button hierarchy)
  - Semantic label: "Replay last response"
- [x] 7.2 Wire in `_buildTurnCard()` for `InterviewReady` case:
  - Pass `onReplay` callback only when `state.lastTtsAudioUrl.isNotEmpty`
  - Callback: `context.read<InterviewCubit>().replayLastResponse()`

### Task 8: Wire `PlaybackControlBar` into `InterviewView` (AC: #1, #2, #3)

- [x] 8.1 In `_buildTurnCard()` for `InterviewSpeaking` case:
  - Add `PlaybackControlBar` below the `TurnCard` (or inside it below `responseText`)
  - Pass `isPaused: state.isPaused`
  - Wire `onPause`, `onResume`, `onStop` to cubit methods
- [x] 8.2 Alternatively: embed controls inside the existing `TurnCard` widget for `InterviewSpeaking` state
  - Decide based on layout stability — the turn card area is scrollable, so controls in the card won't cause layout jumps

### Task 9: Handle expired TTS during replay (AC: #7)

- [x] 9.1 In `replayLastResponse()`, catch playback errors:
  - If error occurs during replay: show a SnackBar "Response audio expired" (non-alarming)
  - Transition back to Ready, do NOT show the full error recovery sheet
  - Log the expired URL with `developer.log`

### Task 10: Write unit tests (AC: #1–#7)

- [x] 10.1 Update `apps/mobile/test/core/audio/playback_service_test.dart`:
  - Test: `pause()` pauses playback
  - Test: `resume()` resumes from paused position
  - Test: `isPaused` getter returns correct state
  - Test: `PlaybackPaused` event emitted on pause
  - Test: `PlaybackPlaying` event emitted on resume
  - Test: `pause()` is no-op in noop mode
  - Test: `resume()` is no-op in noop mode
- [x] 10.2 Update `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart`:
  - Test: `pausePlayback()` from Speaking → Speaking(isPaused: true)
  - Test: `resumePlayback()` from Speaking(isPaused: true) → Speaking(isPaused: false)
  - Test: `stopPlayback()` from Speaking → Ready
  - Test: `replayLastResponse()` from Ready → Speaking → Ready (same question)
  - Test: `replayLastResponse()` is rejected if `_lastTtsAudioUrl` is empty
  - Test: `replayLastResponse()` handles expired URL gracefully
  - Test: `pausePlayback()` is rejected from non-Speaking states
  - Test: `canReplay` returns correct value based on state and URL
- [x] 10.3 Create `apps/mobile/test/features/interview/presentation/widgets/playback_control_bar_test.dart`:
  - Test: renders Pause and Stop buttons when not paused
  - Test: renders Resume and Stop buttons when paused
  - Test: tapping Pause calls `onPause`
  - Test: tapping Resume calls `onResume`
  - Test: tapping Stop calls `onStop`
  - Test: all buttons have correct semantic labels
- [x] 10.4 Update existing `TurnCard` tests (if any):
  - Test: "Replay" button shown when `onReplay` is provided
  - Test: "Replay" button hidden when `onReplay` is null
- [x] 10.5 Run full test suite: `cd apps/mobile && flutter test`

### Task 11: Verify integration (AC: #1–#5)

- [x] 11.1 Build and run: `cd apps/mobile && flutter run`
- [x] 11.2 Test pause/resume during AI speaking — audio should pause and resume cleanly
- [x] 11.3 Test stop during AI speaking — should immediately transition to Ready
- [x] 11.4 Test replay after response finishes — should re-play the last response
- [x] 11.5 Test replay after 5+ minutes — should show expiry message gracefully
- [x] 11.6 Verify Hold-to-Talk is disabled during replay (Speaking state enforces this)
- [x] 11.7 Verify layout stability — no jumps when controls appear/disappear

## Dev Notes

### Existing Infrastructure (ALREADY BUILT — leverage, don't rebuild)

**`PlaybackService`** (`apps/mobile/lib/core/audio/playback_service.dart`):

- Already has `playUrl(url, {bearerToken})`, `stop()`, `dispose()`
- Already has `PlaybackEvent` sealed class with `PlaybackPlaying`, `PlaybackCompleted`, `PlaybackError`
- Already enforces no-overlap: `playUrl()` calls `stop()` before new play
- Already handles auth headers via `AudioSource.uri(headers: ...)`
- **Needs:** `pause()`, `resume()`, `isPaused` getter, `PlaybackPaused` event

**`InterviewCubit`** (`apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`):

- Already has `_startPlayback(ttsAudioUrl)` — fetches and plays TTS audio
- Already has `onSpeakingComplete()` — transitions Speaking → Ready
- Already has `_handleSpeakingInterruption()` — stops playback on audio focus loss
- Already subscribes to `PlaybackEvent` stream in `_startPlayback()`
- Already resolves relative TTS URLs via `_resolveTtsUrl()`
- **Needs:** `pausePlayback()`, `resumePlayback()`, `stopPlayback()`, `replayLastResponse()`, `_lastTtsAudioUrl`/`_lastResponseText` fields

**`InterviewSpeaking` state** (`interview_state.dart`):

- Already has all turn context: `questionNumber`, `totalQuestions`, `questionText`, `transcript`, `responseText`, `ttsAudioUrl`
- **Needs:** `isPaused` bool field (default `false`)

**`InterviewReady` state** (`interview_state.dart`):

- Already has `questionNumber`, `totalQuestions`, `questionText`, `previousTranscript`, `wasInterrupted`
- **Needs:** `lastTtsAudioUrl` string field (default `''`) for replay eligibility

**`InterviewView`** (`interview_view.dart`):

- Already renders `TurnCard` during `InterviewSpeaking` with `responseText` visible
- Already disables Hold-to-Talk during Speaking (line 290: `isEnabled = state is InterviewReady || state is InterviewRecording`)
- Turn card area is scrollable — controls can be added without layout jumps
- **Needs:** `PlaybackControlBar` during Speaking state, "Replay" button during Ready state when replay is available

**`TurnCard`** widget:

- Already renders question, transcript, and response text
- **Needs:** optional `onReplay` callback for "Replay" button

### What Needs to Be Built

This story adds **user-facing playback controls** on top of the existing audio infrastructure:

1. **`PlaybackService` extensions** — Add `pause()`, `resume()`, `isPaused`, and `PlaybackPaused` event
2. **Cubit control methods** — `pausePlayback()`, `resumePlayback()`, `stopPlayback()`, `replayLastResponse()`
3. **State extensions** — `isPaused` on `InterviewSpeaking`, `lastTtsAudioUrl` on `InterviewReady`
4. **`PlaybackControlBar` widget** — New widget with Pause/Resume/Stop buttons
5. **Replay button in TurnCard** — "Replay response" button when last TTS URL is available
6. **View wiring** — Integrate controls into `InterviewView`
7. **Expired URL handling** — Graceful snackbar for 404 on replay
8. **Tests** — Unit tests for service, cubit, and widget

### Architecture-Mandated Patterns

From architecture.md:

- **Audio stack:** `just_audio 0.10.5` for playback — `pause()` and `play()` (resume) are native `AudioPlayer` methods
- **Audio location:** `PlaybackService` extensions stay in `apps/mobile/lib/core/audio/playback_service.dart`
- **State management:** `InterviewCubit` owns all playback lifecycle; UI ONLY renders state
- **No overlap:** Replay triggers the same `_startPlayback()` flow that enforces stop-before-play
- **Concurrency rules:** Replay transitions to Speaking, which disables recording (existing guard)
- **Feature structure:** New widget goes in `apps/mobile/lib/features/interview/presentation/widgets/`
- **No parallel local bool flags:** UI reads `isPaused` from Cubit state, never from local variables

### UX Specifications (from ux-design-specification.md)

- **Turn-taking rules (non-negotiable):** "Provide an explicit Stop speaking control during AI speech" (line 854) — this story fulfills this requirement
- **Playback pattern:** "Provide Replay question consistently" (line 865) — implemented as replay of last response
- **Button hierarchy:** Stop/Pause are secondary actions (Filled Tonal), Replay is an Outlined button
- **Component Strategy Phase 1:** "Basic audio controls (Stop/Replay question)" — listed as MVP-critical
- **Accessibility semantics:** "Stop coach audio" (line 1028), "Replay question" (line 1029) — use these exact labels
- **Calm, non-alarming errors:** expired TTS on replay is a soft inline message, not an error sheet
- **Speaking state styling:** "Subtle secondary accent to indicate 'AI turn'" — controls should use this accent

### Previous Story Learnings (from Story 3.3)

- **`just_audio.AudioPlayer.pause()`** preserves seek position — resume with `player.play()`
- **`PlaybackService` wraps `AudioPlayer`** — all interactions go through the service, never direct player access
- **Event-driven architecture** — cubit reacts to `PlaybackEvent` stream; extend with `PlaybackPaused`
- **No new `AudioPlayer` per replay** — reuse the single player instance; `playUrl()` already handles stop+re-source
- **Auth headers on every request** — including replay; pass `bearerToken` to `playUrl()`
- **TTS URL is relative** — `_resolveTtsUrl()` prepends base URL; reuse for replay
- **80-char line length for Dart** — follow linting rules
- **Feature branches:** Use pattern `feature/story-3-4-short-description`
- **Conventional commits:** `feat:`, `fix:`, `test:` prefixes

### Git Intelligence (Recent Commits)

```
2fa4591 Merge pull request — Story 3.3 playback queue with no overlap
d1d33cb feat(interview): pass InterviewCubit to DiagnosticsPage during navigation
afe1c1c Merge pull request — Story 3.2 GET /tts endpoint
403addf docs: Add sprint status tracking and Epic 2 retrospective documents
3368853 Merge pull request #19 — Handle interruptions during recording
```

Key observations:

- Story 3.3 (playback queue) is DONE — this story adds controls ON TOP of that infrastructure
- `PlaybackService` is brand new from Story 3.3 — extend it, don't refactor it
- Feature branch naming: `feature/story-3-4-playback-controls`
- Commit convention: `feat:`, `fix:`, `test:` prefixes used consistently

### `just_audio` Pause/Resume API Notes

**Pause:**

```dart
await player.pause();
// player.playing == false, position preserved
```

**Resume (just call play again):**

```dart
await player.play();
// Resumes from paused position
```

**Check if paused:**

```dart
final isPaused = !player.playing &&
    player.processingState != ProcessingState.idle &&
    player.processingState != ProcessingState.completed;
```

### Critical Naming Conventions

- **File names:** `snake_case` — `playback_control_bar.dart`
- **Class names:** `PascalCase` — `PlaybackControlBar`, `PlaybackPaused`
- **Method names:** `lowerCamelCase` — `pausePlayback()`, `resumePlayback()`, `stopPlayback()`, `replayLastResponse()`
- **Test file:** `playback_control_bar_test.dart` in `apps/mobile/test/features/interview/presentation/widgets/`
- **Parameters:** `lowerCamelCase` — `isPaused`, `onPause`, `onResume`, `onStop`, `onReplay`, `lastTtsAudioUrl`

### Gotchas / Anti-Patterns to Avoid

1. **DO NOT put pause/resume logic in the View** — The `InterviewCubit` owns the state machine. The view calls `cubit.pausePlayback()`, never `playbackService.pause()` directly.

2. **DO NOT create a separate "Replaying" state** — Replay reuses `InterviewSpeaking`. The cubit internally tracks whether this is a replay or initial play; the UI treats them identically.

3. **DO NOT advance to the next question on replay completion** — When replay finishes, restoring to the SAME Ready state (same `questionNumber`) is critical. Replay is "re-listen", not "next turn".

4. **DO NOT show the error recovery sheet on replay failure** — Replay expiry is not a turn-blocking error. Show a SnackBar, stay in Ready, done.

5. **DO NOT add a `position` or `duration` stream to the cubit** — MVP controls are discrete (pause/resume/stop/replay), NOT a scrubber/timeline. Complex playback progress tracking is post-MVP.

6. **DO NOT modify `_startPlayback()` to emit different states** — `_startPlayback()` already works. Use flags (`_isReplay`) to decide what happens on completion, not different playback flows.

7. **DO NOT forget to clear `_lastTtsAudioUrl` on `cancel()`** — If the session ends, replay should not be possible after cancellation.

8. **DO NOT add `isPaused` to the `PlaybackService` as a stream** — A simple `bool get isPaused` getter is sufficient. The cubit manages state transitions; it doesn't need to subscribe to a pause stream.

9. **DO NOT break existing tests** — Story 3.3 tests all pass. Adding `isPaused` to `InterviewSpeaking` may require updating test assertions. Update ONLY the assertions that check `props`, not the test logic.

10. **DO NOT change the `InterviewSpeaking` constructor to be breaking** — `isPaused` must default to `false` so all existing code continues to work without changes.

### File Inventory

**Files to create:**

- `apps/mobile/lib/features/interview/presentation/widgets/playback_control_bar.dart` — PlaybackControlBar widget

**Files to create (tests):**

- `apps/mobile/test/features/interview/presentation/widgets/playback_control_bar_test.dart` — PlaybackControlBar widget tests

**Files to modify:**

- `apps/mobile/lib/core/audio/playback_service.dart` — Add `pause()`, `resume()`, `isPaused`, `PlaybackPaused` event
- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart` — Add `isPaused` to `InterviewSpeaking`, `lastTtsAudioUrl` to `InterviewReady`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart` — Add `pausePlayback()`, `resumePlayback()`, `stopPlayback()`, `replayLastResponse()`, `_lastTtsAudioUrl`/`_lastResponseText` fields
- `apps/mobile/lib/features/interview/presentation/view/interview_view.dart` — Wire PlaybackControlBar during Speaking, Replay button during Ready
- `apps/mobile/lib/features/interview/presentation/widgets/widgets.dart` — Export `playback_control_bar.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/turn_card.dart` — Add optional `onReplay` callback
- `apps/mobile/test/core/audio/playback_service_test.dart` — Tests for pause/resume
- `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart` — Tests for playback control methods

**Files to validate (likely NO changes):**

- `apps/mobile/lib/core/audio/audio.dart` — Barrel file, already exports `playback_service.dart`
- `apps/mobile/lib/core/audio/audio_focus_service.dart` — No changes needed
- `apps/mobile/lib/features/interview/presentation/view/interview_page.dart` — No new DI needed (PlaybackService already provided)
- `apps/mobile/pubspec.yaml` — No new dependencies needed (`just_audio` already added in Story 3.3)

### Project Structure Notes

- `PlaybackControlBar` goes in `apps/mobile/lib/features/interview/presentation/widgets/` — consistent with `HoldToTalkButton`, `TurnCard`, etc.
- Tests go in matching mirror path under `test/`
- No new directories needed — extends existing audio module and widget directory
- Follows same DI pattern: no new service injection required (PlaybackService already injected in Story 3.3)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.4] — FR25, acceptance criteria
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] — `just_audio 0.10.5`, pause/resume API
- [Source: _bmad-output/planning-artifacts/architecture.md#State Management Patterns] — InterviewCubit state machine
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice and Audio Interaction Patterns] — Stop speaking control, Replay pattern
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Component Strategy] — Basic audio controls (Stop/Replay) listed MVP-critical
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Accessibility Semantics Checklist] — "Stop coach audio", "Replay question" labels
- [Source: _bmad-output/implementation-artifacts/3-3-android-playback-queue-with-no-overlap.md] — PlaybackService implementation details
- [Source: apps/mobile/lib/core/audio/playback_service.dart] — Current PlaybackService code
- [Source: apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart] — Current InterviewCubit with \_startPlayback()
- [Source: apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart] — InterviewSpeaking, InterviewReady state classes
- [Source: apps/mobile/lib/features/interview/presentation/view/interview_view.dart] — Current UI rendering logic

### Change Log

| Date       | Change                                                                                          | Author                 |
| ---------- | ----------------------------------------------------------------------------------------------- | ---------------------- |
| 2026-02-17 | Story 3.4 created — playback controls (pause/stop/replay) for MVP                               | Antigravity (SM Agent) |
| 2026-02-18 | Implemented Tasks 1-10 with passing automated tests; Task 11 pending device/manual verification | Amelia (Dev Agent)     |
| 2026-02-18 | Manual verification completed for Task 11; story moved to review                                | Amelia (Dev Agent)     |

## Dev Agent Record

### Debug Log

- Updated sprint tracking to `in-progress` for `3-4-playback-controls-pause-stop-replay`.
- Implemented playback pause/resume/replay service APIs and `PlaybackPaused` event.
- Extended interview state/cubit and wired replay + speaking controls into UI.
- Added/updated unit and widget tests for playback service, cubit playback controls, control bar, and replay button visibility.
- Ran targeted test files plus full suite (`335` passed, `0` failed).
- Attempted `flutter run -d windows -t lib/main_development.dart`; blocked by missing Visual Studio toolchain (`flutter doctor` required).
- Manual verification completed by user for Task 11 integration scenarios.
- Updated story status to `review`.

### Completion Notes

- Completed implementation and automated validation for Tasks `1.1` through `10.5`.
- Completed manual verification for Tasks `11.1` through `11.7`.
- Story status updated to `review` and ready for code review workflow.

## File List

- apps/mobile/lib/core/audio/playback_service.dart
- apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart
- apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart
- apps/mobile/lib/features/interview/presentation/view/interview_view.dart
- apps/mobile/lib/features/interview/presentation/widgets/turn_card.dart
- apps/mobile/lib/features/interview/presentation/widgets/widgets.dart
- apps/mobile/lib/features/interview/presentation/widgets/playback_control_bar.dart
- apps/mobile/test/core/audio/playback_service_test.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart
- apps/mobile/test/features/interview/presentation/widgets/turn_card_test.dart
- apps/mobile/test/features/interview/presentation/widgets/playback_control_bar_test.dart
- \_bmad-output/implementation-artifacts/3-4-playback-controls-pause-stop-replay.md
- \_bmad-output/implementation-artifacts/sprint-status.yaml
