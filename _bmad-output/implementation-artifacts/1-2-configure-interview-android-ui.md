# Story 1.2: Configure Interview (Android UI)

Status: done

## Story

As a job seeker,
I want to configure role, interview type, and difficulty,
So that the interview matches what I'm practicing.

## Acceptance Criteria

1. **Given** I am on Android and I have opened the app
   **When** I navigate to the interview setup screen
   **Then** I can select a target role, interview type, and difficulty
   **And** the screen clearly shows my current selections before starting

2. **Given** I have not started a session yet
   **When** I change any selection
   **Then** the updated selection is reflected immediately in the UI
   **And** the "Start Interview" action remains available

## Tasks / Subtasks

- [x] **Task 1: Create interview configuration data models** (AC: #1, #2)
  - [x] Create `InterviewRole` enum in `lib/features/interview/domain/`
  - [x] Create `InterviewType` enum in `lib/features/interview/domain/`
  - [x] Create `DifficultyLevel` enum in `lib/features/interview/domain/`
  - [x] Create `InterviewConfig` model class holding all selections
  - [x] Add validation to allow 5-10 question selection (default: 5)

- [x] **Task 2: Create ConfigurationCubit for state management** (AC: #2)
  - [x] Create `ConfigurationCubit` in `lib/features/interview/presentation/cubit/`
  - [x] Create `ConfigurationState` with current selections
  - [x] Implement `updateRole`, `updateType`, `updateDifficulty`, `updateQuestionCount` methods
  - [x] Implement `resetToDefaults` method
  - [x] Add persistence of "last used" configuration via shared preferences

- [x] **Task 3: Build interview setup screen UI** (AC: #1)
  - [x] Create `SetupPage` in `lib/features/interview/presentation/view/`
  - [x] Create `SetupView` widget with responsive layout
  - [x] Implement role selector (bottom sheet picker for role list)
  - [x] Implement interview type selector (segmented control or chips)
  - [x] Implement difficulty selector (segmented control: Easy/Medium/Hard)
  - [x] Implement question count selector (slider or number picker, 5-10)
  - [x] Apply Calm Ocean design tokens (colors, typography, spacing)

- [x] **Task 4: Create selection summary component** (AC: #1)
  - [x] Create `ConfigurationSummaryCard` widget showing all current selections
  - [x] Ensure selections are clearly visible before starting
  - [x] Use appropriate typography hierarchy (H3 for titles, Body for values)

- [x] **Task 5: Implement "Start Interview" button** (AC: #1, #2)
  - [x] Create primary CTA button following Material 3 Filled button style
  - [x] Button remains enabled when all required selections are made
  - [x] Add loading state for future session start integration
  - [x] Position button at bottom of screen (stable anchor position)

- [x] **Task 6: Wire navigation with go_router** (AC: #1)
  - [x] Add `/setup` route to app router
  - [x] Navigate from Home to Setup screen
  - [x] Prepare route for future `/interview` screen (placeholder for now)

- [x] **Task 7: Write unit tests for ConfigurationCubit** (AC: #2)
  - [x] Test initial state with default values
  - [x] Test state updates for each selection method
  - [x] Test persistence and restoration of last used config

- [x] **Task 8: Write widget tests for SetupView** (AC: #1, #2)
  - [x] Test all selectors are rendered
  - [x] Test selection changes update the UI immediately
  - [x] Test configuration summary reflects current selections
  - [x] Test Start Interview button is visible and enabled

## Dev Notes

### Implements FRs
- **FR2:** User can select a target job role for the interview
- **FR3:** User can select an interview type (Behavioral or Technical)
- **FR4:** User can select an interview difficulty level
- **FR5:** User can view and change selections before starting the session

### Architecture Compliance (MUST FOLLOW)

#### State Management Pattern
- Use `flutter_bloc 9.1.1` (already installed via VGV template)
- Create a dedicated `ConfigurationCubit` (NOT part of `InterviewCubit`)
- `InterviewCubit` is reserved for the interview state machine (Ready → Recording → etc.)
- Configuration state is pre-interview; interview state is during-interview

#### File Locations (Architecture-Mandated)
```
apps/mobile/lib/features/interview/
├── domain/
│   ├── interview_stage.dart          # (existing or future - state machine stages)
│   ├── interview_failure.dart        # (existing or future)
│   ├── interview_role.dart           # NEW - enum for roles
│   ├── interview_type.dart           # NEW - enum for interview types
│   ├── difficulty_level.dart         # NEW - enum for difficulty
│   └── interview_config.dart         # NEW - config model
├── presentation/
│   ├── cubit/
│   │   ├── configuration_cubit.dart  # NEW
│   │   ├── configuration_state.dart  # NEW
│   │   ├── interview_cubit.dart      # (future - story 2.1)
│   │   └── interview_state.dart      # (future - story 2.1)
│   ├── view/
│   │   ├── setup_page.dart           # NEW - route entrypoint
│   │   ├── setup_view.dart           # NEW - main UI
│   │   ├── interview_page.dart       # (future)
│   │   └── interview_view.dart       # (future)
│   └── widgets/
│       ├── configuration_summary_card.dart  # NEW
│       ├── role_selector.dart               # NEW
│       ├── type_selector.dart               # NEW
│       ├── difficulty_selector.dart         # NEW
│       └── question_count_selector.dart     # NEW
└── data/
    └── interview_repository.dart     # (future - API calls)
```

#### Routing Pattern
- Use `go_router 17.0.1` (add to pubspec.yaml if not present)
- Routes should follow the pattern: `/setup`, `/interview`
- Define routes in `lib/app/` directory (VGV convention)

### UX Requirements (MUST FOLLOW)

#### Visual Design - Calm Ocean Theme
```dart
// Primary Colors
const kPrimary = Color(0xFF2F6FED);
const kSecondary = Color(0xFF27B39B);
const kBackground = Color(0xFFF7F9FC);
const kSurface = Color(0xFFFFFFFF);
const kTextPrimary = Color(0xFF0F172A);
const kTextMuted = Color(0xFF5B6475);

// Semantic Colors
const kSuccess = Color(0xFF1E9E6A);
const kWarning = Color(0xFFD99A00);
const kError = Color(0xFFD64545); // Use sparingly
```

#### Typography Scale
- H1: 28/34, semibold (screen titles)
- H2: 22/28, semibold (section headers)
- H3: 18/24, semibold (card titles)
- Body: 16/24, regular (primary text)
- Small: 14/20, regular (helper text)
- Micro: 12/16, medium (labels/status chips)

#### Spacing System (8dp base)
- 8dp: tight grouping
- 16dp: default spacing
- 24dp: section spacing
- 32dp: major separation

#### Component Guidelines
- Primary CTA (Start Interview): Material 3 Filled button, bottom-anchored
- Selectors: Use bottom sheet for long lists (roles), segmented controls for short lists (3 items)
- Cards: Use Material Surface with 8dp radius
- Touch targets: minimum 44dp

#### Layout Principles
- **Stability first:** layout should not jump during selection changes
- **Single dominant action:** "Start Interview" is the only primary CTA
- **Airy but not sparse:** provide breathing room to reduce anxiety

### Configuration Data Defaults

#### Interview Roles (Phase 1 MVP)
```dart
enum InterviewRole {
  softwareEngineer,
  productManager,
  dataScientist,
  generalBusiness,
}
```

#### Interview Types
```dart
enum InterviewType {
  behavioral, // "Tell me about a time..."
  technical,  // Role-specific technical questions
}
```

#### Difficulty Levels
```dart
enum DifficultyLevel {
  easy,    // Entry-level, supportive prompts
  medium,  // Mid-level, moderate challenge
  hard,    // Senior-level, tough follow-ups
}
```

#### Defaults
- Role: `softwareEngineer`
- Type: `behavioral`
- Difficulty: `medium`
- Question count: `5`

### Previous Story Intelligence (Story 1.1)

#### Key Learnings
- VGV template creates standard structure - preserve it
- VGV template had lint error on `context.select` - fixed by using `context.watch<Cubit>()`
- Stub directories already exist: `lib/core/`, `lib/features/interview/`
- 8 tests pass in the template; maintain test coverage

#### Files Modified/Created
- `lib/counter/view/counter_page.dart` was modified for lint fix
- Core stubs exist but are empty placeholders

#### Dependencies Already Installed
- `flutter_bloc 9.1.1` ✓
- `bloc_test` ✓
- `mocktail` ✓

#### Dependencies to Add
```yaml
# Add to pubspec.yaml
dependencies:
  go_router: ^17.0.1
  shared_preferences: ^2.5.3
  equatable: ^2.0.7  # If not already present (check VGV template)
```

### Anti-Patterns to AVOID

- ❌ Do NOT put configuration logic in `InterviewCubit` - keep cubits single-purpose
- ❌ Do NOT use plain StatefulWidget with setState - use Cubit
- ❌ Do NOT hardcode string values for roles/types - use enums
- ❌ Do NOT create custom widgets without reusing Material 3 foundations
- ❌ Do NOT use red/error colors for normal UI states - reserve for true errors
- ❌ Do NOT skip tests - maintain VGV test coverage standards
- ❌ Do NOT create navigation outside go_router pattern
- ❌ Do NOT use camelCase for file names - use snake_case per VGV conventions

### Project Structure Notes

- Alignment with unified project structure: all new files go under `lib/features/interview/`
- Domain models are separate from presentation (Clean Architecture lite)
- Cubit files are under `presentation/cubit/`, not `domain/`
- Widget tests go under `test/features/interview/`

### Testing Standards

- **Unit tests:** Test `ConfigurationCubit` state transitions
- **Widget tests:** Test `SetupView` renders correctly and responds to user input
- **Coverage:** Maintain existing coverage percentage
- **Mocking:** Use `mocktail` for dependencies

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture] - flutter_bloc, go_router, feature-first structure
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries] - file locations
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Visual Design Foundation] - Calm Ocean colors, typography
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Component Strategy] - Material 3 foundations
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.2] - acceptance criteria
- [Source: _bmad-output/planning-artifacts/prd.md#FR2-FR5] - functional requirements

### Dev Agent Record

### Agent Model Used

Claude Sonnet 4 (Antigravity)

### Debug Log References

None required - implementation proceeded without blocking issues.

### Completion Notes List

- ✅ Created domain models (InterviewRole, InterviewType, DifficultyLevel, InterviewConfig) with validation
- ✅ Implemented Calm Ocean theme tokens (VoiceMockColors, VoiceMockTypography, VoiceMockSpacing)
- ✅ Built ConfigurationCubit with full persistence via SharedPreferences
- ✅ Created responsive SetupView with all selectors (role, type, difficulty, question count)
- ✅ Implemented role selector with scrollable bottom sheet picker
- ✅ Created ConfigurationSummaryCard showing all current selections
- ✅ Added go_router integration with /setup route and placeholder /interview route
- ✅ All 50 tests pass (19 domain, 15 cubit, 8 widget, 8 existing)
- ✅ No lint issues - code passes `dart analyze`

### Review Fixes
- ✅ **Code Review**: Fixed "Brittle Persistence" by storing enum names instead of indices in `ConfigurationCubit`
- ✅ **Code Review**: Fixed "Inefficient Dependency Injection" by hoisting `SharedPreferences` to `App` level and removing `FutureBuilder` in `SetupPage`
- ✅ **Code Review**: Fixed "Navigation" by wiring `go_router` in `SetupView` to navigate to `/interview`
- ✅ **Code Review**: Tracked previously untracked new files in `lib/features/interview/`

### Change Log

- 2026-02-03: Story implementation complete - all 8 tasks finished
- 2026-02-03: Code review fixes applied - robustness, DI efficiency, and navigation wiring

### File List

**New Files (17):**
- `lib/core/theme/voicemock_theme.dart` - Calm Ocean design tokens
- `lib/features/interview/domain/interview_role.dart` - InterviewRole enum
- `lib/features/interview/domain/interview_type.dart` - InterviewType enum
- `lib/features/interview/domain/difficulty_level.dart` - DifficultyLevel enum
- `lib/features/interview/domain/interview_config.dart` - InterviewConfig model
- `lib/features/interview/presentation/cubit/configuration_cubit.dart` - ConfigurationCubit (Updated)
- `lib/features/interview/presentation/cubit/configuration_state.dart` - ConfigurationState
- `lib/features/interview/presentation/view/setup_page.dart` - SetupPage (Updated)
- `lib/features/interview/presentation/view/setup_view.dart` - SetupView widget (Updated)
- `lib/features/interview/presentation/widgets/role_selector.dart` - Role selector with bottom sheet
- `lib/features/interview/presentation/widgets/type_selector.dart` - Interview type selector
- `lib/features/interview/presentation/widgets/difficulty_selector.dart` - Difficulty selector
- `lib/features/interview/presentation/widgets/question_count_selector.dart` - Question count slider
- `lib/features/interview/presentation/widgets/configuration_summary_card.dart` - Summary card
- `lib/app/router.dart` - go_router configuration
- `test/features/interview/domain/interview_config_test.dart` - Domain model tests
- `test/features/interview/presentation/cubit/configuration_cubit_test.dart` - Cubit tests (Updated)
- `test/features/interview/presentation/view/setup_view_test.dart` - Widget tests (Updated)

**Modified Files (7):**
- `pubspec.yaml` - Added shared_preferences and equatable dependencies
- `lib/bootstrap.dart` - Added SharedPreferences initialization
- `lib/app/view/app.dart` - Updated for DI and go_router
- `lib/features/interview/domain/domain.dart` - Updated barrel exports
- `lib/features/interview/presentation/presentation.dart` - Updated barrel exports
- `lib/counter/view/counter_page.dart` - Added navigation to setup screen
- `lib/main_*.dart` - Updated bootstrapping (3 files)
