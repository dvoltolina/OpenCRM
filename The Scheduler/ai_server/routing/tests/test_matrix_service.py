"""Tests for matrix service."""

import pytest
from unittest.mock import patch

from ..config import settings
from ..services.matrix_service import (
    MatrixService,
    Location,
    haversine_distance,
    estimate_duration,
)
from ..services.models import DistanceMatrix, RouteLeg
from ..services.routing_providers import (
    HaversineRoutingProvider,
)
from ..services.errors import ProviderConfigurationError, ProviderUnavailableError


def test_haversine_distance():
    """Test haversine distance calculation."""
    # New York to Los Angeles (approx 3944 km)
    nyc = (40.7128, -74.0060)
    la = (34.0522, -118.2437)

    distance = haversine_distance(nyc[0], nyc[1], la[0], la[1])

    # Should be approximately 3944 km (3,944,000 meters)
    assert 3_900_000 < distance < 4_000_000


def test_haversine_same_point():
    """Test haversine returns 0 for same point."""
    distance = haversine_distance(40.7128, -74.0060, 40.7128, -74.0060)
    assert distance == 0


def test_haversine_short_distance():
    """Test haversine for short distances."""
    # Two points about 1km apart
    lat1, lon1 = 40.7128, -74.0060
    lat2, lon2 = 40.7218, -74.0060  # About 1km north

    distance = haversine_distance(lat1, lon1, lat2, lon2)

    # Should be approximately 1km
    assert 900 < distance < 1100


def test_estimate_duration():
    """Test duration estimation."""
    # 10 km at 40 km/h = 15 minutes = 900 seconds
    duration = estimate_duration(10000, 40)
    assert duration == 900


def test_estimate_duration_zero_speed():
    """Test duration with zero speed."""
    duration = estimate_duration(10000, 0)
    assert duration == 0


@pytest.mark.asyncio
async def test_build_haversine_matrix():
    """Test building matrix with haversine fallback."""
    provider = HaversineRoutingProvider(default_speed_kmh=40)

    locations = [
        Location(id="a", latitude=40.7128, longitude=-74.0060, name="NYC"),
        Location(id="b", latitude=40.7589, longitude=-73.9851, name="Midtown"),
        Location(id="c", latitude=40.6892, longitude=-74.0445, name="Brooklyn"),
    ]

    matrix = await provider.build_matrix(locations)

    assert matrix.source == "haversine"
    assert len(matrix.durations) == 3
    assert len(matrix.distances) == 3

    # Diagonal should be 0
    for i in range(3):
        assert matrix.durations[i][i] == 0
        assert matrix.distances[i][i] == 0

    # Off-diagonal should be positive
    assert matrix.durations[0][1] > 0
    assert matrix.distances[0][1] > 0


@pytest.mark.asyncio
async def test_build_matrix_osrm_fallback():
    """Test fallback to haversine when OSRM fails."""
    class FailingProvider:
        name = "failing"

        async def build_matrix(self, *_args, **_kwargs):
            raise ProviderUnavailableError("OSRM unavailable")

        async def get_route(self, *_args, **_kwargs):
            raise ProviderUnavailableError("OSRM unavailable")

    service = MatrixService(
        providers=[
            FailingProvider(),
            HaversineRoutingProvider(default_speed_kmh=40),
        ]
    )

    locations = [
        Location(id="a", latitude=40.7128, longitude=-74.0060, name="A"),
        Location(id="b", latitude=40.7589, longitude=-73.9851, name="B"),
    ]

    matrix = await service.build_matrix(locations)

    assert matrix.source == "haversine"
    assert len(matrix.durations) == 2


@pytest.mark.asyncio
async def test_build_matrix_empty():
    """Test building matrix with empty locations."""
    with patch.object(settings, "routing_provider", "haversine"):
        service = MatrixService()
        matrix = await service.build_matrix([], departure_time=None)

    assert matrix.source == "empty"
    assert len(matrix.locations) == 0
    assert len(matrix.durations) == 0


@pytest.mark.asyncio
async def test_get_single_route_fallback():
    """Test single route with haversine fallback."""
    class FailingProvider:
        name = "failing"

        async def build_matrix(self, *_args, **_kwargs):
            raise ProviderUnavailableError("OSRM unavailable")

        async def get_route(self, *_args, **_kwargs):
            raise ProviderUnavailableError("OSRM unavailable")

    service = MatrixService(
        providers=[
            FailingProvider(),
            HaversineRoutingProvider(default_speed_kmh=40),
        ]
    )

    from_loc = Location(id="a", latitude=40.7128, longitude=-74.0060, name="A")
    to_loc = Location(id="b", latitude=40.7589, longitude=-73.9851, name="B")

    leg = await service.get_single_route(from_loc, to_loc)

    assert leg.distance_meters > 0
    assert leg.duration_seconds > 0
    assert leg.polyline is None  # No polyline in fallback


@pytest.mark.asyncio
async def test_build_matrix_missing_key_fallback():
    """Provider configuration errors should fall back."""

    class MissingKeyProvider:
        name = "google_routes"

        async def build_matrix(self, *_args, **_kwargs):
            raise ProviderConfigurationError("missing key")

        async def get_route(self, *_args, **_kwargs):
            raise ProviderConfigurationError("missing key")

    service = MatrixService(
        providers=[
            MissingKeyProvider(),
            HaversineRoutingProvider(default_speed_kmh=40),
        ]
    )

    locations = [
        Location(id="a", latitude=0.0, longitude=0.0, name="A"),
        Location(id="b", latitude=1.0, longitude=1.0, name="B"),
    ]

    matrix = await service.build_matrix(locations)

    assert matrix.source == "haversine"


@pytest.mark.asyncio
async def test_matrix_symmetry():
    """Test that haversine matrix is symmetric."""
    provider = HaversineRoutingProvider(default_speed_kmh=40)

    locations = [
        Location(id="a", latitude=40.7128, longitude=-74.0060, name="A"),
        Location(id="b", latitude=40.7589, longitude=-73.9851, name="B"),
    ]

    matrix = await provider.build_matrix(locations)

    # Matrix should be symmetric
    assert matrix.distances[0][1] == matrix.distances[1][0]
    assert matrix.durations[0][1] == matrix.durations[1][0]


@pytest.mark.asyncio
async def test_matrix_service_prefers_preferred_source_for_route():
    """Preferred source should be attempted first for legs."""

    class StubProvider:
        name = "stub"

        async def build_matrix(self, locations, *_args, **_kwargs):
            return DistanceMatrix(
                locations=locations,
                durations=[[0, 1], [1, 0]],
                distances=[[0, 1], [1, 0]],
                source=self.name,
            )

        async def get_route(self, *_args, **_kwargs):
            return RouteLeg(
                distance_meters=111,
                duration_seconds=222,
                polyline="xyz",
                source=self.name,
            )

    fallback = HaversineRoutingProvider(default_speed_kmh=40)
    service = MatrixService(providers=[fallback, StubProvider()])

    from_loc = Location(id="a", latitude=0.0, longitude=0.0, name="A")
    to_loc = Location(id="b", latitude=1.0, longitude=1.0, name="B")

    leg = await service.get_single_route(
        from_loc, to_loc, preferred_source="stub"
    )

    assert leg.source == "stub"
    assert leg.polyline == "xyz"
