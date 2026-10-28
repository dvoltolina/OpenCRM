"""
Configuration for sentiment analysis service.
Uses environment variables with sensible defaults.

Agent AI-6: Python Sentiment Service (Ollama LLM)

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
    Prefix: SENTIMENT_
    """

    # Server settings
    host: str = "0.0.0.0"
    port: int = 8002
    debug: bool = False
    require_https: bool = True  # Enforce HTTPS in production
    require_client_certificate: bool = False  # Enable when mTLS is enforced at ingress

    # Ollama settings
    ollama_url: str = "http://localhost:11434"
    ollama_timeout: float = 60.0
    default_model: str = "phi3:mini"
    deep_analysis_model: str = "llama3.1:8b"

    # Analysis settings
    result_ttl_hours: int = 168  # 7 days
    max_batch_size: int = 20

    # CORS settings - configure for your Flutter app's origin
    # HIPAA: Restrict to known origins in production
    allowed_origins: List[str] = [
        "https://admin.example.com",
        "https://app.example.com",
        "http://localhost:3000",  # dev only
        "http://localhost:8080",  # dev only
    ]

    # Explicit headers (no wildcard)
    allowed_headers: List[str] = [
        "Content-Type",
        "Accept",
        "Authorization",
        "X-API-Key",
        "X-Request-ID",
        "X-Business-ID",
        "X-Client-Cert",
        "X-Forwarded-Proto",
    ]

    # Logging
    log_level: str = "INFO"

    # API versioning
    api_version: str = "v1"

    # Provider selection
    sentiment_provider: str = "google"  # google | openai | ollama | vader

    # Google Cloud Natural Language
    google_language_endpoint: str = "https://language.googleapis.com"
    google_language_model_version: str = "google-nl-v1"

    # OpenAI
    openai_api_key: str | None = None
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    openai_timeout: float = 15.0

    # Local fallback (no external calls)
    enable_textblob_fallback: bool = True

    # Outbound transport enforcement
    require_https_outbound: bool = True  # Enforce HTTPS for external providers
    allow_local_http_providers: bool = True  # Allow http://localhost during dev

    # ============ HIPAA Security Settings ============

    # Authentication - MUST be True in production for HIPAA
    require_authentication: bool = True  # MUST be True in production

    # JWT authentication (preferred)
    require_jwt_auth: bool = True
    jwt_public_key: str | None = None  # PEM-encoded public key for RS256
    jwt_secret: str | None = None  # HS256 fallback
    jwt_algorithm: str = "RS256"
    jwt_audience: str | None = None
    jwt_issuer: str | None = None
    allow_api_key_fallback: bool = False  # Legacy; enable only during migration

    # API Keys - format: "key_value:business_id" or "key_value" for admin
    # HIPAA: Each business should have its own API key
    # Example: ["abc123:business_001", "def456:business_002", "admin_key"]
    api_keys: List[str] = []

    # Rate limiting (requests per minute per API key)
    rate_limit_rpm: int = 60

    # Audit logging - HIPAA requires this, always enabled
    enable_audit_logging: bool = True

    # PHI protection - minimize response PHI
    max_analyzed_text_length: int = 64  # keep very short in responses
    redact_trigger_text: bool = True  # redact PHI trigger snippets
    redact_summary: bool = True  # redact generated summaries (may contain PHI)
    redact_recommended_action: bool = True  # redact actions (may echo PHI)

    model_config = {
        "env_prefix": "SENTIMENT_",
        "env_file": ".env",
        "extra": "ignore",
    }


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
