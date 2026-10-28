"""Routing provider implementations (Google Routes, OSRM, Haversine)."""

import logging
import math
from typing import List, Optional

from .errors import ProviderUnavailableError
from .google_routes_client import GoogleRoutesClient
from .models import DistanceMatrix, Location, RouteLeg
from .osrm_client import OSRMClient, get_osrm_client

logger = logging.getLogger(__name__)


# ============================================================
# Helper functions
# ============================================================

def haversine_distance(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Calculate haversine distance between two points in meters."""
    R = 6371000  # Earth's radius in meters

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def estimate_duration(distance_meters: float, speed_kmh: int) -> int:
    """Estimate travel duration from distance and speed."""
    speed_ms = speed_kmh * 1000 / 3600  # Convert to m/s
    return int(distance_meters / speed_ms) if speed_ms > 0 else 0


# ============================================================
# Provider base
# ============================================================

class RoutingProvider:
    """Base class for routing providers."""

    name: str = "base"

    async def build_matrix(
        self,
        locations: List[Location],
        departure_time=None,
    ) -> DistanceMatrix:  # pragma: no cover - interface
        raise NotImplementedError

    async def get_route(
        self,
        origin: Location,
        destination: Location,
        departure_time=None,
    ) -> RouteLeg:  # pragma: no cover - interface
        raise NotImplementedError


# ============================================================
# Google Routes Provider
# ============================================================

class GoogleRoutesProvider(RoutingProvider):
    """Provider backed by Google Routes Preferred API."""

    name = "google_routes"

    def __init__(self, client: Optional[GoogleRoutesClient] = None):
        self.client = client or GoogleRoutesClient()

    async def build_matrix(
        self,
        locations: List[Location],
        departure_time=None,
    ) -> DistanceMatrix:
        return await self.client.compute_matrix(locations, departure_time)

    async def get_route(
        self,
        origin: Location,
        destination: Location,
        departure_time=None,
    ) -> RouteLeg:
        return await self.client.get_directions(origin, destination, departure_time)


# ============================================================
# OSRM Provider
# ============================================================

class OsrmRoutingProvider(RoutingProvider):
    """Provider backed by OSRM."""

    name = "osrm"

    def __init__(self, osrm_client: Optional[OSRMClient] = None):
        self.osrm_client = osrm_client or get_osrm_client()

    async def build_matrix(
        self,
        locations: List[Location],
        departure_time=None,  # Unused but kept for interface parity
    ) -> DistanceMatrix:
        # OSRM expects (lon, lat)
        coordinates = [(loc.longitude, loc.latitude) for loc in locations]
        result = await self.osrm_client.get_table(coordinates)

        durations = [
            [int(d) if d is not None else 999999 for d in row]
            for row in result.durations
        ]
        distances = [
            [int(d) if d is not None else 999999 for d in row]
            for row in result.distances
        ]

        return DistanceMatrix(
            locations=locations,
            durations=durations,
            distances=distances,
            source="osrm",
        )

    async def get_route(
        self,
        origin: Location,
        destination: Location,
        departure_time=None,  # Unused but kept for interface parity
    ) -> RouteLeg:
        result = await self.osrm_client.get_route([
            (origin.longitude, origin.latitude),
            (destination.longitude, destination.latitude),
        ])
        return RouteLeg(
            distance_meters=int(result.distance),
            duration_seconds=int(result.duration),
            polyline=result.geometry,
            source="osrm",
        )


# ============================================================
# Haversine Provider (fallback)
# ============================================================

class HaversineRoutingProvider(RoutingProvider):
    """Fallback provider using haversine estimation."""

    name = "haversine"

    def __init__(self, default_speed_kmh: int):
        self.default_speed_kmh = default_speed_kmh

    async def build_matrix(
        self,
        locations: List[Location],
        departure_time=None,
    ) -> DistanceMatrix:
        n = len(locations)
        durations = [[0] * n for _ in range(n)]
        distances = [[0] * n for _ in range(n)]

        for i in range(n):
            for j in range(n):
                if i == j:
                    continue
                dist = haversine_distance(
                    locations[i].latitude,
                    locations[i].longitude,
                    locations[j].latitude,
                    locations[j].longitude,
                )
                dist = int(dist * 1.3)  # road factor
                distances[i][j] = dist
                durations[i][j] = estimate_duration(dist, self.default_speed_kmh)

        return DistanceMatrix(
            locations=locations,
            durations=durations,
            distances=distances,
            source=self.name,
        )

    async def get_route(
        self,
        origin: Location,
        destination: Location,
        departure_time=None,
    ) -> RouteLeg:
        dist = haversine_distance(
            origin.latitude, origin.longitude,
            destination.latitude, destination.longitude,
        )
        dist = int(dist * 1.3)
        duration = estimate_duration(dist, self.default_speed_kmh)
        return RouteLeg(
            distance_meters=dist,
            duration_seconds=duration,
            polyline=None,
            source=self.name,
        )
