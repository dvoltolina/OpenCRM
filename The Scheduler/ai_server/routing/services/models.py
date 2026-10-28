"""Shared routing service models."""

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class Location:
    """A geographic location."""
    id: str
    latitude: float
    longitude: float
    name: str = ""


@dataclass
class DistanceMatrix:
    """Distance and duration matrix between locations."""
    locations: List[Location]
    durations: List[List[int]]  # seconds
    distances: List[List[int]]  # meters
    source: str  # google_routes | osrm | haversine | empty


@dataclass
class RouteLeg:
    """Single leg travel details between two points."""
    distance_meters: int
    duration_seconds: int
    polyline: Optional[str]
    source: str
