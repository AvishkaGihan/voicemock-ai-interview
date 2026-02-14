"""Turn submission route - POST /turn endpoint."""

import time
from fastapi import APIRouter, Depends, File, Form, UploadFile, Header

from src.api.dependencies import RequestContext, get_request_context
from src.api.dependencies.shared_services import get_session_store, get_token_service
from src.api.models import (
    TurnResponseData,
    TurnResponse,
    ApiEnvelope,
    ApiError,
)
from src.services import process_turn, TurnProcessingError
from src.security import SessionTokenService
from src.services import SessionStore


router = APIRouter(tags=["Turn Management"])


@router.post(
    "",
    response_model=TurnResponse,
    status_code=200,
    summary="Submit a turn (audio answer)",
    description="Upload audio answer to be transcribed and processed through the interview pipeline.",
)
async def submit_turn(
    audio: UploadFile = File(..., description="Recorded audio file"),
    session_id: str = Form(..., description="Active session ID"),
    authorization: str = Header(..., alias="Authorization"),
    ctx: RequestContext = Depends(get_request_context),
    session_store: SessionStore = Depends(get_session_store),
    token_service: SessionTokenService = Depends(get_token_service),
) -> TurnResponse:
    """
    Submit a turn (audio answer) for processing.

    **Multipart Form Data:**
    - `audio`: Recorded audio file (required)
    - `session_id`: Active session ID (required)

    **Headers:**
    - `Authorization`: Bearer token for session authentication (required)

    **Response:**
    - `transcript`: Speech-to-text transcription of the answer
    - `assistant_text`: LLM-generated follow-up question or closing acknowledgment
    - `tts_audio_url`: URL for TTS audio (null in this story)
    - `timings`: Stage-wise processing timings
    - `is_complete`: Whether this was the final turn (session complete)
    - `question_number`: Current question number (1-indexed)
    - `total_questions`: Total configured questions for the session

    **Errors:**
    - 401: Invalid or expired session token
    - 403: Session ID mismatch with token
    - 404: Session not found
    - 422: Missing audio file, empty audio, or invalid audio format
    - 500: STT processing error (with stage and retryable flag)
    """
    upload_start = time.perf_counter()

    # Extract Bearer token
    if not authorization.startswith("Bearer "):
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="invalid_token",
                message_safe="Invalid authorization header format",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    token = authorization[7:]  # Remove "Bearer " prefix

    # Verify token
    token_session_id = token_service.verify_token(token)
    if token_session_id is None:
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="invalid_token",
                message_safe="Session token is invalid or expired",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    # Validate session_id matches token
    if token_session_id != session_id:
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="session_id_mismatch",
                message_safe="Session ID does not match token",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    # Validate session exists and is active
    session = session_store.get_session(session_id)
    if session is None:
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="session_not_found",
                message_safe="Session not found or expired",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    # Validate audio file
    if not audio.content_type or not audio.content_type.startswith("audio/"):
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="invalid_audio",
                message_safe="Audio file must have audio/* MIME type",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    # Read audio bytes
    audio_bytes = await audio.read()
    if len(audio_bytes) == 0:
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage="upload",
                code="invalid_audio",
                message_safe="Audio file is empty",
                retryable=False,
            ),
            request_id=ctx.request_id,
        )

    upload_end = time.perf_counter()
    upload_ms = (upload_end - upload_start) * 1000

    # Process turn through orchestrator
    try:
        result = await process_turn(
            audio_bytes,
            audio.content_type,
            session,
            role=session.role,
            interview_type=session.interview_type,
            difficulty=session.difficulty,
            asked_questions=session.asked_questions,
            question_count=session.question_count,
        )

        # Update asked_questions list
        new_asked_questions = list(session.asked_questions)
        if result.assistant_text:
            new_asked_questions.append(result.assistant_text)

        # Detect session completion
        is_complete = session.turn_count >= session.question_count
        new_status = "completed" if is_complete else session.status

        # Save session state changes
        session_store.update_session(
            session_id,
            turn_count=session.turn_count,
            last_activity_at=session.last_activity_at,
            asked_questions=new_asked_questions,
            status=new_status,
        )

        # Add upload timing to result timings
        result.timings["upload_ms"] = upload_ms

        # Build response data
        turn_data = TurnResponseData(
            transcript=result.transcript,
            assistant_text=result.assistant_text,
            tts_audio_url=result.tts_audio_url,
            timings=result.timings,
            is_complete=is_complete,
            question_number=session.turn_count,
            total_questions=session.question_count,
        )

        return ApiEnvelope(
            data=turn_data,
            error=None,
            request_id=ctx.request_id,
        )

    except TurnProcessingError as e:
        # Return stage-aware error response
        return ApiEnvelope(
            data=None,
            error=ApiError(
                stage=e.stage,
                code=e.code,
                message_safe=e.message_safe,
                retryable=e.retryable,
            ),
            request_id=ctx.request_id,
        )
