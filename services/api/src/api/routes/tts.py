"""TTS audio fetch route - GET /tts/{request_id} endpoint."""

import logging
from fastapi import APIRouter, Depends, Header, Response

from src.api.dependencies import RequestContext, get_request_context
from src.api.dependencies.shared_services import (
    get_token_service,
    get_tts_cache,
)
from src.api.models import ApiEnvelope, ApiError
from src.security import SessionTokenService
from src.services import TTSCache


router = APIRouter(tags=["TTS Audio"])
logger = logging.getLogger(__name__)


@router.get(
    "/{request_id}",
    status_code=200,
    summary="Fetch TTS audio by request ID",
    description=(
        "Retrieve cached TTS audio bytes for the specified request_id. "
        "Audio is available for a short-lived window (TTL: 5 minutes). "
        "Returns raw audio bytes on success, envelope-wrapped JSON on errors."
    ),
    responses={
        200: {
            "description": "TTS audio retrieved successfully",
            "content": {"audio/mpeg": {"example": "<binary audio data>"}},
        },
        401: {
            "description": "Invalid or missing session token",
            "content": {
                "application/json": {
                    "example": {
                        "data": None,
                        "error": {
                            "stage": "tts",
                            "code": "invalid_token",
                            "message_safe": "Session token is invalid or expired",
                            "retryable": False,
                        },
                        "request_id": "550e8400-e29b-41d4-a716-446655440000",
                    }
                }
            },
        },
        404: {
            "description": "TTS audio not found or expired",
            "content": {
                "application/json": {
                    "example": {
                        "data": None,
                        "error": {
                            "stage": "tts",
                            "code": "tts_audio_not_found",
                            "message_safe": "TTS audio not found or has expired",
                            "retryable": False,
                        },
                        "request_id": "550e8400-e29b-41d4-a716-446655440000",
                    }
                }
            },
        },
    },
)
async def fetch_tts_audio(
    request_id: str,
    authorization: str | None = Header(None, alias="Authorization"),
    ctx: RequestContext = Depends(get_request_context),
    token_service: SessionTokenService = Depends(get_token_service),
    tts_cache: TTSCache = Depends(get_tts_cache),
) -> Response:
    """
    Fetch TTS audio by request ID.

    **Path Parameters:**
    - `request_id`: Unique identifier for the TTS audio request

    **Headers:**
    - `Authorization`: Bearer token for session authentication (required)

    **Success Response (200):**
    - Returns raw audio bytes with `Content-Type: audio/mpeg`
    - Includes `X-Request-ID` header (added by middleware)

    **Error Responses:**
    - 401: Invalid or missing session token
    - 404: Audio not found or expired (TTL exceeded)

    **Notes:**
    - Audio is cached for 5 minutes after generation
    - After TTL expiration, the endpoint returns 404
    - Successful responses return raw bytes, NOT JSON envelope
    - Error responses use the standard JSON envelope format
    """
    # Check if Authorization header is missing
    if authorization is None:
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="tts",
                    code="invalid_token",
                    message_safe="Missing authorization header",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    # Extract Bearer token
    if not authorization.startswith("Bearer "):
        logger.warning(
            f"Invalid authorization header format for request_id: {request_id}"
        )
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="tts",
                    code="invalid_token",
                    message_safe="Invalid authorization header format",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    token = authorization[7:]  # Remove "Bearer " prefix

    # Verify token
    token_session_id = token_service.verify_token(token)
    if token_session_id is None:
        logger.warning(f"Invalid or expired token for TTS request_id: {request_id}")
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="tts",
                    code="invalid_token",
                    message_safe="Session token is invalid or expired",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    # Attempt to retrieve audio from cache
    audio_bytes = tts_cache.get(request_id)

    if audio_bytes is None:
        logger.warning(f"TTS audio not found or expired for request_id: {request_id}")
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="tts",
                    code="tts_audio_not_found",
                    message_safe="TTS audio not found or has expired",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=404,
            media_type="application/json",
        )

    # Success: return raw audio bytes
    logger.info(
        f"TTS audio retrieved successfully for request_id: {request_id}, "
        f"size: {len(audio_bytes)} bytes"
    )
    return Response(
        content=audio_bytes,
        media_type="audio/mpeg",
    )
