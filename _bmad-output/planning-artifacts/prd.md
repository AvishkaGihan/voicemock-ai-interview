---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-e-01-discovery
  - step-e-02-review
  - step-e-03-edit
inputDocuments:
  - docs/voicemock-prd-brief.md
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
classification:
  projectType: mobile_app
  domain: edtech
  complexity: medium
  projectContext: greenfield
workflowType: prd
workflow: edit
lastEdited: 2026-01-27
editHistory:
  - date: 2026-01-27
    changes: Renumbered NFRs to NFR1–NFR13 aligned with epics; tightened all NFRs with measurable thresholds (latency, reliability, audio, security, retention/logging, accessibility, OS targets, cost controls).
project:
  name: voicemock-ai-interview
  title: VoiceMock (AI Interview Coach)
meta:
  author: AvishkaGihan
  date: 2026-01-27
  communicationLanguage: English
  documentOutputLanguage: English
  userSkillLevel: intermediate
---

# Product Requirements Document — VoiceMock (AI Interview Coach)

**Author:** AvishkaGihan  
**Date:** 2026-01-27

## Executive Summary

VoiceMock is a voice-first mobile interview coach that simulates a real interview conversation: the user speaks answers, the system transcribes, evaluates, asks relevant follow-up questions, and replies using voice.

**Primary users:** job seekers, students, and non-native speakers practicing spoken English interviews.

**Target buyers (future):** EdTech companies, HR platforms, and teams building voice agents who want a reusable voice-interview loop.

**Portfolio value:** demonstrates a production-style voice agent loop (audio capture → STT → LLM → TTS) with careful latency management, robust state handling, and observable stage timings.

**MVP in one sentence:** complete a 5-question push-to-talk interview session with spoken responses and an end-of-session coaching summary.

## Success Criteria

### User Success

- Complete a realistic voice interview session (default: 5 questions) end-to-end without confusion.
- Receive clear, actionable feedback after each answer and a session summary at the end.
- Feel an improvement in speaking confidence over repeated sessions (measured via quick self-rating).

### Business Success

- Produce a portfolio-quality demo (screen recording + clear voice interaction) suitable for client acquisition.
- Reusable “Voice Agent” backend architecture that can be adapted to adjacent gigs (voice tutor, customer support bot).
- Keep portfolio operating costs near-zero by defaulting to free tiers and minimizing unnecessary token/audio usage.

### Technical Success

- Voice loop responsiveness: end-of-user-speech → start-of-system-speech ≤ 3.0s for P50 and P95 (measured via in-app timing instrumentation).
- Transcription quality: > 90% word accuracy on quiet environments for standard accents; graceful degradation with noisy inputs.
- Stability: no UI freezing during recording/playback; crash-free session rate > 99% in local testing.
- Audio playback clarity: no clipping, no overlapping TTS playback, and consistent volume normalization.

### Measurable Outcomes

- Session completion rate: ≥ 80% of started sessions reach the final summary.
- Latency breakdown (P50/P95): STT/LLM/TTS timings captured per turn; total end-of-user-speech → start-of-system-speech ≤ 3.0s for both P50 and P95 under defined baseline conditions.
- App performance: UI thread remains responsive during record/transmit/playback (no dropped frames noticeable to user).
- Cost target (portfolio mode): ≤ $0.10 per full 5-question session on paid tiers; $0 on free tier when within limits.

## Product Scope

### MVP - Minimum Viable Product

- Cross-platform mobile app (Flutter preferred) with microphone permission flow.
- Interview configuration: role (preset list), interview type (Behavioral/Technical), difficulty (Easy/Medium/Hard).
- Push-to-talk recording (hold to record, release to send).
- Backend orchestration (FastAPI) that runs the pipeline: STT → LLM → TTS.
- Clear state UI: Recording → Uploading → Transcribing → Thinking → Speaking.
- End-of-session feedback report: grammar/clarity, confidence, structure, filler words (basic rubric).
- Basic observability: request IDs, timing metrics per stage, and error messages suitable for demo troubleshooting.

### Growth Features (Post-MVP)

- Voice Activity Detection (VAD) to remove push-to-talk friction.
- Streaming / partial results (progressive STT + “thinking” partial TTS) to reduce perceived latency.
- Role packs (e.g., React, Flutter, Product Manager, Sales) with curated question banks and rubrics.
- Resume/context upload to tailor interview questions.
- Session history, trend charts, and “replay your answer” audio clips.
- Shareable summary (PDF/Link) to show progress.

### Vision (Future)

- Real-time conversational agent with barge-in (user can interrupt TTS).
- Multi-language speaking practice (accent coaching, pronunciation scoring).
- Enterprise “voice agent” SDK / template for call-center and tutoring clients.
- Human-in-the-loop review mode for coaches/interviewers.

### Explicitly Out of Scope (MVP)

- Real-time streaming STT/TTS and barge-in
- Resume upload and personalization
- Push notifications
- Advanced analytics dashboards

## User Journeys

### Journey 1 — Primary User (Happy Path): “Nadia, the anxious job seeker”

Nadia has an interview tomorrow for a junior Flutter developer role. She knows the basics, but when she speaks out loud, her answers ramble and she panics in the silence.

She opens VoiceMock on her phone, selects **Flutter Developer → Technical → Medium**, and hears a calm voice say: “Hi Nadia. Tell me about your experience with state management.” Nadia presses and holds **Talk**, answers, and releases.

The app shows **Transcribing → Thinking**, then the interviewer responds with a follow-up question that feels natural. Nadia realizes this isn’t a static question list — it reacts to what she said. After 5 questions, she gets a summary: strengths, filler words, clarity, structure, and a short set of “try this next time” suggestions.

She repeats the session once more and notices she’s calmer. The product succeeds when Nadia feels: “I can handle this.”

### Journey 2 — Primary User (Edge Case): “Ravi, noisy environment + network hiccup”

Ravi practices on the bus. He speaks, but background noise and intermittent network cause delays. On one answer, the upload fails.

VoiceMock detects the failure, shows a clear message (“Connection dropped — retrying…”) and offers actions: **Retry**, **Cancel**, or **Save and send later** (post-MVP). The app never “hangs” silently.

Ravi completes the session despite disruptions. The product succeeds when it stays trustworthy under bad conditions, not only in a quiet room.

### Journey 3 — Secondary User (Portfolio Operator / Admin): “Avishka, demo and observability”

Avishka is preparing a client demo. He needs to ensure the voice loop feels instant and that failures are diagnosable.

He runs a test session and checks a lightweight “Debug Info” panel (MVP) that lists timing for **STT / LLM / TTS** and the chosen providers. When a provider rate-limit occurs, the system logs a clear error reason with a request ID.

Avishka can confidently record a demo knowing he can explain architecture and performance decisions to clients.

### Journey 4 — Support/Troubleshooting: “Lena, investigating user issues” (post-MVP)

Lena receives a report: “The app keeps talking over itself.” She needs quick insight.

She pulls the session trace via request ID: overlapping TTS requests are identified, and the timeline shows that a second response started playback before the first finished. A fix is straightforward: enforce a single playback queue and cancel previous TTS on new turns.

This journey ensures the system is built with debuggability, not just happy-path behavior.

### Journey 5 — API Consumer: “Dev team integrating the Voice Agent” (future)

A client wants the same pipeline embedded in their own app. They use a documented API endpoint to submit audio and receive TTS audio plus metadata.

They succeed when integration is simple (clear contracts, stable formats, timing metrics, and predictable errors).

### Journey Requirements Summary

- **Onboarding & setup:** role/type/difficulty selection, permissions, and a quick “test mic” check.
- **Conversation loop UI:** explicit states (recording/uploading/transcribing/thinking/speaking) + timers.
- **Error recovery:** retries, timeouts, and user-facing messages for network/provider failures.
- **Audio experience:** push-to-talk UX, single playback queue, and cancellation rules to avoid overlapping speech.
- **Observability:** per-stage latency metrics, request IDs, and structured logs.
- **Extensibility:** provider abstraction layer (swap STT/LLM/TTS), and future API surface for integrations.

## Domain-Specific Requirements

### Compliance & Regulatory

- **Student privacy awareness:** While the app targets job seekers and adult learners, design with EdTech privacy principles in mind.
- **COPPA/FERPA posture (defensive):** Avoid targeting children; include an age gate / “not for under 13” notice and avoid collecting unnecessary personal data.
- **GDPR-style expectations:** Provide clear consent for audio processing, clear explanation of third-party processors (STT/TTS/LLM), and deletion/export expectations.

### Technical Constraints

- **Data minimization:** Store audio only when needed for debugging/session history; default to not persisting raw audio in MVP.
- **Consent & retention:** Explicitly disclose that audio is sent to STT/TTS providers; provide a “Delete session” action and a retention policy.
- **Accessibility:** Ensure the voice-first UX still works with captions/transcripts, readable states, and WCAG-minded UI patterns.

### Integration Requirements

- MVP has no external LMS integration; design the backend with clean boundaries so future LMS/HR integrations are possible.

### Risk Mitigations

- **Privacy risk:** Use encryption in transit, avoid logging raw transcripts in plaintext, and scrub PII from logs.
- **Content safety:** Add basic prompt constraints and refusal behavior for inappropriate prompts/answers.
- **User trust:** Provide transparency UI (what was heard / transcript preview) before generating feedback.

### Content Safety Policy (MVP)

- **Disallowed content:** hate/harassment, sexual content, self-harm encouragement, illegal wrongdoing, and requests to generate personal data about real people.
- **Refusal behavior:** when disallowed content is detected, the system must refuse, give a brief reason, and redirect to interview-relevant coaching.
- **User controls:** user can end session at any time; show a “Report issue” action on refusal messages (records request ID + category, not raw audio by default).

## Innovation & Novel Patterns

### Detected Innovation Areas

- **Conversational voice loop as the core UX:** The product value is created by the feeling of a “real interview,” not by a static question list.
- **Latency-first architecture:** The pipeline is designed and instrumented around turn latency (STT → LLM → TTS) to feel natural.
- **Reusable voice-agent orchestration:** The backend is intentionally structured so the same components can power other client demos (support bot, tutor).

### Market Context & Competitive Landscape

- Adjacent solutions exist (interview practice apps and chat-based coaches), but voice-first, real-time interaction is less common in portfolio projects and is highly demo-able.
- Differentiation is achieved primarily through execution quality: low perceived latency, clear UI state transitions, and actionable feedback.

### Validation Approach

- **Latency instrumentation:** Log per-stage timings and compute P50/P95 turn latency; confirm targets across Wi-Fi and cellular.
- **Usability test (lightweight):** 3–5 users run a 5-question session; collect perceived responsiveness and confidence improvement ratings.
- **Transcription spot checks:** Compare STT output to a human transcript on a small test set (quiet/noisy).

### Risk Mitigation

- If end-to-end latency is too high, prefer **push-to-talk** (already in MVP) and keep answers shorter via UI guidance.
- If TTS sounds robotic or slow, allow switching providers and provide a “text-only fallback” mode.
- If noisy environments break STT quality, provide “quiet mode” tips and basic noise-handling on-device.

## Mobile App Specific Requirements

### Project-Type Overview

- **Platform approach:** Cross-platform (Flutter) to maximize speed-to-demo and plugin maturity for audio capture.
- **Primary interaction model:** Voice-first, push-to-talk by default to keep turn-taking deterministic.

### Technical Architecture Considerations

- **Audio capture:** Record locally, then upload the clip to the backend as a single request (MVP). Design for future streaming/WebSocket.
- **State management:** Strict state machine for the voice loop to avoid “double speak” and UI freeze.
- **Background behavior:** Keep MVP sessions foreground-only; explicitly handle interruption (incoming call, app background).

### Platform Requirements

- **Supported OS (MVP):** Android 10+ and iOS 15+.
- **Device compatibility:** Works with built-in mic/speaker and common Bluetooth headsets.
- **Performance:** Must maintain responsive UI during recording and playback.

### Device Permissions

- **Microphone permission:** Required; show rationale and graceful denial handling.
- **Storage/file access:** Avoid broad storage permission; store audio in app sandbox.
- **Network:** Require network for STT/LLM/TTS; provide clear offline messaging.

### Offline Mode

- **MVP:** No offline interview generation; offline state shows “Requires internet” and blocks session start.
- **Post-MVP option:** Cache question packs and allow “record now, submit later” for transcription.

### Push Strategy

- **MVP:** No push notifications.
- **Post-MVP:** Reminders to practice, streaks, and “review your feedback” notifications.

### Store Compliance

- **Privacy policy:** Must disclose audio capture, third-party processors, retention, and deletion.
- **Permission strings:** Clear, user-friendly explanation for microphone use.
- **Content policy:** Define acceptable use; add safety controls to avoid disallowed content generation.

### Implementation Considerations

- **Audio format:** Prefer `.m4a` (AAC) or `.wav`; choose one consistent format and document it.
- **Retries/timeouts:** Implement upload timeouts and one-tap retry; never leave the user in indefinite “thinking.”
- **Interruption handling:** Pause/cancel recording on interruptions; stop TTS playback when app loses audio focus.

## Functional Requirements

### Interview Setup & Session Configuration

- FR1: User can start a new interview session.
- FR2: User can select a target job role for the interview.
- FR3: User can select an interview type (e.g., Behavioral or Technical).
- FR4: User can select an interview difficulty level.
- FR5: User can view and change selections before starting the session.

### Voice Turn-Taking & Session Loop

- FR6: System can introduce the session with an opening prompt.
- FR7: User can provide an answer to a question using voice input.
- FR8: System can produce a follow-up question based on the user’s prior answer.
- FR9: System can end a session after a configured number of questions.
- FR10: User can cancel a session in progress.

### Audio Capture & Input Handling

- FR11: User can grant or deny microphone access.
- FR12: System can explain why microphone access is needed when requesting permission.
- FR13: User can record an answer using a push-to-talk interaction.
- FR14: System can detect and handle interruptions (e.g., calls, backgrounding) during recording.
- FR15: System can prevent overlapping recording and playback states.

### Transcription & Understanding

- FR16: System can convert a recorded user answer into text.
- FR17: User can view the transcript of their most recent answer.
- FR18: User can retry an answer submission if transcription fails.

### Interview Reasoning & Coaching

- FR19: System can evaluate an answer against a coaching rubric (e.g., clarity, structure, filler words).
- FR20: System can provide feedback after an answer (either immediately or at session end).
- FR21: System can adapt question selection to match the chosen role, interview type, and difficulty.
- FR22: System can avoid repeating the same question within a session.

### Voice Output & Playback

- FR23: System can convert interview prompts and feedback into spoken audio.
- FR24: System can automatically play the spoken response to the user.
- FR25: User can control playback (pause/stop/replay) for the latest system response.
- FR26: System can ensure only one spoken response plays at a time.

### Status Visibility & Error Recovery

- FR27: System can display the current processing stage (e.g., transcribing, generating, speaking).
- FR28: When a step fails, system can surface a recoverable error state that includes (a) what failed (stage), (b) what the user can do next (Retry/Cancel), and (c) a short request ID for support/debug.
- FR29: System can offer a retry path for transient failures.

### Session Summary & Progress

- FR30: System can generate an end-of-session summary across the whole interview.
- FR31: User can view the summary after the session ends.
- FR32: System can provide recommended next actions (e.g., “try answering with STAR”).

### Safety, Privacy, and Data Controls

- FR33: System can disclose that audio/transcripts are processed by third-party AI services.
- FR34: User can delete a session’s stored artifacts (at minimum: transcript and summary).
- FR35: System can enforce basic safety constraints for inappropriate content.

### Operations & Observability (Portfolio/Admin)

- FR36: System can record basic diagnostic metadata for each session (e.g., request identifiers).
- FR37: User can view a debug/diagnostic screen suitable for demo troubleshooting.

## Non-Functional Requirements

### Performance (Conversational Latency)

- NFR1: P50 end-of-user-speech → start-of-system-speech latency ≤ 3.0s, measured on-device from push-to-talk release (or end-of-speech event) to audio playback start, over ≥ 100 turns on baseline devices.
- NFR2: P95 end-of-user-speech → start-of-system-speech latency ≤ 3.0s, measured with the same method and dataset as NFR1.
- NFR3: If any turn exceeds 3.0s, the UI must (a) continue showing a clear in-progress state and (b) offer Retry/Cancel within 1.0s of crossing the threshold; if a turn exceeds 30s total, it must transition to an explicit error state (never indefinite waiting).

### Reliability & Fault Tolerance

- NFR4: During recording/uploading/playback, the app must remain responsive: 0 ANRs in a 20-minute endurance run on baseline devices, and no main-thread stall > 1.0s during an interview session (verified via platform performance tooling).
- NFR5: On provider/network failures (timeout, rate limit, 5xx, network drop), the system must fail gracefully: errors are stage-tagged (upload/stt/llm/tts), include a safe message, include retryable true/false, and the user must be able to recover via Retry/Re-record/Cancel without restarting (verified via fault-injection test cases).

### Audio Quality

- NFR6: Recorded audio + transcription intelligibility: STT word accuracy ≥ 90% on a fixed reference script in a quiet indoor environment, and ≥ 80% under moderate background noise (verified via periodic scripted test runs with human-verified ground truth).
- NFR7: Playback must never overlap: at most one system audio response may be audible at a time (0ms overlap), and playback must avoid clipping (peak level ≤ -1 dBFS) on baseline devices/headphones (verified via playback event tracing + audio-level checks).

### Security & Privacy

- NFR8: All audio/transcript data must be encrypted in transit using HTTPS (TLS 1.2+); plaintext HTTP is not permitted for any client↔backend or backend↔provider communication.
- NFR9: Data minimization + retention defaults must be explicit and testable: raw audio is not persisted by default; session artifacts (transcript/summary/timings) are retained only for the current session unless the user explicitly saves a session; user-initiated deletion must complete within 30s.
- NFR10: Logs/telemetry must never contain raw audio; transcript logging must be disabled by default; any debug logging must be explicitly opt-in and must redact obvious PII (verified by log scanning against an allowlist of fields).

### Accessibility

- NFR11: The experience must not be voice-only: every spoken system response must have a text equivalent visible in the UI for the same turn, and the user’s last-answer transcript must be visible before the next prompt is presented (verified via UI checks).

### Compatibility

- NFR12: MVP OS targets are locked to Android 10+ and iOS 15+ (matches Mobile App Specific Requirements), verified via smoke tests on at least one baseline device per OS family.

### Cost Efficiency (Portfolio Constraints)

- NFR13: The system must expose cost-control limits (max turns/session, max audio duration/turn, max retries, and provider usage caps); when limits are reached, the user sees a clear, recoverable message within 2.0s and the session remains usable (verified via configured-limit test cases).

