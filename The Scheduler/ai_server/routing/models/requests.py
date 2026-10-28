"""
Pydantic models for API requests.

REQUIREMENTS:
1. Match Flutter RouteOptimizationRequest model from AI-8
2. Validate all inputs
3. Provide clear error messages
4. Sanitize inputs to prevent injection
"""

import re
from datetime import datetime
from enum import Enum
from typing import Optional, List

from pydantic import Field, field_validator, model_validator

from .base import RoutingBaseModel


# Validation patterns
ID_PATTERN = re.compile(r"^[a-zA-Z0-9_-]{1,64}$")
NAME_MAX_LENGTH = 200


class OptimizationObjective(str, Enum):
    """What to optimize for."""
    MINIMIZE_TIME = "minimizeTime"
    MINIMIZE_DISTANCE = "minimizeDistance"
    BALANCED = "balanced"
    MINIMIZE_LATEST_ARRIVAL = "minimizeLatestArrival"


class Waypoint(RoutingBaseModel):
    """A location to visit during route optimization."""

    id: str = Field(..., description="Unique identifier (usually appointment ID)")
    name: str = Field(..., description="Display name")
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    window_start: datetime = Field(..., description="Earliest arrival time")
    window_end: datetime = Field(..., description="Latest arrival time")
    service_duration_minutes: int = Field(..., ge=0, le=480)
    priority: int = Field(default=1, ge=1, le=10)
    is_required: bool = Field(default=True)
    client_id: Optional[str] = None
    appointment_id: Optional[str] = None

    @field_validator("window_end")
    @classmethod
    def window_end_after_start(cls, v: datetime, info) -> datetime:
        """Validate window_end is after window_start."""
        window_start = info.data.get("window_start")
        if window_start and v <= window_start:
            raise ValueError("window_end must be after window_start")
        return v

def _validate_id(value: str, field_name: str) -> str:
    """Validate an ID field format."""
    if not value:
        raise ValueError(f"{field_name} is required")
    if not ID_PATTERN.match(value):
        raise ValueError(
            f"{field_name} must be 1-64 alphanumeric characters, hyphens, or underscores"
        )
    return value


def _sanitize_string(value: str, max_length: int = NAME_MAX_LENGTH) -> str:
    """Sanitize a string input."""
    if not value:
        return value
    # Truncate to max length
    value = value[:max_length]
    # Remove control characters
    value = "".join(c for c in value if c.isprintable() or c in "\n\t")
    return value.strip()


class RouteOptimizationRequest(RoutingBaseModel):
    """Request to optimize a route."""

    business_id: str = Field(..., min_length=1, max_length=64)
    provider_id: str = Field(..., min_length=1, max_length=64)
    route_date: datetime

    @field_validator("business_id", "provider_id")
    @classmethod
    def validate_ids(cls, v: str, info) -> str:
        """Validate ID format to prevent injection."""
        return _validate_id(v, info.field_name)

    # Depot (start location)
    depot_latitude: float = Field(..., ge=-90, le=90)
    depot_longitude: float = Field(..., ge=-180, le=180)
    depot_address: str = Field(..., min_length=1, max_length=500)

    @field_validator("depot_address")
    @classmethod
    def sanitize_depot_address(cls, v: str) -> str:
        """Sanitize address input."""
        return _sanitize_string(v, max_length=500)

    # End location
    return_to_depot: bool = Field(default=True)
    end_latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    end_longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    end_address: Optional[str] = None

    # Waypoints
    waypoints: List[Waypoint] = Field(..., min_length=1, max_length=50)

    # Time constraints
    earliest_departure: datetime
    latest_return: datetime
    max_driving_minutes: Optional[int] = Field(default=None, ge=30, le=720)

    # Preferences
    objective: OptimizationObjective = OptimizationObjective.MINIMIZE_TIME
    include_breaks: bool = False
    break_duration_minutes: int = Field(default=30, ge=15, le=120)
    break_window_start: Optional[datetime] = None
    break_window_end: Optional[datetime] = None

    # Vehicle constraints
    average_speed_kmh: int = Field(default=40, ge=10, le=120)
    buffer_between_stops_minutes: int = Field(default=5, ge=0, le=30)

    @field_validator("waypoints")
    @classmethod
    def validate_waypoints(cls, v: List[Waypoint]) -> List[Waypoint]:
        """Ensure no duplicate waypoint IDs."""
        ids = [w.id for w in v]
        if len(ids) != len(set(ids)):
            raise ValueError("Duplicate waypoint IDs found")
        return v

    @model_validator(mode="after")
    def validate_time_constraints(self) -> "RouteOptimizationRequest":
        """Validate time constraints are logical."""
        if self.latest_return <= self.earliest_departure:
            raise ValueError("latest_return must be after earliest_departure")
        return self

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}
