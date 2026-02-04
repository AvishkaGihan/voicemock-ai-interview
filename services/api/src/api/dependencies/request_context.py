"""Request context dependency for FastAPI.

This module provides the RequestContext dependency that extracts
the request_id from request.state for use in route handlers.
"""

from fastapi import Request


class RequestContext:
    """Request-scoped context with request ID.

    This class encapsulates request-specific context data that can be
    injected into route handlers via FastAPI's dependency injection.

    Attributes:
        request_id: Unique identifier for this request (from middleware)
    """

    def __init__(self, request_id: str) -> None:
        """Initialize RequestContext with request ID.

        Args:
            request_id: The unique identifier for this request
        """
        self.request_id = request_id


def get_request_context(request: Request) -> RequestContext:
    """Extract request context from request state.

    This dependency extracts the request_id that was attached to the
    request by the middleware and wraps it in a RequestContext object.

    Args:
        request: The FastAPI request object

    Returns:
        RequestContext with the request_id from request.state
    """
    return RequestContext(request_id=request.state.request_id)
