# PRD Brief — Portfolio Project #3: VoiceMock (AI Interview Coach)

## 1. Overview

**VoiceMock** is a voice-first mobile application that simulates a real job interview. Users choose a job role (e.g., "React Developer" or "Marketing Manager"), and the AI acts as the interviewer. The user speaks their answers, and the AI listens, evaluates the response, and asks the next relevant question—mimicking a real conversation.

**Business Value:**

* **Technical Authority:** Demonstrates mastery of **Audio Streaming**, **STT/TTS pipelines**, and **Latency management**.
* **High Market Demand:** Clients want "AI Customer Support Voice Bots" and "Language Tutors." This project is the foundational proof for those gigs.
* **"Wow" Factor:** Video demos of *talking* to an app convert clients much faster than text chat demos.

## 2. Goals & Success Criteria

* **User Goal:** Practice speaking confidence and get feedback on answers without needing a human partner.
* **Business Goal:** Create a reusable "Voice Agent" architecture for future "AI Call Center" clients.
* **Success Metrics:**
  * Voice-to-Text accuracy > 90%.
  * Interaction Latency (User stops talking -> AI starts talking) < 3 seconds.
  * Clear audio playback without UI freezing.

## 3. Users

* **Primary User:** Job seekers, students, or non-native speakers practicing English.
* **Target Client:** EdTech companies, HR platforms, or businesses automating phone support.

## 4. Functional Requirements

* **FR-1 (Setup):** User selects interview type (Behavioral, Technical) and difficulty level.
* **FR-2 (Speech Input):** App records user audio when they hold a "Talk" button (Push-to-Talk) or detects silence (VAD).
* **FR-3 (Transcription):** Convert user audio to text (STT) via API.
* **FR-4 (AI Reasoning):** LLM generates a relevant follow-up question or feedback based on the user's spoken answer.
* **FR-5 (Voice Output):** Convert AI text response to audio (TTS) and play it back automatically.
* **FR-6 (Feedback Report):** At the end of the session, provide a text summary: "Grammar: 8/10, Confidence: High."

## 5. Non-Functional Requirements

* **Latency:** Critical. The loop (Record -> Transcribe -> Think -> Speak) must feel conversational.
* **Audio Quality:** Noise cancellation (basic) on the mobile side.
* **Cost Efficiency:** Must use free-tier options for STT/TTS to keep portfolio costs zero.

## 6. High-Level User Flows

1. **Config:** User selects "Flutter Developer" interview.
2. **Introduction:** AI speaks: "Hello! Tell me about your experience with State Management."
3. **User Response:** User holds button, speaks: "I mostly use Riverpod because..." -> Releases button.
4. **Processing:** App shows "Listening..." -> "Thinking..."
5. **AI Reply:** AI speaks: "That's interesting. How does Riverpod compare to Provider in large apps?"
6. **Loop:** Continues for 5 questions.

## 7. Technical Outline

### Frontend (Mobile)

* **Framework:** Flutter (preferred for sound plugins) or React Native.
* **Audio Package:** `flutter_sound` (Flutter) or `react-native-audio-recorder-player`.
* **Permission:** Microphone access handling.

### Backend (Orchestration)

* **Framework:** Python (FastAPI). *Reason: Python has the best library support for audio processing.*
* **API Pattern:** REST (simplest) or WebSocket (advanced, for lower latency).

### AI Services (The "Voice Stack")

* **Speech-to-Text (STT):** **Deepgram** (Excellent Free Tier for developers, extremely fast) or OpenAI Whisper (via API).
* **LLM (The Brain):** **Groq** (Llama 3 models) or **Gemini Flash**. *Why: Groq is insanely fast, essential for voice apps.*
* **Text-to-Speech (TTS):** **Deepgram Aura** (Free tier included) or **Google Cloud TTS** (Free tier).

## 8. Tech Stack Summary

| Component | Tool / Technology | Purpose |
| --- | --- | --- |
| **Mobile App** | **Flutter** | UI & Audio Capture |
| **Backend** | **FastAPI (Python)** | Coordinating the AI pipeline |
| **STT (Ear)** | **Deepgram Nova-2** | Fast speech transcription |
| **LLM (Brain)** | **Groq (Llama 3)** | Instant text generation |
| **TTS (Mouth)** | **Deepgram Aura** | Fast, human-like voice generation |

## 9. Deployment & Production Notes

* **Backend Hosting:** **Render.com** (Docker container for Python).
* **Audio Formats:** Ensure mobile sends `.wav` or `.m4a` and backend can decode it.
* **Environment:** Store `DEEPGRAM_API_KEY` and `GROQ_API_KEY` securely in the backend.

## 10. Risks & Mitigations

* **Risk:** Latency is too high (awkward silence).
  * *Mitigation:* Use **Groq** (near instant) instead of GPT-4. Use "Push-to-Talk" instead of Voice Activity Detection (VAD) to simplify the logic for a portfolio project.

* **Risk:** Audio codec mismatch.
  * *Mitigation:* Test recording format on both iOS (often AAC) and Android ensuring the backend (FFmpeg) can handle it.

## 11. Estimated Build Timeline (Solo)

* **Day 1:** Mobile UI setup + Microphone permission + Recording logic.
* **Day 2:** FastAPI backend setup + Deepgram (STT) integration.
* **Day 3:** Groq (LLM) integration + Deepgram (TTS) integration.
* **Day 4:** Stitching the loop (Mobile sends Audio -> Plays returned Audio).
* **Day 5:** UI Polish (Waveform animations) and Demo recording.

## 12. Portfolio Presentation

* **GitHub Repo:** `voicemock-ai-interview`.
* **Architecture Diagram:** (TBD)
