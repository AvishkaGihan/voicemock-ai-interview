"""Tests for turn-related Pydantic models."""

import pytest
from pydantic import ValidationError

from src.api.models.turn_models import TurnResponseData


def test_turn_response_data_valid():
    """Test TurnResponseData with valid inputs."""
    data = TurnResponseData(
        transcript="I would approach this problem by breaking it down.",
        assistant_text=None,
        tts_audio_url=None,
        timings={"upload_ms": 120.5, "stt_ms": 820.3, "total_ms": 940.8},
        is_complete=False,
        question_number=1,
        total_questions=5,
    )

    assert data.transcript == "I would approach this problem by breaking it down."
    assert data.assistant_text is None
    assert data.tts_audio_url is None
    assert data.coaching_feedback is None
    assert data.timings["upload_ms"] == 120.5
    assert data.timings["stt_ms"] == 820.3
    assert data.timings["total_ms"] == 940.8
    assert data.is_complete is False
    assert data.question_number == 1
    assert data.total_questions == 5


def test_turn_response_data_with_assistant_text():
    """Test TurnResponseData with assistant_text populated."""
    data = TurnResponseData(
        transcript="My answer",
        assistant_text="That's a good start. Can you elaborate?",
        tts_audio_url=None,
        timings={"total_ms": 1500.0},
        is_complete=False,
        question_number=2,
        total_questions=5,
    )

    assert data.assistant_text == "That's a good start. Can you elaborate?"


def test_turn_response_data_with_tts_url():
    """Test TurnResponseData with tts_audio_url populated."""
    data = TurnResponseData(
        transcript="My answer",
        assistant_text="Follow-up question",
        tts_audio_url="https://api.example.com/tts/abc123",
        timings={"total_ms": 2000.0},
        is_complete=False,
        question_number=3,
        total_questions=5,
    )

    assert data.tts_audio_url == "https://api.example.com/tts/abc123"


def test_turn_response_data_missing_required_fields():
    """Test that required fields (transcript, timings) cannot be omitted."""
    with pytest.raises(ValidationError):
        TurnResponseData(
            assistant_text=None,
            tts_audio_url=None,
            timings={"total_ms": 100.0},
            # Missing transcript
        )

    with pytest.raises(ValidationError):
        TurnResponseData(
            transcript="Test transcript",
            assistant_text=None,
            tts_audio_url=None,
            # Missing timings
        )


def test_turn_response_data_json_serialization():
    """Test JSON serialization/deserialization."""
    data = TurnResponseData(
        transcript="Test",
        assistant_text="Response",
        tts_audio_url="http://example.com/audio",
        timings={"upload_ms": 100.0, "stt_ms": 500.0},
        is_complete=True,
        question_number=5,
        total_questions=5,
    )

    # Serialize to JSON
    json_data = data.model_dump()

    assert json_data["transcript"] == "Test"
    assert json_data["assistant_text"] == "Response"
    assert json_data["tts_audio_url"] == "http://example.com/audio"
    assert "coaching_feedback" in json_data
    assert json_data["coaching_feedback"] is None
    assert json_data["timings"]["upload_ms"] == 100.0
    assert json_data["is_complete"] is True
    assert json_data["question_number"] == 5
    assert json_data["total_questions"] == 5

    # Deserialize from JSON
    reconstructed = TurnResponseData(**json_data)
    assert reconstructed.transcript == data.transcript
    assert reconstructed.assistant_text == data.assistant_text
    assert reconstructed.tts_audio_url == data.tts_audio_url
    assert reconstructed.timings == data.timings
    assert reconstructed.is_complete == data.is_complete
    assert reconstructed.question_number == data.question_number
    assert reconstructed.total_questions == data.total_questions
