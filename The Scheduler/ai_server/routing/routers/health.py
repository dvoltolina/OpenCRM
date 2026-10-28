"""
Health check endpoints.

REQUIREMENTS:
1. Basic health check
2. OSRM connectivity check
3. Detailed status for monitoring
"""

from datetime import datetime
from fastapi import APIRouter, Depends

from ..config import settings
from ..models.responses import HealthResponse
from ..services.osrm_client import get_osrm_client, OSRMClient

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Basic health check."""
    return HealthResponse(
        status="healthy",
        service=settings.service_name,
        version=settings.service_version,
        timestamp=datetime.utcnow(),
    )


@router.get("/detailed", response_model=HealthResponse)
async def detailed_health_check(
    osrm_client: OSRMClient = Depends(get_osrm_client),
) -> HealthResponse:
    """Detailed health check including dependencies."""
    osrm_healthy = await osrm_client.health_check()

    return HealthResponse(
        status="healthy" if osrm_healthy else "degraded",
        service=settings.service_name,
        version=settings.service_version,
        osrm_status="healthy" if osrm_healthy else "unreachable",
        timestamp=datetime.utcnow(),
    )
