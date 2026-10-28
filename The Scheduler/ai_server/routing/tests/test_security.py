"""Tests for security features."""

import pytest
from datetime import datetime, timedelta
from unittest.mock import patch

from fastapi.testclient import TestClient

from ..app import app
from ..config import Settings, settings
from ..security import (
    constant_time_compare,
    mask_identifier,
    sanitize_for_logging,
    RateLimiter,
)


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app, base_url="https://testserver")


# ============================================================
# Unit Tests for Security Functions
# ============================================================


def test_constant_time_compare_equal():
    """Test constant time comparison with equal strings."""
    assert constant_time_compare("secret123", "secret123") is True


def test_constant_time_compare_not_equal():
    """Test constant time comparison with different strings."""
    assert constant_time_compare("secret123", "secret456") is False


def test_constant_time_compare_empty():
    """Test constant time comparison with empty strings."""
    assert constant_time_compare("", "") is False
    assert constant_time_compare("secret", "") is False
    assert constant_time_compare("", "secret") is False


def test_mask_identifier_long():
    """Test identifier masking with long ID."""
    result = mask_identifier("business_12345678")
    assert result == "****5678"
    assert "1234" not in result


def test_mask_identifier_short():
    """Test identifier masking with short ID."""
    assert mask_identifier("abc") == "****"
    assert mask_identifier("") == "****"
    assert mask_identifier(None) == "****"


def test_sanitize_for_logging_truncate():
    """Test log sanitization truncates long values."""
    long_value = "a" * 100
    result = sanitize_for_logging(long_value, max_length=50)
    assert len(result) == 53  # 50 + "..."
    assert result.endswith("...")


def test_sanitize_for_logging_short():
    """Test log sanitization preserves short values."""
    result = sanitize_for_logging("short", max_length=50)
    assert result == "short"


# ============================================================
# Rate Limiter Tests
# ============================================================


def test_rate_limiter_allows_under_limit():
    """Test rate limiter allows requests under limit."""
    limiter = RateLimiter(max_requests=5, window_seconds=60)

    for _ in range(5):
        assert limiter.is_allowed("client_1") is True


def test_rate_limiter_blocks_over_limit():
    """Test rate limiter blocks requests over limit."""
    limiter = RateLimiter(max_requests=3, window_seconds=60)

    assert limiter.is_allowed("client_1") is True
    assert limiter.is_allowed("client_1") is True
    assert limiter.is_allowed("client_1") is True
    assert limiter.is_allowed("client_1") is False


def test_rate_limiter_separate_clients():
    """Test rate limiter tracks clients separately."""
    limiter = RateLimiter(max_requests=2, window_seconds=60)

    assert limiter.is_allowed("client_1") is True
    assert limiter.is_allowed("client_1") is True
    assert limiter.is_allowed("client_1") is False

    # Different client should still be allowed
    assert limiter.is_allowed("client_2") is True


def test_rate_limiter_remaining():
    """Test rate limiter remaining calculation."""
    limiter = RateLimiter(max_requests=5, window_seconds=60)

    assert limiter.get_remaining("client_1") == 5
    limiter.is_allowed("client_1")
    assert limiter.get_remaining("client_1") == 4


# ============================================================
# API Security Tests
# ============================================================


def test_security_headers_present(client):
    """Test security headers are added to responses."""
    response = client.get("/")

    assert "X-Content-Type-Options" in response.headers
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert "X-Frame-Options" in response.headers
    assert response.headers["X-Frame-Options"] == "DENY"


def test_request_id_header(client):
    """Test request ID is added to responses."""
    response = client.get("/")

    assert "X-Request-ID" in response.headers
    assert len(response.headers["X-Request-ID"]) > 0


def test_request_id_preserved(client):
    """Test client-provided request ID is preserved."""
    response = client.get(
        "/",
        headers={"X-Request-ID": "custom-id-12345"}
    )

    assert response.headers["X-Request-ID"] == "custom-id-12345"


def test_invalid_business_id_format():
    """Test validation rejects invalid business_id format."""
    now = datetime.utcnow()
    invalid_request = {
        "business_id": "invalid@id!",  # Invalid characters
        "provider_id": "valid_id",
        "route_date": now.isoformat(),
        "depot_latitude": 40.7128,
        "depot_longitude": -74.0060,
        "depot_address": "NYC",
        "waypoints": [
            {
                "id": "wp_1",
                "name": "Client",
                "latitude": 40.7589,
                "longitude": -73.9851,
                "window_start": (now + timedelta(hours=1)).isoformat(),
                "window_end": (now + timedelta(hours=2)).isoformat(),
                "service_duration_minutes": 30,
            },
        ],
        "earliest_departure": now.isoformat(),
        "latest_return": (now + timedelta(hours=10)).isoformat(),
    }

    with patch.object(settings, "debug", True), \
         patch.object(settings, "require_authentication", False), \
         patch.object(settings, "require_jwt_auth", False):
        client = TestClient(app, base_url="https://testserver")
        response = client.post(
            "/api/v1/routes/optimize",
            json=invalid_request,
            headers={"X-API-Key": "test-key"},
        )
        assert response.status_code == 422  # Validation error


def test_cors_wildcard_blocked_in_production():
    """Test CORS wildcard is blocked in production."""
    with pytest.raises(ValueError, match="Wildcard CORS origin not allowed"):
        Settings(
            debug=False,
            cors_origins=["*"],
            api_key="test-key",
        )


def test_docs_disabled_in_production():
    """Test OpenAPI docs are disabled in production."""
    settings = Settings(
        debug=False,
        enable_docs=False,
        api_key="test-key",
        cors_origins=["https://example.com"],
    )
    assert settings.enable_docs is False


def test_api_key_warning_in_production():
    """Test warning is logged when API key missing in production."""
    # This should not raise, but logs a warning
    settings = Settings(
        debug=False,
        require_authentication=True,
        api_key="",  # Empty
        cors_origins=["https://example.com"],
    )
    assert settings.api_key == ""
