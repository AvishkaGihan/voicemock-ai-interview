---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# voicemock-ai-interview - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for voicemock-ai-interview, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: User can start a new interview session.
FR2: User can select a target job role for the interview.
FR3: User can select an interview type (e.g., Behavioral or Technical).
FR4: User can select an interview difficulty level.
FR5: User can view and change selections before starting the session.
FR6: System can introduce the session with an opening prompt.
FR7: User can provide an answer to a question using voice input.
FR8: System can produce a follow-up question based on the user’s prior answer.
FR9: System can end a session after a configured number of questions.
FR10: User can cancel a session in progress.
FR11: User can grant or deny microphone access.
FR12: System can explain why microphone access is needed when requesting permission.
FR13: User can record an answer using a push-to-talk interaction.
FR14: System can detect and handle interruptions (e.g., calls, backgrounding) during recording.
FR15: System can prevent overlapping recording and playback states.
FR16: System can convert a recorded user answer into text.
FR17: User can view the transcript of their most recent answer.
FR18: User can retry an answer submission if transcription fails.
FR19: System can evaluate an answer against a coaching rubric (e.g., clarity, structure, filler words).
FR20: System can provide feedback after an answer (either immediately or at session end).
FR21: System can adapt question selection to match the chosen role, interview type, and difficulty.
FR22: System can avoid repeating the same question within a session.
FR23: System can convert interview prompts and feedback into spoken audio.
FR24: System can automatically play the spoken response to the user.
FR25: User can control playback (pause/stop/replay) for the latest system response.
FR26: System can ensure only one spoken response plays at a time.
FR27: System can display the current processing stage (e.g., transcribing, generating, speaking).
FR28: When a step fails, system can surface a recoverable error state that includes (a) what failed (stage), (b) what the user can do next (Retry/Cancel), and (c) a short request ID for support/debug.
FR29: System can offer a retry path for transient failures.
FR30: System can generate an end-of-session summary across the whole interview.
FR31: User can view the summary after the session ends.
FR32: System can provide recommended next actions (e.g., “try answering with STAR”).
FR33: System can disclose that audio/transcripts are processed by third-party AI services.
FR34: User can delete a session’s stored artifacts (at minimum: transcript and summary).
FR35: System can enforce basic safety constraints for inappropriate content.
FR36: System can record basic diagnostic metadata for each session (e.g., request identifiers).
FR37: User can view a debug/diagnostic screen suitable for demo troubleshooting.

### NonFunctional Requirements

NFR1: P50 end-of-user-speech → start-of-system-speech latency ≤ 3.0s, measured on-device from push-to-talk release (or end-of-speech event) to audio playback start, over ≥ 100 turns on baseline devices.
NFR2: P95 end-of-user-speech → start-of-system-speech latency ≤ 3.0s, measured with the same method and dataset as NFR1.
NFR3: If any turn exceeds 3.0s, the UI must (a) continue showing a clear in-progress state and (b) offer Retry/Cancel within 1.0s of crossing the threshold; if a turn exceeds 30s total, it must transition to an explicit error state.
NFR4: During recording/uploading/playback, the app must remain responsive: 0 ANRs in a 20-minute endurance run on baseline devices, and no main-thread stall > 1.0s during an interview session.
NFR5: On provider/network failures (timeout, rate limit, 5xx, network drop), errors are stage-tagged (upload/stt/llm/tts), include a safe message, include retryable true/false, and allow recovery via Retry/Re-record/Cancel without restarting.
NFR6: Recorded audio + transcription intelligibility: STT word accuracy ≥ 90% on a fixed reference script in a quiet indoor environment, and ≥ 80% under moderate background noise.
NFR7: Playback must never overlap (0ms overlap) and must avoid clipping (peak level ≤ -1 dBFS) on baseline devices/headphones.
NFR8: All audio/transcript data must be encrypted in transit using HTTPS (TLS 1.2+); plaintext HTTP is not permitted.
NFR9: Raw audio is not persisted by default; session artifacts (transcript/summary/timings) are retained only for the current session unless the user explicitly saves a session; user-initiated deletion completes within 30s.
NFR10: Logs/telemetry must never contain raw audio; transcript logging is disabled by default; any debug logging is opt-in and redacts obvious PII.
NFR11: The experience must not be voice-only: every spoken system response has a text equivalent visible in the UI for the same turn, and the user’s last-answer transcript is visible before the next prompt is presented.
NFR12: MVP OS targets are locked to Android 10+ and iOS 15+.
NFR13: The system must expose cost-control limits (max turns/session, max audio duration/turn, max retries, and provider usage caps) with a clear, recoverable user-facing message when limits are reached.

### Additional Requirements

- Deterministic turn-taking state machine across the system: Ready → Recording → Uploading → Transcribing → Thinking → Speaking → Ready (+ Error).
- Strict concurrency rules: never record while speaking; never overlap TTS; single playback queue with cancel/stop behavior.
- Transcript “trust layer” after each turn: show what the app heard; support re-record/retry when needed.
- Visible stage UI with time-bound feedback: Uploading → Transcribing → Thinking → Speaking; never “stuck thinking”.
- Stage-aware error taxonomy aligned to UX, always including: { stage, code, message_safe, retryable, request_id }.
- Observability: request IDs + per-stage timings returned to the client; structured logs keyed by request ID; redaction/no raw audio logs.
- Backend MVP constraints: guest-only sessions; server-issued session token required on all turn endpoints; in-memory session store with TTL (default 60 minutes idle); single backend instance assumption.
- Turn API contract (two-step TTS): POST /session/start → {session_id, session_token}; POST /turn (multipart audio upload) → {transcript, assistant_text, request_id, timings, tts_audio_url}; GET /tts/{request_id} serves short-lived audio bytes.
- Rate limiting and abuse controls for high-cost endpoints (turn, TTS), plus payload limits and strict timeouts per pipeline stage.
- Provider abstraction to swap STT/LLM/TTS vendors and control cost/latency; default “speed stack” noted in architecture (Deepgram STT/TTS + Groq LLM).
- Data minimization and retention defaults: do not persist raw audio by default; store minimal session artifacts (transcripts, assistant text, timings, errors, summary); provide delete controls.
- Mobile foundation choices from architecture: Very Good Flutter App starter; flutter_bloc state management; go_router routing; audio stack (record + just_audio + audio_session); handle mic permissions and audio focus interruptions.
- Hosting/deployment expectations: FastAPI in Docker on Render; uvicorn binds to 0.0.0.0 and $PORT; environment-driven configuration via pydantic-settings.
- UX tone and interaction constraints: calm, anxiety-aware microcopy; single primary CTA (push-to-talk); avoid overuse of red/error styling; keep coaching feedback skimmable (1–3 prioritized tips).
- Audio implementation considerations from PRD: pick a single documented audio format (.m4a AAC or .wav); implement upload timeouts and one-tap retry; stop TTS playback when app loses audio focus.

### FR Coverage Map

### FR Coverage Map

FR1: Epic 1 - Start interview session
FR2: Epic 1 - Choose role
FR3: Epic 1 - Choose interview type
FR4: Epic 1 - Choose difficulty
FR5: Epic 1 - Review/change configuration before start
FR6: Epic 1 - System opening prompt

FR7: Epic 2 - Answer via voice
FR8: Epic 2 - Follow-up questions based on last answer
FR9: Epic 2 - End after configured number of questions
FR10: Epic 2 - Cancel session

FR11: Epic 1 - Grant/deny microphone access
FR12: Epic 1 - Explain microphone permission rationale

FR13: Epic 2 - Push-to-talk recording interaction
FR14: Epic 2 - Handle interruptions during recording
FR15: Epic 2 - Prevent overlap between recording and playback

FR16: Epic 2 - Convert recorded answer to text
FR17: Epic 2 - Show transcript of most recent answer
FR18: Epic 2 - Retry when transcription fails

FR19: Epic 4 - Evaluate answer against coaching rubric
FR20: Epic 4 - Provide feedback after answer or at session end
FR21: Epic 2 - Adapt questions based on role/type/difficulty
FR22: Epic 2 - Avoid repeating questions within a session

FR23: Epic 3 - Convert prompts/feedback to speech
FR24: Epic 3 - Auto-play spoken response
FR25: Epic 3 - Playback controls (pause/stop/replay)
FR26: Epic 3 - Enforce single spoken response at a time

FR27: Epic 2 - Display processing stage
FR28: Epic 2 - Stage-aware recoverable errors with request ID
FR29: Epic 2 - Retry transient failures

FR30: Epic 4 - Generate end-of-session summary
FR31: Epic 4 - View summary
FR32: Epic 4 - Recommend next actions

FR33: Epic 5 - Disclose third-party processing
FR34: Epic 5 - Delete session artifacts
FR35: Epic 5 - Safety constraints
FR36: Epic 5 - Record diagnostic metadata
FR37: Epic 5 - Debug/diagnostic screen

## Epic List

### Epic 1: Start & Configure an Interview Session
Users can open the app, choose role/type/difficulty, grant mic permission, and start an interview with a clear opening prompt.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR11, FR12

### Epic 2: Complete the Core Voice Turn Loop (Record → Transcribe → Next Question)
Users can answer via push-to-talk, see what was heard (transcript), re-try when needed, and progress through a multi-question interview without repeats, with clear “what’s happening” states.
**FRs covered:** FR7, FR8, FR9, FR10, FR13, FR14, FR15, FR16, FR17, FR18, FR21, FR22, FR27, FR28, FR29

### Epic 3: Hear the Interviewer (Voice Output + Playback Control)
Users can reliably listen to the interviewer’s prompts/feedback with full playback control and no overlapping audio.
**FRs covered:** FR23, FR24, FR25, FR26

### Epic 4: Get Coaching Feedback & End-of-Session Summary
Users get structured coaching feedback (rubric-based) plus an end-of-session summary and recommended next actions.
**FRs covered:** FR19, FR20, FR30, FR31, FR32

### Epic 5: Trust, Safety, Privacy & Demo Diagnostics
Users get transparency and control over their data; the system enforces safety constraints; and the “portfolio operator” can view diagnostics.
**FRs covered:** FR33, FR34, FR35, FR36, FR37

## Epic 1: Start & Configure an Interview Session

Users can open the app, choose role/type/difficulty, grant mic permission, and start an interview with a clear opening prompt (text-only in this epic).

### Story 1.1: Bootstrap projects from approved starter templates (Android-first)

As a portfolio operator,
I want to bootstrap the Android app and backend from the approved starter templates,
So that we can validate the session handshake and JSON contracts on a stable foundation.

**FRs enabled:** FR1–FR37 (foundation)

**Acceptance Criteria:**

**Given** I am starting from an empty workspace
**When** I initialize the mobile app using the approved Flutter starter (Very Good Flutter App)
**Then** the project builds and runs on Android
**And** baseline lint/test commands run successfully (where applicable)

**Given** I initialize the backend as a minimal FastAPI + Docker service
**When** I run it locally
**Then** it binds to `0.0.0.0` and `$PORT` (Render-compatible)
**And** a health endpoint is available for smoke testing

### Story 1.2: Configure interview (Android UI)

As a job seeker,
I want to configure role, interview type, and difficulty,
So that the interview matches what I’m practicing.

**Implements:** FR2, FR3, FR4, FR5

**Acceptance Criteria:**

**Given** I am on Android and I have opened the app
**When** I navigate to the interview setup screen
**Then** I can select a target role, interview type, and difficulty
**And** the screen clearly shows my current selections before starting

**Given** I have not started a session yet
**When** I change any selection
**Then** the updated selection is reflected immediately in the UI
**And** the “Start Interview” action remains available

### Story 1.3: Microphone permission request + graceful denial (Android)

As a user,
I want a clear microphone permission request with a rationale,
So that I understand why access is required and can decide confidently.

**Implements:** FR11, FR12

**Acceptance Criteria:**

**Given** I have not granted microphone permission
**When** the app requests microphone access
**Then** I see a user-friendly explanation of why the mic is needed
**And** I can choose Allow or Deny

**Given** I deny microphone permission
**When** I return to the setup screen
**Then** the app clearly indicates recording won’t work without permission
**And** I can retry the permission request from a visible action

### Story 1.4: Backend baseline + health endpoint

As a developer,
I want a minimal FastAPI backend skeleton with a health endpoint,
So that we can validate connectivity before implementing session endpoints.

**FRs enabled:** FR1 (start session), FR36 (diagnostics via request IDs)

**Acceptance Criteria:**

**Given** the backend service is running
**When** I call a health endpoint
**Then** I receive a successful response confirming the service is up

**Given** I call a health endpoint
**When** the backend is running
**Then** I receive a successful response confirming the service is up

### Story 1.5: Implement `POST /session/start` (token + in-memory session)

As a user,
I want to start a new interview session,
So that I can begin the interview loop.

**Implements:** FR1, FR6

**Acceptance Criteria:**

**Given** I provide role, interview type, difficulty, and desired question count (or accept defaults)
**When** the app calls `POST /session/start`
**Then** the backend creates a server-authoritative in-memory session with TTL
**And** the response contains a new `session_id` and `session_token`

**Given** a session is created
**When** the backend returns the response
**Then** the response also includes an opening prompt text for the session
**And** no audio is returned in this epic

### Story 1.6: Start session from Android app + show opening prompt (text-only)

As a job seeker,
I want to start an interview and see the opening prompt,
So that I know the session has started successfully.

**Implements:** FR1, FR6

**Acceptance Criteria:**

**Given** I have selected role/type/difficulty
**When** I tap “Start Interview”
**Then** the app calls `POST /session/start` and stores `session_id` + `session_token`
**And** the opening prompt text is displayed on the interview screen

**Given** the start request fails
**When** the app receives an error response
**Then** I see a clear, recoverable error message
**And** I can retry or cancel

### Story 1.7: Block starting without internet (Android-first MVP)

As a user,
I want the app to tell me when internet is required before starting,
So that I don’t get confused by failures.

**Supports:** FR1

**Acceptance Criteria:**

**Given** I have no network connectivity
**When** I attempt to start an interview
**Then** the app blocks the action with a clear “Requires internet” message
**And** the UI remains responsive

**Given** connectivity is restored
**When** I try again
**Then** session start proceeds normally

## Epic 2: Complete the Core Voice Turn Loop (Record → Transcribe → Next Question)

Users can answer via push-to-talk, see what was heard (transcript), re-try when needed, and progress through a multi-question interview without repeats, with clear “what’s happening” states.

### Story 2.1: Interview state machine (Android UI)

As a user,
I want the app to clearly show whose turn it is and what stage it’s in,
So that I’m never confused about whether I should speak or wait.

**Implements:** FR27, FR15

**Acceptance Criteria:**

**Given** I am in an active interview session
**When** I move through the interview loop
**Then** the UI reflects a single explicit state at a time (Ready/Recording/Uploading/Transcribing/Thinking/Speaking/Ready/Error)
**And** the user cannot trigger actions that violate the state (e.g., start upload while already uploading)

### Story 2.2: Push-to-talk recording capture (Android)

As a user,
I want to record my answer using push-to-talk,
So that turn-taking stays deterministic and simple.

**Implements:** FR7, FR13

**Acceptance Criteria:**

**Given** microphone permission is granted and the app is in Ready state
**When** I press and hold the Talk control
**Then** recording starts and the UI indicates “Recording”

**Given** I release the Talk control
**When** recording stops
**Then** the recorded audio clip is saved locally in app storage
**And** the app transitions to Uploading

### Story 2.3: `POST /turn` contract (multipart) + transcript response

As a user,
I want my recorded answer converted into a transcript,
So that I can verify what the app heard.

**Implements:** FR16, FR17

**Acceptance Criteria:**

**Given** I have an active session (`session_id`, `session_token`)
**When** the app uploads audio to `POST /turn` as multipart
**Then** the backend validates the token and processes the turn
**And** returns a JSON response including `transcript`, `request_id`, and `timings`

**Given** the response is returned
**When** the app receives it
**Then** the UI transitions through Transcribing/Thinking as appropriate
**And** the transcript is shown to the user when available

### Story 2.4: Transcript trust layer + re-record flow

As a user,
I want to see the transcript of my last answer and re-record if it’s wrong,
So that coaching and follow-ups are based on accurate input.

**Supports:** FR17

**Acceptance Criteria:**

**Given** a turn transcript is available
**When** the app displays “what we heard”
**Then** I can choose to accept it and continue
**And** I can choose to re-record, returning the app to Ready state for a new attempt

### Story 2.5: Question progression, avoid repeats, end/cancel

As a user,
I want the interview to progress through a configured number of questions without repeats,
So that practice feels realistic and structured.

**Implements:** FR8, FR9, FR10, FR21, FR22

**Acceptance Criteria:**

**Given** I started a session with a configured question count
**When** I complete each turn
**Then** the backend selects the next question/follow-up based on my last answer and session context
**And** the backend tracks asked questions and avoids repeating them within the session

**Given** I reach the configured number of questions
**When** the session completes
**Then** the backend marks the session complete and the app transitions to summary entry point

**Given** I want to stop early
**When** I cancel the session
**Then** the app stops the loop and returns to a safe idle state

### Story 2.6: Stage-aware recoverable errors with request IDs

As a user,
I want clear, recoverable errors that tell me what failed,
So that I can retry without anxiety and support can diagnose issues.

**Implements:** FR18, FR28, FR29

**Acceptance Criteria:**

**Given** an error occurs during Uploading/Transcribing/Thinking
**When** the backend returns an error
**Then** the response includes `error.stage`, `error.code`, `error.message_safe`, `error.retryable`, and `request_id`
**And** the app displays the stage and offers Retry/Cancel actions

**Given** transcription fails for my submitted answer
**When** the app shows the error state
**Then** I can retry the submission or re-record my answer
**And** the app does not get stuck in a non-actionable state

**Given** I tap Retry
**When** the error is retryable
**Then** the app retries the correct operation without requiring a full restart

### Story 2.7: Latency timings captured and surfaced (basic)

As a portfolio operator,
I want per-stage timing metrics for each turn,
So that I can validate latency goals and troubleshoot bottlenecks.

**Implements:** FR36, FR37

**Acceptance Criteria:**

**Given** a successful turn response
**When** the backend returns `timings`
**Then** it includes stage timings at minimum for STT/LLM/TTS (or whichever stages are executed)
**And** the app can display these timings in a basic diagnostics surface

### Story 2.8: Handle interruptions during recording (Android)

As a user,
I want recording to stop safely when the app loses audio focus,
So that I don’t end up in a broken state.

**Implements:** FR14

**Acceptance Criteria:**

**Given** I am recording
**When** an interruption occurs (call, backgrounding, audio focus loss)
**Then** recording is stopped and the UI returns to a safe Ready or Error state
**And** the user is not stuck in Recording

## Epic 3: Hear the Interviewer (Voice Output + Playback Control)

Users can reliably listen to the interviewer’s prompts/feedback with full playback control and no overlapping audio.

### Story 3.1: Generate TTS and return `tts_audio_url` in `POST /turn`

As a user,
I want the interviewer response spoken aloud,
So that the interview feels conversational.

**Implements:** FR23, FR24

**Acceptance Criteria:**

**Given** a successful `POST /turn` response
**When** TTS is generated for the assistant response
**Then** the backend caches the audio in-memory keyed by `request_id`
**And** returns a `tts_audio_url` that the client can fetch

### Story 3.2: Implement `GET /tts/{request_id}` (short-lived audio fetch)

As the mobile app,
I want to fetch TTS audio by request id,
So that playback is decoupled from the JSON response.

**Supports:** FR24

**Acceptance Criteria:**

**Given** a `tts_audio_url` is provided
**When** the app calls `GET /tts/{request_id}`
**Then** the backend returns audio bytes with an appropriate content type
**And** the audio is available only for a short-lived window in MVP

### Story 3.3: Android playback queue with no overlap

As a user,
I want the app to play exactly one response at a time,
So that I never hear overlapping speech.

**Implements:** FR26, FR15

**Acceptance Criteria:**

**Given** a TTS audio response is ready
**When** playback starts
**Then** the app enters “Speaking” state and plays the audio

**Given** another response becomes ready
**When** the app attempts to play it
**Then** the app stops/cancels the previous playback before starting the next
**And** recording is not allowed while speaking

### Story 3.4: Playback controls (pause/stop/replay)

As a user,
I want to pause, stop, or replay the last interviewer response,
So that I can listen carefully.

**Implements:** FR25

**Acceptance Criteria:**

**Given** the latest response audio is available
**When** I use pause/stop/replay controls
**Then** playback behaves as expected
**And** the UI state stays consistent with what I hear

## Epic 4: Get Coaching Feedback & End-of-Session Summary

Users get structured coaching feedback (rubric-based) plus an end-of-session summary and recommended next actions.

### Story 4.1: Coaching rubric feedback returned in turn response

As a user,
I want coaching feedback aligned to a simple rubric,
So that I can improve with actionable guidance.

**Implements:** FR19, FR20

**Acceptance Criteria:**

**Given** a turn is processed
**When** the backend generates coaching feedback
**Then** the response includes structured feedback aligned to the rubric (e.g., clarity, structure, filler words)
**And** feedback is short and skimmable by default

### Story 4.2: End-of-session summary generation and display

As a user,
I want an end-of-session summary across the whole interview,
So that I can reflect on strengths and what to improve.

**Implements:** FR30, FR31

**Acceptance Criteria:**

**Given** the session reaches the configured question count
**When** the session ends
**Then** the backend produces a summary derived from the session turns
**And** the Android app displays the summary in a dedicated view

### Story 4.3: Recommended next actions in summary

As a user,
I want recommended next actions after my session,
So that I know exactly what to practice next.

**Implements:** FR32

**Acceptance Criteria:**

**Given** a session summary is displayed
**When** recommendations are shown
**Then** I see concrete next actions (e.g., “Try STAR structure”) tied to my performance

## Epic 5: Trust, Safety, Privacy & Demo Diagnostics

Users get transparency and control over their data; the system enforces safety constraints; and the “portfolio operator” can view diagnostics.

### Story 5.1: Third-party processing disclosure

As a user,
I want to understand that my audio and transcript are processed by third-party services,
So that I can make an informed decision.

**Implements:** FR33

**Acceptance Criteria:**

**Given** I am about to start an interview
**When** I view the disclosure
**Then** the app clearly states that audio/transcripts are sent to third-party AI services
**And** it links (or references) retention and deletion behavior at a high level

### Story 5.2: Delete session artifacts

As a user,
I want to delete my session artifacts,
So that I can control my data.

**Implements:** FR34

**Acceptance Criteria:**

**Given** I have an existing session
**When** I choose “Delete session”
**Then** the backend deletes (or expires) stored artifacts at minimum for transcript and summary
**And** the app confirms deletion without exposing sensitive data

### Story 5.3: Safety constraints and refusal behavior

As a user,
I want the system to refuse inappropriate content safely,
So that the app stays focused on interview coaching.

**Implements:** FR35

**Acceptance Criteria:**

**Given** the user input or transcript contains disallowed content
**When** the backend evaluates the request
**Then** it returns a refusal response with a safe message
**And** includes a `request_id` for diagnostics

### Story 5.4: Diagnostics screen (request id + timings + last error)

As a portfolio operator,
I want a lightweight diagnostics screen,
So that I can troubleshoot and demo the system confidently.

**Implements:** FR36, FR37

**Acceptance Criteria:**

**Given** I enable or navigate to diagnostics
**When** I open the diagnostics screen
**Then** I can see recent `request_id` values, per-stage timings, and the last error (if any)
**And** it is clearly separated from the main user flow
