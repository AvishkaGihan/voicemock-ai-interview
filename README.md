# VoiceMock AI Interview Coach

An AI-powered voice interview coach that helps job seekers practice and improve their interviewing skills through realistic mock interviews.

## 🎯 Project Overview

VoiceMock is an **Android-first MVP** that provides:
- Voice-based mock interviews for technical roles
- Real-time speech-to-text transcription
- AI-generated interviewer responses
- Natural text-to-speech for interviewer voice
- Coaching feedback and improvement suggestions

## 🏗️ Architecture

This is a **monorepo** containing:

```
voicemock-ai-interview/
├── apps/
│   └── mobile/          # Flutter mobile app (Android-first)
├── services/
│   └── api/             # FastAPI backend service
├── contracts/           # API contracts and specifications
└── docs/                # Project documentation
```

### Tech Stack

**Mobile (Flutter)**
- Dart 3.x with Flutter 3.x
- flutter_bloc for state management
- go_router for navigation
- Very Good CLI starter template

**Backend (FastAPI)**
- Python 3.12
- FastAPI 0.128.0 + Uvicorn
- Pydantic v2 for validation
- Docker deployment on Render.com

**Third-Party Integrations** (Future)
- Deepgram for Speech-to-Text
- OpenAI for LLM responses
- ElevenLabs for Text-to-Speech

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x)
- [Python 3.12](https://www.python.org/downloads/)
- [Docker](https://www.docker.com/get-started)
- Android Studio / VS Code with Flutter extensions

### Mobile App Setup

```bash
cd apps/mobile
flutter pub get
flutter run
```

### Backend Setup

```bash
cd services/api
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn src.main:app --reload
```

### Docker

```bash
cd services/api
docker build -t voicemock-api .
docker run -p 8000:8000 -e PORT=8000 voicemock-api
```

## 📚 Documentation

- [API Error Taxonomy](docs/api/error-taxonomy.md)
- [API Contracts](contracts/)
  - [Stages](contracts/api/stages.md)
  - [Error Codes](contracts/api/codes.md)
  - [Headers](contracts/api/headers.md)
  - [Response Envelope](contracts/naming/response-envelope.md)

## 🧪 Testing

**Flutter**
```bash
cd apps/mobile
flutter test
flutter analyze
```

**Backend**
```bash
cd services/api
pytest
```

## 📦 Deployment

The backend is configured for deployment on [Render.com](https://render.com):
- Docker-based deployment
- Auto-scaling configuration
- Environment variable management

## 📄 License

*License information to be added*

## 🤝 Contributing

Please read our [Branching Strategy](docs/branching-strategy.md) before contributing.

*Additional contributing guidelines to be added*
