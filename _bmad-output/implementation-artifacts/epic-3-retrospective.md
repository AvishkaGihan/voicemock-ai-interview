# Retrospective: Epic 3 - Hear the Interviewer

**Status:** Completed
**Date:** 2026-02-18
**Participants:** AvishkaGihan, Bob (SM), Alice (PO), Charlie (Tech Lead), Dana (QA)

## Executive Summary
Epic 3 successfully delivered the core "Voice Output" experience, enabling the interviewer to speak back to the user and providing playback controls. The system is now a full two-way voice loop. The architecture held up well, with the decoupling of TTS generation and serving being a key win.

## 🏆 Successes (What went well)
*   **Architecture & Separation of Concerns:** The decision to separate `DeepgramTTSProvider` (generation) from `TTSCache` (serving) and the `GET /tts/{id}` endpoint proved robust. It allows for efficient caching and secure audio delivery.
*   **Robust State Management:** The `InterviewCubit` successfully manages complex playback states (`Speaking`, `isPaused`, `isResumed`) without leaking logic to the UI. The "no-overlap" rule successfully prevents race conditions.
*   **User Experience:** The addition of the "Speaking" state visual cues and playback controls (Pause/Resume/Replay) significantly improved the user's sense of control and system transparency.
*   **Quality Assurance:** Test coverage is high, and edge cases like "spamming pause/resume" were handled gracefully.

## ⚠️ Challenges (What was hard)
*   **Authentication Headers:** Discovering that the audio player required explicit `Bearer` token headers (Story 3.3) was a critical integration detail that wasn't initially obvious.
*   **State Preservation on Replay:** Implementing "Replay" required careful tracking of `lastTtsAudioUrl` to avoid invalid state transitions or re-fetching expired URLs.

## 📉 Missed Opportunities / Lessons Learned
*   **Error UX:** We established a good pattern for differentiating "turn failures" from "playback failures," but we could still improve the "graceful degradation" (e.g., falling back to text-only if audio fails) in future iterations.

## ⏭️ Action Items for Epic 4 (Coaching Feedback)
| Action | Owner | Type | Priority |
| :--- | :--- | :--- | :--- |
| **Finalize LLM Prompt for Rubric** | Charlie | Technical | High |
| **Implement `/session/end` Endpoint** | Backend | Technical | High |
| **Design "Session Summary" UI** | Alice/Design| UX | High |
| **Define "Clarity & Relevance" Criteria** | Product | Process | Medium |

## 📊 Metrics & Readiness
*   **Story Completion:** 100% (4/4)
*   **Test Coverage:** High (Unit + Widget tests for all new features)
*   **Stability:** Stable (No known blocking bugs)
