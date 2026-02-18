# Epic 2 Retrospective: Complete the Core Voice Turn Loop

## Summary
Epic 2 successfully established the core "Voice Turn Loop," transforming the app from a text-only bootstrap into a functional voice-first interview coach. We implemented a robust state machine, integrated Deepgram for transcription and Groq for follow-up questions, and built a transparent error recovery system.

## Successes (What Went Well)
- **Deterministic State Machine**: The 8-state transition logic (`Ready` → `Recording` → `Uploading` → `Transcribing` → `Review` → `Thinking` → `Speaking` → `Ready`) provides a clear, reliable user journey.
- **Transcript Trust Layer**: Story 2.4's addition of the review stage significantly improved UX by allowing users to verify and "Accept" or "Re-record" their answers before the LLM processes them.
- **Stage-Aware Error Recovery**: We moved beyond generic "error" states to stage-specific recovery (e.g., retrying only the LLM call vs. re-uploading audio), reducing user frustration and backend load.
- **End-to-End Latency Instrumentation**: Every turn now captures `upload_ms`, `stt_ms`, `llm_ms`, and `total_ms`, surfaced in a hidden diagnostics surface to help hit our speed targets.
- **Audio Reliability**: Integrated `audio_session` to handle real-world interruptions like phone calls, preventing the app from getting stuck in a recording state.

## Challenges & Lessons Learned
- **Singleton Scoping (Backend)**: We encountered a critical "Session not found" bug caused by separate `SessionStore` instances in different routes. This underscored the need for explicit shared dependency injection in FastAPI.
- **Diagnostics Navigation (Flutter)**: A `ProviderNotFoundException` during diagnostics access revealed that `go_router` top-level routes lose access to the `InterviewCubit` unless explicitly passed in the `extra` parameter.
- **State Preservation**: We learned that state data (like `totalQuestions`) needs careful preservation through all transitions to avoid UI reset bugs.

## Action Item Tracking (from Epic 1)
| Action Item | Status | Result |
| :--- | :--- | :--- |
| Research Audio Library | ✅ Done | Selected `record: ^6.1.2` for its robust AAC support. |
| PoC for Multipart Upload | ✅ Done | Implemented `POST /turn` using `multipart/form-data`. |
| Audio Testing Strategy | ✅ Done | Implemented comprehensive unit/widget tests for recording and interruptions. |

## New Action Items for Epic 3
- [ ] **Research Audio Playback**: Select a library (likely `just_audio`) to handle the Speaking phase.
- [ ] **Latency Optimization**: Review LLM (Groq) and STT (Deepgram) settings to shave off ~2s of "wait time" where possible.
- [ ] **TTS Integration**: Define the contract for `GET /tts/{request_id}` and implement audio synthesis.

## Preview of Next Epic: Playback & UX Refinement
Epic 3 will focus on closing the loop with **Voice Output**. We will implement the Speaking phase (TTS), add audio replay for questions, and polish the transitions between turns to feel more conversational.
