# Story 3.3: Android playback queue with no overlap

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want the app to play exactly one response at a time,
So that I never hear overlapping speech.

## Acceptance Criteria

1. **Given** a TTS audio response is ready (non-empty `tts_audio_url` in `InterviewSpeaking` state)
   **When** the app enters Speaking state
   **Then** it fetches audio from `GET /tts/{request_id}` and plays it using `just_audio`
   **And** the Hold-to-Talk button is disabled during playback

2. **Given** audio is already playing (Speaking state)
   **When** a new response arrives (e.g., rapid-fire edge case)
   **Then** the app stops/cancels the current playback before starting the new one
   **And** no audio overlap occurs (0ms overlap per NFR7)

3. **Given** audio playback finishes normally
   **When** the player reports completion
   **Then** the `InterviewCubit` transitions from Speaking → Ready (next question)
   **And** the Hold-to-Talk button re-enables

4. **Given** audio playback fails (network error, decode error, corrupted audio)
   **When** the player reports an error
   **Then** the app shows `assistant_text` as readable text (voice-first, not voice-only fallback)
   **And** transitions to Ready state so the user can continue
   **And** the failure is logged with the `request_id`

5. **Given** recording is not allowed while speaking
   **When** the app is in Speaking state
   **Then** `InterviewCubit` rejects `startRecording()` calls (existing guard)
   **And** the UI disables the Hold-to-Talk button

6. **Given** the app loses audio focus during playback (e.g., phone call, notification)
   **When** an audio interruption event occurs
   **Then** playback stops cleanly
   **And** the app transitions to Ready state with the response text still visible

7. **Given** the user navigates away or cancels the session during playback
   **When** the session is cancelled or the widget is disposed
   **Then** playback stops and all audio resources are released
   **And** no leaked player instances remain

## Tasks / Subtasks

### Task 1: Add `just_audio` dependency (AC: #1)

- [x] 1.1 Add `just_audio: ^0.10.5` to `apps/mobile/pubspec.yaml` dependencies
- [x] 1.2 Run `flutter pub get` to verify resolution
- [x] 1.3 Verify no conflicts with existing `audio_session` or `record` packages

### Task 2: Create `PlaybackService` in `core/audio/` (AC: #1, #2, #3, #6)

- [x] 2.1 Create `apps/mobile/lib/core/audio/playback_service.dart`:
  - Wrap `just_audio.AudioPlayer`
  - Method: `Future<void> playUrl(String url, {String? bearerToken})` — sets URL source with auth headers and starts playback
  - Method: `Future<void> stop()` — stops current playback immediately
  - Method: `Future<void> dispose()` — releases the player
  - Getter: `bool get isPlaying` — current playback status
  - Stream: `Stream<PlaybackEvent>` — exposes player state changes (playing, completed, error)
  - **CRITICAL**: `playUrl()` must call `stop()` before starting new playback to enforce no-overlap
  - **CRITICAL**: Pass `Authorization: Bearer <token>` header when loading URL (TTS endpoint requires auth)
- [x] 2.2 Define `PlaybackEvent` enum/sealed class: `playing`, `completed`, `error(String message)`
- [x] 2.3 Export `playback_service.dart` from barrel file `apps/mobile/lib/core/audio/audio.dart`

### Task 3: Wire `PlaybackService` into `InterviewCubit` (AC: #1, #2, #3, #4, #6)

- [x] 3.1 Accept `PlaybackService` as a constructor parameter in `InterviewCubit`
  - Follow existing pattern: `RecordingService` and `AudioFocusService` are already injected
- [x] 3.2 In `onResponseReady()` method (line ~415): after transitioning to `InterviewSpeaking`, trigger playback:
  - If `ttsAudioUrl` is non-empty: call `_startPlayback(ttsAudioUrl)`
  - If `ttsAudioUrl` is empty: call `onSpeakingComplete()` immediately (existing behavior for pre-TTS fallback)
- [x] 3.3 Create private method `_startPlayback(String ttsAudioUrl)`:
  - Construct full URL from base URL + relative `ttsAudioUrl`
  - Call `_playbackService.playUrl(fullUrl, bearerToken: _sessionToken)`
  - Listen to `PlaybackEvent` stream:
    - On `completed`: call `onSpeakingComplete()`
    - On `error`: log the error with request_id, call `onSpeakingComplete()` (graceful degradation — text is already visible)
- [x] 3.4 In `cancel()` method: call `_playbackService.stop()` to clean up on session cancellation
- [x] 3.5 In `close()` method: call `_playbackService.dispose()` to release resources
- [x] 3.6 Handle audio interruptions during playback: in `_onAudioInterruption()`, stop playback if Speaking

### Task 4: Update `InterviewView` to remove placeholder auto-complete (AC: #1, #3)

- [x] 4.1 **Remove** the auto-complete placeholder in `interview_view.dart` lines 112–122:

  ```dart
  // REMOVE THIS BLOCK:
  if (state is InterviewSpeaking && state.ttsAudioUrl.isEmpty) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<InterviewCubit>().onSpeakingComplete();
      }
    });
  }
  ```

  - This logic now lives in `InterviewCubit.onResponseReady()` (Task 3.2)

- [x] 4.2 Optionally: add a "Stop speaking" button visible during `InterviewSpeaking` state to let user skip playback
  - This is a stretch goal for this story; Story 3.4 covers full playback controls

### Task 5: Provide `PlaybackService` in dependency injection (AC: #1)

- [x] 5.1 Update `apps/mobile/lib/features/interview/presentation/view/interview_page.dart` (or wherever `InterviewCubit` is created):
  - Create `PlaybackService` instance
  - Pass it to `InterviewCubit` constructor
- [x] 5.2 Ensure `PlaybackService` is disposed when the page/cubit is disposed

### Task 6: Write unit tests (AC: #1–#7)

- [x] 6.1 Create `apps/mobile/test/core/audio/playback_service_test.dart`:
  - Test: `playUrl()` starts playback
  - Test: `stop()` stops playback
  - Test: `playUrl()` while already playing stops previous playback first (no overlap)
  - Test: completion event is emitted when playback finishes
  - Test: error event is emitted on failure
  - Test: `dispose()` releases resources
- [x] 6.2 Update `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart`:
  - Add mock `PlaybackService` to test setup
  - Test: `onResponseReady()` with non-empty `ttsAudioUrl` triggers playback
  - Test: `onResponseReady()` with empty `ttsAudioUrl` calls `onSpeakingComplete()` immediately
  - Test: playback completion triggers `onSpeakingComplete()`
  - Test: playback error triggers `onSpeakingComplete()` (graceful degradation)
  - Test: `cancel()` stops playback
  - Test: audio interruption during Speaking stops playback
  - Test: `startRecording()` is rejected during Speaking state (existing test, verify still passes)
- [x] 6.3 Run full test suite: `cd apps/mobile && flutter test`

### Task 7: Verify integration (AC: #1, #2, #5)

- [x] 7.1 Build and run the app: `cd apps/mobile && flutter run`
- [x] 7.2 Verify the full interview loop with TTS playback: record → process → hear response → next question
- [x] 7.3 Verify no audio overlap when quickly progressing through turns
- [x] 7.4 Verify the Hold-to-Talk button is disabled during Speaking state
- [x] 7.5 Verify graceful degradation when TTS fetch fails (assistant text still visible)

## Dev Notes

### Existing Infrastructure (ALREADY BUILT — leverage, don't rebuild)

**`InterviewCubit`** (`apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart`):

- Already has `onResponseReady({required String responseText, required String ttsAudioUrl})` — transitions to `InterviewSpeaking` state (line ~415)
- Already has `onSpeakingComplete()` — transitions from Speaking → Ready with next question (line ~439)
- Already has `_onAudioInterruption()` — handles audio focus interruptions during Recording (line ~369); needs extension for Speaking
- Already guards `startRecording()` — rejects from non-Ready states (line ~80)
- Accepts `RecordingService` and `AudioFocusService` as constructor params — follow same DI pattern for `PlaybackService`

**`InterviewSpeaking` state** (`interview_state.dart`):

- Already defined with all needed fields: `questionNumber`, `totalQuestions`, `questionText`, `transcript`, `responseText`, `ttsAudioUrl`
- No changes needed to the state class

**`InterviewView`** (`interview_view.dart`):

- Line 112–122: **PLACEHOLDER TO REMOVE** — auto-completes Speaking when `ttsAudioUrl.isEmpty`. This was a stub awaiting real playback implementation.
- Hold-to-Talk button already disabled during Speaking (line 302: `isEnabled = state is InterviewReady || state is InterviewRecording`)
- Turn card already shows `responseText` during Speaking state (line 266–279)

**`AudioFocusService`** (`apps/mobile/lib/core/audio/audio_focus_service.dart`):

- Already wraps `audio_session`, exposes `Stream<AudioInterruptionEvent>`
- `InterviewCubit` already subscribes via `_onAudioInterruption()` — currently only handles Recording; needs extension for Speaking

**`ApiClient`** (`apps/mobile/lib/core/http/api_client.dart`):

- Currently has `post()` and `postMultipart()` for JSON-based requests
- `GET /tts/{request_id}` returns raw audio bytes (NOT JSON) — `just_audio` handles this directly by loading a URL, so **no changes to ApiClient are needed**
- `just_audio` supports setting HTTP headers on `AudioSource.uri()` — pass `Authorization: Bearer <token>` directly via the player's `headers` parameter

**`_handleTurnResponse`** (`interview_cubit.dart` line ~830):

- Already extracts `ttsAudioUrl` from `TurnResponseData` and passes it to `onResponseReady()`
- No changes needed here

**Backend `GET /tts/{request_id}`** (Story 3.2, already done):

- Endpoint at `/tts/{request_id}`, returns raw `audio/mpeg` bytes
- Requires `Authorization: Bearer <session_token>` header
- Returns 404 with envelope error for missing/expired audio
- TTL default: 300 seconds (5 min)
- `X-Request-ID` in response headers

### What Needs to Be Built

This story is about **playing TTS audio on Android with no overlap**:

1. **`PlaybackService`** — New service wrapping `just_audio.AudioPlayer` under `core/audio/`
2. **Cubit integration** — Wire `PlaybackService` into `InterviewCubit` to trigger playback on Speaking state
3. **Remove placeholder** — Delete the auto-complete stub in `interview_view.dart`
4. **Interruption handling** — Extend `_onAudioInterruption()` to stop playback during Speaking
5. **DI wiring** — Provide `PlaybackService` wherever `InterviewCubit` is created
6. **Tests** — Unit tests for `PlaybackService` and updated `InterviewCubit` tests

### Architecture-Mandated Patterns

From architecture.md:

- **Audio stack:** `just_audio 0.10.5` for playback — MUST use this library
- **Audio location:** `apps/mobile/lib/core/audio/` — `PlaybackService` MUST go here (alongside `recording_service.dart` and `audio_focus_service.dart`)
- **State management:** `InterviewCubit` owns the interview state machine; playback lifecycle is managed by the Cubit, NOT by the UI
- **No overlap:** "Never play TTS while recording; never overlap TTS; single playback queue with cancel/stop behavior" — this is a hard architectural constraint
- **Concurrency rules:** "Never record while speaking; never overlap TTS" — enforced by the Cubit state machine
- **Audio focus/interruptions:** Use `audio_session 0.2.2` — already initialized in `AudioFocusService`; extend interruption handling to playback
- **Feature structure:** Feature-first, `InterviewCubit` under `features/interview/presentation/cubit/`
- **No parallel local bool flags:** UI renders solely from Cubit state; no `isPlaying` booleans in the view

### UX Specifications (from ux-design-specification.md)

- **Speaking state:** "Subtle secondary accent to indicate 'AI turn'" — already defined in state styling
- **Voice Pipeline Stepper:** Speaking step highlighted during playback; all steps completed when done
- **No overlap (NFR7):** "Playback must never overlap (0ms overlap)" — `PlaybackService.playUrl()` must stop before play
- **Voice-first, not voice-only:** `assistant_text` always visible; audio is an enhancement — if playback fails, text is sufficient
- **Playback controls:** "Stop/Replay question" — Story 3.4 covers full controls; this story focuses on basic play + stop
- **Hold-to-Talk during Speaking:** disabled, label optionally changes to "Listening…" — already handled by existing UI code
- **Component Accessibility:** Semantic labels change by state (e.g., "Disabled while AI is speaking") — existing implementation

### Previous Story Learnings (from Stories 3.1 + 3.2)

- **TTS audio format is MP3** — `Content-Type: audio/mpeg` (Deepgram Aura returns MP3); `just_audio` handles MP3 natively
- **`tts_audio_url` is a relative path** like `/tts/{request_id}` — client must prepend base URL before passing to player
- **TTL is 5 minutes** — audio may expire if user takes too long; handle 404 gracefully
- **Auth required on TTS endpoint** — `Authorization: Bearer <session_token>` header needed; `just_audio` supports custom headers on `AudioSource.uri()`
- **Error hierarchy follows pattern:** `stage`, `code`, `retryable` fields on errors
- **80-char line length for Dart:** follow linting rules
- **Feature branches:** Use pattern `feature/story-3-3-short-description`
- **Conventional commits:** `feat:`, `fix:`, `test:` prefixes

### Git Intelligence (Recent Commits)

```
ba90a34 Merge pull request - Story 3.2 GET /tts endpoint
d1d33cb feat(interview): pass InterviewCubit to DiagnosticsPage during navigation
afe1c1c Merge pull request - Story 3.1 TTS generation
403addf docs: Add sprint status tracking and Epic 2 retrospective documents
3368853 Merge pull request #19 - Handle interruptions during recording
```

Key observations:

- Stories 3.1 (TTS generation) and 3.2 (TTS fetch endpoint) are DONE — this story completes the client-side playback
- Audio interruption handling pattern established in Story 2.8 — extend it for playback
- Feature branch naming: `feature/story-3-3-playback-queue`
- Commit convention: `feat:`, `fix:`, `test:` prefixes used consistently

### Critical `just_audio` Integration Notes

**`just_audio` URL playback with auth headers:**

```dart
// How to set up just_audio with auth headers:
final player = AudioPlayer();

await player.setAudioSource(
  AudioSource.uri(
    Uri.parse(fullTtsUrl),
    headers: {'Authorization': 'Bearer $sessionToken'},
  ),
);

await player.play();
```

**Listening for completion:**

```dart
player.playerStateStream.listen((state) {
  if (state.processingState == ProcessingState.completed) {
    // Playback finished
  }
});
```

**Error handling:**

```dart
player.playbackEventStream.listen(
  (event) {},
  onError: (Object e, StackTrace st) {
    // Handle playback error
  },
);
```

### Critical Naming Conventions

- **File names:** `snake_case` — `playback_service.dart`
- **Class names:** `PascalCase` — `PlaybackService`, `PlaybackEvent`
- **Method names:** `lowerCamelCase` — `playUrl()`, `stop()`, `dispose()`
- **Test file:** `playback_service_test.dart` in `apps/mobile/test/core/audio/`
- **Parameters:** `lowerCamelCase` — `bearerToken`, `ttsAudioUrl`

### Gotchas / Anti-Patterns to Avoid

1. **DO NOT put playback logic in the View** — The `InterviewCubit` owns the state machine. Playback must be triggered and managed by the Cubit, not by `BlocListener` in the view. The view's job is displaying state, not orchestrating audio.

2. **DO NOT skip `stop()` before `play()`** — Always call `stop()` before starting new playback in `playUrl()` to enforce the no-overlap constraint (NFR7).

3. **DO NOT create a new `AudioPlayer` instance per turn** — Reuse a single `AudioPlayer` instance within `PlaybackService`; call `stop()` and set new source. Creating and disposing players per turn wastes resources and risks leaks.

4. **DO NOT crash on playback failure** — If TTS fetch returns 404 (expired) or playback fails for any reason, **gracefully degrade**: log the error, transition to Ready state so the user can continue. The `assistant_text` is always visible as fallback.

5. **DO NOT add playback state to `InterviewSpeaking`** — The existing `InterviewSpeaking` class is sufficient. Do NOT add `isActuallyPlaying` or `playbackProgress` fields. The Cubit state represents the interview stage, not the audio player's internal state.

6. **DO NOT hold onto `StreamSubscription` without cancelling** — Cancel the playback event subscription in `stop()`, `dispose()`, and when starting a new playback. Otherwise, stale listeners may fire after the turn has ended.

7. **DO NOT modify `InterviewState` classes** — All state classes are already defined and sufficient for this story. Do NOT add new fields or create new states.

8. **DO NOT forget auth headers** — The `GET /tts/{request_id}` endpoint requires `Authorization: Bearer <session_token>`. `just_audio` supports custom headers via `AudioSource.uri(headers: {...})`.

9. **DO NOT use `just_audio_background`** — Not needed for MVP. The TTS playback is foreground-only and does not need background audio support.

10. **DO NOT forget to update the barrel file** — `apps/mobile/lib/core/audio/audio.dart` must export `playback_service.dart`.

### File Inventory

**Files to create:**

- `apps/mobile/lib/core/audio/playback_service.dart` — PlaybackService wrapping just_audio

**Files to create (tests):**

- `apps/mobile/test/core/audio/playback_service_test.dart` — PlaybackService unit tests

**Files to modify:**

- `apps/mobile/pubspec.yaml` — Add `just_audio: ^0.10.5` dependency
- `apps/mobile/lib/core/audio/audio.dart` — Export `playback_service.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart` — Accept `PlaybackService`, wire playback in `onResponseReady()`, extend `_onAudioInterruption()`, cleanup in `cancel()`/`close()`
- `apps/mobile/lib/features/interview/presentation/view/interview_view.dart` — Remove placeholder auto-complete block (lines 112–122)
- `apps/mobile/lib/features/interview/presentation/view/interview_page.dart` — Provide `PlaybackService` to `InterviewCubit`
- `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart` — Add mock `PlaybackService` to all test cases

**Files to validate (likely NO changes):**

- `apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart` — Already has `InterviewSpeaking` with all needed fields
- `apps/mobile/lib/core/audio/audio_focus_service.dart` — Already works, no changes needed
- `apps/mobile/lib/core/models/turn_models.dart` — Already has `ttsAudioUrl` field
- `apps/mobile/lib/core/http/api_client.dart` — No changes needed; `just_audio` loads URL directly

### Project Structure Notes

- `playback_service.dart` goes in `apps/mobile/lib/core/audio/` — consistent with `recording_service.dart` and `audio_focus_service.dart`
- Tests go in `apps/mobile/test/core/audio/playback_service_test.dart`
- No new directories needed — this adds a single service file to the existing audio module
- Alignment with architecture project structure: `apps/mobile/lib/core/audio/playback_service.dart` matches the architecture's planned structure exactly

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 3.3] — FR26, FR15, acceptance criteria
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] — `just_audio 0.10.5`, audio stack
- [Source: _bmad-output/planning-artifacts/architecture.md#State Management Patterns] — No overlap rules, InterviewCubit state machine
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries] — `core/audio/` location for playback
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice Pipeline Stepper] — Speaking state UX
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Component Strategy] — No-overlap audio rule
- [Source: _bmad-output/implementation-artifacts/3-2-implement-get-tts-request-id-short-lived-audio-fetch.md] — TTS endpoint details, auth pattern, MP3 format
- [Source: apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart] — onResponseReady(), onSpeakingComplete(), \_onAudioInterruption()
- [Source: apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart] — InterviewSpeaking state class
- [Source: apps/mobile/lib/features/interview/presentation/view/interview_view.dart#L112-122] — Placeholder to remove
- [Source: apps/mobile/lib/core/audio/audio_focus_service.dart] — AudioFocusService pattern

### Change Log

| Date       | Change                                                                                                    | Author                 |
| ---------- | --------------------------------------------------------------------------------------------------------- | ---------------------- |
| 2026-02-17 | Story 3.3 created — comprehensive context for Android playback queue with no-overlap audio enforcement    | Antigravity (SM Agent) |
| 2026-02-17 | Implemented playback service/cubit integration and tests; left manual integration checks pending (Task 7) | Amelia (Dev Agent)     |
| 2026-02-17 | Fixed silent playback regression by preserving `ttsAudioUrl` through transcript acceptance flow           | Amelia (Dev Agent)     |
| 2026-02-17 | Added Android debug cleartext config for localhost TTS and validated manual playback flow end-to-end      | Amelia (Dev Agent)     |

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

### Completion Notes List

- Implemented playback pipeline in `PlaybackService` with explicit no-overlap
  enforcement (`stop()` before new `playUrl()`), completion/error events, auth
  header support, and safe cleanup.
- Integrated playback lifecycle into `InterviewCubit` and moved speaking
  transition completion logic into cubit-managed playback handlers.
- Removed `InterviewView` speaking auto-complete placeholder block.
- Wired dependency injection in `InterviewPage` and added `ApiClient.baseUrl`
  accessor for relative TTS URL resolution.
- Added/updated tests for playback, cubit behavior dependencies, and related
  affected tests; full suite and analyzer pass.
- Fixed a regression where `acceptTranscript()` forced an empty `ttsAudioUrl`,
  causing immediate Speaking → Ready transitions with no audible playback.
- Completed manual integration checks for Task 7 after Android debug network
  policy fix; verified audible playback and normal progression behavior.

### File List

- apps/mobile/lib/core/audio/audio.dart
- apps/mobile/lib/core/audio/playback_service.dart
- apps/mobile/lib/core/http/api_client.dart
- apps/mobile/lib/features/interview/presentation/cubit/interview_state.dart
- apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart
- apps/mobile/lib/features/interview/presentation/view/interview_page.dart
- apps/mobile/lib/features/interview/presentation/view/interview_view.dart
- apps/mobile/android/app/src/debug/AndroidManifest.xml
- apps/mobile/android/app/src/debug/res/xml/network_security_config.xml
- apps/mobile/test/core/audio/playback_service_test.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_diagnostics_test.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_interruption_test.dart
- apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart
- apps/mobile/test/features/interview/presentation/view/interview_page_test.dart
- apps/mobile/test/fix_diagnostics_provider_nav_test.dart
- \_bmad-output/implementation-artifacts/sprint-status.yaml
