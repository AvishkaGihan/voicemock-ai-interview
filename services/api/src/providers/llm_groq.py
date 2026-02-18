"""Groq LLM provider for generating interview follow-up questions."""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any

from groq import AsyncGroq
from groq import APIError
from groq import APITimeoutError
from groq import RateLimitError

from src.api.models.turn_models import CoachingFeedback


class LLMError(Exception):
    """Error during LLM processing with stage-aware details."""

    def __init__(self, message: str, code: str, retryable: bool):
        super().__init__(message)
        self.stage = "llm"
        self.code = code
        self.retryable = retryable


@dataclass(frozen=True)
class LLMResponse:
    """Structured response from LLM generation."""

    follow_up_question: str
    coaching_feedback: CoachingFeedback | None = None


# Rubric definitions for dynamic prompt generation
RUBRIC_DIMENSIONS = [
    {
        "label": "Clarity",
        "description": "Clear articulation of ideas",
    },
    {
        "label": "Relevance",
        "description": "Answer directly addresses the question and role",
    },
    {
        "label": "Structure",
        "description": "Logical flow (e.g., STAR method)",
    },
    {
        "label": "Filler Words",
        "description": "Minimal use of fillers like 'um', 'uh', 'like'",
    },
]


class GroqLLMProvider:
    """Groq-based LLM provider for interview coaching.

    Uses Groq's chat completions API to generate contextual follow-up
    questions based on the user's transcript and interview parameters.
    """

    def __init__(
        self,
        api_key: str,
        model: str = "llama-3.3-70b-versatile",
        timeout_seconds: int = 30,
        max_tokens: int = 400,
    ):
        """Initialize Groq LLM provider.

        Args:
            api_key: Groq API key
            model: Groq model to use (default: llama-3.3-70b-versatile)
            timeout_seconds: Timeout for LLM requests (default: 30s)
            max_tokens: Maximum tokens in LLM response (default: 400)
        """
        self._client = AsyncGroq(api_key=api_key, timeout=timeout_seconds)
        self._model = model
        self._max_tokens = max_tokens

    async def generate_follow_up(
        self,
        transcript: str,
        role: str,
        interview_type: str,
        difficulty: str,
        asked_questions: list[str],
        question_number: int,
        total_questions: int,
    ) -> LLMResponse:
        """Generate the next interview question based on context.

        Args:
            transcript: User's answer transcript from STT
            role: Interview role (e.g., "Software Engineer")
            interview_type: Interview type (e.g., "Behavioral", "Technical")
            difficulty: Difficulty level (e.g., "Entry", "Mid", "Senior")
            asked_questions: List of previously asked questions (to avoid repeats)
            question_number: Current question number (1-indexed)
            total_questions: Total configured questions for the session

        Returns:
            Structured response containing next question and optional coaching feedback

        Raises:
            LLMError: If LLM request fails with timeout or API error
        """
        system_prompt = self._build_system_prompt(
            role,
            interview_type,
            difficulty,
            asked_questions,
            question_number,
            total_questions,
        )

        try:
            response = await self._client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": transcript},
                ],
                max_tokens=self._max_tokens,
                temperature=0.7,
            )
            raw_content = response.choices[0].message.content
            if raw_content is None:
                raise LLMError(
                    message="LLM returned null content",
                    code="null_response",
                    retryable=False,
                )
            content = raw_content.strip()

            if not content:
                raise LLMError(
                    message="LLM returned empty response",
                    code="empty_response",
                    retryable=False,
                )

            return self._parse_llm_response(content)

        except APITimeoutError as e:
            raise LLMError(
                message=str(e),
                code="llm_timeout",
                retryable=True,
            ) from e
        except RateLimitError as e:
            raise LLMError(
                message=str(e),
                code="llm_rate_limit",
                retryable=True,
            ) from e
        except APIError as e:
            # Check if it's be content filter error
            error_msg = str(e).lower()
            if "content" in error_msg and (
                "filter" in error_msg or "policy" in error_msg
            ):
                raise LLMError(
                    message=str(e),
                    code="llm_content_filter",
                    retryable=False,
                ) from e
            # Generic provider error
            raise LLMError(
                message=str(e),
                code="llm_provider_error",
                retryable=True,
            ) from e

    def _parse_llm_response(self, content: str) -> LLMResponse:
        """Parse LLM output JSON with graceful fallback to plain text."""
        try:
            parsed = json.loads(content)
        except json.JSONDecodeError:
            return LLMResponse(follow_up_question=content, coaching_feedback=None)

        if not isinstance(parsed, dict):
            return LLMResponse(follow_up_question=content, coaching_feedback=None)

        follow_up_question = parsed.get("follow_up_question")
        if not isinstance(follow_up_question, str) or not follow_up_question.strip():
            follow_up_question = content
        else:
            follow_up_question = follow_up_question.strip()

        coaching_feedback_raw = parsed.get("coaching_feedback")
        if coaching_feedback_raw is None:
            return LLMResponse(
                follow_up_question=follow_up_question,
                coaching_feedback=None,
            )

        try:
            coaching_feedback = CoachingFeedback.model_validate(coaching_feedback_raw)
        except Exception:
            coaching_feedback = None

        return LLMResponse(
            follow_up_question=follow_up_question,
            coaching_feedback=coaching_feedback,
        )

    def _build_system_prompt(
        self,
        role: str,
        interview_type: str,
        difficulty: str,
        asked_questions: list[str],
        question_number: int,
        total_questions: int,
    ) -> str:
        """Build the system prompt for the LLM.

        Args:
            role: Interview role
            interview_type: Interview type
            difficulty: Difficulty level
            asked_questions: Previously asked questions
            question_number: Current question number (1-indexed)
            total_questions: Total questions in session

        Returns:
            System prompt string
        """
        is_last_question = question_number > total_questions

        asked_section = ""
        if asked_questions:
            asked_section = (
                "\n\nPreviously asked questions (DO NOT repeat these):\n"
                + "\n".join(f"- {q}" for q in asked_questions)
            )

        # Build rubric JSON structure explanation dynamically
        rubric_labels = ", ".join([d["label"] for d in RUBRIC_DIMENSIONS])
        rubric_json_fields = ", ".join(
            [
                f'{{"label": "{d["label"]}", "score": 1-5 integer, "tip": <=25 words}}'
                for d in RUBRIC_DIMENSIONS
            ]
        )

        schema_instruction = (
            f"Return ONLY valid JSON with this exact schema: "
            f'{{"follow_up_question": string, "coaching_feedback": {{"dimensions": '
            f'[{rubric_json_fields}], "summary_tip": <=30 words}}}}. '
            f"Use these exact rubric labels in order: {rubric_labels}."
        )

        if is_last_question:
            return (
                f"You are an interview coach conducting a {difficulty} "
                f"{interview_type} interview for the role of {role}. "
                f"This is the FINAL question (question {question_number} of "
                f"{total_questions}). The candidate just answered. "
                f"Provide a brief, positive closing acknowledgment of their answer. "
                f"Do NOT ask another question. Keep it to 1-2 sentences. "
                f"{schema_instruction}"
                f"{asked_section}"
            )
        else:
            return (
                f"You are an interview coach conducting a {difficulty} "
                f"{interview_type} interview for the role of {role}. "
                f"This is question {question_number} of {total_questions}. "
                f"Based on the candidate's answer, generate a relevant "
                f"follow-up question. The question should be natural, "
                f"conversational, and appropriate for the difficulty level. "
                f"{schema_instruction} "
                f"Keep coaching tone supportive, specific, and skimmable."
                f"{asked_section}"
            )

    async def generate_session_summary(
        self,
        turn_history: list[dict[str, Any]],
        role: str,
        interview_type: str,
        difficulty: str,
    ) -> dict[str, Any] | None:
        """Generate end-of-session summary JSON from all turn records.

        Returns None if parsing fails or model output is invalid.
        """
        average_scores = self._compute_average_scores(turn_history)
        prompt = self._build_session_summary_prompt(
            turn_history=turn_history,
            role=role,
            interview_type=interview_type,
            difficulty=difficulty,
            average_scores=average_scores,
        )

        try:
            response = await self._client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": prompt},
                    {
                        "role": "user",
                        "content": "Generate the session summary JSON now.",
                    },
                ],
                max_tokens=self._max_tokens,
                temperature=0.5,
            )
            raw_content = response.choices[0].message.content
            if raw_content is None:
                return None

            parsed = json.loads(raw_content.strip())
            if not isinstance(parsed, dict):
                return None

            parsed["average_scores"] = average_scores

            required_keys = {
                "overall_assessment",
                "strengths",
                "improvements",
                "average_scores",
            }
            if not required_keys.issubset(parsed.keys()):
                return None

            return parsed

        except Exception:
            return None

    def _build_session_summary_prompt(
        self,
        turn_history: list[dict[str, Any]],
        role: str,
        interview_type: str,
        difficulty: str,
        average_scores: dict[str, float],
    ) -> str:
        rubric_labels = ", ".join([d["label"] for d in RUBRIC_DIMENSIONS])

        return (
            f"You are an interview coach summarizing a completed {difficulty} "
            f"{interview_type} interview for role {role}. "
            "Return ONLY valid JSON with this exact schema: "
            '{"overall_assessment": string <=60 words, '
            '"strengths": array of 1-3 strings each <=20 words, '
            '"improvements": array of 1-3 strings each <=20 words, '
            '"average_scores": object}. '
            f"Rubric dimensions are: {rubric_labels}. "
            "Use supportive coaching tone. Do not include markdown. "
            "Use this deterministic average_scores exactly as provided without "
            f"changes: {json.dumps(average_scores)}. "
            f"Turn history JSON: {json.dumps(turn_history)}"
        )

    def _compute_average_scores(
        self,
        turn_history: list[dict[str, Any]],
    ) -> dict[str, float]:
        score_totals: dict[str, int] = {}
        score_counts: dict[str, int] = {}

        for turn in turn_history:
            coaching_feedback = turn.get("coaching_feedback")
            if not isinstance(coaching_feedback, dict):
                continue

            dimensions = coaching_feedback.get("dimensions")
            if not isinstance(dimensions, list):
                continue

            for dimension in dimensions:
                if not isinstance(dimension, dict):
                    continue

                label = dimension.get("label")
                score = dimension.get("score")
                if not isinstance(label, str):
                    continue
                if not isinstance(score, (int, float)):
                    continue

                normalized_label = label.strip().lower().replace(" ", "_")
                score_totals[normalized_label] = score_totals.get(
                    normalized_label, 0
                ) + int(score)
                score_counts[normalized_label] = (
                    score_counts.get(normalized_label, 0) + 1
                )

        if not score_totals:
            return {}

        return {
            label: round(score_totals[label] / score_counts[label], 2)
            for label in score_totals
        }
