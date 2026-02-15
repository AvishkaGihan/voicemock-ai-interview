"""Session start route - POST /session/start endpoint."""

from fastapi import APIRouter, Depends

from src.api.dependencies import RequestContext, get_request_context
from src.api.dependencies.shared_services import get_session_store, get_token_service
from src.api.models import (
    SessionStartRequest,
    SessionStartResponse,
    SessionData,
    ApiEnvelope,
)
from src.security import SessionTokenService
from src.services import SessionStore, generate_opening_prompt


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
