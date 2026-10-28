"""
Pydantic models for API responses.

REQUIREMENTS:
1. Match Flutter OptimizedRoute model from AI-8
2. Include all optimization metrics
3. Support partial results on timeout
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List

from pydantic import Field

from .base import RoutingBaseModel


class RouteStopType(str, Enum):
    """Type of stop in a route."""
    DEPOT = "depot"
    APPOINTMENT = "appointment"
    BREAK_STOP = "breakStop"
    END_DEPOT = "endDepot"


class RouteStopStatus(str, Enum):
    """Status of a route stop."""
    PENDING = "pending"


class RouteStopResponse(RoutingBaseModel):
    """A single stop in the optimized route."""

    id: str
    sequence_order: int
    stop_type: RouteStopType
    status: RouteStopStatus = RouteStopStatus.PENDING

    # Location
    name: str
    address: str
    latitude: float
    longitude: float
    arrival_notes: Optional[str] = None

    # Timing
    window_start: datetime
    window_end: datetime
    scheduled_arrival: datetime
    service_duration_minutes: int
    buffer_minutes: int = 0

    # References
    appointment_id: Optional[str] = None
    client_id: Optional[str] = None
    service_id: Optional[str] = None
    service_name: Optional[str] = None

    # Travel to next
    travel_to_next_minutes: Optional[int] = None
    distance_to_next_meters: Optional[int] = None

class TravelSegmentResponse(RoutingBaseModel):
    """Travel segment between two stops."""

    id: str
    route_id: str
    from_stop_id: str
    to_stop_id: str
    sequence_order: int

    distance_meters: int
    estimated_duration_seconds: int

    from_latitude: float
    from_longitude: float
    to_latitude: float
    to_longitude: float

    encoded_polyline: Optional[str] = None
    calculated_at: datetime
    routing_source: str = "osrm"

class RouteStatus(str, Enum):
    """Status of the optimized route."""
    PLANNED = "planned"
    OPTIMIZATION_FAILED = "optimizationFailed"
    PARTIAL = "partial"  # Timeout with partial solution


class OptimizedRouteResponse(RoutingBaseModel):
    """Complete optimized route response."""

    id: str
    business_id: str
    provider_id: str
    provider_name: str = ""
    route_date: datetime
    status: RouteStatus = RouteStatus.PLANNED

    # Stops and segments
    stops: List[RouteStopResponse]
    segments: List[TravelSegmentResponse]

    # Timing
    start_time: datetime
    expected_end_time: datetime

    # Metrics
    total_distance_meters: int
    total_travel_time_seconds: int
    total_service_time_seconds: int

    # Optimization results
    original_distance_meters: Optional[int] = None
    original_travel_time_seconds: Optional[int] = None
    distance_saved_meters: Optional[int] = None
    time_saved_seconds: Optional[int] = None
    optimization_improvement_percent: Optional[float] = None

    # Metadata
    optimizer_version: str
    optimized_at: datetime
    computation_time_ms: int
    solver_status: str

class ErrorResponse(RoutingBaseModel):
    """Error response model."""

    error: str
    detail: Optional[str] = None
    code: str = "OPTIMIZATION_ERROR"


class HealthResponse(RoutingBaseModel):
    """Health check response."""

    status: str = "healthy"
    service: str
    version: str
    osrm_status: str = "unknown"
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}
