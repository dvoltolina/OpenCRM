"""
HIPAA-compliant audit logging for route optimization.

REQUIREMENTS:
1. Log all API access (who, when, what)
2. No PHI in logs (no names, addresses, specific locations)
3. Structured logging for analysis
4. Correlation IDs for request tracing
"""

import json
import logging
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, Any

from fastapi import Request

from .config import settings
from .security import _get_client_ip, mask_identifier

# Configure structured logging
logger = logging.getLogger("audit")


class AuditAction(str, Enum):
    """Audit action types."""
    ROUTE_OPTIMIZE_REQUEST = "route_optimize_request"
    ROUTE_OPTIMIZE_SUCCESS = "route_optimize_success"
    ROUTE_OPTIMIZE_FAILURE = "route_optimize_failure"
    AUTH_SUCCESS = "auth_success"
    AUTH_FAILURE = "auth_failure"
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded"
    HEALTH_CHECK = "health_check"


class AuditLogger:
    """
    HIPAA-compliant audit logger.

    Logs structured events without PHI.
    """

    def __init__(self, service_name: str):
        self.service_name = service_name

    def log(
        self,
        action: AuditAction,
        endpoint: str,
        request: Optional[Request] = None,
        business_id: Optional[str] = None,
        provider_id: Optional[str] = None,
        user_id: Optional[str] = None,
        correlation_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        routing_source: Optional[str] = None,
        status_code: Optional[int] = None,
        processing_time_ms: Optional[int] = None,
        success: bool = True,
        error_code: Optional[str] = None,
        request_id: Optional[str] = None,
    ) -> None:
        """
        Log an audit event.

        IMPORTANT: No PHI should be passed in metadata.
        Only pass counts, IDs (masked), and status codes.
        """
        event = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "service": self.service_name,
            "action": action.value,
            "endpoint": endpoint,
            "success": success,
            "correlation_id": correlation_id,
            "business_id": business_id,
            "user_id": user_id,
            "request_id": request_id,
            "status_code": status_code,
            "processing_time_ms": processing_time_ms,
            "routing_source": routing_source,
            "provider_id_suffix": mask_identifier(provider_id) if provider_id else None,
        }

        if request:
            event.update({
                "client_ip": _get_client_ip(request),
                "request_id": getattr(request.state, "request_id", None)
                or event["request_id"],
                "user_agent": request.headers.get("User-Agent", "")[:100],
            })

        if error_code:
            event["error_code"] = error_code

        # Add safe metadata (no PHI)
        if metadata:
            safe_metadata = self._sanitize_metadata(metadata)
            event["metadata"] = safe_metadata

        # Log as JSON for structured logging
        logger.info(json.dumps(event))

    def _sanitize_metadata(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """
        Sanitize metadata to ensure no PHI.

        Only allows known safe fields.
        """
        allowed_fields = {
            # Counts (never PHI)
            "waypoint_count",
            "stop_count",
            "segment_count",
            # Performance metrics (never PHI)
            "computation_time_ms",
            "total_distance_meters",
            "total_duration_seconds",
            "time_saved_seconds",
            "improvement_percent",
            # Status fields (never PHI)
            "solver_status",
            "matrix_source",
            "route_status",
            # Error info (never PHI)
            "error_type",
            "http_status",
        }

        return {
            k: v for k, v in metadata.items()
            if k in allowed_fields
        }

    def log_optimize_request(
        self,
        request: Request,
        business_id: str,
        provider_id: str,
        correlation_id: str,
        waypoint_count: int,
        user_id: Optional[str],
        routing_source: Optional[str],
        request_id: Optional[str],
    ) -> None:
        """Log route optimization request (no PHI)."""
        self.log(
            action=AuditAction.ROUTE_OPTIMIZE_REQUEST,
            endpoint="/api/v1/routes/optimize",
            request=request,
            business_id=business_id,
            provider_id=provider_id,
            user_id=user_id,
            request_id=request_id,
            correlation_id=correlation_id,
            routing_source=routing_source,
            status_code=None,
            processing_time_ms=0,
            metadata={"waypoint_count": waypoint_count},
        )

    def log_optimize_success(
        self,
        request: Request,
        business_id: str,
        provider_id: str,
        correlation_id: str,
        stop_count: int,
        computation_time_ms: int,
        time_saved_seconds: int,
        improvement_percent: float,
        routing_source: Optional[str],
        status_code: int,
        request_id: Optional[str],
        user_id: Optional[str],
        processing_time_ms: int,
    ) -> None:
        """Log successful optimization (no PHI)."""
        self.log(
            action=AuditAction.ROUTE_OPTIMIZE_SUCCESS,
            endpoint="/api/v1/routes/optimize",
            request=request,
            business_id=business_id,
            provider_id=provider_id,
            user_id=user_id,
            request_id=request_id,
            correlation_id=correlation_id,
            routing_source=routing_source,
            status_code=status_code,
            processing_time_ms=processing_time_ms,
            metadata={
                "stop_count": stop_count,
                "computation_time_ms": computation_time_ms,
                "time_saved_seconds": time_saved_seconds,
                "improvement_percent": round(improvement_percent, 2),
            },
        )

    def log_optimize_failure(
        self,
        request: Request,
        business_id: str,
        provider_id: str,
        correlation_id: str,
        error_type: str,
        http_status: int,
        routing_source: Optional[str],
        request_id: Optional[str],
        user_id: Optional[str],
        processing_time_ms: int,
    ) -> None:
        """Log failed optimization (no PHI)."""
        self.log(
            action=AuditAction.ROUTE_OPTIMIZE_FAILURE,
            endpoint="/api/v1/routes/optimize",
            request=request,
            business_id=business_id,
            provider_id=provider_id,
            user_id=user_id,
            request_id=request_id,
            correlation_id=correlation_id,
            routing_source=routing_source,
            status_code=http_status,
            processing_time_ms=processing_time_ms,
            success=False,
            error_code=error_type,
            metadata={
                "error_type": error_type,
                "http_status": http_status,
            },
        )


# Global audit logger instance
audit_logger = AuditLogger(service_name=settings.service_name)
