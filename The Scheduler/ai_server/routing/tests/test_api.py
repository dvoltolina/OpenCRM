"""Tests for API endpoints."""

import pytest
import jwt
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from unittest.mock import patch

from ..app import app
from ..config import settings


def _build_jwt(business_id: str = "biz_123", user_id: str = "user_123") -> str:
    """Create a signed JWT for testing."""
    return jwt.encode(
        {"businessId": business_id, "sub": user_id},
        "test-secret",
        algorithm="HS256",
    )


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app, base_url="https://testserver")


@pytest.fixture
def sample_optimize_request():
    """Sample optimization request body."""
    now = datetime.utcnow()
    return {
        "business_id": "biz_123",
        "provider_id": "provider_456",
        "route_date": now.isoformat(),
        "depot_latitude": 40.7128,
        "depot_longitude": -74.0060,
        "depot_address": "New York, NY",
        "waypoints": [
            {
                "id": "wp_1",
                "name": "Client A",
                "latitude": 40.7589,
                "longitude": -73.9851,
                "window_start": (now + timedelta(hours=1)).isoformat(),
                "window_end": (now + timedelta(hours=2)).isoformat(),
                "service_duration_minutes": 30,
            },
            {
                "id": "wp_2",
                "name": "Client B",
                "latitude": 40.7484,
                "longitude": -73.9857,
                "window_start": (now + timedelta(hours=2)).isoformat(),
                "window_end": (now + timedelta(hours=3)).isoformat(),
                "service_duration_minutes": 45,
            },
        ],
        "earliest_departure": now.isoformat(),
        "latest_return": (now + timedelta(hours=10)).isoformat(),
    }


def test_health_check(client):
    """Test basic health endpoint."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_root_endpoint(client):
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200

    data = response.json()
    assert "service" in data
    assert "version" in data


def test_optimize_missing_api_key(client, sample_optimize_request):
    """Test optimization fails without bearer token in production mode."""
    with patch.multiple(
        settings,
        debug=False,
        require_authentication=True,
        require_jwt_auth=True,
        allow_api_key_fallback=False,
        jwt_secret="test-secret",
        jwt_public_key=None,
    ):
        response = client.post(
            "/api/v1/routes/optimize",
            json=sample_optimize_request,
            headers={"X-Business-ID": "biz_123"},
        )
        assert response.status_code == 401


def test_optimize_with_jwt(client, sample_optimize_request):
    """Test optimization with valid JWT + business header."""
    token = _build_jwt()
    with patch.multiple(
        settings,
        debug=False,
        require_authentication=True,
        require_jwt_auth=True,
        allow_api_key_fallback=False,
        jwt_secret="test-secret",
        jwt_public_key=None,
    ):
        response = client.post(
            "/api/v1/routes/optimize",
            json=sample_optimize_request,
            headers={
                "Authorization": f"Bearer {token}",
                "X-Business-ID": "biz_123",
            },
        )
        # May fail on actual optimization but auth should pass
        assert response.status_code in [200, 400, 500]


def test_optimize_debug_mode(client, sample_optimize_request):
    """Test optimization in debug mode (no API key required)."""
    with patch.multiple(
        settings,
        debug=True,
        require_authentication=False,
    ):
        response = client.post(
            "/api/v1/routes/optimize",
            json=sample_optimize_request,
        )
        # Should not fail on auth
        assert response.status_code in [200, 400, 500]


def test_optimize_invalid_coordinates(client):
    """Test validation of invalid coordinates."""
    now = datetime.utcnow()
    invalid_request = {
        "business_id": "biz",
        "provider_id": "prov",
        "route_date": now.isoformat(),
        "depot_latitude": 999,  # Invalid
        "depot_longitude": -74.0060,
        "depot_address": "Invalid",
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

    with patch.multiple(
        settings,
        debug=True,
        require_authentication=False,
    ):
        response = client.post("/api/v1/routes/optimize", json=invalid_request)
        assert response.status_code == 422  # Validation error


def test_optimize_invalid_time_window(client):
    """Test validation of invalid time windows."""
    now = datetime.utcnow()
    invalid_request = {
        "business_id": "biz",
        "provider_id": "prov",
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
                "window_start": (now + timedelta(hours=2)).isoformat(),
                "window_end": (now + timedelta(hours=1)).isoformat(),  # End before start
                "service_duration_minutes": 30,
            },
        ],
        "earliest_departure": now.isoformat(),
        "latest_return": (now + timedelta(hours=10)).isoformat(),
    }

    with patch.multiple(
        settings,
        debug=True,
        require_authentication=False,
    ):
        response = client.post("/api/v1/routes/optimize", json=invalid_request)
        assert response.status_code == 422  # Validation error


def test_optimize_duplicate_waypoint_ids(client):
    """Test validation of duplicate waypoint IDs."""
    now = datetime.utcnow()
    invalid_request = {
        "business_id": "biz",
        "provider_id": "prov",
        "route_date": now.isoformat(),
        "depot_latitude": 40.7128,
        "depot_longitude": -74.0060,
        "depot_address": "NYC",
        "waypoints": [
            {
                "id": "wp_1",  # Duplicate ID
                "name": "Client A",
                "latitude": 40.7589,
                "longitude": -73.9851,
                "window_start": (now + timedelta(hours=1)).isoformat(),
                "window_end": (now + timedelta(hours=2)).isoformat(),
                "service_duration_minutes": 30,
            },
            {
                "id": "wp_1",  # Duplicate ID
                "name": "Client B",
                "latitude": 40.7484,
                "longitude": -73.9857,
                "window_start": (now + timedelta(hours=2)).isoformat(),
                "window_end": (now + timedelta(hours=3)).isoformat(),
                "service_duration_minutes": 30,
            },
        ],
        "earliest_departure": now.isoformat(),
        "latest_return": (now + timedelta(hours=10)).isoformat(),
    }

    with patch.multiple(
        settings,
        debug=True,
        require_authentication=False,
    ):
        response = client.post("/api/v1/routes/optimize", json=invalid_request)
        assert response.status_code == 422  # Validation error


def test_optimize_empty_waypoints(client):
    """Test validation of empty waypoints list."""
    now = datetime.utcnow()
    invalid_request = {
        "business_id": "biz",
        "provider_id": "prov",
        "route_date": now.isoformat(),
        "depot_latitude": 40.7128,
        "depot_longitude": -74.0060,
        "depot_address": "NYC",
        "waypoints": [],  # Empty
        "earliest_departure": now.isoformat(),
        "latest_return": (now + timedelta(hours=10)).isoformat(),
    }

    with patch.multiple(
        settings,
        debug=True,
        require_authentication=False,
    ):
        response = client.post("/api/v1/routes/optimize", json=invalid_request)
        assert response.status_code == 422  # Validation error
