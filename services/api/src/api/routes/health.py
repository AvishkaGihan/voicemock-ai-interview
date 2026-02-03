"""Health check endpoint for VoiceMock API.

Provides a simple health check endpoint that can be used for:
- Load balancer health checks
- Container orchestration liveness probes
- Smoke testing during deployment
"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/healthz")
async def health_check() -> dict:
    """Health check endpoint.

    Returns a simple status indicator for load balancers and
    monitoring systems.

    Returns:
        dict: Health status response with {"status": "ok"}
    """
    return {"status": "ok"}
