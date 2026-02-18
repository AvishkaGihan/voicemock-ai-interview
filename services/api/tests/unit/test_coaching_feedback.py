"""Tests for coaching feedback models and turn response serialization."""

import pytest
from pydantic import ValidationError

from src.api.models.turn_models import (
    CoachingDimension,
    CoachingFeedback,
    TurnResponseData,
)


def test_coaching_dimension_valid():
    """Validate coaching dimension accepts valid score and tip."""
    dimension = CoachingDimension(
        label="Clarity",
        score=4,
        tip="Lead with one concise point before adding details.",
    )

    assert dimension.label == "Clarity"
    assert dimension.score == 4


@pytest.mark.parametrize("score", [0, 6])
def test_coaching_dimension_score_out_of_range_invalid(score: int):
    """Validate score must be within 1-5."""
    with pytest.raises(ValidationError):
        CoachingDimension(
            label="Clarity",
            score=score,
            tip="Use concise examples.",
        )


def test_coaching_feedback_word_limits_enforced():
    """Validate tip and summary word limits are enforced."""
    with pytest.raises(ValidationError):
        CoachingDimension(
            label="Structure",
            score=3,
            tip=" ".join(["word"] * 26),
        )

    with pytest.raises(ValidationError):
        CoachingFeedback(
            dimensions=[
                CoachingDimension(
                    label="Clarity",
                    score=4,
                    tip="Use a concise opening statement.",
                )
            ],
            summary_tip=" ".join(["word"] * 31),
        )


def test_turn_response_serializes_with_and_without_coaching_feedback():
    """Validate `coaching_feedback` shape in turn response data."""
    with_feedback = TurnResponseData(
        transcript="I solved it using indexing.",
        assistant_text="What trade-offs did you consider?",
        tts_audio_url=None,
        coaching_feedback=CoachingFeedback(
            dimensions=[
                CoachingDimension(
                    label="Clarity",
                    score=4,
                    tip="Lead with your main point first.",
                ),
                CoachingDimension(
                    label="Relevance",
                    score=5,
                    tip="Tie each example to the role.",
                ),
                CoachingDimension(
                    label="Structure",
                    score=4,
                    tip="Use problem, action, result sequence.",
                ),
                CoachingDimension(
                    label="Filler Words",
                    score=3,
                    tip="Pause briefly instead of saying fillers.",
                ),
            ],
            summary_tip="Lead with one strong thesis and support it with two concrete examples.",
        ),
        timings={"stt_ms": 100.0, "llm_ms": 200.0, "total_ms": 300.0},
        is_complete=False,
        question_number=1,
        total_questions=5,
    )

    serialized = with_feedback.model_dump(mode="json")
    assert serialized["coaching_feedback"] is not None
    assert serialized["coaching_feedback"]["dimensions"][0]["label"] == "Clarity"

    without_feedback = TurnResponseData(
        transcript="I solved it using indexing.",
        assistant_text="What trade-offs did you consider?",
        tts_audio_url=None,
        coaching_feedback=None,
        timings={"stt_ms": 100.0, "llm_ms": 200.0, "total_ms": 300.0},
        is_complete=False,
        question_number=1,
        total_questions=5,
    )

    serialized_without = without_feedback.model_dump(mode="json")
    assert "coaching_feedback" in serialized_without
    assert serialized_without["coaching_feedback"] is None
