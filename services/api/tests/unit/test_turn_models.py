"""Tests for turn-related Pydantic models."""

import pytest
from pydantic import ValidationError

from src.api.models.turn_models import SessionSummary, TurnResponseData


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


def test_session_summary_model_valid():
    """SessionSummary accepts valid structured payload."""
    summary = SessionSummary(
        overall_assessment="You stayed concise and structured throughout the interview.",
        strengths=["Clear structure", "Relevant examples"],
        improvements=["Quantify impact more often"],
        average_scores={"clarity": 4.0, "relevance": 4.5},
    )

    assert summary.average_scores["clarity"] == 4.0


def test_session_summary_overall_assessment_word_limit():
    """overall_assessment must be <= 60 words."""
    too_long = " ".join(["word"] * 61)
    with pytest.raises(ValidationError):
        SessionSummary(
            overall_assessment=too_long,
            strengths=["Clear structure"],
            improvements=["Use metrics"],
            average_scores={},
        )


def test_turn_response_data_supports_session_summary_field():
    """TurnResponseData includes nullable session_summary."""
    data = TurnResponseData(
        transcript="Final response",
        assistant_text="Great work.",
        tts_audio_url=None,
        timings={"total_ms": 1000.0},
        is_complete=True,
        question_number=5,
        total_questions=5,
        session_summary={
            "overall_assessment": "Strong clarity and composure.",
            "strengths": ["Clear articulation"],
            "improvements": ["Add more quantified outcomes"],
            "average_scores": {"clarity": 4.2},
        },
    )

    payload = data.model_dump()
    assert payload["session_summary"] is not None
    assert payload["session_summary"]["average_scores"]["clarity"] == 4.2


# ---------------------------------------------------------------------------
# Task 5.1 / 5.2: recommended_actions field on SessionSummary
# ---------------------------------------------------------------------------


def test_session_summary_recommended_actions_valid_2_items():
    """recommended_actions accepts exactly 2 items each <= 25 words."""
    summary = SessionSummary(
        overall_assessment="Clear and structured responses throughout the session.",
        strengths=["Strong examples"],
        improvements=["Quantify impact"],
        average_scores={"clarity": 3.5},
        recommended_actions=[
            "Try structuring answers with the STAR method for clearer narratives.",
            "Practice pausing instead of using filler words when thinking.",
        ],
    )
    assert len(summary.recommended_actions) == 2


def test_session_summary_recommended_actions_valid_4_items():
    """recommended_actions accepts up to 4 items."""
    summary = SessionSummary(
        overall_assessment="Solid performance with room to grow.",
        strengths=["Clear examples"],
        improvements=["Quantify impact"],
        average_scores={},
        recommended_actions=[
            "Practice using the STAR method for a clear action-result narrative.",
            "Reduce filler words by pausing briefly before each new thought.",
            "Quantify your achievements with specific numbers or percentages.",
            "Focus on linking your past experience directly to the target role.",
        ],
    )
    assert len(summary.recommended_actions) == 4


def test_session_summary_recommended_actions_defaults_to_empty_list():
    """recommended_actions defaults to [] when omitted — backward compatibility."""
    summary = SessionSummary(
        overall_assessment="Clear and structured responses throughout the session.",
        strengths=["Strong examples"],
        improvements=["Quantify impact"],
        average_scores={"clarity": 3.5},
    )
    assert summary.recommended_actions == []


def test_session_summary_recommended_actions_allows_single_item():
    """recommended_actions accepts 1 item."""
    summary = SessionSummary(
        overall_assessment="Good interview.",
        strengths=["Strong examples"],
        improvements=["Quantify impact"],
        average_scores={},
        recommended_actions=["Only one action here is now allowed."],
    )
    assert len(summary.recommended_actions) == 1


def test_session_summary_recommended_actions_rejects_more_than_4_items():
    """recommended_actions rejects lists with 5+ items."""
    with pytest.raises(ValidationError):
        SessionSummary(
            overall_assessment="Good interview.",
            strengths=["Strong examples"],
            improvements=["Quantify impact"],
            average_scores={},
            recommended_actions=[
                "Practice using the STAR method for structured answers.",
                "Reduce filler words by pausing before each response.",
                "Try quantifying your achievements with specific metrics.",
                "Focus on connecting your experience to the role requirements.",
                "Work on keeping responses concise and well-targeted.",
            ],
        )


def test_session_summary_recommended_actions_rejects_item_over_25_words():
    """Each recommended action must be 25 words or fewer."""
    long_action = " ".join(["word"] * 26)
    with pytest.raises(ValidationError):
        SessionSummary(
            overall_assessment="Good interview.",
            strengths=["Strong examples"],
            improvements=["Quantify impact"],
            average_scores={},
            recommended_actions=[
                long_action,
                "Practice pausing before speaking instead of using filler words.",
            ],
        )


def test_session_summary_with_recommended_actions_serializes_correctly():
    """SessionSummary with recommended_actions round-trips through model_dump."""
    actions = [
        "Try structuring answers with the STAR method for clearer narratives.",
        "Practice pausing instead of using filler words when thinking.",
    ]
    summary = SessionSummary(
        overall_assessment="Clear and structured responses throughout.",
        strengths=["Strong examples"],
        improvements=["Quantify impact"],
        average_scores={"clarity": 4.0},
        recommended_actions=actions,
    )
    payload = summary.model_dump()
    assert payload["recommended_actions"] == actions
