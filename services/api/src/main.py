"""VoiceMock API - FastAPI Application Entry Point.

This module initializes the FastAPI application with:
- CORS middleware configuration
- Request ID middleware for tracing
- Exception handling middleware for envelope-wrapped errors
- Route registration
"""

import logging
import uuid
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from src.api.models import ApiEnvelope, ApiError
from src.api.routes import health

# Configure logging
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan handler for startup/shutdown events."""
    # Startup
    logger.info("VoiceMock API starting up...")
    yield
    # Shutdown
    logger.info("VoiceMock API shutting down...")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="VoiceMock AI Interview Coach API",
        description="Backend API for VoiceMock voice interview coaching application",
        version="0.1.0",
        lifespan=lifespan,
    )

    # CORS middleware - allowing all origins for development
    # TODO: [SECURITY] Restrict origins in production from ["*"] to specific domains
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "X-Session-Token"],
    )

    # Request ID middleware
    @app.middleware("http")
    async def add_request_id(request: Request, call_next):
        """Add X-Request-ID to all responses and request state."""
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    # 404, 405, etc. Handler
    from starlette.exceptions import HTTPException as StarletteHTTPException

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        """Handle standard HTTP exceptions with envelope."""
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))

        # Map status code to stage/code
        code = "not_found" if exc.status_code == 404 else "http_error"

        error_response = ApiEnvelope(
            data=None,
            error=ApiError(
                stage="unknown",  # Acts as routing layer error
                code=code,
                message_safe=str(exc.detail),
                retryable=False,
                details={"status_code": exc.status_code},
            ),
            request_id=request_id,
        )
        return JSONResponse(
            status_code=exc.status_code,
            content=error_response.model_dump(),
            headers={"X-Request-ID": request_id},
        )

    # Validation Error Handler (422)
    from fastapi.exceptions import RequestValidationError

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        """Handle validation errors with envelope."""
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))

        error_response = ApiEnvelope(
            data=None,
            error=ApiError(
                stage="unknown",  # Input validation is usually pre-domain logic
                code="validation_error",
                message_safe="Invalid request parameters",
                retryable=False,
                details={"errors": exc.errors()},
            ),
            request_id=request_id,
        )
        return JSONResponse(
            status_code=422,
            content=error_response.model_dump(),
            headers={"X-Request-ID": request_id},
        )

    # Global exception handler
    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        """Handle unhandled exceptions with envelope-wrapped error response.

        This ensures all errors return a properly formatted response
        that clients can parse consistently.
        """
        # Get request_id from state if available, otherwise generate new one
        request_id = getattr(request.state, "request_id", str(uuid.uuid4()))

        # Log the exception for debugging
        logger.exception(
            "Unhandled exception",
            extra={"request_id": request_id, "path": request.url.path},
        )

        # Create envelope-wrapped error response
        error_response = ApiEnvelope(
            data=None,
            error=ApiError(
                stage="unknown",
                code="internal_error",
                message_safe="An unexpected error occurred. Please try again later.",
                retryable=True,
                details=None,  # Don't expose internal details to clients
            ),
            request_id=request_id,
        )

        return JSONResponse(
            status_code=500,
            content=error_response.model_dump(),
            headers={"X-Request-ID": request_id},
        )

    # Register routers
    app.include_router(health.router, tags=["Health"])

    return app


# Create the app instance
app = create_app()

