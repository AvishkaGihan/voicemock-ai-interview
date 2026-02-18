# Story 5.1: Third-Party Processing Disclosure

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to understand that my audio and transcript are processed by third-party services,
So that I can make an informed decision.

## Implements

FR33 (System can disclose that audio/transcripts are processed by third-party AI services)

## Acceptance Criteria (ACs)

### AC 1: Disclosure banner shown before the first session start

**Given** I am on the interview setup screen and have never acknowledged the disclosure
**When** I view the setup screen
**Then** a clearly visible disclosure banner or card is displayed near the "Start Interview" button
**And** it states that audio and transcripts are processed by third-party AI services
**And** it provides a brief, non-legalistic summary of retention/deletion behavior (e.g., "Audio is not stored. Transcripts are kept for this session only.")

### AC 2: Disclosure links to a detail view or expanded content

**Given** the disclosure banner is visible
**When** I tap "Learn more" or an equivalent action
**Then** I see expanded disclosure content (bottom sheet or detail screen) explaining:

- Which types of data are sent (audio, text transcripts)
- That third-party AI services process the data (STT, LLM, TTS)
- That audio is not persisted by default
- That session data (transcripts, summaries) can be deleted
  **And** the content uses calm, non-legalistic language consistent with the UX tone

### AC 3: Disclosure acknowledgment is persisted locally

**Given** I have read the disclosure
**When** I tap "Got it" or dismiss the banner
**Then** the acknowledgment is stored locally (SharedPreferences or equivalent)
**And** the banner does not reappear on subsequent app launches
**And** the full disclosure remains accessible from app Settings

### AC 4: Disclosure is accessible from Settings

**Given** I have previously acknowledged the disclosure
**When** I navigate to app Settings
**Then** I can find a "Data & Privacy" or "Processing Disclosure" section
**And** tapping it shows the same detailed disclosure content from AC 2

### AC 5: Disclosure does not block the interview start

**Given** the disclosure banner is visible but unacknowledged
**When** I tap "Start Interview"
**Then** the interview starts normally (the disclosure is informational, not a consent gate)
**And** the banner is automatically marked as acknowledged

## Tasks

- [x] Task 1: Create disclosure content constants (AC: 1, 2)
  - [x] 1.1: Create `apps/mobile/lib/core/constants/disclosure_strings.dart` with all disclosure copy (banner text, detail text, section headers)
  - [x] 1.2: Define short banner text (~2 sentences): "Your audio and responses are processed by third-party AI services to generate transcripts, questions, and feedback. Audio is not stored after processing."
  - [x] 1.3: Define detailed disclosure text covering: data types sent, third-party processing, retention policy, deletion controls

- [x] Task 2: Create disclosure persistence service (AC: 3)
  - [x] 2.1: Create `apps/mobile/lib/core/storage/disclosure_prefs.dart` with `DisclosurePrefs` class
  - [x] 2.2: Implement `hasAcknowledgedDisclosure()` → `Future<bool>` using `SharedPreferences`
  - [x] 2.3: Implement `acknowledgeDisclosure()` → `Future<void>` to persist acknowledgment
  - [x] 2.4: Use key `'disclosure_acknowledged_v1'` (versioned for future disclosure updates)

- [x] Task 3: Create disclosure banner widget (AC: 1, 5)
  - [x] 3.1: Create `apps/mobile/lib/features/interview/presentation/widgets/disclosure_banner.dart`
  - [x] 3.2: Design as a Card with InfoOutlined icon, short disclosure text, and "Learn more" text button
  - [x] 3.3: Use `VoiceMockColors.secondary` (#27B39B) accent or neutral info styling (not warning/error)
  - [x] 3.4: Include "Got it" dismiss action that calls `DisclosurePrefs.acknowledgeDisclosure()`
  - [x] 3.5: Conditionally render: only show when `hasAcknowledgedDisclosure() == false`

- [x] Task 4: Create disclosure detail bottom sheet (AC: 2, 4)
  - [x] 4.1: Create `apps/mobile/lib/features/interview/presentation/widgets/disclosure_detail_sheet.dart`
  - [x] 4.2: Render the full disclosure content in a scrollable bottom sheet
  - [x] 4.3: Include sections: "What data is processed", "How it's processed", "Data retention", "Your controls"
  - [x] 4.4: Use calm typography (Body + Small text styles) consistent with UX spec
  - [x] 4.5: Include a "Close" or "Got it" button at the bottom

- [x] Task 5: Integrate disclosure banner into SetupView (AC: 1, 5)
  - [x] 5.1: Add `DisclosurePrefs` dependency to `SetupView` (inject or create in `initState`)
  - [x] 5.2: Load `hasAcknowledgedDisclosure()` state on init
  - [x] 5.3: Show `DisclosureBanner` above the "Start Interview" button area when not yet acknowledged
  - [x] 5.4: Auto-acknowledge on "Start Interview" tap if banner is still visible (AC 5)
  - [x] 5.5: Wire "Learn more" tap to open `DisclosureDetailSheet`

- [x] Task 6: Add disclosure to Settings screen (AC: 4)
  - [x] 6.1: Identify or create the Settings/preferences screen (if not existing yet, create a minimal `SettingsPage`)
  - [x] 6.2: Add a "Data & Privacy" section with a "Processing Disclosure" list tile
  - [x] 6.3: Tapping the tile opens `DisclosureDetailSheet` from Task 4
  - [x] 6.4: Ensure navigation to Settings is accessible from the app (e.g., gear icon on setup screen)

- [x] Task 7: Add unit tests for DisclosurePrefs (AC: 3)
  - [x] 7.1: Test `hasAcknowledgedDisclosure()` returns `false` by default
  - [x] 7.2: Test `acknowledgeDisclosure()` persists the value
  - [x] 7.3: Test `hasAcknowledgedDisclosure()` returns `true` after acknowledgment

- [x] Task 8: Add widget tests for disclosure components (AC: 1, 2, 4, 5)
  - [x] 8.1: Test `DisclosureBanner` renders when not acknowledged
  - [x] 8.2: Test `DisclosureBanner` is hidden when already acknowledged
  - [x] 8.3: Test "Learn more" tap opens the detail sheet
  - [x] 8.4: Test "Got it" tap calls acknowledge and hides the banner
  - [x] 8.5: Test `DisclosureDetailSheet` renders all required sections
  - [x] 8.6: Test `SetupView` shows disclosure banner on first launch
  - [x] 8.7: Test `SetupView` auto-acknowledges disclosure on "Start Interview" tap

## Dev Notes

### Architecture Alignment

- **No backend changes.** This story is entirely mobile-side. The disclosure is informational UI — no new API endpoints, no new server logic.
- **No state machine changes.** The `InterviewCubit` and its states are unaffected. The disclosure banner is managed by local widget state + `SharedPreferences`, completely decoupled from the interview flow.
- **Feature-first structure:** New widgets go under `features/interview/presentation/widgets/`. Shared services (disclosure prefs) go under `core/storage/`.

### UX Alignment

- **UX Spec §Privacy & Data Defaults → Processing Disclosure:** "Show a short disclosure during first-time onboarding and/or first session start: audio is processed to generate transcripts and responses; third-party services may be involved. Keep the message calm and non-legalistic; link to details in Settings."
- **UX Spec §Experience Principles #4:** "Trust by design — transparency about processing, deletion controls, clear errors."
- **UX Spec §Micro-Emotions:** "Trust over skepticism: transparency."
- **Tone:** Calm, non-legalistic, informational. NOT a consent gate — the user is informed, not blocked. Use language like "Your audio is processed by AI services to generate responses" rather than "By continuing, you agree..."
- **Visual weight:** The banner should be noticeable but not alarming. Use neutral-to-accent styling (info icon + secondary accent color), not warning/error styling.

### Disclosure Copy Guidance

**Banner (short):**

> "Your audio and responses are processed by third-party AI services to generate transcripts, questions, and feedback. Audio is not stored after processing."

**Detail sections:**

1. **What data is processed:** Audio recordings (sent for speech-to-text), text transcripts (sent for question generation and coaching feedback).
2. **How it's processed:** Third-party AI services (speech recognition, language model, text-to-speech) process your data to provide the interview experience.
3. **Data retention:** Audio is not persisted after processing. Transcripts and summaries are kept only for the current session and can be deleted.
4. **Your controls:** You can delete session data at any time. Diagnostics data (request IDs, timings) does not include audio or full transcripts.

### Settings Screen Strategy

- If a Settings screen doesn't exist yet, create a minimal one:
  - `apps/mobile/lib/features/settings/presentation/view/settings_page.dart`
  - Simple `Scaffold` with `ListView` containing a "Data & Privacy" section
  - Add a gear icon button on the setup screen app bar to navigate to it
- If a Settings screen already exists, add the "Data & Privacy" section to it.

### SharedPreferences Dependency

- The project likely already has `shared_preferences` as a dependency (check `pubspec.yaml`).
- If not, add `shared_preferences: ^2.3.0` to `pubspec.yaml`.
- Use a versioned key (`disclosure_acknowledged_v1`) so future disclosure updates can re-trigger the banner.

### Key Risks

1. **SharedPreferences availability on first run:** `SharedPreferences.getInstance()` is async. Handle the loading state gracefully — show the banner by default until prefs load, or wrap in a `FutureBuilder`.
2. **Settings screen may not exist:** If no Settings screen exists, creating a minimal one adds scope. Keep it simple for MVP — a basic list with one section.
3. **Copy length:** Keep the banner text very short (2 sentences). Detail sheet can be longer but should still be non-overwhelming.

### Dependencies

- **Upstream:** No story dependencies (this is the first story in Epic 5).
- **Downstream:** Story 5.2 (Delete session artifacts) will add deletion controls from Settings, so a minimal Settings screen created here will be reused.
- **Packages:** `shared_preferences` (likely already in pubspec).

### Previous Story Intelligence (4-3)

- The `SetupView` is at `apps/mobile/lib/features/interview/presentation/view/setup_view.dart` (332 lines). It manages interview configuration (role/type/difficulty/question count) and permission handling.
- The `_StartInterviewButton` widget handles the "Start Interview" tap with connectivity and permission checks before navigating to the interview screen.
- `VoiceMockColors.secondary` (#27B39B) is used for coaching/accent styling — consistent with the banner's informational but non-alarming tone.
- Widget structure follows VGV Flutter conventions: widgets in `presentation/widgets/`, views in `presentation/view/`.
- `features/diagnostics/` already exists with a `presentation/` directory — confirms the mobile project supports multiple feature directories.

### Git Intelligence

- Recent commits are on Epic 4 completion (stories 4.1–4.3) plus the Epic 4 retrospective:
- `f98530f` feat: Add Epic 4 retrospective document and update sprint status
- `99549c3` Merge PR #28 from story-4-3
- All backend (146) and mobile (413) tests passing

### Epic 4 Retrospective Action Items Relevant to This Story

- **Review Secure Storage Policies** — This story starts the privacy surface by adding disclosure; future stories (5.2) will add deletion controls.
- **Implement PII Redaction** — Not directly in scope for 5.1, but the disclosure content should accurately reflect what data handling exists.

### Project Structure Notes

- New files align with established patterns: widgets in `features/interview/presentation/widgets/`, core services in `core/storage/`, constants in `core/constants/`
- No new backend files
- Settings screen (if created) follows feature-first pattern: `features/settings/presentation/view/`

### References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 5, Story 5.1 (FR33)
- [architecture.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — Privacy-by-default, data retention, no audio persistence
- [ux-design-specification.md §Privacy & Data Defaults](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — Processing Disclosure UX, Default Retention, User Controls
- [setup_view.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/interview/presentation/view/setup_view.dart) — Setup screen where disclosure banner will be integrated
- [epic-4-retrospective.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/epic-4-retrospective.md) — Action items for Epic 5
- [sprint-status.yaml](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/sprint-status.yaml) — Sprint tracking

## Dev Agent Record

### Agent Model Used

Google Deepmind Antigravity

### Debug Log References

- Fix: `DisclosureDetailSheet` test used modal bottom sheet — lazy `ListView` items in `DraggableScrollableSheet` were not built in test viewport. Resolution: pump widget directly in `Scaffold` body for 8.5 content render tests.
- Fix: `any()` matcher on `InterviewConfig` parameter in `MockSessionCubit.startSession` required `registerFallbackValue(InterviewConfig.defaults())` in `setUpAll`.

### Completion Notes List

- **Task 1** — `DisclosureStrings` abstract class created with banner copy, 4 detail sections (header + body), settings tile copy. All copy is calm and non-legalistic per UX spec.
- **Task 2** — `DisclosurePrefs` class wraps `SharedPreferences` with versioned key `disclosure_acknowledged_v1`. Both async methods implemented.
- **Task 3** — `DisclosureBanner` is a pure `StatelessWidget` Card using `VoiceMockColors.secondary` with `Icons.info_outline_rounded`, "Learn more" + "Got it" callbacks. Parent (SetupView) controls visibility.
- **Task 4** — `DisclosureDetailSheet` uses `DraggableScrollableSheet` (0.4–0.95 range, initial 0.7). `show()` static helper. All 4 sections rendered as `_DisclosureSection` widgets. "Got it" closes the sheet.
- **Task 5** — `SetupView` gains `_disclosurePrefs` + `_disclosureAcknowledged` state, loaded async in `initState`. Banner placed between scrollable content and Start Interview button. `_StartInterviewButton` accepts `onBeforeStart` callback for auto-acknowledge on Start. Gear icon added to `AppBar` actions → `/settings`.
- **Task 6** — `SettingsPage` created at `features/settings/presentation/view/`. "Data & Privacy" section with "Processing Disclosure" tile. Route `/settings` registered in `app/router.dart`.
- **Task 7** — 4 unit tests for `DisclosurePrefs` using `SharedPreferences.setMockInitialValues`. All pass.
- **Task 8** — 9 widget tests covering banner rendering, callbacks, detail sheet sections, SetupView first-launch, hidden-when-acknowledged, and auto-acknowledge-on-start. All pass.
- **Full regression suite:** 426 tests passed, 0 failures, 1 skipped (pre-existing). No regressions.

### File List

**New files:**

- `apps/mobile/lib/core/constants/disclosure_strings.dart`
- `apps/mobile/lib/core/storage/disclosure_prefs.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/disclosure_banner.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/disclosure_detail_sheet.dart`
- `apps/mobile/lib/features/settings/presentation/view/settings_page.dart`
- `apps/mobile/test/core/disclosure_prefs_test.dart`
- `apps/mobile/test/features/interview/presentation/widgets/disclosure_widgets_test.dart`

**Modified files:**

- `apps/mobile/lib/features/interview/presentation/view/setup_view.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/widgets.dart`
- `apps/mobile/lib/app/router.dart`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/5-1-third-party-processing-disclosure.md`

## Change Log

- 2026-02-18: Story 5.1 implementation complete. Added third-party processing disclosure banner to SetupView (shown on first launch, auto-dismissed on Start Interview). Created disclosure detail bottom sheet (4 sections: What/How/Retention/Controls). Disclosure acknowledgment persisted via SharedPreferences versioned key. Created minimal SettingsPage with Data & Privacy section accessible via gear icon on setup screen. All ACs satisfied. 13 new tests added (4 unit + 9 widget). Zero regressions.
