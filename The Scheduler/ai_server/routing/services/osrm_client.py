"""
OSRM (Open Source Routing Machine) API client.

REQUIREMENTS:
1. Call OSRM /table endpoint for distance/duration matrices
2. Call OSRM /route endpoint for polylines (optional)
3. Handle errors gracefully with fallback to haversine
4. Support connection pooling for performance
"""

import logging
from typing import Optional, List, Tuple

import httpx
from dataclasses import dataclass

from ..config import settings

logger = logging.getLogger(__name__)


@dataclass
class OSRMTableResult:
    """Result from OSRM table query."""
    durations: List[List[float]]  # seconds
    distances: List[List[float]]  # meters
    sources: List[dict]
    destinations: List[dict]


@dataclass
class OSRMRouteResult:
    """Result from OSRM route query."""
    distance: float  # meters
    duration: float  # seconds
    geometry: str  # encoded polyline


class OSRMClient:
    """
    Client for OSRM routing service.

    OSRM provides fast routing for OpenStreetMap data.
    We use the /table endpoint for distance matrices and
    /route endpoint for individual route polylines.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: Optional[int] = None,
        max_coordinates: Optional[int] = None,
    ):
        self.base_url = (base_url or settings.osrm_url).rstrip("/")
        self.timeout = timeout or settings.osrm_timeout_seconds
        self.max_coordinates = max_coordinates or settings.osrm_max_coordinates
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        """Get or create HTTP client with connection pooling."""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(self.timeout),
                limits=httpx.Limits(max_connections=10, max_keepalive_connections=5),
            )
        return self._client

    async def close(self) -> None:
        """Close the HTTP client."""
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def health_check(self) -> bool:
        """Check if OSRM server is reachable."""
        try:
            client = await self._get_client()
            # Simple route request to check connectivity
            response = await client.get(
                f"{self.base_url}/route/v1/driving/-74.005,40.7128;-73.985,40.758",
                timeout=5.0,
            )
            return response.status_code == 200
        except Exception as e:
            logger.warning(f"OSRM health check failed: {e}")
            return False

    async def get_table(
        self,
        coordinates: List[Tuple[float, float]],
        sources: Optional[List[int]] = None,
        destinations: Optional[List[int]] = None,
    ) -> OSRMTableResult:
        """
        Get distance/duration matrix for coordinates.

        Args:
            coordinates: List of (longitude, latitude) tuples
            sources: Indices of source locations (default: all)
            destinations: Indices of destination locations (default: all)

        Returns:
            OSRMTableResult with durations and distances matrices

        Raises:
            ValueError: If too many coordinates
            httpx.HTTPError: If OSRM request fails
        """
        if len(coordinates) > self.max_coordinates:
            raise ValueError(
                f"Too many coordinates: {len(coordinates)} > {self.max_coordinates}"
            )

        # Build coordinate string (lon,lat;lon,lat;...)
        coord_str = ";".join(f"{lon},{lat}" for lon, lat in coordinates)
        url = f"{self.base_url}/table/v1/driving/{coord_str}"

        params = {
            "annotations": "duration,distance",
        }

        if sources is not None:
            params["sources"] = ";".join(str(i) for i in sources)
        if destinations is not None:
            params["destinations"] = ";".join(str(i) for i in destinations)

        client = await self._get_client()
        response = await client.get(url, params=params)
        response.raise_for_status()

        data = response.json()

        if data.get("code") != "Ok":
            raise ValueError(f"OSRM error: {data.get('message', 'Unknown error')}")

        return OSRMTableResult(
            durations=data["durations"],
            distances=data["distances"],
            sources=data.get("sources", []),
            destinations=data.get("destinations", []),
        )

    async def get_route(
        self,
        coordinates: List[Tuple[float, float]],
        overview: str = "simplified",
    ) -> OSRMRouteResult:
        """
        Get route between coordinates with geometry.

        Args:
            coordinates: List of (longitude, latitude) tuples
            overview: Geometry detail level (full, simplified, false)

        Returns:
            OSRMRouteResult with distance, duration, and polyline
        """
        coord_str = ";".join(f"{lon},{lat}" for lon, lat in coordinates)
        url = f"{self.base_url}/route/v1/driving/{coord_str}"

        params = {
            "overview": overview,
            "geometries": "polyline",
        }

        client = await self._get_client()
        response = await client.get(url, params=params)
        response.raise_for_status()

        data = response.json()

        if data.get("code") != "Ok":
            raise ValueError(f"OSRM error: {data.get('message', 'Unknown error')}")

        route = data["routes"][0]
        return OSRMRouteResult(
            distance=route["distance"],
            duration=route["duration"],
            geometry=route.get("geometry", ""),
        )


# Singleton instance
_osrm_client: Optional[OSRMClient] = None


def get_osrm_client() -> OSRMClient:
    """Get singleton OSRM client instance."""
    global _osrm_client
    if _osrm_client is None:
        _osrm_client = OSRMClient()
    return _osrm_client
