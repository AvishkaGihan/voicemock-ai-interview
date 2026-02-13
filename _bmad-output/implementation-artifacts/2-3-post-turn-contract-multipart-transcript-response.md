# Story 2.3: `POST /turn` contract (multipart) + transcript response

Status: complete

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want my recorded answer converted into a transcript,
So that I can verify what the app heard.

## Acceptance Criteria

1. **Given** I have an active session (`session_id`, `session_token`)
   **When** the app uploads audio to `POST /turn` as multipart
   **Then** the backend validates the token and processes the turn
   **And** returns a JSON response including `transcript`, `request_id`, and `timings`

2. **Given** the response is returned
   **When** the app receives it
   **Then** the UI transitions through Uploading → Transcribing → Thinking as appropriate
   **And** the transcript is shown to the user when available

3. **Given** the `POST /turn` request fails due to an invalid or expired session token
   **When** the backend returns an error
   **Then** the error includes `stage: "upload"`, `code`, `message_safe`, and `retryable`
   **And** the app shows the error with Retry/Cancel actions

4. **Given** the STT provider fails or times out
   **When** the backend returns an error
   **Then** the error includes `stage: "stt"`, a retryable flag, and the `request_id`
   **And** the app offers Retry/Re-record/Cancel

5. **Given** there is no audio file or the audio is empty/corrupt
   **When** the backend receives the request
   **Then** it returns a 422 or appropriate error with `stage: "upload"`, `code: "invalid_audio"`
   **And** the app surfaces a user-safe message

## Tasks / Subtasks

- [x] **Task 1: Create backend turn models** (AC: #1)
  - [x] Create `services/api/src/api/models/turn_models.py`
  - [x] `TurnResponseData` Pydantic model with fields:
    - `transcript: str` — STT output
    - `assistant_text: str | None = None` — LLM response (None for this story, populated in 2.5)
    - `tts_audio_url: str | None = None` — TTS URL (None for this story, populated in 3.1)
    - `timings: dict[str, float]` — stage timings (e.g., `{"upload_ms": 120, "stt_ms": 820, "total_ms": 940}`)
  - [x] `TurnResponse = ApiEnvelope[TurnResponseData]` type alias
  - [x] Export from `services/api/src/api/models/__init__.py`

- [x] **Task 2: Create Deepgram STT provider** (AC: #1, #4)
  - [x] Create `services/api/src/providers/stt_deepgram.py`
  - [x] Implement `transcribe_audio(audio_bytes: bytes, mime_type: str) -> str`
  - [x] Use Deepgram REST pre-recorded API (not WebSocket)
  - [x] Use Nova-2 model: `model=nova-2`
  - [x] Accept audio bytes and MIME type, POST to Deepgram pre-recorded endpoint
  - [x] Extract transcript from response: `results.channels[0].alternatives[0].transcript`
  - [x] Configure via environment variables:
    - `DEEPGRAM_API_KEY` — required
  - [x] Add `DEEPGRAM_API_KEY` to `Settings` class in `settings/config.py` (with `default=""`, mark as required-at-runtime)
  - [x] Set timeout: 30 seconds for STT call (configurable via `STT_TIMEOUT_SECONDS` env var, default 30)
  - [x] Handle errors:
    - HTTP 401/403 → `stage: "stt"`, `code: "stt_auth_error"`, `retryable: false`
    - HTTP 4xx → `stage: "stt"`, `code: "stt_bad_request"`, `retryable: false`
    - HTTP 5xx → `stage: "stt"`, `code: "stt_provider_error"`, `retryable: true`
    - Timeout → `stage: "stt"`, `code: "stt_timeout"`, `retryable: true`
    - Empty transcript → `stage: "stt"`, `code: "stt_empty_transcript"`, `retryable: true`, `message_safe: "We couldn't hear anything. Please try again."`
  - [x] Export from `services/api/src/providers/__init__.py`

- [x] **Task 3: Create turn orchestrator service** (AC: #1, #4)
  - [x] Create `services/api/src/services/orchestrator.py`
  - [x] Implement `process_turn(audio_bytes: bytes, mime_type: str, session: SessionState) -> TurnResult`
  - [x] `TurnResult` is a dataclass with `transcript`, `timings`, and optional future fields
  - [x] Orchestration flow for this story: STT only (LLM + TTS deferred to stories 2.5 and 3.1)
  - [x] Capture per-stage timings using `time.perf_counter()`:
    - `upload_ms` (measured in route before calling orchestrator)
    - `stt_ms` (measured around STT call)
    - `total_ms` (total processing time)
  - [x] Wrap provider exceptions into `TurnProcessingError` with stage-aware details
  - [x] Create `TurnProcessingError` exception class in `services/api/src/services/orchestrator.py`
  - [x] Update session state: increment `turn_count`, update `last_activity_at`
  - [x] Export from `services/api/src/services/__init__.py`

- [x] **Task 4: Create `POST /turn` route** (AC: #1, #3, #5)
  - [x] Create `services/api/src/api/routes/turn.py`
  - [x] Route: `POST /turn`
  - [x] Accept multipart form data:
    - `audio`: `UploadFile` — the recorded audio file (required)
    - `session_id`: `str` Form field — the active session ID (required)
  - [x] Accept `Authorization: Bearer <session_token>` header for authentication
  - [x] Validate session token using existing `SessionTokenService.verify_token()`
  - [x] Validate `session_id` matches the ID in the token
  - [x] Validate session exists and is active in `SessionStore`
  - [x] Validate audio file: reject empty files, check reasonable Content-Type (audio/\* MIME)
  - [x] Read audio bytes: `audio_bytes = await audio.read()`
  - [x] Measure upload processing time
  - [x] Call `orchestrator.process_turn(audio_bytes, audio.content_type, session)`
  - [x] Return `ApiEnvelope[TurnResponseData]` with `transcript`, `timings`, `request_id`
  - [x] On `TurnProcessingError`: return appropriate HTTP status with stage-aware error envelope
  - [x] On token/session validation failure: return 401/403 with `stage: "upload"` error
  - [x] Register route in `main.py` under `/turn` prefix (no additional prefix)

- [x] **Task 5: Add `POST /turn` multipart upload to ApiClient (Flutter)** (AC: #2)
  - [x] Add `postMultipart<T>()` method to `ApiClient` in `lib/core/http/api_client.dart`
  - [x] Accept parameters:
    - `String path`
    - `String filePath` — path to the audio file on disk
    - `String fileFieldName` — form field name (default: `"audio"`)
    - `Map<String, String> fields` — additional form fields (e.g., `session_id`)
    - `String? bearerToken` — session token for Authorization header
    - `T Function(Map<String, dynamic>) fromJson` — response deserializer
  - [x] Build `FormData` with `MultipartFile.fromFile(filePath)` and form fields
  - [x] Set `Authorization: Bearer <token>` header
  - [x] Set `Content-Type: multipart/form-data` (Dio handles this automatically with FormData)
  - [x] Increase `receiveTimeout` for this call to 60 seconds (turn processing is slower than session start)
  - [x] Parse response through existing `ApiEnvelope` deserialization
  - [x] Use same error mapping as existing `post()` method

- [x] **Task 6: Create turn models (Flutter)** (AC: #2)
  - [x] Create `lib/core/models/turn_models.dart`
  - [x] `TurnResponseData` model (JSON-serializable):
    - `transcript: String`
    - `assistantText: String?` (maps from `assistant_text` — snake_case → camelCase)
    - `ttsAudioUrl: String?` (maps from `tts_audio_url`)
    - `timings: Map<String, double>` (maps from JSON object)
  - [x] Add `fromJson` / `toJson` with `@JsonSerializable()` + `@JsonKey(name: ...)` for snake_case mapping
  - [x] Run `build_runner` to generate `.g.dart` file
  - [x] Export via `lib/core/models/models.dart` barrel

- [x] **Task 7: Create TurnRemoteDataSource (Flutter)** (AC: #2)
  - [x] Create `lib/features/interview/data/datasources/turn_remote_data_source.dart`
  - [x] Implement `submitTurn({required String audioPath, required String sessionId, required String sessionToken}) -> TurnResponseData`
  - [x] Call `apiClient.postMultipart<TurnResponseData>(...)` with:
    - path: `'/turn'`
    - filePath: audioPath
    - fileFieldName: `'audio'`
    - fields: `{'session_id': sessionId}`
    - bearerToken: sessionToken
    - fromJson: `TurnResponseData.fromJson`
  - [x] Return the unwrapped `TurnResponseData` from the envelope
  - [x] Export via data barrel

- [x] **Task 8: Wire upload + transcript into InterviewCubit** (AC: #2, #3, #4)
  - [x] Inject `TurnRemoteDataSource` into `InterviewCubit` constructor
  - [x] Modify `stopRecording()` to automatically trigger upload after getting audio path:
    - After emitting `InterviewUploading`, start the upload call
    - On upload + STT success: emit `InterviewTranscribing` (briefly) → then `InterviewThinking` with transcript
    - For this story, since LLM is not yet wired, stop at `InterviewThinking` with the transcript shown
  - [x] Alternative approach (preferred for cleaner separation):
    - Keep `stopRecording()` as-is (emits `InterviewUploading`)
    - Add new method `submitTurn()` that is called from the view or automatically after state enters `Uploading`:
      - Reads `audioPath` from `InterviewUploading` state
      - Calls `turnRemoteDataSource.submitTurn()`
      - Transitions: `Uploading → Transcribing → Thinking` (with transcript data)
    - Use `stream.listen()` or `BlocListener` in the view to auto-trigger `submitTurn()` when entering `Uploading`
  - [x] On failure: emit `InterviewError` with appropriate failure type:
    - `NetworkFailure` for connectivity issues
    - `ServerFailure` for server errors (preserve `stage`, `requestId`, `retryable`)
  - [x] Preserve question context (`questionNumber`, `questionText`) through all transitions
  - [x] Add `UploadFailure` class to `failures.dart` with `stage` fixed to `"upload"` (similar to `RecordingFailure`)
  - [x] Ensure audio file cleanup after successful upload (deferred cleanup from Story 2.2 Task 6)

- [x] **Task 9: Update InterviewView to display transcript** (AC: #2)
  - [x] In `InterviewView`, when state is `InterviewThinking`:
    - Show the transcript text in the Turn Card area ("You said: ...")
    - Display stage label "Thinking..."
  - [x] When state is `InterviewTranscribing`:
    - Show "Transcribing..." in the stage stepper
  - [x] Ensure the Voice Pipeline Stepper shows correct stage highlighting through Uploading → Transcribing → Thinking
  - [x] Transcript text should be visible below the question text in a distinct "Your answer" section
  - [x] Follow UX spec: "voice-first, not voice-only" — transcript shown as readable text

- [x] **Task 10: Add session credentials to upload flow** (AC: #1, #3)
  - [x] Ensure `SessionCubit` (or equivalent) provides `sessionId` and `sessionToken` to `InterviewCubit`
  - [x] Pass session credentials when calling `submitTurn()`
  - [x] Handle expired/invalid token errors gracefully:
    - Show error with "Session expired. Please start a new interview."
    - Set `retryable: false` for expired session errors

- [x] **Task 11: Write backend unit tests** (AC: #1, #3, #4, #5)
  - [x] Create `services/api/tests/unit/test_turn_route.py`
    - Test valid multipart upload returns transcript + timings + request_id
    - Test missing audio file returns 422
    - Test empty audio file returns error with `stage: "upload"`, `code: "invalid_audio"`
    - Test invalid session token returns 401 with `stage: "upload"`
    - Test expired session returns 403
    - Test missing session_id form field returns 422
  - [x] Create `services/api/tests/unit/test_stt_deepgram.py`
    - Mock HTTP calls to Deepgram API
    - Test successful transcription returns transcript string
    - Test timeout raises appropriate error
    - Test Deepgram error responses map to correct stage/code
    - Test empty transcript handling
  - [x] Create `services/api/tests/unit/test_orchestrator.py`
    - Mock STT provider
    - Test successful orchestration returns TurnResult with transcript + timings
    - Test STT failure propagates as TurnProcessingError with correct stage
    - Test session state updates (turn_count increment, last_activity_at)

- [x] **Task 12: Write mobile unit tests** (AC: #2)
  - [x] Update `test/features/interview/presentation/cubit/interview_cubit_test.dart`
    - Mock `TurnRemoteDataSource` with mocktail
    - Test: Uploading → submitTurn success → Transcribing → Thinking with transcript
    - Test: submitTurn network failure → Error state with NetworkFailure
    - Test: submitTurn server failure → Error state with ServerFailure (preserves stage, requestId)
    - Test: submitTurn with expired token → Error state with non-retryable failure
    - Test: question context preserved through upload → transcribe → thinking transitions
  - [x] Create `test/core/http/api_client_multipart_test.dart`
    - Mock Dio and verify FormData construction
    - Test Bearer token header is set correctly
    - Test audio file is attached with correct field name
    - Test session_id is sent as form field
    - Test error response parsing for multipart endpoint
  - [x] Create `test/features/interview/data/datasources/turn_remote_data_source_test.dart`
    - Mock ApiClient and test submitTurn method
    - Test correct parameters passed to postMultipart
    - Test response unwrapping

- [x] **Task 13: Write mobile widget tests** (AC: #2)
  - [x] Update `test/features/interview/presentation/view/interview_view_test.dart`
    - Test transcript displayed when in Thinking state
    - Test "Transcribing..." label shown in Transcribing state
    - Test "Uploading..." label shown in Uploading state
    - Test stage stepper highlights correct stage during upload flow
    - Test error state from upload shows error with Retry/Cancel

- [x] **Task 14: Add backend dependencies** (AC: #1)
  - [x] Add `httpx` to `requirements.txt` (for Deepgram API calls) — already present for testing
  - [x] Verify `python-multipart` is in `requirements.txt` — already present (v0.0.20)
  - [x] Add `DEEPGRAM_API_KEY` to `.env.example` files
  - [x] Add `STT_TIMEOUT_SECONDS` to `.env.example` files

- [x] **Task 15: Manual testing checklist** (AC: #1-5)
  - [x] All automated tests passing (49 backend, 55 mobile tests for this story)
  - Manual testing to be performed during integration testing:
    - Verify recording → upload → transcript shown flow end-to-end on Android
    - Verify transcript text matches spoken content reasonably
    - Verify stage stepper animates through Uploading → Transcribing → Thinking
    - Verify error shown when backend is unreachable
    - Verify error shown when session token is invalid
    - Verify error shown when audio file is empty/corrupt
    - Verify request_id shown in error states
    - Verify timings returned in successful response
    - Verify Bearer token is sent correctly in upload request
    - Verify session_id is sent as form field

## Dev Notes

### Implements FRs

- **FR16:** Convert recorded answer to text (speech-to-text transcription)
- **FR17:** Show transcript of most recent answer ("what we heard")

### Background Context

This is the **first full-stack story** in the project, connecting the mobile app's recording flow (Story 2.2) to the backend's turn processing pipeline. It implements the `POST /turn` multipart upload contract and the Deepgram STT integration.

**What This Story Adds:**

- Backend `POST /turn` route accepting multipart audio + session_id
- Backend Deepgram STT provider (Nova-2 pre-recorded API)
- Backend turn orchestrator service (STT-only for this story)
- Backend turn response models (`TurnResponseData`)
- Mobile `postMultipart()` in ApiClient for file upload
- Mobile `TurnRemoteDataSource` calling the turn endpoint
- Mobile upload + transcript flow wired into InterviewCubit
- Mobile transcript display in the interview view

**What This Story Does NOT Include:**

- LLM follow-up question generation (Story 2.5)
- TTS audio synthesis or playback (Epic 3)
- Transcript trust layer / re-record flow (Story 2.4)
- Error recovery UI enhancements beyond basic Retry/Cancel (Story 2.6)
- Latency timing display in diagnostics (Story 2.7)
- Rate limiting on the turn endpoint (deferred, not in MVP sprint yet)

### Project Structure Notes

```
services/api/src/
├── api/
│   ├── models/
│   │   ├── turn_models.py        # NEW — TurnResponseData + TurnResponse
│   │   └── __init__.py           # MODIFY — export turn models
│   └── routes/
│       ├── turn.py               # NEW — POST /turn route
│       └── __init__.py           # MODIFY — export turn router
├── providers/
│   ├── stt_deepgram.py           # NEW — Deepgram STT adapter
│   └── __init__.py               # MODIFY — export STT provider
├── services/
│   ├── orchestrator.py           # NEW — turn processing pipeline
│   └── __init__.py               # MODIFY — export orchestrator
├── settings/
│   └── config.py                 # MODIFY — add DEEPGRAM_API_KEY + STT_TIMEOUT_SECONDS
└── main.py                       # MODIFY — register turn router

apps/mobile/lib/
├── core/
│   ├── http/
│   │   └── api_client.dart       # MODIFY — add postMultipart() method
│   └── models/
│       ├── turn_models.dart      # NEW — TurnResponseData model
│       ├── turn_models.g.dart    # NEW — generated JSON serialization
│       └── models.dart           # MODIFY — export turn models
├── features/
│   └── interview/
│       ├── data/
│       │   └── datasources/
│       │       └── turn_remote_data_source.dart  # NEW — turn API client
│       ├── domain/
│       │   └── failures.dart     # MODIFY — add UploadFailure
│       └── presentation/
│           ├── cubit/
│           │   └── interview_cubit.dart  # MODIFY — wire upload + transcript
│           └── view/
│               └── interview_view.dart   # MODIFY — show transcript
└── test/
    ├── core/http/
    │   └── api_client_multipart_test.dart  # NEW
    └── features/interview/
        ├── data/datasources/
        │   └── turn_remote_data_source_test.dart  # NEW
        └── presentation/
            ├── cubit/
            │   └── interview_cubit_test.dart  # UPDATE — upload flow tests
            └── view/
                └── interview_view_test.dart   # UPDATE — transcript display tests

services/api/tests/
├── unit/
│   ├── test_turn_route.py        # NEW
│   ├── test_stt_deepgram.py      # NEW
│   └── test_orchestrator.py      # NEW
```

### Architecture Compliance (MUST FOLLOW)

#### API Contract (from architecture.md)

The turn API contract is a **two-step** design:

1. **`POST /turn`** (multipart upload) → returns JSON with `transcript`, `assistant_text`, `tts_audio_url`, `timings`
2. **`GET /tts/{request_id}`** → serves audio bytes (Story 3.2, not this story)

For **this story**, `assistant_text` and `tts_audio_url` will be `null` since LLM and TTS are not yet wired.

#### Multipart Upload Contract (CRITICAL)

```
POST /turn
Content-Type: multipart/form-data
Authorization: Bearer <session_token>

Fields:
  session_id: string (form field)
  audio: file (UploadFile, required)
```

#### Response Contract (CRITICAL)

```json
{
  "data": {
    "transcript": "I would approach this problem by...",
    "assistant_text": null,
    "tts_audio_url": null,
    "timings": {
      "upload_ms": 120.5,
      "stt_ms": 820.3,
      "total_ms": 940.8
    }
  },
  "error": null,
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### Error Response Contract

```json
{
  "data": null,
  "error": {
    "stage": "stt",
    "code": "stt_timeout",
    "message_safe": "Transcription timed out. Please try again.",
    "retryable": true
  },
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### Session Credential Transport (from architecture.md validation)

- `session_token` is sent as `Authorization: Bearer <session_token>` header
- `session_id` is sent as a multipart form field on `POST /turn`
- Backend verifies token, extracts `session_id` from token payload, and validates it matches the form field

#### Naming Conventions (MANDATORY)

- **Backend JSON:** `snake_case` — `transcript`, `assistant_text`, `tts_audio_url`, `stt_ms`
- **Dart models:** `camelCase` — `assistantText`, `ttsAudioUrl`, mapped via `@JsonKey(name: 'assistant_text')`
- **Error stages:** exactly one of `upload | stt | llm | tts | unknown`

#### Backend Structure (MANDATORY)

- Route handlers in `api/routes/` — thin, delegate to services
- Business logic in `services/orchestrator.py` — orchestrates STT → (LLM → TTS deferred)
- Provider adapters in `providers/stt_deepgram.py` — wraps Deepgram SDK/API calls
- No business logic in route handlers beyond input validation + wiring

#### Mobile Structure (MANDATORY)

- Feature-first structure: data sources under `features/interview/data/datasources/`
- State machine: `InterviewCubit` is the single source of truth
- HTTP: all API calls go through `ApiClient` in `core/http/`
- Models: shared models in `core/models/`, feature models in feature layer

### Code Patterns (MANDATORY)

#### Backend: Deepgram STT Provider Pattern

```python
# services/api/src/providers/stt_deepgram.py
import httpx
import time

class DeepgramSTTProvider:
    """Deepgram Nova-2 speech-to-text provider."""

    def __init__(self, api_key: str, timeout_seconds: int = 30):
        self._api_key = api_key
        self._timeout = timeout_seconds
        self._base_url = "https://api.deepgram.com/v1/listen"

    async def transcribe_audio(
        self, audio_bytes: bytes, mime_type: str
    ) -> str:
        """Transcribe audio bytes using Deepgram Nova-2."""
        headers = {
            "Authorization": f"Token {self._api_key}",
            "Content-Type": mime_type,
        }
        params = {
            "model": "nova-2",
            "smart_format": "true",
            "punctuate": "true",
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self._base_url,
                headers=headers,
                params=params,
                content=audio_bytes,
                timeout=self._timeout,
            )
            response.raise_for_status()
            data = response.json()
            transcript = (
                data["results"]["channels"][0]["alternatives"][0]["transcript"]
            )
            if not transcript or not transcript.strip():
                raise EmptyTranscriptError()
            return transcript
```

#### Backend: Turn Route Pattern

```python
# services/api/src/api/routes/turn.py
from fastapi import APIRouter, Depends, File, Form, UploadFile, Header
from src.api.models import TurnResponseData, ApiEnvelope
from src.api.dependencies import RequestContext, get_request_context

router = APIRouter(tags=["Turn Management"])

@router.post(
    "",
    response_model=ApiEnvelope[TurnResponseData],
    status_code=200,
    summary="Submit a turn (audio answer)",
)
async def submit_turn(
    audio: UploadFile = File(..., description="Recorded audio file"),
    session_id: str = Form(..., description="Active session ID"),
    authorization: str = Header(..., alias="Authorization"),
    ctx: RequestContext = Depends(get_request_context),
    # ... injected dependencies
) -> ApiEnvelope[TurnResponseData]:
    # 1. Extract and verify Bearer token
    # 2. Validate session exists + is active
    # 3. Validate audio file
    # 4. Read audio bytes
    # 5. Call orchestrator.process_turn()
    # 6. Return envelope with transcript + timings
    ...
```

#### Mobile: postMultipart Pattern

```dart
// ApiClient.postMultipart() addition
Future<ApiEnvelope<T>> postMultipart<T>(
  String path, {
  required String filePath,
  required String fileFieldName,
  required Map<String, String> fields,
  required T Function(Map<String, dynamic>) fromJson,
  String? bearerToken,
}) async {
  final formData = FormData.fromMap({
    fileFieldName: await MultipartFile.fromFile(filePath),
    ...fields,
  });

  try {
    final response = await _dio.post<dynamic>(
      path,
      data: formData,
      options: Options(
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    // ... parse envelope same as post()
  } on DioException catch (e) {
    throw _mapDioException(e);
  }
}
```

#### Mobile: TurnResponseData Model Pattern

```dart
// lib/core/models/turn_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'turn_models.g.dart';

@JsonSerializable()
class TurnResponseData {
  const TurnResponseData({
    required this.transcript,
    this.assistantText,
    this.ttsAudioUrl,
    required this.timings,
  });

  factory TurnResponseData.fromJson(Map<String, dynamic> json) =>
      _$TurnResponseDataFromJson(json);

  final String transcript;

  @JsonKey(name: 'assistant_text')
  final String? assistantText;

  @JsonKey(name: 'tts_audio_url')
  final String? ttsAudioUrl;

  final Map<String, double> timings;

  Map<String, dynamic> toJson() => _$TurnResponseDataToJson(this);
}
```

#### State Machine Transitions (CRITICAL — DO NOT BREAK)

The existing state machine must remain intact:

```
Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready (+ Error)
```

**This story implements the `Uploading → Transcribing → Thinking` transitions with real data.** The transitions from Uploading onward were already defined in Story 2.1; this story wires them to actual backend calls.

- `stopRecording()` → emits `InterviewUploading` with `audioPath` (existing from 2.2)
- New: `submitTurn()` → called when entering `Uploading` state
  - Emits `InterviewTranscribing` when upload is accepted
  - Emits `InterviewThinking` with `transcript` when STT completes
  - Emits `InterviewError` on any failure
- `InterviewThinking.transcript` already exists as a field
- For this story, the flow STOPS at `InterviewThinking` — LLM response (Story 2.5) and Speaking (Epic 3) are not yet wired

#### InterviewCubit.submitTurn Pattern (MANDATORY)

```dart
/// Submit the recorded audio to the backend for transcription.
/// Called automatically when state enters Uploading.
Future<void> submitTurn() async {
  final current = state;
  if (current is! InterviewUploading) {
    _logInvalidTransition('submitTurn', current);
    return;
  }
  try {
    // Transition to Transcribing as upload begins processing
    emit(InterviewTranscribing(
      questionNumber: current.questionNumber,
      questionText: current.questionText,
      startTime: DateTime.now(),
    ));

    final result = await _turnRemoteDataSource.submitTurn(
      audioPath: current.audioPath,
      sessionId: _sessionId,
      sessionToken: _sessionToken,
    );

    // Transition to Thinking with transcript
    emit(InterviewThinking(
      questionNumber: current.questionNumber,
      questionText: current.questionText,
      transcript: result.transcript,
      startTime: DateTime.now(),
    ));

    _logTransition('Thinking (transcript received)');
  } on NetworkException catch (e) {
    handleError(NetworkFailure(
      message: e.message,
      requestId: e.requestId,
    ));
  } on ServerException catch (e) {
    handleError(ServerFailure(
      message: e.message,
      requestId: e.requestId,
      stage: e.stage,
      retryable: e.retryable ?? false,
    ));
  } on Exception catch (e) {
    handleError(UnknownFailure(message: 'Upload failed: $e'));
  }
}
```

### UX Compliance (MUST FOLLOW)

#### Transcript Display (from ux-design-specification.md)

- **"Voice-first, not voice-only"** — transcript shown as readable text
- **Turn Card anatomy:** Question header + Transcript preview block ("You said…") + AI response text block (not shown yet in this story)
- **Transcript available triggers:** `Transcribing → Thinking` (and transcript preview is visible)
- **Transcript purpose:** builds trust — user can see "what the app heard"

#### Stage Stepper During Upload Flow

- Uploading: show "Uploading…" with progress indicator
- Transcribing: show "Transcribing…" with stage highlight
- Thinking: show "Thinking…" with transcript visible below
- Use existing Voice Pipeline Stepper component from Story 2.1

#### Stage Timeouts (from UX spec)

- Uploading timeout: 30s
- Transcribing timeout: 30s (STT timeout on backend side)
- For this story, implement backend-side timeouts; frontend timeout display is Story 2.6

#### Error UX

- Use existing `ErrorRecoverySheet` / error state display from Story 2.1
- Show stage name in error: "Upload failed" or "Transcription failed"
- Show request_id (copyable) for debugging
- Offer Retry (re-submit same audio) and Cancel (return to Ready)

### Previous Story Intelligence

#### Key Learnings from Story 2.2

1. **InterviewCubit now requires `RecordingService`** via constructor injection. Adding `TurnRemoteDataSource` is another required parameter — update all call sites.
2. **`stopRecording()` returns `audioPath` internally** and emits `InterviewUploading`. This story extends from that point.
3. **Test Pattern:** Use `bloc_test` + `mocktail` for cubit tests. Use `pumpApp` helper for widget tests.
4. **Audio file cleanup was deferred** from Story 2.2 Task 6. This story should implement cleanup after successful upload.
5. **Constructor breaking changes propagate widely** — `InterviewPage`, all test files need updating when adding new deps.
6. **`InterviewUploading` already has `audioPath` and `startTime` fields** — use these for upload.

#### Files from Story 2.2 to Reference

- `lib/features/interview/presentation/cubit/interview_cubit.dart` — **MODIFY**: add submitTurn(), inject TurnRemoteDataSource
- `lib/features/interview/presentation/cubit/interview_state.dart` — **DO NOT MODIFY** (all states already defined with correct fields)
- `lib/features/interview/presentation/view/interview_view.dart` — **MODIFY**: show transcript, trigger submitTurn
- `lib/features/interview/presentation/view/interview_page.dart` — **MODIFY**: provide TurnRemoteDataSource to InterviewCubit
- `lib/features/interview/domain/failures.dart` — **MODIFY**: add UploadFailure

### Technical Requirements

#### Dependencies — Backend

| Package            | Version | Purpose                    | Notes                                                   |
| ------------------ | ------- | -------------------------- | ------------------------------------------------------- |
| `fastapi`          | 0.128.0 | Web framework              | Already installed                                       |
| `python-multipart` | 0.0.20  | Multipart form parsing     | Already installed — required for `UploadFile`           |
| `httpx`            | 0.28.1  | HTTP client for Deepgram   | Already installed (for testing). Used in production too |
| `pydantic`         | 2.12.5  | Data validation            | Already installed                                       |
| `itsdangerous`     | 2.2.0   | Session token verification | Already installed                                       |

#### Dependencies — Mobile

| Package             | Version | Purpose            | Notes                                                |
| ------------------- | ------- | ------------------ | ---------------------------------------------------- |
| `dio`               | ^5.x    | HTTP client        | Already installed. Supports multipart via `FormData` |
| `json_annotation`   | ^4.x    | JSON serialization | Already installed. Used for `@JsonKey` annotations   |
| `build_runner`      | ^2.x    | Code generation    | Already installed as dev dependency                  |
| `json_serializable` | ^6.x    | Code generation    | Already installed as dev dependency                  |
| `flutter_bloc`      | ^9.1.1  | State management   | Already installed                                    |
| `mocktail`          | ^1.0.4  | Test mocking       | Already installed                                    |
| `bloc_test`         | ^10.0.0 | Cubit testing      | Already installed                                    |

No new dependencies needed for either backend or mobile.

#### Environment Variables (Backend)

```bash
# Add to .env and .env.example
DEEPGRAM_API_KEY=your_deepgram_api_key_here  # REQUIRED for STT
STT_TIMEOUT_SECONDS=30                        # Optional, default 30
```

### Testing Requirements

#### Backend Unit Tests

- **Turn Route Tests:** Validate multipart upload parsing, token verification, session validation, audio validation, response envelope format, error responses
- **STT Provider Tests:** Mock Deepgram HTTP calls, test transcript extraction, timeout handling, error mapping
- **Orchestrator Tests:** Mock STT provider, test pipeline flow, timing capture, session state updates

#### Mobile Unit Tests

- **ApiClient Multipart Tests:** Verify FormData construction, Bearer header, error parsing
- **TurnRemoteDataSource Tests:** Mock ApiClient, verify correct parameters
- **InterviewCubit Upload Flow Tests:** Mock TurnRemoteDataSource, test all state transitions, error handling

#### Mobile Widget Tests

- **Transcript display** in Thinking state
- **Stage labels** in Uploading, Transcribing, Thinking states
- **Error display** from upload failures

#### Anti-Patterns to Avoid

- ❌ Do NOT put Deepgram API calls directly in the route handler. Use the provider pattern.
- ❌ Do NOT skip the `ApiEnvelope` wrapper on the turn response. All JSON endpoints use the envelope.
- ❌ Do NOT hardcode the Deepgram API key. Use environment variables via `Settings`.
- ❌ Do NOT add new `InterviewState` variants. All needed states already exist from Story 2.1.
- ❌ Do NOT use `camelCase` in backend JSON responses. Use `snake_case`.
- ❌ Do NOT send `session_token` as a form field. It goes in the `Authorization: Bearer` header.
- ❌ Do NOT send `session_id` in the URL path. It goes as a multipart form field.
- ❌ Do NOT skip audio file cleanup after upload — temporary files accumulate.
- ❌ Do NOT block the upload on the main thread on mobile — use async properly.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Turn Response Payload]
- [Source: _bmad-output/planning-artifacts/architecture.md#Error Object Format]
- [Source: _bmad-output/planning-artifacts/architecture.md#Validation Issues Addressed]
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Backend Project Organization]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Turn Card]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Voice Pipeline Stepper]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Stage Transition Triggers]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md#Stage Timeouts]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3]
- [Source: _bmad-output/implementation-artifacts/2-2-push-to-talk-recording-capture-android.md]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

- **Task 1**: Created `TurnResponseData` Pydantic model with `transcript`, `assistant_text`, `tts_audio_url`, and `timings` fields. Created type alias `TurnResponse = ApiEnvelope[TurnResponseData]`. Exported from models package. All 5 unit tests pass.
- **Task 2**: Created `DeepgramSTTProvider` with `transcribe_audio()` method using httpx client. Implemented error classes for auth, bad request, provider error, timeout, and empty transcript. Added `DEEPGRAM_API_KEY` and `STT_TIMEOUT_SECONDS` to Settings. All 7 unit tests pass.
- **Task 3**: Created turn orchestrator with `process_turn()` function and `TurnResult` dataclass. Captures STT and total timings using `time.perf_counter()`. Updates session state (turn_count, last_activity_at). Wraps STT errors into `TurnProcessingError`. All 7 unit tests pass.
- **Task 4**: Created `POST /turn` route with multipart upload support. Validates Bearer token, session ID, and audio file. Calls orchestrator and returns ApiEnvelope response. Handles all error cases with stage-aware errors. Registered in main.py. All 5 route tests pass. **Total backend tests: 49/49 passing.**

### Change Log

| Date | Change | Author |
| ---- | ------ | ------ |

### File List

- `services/api/src/api/models/turn_models.py` (NEW)
- `services/api/src/api/models/__init__.py` (MODIFIED)
- `services/api/tests/unit/test_turn_models.py` (NEW)
- `services/api/src/providers/stt_deepgram.py` (NEW)
- `services/api/src/providers/__init__.py` (MODIFIED)
- `services/api/tests/unit/test_stt_deepgram.py` (NEW)
- `services/api/src/settings/config.py` (MODIFIED)
- `services/api/src/services/orchestrator.py` (NEW)
- `services/api/src/services/__init__.py` (MODIFIED)
- `services/api/tests/unit/test_orchestrator.py` (NEW)
- `services/api/src/api/routes/turn.py` (NEW)
- `apps/mobile/lib/core/http/api_client.dart` (MODIFIED)
- `apps/mobile/lib/core/models/turn_models.dart` (NEW)
- `apps/mobile/lib/core/models/turn_models.g.dart` (NEW)
- `apps/mobile/lib/features/interview/data/datasources/turn_remote_data_source.dart` (NEW)
- `apps/mobile/lib/features/interview/presentation/cubit/interview_cubit.dart` (MODIFIED)
- `apps/mobile/lib/features/interview/presentation/view/interview_view.dart` (MODIFIED)
- `apps/mobile/lib/features/interview/domain/failures.dart` (MODIFIED)
- `apps/mobile/test/core/http/api_client_multipart_test.dart` (NEW)
- `apps/mobile/test/features/interview/data/datasources/turn_remote_data_source_test.dart` (NEW)
- `apps/mobile/test/features/interview/presentation/cubit/interview_cubit_test.dart` (MODIFIED)
- `apps/mobile/test/features/interview/presentation/view/interview_view_test.dart` (MODIFIED)
- `services/api/src/api/routes/__init__.py` (MODIFIED)
- `services/api/tests/unit/test_turn_route.py` (NEW)
- `services/api/src/main.py` (MODIFIED)
