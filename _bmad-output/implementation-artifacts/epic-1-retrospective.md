# Epic 1 Retrospective: Start & Configure an Interview Session

**Date:** 2026-02-04
**Participants:** AvishkaGihan (Lead), Alice (PO), Bob (SM), Charlie (Dev), Dana (QA), Elena (Dev)

## 1. Summary
Epic 1 established the foundational mobile and backend "skeleton" for the VoiceMock application. We successfully delivered a functioning Android app that can handle permissions, configure an interview, and start a session against a live FastAPI backend.

- **Status:** Completed (100% Story Completion)
- **Velocity:** 7 Stories delivered with no blockers.
- **Key Win:** Achieved 100% Acceptance Criteria pass rate with zero technical debt logged.

## 2. What Went Well?
- **Architecture & Patterns:** The upfront investment in Clean Architecture (Flutter) and Response Envelopes (FastAPI) paid off significantly. Story 1.7 (Connectivity) was delivered rapidly by reusing these components.
- **Quality Assurance:** Comprehensive testing strategy (Unit + Integration + Widget tests) caught issues early. 100+ tests are passing.
- **UX/Flow:** The "Dead End UI" in permission handling was identified and fixed during Story 1.3 development, preventing a poor user experience.
- **Cross-Stack Capability:** Successfully established the network contract between Dart (Client) and Python (Server) using strict typing and interceptors.

## 3. Challenges & Learnings
- **Security Pivot:** We initially used `SharedPreferences` but had to pivot to `flutter_secure_storage` for token security in Story 1.6.
    *   *Learning:* Data sensitivity classification needs to happen earlier in the planning phase.
- **Serialization Rigor:** The mismatch between Backend (`snake_case`) and Mobile (`camelCase`) requires strict vigilance.
    *   *Risk:* As data complexity grows in Epic 2, manual mapping errors become more likely.
- **Platform Constraints:** Sticking strictly to "Android-first" meant using specific storage options (`AndroidOptions`). This is a known trade-off that may require refactoring when iOS support is added.

## 4. Action Items

### P0: Technical Risk Mitigation (Epic 2 Preparation)
These items are critical prerequisites for the success of Epic 2's voice features. They will be executed as "Research Tasks" within the first relevant stories of Epic 2.

| ID | Action Item | Owner | Context |
|----|-------------|-------|---------|
| **AI-1** | **Research Audio Library:** Evaluate `flutter_sound` vs `record` for Android support, AAC/M4A formats, and ease of use. | Charlie | **Evaluate in Story 2.2** (Recording) |
| **AI-2** | **Proof-of-Concept for Multipart Uploads:** Verify FastAPI handling of `multipart/form-data` audio uploads securely. | Elena | **Evaluate in Story 2.3** (Turn Contract) |
| **AI-3** | **Define Audio Testing Strategy:** Establish a pattern for mocking audio input in automated tests. | Dana | **Defined in Story 2.2** |

### P1: Process Improvements
- **Continue Pattern of "Build Once, Reuse Everywhere":** Maintain the discipline of abstracting core components (like the API Client and Connectivity Cubit) to keep velocity high.
- **Strict Mapping Discipline:** Continue forcing manual `toJson`/`fromJson` mapping to explicit keys to preventing serialization bugs.

## 5. Decision Log
- **Approvals:** Epic 1 is formally closed. Epic 2 is approved to start.
