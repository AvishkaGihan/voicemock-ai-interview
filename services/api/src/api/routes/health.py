"""Health check endpoint for VoiceMock API.

Provides a simple health check endpoint that can be used for:
- Load balancer health checks
- Container orchestration liveness probes
- Smoke testing during deployment

This endpoint follows the architecture-mandated response envelope pattern.
"""

from fastapi import APIRouter, Depends

from src.api.dependencies import RequestContext, get_request_context
from src.api.models import HealthData, HealthResponse

router = APIRouter()


@router.get(
    "/healthz",
    response_model=HealthResponse,
    responses={
        200: {
            "description": "Service is healthy",
            "content": {
                "application/json": {
                    "example": {
                        "data": {"status": "ok"},
                        "error": None,
                        "request_id": "550e8400-e29b-41d4-a716-446655440000",
                    }
                }
            },
        }
    },
)
async def health_check(
    ctx: RequestContext = Depends(get_request_context),
) -> HealthResponse:
    """Health check endpoint.

    Returns a simple status indicator for load balancers and
    monitoring systems, wrapped in the standard API envelope format.

    The response includes:
    - data: Contains {"status": "ok"} when service is healthy
    - error: Always null for successful health checks
    - request_id: Unique identifier for request tracing

    Args:
        ctx: Request context containing request_id (injected)

    Returns:
        HealthResponse: Health status wrapped in API envelope
    """
    return HealthResponse(
        data=HealthData(status="ok"),
        error=None,
        request_id=ctx.request_id,
    )
