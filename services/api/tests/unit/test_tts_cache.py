"""Unit tests for TTS cache."""

import pytest
import time

from src.services.tts_cache import TTSCache


@pytest.fixture
def tts_cache():
    """Create a fresh TTS cache for each test."""
    return TTSCache(ttl_seconds=300)


def test_store_and_retrieve_audio_bytes(tts_cache):
    """Test that store and get work correctly."""
    request_id = "test-request-123"
    audio_bytes = b"fake_audio_data_mp3"

    tts_cache.store(request_id, audio_bytes)
    retrieved = tts_cache.get(request_id)

    assert retrieved == audio_bytes


def test_get_returns_none_for_missing_key(tts_cache):
    """Test that get returns None for non-existent request_id."""
    result = tts_cache.get("non-existent-request-id")

    assert result is None


def test_get_returns_none_for_expired_entry():
    """Test that get returns None for expired entry."""
    cache = TTSCache(ttl_seconds=1)  # 1 second TTL
    request_id = "expire-test"
    audio_bytes = b"audio_data"

    cache.store(request_id, audio_bytes)

    # Wait for entry to expire
    time.sleep(1.1)

    result = cache.get(request_id)

    assert result is None


def test_cleanup_removes_expired_entries():
    """Test that cleanup removes expired entries."""
    cache = TTSCache(ttl_seconds=1)  # 1 second TTL

    # Store multiple entries
    cache.store("request-1", b"audio1")
    cache.store("request-2", b"audio2")
    cache.store("request-3", b"audio3")

    # Wait for entries to expire
    time.sleep(1.1)

    # Add a new entry that hasn't expired
    cache.store("request-4", b"audio4")

    # Run cleanup
    removed_count = cache.cleanup()

    # Should have removed 3 expired entries
    assert removed_count == 3

    # Expired entries should be gone
    assert cache.get("request-1") is None
    assert cache.get("request-2") is None
    assert cache.get("request-3") is None

    # Non-expired entry should still exist
    assert cache.get("request-4") == b"audio4"


def test_cleanup_preserves_non_expired_entries(tts_cache):
    """Test that cleanup preserves non-expired entries."""
    # Store some entries
    tts_cache.store("request-1", b"audio1")
    tts_cache.store("request-2", b"audio2")

    # Run cleanup immediately (no entries should be expired)
    removed_count = tts_cache.cleanup()

    assert removed_count == 0

    # Entries should still exist
    assert tts_cache.get("request-1") == b"audio1"
    assert tts_cache.get("request-2") == b"audio2"


def test_store_overwrites_existing_entry(tts_cache):
    """Test that storing with the same request_id overwrites."""
    request_id = "overwrite-test"

    tts_cache.store(request_id, b"original_audio")
    tts_cache.store(request_id, b"new_audio")

    retrieved = tts_cache.get(request_id)

    assert retrieved == b"new_audio"


def test_lazy_cleanup_on_get():
    """Test that get performs lazy cleanup of expired entries."""
    cache = TTSCache(ttl_seconds=1)
    request_id = "lazy-cleanup-test"

    cache.store(request_id, b"audio")

    # Wait for expiry
    time.sleep(1.1)

    # Access the expired entry (should trigger lazy cleanup)
    result = cache.get(request_id)

    assert result is None

    # Entry should be removed from internal cache
    # (verify by checking it doesn't come back after cleanup)
    removed_count = cache.cleanup()
    assert removed_count == 0  # Already removed during get()


def test_thread_safety_basic():
    """Test basic thread safety of cache operations."""
    import threading

    cache = TTSCache(ttl_seconds=300)
    errors = []

    def store_and_retrieve(request_id, audio_bytes):
        try:
            cache.store(request_id, audio_bytes)
            retrieved = cache.get(request_id)
            assert retrieved == audio_bytes
        except Exception as e:
            errors.append(e)

    threads = []
    for i in range(10):
        thread = threading.Thread(
            target=store_and_retrieve,
            args=(f"request-{i}", f"audio-{i}".encode()),
        )
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

    assert len(errors) == 0
