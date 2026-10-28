"""
Configuration for the Route Optimization Service.

REQUIREMENTS:
1. Load from environment variables
2. Support local and cloud deployments
3. Validate required settings on startup
4. Secure defaults for production
"""

import logging
from functools import lru_cache
from typing import List, Optional

from pydantic_settings import BaseSettings
from pydantic import Field, field_validator, model_validator

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application settings loaded from environment."""

    # Service Configuration
    service_name: str = "route-optimization-service"
    service_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"
    routing_provider: str = Field(
        default="osrm", alias="provider"
    )  # google | osrm | haversine

    # API Configuration
    api_prefix: str = "/api/v1"
    api_key: str = ""  # Required in production
    require_authentication: bool = True  # Disable only for local dev

    # OSRM Configuration
    osrm_url: str = "http://localhost:5000"  # Local OSRM server
    osrm_timeout_seconds: int = 30
    osrm_max_coordinates: int = 100  # Max waypoints per request

    # OR-Tools Configuration
    solver_time_limit_seconds: int = 30
    solver_solution_limit: int = 100
    default_vehicle_speed_kmh: int = 40  # Fallback if OSRM unavailable

    # Rate Limiting
    max_requests_per_minute: int = 60
    max_waypoints_per_request: int = 50

    # CORS - SECURE DEFAULTS (no wildcard!)
    cors_origins: List[str] = []  # Must be explicitly configured
    cors_allow_credentials: bool = False

    # Security
    enable_docs: bool = False  # OpenAPI docs disabled by default
    trusted_hosts: Optional[List[str]] = None
    require_https: bool = True
    require_client_certificate: bool = False

    # Google Routes Preferred (external provider)
    google_routes_api_key: Optional[str] = None
    google_routes_base_url: str = "https://routes.googleapis.com"
    google_routes_region_code: Optional[str] = None
    google_routes_timeout_seconds: int = 20
    google_routes_traffic_model: str = "TRAFFIC_AWARE_OPTIMAL"  # TRAFFIC_AWARE or TRAFFIC_AWARE_OPTIMAL

    # JWT Configuration (for HIPAA-compliant auth)
    require_jwt_auth: bool = True
    allow_api_key_fallback: bool = False
    jwt_secret: Optional[str] = None
    jwt_public_key: Optional[str] = None
    jwt_algorithm: str = "HS256"
    jwt_audience: Optional[str] = None
    jwt_issuer: Optional[str] = None

    # Audit Logging
    audit_log_file: str = "/var/log/ai_server/routing_audit.log"
    enable_audit_logging: bool = True

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        """Parse CORS origins from comma-separated string or list."""
        if isinstance(v, str):
            if not v:
                return []
            return [origin.strip() for origin in v.split(",")]
        return v

    @field_validator("google_routes_base_url")
    @classmethod
    def validate_google_routes_url(cls, v: str) -> str:
        """Google Routes requires HTTPS endpoints."""
        if v and not v.startswith("https://"):
            raise ValueError("Google Routes base URL must be HTTPS")
        return v.rstrip("/") if v else v

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        """Validate settings are secure for production."""
        allowed_providers = {"google", "google_routes", "osrm", "haversine"}
        provider_value = self.routing_provider.lower()
        if provider_value not in allowed_providers:
            raise ValueError(
                f"routing_provider must be one of {allowed_providers}"
            )

        if provider_value == "google_routes":
            self.routing_provider = "google"

        if not self.debug:
            # Require API key in production
            if self.require_authentication and not self.api_key:
                logger.warning(
                    "SECURITY: No API key configured in production mode. "
                    "Set ROUTING_API_KEY environment variable."
                )

            # Warn about CORS
            if not self.cors_origins:
                logger.warning(
                    "SECURITY: No CORS origins configured. "
                    "Set ROUTING_CORS_ORIGINS to allowed domains."
                )
            elif "*" in self.cors_origins:
                logger.error(
                    "SECURITY: Wildcard CORS origin detected! "
                    "This is not allowed in production."
                )
                raise ValueError("Wildcard CORS origin not allowed in production")
            else:
                insecure_origins = [
                    origin for origin in self.cors_origins
                    if origin.startswith("http://") and "localhost" not in origin
                ]
                if insecure_origins:
                    logger.error(
                        "SECURITY: Insecure CORS origins configured: %s",
                        insecure_origins,
                    )
                    raise ValueError("CORS origins must be HTTPS in production")

            if self.trusted_hosts and "*" in self.trusted_hosts:
                logger.error(
                    "SECURITY: Wildcard trusted host detected! Configure explicit hosts."
                )
                raise ValueError("Wildcard trusted host not allowed in production")

            if self.allow_api_key_fallback:
                logger.error(
                    "SECURITY: API key fallback is disabled in production. "
                    "Set ROUTING_ALLOW_API_KEY_FALLBACK=false or enable debug for local dev."
                )
                raise ValueError("API key fallback not allowed when debug is false")

            if not self.require_https:
                logger.error("SECURITY: HTTPS is required in production deployments.")
                raise ValueError("HTTPS must be enabled in production")

        return self

    class Config:
        env_file = ".env"
        env_prefix = "ROUTING_"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Convenience access
settings = get_settings()
