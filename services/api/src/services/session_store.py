"""In-memory session storage service."""

import uuid
from datetime import datetime, timedelta, timezone
from threading import Lock
from typing import Optional

from src.api.models.session_models import SessionStartRequest
from src.domain.session_state import SessionState


class SessionStore:
    """Thread-safe in-memory session storage with TTL management."""

    def __init__(self, ttl_minutes: int = 60):
        """
        Initialize the session store.

        Args:
            ttl_minutes: Time-to-live for sessions in minutes (default: 60)
        """
        self._sessions: dict[str, SessionState] = {}
        self._lock = Lock()
        self._ttl_minutes = ttl_minutes

    def create_session(self, request: SessionStartRequest) -> SessionState:
        """
        Create a new session from a session start request.

        Args:
            request: The validated session start request

        Returns:
            A newly created SessionState (copy)
        """
        now = datetime.now(timezone.utc)
        session_id = str(uuid.uuid4())

        session = SessionState(
            session_id=session_id,
            role=request.role,
            interview_type=request.interview_type,
            difficulty=request.difficulty,
            question_count=request.question_count,
            created_at=now,
            last_activity_at=now,
            turn_count=0,
            asked_questions=[],
            status="active",
        )

        with self._lock:
            self._sessions[session_id] = session
            # Return a copy to prevent external modification of stored state
            return self._deep_copy_session(session)

    def get_session(self, session_id: str) -> Optional[SessionState]:
        """
        Retrieve a session by ID.

        Args:
            session_id: The session identifier

        Returns:
            A copy of the SessionState if found, None otherwise
        """
        with self._lock:
            session = self._sessions.get(session_id)
            if session:
                return self._deep_copy_session(session)
            return None

    def update_session(self, session_id: str, **updates) -> Optional[SessionState]:
        """
        Update a session with new field values.

        Args:
            session_id: The session identifier
            **updates: Field names and values to update

        Returns:
            A copy of the updated SessionState if found, None otherwise
        """
        with self._lock:
            session = self._sessions.get(session_id)
            if not session:
                return None

            # Update last_activity_at automatically unless explicitly provided
            if "last_activity_at" not in updates:
                updates["last_activity_at"] = datetime.now(timezone.utc)

            # Apply updates
            for key, value in updates.items():
                if hasattr(session, key):
                    setattr(session, key, value)

            return self._deep_copy_session(session)

    def delete_session(self, session_id: str) -> bool:
        """
        Delete a session by ID.

        Args:
            session_id: The session identifier

        Returns:
            True if session was deleted, False if not found
        """
        with self._lock:
            if session_id in self._sessions:
                del self._sessions[session_id]
                return True
            return False

    def cleanup_expired_sessions(self) -> int:
        """
        Remove sessions that have exceeded their TTL.

        Returns:
            Number of sessions cleaned up
        """
        now = datetime.now(timezone.utc)
        cutoff_time = now - timedelta(minutes=self._ttl_minutes)

        with self._lock:
            # Create list of expired IDs first to avoid modifying dict while iterating
            expired_ids = [
                session_id
                for session_id, session in self._sessions.items()
                if session.last_activity_at < cutoff_time
            ]

            for session_id in expired_ids:
                del self._sessions[session_id]

        return len(expired_ids)

    def _deep_copy_session(self, session: SessionState) -> SessionState:
        """Create a deep copy of a session state object."""
        # Manual deep copy is often faster/cleaner for known structures than copy.deepcopy
        return SessionState(
            session_id=session.session_id,
            role=session.role,
            interview_type=session.interview_type,
            difficulty=session.difficulty,
            question_count=session.question_count,
            created_at=session.created_at,
            last_activity_at=session.last_activity_at,
            turn_count=session.turn_count,
            # Create a new list copy
            asked_questions=list(session.asked_questions),
            status=session.status,
        )
