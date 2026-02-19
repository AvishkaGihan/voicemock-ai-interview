"""Tests for transcript safety filter."""

from src.services.safety_filter import SafetyFilter


def test_check_transcript_detects_obvious_violations() -> None:
    """Detects profanity and explicit threats as unsafe."""
    filter_service = SafetyFilter(enabled=True)

    profanity_result = filter_service.check_transcript("This is shit")
    assert profanity_result.is_safe is False
    assert profanity_result.reason == "profanity_or_slur"

    threat_result = filter_service.check_transcript("I will kill this person")
    assert threat_result.is_safe is False
    assert threat_result.reason == "explicit_threat"


def test_check_transcript_allows_normal_interview_answers() -> None:
    """Normal interview responses should pass safety checks."""
    filter_service = SafetyFilter(enabled=True)

    result = filter_service.check_transcript(
        "I used the STAR method to explain a production incident and its impact."
    )

    assert result.is_safe is True
    assert result.reason is None


def test_check_transcript_bypasses_when_disabled() -> None:
    """Safety checks are bypassed when SAFETY_ENABLED is false."""
    filter_service = SafetyFilter(enabled=False)

    result = filter_service.check_transcript("I will kill this process")

    assert result.is_safe is True
    assert result.reason is None
