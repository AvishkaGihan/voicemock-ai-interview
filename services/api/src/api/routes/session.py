"""Session routes - /session endpoints."""

from fastapi import APIRouter, BackgroundTasks, Depends, Header, Response

from src.api.dependencies import RequestContext, get_request_context
from src.api.dependencies.shared_services import (
    get_session_store,
    get_token_service,
    get_tts_cache,
)
from src.api.models import (
    SessionStartRequest,
    SessionStartResponse,
    SessionData,
    DeleteResult,
    DeleteSessionResponse,
    ApiEnvelope,
    ApiError,
)
from src.security import SessionTokenService
from src.services import SessionStore, TTSCache, generate_opening_prompt


router = APIRouter(tags=["Session Management"])


@router.post(
    "/start",
    response_model=SessionStartResponse,
    status_code=200,
    summary="Start a new interview session",
    description="Creates a new server-authoritative interview session with TTL and returns session credentials and opening prompt.",
)
async def start_session(
    request: SessionStartRequest,
    ctx: RequestContext = Depends(get_request_context),
    session_store: SessionStore = Depends(get_session_store),
    token_service: SessionTokenService = Depends(get_token_service),
) -> SessionStartResponse:
    """
    Start a new interview session.

    **Request body:**
    - `role`: Target job role (e.g., "Software Engineer")
    - `interview_type`: Type of interview (e.g., "behavioral", "technical")
    - `difficulty`: Difficulty level ("easy", "medium", "hard")
    - `question_count`: Number of questions (default: 5, range: 1-10)

    **Response:**
    - `session_id`: Unique session identifier (UUID)
    - `session_token`: Bearer token for session authentication
    - `opening_prompt`: Welcome message for the user

    **Errors:**
    - 422: Invalid request body (missing fields, invalid difficulty, etc.)
    """
    # Create session
    session = session_store.create_session(request)

    # Generate token
    token = token_service.generate_token(session.session_id)

    # Generate opening prompt
    opening_prompt = generate_opening_prompt(
        role=request.role,
        interview_type=request.interview_type,
        difficulty=request.difficulty,
    )

    # Build response data
    session_data = SessionData(
        session_id=session.session_id,
        session_token=token,
        opening_prompt=opening_prompt,
    )

    # Return envelope response
    return ApiEnvelope(data=session_data, error=None, request_id=ctx.request_id)


@router.delete(
    "/{session_id}",
    response_model=DeleteSessionResponse,
    status_code=200,
    summary="Delete session artifacts",
    description=(
        "Deletes transcript, turn history, summary, and coaching feedback for "
        "the specified session. Also triggers TTS cache cleanup."
    ),
)
async def delete_session(
    session_id: str,
    background_tasks: BackgroundTasks,
    authorization: str | None = Header(None, alias="Authorization"),
    ctx: RequestContext = Depends(get_request_context),
    session_store: SessionStore = Depends(get_session_store),
    token_service: SessionTokenService = Depends(get_token_service),
    tts_cache: TTSCache = Depends(get_tts_cache),
) -> DeleteSessionResponse | Response:
    """Delete session artifacts for a valid session/token pair."""
    if authorization is None:
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="unknown",
                    code="invalid_token",
                    message_safe="Missing authorization header",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    if not authorization.startswith("Bearer "):
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="unknown",
                    code="invalid_token",
                    message_safe="Invalid authorization header format",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    token = authorization[7:]
    token_session_id = token_service.verify_token(token)
    if token_session_id is None or token_session_id != session_id:
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="unknown",
                    code="invalid_token",
                    message_safe="Session token is invalid or expired",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=401,
            media_type="application/json",
        )

    deleted = session_store.delete_session(session_id)
    if not deleted:
        return Response(
            content=ApiEnvelope(
                data=None,
                error=ApiError(
                    stage="unknown",
                    code="session_not_found",
                    message_safe="Session not found or already deleted.",
                    retryable=False,
                ),
                request_id=ctx.request_id,
            ).model_dump_json(),
            status_code=404,
            media_type="application/json",
        )

    background_tasks.add_task(tts_cache.cleanup)

    return ApiEnvelope(
        data=DeleteResult(deleted=True),
        error=None,
        request_id=ctx.request_id,
    )
