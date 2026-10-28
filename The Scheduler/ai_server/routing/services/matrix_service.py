"""
Distance/Time Matrix Service.

REQUIREMENTS:
1. Build matrices from OSRM or fallback to haversine
2. Cache results for performance
3. Handle OSRM failures gracefully
"""

import logging
from typing import List, Optional

from .errors import ProviderConfigurationError, ProviderUnavailableError
from .models import DistanceMatrix, Location, RouteLeg
from .routing_providers import (
    GoogleRoutesProvider,
    HaversineRoutingProvider,
    OsrmRoutingProvider,
    estimate_duration,
    haversine_distance,
)
from ..config import settings

logger = logging.getLogger(__name__)


class MatrixService:
    """
    Service for building distance/duration matrices.

    Attempts to use configured provider (Google Routes or OSRM),
    falls back to haversine estimates when providers are unavailable.
    """

    def __init__(self, providers: Optional[List] = None):
        self.default_speed_kmh = settings.default_vehicle_speed_kmh
        self.providers = providers or self._build_providers()

    def _build_providers(self) -> List:
        """Build provider chain with fallbacks."""
        chain: List = []
        provider_name = (settings.routing_provider or "osrm").lower()

        if provider_name == "google":
            chain.append(GoogleRoutesProvider())
            chain.append(OsrmRoutingProvider())
        elif provider_name == "osrm":
            chain.append(OsrmRoutingProvider())
        elif provider_name == "haversine":
            # No primary network provider; haversine added below
            pass
        else:
            logger.warning(
                "Unknown routing_provider '%s'; defaulting to OSRM", provider_name
            )
            chain.append(OsrmRoutingProvider())

        chain.append(HaversineRoutingProvider(self.default_speed_kmh))
        return chain

    async def build_matrix(
        self,
        locations: List[Location],
        departure_time: Optional = None,
    ) -> DistanceMatrix:
        """
        Build distance/duration matrix for locations.

        Args:
            locations: List of locations to include
            departure_time: Optional departure time for traffic-aware providers

        Returns:
            DistanceMatrix with durations and distances
        """
        n = len(locations)

        if n == 0:
            return DistanceMatrix(
                locations=[],
                durations=[],
                distances=[],
                source="empty",
            )

        for provider in self.providers:
            try:
                matrix = await provider.build_matrix(locations, departure_time)
                return matrix
            except ProviderConfigurationError as exc:
                logger.warning(
                    "Routing provider %s configuration error: %s",
                    provider.name,
                    exc,
                )
            except ProviderUnavailableError as exc:
                logger.warning(
                    "Routing provider %s unavailable: %s",
                    provider.name,
                    exc,
                )
            except Exception as exc:
                logger.warning(
                    "Routing provider %s failed, falling back: %s",
                    provider.name,
                    exc,
                )

        # Should never reach here because haversine provider is always last, but keep
        fallback = HaversineRoutingProvider(self.default_speed_kmh)
        return await fallback.build_matrix(locations, departure_time)

    async def get_single_route(
        self,
        from_loc: Location,
        to_loc: Location,
        preferred_source: Optional[str] = None,
        departure_time: Optional = None,
    ) -> RouteLeg:
        """
        Get distance, duration, and polyline for a single route.

        Returns:
            RouteLeg with distance, duration, polyline, and source
        """
        provider_order = self._order_providers(preferred_source)

        for provider in provider_order:
            try:
                return await provider.get_route(from_loc, to_loc, departure_time)
            except (ProviderUnavailableError, ProviderConfigurationError):
                continue
            except Exception:
                continue

        fallback = HaversineRoutingProvider(self.default_speed_kmh)
        return await fallback.get_route(from_loc, to_loc, departure_time)

    def _order_providers(self, preferred_source: Optional[str]) -> List:
        """Order providers placing preferred provider first when available."""
        if not preferred_source:
            return self.providers

        preferred = []
        others = []
        for provider in self.providers:
            if provider.name == preferred_source:
                preferred.append(provider)
            else:
                others.append(provider)
        return preferred + others


# Singleton
_matrix_service: Optional[MatrixService] = None


def get_matrix_service() -> MatrixService:
    """Get singleton matrix service instance."""
    global _matrix_service
    if _matrix_service is None:
        _matrix_service = MatrixService()
    return _matrix_service
