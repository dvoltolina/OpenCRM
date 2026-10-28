"""
Security middleware for HIPAA compliance in forecasting service.

Provides:
- JWT/API key authentication
- Multi-tenant isolation via X-Business-ID header validation
- HTTPS enforcement
- Rate limiting
- Request ID tracking for audit correlation

Agent AI-21: Waitlist Intelligence & Demand Forecasting
"""
import hashlib
import logging
import time
import uuid
from collections import defaultdict
from datetime import datetime
from typing import Any, Callable, Dict, Optional

import jwt
from fastapi import Depends, HTTPException, Request
from fastapi.security import APIKeyHeader
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from .config import get_settings

logger = logging.getLogger(__name__)

# Headers
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
authorization_header = APIKeyHeader(name="Authorization", auto_error=False)
business_id_header = APIKeyHeader(name="X-Business-ID", auto_error=False)


class SecurityContext:
    """Security context for the current request."""

    def __init__(
        self,
        request_id: str,
        business_id: Optional[str] = None,
        user_id: Optional[str] = None,
        api_key_id: Optional[str] = None,
        source_ip: Optional[str] = None,
        token_id: Optional[str] = None,
    ):
        self.request_id = request_id
        self.business_id = business_id
        self.user_id = user_id
        self.api_key_id = api_key_id
        self.source_ip = source_ip
        self.token_id = token_id
        self.created_at = datetime.utcnow()

    def validate_tenant_access(self, requested_business_id: str) -> bool:
        """Validate tenant access - HIPAA multi-tenant isolation."""
        if not self.business_id:
            return False
        if self.business_id != requested_business_id:
            logger.warning(
                "Tenant access violation",
                extra={
                    "event": "tenant_violation",
                    "claimed": requested_business_id,
                    "authenticated": self.business_id,
                    "request_id": self.request_id,
                },
            )
            return False
        return True


class RateLimiter:
    """In-memory rate limiter."""

    def __init__(self, requests_per_minute: int = 60):
        self.rpm = requests_per_minute
        self.requests: Dict[str, list] = defaultdict(list)

    def is_allowed(self, key: str) -> bool:
        now = time.time()
        minute_ago = now - 60
        self.requests[key] = [t for t in self.requests[key] if t > minute_ago]
        if len(self.requests[key]) >= self.rpm:
            return False
        self.requests[key].append(now)
        return True


_settings = get_settings()
rate_limiter = RateLimiter(requests_per_minute=_settings.rate_limit_rpm)


def hash_api_key(api_key: str) -> str:
    """Hash API key for logging (never log actual key)."""
    return hashlib.sha256(api_key.encode()).hexdigest()[:8]


def validate_api_key(api_key: Optional[str]) -> Optional[Dict]:
    """Validate API key and return metadata."""
    if not api_key:
        return None

    settings = get_settings()
    for valid_key in settings.api_keys:
        if ":" in valid_key:
            key_value, key_business_id = valid_key.rsplit(":", 1)
            if api_key == key_value:
                return {"key_id": hash_api_key(api_key), "business_id": key_business_id}
        elif api_key == valid_key:
            return {"key_id": hash_api_key(api_key), "business_id": None}
    return None


def validate_jwt_token(token: str) -> Dict[str, Any]:
    """Validate JWT and return claims."""
    settings = get_settings()
    if not settings.jwt_public_key and not settings.jwt_secret:
        raise HTTPException(status_code=500, detail="JWT not configured")

    try:
        key = settings.jwt_public_key or settings.jwt_secret
        options = {"verify_aud": settings.jwt_audience is not None}
        return jwt.decode(
            token,
            key,
            algorithms=[settings.jwt_algorithm],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
            options=options,
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")


async def get_security_context(
    request: Request,
    api_key: Optional[str] = Depends(api_key_header),
    authorization: Optional[str] = Depends(authorization_header),
    x_business_id: Optional[str] = Depends(business_id_header),
) -> SecurityContext:
    """Dependency providing authenticated security context."""
    settings = get_settings()
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    source_ip = request.client.host if request.client else None

    if not settings.require_authentication:
        # Dev mode - still track business from header
        return SecurityContext(
            request_id=request_id,
            business_id=x_business_id,
            source_ip=source_ip,
        )

    # JWT authentication (preferred)
    token = None
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1]

    if settings.require_jwt_auth:
        if not token:
            logger.warning("Missing bearer token", extra={"request_id": request_id})
            raise HTTPException(
                status_code=401,
                detail="Bearer token required",
                headers={"WWW-Authenticate": "Bearer"},
            )

        claims = validate_jwt_token(token)
        business_id = claims.get("businessId") or claims.get("business_id")
        user_id = claims.get("sub") or claims.get("userId")

        if not business_id or not user_id:
            raise HTTPException(status_code=401, detail="Invalid token claims")

        # Validate X-Business-ID matches JWT claim
        if x_business_id and x_business_id != business_id:
            logger.warning(
                "Business ID mismatch",
                extra={
                    "header_business_id": x_business_id,
                    "token_business_id": business_id,
                    "request_id": request_id,
                },
            )
            raise HTTPException(
                status_code=403, detail="Business ID mismatch with token"
            )

        return SecurityContext(
            request_id=request_id,
            business_id=business_id,
            user_id=user_id,
            source_ip=source_ip,
            token_id=str(claims.get("jti", "")) or None,
        )

    # API key fallback
    if settings.allow_api_key_fallback:
        if not api_key:
            raise HTTPException(
                status_code=401,
                detail="API key required",
                headers={"WWW-Authenticate": "ApiKey"},
            )

        key_info = validate_api_key(api_key)
        if not key_info:
            raise HTTPException(status_code=401, detail="Invalid API key")

        if not rate_limiter.is_allowed(key_info["key_id"]):
            raise HTTPException(status_code=429, detail="Rate limit exceeded")

        # For API key auth, X-Business-ID header is required
        effective_business_id = key_info.get("business_id") or x_business_id
        if not effective_business_id:
            raise HTTPException(
                status_code=400, detail="X-Business-ID header required"
            )

        return SecurityContext(
            request_id=request_id,
            business_id=effective_business_id,
            api_key_id=key_info["key_id"],
            source_ip=source_ip,
        )

    raise HTTPException(
        status_code=401,
        detail="Authentication required",
        headers={"WWW-Authenticate": "Bearer"},
    )


def require_tenant_access(
    security_context: SecurityContext,
    requested_business_id: str,
):
    """Validate tenant access or raise 403."""
    settings = get_settings()
    if not settings.require_authentication:
        return

    # Admin keys (business_id=None) can access all
    if security_context.business_id is None:
        return

    if not security_context.validate_tenant_access(requested_business_id):
        raise HTTPException(status_code=403, detail="Access denied to this business")


class RequestIdMiddleware(BaseHTTPMiddleware):
    """Add request ID for audit correlation."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class TransportSecurityMiddleware(BaseHTTPMiddleware):
    """Enforce HTTPS and optional mTLS."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        settings = get_settings()

        if settings.require_https:
            proto = request.headers.get("x-forwarded-proto") or request.url.scheme
            if proto != "https":
                raise HTTPException(status_code=400, detail="HTTPS required")

        if settings.require_client_certificate:
            verified = request.headers.get("x-ssl-client-verify") or request.headers.get(
                "x-client-cert-verified"
            )
            if verified not in ("SUCCESS", "SUCCESSFUL", "true", "1"):
                raise HTTPException(status_code=400, detail="Client certificate required")

        return await call_next(request)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to responses."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        response.headers["Pragma"] = "no-cache"

        settings = get_settings()
        if not settings.debug:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )
        return response
