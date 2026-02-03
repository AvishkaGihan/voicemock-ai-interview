"""VoiceMock API - FastAPI Application Entry Point.

This module initializes the FastAPI application with:
- CORS middleware configuration
- Health check endpoint
- Request ID middleware (for future stories)
- Route registration
"""

import uuid
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from src.api.routes import health


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan handler for startup/shutdown events."""
    # Startup
    print("VoiceMock API starting up...")
    yield
    # Shutdown
    print("VoiceMock API shutting down...")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="VoiceMock AI Interview Coach API",
        description="Backend API for VoiceMock voice interview coaching application",
        version="0.1.0",
        lifespan=lifespan,
    )

    # CORS middleware - allowing all origins for development
    # TODO: Restrict origins in production
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
        """Add X-Request-ID to all responses."""
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    # Register routers
    app.include_router(health.router, tags=["Health"])

    return app


# Create the app instance
app = create_app()
