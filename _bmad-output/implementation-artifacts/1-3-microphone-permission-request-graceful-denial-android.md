# Story 1.3: Microphone Permission Request + Graceful Denial (Android)

Status: done

## Story

As a user,
I want a clear microphone permission request with a rationale,
So that I understand why access is required and can decide confidently.

## Acceptance Criteria

1. **Given** I have not granted microphone permission
   **When** the app requests microphone access
   **Then** I see a user-friendly explanation of why the mic is needed
   **And** I can choose Allow or Deny

2. **Given** I deny microphone permission
   **When** I return to the setup screen
   **Then** the app clearly indicates recording won't work without permission
   **And** I can retry the permission request from a visible action

## Tasks / Subtasks

- [x] **Task 1: Create permission service abstraction** (AC: #1)
  - [x] Create `lib/core/permissions/permission_service.dart` interface
  - [x] Create `lib/core/permissions/microphone_permission_service.dart` implementation using `permission_handler` package
  - [x] Define `MicrophonePermissionStatus` enum (granted, denied, permanentlyDenied, restricted, limited)
  - [x] Implement `checkMicrophonePermission()` method
  - [x] Implement `requestMicrophonePermission()` method
  - [x] Implement `openAppSettings()` method for permanently denied cases

- [x] **Task 2: Create permission Cubit for state management** (AC: #1, #2)
  - [x] Create `lib/features/interview/presentation/cubit/permission_cubit.dart`
  - [x] Create `lib/features/interview/presentation/cubit/permission_state.dart`
  - [x] Implement `checkPermission()` method
  - [x] Implement `requestPermission()` method
  - [x] Handle state transitions: unknown → checking → granted/denied/permanentlyDenied
  - [x] Inject `MicrophonePermissionService` via constructor

- [x] **Task 3: Design permission rationale screen** (AC: #1)
  - [x] Create `lib/features/interview/presentation/view/permission_rationale_page.dart`
  - [x] Create `lib/features/interview/presentation/view/permission_rationale_view.dart`
  - [x] Add calm, reassuring header illustration or icon (mic icon with friendly visual)
  - [x] Add clear headline: "VoiceMock needs microphone access"
  - [x] Add rationale body text explaining why (interview practice requires voice input)
  - [x] Add primary CTA: "Allow Microphone Access"
  - [x] Apply Calm Ocean design tokens (colors, typography, spacing)
  - [x] Center the content with appropriate breathing room (anxiety-aware design)

- [x] **Task 4: Create permission denied state component** (AC: #2)
  - [x] Create `lib/features/interview/presentation/widgets/permission_denied_banner.dart`
  - [x] Show non-alarming warning message ("Microphone access is required for voice practice")
  - [x] Include primary action: "Enable Microphone" (triggers re-request or opens settings)
  - [x] Include secondary action: "Not now" to dismiss temporarily
  - [x] Use neutral/warning styling (avoid red/error colors per UX guidelines)
  - [x] Handle `permanentlyDenied` state with "Open Settings" action

- [x] **Task 5: Integrate permission flow with setup screen** (AC: #1, #2)
  - [x] Modify `SetupPage` to check permission status on mount
  - [x] Add `PermissionCubit` provider to `SetupPage`
  - [x] Show `PermissionDeniedBanner` when permission is denied
  - [x] Intercept "Start Interview" tap to check permission first
  - [x] Navigate to `PermissionRationalePage` if permission not granted
  - [x] After permission granted, proceed to interview or return to setup ready state
  - [x] Ensure navigation uses `go_router` patterns

- [x] **Task 6: Add permission_handler dependency** (AC: #1)
  - [x] Add `permission_handler: ^11.3.1` to `pubspec.yaml`
  - [x] Update Android `AndroidManifest.xml` with `RECORD_AUDIO` permission
  - [x] Add POST_NOTIFICATIONS permission for Android 13+ if needed (not required for MVP)
  - [x] Run `flutter pub get` to resolve dependencies

- [x] **Task 7: Add go_router routes for permission flow** (AC: #1)
  - [x] Add `/permission` route to `lib/app/router.dart`
  - [x] Configure route to navigate back to `/setup` after permission handling
  - [x] Ensure back navigation from permission screen is intuitive

- [x] **Task 8: Write unit tests for PermissionCubit** (AC: #1, #2)
  - [x] Mock `MicrophonePermissionService`
  - [x] Test initial state is `unknown`
  - [x] Test `checkPermission()` transitions to correct status
  - [x] Test `requestPermission()` handles granted flow
  - [x] Test `requestPermission()` handles denied flow
  - [x] Test `requestPermission()` handles permanentlyDenied flow

- [x] **Task 9: Write widget tests for permission UI** (AC: #1, #2)
  - [x] Test `PermissionRationalePage` renders rationale text
  - [x] Test "Allow Microphone Access" button triggers permission request
  - [x] Test `PermissionDeniedBanner` displays when permission denied
  - [x] Test "Enable Microphone" action works correctly
  - [x] Test "Open Settings" appears for permanently denied state
  - [x] Test `SetupView` shows banner when permission is not granted

## Dev Notes

### Implements FRs
- **FR11:** User can grant or deny microphone access
- **FR12:** System can explain why microphone access is needed when requesting permission

### Architecture Compliance (MUST FOLLOW)

#### State Management Pattern
- Use `flutter_bloc 9.1.1` (already installed)
- Create a dedicated `PermissionCubit` for permission state
- Separate from `ConfigurationCubit` (configuration) and future `InterviewCubit` (interview flow)
- Single responsibility: only handle microphone permission state

#### File Locations (Architecture-Mandated)
```
apps/mobile/lib/
├── core/
│   └── permissions/
│       ├── permissions.dart                    # NEW - barrel export
│       ├── permission_service.dart             # NEW - abstract interface
│       └── microphone_permission_service.dart  # NEW - implementation
├── features/
│   └── interview/
│       ├── presentation/
│       │   ├── cubit/
│       │   │   ├── permission_cubit.dart       # NEW
│       │   │   └── permission_state.dart       # NEW
│       │   ├── view/
│       │   │   ├── permission_rationale_page.dart  # NEW
│       │   │   └── permission_rationale_view.dart  # NEW
│       │   └── widgets/
│       │       └── permission_denied_banner.dart   # NEW
└── app/
    └── router.dart                             # MODIFY - add /permission route
```

#### Routing Pattern
- Use `go_router 17.0.1` (already configured)
- Add `/permission` route for the permission rationale screen
- Navigation flow: `/setup` → `/permission` → (grant) → `/setup` or `/interview`

### UX Requirements (MUST FOLLOW)

#### Permission Rationale Screen Design
From UX Design Specification (Journey 3 - Permissions & First-Time Trust):

1. **Before OS prompt:** Show a short rationale screen explaining why mic is needed
2. **Calm, non-alarming tone:** Use encouraging language, avoid technical jargon
3. **Single primary CTA:** "Allow Microphone Access" - triggers OS permission dialog
4. **Clean layout:** Centered content, generous spacing, friendly illustration/icon

#### Permission Denied State Design
From UX Design Specification:

1. **Neutral styling:** Do NOT use red/error colors - use warning orange or calm neutral
2. **Non-judgmental copy:** "Recording requires microphone access" not "Permission denied!"
3. **Clear actions:**
   - Primary: "Enable Microphone" (opens settings or retries request)
   - Secondary: "Not now" (dismisses banner but maintains warning state)
4. **Permanently denied case:** Detect and show "Open Settings" as the only viable path

#### Visual Design - Calm Ocean Theme
```dart
// From previous story (1.2), reuse existing theme tokens
const kPrimary = Color(0xFF2F6FED);
const kSecondary = Color(0xFF27B39B);
const kBackground = Color(0xFFF7F9FC);
const kSurface = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF0F172A);
const kTextMuted = Color(0xFF5B6475);
const kWarning = Color(0xFFD99A00);  // Use for permission warnings

// Typography (already defined in lib/core/theme/voicemock_theme.dart)
// H1: 28/34 semibold - Screen titles
// Body: 16/24 regular - Primary text
// Small: 14/20 regular - Helper text
```

#### Microcopy Guidelines
- **Rationale headline:** "VoiceMock needs microphone access"
- **Rationale body:** "To practice interview answers with your voice, we need access to your microphone. Your audio is processed to create your personal interview experience."
- **CTA text:** "Allow Microphone Access"
- **Denied banner:** "Microphone access is required for voice practice"
- **Open Settings text:** "Open Settings" (for permanently denied)
- **Dismiss text:** "Not now"

### Android-Specific Requirements

#### AndroidManifest.xml Permissions
```xml
<!-- Required for recording -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Optional but may help with audio focus -->
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

#### Permission Handler Package
```yaml
# pubspec.yaml
dependencies:
  permission_handler: ^11.3.1
```

Note: `permission_handler` handles the complexity of:
- Checking current permission status
- Requesting permission with proper callbacks
- Detecting "permanently denied" state (user selected "Don't ask again")
- Opening app settings for permanently denied cases

### Previous Story Intelligence (Story 1.2)

#### Key Learnings
- VGV template structure preserved - continue using it
- `context.watch<Cubit>()` pattern used instead of `context.select`
- Theme tokens defined in `lib/core/theme/voicemock_theme.dart` - reuse them
- All 50 tests pass - maintain test coverage
- SharedPreferences initialized at App level - similar pattern for services

#### Dependencies Already Installed
- `flutter_bloc 9.1.1` ✓
- `bloc_test` ✓
- `mocktail` ✓
- `go_router ^17.0.1` ✓
- `shared_preferences ^2.5.3` ✓
- `equatable ^2.0.7` ✓

#### Files Modified/Created (from 1.2)
- Go router configured in `lib/app/router.dart`
- Theme tokens in `lib/core/theme/voicemock_theme.dart`
- Cubit pattern established in `lib/features/interview/presentation/cubit/`

### Anti-Patterns to AVOID

- ❌ Do NOT show permission request without rationale first on first app launch
- ❌ Do NOT use red/error styling for permission denied state - use neutral/warning
- ❌ Do NOT block the entire app when permission is denied - let user continue browsing
- ❌ Do NOT auto-retry permission request infinitely
- ❌ Do NOT put permission logic in widgets - encapsulate in a service + Cubit
- ❌ Do NOT hardcode permission messages - use localization-ready strings
- ❌ Do NOT forget to handle "permanently denied" (Don't ask again) case
- ❌ Do NOT skip tests - maintain VGV test coverage standards

### Testing Standards

- **Unit tests:** Test `PermissionCubit` state transitions with mocked service
- **Widget tests:** Test UI renders correctly for each permission state
- **Integration consideration:** Actual permission requests require real device testing
- **Coverage:** Maintain existing coverage percentage
- **Mocking:** Use `mocktail` to mock `MicrophonePermissionService`

### Project Structure Notes

- New `lib/core/permissions/` directory follows architecture pattern of separating core services
- Permission service is a core concern, not interview-feature-specific
- `PermissionCubit` is placed under interview feature since it's the primary consumer for MVP
- Future: could move to core if other features need permission management

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3] - acceptance criteria
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] - flutter_bloc, go_router patterns
- [Source: _bmad-output/planning-artifacts/architecture.md#Mobile permission and interruption handling] - mic permission requirements
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Journey 3 — Permissions & First-Time Trust] - permission flow UX
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Permission pattern] - rationale screen + denied state design
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Visual Design Foundation] - Calm Ocean colors, typography
- [Source: _bmad-output/planning-artifacts/prd.md#FR11-FR12] - functional requirements

## Dev Agent Record

### Agent Model Used

Claude (Anthropic) - Antigravity Agentic Coding Assistant

### Debug Log References

- All 81 tests pass after implementation

### Completion Notes List

- ✅ Created permission service abstraction with `PermissionService` interface and `MicrophonePermissionService` implementation
- ✅ Implemented `PermissionCubit` for state management with check/request/openSettings functionality
- ✅ Designed permission rationale screen with Calm Ocean theme, centered layout, and mic icon
- ✅ Created `PermissionDeniedBanner` with warning styling (orange, not red) and proper action buttons
- ✅ Integrated permission flow into `SetupPage` and `SetupView` with permission check on Start Interview
- ✅ Added `permission_handler ^11.3.1` dependency and `RECORD_AUDIO` permission to AndroidManifest.xml
- ✅ Added `/permission` route to go_router configuration
- ✅ Wrote comprehensive unit tests for `PermissionCubit` (15 tests)
- ✅ Wrote widget tests for `PermissionRationaleView` (10 tests) and `PermissionDeniedBanner` (8 tests)
- ✅ Updated existing `SetupView` tests to include `PermissionCubit` provider (12 tests)

### Change Log

- 2026-02-03: Implemented all 9 tasks for microphone permission request feature
- 2026-02-03: Added 31 new tests (81 total tests pass)
- 2026-02-03: Story moved to review status

### File List

**New Files:**
- `apps/mobile/lib/core/permissions/permission_service.dart`
- `apps/mobile/lib/core/permissions/microphone_permission_service.dart`
- `apps/mobile/lib/core/permissions/permissions.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/permission_cubit.dart`
- `apps/mobile/lib/features/interview/presentation/cubit/permission_state.dart`
- `apps/mobile/lib/features/interview/presentation/view/permission_rationale_page.dart`
- `apps/mobile/lib/features/interview/presentation/view/permission_rationale_view.dart`
- `apps/mobile/lib/features/interview/presentation/widgets/permission_denied_banner.dart`
- `apps/mobile/test/features/interview/presentation/cubit/permission_cubit_test.dart`
- `apps/mobile/test/features/interview/presentation/view/permission_rationale_view_test.dart`
- `apps/mobile/test/features/interview/presentation/widgets/permission_denied_banner_test.dart`

**Modified Files:**
- `apps/mobile/pubspec.yaml` - added permission_handler dependency
- `apps/mobile/android/app/src/main/AndroidManifest.xml` - added RECORD_AUDIO permission
- `apps/mobile/lib/app/router.dart` - added /permission route
- `apps/mobile/lib/features/interview/presentation/view/setup_page.dart` - added PermissionCubit provider
- `apps/mobile/lib/features/interview/presentation/view/setup_view.dart` - integrated permission banner and Start Interview check
- `apps/mobile/lib/features/interview/presentation/presentation.dart` - added new exports
- `apps/mobile/test/features/interview/presentation/view/setup_view_test.dart` - updated to include PermissionCubit mock

### Code Review Fixes (2026-02-03)
- **Fixed High Issue:** Added `WidgetsBindingObserver` to `SetupView` to re-check permissions when app resumes (e.g. returning from Settings).
- **Fixed High Issue:** Updated `PermissionRationaleView` to handle `permanentlyDenied` state by navigating back to the setup screen where the proper banner is shown, eliminating a dead-end UI.
- **Fixed Medium Issue:** Switched navigation from `go` to `pushNamed`/`pop` to preserve `SetupPage` state (including Cubits) when navigating to and from the permission rationale screen.
- **Fixed Low Issue:** Refactored `router.dart` and `setup_view.dart` to use `PermissionRationalePage.routeName` constant instead of magic strings.
- **Verification:** All tests passed after refactoring.

