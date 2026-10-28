"""Tests for OSRM client."""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock

import httpx

from ..services.osrm_client import OSRMClient, OSRMTableResult


@pytest.fixture
def osrm_client():
    return OSRMClient(base_url="http://test-osrm:5000", timeout=10)


@pytest.mark.asyncio
async def test_health_check_success(osrm_client):
    """Test successful health check."""
    mock_response = MagicMock()
    mock_response.status_code = 200

    with patch.object(osrm_client, "_get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        result = await osrm_client.health_check()
        assert result is True


@pytest.mark.asyncio
async def test_health_check_failure(osrm_client):
    """Test failed health check."""
    with patch.object(osrm_client, "_get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get.side_effect = httpx.ConnectError("Connection refused")
        mock_get_client.return_value = mock_client

        result = await osrm_client.health_check()
        assert result is False


@pytest.mark.asyncio
async def test_get_table_success(osrm_client):
    """Test successful table query."""
    mock_response_data = {
        "code": "Ok",
        "durations": [[0, 100, 200], [100, 0, 150], [200, 150, 0]],
        "distances": [[0, 1000, 2000], [1000, 0, 1500], [2000, 1500, 0]],
        "sources": [],
        "destinations": [],
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_response_data
    mock_response.raise_for_status = MagicMock()

    with patch.object(osrm_client, "_get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        coordinates = [(-74.0, 40.7), (-74.1, 40.8), (-74.2, 40.9)]
        result = await osrm_client.get_table(coordinates)

        assert isinstance(result, OSRMTableResult)
        assert len(result.durations) == 3
        assert len(result.distances) == 3


@pytest.mark.asyncio
async def test_get_table_too_many_coordinates(osrm_client):
    """Test error when too many coordinates."""
    osrm_client.max_coordinates = 5
    coordinates = [(-74.0 + i * 0.1, 40.7 + i * 0.1) for i in range(10)]

    with pytest.raises(ValueError, match="Too many coordinates"):
        await osrm_client.get_table(coordinates)


@pytest.mark.asyncio
async def test_get_table_osrm_error(osrm_client):
    """Test OSRM error response."""
    mock_response_data = {
        "code": "InvalidQuery",
        "message": "Invalid coordinates",
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_response_data
    mock_response.raise_for_status = MagicMock()

    with patch.object(osrm_client, "_get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        coordinates = [(-74.0, 40.7), (-74.1, 40.8)]
        with pytest.raises(ValueError, match="OSRM error"):
            await osrm_client.get_table(coordinates)


@pytest.mark.asyncio
async def test_get_route_success(osrm_client):
    """Test successful route query."""
    mock_response_data = {
        "code": "Ok",
        "routes": [
            {
                "distance": 5000,
                "duration": 600,
                "geometry": "encoded_polyline_data",
            }
        ],
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_response_data
    mock_response.raise_for_status = MagicMock()

    with patch.object(osrm_client, "_get_client") as mock_get_client:
        mock_client = AsyncMock()
        mock_client.get.return_value = mock_response
        mock_get_client.return_value = mock_client

        coordinates = [(-74.0, 40.7), (-74.1, 40.8)]
        result = await osrm_client.get_route(coordinates)

        assert result.distance == 5000
        assert result.duration == 600
        assert result.geometry == "encoded_polyline_data"


@pytest.mark.asyncio
async def test_close_client(osrm_client):
    """Test closing the HTTP client."""
    mock_client = AsyncMock()
    mock_client.is_closed = False
    osrm_client._client = mock_client

    await osrm_client.close()

    mock_client.aclose.assert_called_once()
