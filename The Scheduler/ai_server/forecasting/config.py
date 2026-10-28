"""
Configuration for Demand Forecasting Service.

Uses environment variables for security-sensitive settings.

Agent AI-21: Waitlist Intelligence & Demand Forecasting
"""
import os
from functools import lru_cache
from typing import List, Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment."""

    # Server
    host: str = "0.0.0.0"
    port: int = 8002
    debug: bool = False

    # Security
    require_authentication: bool = True
    require_jwt_auth: bool = True
    allow_api_key_fallback: bool = True
    require_https: bool = True
    require_client_certificate: bool = False

    # JWT Configuration
    jwt_secret: Optional[str] = None
    jwt_public_key: Optional[str] = None
    jwt_algorithm: str = "HS256"
    jwt_audience: Optional[str] = None
    jwt_issuer: Optional[str] = None

    # API Keys (comma-separated, format: "key:business_id" or just "key" for admin)
    api_keys_str: str = ""

    # Rate Limiting
    rate_limit_rpm: int = 60  # Requests per minute

    # Prophet settings
    prophet_yearly_seasonality: bool = False
    prophet_weekly_seasonality: bool = True
    forecast_max_days: int = 90

    # Audit logging
    audit_log_file: str = "/var/log/ai_server/forecasting_audit.log"
    enable_audit_logging: bool = True

    @property
    def api_keys(self) -> List[str]:
        """Parse API keys from comma-separated string."""
        if not self.api_keys_str:
            return []
        return [k.strip() for k in self.api_keys_str.split(",") if k.strip()]

    class Config:
        env_prefix = "FORECAST_"
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
