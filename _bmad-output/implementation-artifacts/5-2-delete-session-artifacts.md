# Story 5.2: Delete Session Artifacts

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to delete my session artifacts,
So that I can control my data.

## Implements

FR34 (User can delete a session's stored artifacts — at minimum: transcript and summary)

## Acceptance Criteria (ACs)

### AC 1: Backend DELETE endpoint removes session artifacts

**Given** I have an active or completed session (`session_id`, `session_token`)
**When** the app calls `DELETE /session/{session_id}` with a valid Bearer token
**Then** the backend deletes the session's stored artifacts (transcript, turn history, summary, coaching feedback)
**And** the backend also purges any TTS audio entries associated with the session from the TTS cache
**And** the backend returns a wrapped JSON success response `{ "data": { "deleted": true }, "error": null, "request_id": "..." }`
**And** the response includes the `X-Request-ID` header

### AC 2: Delete endpoint rejects unauthorized or invalid requests

**Given** a delete request is made
**When** the `session_token` is missing, expired, or invalid
**Then** the backend returns a `401` error with a stage-aware error object
**And** the response includes `request_id`

**Given** a delete request targets a non-existent session
**When** the `session_id` is not found in the store
**Then** the backend returns a `404` error with `{ "error": { "stage": "unknown", "code": "session_not_found", "message_safe": "Session not found or already deleted.", "retryable": false } }`

### AC 3: Mobile app sends delete request and handles response

**Given** I have a current session stored in the app state
**When** the app sends a `DELETE /session/{session_id}` request via `ApiClient`
**Then** the app uses the stored `session_token` as `Authorization: Bearer <token>`
**And** handles success (clear local session state) and error (show error message) responses

### AC 4: Delete confirmation dialog in Settings

**Given** I have an active or recently completed session
**When** I navigate to Settings → Data & Privacy and tap "Delete Session Data"
**Then** a confirmation dialog appears with calm, non-legalistic language:

- Title: "Delete Session Data?"
- Body: "This will permanently delete your transcripts, coaching feedback, and session summary. This cannot be undone."
- Primary action: "Delete" (destructive styling)
- Secondary action: "Cancel"

### AC 5: Successful deletion feedback

**Given** I confirm deletion in the dialog
**When** the delete request succeeds
**Then** the app shows a SnackBar: "Session data deleted."
**And** the "Delete Session Data" tile is disabled or hidden (no session to delete)
**And** local session references are cleared

### AC 6: Delete failure is recoverable

**Given** I confirm deletion
**When** the delete request fails (network error, server error)
**Then** the app shows a SnackBar with the error message and a "Retry" action
**And** the "Delete Session Data" option remains available

### AC 7: Deletion completes within acceptable time

**Given** the NFR requirement (user-initiated deletion completes within 30s)
**When** I trigger deletion
**Then** the backend processes the delete and responds within the 30-second window
**And** a loading indicator is shown while the request is in progress

## Tasks

- [x] Task 1: Create `DELETE /session/{session_id}` backend endpoint (AC: 1, 2)
  - [x] 1.1: Create route handler in `services/api/src/api/routes/session.py`
  - [x] 1.2: Add `@router.delete("/{session_id}")` with token verification via `Depends`
  - [x] 1.3: Validate session token against `session_id` using `SessionTokenService`
  - [x] 1.4: Call `session_store.delete_session(session_id)` to remove session data
  - [x] 1.5: Call `tts_cache.cleanup()` to purge any lingering TTS entries (MVP: full cleanup is acceptable since sessions are short-lived)
  - [x] 1.6: Return `ApiEnvelope(data={"deleted": True}, error=None, request_id=ctx.request_id)` on success
  - [x] 1.7: Return 404 with stage-aware error if session not found
  - [x] 1.8: Return 401 if token is invalid/missing (handled by existing auth dependency)

- [x] Task 2: Create response model for delete endpoint (AC: 1)
  - [x] 2.1: Add `DeleteSessionResponse` (or `DeleteResult`) model in `services/api/src/api/models/session_models.py`
  - [x] 2.2: Model contains `deleted: bool` field
  - [x] 2.3: Wire into `ApiEnvelope` response

- [x] Task 3: Add `delete` method to mobile `ApiClient` (AC: 3)
  - [x] 3.1: Add `ApiClient.delete<T>(String path, {required T Function(Map<String, dynamic>) fromJson, String? bearerToken})` method
  - [x] 3.2: Follow the same envelope parsing and error mapping as `post()` / `postMultipart()`
  - [x] 3.3: Include `X-Request-ID` injection via existing interceptor

- [x] Task 4: Add delete session method to mobile data layer (AC: 3)
  - [x] 4.1: Create or extend the session/interview repository with `deleteSession(String sessionId, String sessionToken)` method
  - [x] 4.2: Call `ApiClient.delete('/session/$sessionId', bearerToken: sessionToken, fromJson: ...)`
  - [x] 4.3: Return success/failure result

- [x] Task 5: Create delete confirmation dialog widget (AC: 4)
  - [x] 5.1: Create `apps/mobile/lib/features/settings/presentation/widgets/delete_session_dialog.dart`
  - [x] 5.2: Implement as a `showDialog()` with calm copy: title "Delete Session Data?", body explaining what's deleted, "Delete" (destructive) + "Cancel" buttons
  - [x] 5.3: Use `VoiceMockColors.error` (#D64545) only for the Delete button text/background — keep the rest neutral
  - [x] 5.4: Return `true` from dialog if user confirms, `false`/null if cancelled

- [x] Task 6: Add "Delete Session Data" tile to Settings page (AC: 4, 5, 6, 7)
  - [x] 6.1: Add a new section or ListTile in `SettingsPage` under the Data & Privacy section
  - [x] 6.2: Tile shows "Delete Session Data" with a delete icon and calm subtitle: "Remove transcripts, feedback, and summary"
  - [x] 6.3: On tap: show the confirmation dialog from Task 5
  - [x] 6.4: On confirm: show loading indicator, call delete API, handle success (SnackBar + disable tile), handle failure (SnackBar with Retry)
  - [x] 6.5: Disable or hide the tile when there is no active session to delete
  - [x] 6.6: Manage session availability state (read from InterviewCubit or passed as parameter)

- [x] Task 7: Clear local session state after deletion (AC: 5)
  - [x] 7.1: After successful backend deletion, clear `session_id` and `session_token` from local state
  - [x] 7.2: If the InterviewCubit holds session references, reset relevant fields
  - [x] 7.3: Ensure the app returns to a clean state (can start a new session)

- [x] Task 8: Add backend unit tests for delete endpoint (AC: 1, 2)
  - [x] 8.1: Test successful deletion returns `200` with `{ "data": { "deleted": true } }`
  - [x] 8.2: Test deletion of non-existent session returns `404`
  - [x] 8.3: Test unauthorized request (no/bad token) returns `401`
  - [x] 8.4: Test session data is actually removed from the store after deletion
  - [x] 8.5: Test `X-Request-ID` is present in response

- [x] Task 9: Add mobile unit and widget tests (AC: 3, 4, 5, 6)
  - [x] 9.1: Test `ApiClient.delete()` parses envelope correctly
  - [x] 9.2: Test delete session repository method handles success and failure
  - [x] 9.3: Test `DeleteSessionDialog` renders with correct copy and buttons
  - [x] 9.4: Test confirm returns `true`, cancel returns `false`
  - [x] 9.5: Test `SettingsPage` shows "Delete Session Data" tile
  - [x] 9.6: Test tile tap shows confirmation dialog
  - [x] 9.7: Test successful deletion shows SnackBar and disables tile
  - [x] 9.8: Test failed deletion shows error SnackBar with Retry option

## Dev Notes

### Architecture Alignment

- **Backend:** The `SessionStore` already implements `delete_session(session_id)` (returns `True`/`False`). The new route handler is a thin wrapper that validates the token and calls the existing method. No new service logic needed.
- **API Contract:** Follow the established wrapped envelope pattern: `{ "data": ..., "error": ..., "request_id": "..." }`. Use `snake_case` fields. Include `X-Request-ID` header.
- **Mobile `ApiClient`:** Currently has `post()` and `postMultipart()` methods but **no `delete()` method**. Must add one following the identical envelope parsing and error mapping patterns.
- **Authentication:** The `DELETE /session/{session_id}` endpoint MUST validate the session token (Bearer token) against the `session_id`. Reuse the existing auth dependency patterns from `turn.py` route (see `verify_session_token` or equivalent).
- **TTS Cache:** On session deletion, also clean up any TTS cache entries. The `TTSCache` does not currently index by `session_id`, so a full `cleanup()` call (which removes expired entries) is the MVP approach. The TTSCache TTL (5 min default) means most entries will already be expired by the time a user manually deletes. This is acceptable for MVP.
- **State Machine:** The `InterviewCubit` and state machine are NOT affected by deletion. Deletion is an out-of-band settings action, not a state machine transition.

### UX Alignment

- **UX Spec §User Controls:** "Provide 'Delete session' (clears transcript/summary) and 'Clear diagnostics' (clears request IDs) in Settings." — This story covers the "Delete session" control. "Clear diagnostics" is deferred to Story 5.4.
- **UX Spec §Modal and Overlay Patterns:** "Use dialogs for irreversible actions (delete/wipe) or actions with clear data loss." — Confirm deletion with a dialog, not a bottom sheet.
- **UX Spec §Button Hierarchy:** "Destructive: only for irreversible actions. Confirm if data loss is possible." — The Delete button should use destructive styling.
- **UX Spec §Feedback Patterns:** "SnackBar: transient confirmation." — Use SnackBar for "Session data deleted." confirmation.
- **Tone:** Calm, non-legalistic. "This will permanently delete your transcripts, coaching feedback, and session summary." Not "Are you sure? This action is irreversible!" — avoid panic language.

### Settings Page Integration

- The `SettingsPage` already exists at `apps/mobile/lib/features/settings/presentation/view/settings_page.dart` (created in Story 5.1).
- It already has a "Data & Privacy" section header and a "Processing Disclosure" tile.
- Add the "Delete Session Data" tile below the existing "Processing Disclosure" tile, within the same section.
- The tile should be conditionally enabled: only when the app has an active/recent session with a valid `session_id` and `session_token`.

### Session State Availability

- The `SettingsPage` is a `StatelessWidget`. To know if a session exists for deletion, it needs access to session state.
- **Approach options (pick simplest for MVP):**
  1. Pass `session_id` and `session_token` as constructor parameters to `SettingsPage` from the router.
  2. Use `context.read<InterviewCubit>()` if the cubit is provided above the Settings route in the widget tree.
  3. Convert `SettingsPage` to `StatefulWidget` with its own minimal state management for the delete flow.
- The recommended approach is (2) if the `InterviewCubit` is available in the widget tree above the Settings route, or (1) as a simpler alternative.

### Key Backend Files to Modify/Create

| File                                             | Action | Notes                                         |
| ------------------------------------------------ | ------ | --------------------------------------------- |
| `services/api/src/api/routes/session.py`         | MODIFY | Add `@router.delete("/{session_id}")` handler |
| `services/api/src/api/models/session_models.py`  | MODIFY | Add `DeleteResult` response model             |
| `services/api/tests/unit/test_session_delete.py` | NEW    | Unit tests for delete endpoint                |

### Key Mobile Files to Modify/Create

| File                                                                                | Action | Notes                                        |
| ----------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| `apps/mobile/lib/core/http/api_client.dart`                                         | MODIFY | Add `delete<T>()` method                     |
| `apps/mobile/lib/features/settings/presentation/view/settings_page.dart`            | MODIFY | Add "Delete Session Data" tile + delete flow |
| `apps/mobile/lib/features/settings/presentation/widgets/delete_session_dialog.dart` | NEW    | Confirmation dialog                          |
| `apps/mobile/test/features/settings/`                                               | NEW    | Widget tests for delete flow                 |

### Token Verification Pattern (from `turn.py`)

The existing turn endpoint verifies the session token. Follow the same pattern for the delete endpoint:

```python
from src.api.dependencies.shared_services import get_session_store, get_token_service
from src.security import SessionTokenService

# In the route handler:
token_service.verify_token(token, session_id)  # raises if invalid
```

### NFR Compliance

- **NFR9:** "User-initiated deletion completes within 30s." — The in-memory delete is near-instantaneous. Network latency is the main variable. Add a client-side timeout.
- **NFR10:** "Logs must never contain raw audio; transcript logging is disabled by default." — The delete endpoint should log `session_id` and `request_id` only, not transcript content.

### Key Risks

1. **No `delete()` in `ApiClient`:** Requires adding a new HTTP method to the mobile API client. Follow identical patterns to `post()` for envelope parsing.
2. **Session state not available in Settings:** Must determine how `SettingsPage` accesses `session_id`/`session_token`. Evaluate the widget tree before implementing.
3. **TTS cache not indexed by session:** Cannot surgically delete only TTS entries for one session. Full `cleanup()` of expired entries is the MVP workaround. This is acceptable since TTS entries expire in 5 minutes.
4. **Concurrent deletion + active session:** If user deletes while a turn is in-flight, the turn response may fail with "session not found." This is acceptable for MVP — the delete is user-initiated from Settings (not mid-interview).

### Dependencies

- **Upstream:** Story 5.1 (Settings page created — ✅ done).
- **Downstream:** Story 5.4 (Diagnostics screen) may add "Clear diagnostics" next to "Delete session data."
- **Packages:** No new packages required. Uses existing `dio`, `flutter_bloc`, `shared_preferences`.

### Previous Story Intelligence (5-1)

- `SettingsPage` is at `features/settings/presentation/view/settings_page.dart` (78 lines). Simple `StatelessWidget` with one "Data & Privacy" section and one tile ("Processing Disclosure").
- Widget conventions: use `VoiceMockColors`, `VoiceMockTypography`, `VoiceMockSpacing` tokens.
- `DisclosureDetailSheet.show(context)` pattern used from Settings — similar pattern for showing the delete dialog.
- `DisclosurePrefs` uses `SharedPreferences` — the delete flow does not need `SharedPreferences` (state is from InterviewCubit or API).
- Full regression suite: 426 tests passed last story. Expect ~440+ after this story.
- `disclosure_strings.dart` established the pattern for string constants — create similar for delete dialog copy if needed (or inline since it's only 2 strings).

### Git Intelligence

- Latest commits are on Story 5.1 (third-party processing disclosure) + Epic 4 retrospective.
- The backend test structure uses `tests/unit/` and `tests/integration/` directories.
- Mobile test structure mirrors `lib/` structure under `test/`.

### Project Structure Notes

- New backend files go in `services/api/src/api/routes/` (route modification) and `services/api/tests/unit/` (new test file).
- New mobile files go in `features/settings/presentation/widgets/` (dialog) and `test/features/settings/` (tests).
- `ApiClient` modification is in `core/http/api_client.dart`.
- All file placements align with established project conventions.

### References

- [epics.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/epics.md) — Epic 5, Story 5.2 (FR34)
- [architecture.md §Data Architecture](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — Session retention, deletion controls, API patterns
- [architecture.md §API Patterns](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/architecture.md) — Wrapped envelope `{data, error, request_id}`, `X-Request-ID`, `snake_case`
- [ux-design-specification.md §User Controls](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — "Provide delete session in Settings"
- [ux-design-specification.md §Modal Patterns](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/planning-artifacts/ux-design-specification.md) — "Use dialogs for irreversible actions"
- [session_store.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/services/session_store.py) — Existing `delete_session()` method
- [session.py](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/services/api/src/api/routes/session.py) — Existing session route (add DELETE handler here)
- [api_client.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/core/http/api_client.dart) — Mobile API client (needs `delete()` method)
- [settings_page.dart](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/apps/mobile/lib/features/settings/presentation/view/settings_page.dart) — Settings page (add delete tile here)
- [5-1-third-party-processing-disclosure.md](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/5-1-third-party-processing-disclosure.md) — Previous story learnings
- [sprint-status.yaml](file:///c:/Users/avish/OneDrive/Documents/Projects/voicemock-ai-interview/voicemock-ai-interview/_bmad-output/implementation-artifacts/sprint-status.yaml) — Sprint tracking

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex

### Debug Log References

- Backend targeted tests: `python -m pytest tests/unit/test_session_delete.py tests/unit/test_session_models.py` (6 passed)
- Mobile targeted tests: `flutter test test/core/http/api_client_delete_test.dart test/features/interview/data/repositories/session_repository_impl_test.dart test/features/settings/presentation/widgets/delete_session_dialog_test.dart test/features/settings/presentation/view/settings_page_delete_test.dart` (18 passed)
- Backend full regression: `python -m pytest` (151 passed)
- Mobile full regression: `flutter test` (437 passed, 1 skipped)

### Completion Notes List

- Added backend `DELETE /session/{session_id}` route with Bearer token verification, session/token matching, 401/404 error envelopes, and success envelope `{deleted: true}`.
- Added backend delete response models (`DeleteResult`, `DeleteSessionResponse`) and model exports.
- Added `ApiClient.delete<T>()` with standard envelope parsing, error mapping, and optional Bearer token header.
- Extended session data layer with remote `deleteSession`, repository `deleteSession` + local clear, and `getStoredSession()` for Settings UX.
- Added `DeleteSessionDialog` and integrated delete flow in `SettingsPage` including confirmation dialog, in-progress spinner, success snackbar, failure snackbar with Retry, and tile disable when no local session exists.
- Registered `SessionRepository` at app root to support Settings route access.
- Added backend unit tests for delete success/404/401/store removal/request-id-header and mobile tests for API client delete, repository delete behavior, dialog behavior, and Settings delete UX.

### File List

- services/api/src/api/models/session_models.py
- services/api/src/api/models/**init**.py
- services/api/src/api/routes/session.py
- services/api/tests/unit/test_session_delete.py
- apps/mobile/lib/core/models/session_models.dart
- apps/mobile/lib/core/http/api_client.dart
- apps/mobile/lib/features/interview/data/datasources/session_remote_data_source.dart
- apps/mobile/lib/features/interview/domain/session_repository.dart
- apps/mobile/lib/features/interview/data/repositories/session_repository_impl.dart
- apps/mobile/lib/features/settings/presentation/widgets/delete_session_dialog.dart
- apps/mobile/lib/features/settings/presentation/view/settings_page.dart
- apps/mobile/lib/app/view/app.dart
- apps/mobile/test/core/http/api_client_delete_test.dart
- apps/mobile/test/features/interview/data/repositories/session_repository_impl_test.dart
- apps/mobile/test/features/settings/presentation/widgets/delete_session_dialog_test.dart
- apps/mobile/test/features/settings/presentation/view/settings_page_delete_test.dart
- \_bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- 2026-02-19: Implemented Story 5.2 end-to-end (backend delete endpoint + mobile delete UX + comprehensive tests) and moved story status to `review`.
- 2026-02-19: Completed code review. Fixed timeout mismatch (30s), UX dead-end on 404 (idempotent delete), and blocking cleanup (background task). Moved status to `done`.
