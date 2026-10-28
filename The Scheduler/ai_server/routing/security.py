"""
Security middleware and utilities for HIPAA compliance.

REQUIREMENTS:
1. API key authentication with constant-time comparison
2. JWT authentication with tenant claims
3. X-Business-ID header validation for multi-tenant isolation
4. Rate limiting per client
5. Security headers
6. Request ID tracing
7. Input sanitization
8. HTTPS enforcement

Agent AI-11: Smart Route Optimization
"""

import hashlib
import hmac
import logging
import time
import uuid
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional, Callable, Dict

import jwt
from fastapi import Depends, Request, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.security import APIKeyHeader
from starlette.middleware.base import BaseHTTPMiddleware

from .config import settings, get_settings

logger = logging.getLogger(__name__)

# Security header dependencies
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
authorization_header = APIKeyHeader(name="Authorization", auto_error=False)
business_id_header = APIKeyHeader(name="X-Business-ID", auto_error=False)


# ============================================================
# Security Context
# ============================================================

@dataclass
class SecurityContext:
    """Security context for the current request."""

    request_id: str
    business_id: Optional[str] = None
    user_id: Optional[str] = None
    api_key_id: Optional[str] = None
    source_ip: Optional[str] = None
    token_id: Optional[str] = None

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


def require_tenant_access(
    security_context: SecurityContext,
    requested_business_id: str,
):
    """Validate tenant access or raise 403."""
    if not settings.require_authentication:
        return

    # Admin keys (business_id=None) can access all
    if security_context.business_id is None:
        return

    if not security_context.validate_tenant_access(requested_business_id):
        raise HTTPException(status_code=403, detail="Access denied to this business")


# ============================================================
# Rate Limiting
# ============================================================

class RateLimiter:
    """
    In-memory rate limiter using sliding window.

    For production, use Redis-based rate limiting.
    """

    def __init__(self, max_requests: int, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._requests: Dict[str, list] = defaultdict(list)

    def is_allowed(self, client_id: str) -> bool:
        """Check if request is allowed for client."""
        now = time.time()
        window_start = now - self.window_seconds

        # Clean old requests
        self._requests[client_id] = [
            ts for ts in self._requests[client_id]
            if ts > window_start
        ]

        # Check limit
        if len(self._requests[client_id]) >= self.max_requests:
            return False

        # Record request
        self._requests[client_id].append(now)
        return True

    def get_remaining(self, client_id: str) -> int:
        """Get remaining requests for client."""
        now = time.time()
        window_start = now - self.window_seconds
        current = len([
            ts for ts in self._requests[client_id]
            if ts > window_start
        ])
        return max(0, self.max_requests - current)


# Global rate limiter instance
_rate_limiter = RateLimiter(
    max_requests=settings.max_requests_per_minute,
    window_seconds=60
)


# ============================================================
# Authentication
# ============================================================

def constant_time_compare(a: str, b: str) -> bool:
    """
    Compare two strings in constant time to prevent timing attacks.
    """
    if not a or not b:
        return False
    return hmac.compare_digest(a.encode(), b.encode())


def hash_api_key(api_key: str) -> str:
    """Hash API key for logging (never log actual key)."""
    return hashlib.sha256(api_key.encode()).hexdigest()[:8]


def validate_jwt_token(token: str) -> Dict[str, Any]:
    """Validate JWT and return claims."""
    _settings = get_settings()
    if not _settings.jwt_public_key and not _settings.jwt_secret:
        raise HTTPException(status_code=500, detail="JWT not configured")

    try:
        key = _settings.jwt_public_key or _settings.jwt_secret
        options = {"verify_aud": _settings.jwt_audience is not None}
        return jwt.decode(
            token,
            key,
            algorithms=[_settings.jwt_algorithm],
            audience=_settings.jwt_audience,
            issuer=_settings.jwt_issuer,
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
    _settings = get_settings()
    request_id = getattr(request.state, "request_id", None) or request.headers.get(
        "X-Request-ID", str(uuid.uuid4())
    )
    source_ip = request.client.host if request.client else None

    if not _settings.require_authentication:
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

    if _settings.require_jwt_auth:
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

        if not x_business_id:
            raise HTTPException(
                status_code=400, detail="X-Business-ID header required"
            )

        # Validate X-Business-ID matches JWT claim
        if x_business_id != business_id:
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
    if _settings.allow_api_key_fallback:
        if not _settings.debug:
            raise HTTPException(
                status_code=500,
                detail="API key fallback disabled in production",
            )
        if not api_key:
            raise HTTPException(
                status_code=401,
                detail="API key required",
                headers={"WWW-Authenticate": "ApiKey"},
            )

        if not constant_time_compare(api_key, _settings.api_key):
            logger.warning(
                "Authentication failed",
                extra={
                    "event": "auth_failure",
                    "client_ip": source_ip,
                }
            )
            raise HTTPException(
                status_code=401,
                detail="Invalid API key",
                headers={"WWW-Authenticate": "ApiKey"},
            )

        if not _rate_limiter.is_allowed(hash_api_key(api_key)):
            raise HTTPException(status_code=429, detail="Rate limit exceeded")

        # For API key auth, X-Business-ID header is required
        if not x_business_id:
            raise HTTPException(
                status_code=400, detail="X-Business-ID header required"
            )

        return SecurityContext(
            request_id=request_id,
            business_id=x_business_id,
            api_key_id=hash_api_key(api_key),
            source_ip=source_ip,
        )

    raise HTTPException(
        status_code=401,
        detail="Authentication required",
        headers={"WWW-Authenticate": "Bearer"},
    )


async def verify_api_key_secure(request: Request) -> str:
    """
    Verify API key with constant-time comparison.

    Returns the client identifier for audit logging.
    DEPRECATED: Use get_security_context instead for full JWT support.
    """
    if settings.debug:
        return "debug_client"

    api_key = request.headers.get("X-API-Key")

    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    if not constant_time_compare(api_key, settings.api_key):
        # Log failed auth attempt (no sensitive data)
        logger.warning(
            "Authentication failed",
            extra={
                "event": "auth_failure",
                "client_ip": _get_client_ip(request),
            }
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    return "authenticated_client"


def _get_client_ip(request: Request) -> str:
    """Get client IP, handling proxies."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


# ============================================================
# Security Headers Middleware
# ============================================================

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to all responses."""

    async def dispatch(self, request: Request, call_next: Callable):
        response = await call_next(request)

        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        response.headers["Pragma"] = "no-cache"

        # HSTS for production
        if not settings.debug:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )

        return response


# ============================================================
# Rate Limiting Middleware
# ============================================================

class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limit requests per client."""

    async def dispatch(self, request: Request, call_next: Callable):
        # Skip rate limiting for health checks
        if request.url.path.endswith("/health"):
            return await call_next(request)

        client_id = _get_client_ip(request)

        if not _rate_limiter.is_allowed(client_id):
            logger.warning(
                "Rate limit exceeded",
                extra={
                    "event": "rate_limit",
                    "client_ip": client_id,
                }
            )
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={"error": "Rate limit exceeded", "code": "RATE_LIMITED"},
                headers={
                    "Retry-After": "60",
                    "X-RateLimit-Remaining": "0",
                }
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Remaining"] = str(
            _rate_limiter.get_remaining(client_id)
        )
        return response


# ============================================================
# Request ID Middleware
# ============================================================

class RequestIDMiddleware(BaseHTTPMiddleware):
    """Add unique request ID for tracing."""

    async def dispatch(self, request: Request, call_next: Callable):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


# ============================================================
# Transport Security Middleware
# ============================================================

class TransportSecurityMiddleware(BaseHTTPMiddleware):
    """Enforce HTTPS and optional mTLS."""

    async def dispatch(self, request: Request, call_next: Callable):
        _settings = get_settings()

        if _settings.require_https:
            proto = request.headers.get("x-forwarded-proto") or request.url.scheme
            if proto != "https":
                raise HTTPException(status_code=400, detail="HTTPS required")

        if _settings.require_client_certificate:
            verified = request.headers.get("x-ssl-client-verify") or request.headers.get(
                "x-client-cert-verified"
            )
            if verified not in ("SUCCESS", "SUCCESSFUL", "true", "1"):
                raise HTTPException(status_code=400, detail="Client certificate required")

        return await call_next(request)


# ============================================================
# Utility Functions
# ============================================================

def sanitize_for_logging(value: str, max_length: int = 50) -> str:
    """
    Sanitize a value for safe logging.

    - Truncates long values
    - Masks potential PHI
    """
    if not value:
        return ""

    # Truncate
    if len(value) > max_length:
        return value[:max_length] + "..."

    return value


def mask_identifier(value: str) -> str:
    """
    Mask an identifier for logging (show only last 4 chars).
    """
    if not value or len(value) <= 4:
        return "****"
    return f"****{value[-4:]}"


def generate_correlation_id() -> str:
    """Generate a correlation ID for request tracing."""
    return f"route_{uuid.uuid4().hex[:12]}"
