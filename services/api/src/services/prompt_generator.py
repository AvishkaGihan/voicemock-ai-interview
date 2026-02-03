"""Opening prompt generator for interview sessions."""

# Template-based prompts that adapt to role/type/difficulty
OPENING_PROMPTS = {
    "behavioral": "Great choice practicing behavioral questions for {role}! I'll ask you about past experiences. Take your time with each answer.",
    "technical": "Let's work through some technical scenarios for {role}. Focus on explaining your thought process clearly.",
    "system_design": "Welcome! We'll discuss system design topics relevant to {role}. Think out loud as we explore the architecture together.",
    "default": "Welcome! I'm here to help you practice for your {role} interview. Ready when you are.",
}


def generate_opening_prompt(role: str, interview_type: str, difficulty: str) -> str:
    """
    Generate a contextual opening prompt for the interview session.

    Args:
        role: The job role (e.g., "Software Engineer")
        interview_type: Type of interview (e.g., "behavioral", "technical")
        difficulty: Difficulty level (not currently used but available for future customization)

    Returns:
        A warm, professional opening prompt string
    """
    # Normalize interview type to lowercase for template matching
    interview_key = interview_type.lower()

    # Select template based on interview type, fallback to default
    template = OPENING_PROMPTS.get(interview_key, OPENING_PROMPTS["default"])

    # Format with role
    prompt = template.format(role=role)

    # Adjust based on difficulty
    if difficulty.lower() == "hard":
        prompt += " Since this is a hard interview, I'll be looking for depth and specific details."
    elif difficulty.lower() == "easy":
        prompt += " We'll start with some fundamental concepts."

    return prompt
