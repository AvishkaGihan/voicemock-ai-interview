"""Session state domain model."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Literal


SessionStatus = Literal["active", "completed", "expired"]


@dataclass
class SessionState:
    """Domain model representing interview session state."""

    session_id: str
    role: str
    interview_type: str
    difficulty: Literal["easy", "medium", "hard"]
    question_count: int
    created_at: datetime
    last_activity_at: datetime
    turn_count: int = 0
    asked_questions: list[str] = field(default_factory=list)
    status: SessionStatus = "active"
