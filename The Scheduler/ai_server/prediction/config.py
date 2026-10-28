"""
Configuration for prediction service.
Uses environment variables with sensible defaults.

Agent AI-3: Python Prediction Server

HIPAA COMPLIANCE NOTES:
- Set require_authentication=True in production
- Configure api_keys with business-specific keys
- Use HTTPS in production (terminate TLS at load balancer)
- Enable audit logging (always on by default)
"""
from pydantic_settings import BaseSettings
from typing import List
from functools import lru_cache


class Settings(BaseSettings):
    """
    Server configuration loaded from environment variables.
    Prefix: PREDICTION_
    """

    # Server settings
    host: str = "0.0.0.0"
    port: int = 8001
    debug: bool = False
    workers: int = 1  # LightGBM is already optimized, 1 worker is usually enough
    require_https: bool = True  # Enforce HTTPS (disable only for local dev)
    require_client_certificate: bool = False  # Set true when mTLS is enforced at ingress

    # Model settings
    models_dir: str = "models"
    default_model_name: str = "noshow_model"

    # Prediction thresholds - MUST match Flutter AIConfig defaults
    high_risk_threshold: float = 0.7
    medium_risk_threshold: float = 0.4
    min_confidence_score: float = 0.6
    prediction_cache_ttl_minutes: int = 15

    # Batch settings
    max_batch_size: int = 100

    # CORS settings - configure for your Flutter app's origin
    # HIPAA: Restrict to known origins in production
    allowed_origins: List[str] = [
        "https://admin.example.com",
        "https://app.example.com",
        "http://localhost:3000",  # dev only
        "http://localhost:8080",  # dev only
    ]

    # HIPAA: Explicitly list allowed headers instead of wildcard
    allowed_headers: List[str] = [
        "Content-Type",
        "Accept",
        "X-API-Key",
        "X-Request-ID",
        "X-Business-ID",
        "Authorization",
        "X-Client-Cert",
        "X-Forwarded-Proto",
    ]

    # Logging
    log_level: str = "INFO"

    # API versioning
    api_version: str = "v1"

    # ============ HIPAA Security Settings ============

    # Authentication - MUST be True in production for HIPAA
    require_authentication: bool = True  # Set False only for local dev

    # JWT authentication (preferred, tenant-scoped)
    require_jwt_auth: bool = True
    jwt_public_key: str | None = None  # PEM-encoded public key for RS256
    jwt_secret: str | None = None  # HS256 fallback
    jwt_algorithm: str = "RS256"
    jwt_audience: str | None = None
    jwt_issuer: str | None = None
    allow_api_key_fallback: bool = False  # Legacy path; set True only during migration

    # API Keys - format: "key_value:business_id" or "key_value" for admin (legacy)
    api_keys: List[str] = []

    # Rate limiting (requests per minute per API key)
    rate_limit_rpm: int = 120  # Higher for predictions since they're fast

    # Audit logging - HIPAA requires this, always enabled
    enable_audit_logging: bool = True

    model_config = {
        "env_prefix": "PREDICTION_",
        "env_file": ".env",
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
