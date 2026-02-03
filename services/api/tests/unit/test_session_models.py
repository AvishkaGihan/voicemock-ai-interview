
import pytest
from src.api.models.session_models import SessionStartRequest
from pydantic import ValidationError

def test_question_count_validation_limits():
    """Test that question_count obeys min/max limits."""
    # Valid count
    SessionStartRequest(
        role="Dev",
        interview_type="behavioral",
        difficulty="medium",
        question_count=5
    )

    # Too low
    with pytest.raises(ValidationError):
        SessionStartRequest(
            role="Dev",
            interview_type="behavioral",
            difficulty="medium",
            question_count=0
        )

    # Too high
    with pytest.raises(ValidationError):
        SessionStartRequest(
            role="Dev",
            interview_type="behavioral",
            difficulty="medium",
            question_count=11
        )
