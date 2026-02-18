"""In-memory TTS audio cache service."""

import time
from threading import Lock
from typing import Optional


class TTSCache:
    """Thread-safe in-memory cache for TTS audio bytes with TTL management.

    Stores audio bytes keyed by request_id with automatic expiration
    after a configurable TTL period.
    """

    def __init__(self, ttl_seconds: int = 300):
        """Initialize the TTS cache.

        Args:
            ttl_seconds: Time-to-live for cached audio in seconds
                (default: 300 = 5 minutes)
        """
        self._cache: dict[str, tuple[bytes, float]] = {}
        self._lock = Lock()
        self._ttl_seconds = ttl_seconds

    def store(self, request_id: str, audio_bytes: bytes) -> None:
        """Store audio bytes in the cache with a timestamp.

        Args:
            request_id: Unique request identifier (cache key)
            audio_bytes: Raw audio data to cache
        """
        timestamp = time.time()
        with self._lock:
            self._cache[request_id] = (audio_bytes, timestamp)

    def get(self, request_id: str) -> Optional[bytes]:
        """Retrieve audio bytes from the cache if not expired.

        This method performs lazy cleanup: expired entries are removed
        when accessed.

        Args:
            request_id: Unique request identifier (cache key)

        Returns:
            Audio bytes if found and not expired, None otherwise
        """
        with self._lock:
            if request_id not in self._cache:
                return None

            audio_bytes, timestamp = self._cache[request_id]
            current_time = time.time()

            # Check if entry has expired
            if current_time - timestamp > self._ttl_seconds:
                # Remove expired entry
                del self._cache[request_id]
                return None

            return audio_bytes

    def cleanup(self) -> int:
        """Remove all expired entries from the cache.

        This method can be called periodically for proactive cleanup,
        but lazy cleanup also happens automatically during get().

        Returns:
            Number of expired entries removed
        """
        current_time = time.time()
        expired_keys = []

        with self._lock:
            for request_id, (_, timestamp) in self._cache.items():
                if current_time - timestamp > self._ttl_seconds:
                    expired_keys.append(request_id)

            for key in expired_keys:
                del self._cache[key]

        return len(expired_keys)
