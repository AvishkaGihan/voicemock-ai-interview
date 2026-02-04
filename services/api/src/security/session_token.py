"""Session token service for generating and verifying session authentication tokens."""

from typing import Optional
from itsdangerous import URLSafeTimedSerializer, SignatureExpired, BadSignature


class SessionTokenService:
    """Service for generating and verifying time-limited session tokens."""

    def __init__(self, secret_key: str, max_age_seconds: int = 3600):
        """
        Initialize the token service.

        Args:
            secret_key: Secret key for signing tokens (from environment)
            max_age_seconds: Token expiry time in seconds (default: 3600 = 60 minutes)
        """
        self.serializer = URLSafeTimedSerializer(secret_key)
        self.max_age = max_age_seconds

    def generate_token(self, session_id: str) -> str:
        """
        Generate a signed token containing the session ID.

        Args:
            session_id: The session identifier to encode in the token

        Returns:
            A URL-safe signed token string
        """
        return self.serializer.dumps({"session_id": session_id})

    def verify_token(self, token: str) -> Optional[str]:
        """
        Verify a token and extract the session ID.

        Args:
            token: The token string to verify

        Returns:
            The session_id if valid, None if invalid or expired
        """
        try:
            data = self.serializer.loads(token, max_age=self.max_age)
            return data.get("session_id")
        except (SignatureExpired, BadSignature, Exception):
            return None
