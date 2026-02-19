"""Transcript safety filtering for obvious disallowed content."""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass
from pathlib import Path

from src.settings.config import get_settings

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SafetyCheckResult:
    """Result of safety validation for a transcript."""

    is_safe: bool
    reason: str | None = None


class SafetyFilter:
    """Lightweight regex-based safety filter for transcript checks."""

    _DEFAULT_PATTERNS: tuple[tuple[str, str], ...] = (
        (
            "profanity_or_slur",
            r"\b(fuck|shit|bitch|nigger|faggot)\b",
        ),
        (
            "explicit_threat",
            r"\b(i\s+will\s+(kill|hurt|harm)|i'?m\s+going\s+to\s+(kill|hurt|harm))\b",
        ),
        (
            "pii_solicitation",
            r"\b(tell\s+me\s+your\s+(ssn|social security number|home address|credit card number|password))\b",
        ),
    )

    def __init__(
        self,
        enabled: bool = True,
        patterns_file: str | None = None,
    ) -> None:
        self._enabled = enabled
        self._compiled_patterns = self._load_patterns(patterns_file)

    @classmethod
    def from_settings(cls) -> "SafetyFilter":
        """Construct filter from app settings."""
        settings = get_settings()
        return cls(
            enabled=settings.safety_enabled,
            patterns_file=settings.safety_patterns_file,
        )

    def check_transcript(self, transcript: str) -> SafetyCheckResult:
        """Check transcript for obvious disallowed content patterns."""
        if not self._enabled:
            return SafetyCheckResult(is_safe=True)

        text = transcript.strip()
        if not text:
            return SafetyCheckResult(is_safe=True)

        for reason, pattern in self._compiled_patterns:
            if pattern.search(text):
                return SafetyCheckResult(is_safe=False, reason=reason)

        return SafetyCheckResult(is_safe=True)

    def _load_patterns(
        self, patterns_file: str | None
    ) -> list[tuple[str, re.Pattern[str]]]:
        base_patterns = list(self._DEFAULT_PATTERNS)

        if patterns_file:
            loaded = self._load_patterns_from_file(patterns_file)
            if loaded:
                base_patterns = loaded

        return [
            (name, re.compile(pattern, flags=re.IGNORECASE))
            for name, pattern in base_patterns
        ]

    def _load_patterns_from_file(
        self, patterns_file: str
    ) -> list[tuple[str, str]] | None:
        path = Path(patterns_file)
        if not path.exists() or not path.is_file():
            logger.warning("Safety patterns file not found: %s", patterns_file)
            return None

        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            logger.warning(
                "Failed to parse safety patterns file %s: %s", patterns_file, exc
            )
            return None

        if not isinstance(payload, list):
            logger.warning(
                "Safety patterns file must contain a JSON array: %s", patterns_file
            )
            return None

        parsed: list[tuple[str, str]] = []
        for index, item in enumerate(payload):
            if isinstance(item, str) and item.strip():
                parsed.append((f"custom_pattern_{index}", item))
                continue

            if isinstance(item, dict):
                name = item.get("name")
                pattern = item.get("pattern")
                if (
                    isinstance(name, str)
                    and name.strip()
                    and isinstance(pattern, str)
                    and pattern.strip()
                ):
                    parsed.append((name.strip(), pattern))

        return parsed or None
