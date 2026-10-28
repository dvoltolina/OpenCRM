"""Google Routes Preferred API client (matrix + directions)."""

import json
import logging
from datetime import datetime, timezone
from typing import List, Optional

import httpx

from ..config import settings
from .errors import ProviderConfigurationError, ProviderUnavailableError
from .models import DistanceMatrix, Location, RouteLeg

logger = logging.getLogger(__name__)


class GoogleRoutesClient:
    """Client for Google Routes Preferred API."""

    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        region_code: Optional[str] = None,
        timeout_seconds: Optional[int] = None,
        traffic_model: Optional[str] = None,
        http_client: Optional[httpx.AsyncClient] = None,
    ):
        self.api_key = api_key or settings.google_routes_api_key
        self.base_url = (base_url or settings.google_routes_base_url).rstrip("/")
        self.region_code = region_code or settings.google_routes_region_code
        self.timeout = timeout_seconds or settings.google_routes_timeout_seconds
        self.traffic_model = traffic_model or settings.google_routes_traffic_model
        self._client = http_client

        if not self.base_url.startswith("https://"):
            raise ProviderConfigurationError("Google Routes requires HTTPS base URL")

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(self.timeout),
                limits=httpx.Limits(max_connections=10, max_keepalive_connections=5),
            )
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def compute_matrix(
        self,
        locations: List[Location],
        departure_time: Optional[datetime] = None,
    ) -> DistanceMatrix:
        """Compute time/distance matrix."""
        if not self.api_key:
            raise ProviderConfigurationError("Google Routes API key is not configured")

        client = await self._get_client()
        url = f"{self.base_url}/distanceMatrix/v2:computeRouteMatrix"

        waypoint_payload = [
            {
                "waypoint": {
                    "location": {
                        "latLng": {
                            "latitude": loc.latitude,
                            "longitude": loc.longitude,
                        }
                    }
                }
            }
            for loc in locations
        ]

        body = {
            "origins": waypoint_payload,
            "destinations": waypoint_payload,
            "travelMode": "DRIVE",
            "routingPreference": self.traffic_model or "TRAFFIC_AWARE",
        }

        if departure_time:
            body["departureTime"] = self._format_time(departure_time)

        if self.region_code:
            body["regionCode"] = self.region_code

        headers = {
            "X-Goog-Api-Key": self.api_key,
            # Only request fields we map to avoid PHI and reduce payload size
            "X-Goog-FieldMask": "originIndex,destinationIndex,distanceMeters,duration,condition",
        }

        try:
            response = await client.post(url, headers=headers, json=body)
            response.raise_for_status()
        except Exception as exc:
            raise ProviderUnavailableError(f"Google Routes matrix request failed: {exc}") from exc

        try:
            durations, distances = self._parse_matrix_response(
                response.text, len(locations)
            )
        except Exception as exc:
            raise ProviderUnavailableError(f"Unable to parse Google Routes matrix: {exc}") from exc

        return DistanceMatrix(
            locations=locations,
            durations=durations,
            distances=distances,
            source="google_routes",
        )

    async def get_directions(
        self,
        origin: Location,
        destination: Location,
        departure_time: Optional[datetime] = None,
    ) -> RouteLeg:
        """Get a single leg directions result with polyline."""
        if not self.api_key:
            raise ProviderConfigurationError("Google Routes API key is not configured")

        client = await self._get_client()
        url = f"{self.base_url}/directions/v2:computeRoutes"

        body = {
            "origin": {
                "location": {
                    "latLng": {
                        "latitude": origin.latitude,
                        "longitude": origin.longitude,
                    }
                }
            },
            "destination": {
                "location": {
                    "latLng": {
                        "latitude": destination.latitude,
                        "longitude": destination.longitude,
                    }
                }
            },
            "travelMode": "DRIVE",
            "routingPreference": self.traffic_model or "TRAFFIC_AWARE",
            "computeAlternativeRoutes": False,
            "optimizeWaypointOrder": False,
            "polylineQuality": "HIGH_QUALITY",
            "polylineEncoding": "ENCODED_POLYLINE",
        }

        if departure_time:
            body["departureTime"] = self._format_time(departure_time)
        if self.region_code:
            body["regionCode"] = self.region_code

        headers = {
            "X-Goog-Api-Key": self.api_key,
            "X-Goog-FieldMask": (
                "routes.distanceMeters,routes.duration,"
                "routes.travelAdvisory,routes.polyline.encodedPolyline"
            ),
        }

        try:
            response = await client.post(url, headers=headers, json=body)
            response.raise_for_status()
        except Exception as exc:
            raise ProviderUnavailableError(f"Google Routes directions failed: {exc}") from exc

        try:
            data = response.json()
            route = (data.get("routes") or [{}])[0]
            distance = int(route.get("distanceMeters") or 0)
            duration_seconds = self._parse_duration(
                route.get("duration") or route.get("travelDuration")
            )
            polyline = None
            if route.get("polyline"):
                polyline = route["polyline"].get("encodedPolyline")
        except Exception as exc:
            raise ProviderUnavailableError(f"Unable to parse directions response: {exc}") from exc

        return RouteLeg(
            distance_meters=distance,
            duration_seconds=duration_seconds,
            polyline=polyline,
            source="google_routes",
        )

    def _parse_matrix_response(
        self,
        raw_text: str,
        location_count: int,
    ) -> (List[List[int]], List[List[int]]):
        """Parse NDJSON or JSON array matrix response."""
        durations = [[999999] * location_count for _ in range(location_count)]
        distances = [[999999] * location_count for _ in range(location_count)]

        elements = []
        cleaned = raw_text.strip()
        if not cleaned:
            return durations, distances

        if cleaned.startswith("["):
            elements = json.loads(cleaned)
        else:
            for line in cleaned.splitlines():
                line = line.strip()
                if not line:
                    continue
                elements.append(json.loads(line))

        for element in elements:
            origin_idx = element.get("originIndex")
            dest_idx = element.get("destinationIndex")
            if origin_idx is None or dest_idx is None:
                continue

            distance = int(element.get("distanceMeters") or 0)
            duration_seconds = self._parse_duration(
                element.get("duration") or element.get("travelDuration")
            )

            condition = (element.get("condition") or "").upper()
            if condition and condition != "ROUTE_EXISTS":
                # Treat non-existent routes as very large costs
                distance = 999999
                duration_seconds = 999999

            durations[origin_idx][dest_idx] = duration_seconds
            distances[origin_idx][dest_idx] = distance

        for idx in range(location_count):
            durations[idx][idx] = 0
            distances[idx][idx] = 0

        return durations, distances

    def _parse_duration(self, value: Optional[str]) -> int:
        """Convert Google duration strings (e.g., '123.4s') to int seconds."""
        if not value:
            return 0
        try:
            if isinstance(value, (int, float)):
                return int(value)
            if isinstance(value, str) and value.endswith("s"):
                value = value[:-1]
            return int(float(value))
        except Exception:
            return 0

    def _format_time(self, dt: datetime) -> str:
        """Format datetime to RFC3339 string expected by Google APIs."""
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
