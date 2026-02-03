"""Stage definitions for interview session lifecycle."""

from enum import Enum


class Stage(str, Enum):
    """Interview session stage identifier for error context."""

    UNKNOWN = "unknown"
    SESSION_START = "session_start"
    TURN_SUBMIT = "turn_submit"
    TTS_FETCH = "tts_fetch"
    SESSION_END = "session_end"
