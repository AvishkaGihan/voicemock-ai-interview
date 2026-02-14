"""Groq LLM provider for generating interview follow-up questions."""

from groq import AsyncGroq
from groq import APIError
from groq import APITimeoutError


class LLMError(Exception):
    """Error during LLM processing with stage-aware details."""

    def __init__(self, message: str, code: str, retryable: bool):
        super().__init__(message)
        self.stage = "llm"
        self.code = code
        self.retryable = retryable


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
        max_tokens: int = 256,
    ):
        """Initialize Groq LLM provider.

        Args:
            api_key: Groq API key
            model: Groq model to use (default: llama-3.3-70b-versatile)
            timeout_seconds: Timeout for LLM requests (default: 30s)
            max_tokens: Maximum tokens in LLM response (default: 256)
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
    ) -> str:
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
            Next interview question text, or closing acknowledgment if last question

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

            return content

        except APITimeoutError as e:
            raise LLMError(
                message=str(e),
                code="llm_timeout",
                retryable=True,
            ) from e
        except APIError as e:
            raise LLMError(
                message=str(e),
                code="provider_error",
                retryable=True,
            ) from e

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

        if is_last_question:
            return (
                f"You are an interview coach conducting a {difficulty} "
                f"{interview_type} interview for the role of {role}. "
                f"This is the FINAL question (question {question_number} of "
                f"{total_questions}). The candidate just answered. "
                f"Provide a brief, positive closing acknowledgment of their answer. "
                f"Do NOT ask another question. Keep it to 1-2 sentences."
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
                f"Output ONLY the question text, nothing else."
                f"{asked_section}"
            )
