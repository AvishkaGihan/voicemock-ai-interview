# 🚀 VoiceMock AI Interview Coach
A modern voice-first mobile platform for practicing real-time interview conversations.

VoiceMock simulates a realistic interview loop: you speak your answer, the system transcribes it, evaluates your response, asks relevant follow-ups, and speaks back to you. It's designed to help job seekers, students, and language learners build speaking confidence with ultra-low latency.

---

## 📸 Project Demo

*Screenshots of the app in action:*

<!-- Add your screenshots here.
     We recommend placing your images in a `docs/assets/` folder in your repository.
     Example:
     <img src="docs/assets/dashboard.png" width="250" />
     <img src="docs/assets/recording.png" width="250" />
-->

---

## 🛠 Tech Stack

**Frontend (Mobile):** Flutter, Dart, BLoC (State Management)
**Backend (API):** Python, FastAPI, Pydantic
**AI Providers:** Groq (LLM), Deepgram (STT), External TTS Provider
**Testing:** Pytest (Backend), Flutter Test (Frontend)

---

## ✨ Features

- 🎙️ **Push-To-Talk Voice Loop**: Record answers easily with seamless audio processing.
- ⚡ **Ultra-Low Latency**: Orchestrated voice agent loops (STT → LLM → TTS) maintaining < 3.0s response times.
- 🧑‍🏫 **Dynamic Role Play**: Customize interview roles (e.g., Flutter Developer, Product Manager) and difficulty levels.
- 🧠 **Contextual AI Follow-Ups**: The interviewer reacts to your previous answers dynamically, making it a realistic conversation.
- 📊 **Coaching Summary**: Receive actionable feedback at the end of the session, scoring clarity, filler words, and structure.

---

## 🏗 Architecture / Folder Structure

The project decouples the mobile UI from the AI orchestration, ensuring a lightweight client and a scalable backend.

```text
voicemock-ai-interview/
├── apps/
│   └── mobile/          # Flutter cross-platform mobile application
├── services/
│   └── api/             # FastAPI backend orchestrator for the AI voice loop
└── docs/                # Project PRDs, epics, and architecture diagrams
```

**Architecture Pattern:**
The backend is designed as an API Orchestrator to handle provider integrations, ensuring the mobile app remains a "dumb client". Communication relies on a strict two-step turn contract (`POST /session/start` and `POST /turn`) to manage the state machine and audio artifacts safely.

---

## ⚙️ Setup Instructions

### 1. Backend (FastAPI) Setup
Navigate to the API service directory:
```bash
cd services/api
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```
Create a `.env` file based on `.env.example` and add your API keys:
```env
GROQ_API_KEY=your_key_here
DEEPGRAM_API_KEY=your_key_here
```
Run the local server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend (Flutter) Setup
Navigate to the mobile app directory:
```bash
cd apps/mobile
flutter pub get
```
Run the app on your connected device or emulator:
```bash
flutter run
```

---

## 🧪 Testing

### Backend Tests (Python)
Run unit and integration tests using pytest:
```bash
cd services/api
pytest
# For coverage: pytest --cov=src
```

### Frontend Tests (Flutter)
Run UI and BLoC tests:
```bash
cd apps/mobile
flutter test
# For coverage: flutter test --coverage
```

---

## 📖 API Documentation

The backend exposes a clean REST API. View the full OpenAPI spec by navigating to `http://localhost:8000/docs` while the server is running.

| Method | Endpoint | Description |
|---|---|---|
| POST | `/session/start` | Initializes a new interview session and returns a session token. |
| POST | `/turn` | Accepts multipart audio upload, runs the STT/LLM/TTS pipeline, and returns the next prompt and audio URL. |

---

## 🤔 Engineering Decisions

- **FastAPI for Orchestration:** Chosen for its asynchronous support to handle concurrent STT/TTS streams and LLM API calls with minimal latency.
- **Flutter for Frontend:** Maximized speed-to-demo by reaching both iOS and Android simultaneously. Excellent plugin ecosystem for audio recording (`record`) and playback (`just_audio`).
- **In-Memory Sessions (MVP):** By removing a database requirement for the MVP, the system operates with near-zero latency and avoids data privacy complexities (audio/transcripts are volatile).

---

## 🧗 Challenges & Solutions

- **Audio Overlap & State Issues:** Flutter state management could cause "double speak" if TTS fired multiple times.
  **Solution:** We implemented a strict BLoC state machine that locks the UI and cancels active playback queues when a new turn starts.
- **Latency Spikes:** Sequential API calls (STT then LLM then TTS) caused long response times.
  **Solution:** Carefully selecting high-speed providers (Groq) and establishing a "latency budget" metrics dashboard per turn.

---

## 🚀 Future Improvements

- Add **Voice Activity Detection (VAD)** to remove the push-to-talk button limitation.
- Support **Streaming STT/TTS** to give partial responses ("thinking..." fillers) while the LLM generates the final answer.
- Implement **Resume Uploads** for completely personalized question generation.

---

## 🛡️ License

This project is licensed under the terms described in the `LICENSE` file.

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## 🏆 Badges

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-80%25-yellowgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.35.0-blue?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.128.0-009688?logo=fastapi)
