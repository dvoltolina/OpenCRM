"""Tests for Google Routes client + provider parsing."""

import pytest

from ..services.google_routes_client import GoogleRoutesClient
from ..services.errors import ProviderConfigurationError
from ..services.models import Location


class MockResponse:
    def __init__(self, text="", status_code=200, json_data=None):
        self.text = text
        self.status_code = status_code
        self._json = json_data

    def raise_for_status(self):
        if self.status_code >= 400:
            raise Exception("HTTP error")

    def json(self):
        return self._json


class MockAsyncClient:
    def __init__(self, response):
        self.response = response
        self.is_closed = False
        self.last_request = None

    async def post(self, url, headers=None, json=None):
        self.last_request = {"url": url, "headers": headers, "json": json}
        return self.response

    async def aclose(self):
        self.is_closed = True


@pytest.mark.asyncio
async def test_google_routes_matrix_parsing_ndjson():
    """Verify NDJSON matrix responses are parsed correctly."""
    raw = "\n".join([
        '{"originIndex":0,"destinationIndex":1,"distanceMeters":1200,"duration":"600s"}',
        '{"originIndex":1,"destinationIndex":0,"distanceMeters":1300,"duration":"650s"}',
    ])
    mock_client = MockAsyncClient(MockResponse(text=raw))

    client = GoogleRoutesClient(
        api_key="test-key",
        http_client=mock_client,
    )

    locations = [
        Location(id="a", latitude=1.0, longitude=2.0),
        Location(id="b", latitude=3.0, longitude=4.0),
    ]

    matrix = await client.compute_matrix(locations)

    assert matrix.source == "google_routes"
    assert matrix.distances[0][1] == 1200
    assert matrix.durations[0][1] == 600
    assert matrix.distances[1][0] == 1300
    assert matrix.durations[1][0] == 650
    assert mock_client.last_request["url"].endswith("computeRouteMatrix")
    assert mock_client.last_request["headers"]["X-Goog-Api-Key"] == "test-key"


@pytest.mark.asyncio
async def test_google_routes_directions_parsing():
    """Verify directions payload is parsed to RouteLeg."""
    response_json = {
        "routes": [
            {
                "distanceMeters": 900,
                "duration": "500s",
                "polyline": {"encodedPolyline": "abc123"},
            }
        ]
    }
    mock_client = MockAsyncClient(MockResponse(json_data=response_json))
    client = GoogleRoutesClient(api_key="key", http_client=mock_client)

    origin = Location(id="a", latitude=1.0, longitude=2.0)
    dest = Location(id="b", latitude=3.0, longitude=4.0)

    leg = await client.get_directions(origin, dest)

    assert leg.distance_meters == 900
    assert leg.duration_seconds == 500
    assert leg.polyline == "abc123"
    assert leg.source == "google_routes"
    assert mock_client.last_request["url"].endswith("computeRoutes")


def test_google_routes_requires_https():
    """Ensure non-HTTPS endpoints are rejected."""
    with pytest.raises(ProviderConfigurationError):
        GoogleRoutesClient(api_key="key", base_url="http://routes.googleapis.com")


@pytest.mark.asyncio
async def test_google_routes_missing_key():
    """Missing API key should raise configuration error."""
    client = GoogleRoutesClient(api_key=None, http_client=MockAsyncClient(MockResponse()))
    locations = [Location(id="a", latitude=0.0, longitude=0.0)]

    with pytest.raises(ProviderConfigurationError):
        await client.compute_matrix(locations)
