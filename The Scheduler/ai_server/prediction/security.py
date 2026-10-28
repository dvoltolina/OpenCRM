"""
Security middleware for HIPAA compliance in prediction service.

Provides:
- API key authentication
- Multi-tenant isolation validation
- Request ID tracking for audit correlation
- Rate limiting (basic)
- Optional JWT auth with tenant claims
- Transport security enforcement (HTTPS + mTLS headers)

Agent AI-3: Python Prediction Server (Security Enhancement)
"""
import uuid
import hashlib
import time
from typing import Optional, Dict, Callable, Any
from collections import defaultdict
from datetime import datetime

import jwt
from fastapi import Request, HTTPException, Depends
from fastapi.security import APIKeyHeader
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from .config import get_settings
from .audit import audit_logger


# API Key header
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
authorization_header = APIKeyHeader(name="Authorization", auto_error=False)


class SecurityContext:
    """
    Security context for the current request.

    Provides authenticated identity and tenant information.
    """

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
        """
        Validate that the authenticated context can access the requested business.

        HIPAA requires multi-tenant isolation - a request authenticated for
        business A must not be able to access business B's data.
        """
        if not self.business_id:
            # No authenticated business - deny
            return False

        if self.business_id != requested_business_id:
            # Log the violation attempt
            audit_logger.log_invalid_tenant_access(
                claimed_business_id=requested_business_id,
                authenticated_business_id=self.business_id,
                request_id=self.request_id,
            )
            return False

        return True


class RateLimiter:
    """
    Simple in-memory rate limiter.

    In production, use Redis for distributed rate limiting.
    """

    def __init__(self, requests_per_minute: int = 120):
        self.requests_per_minute = requests_per_minute
        self.requests: Dict[str, list] = defaultdict(list)

    def is_allowed(self, key: str) -> bool:
        """Check if a request is allowed under rate limits."""
        now = time.time()
        minute_ago = now - 60

        # Clean old requests
        self.requests[key] = [t for t in self.requests[key] if t > minute_ago]

        if len(self.requests[key]) >= self.requests_per_minute:
            return False

        self.requests[key].append(now)
        return True


_settings_for_rate_limit = get_settings()
# Global rate limiter
rate_limiter = RateLimiter(requests_per_minute=_settings_for_rate_limit.rate_limit_rpm)


def hash_api_key(api_key: str) -> str:
    """Hash an API key for comparison."""
    return hashlib.sha256(api_key.encode()).hexdigest()


def validate_api_key(api_key: Optional[str]) -> Optional[Dict]:
    """
    Validate an API key and return associated metadata.

    In production, this would query a database of valid API keys.
    For now, we use environment-configured keys.
    """
    if not api_key:
        return None

    settings = get_settings()

    # Check against configured API keys
    # Format: "key_id:business_id" or just the key for admin access
    for valid_key in settings.api_keys:
        if ":" in valid_key:
            key_value, key_business_id = valid_key.rsplit(":", 1)
            if api_key == key_value:
                return {
                    "key_id": hash_api_key(api_key)[:8],
                    "business_id": key_business_id,
                }
        elif api_key == valid_key:
            # Admin key - can access all businesses
            return {
                "key_id": hash_api_key(api_key)[:8],
                "business_id": None,  # None means all businesses
            }

    return None


def validate_jwt_token(token: str) -> Dict[str, Any]:
    """Validate JWT and return claims."""
    settings = get_settings()

    if not settings.jwt_public_key and not settings.jwt_secret:
        raise HTTPException(
            status_code=500,
            detail="JWT validation not configured",
        )

    try:
        key = settings.jwt_public_key or settings.jwt_secret
        algorithms = [settings.jwt_algorithm]
        options = {"verify_aud": settings.jwt_audience is not None}
        decoded = jwt.decode(
            token,
            key,
            algorithms=algorithms,
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
            options=options,
        )
        return decoded
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}")


async def get_security_context(
    request: Request,
    api_key: Optional[str] = Depends(api_key_header),
    authorization: Optional[str] = Depends(authorization_header),
) -> SecurityContext:
    """
    Dependency that provides security context for requests.

    Validates authentication and creates a security context.
    """
    settings = get_settings()

    # Generate request ID for audit correlation
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

    # Get source IP
    source_ip = request.client.host if request.client else None

    # Authentication
    if settings.require_authentication:
        token = None
        if authorization and authorization.lower().startswith("bearer "):
            token = authorization.split(" ", 1)[1]

        # JWT path (preferred)
        if settings.require_jwt_auth:
            if not token:
                audit_logger.log_unauthorized_access(
                    reason="missing_bearer_token",
                    source_ip=source_ip,
                    request_id=request_id,
                )
                raise HTTPException(
                    status_code=401,
                    detail="Bearer token required",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            claims = validate_jwt_token(token)
            business_id = claims.get("businessId") or claims.get("business_id")
            user_id = claims.get("sub") or claims.get("userId")
            if not business_id or not user_id:
                audit_logger.log_unauthorized_access(
                    reason="missing_claims",
                    source_ip=source_ip,
                    request_id=request_id,
                )
                raise HTTPException(status_code=401, detail="Invalid token claims")

            return SecurityContext(
                request_id=request_id,
                business_id=business_id,
                user_id=user_id,
                source_ip=source_ip,
                token_id=str(claims.get("jti", "")) or None,
            )

        # Legacy API key path (optionally enabled)
        if settings.allow_api_key_fallback:
            if not api_key:
                audit_logger.log_unauthorized_access(
                    reason="missing_api_key",
                    source_ip=source_ip,
                    request_id=request_id,
                )
                raise HTTPException(
                    status_code=401,
                    detail="API key required",
                    headers={"WWW-Authenticate": "ApiKey"},
                )

            key_info = validate_api_key(api_key)
            if not key_info:
                audit_logger.log_unauthorized_access(
                    reason="invalid_api_key",
                    source_ip=source_ip,
                    request_id=request_id,
                )
                raise HTTPException(
                    status_code=401,
                    detail="Invalid API key",
                    headers={"WWW-Authenticate": "ApiKey"},
                )

            # Check rate limit by API key
            if not rate_limiter.is_allowed(key_info["key_id"]):
                raise HTTPException(
                    status_code=429,
                    detail="Rate limit exceeded",
                )

            return SecurityContext(
                request_id=request_id,
                business_id=key_info.get("business_id"),
                api_key_id=key_info["key_id"],
                source_ip=source_ip,
            )

        # Auth required but neither JWT nor allowed API key provided
        raise HTTPException(
            status_code=401,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # No authentication required (development mode)
    # Still create a context for audit logging
    return SecurityContext(
        request_id=request_id,
        source_ip=source_ip,
    )


def require_tenant_access(
    security_context: SecurityContext,
    requested_business_id: str,
):
    """
    Validate that the security context can access the requested business.

    Raises HTTPException if access is denied.
    """
    settings = get_settings()

    # Skip validation if authentication is not required (development)
    if not settings.require_authentication:
        return

    # Admin keys (business_id=None) can access all businesses
    if security_context.business_id is None:
        return

    if not security_context.validate_tenant_access(requested_business_id):
        raise HTTPException(
            status_code=403,
            detail="Access denied to this business",
        )


class RequestIdMiddleware(BaseHTTPMiddleware):
    """Middleware to add request ID to all responses for audit correlation."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))

        # Store in request state for access in endpoints
        request.state.request_id = request_id

        response = await call_next(request)

        # Add to response headers
        response.headers["X-Request-ID"] = request_id

        return response


class TransportSecurityMiddleware(BaseHTTPMiddleware):
    """Middleware to enforce HTTPS-only and optional mTLS verification."""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        settings = get_settings()

        # Enforce HTTPS (allow override for localhost/dev)
        if settings.require_https:
            proto = request.headers.get("x-forwarded-proto") or request.url.scheme
            if proto != "https":
                raise HTTPException(
                    status_code=400,
                    detail="HTTPS is required for this endpoint",
                )

        # Enforce mTLS header if enabled (assumes upstream terminates TLS)
        if settings.require_client_certificate:
            verified = request.headers.get("x-ssl-client-verify") or request.headers.get("x-client-cert-verified")
            if verified not in ("SUCCESS", "SUCCESSFUL", "true", "1"):
                raise HTTPException(
                    status_code=400,
                    detail="Client certificate verification required",
                )

        return await call_next(request)
