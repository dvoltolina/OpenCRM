"""
Geographic utility functions.

REQUIREMENTS:
1. Coordinate validation
2. Bounding box calculations
3. Distance formatting
"""

import math
from typing import Optional, List, Tuple


def validate_coordinates(latitude: float, longitude: float) -> bool:
    """Check if coordinates are valid."""
    return -90 <= latitude <= 90 and -180 <= longitude <= 180


def calculate_bounding_box(
    coordinates: List[Tuple[float, float]],
    padding_km: float = 10.0,
) -> Tuple[float, float, float, float]:
    """
    Calculate bounding box for coordinates with padding.

    Args:
        coordinates: List of (latitude, longitude) tuples
        padding_km: Padding to add around the box in km

    Returns:
        Tuple of (min_lat, min_lon, max_lat, max_lon)
    """
    if not coordinates:
        return (0, 0, 0, 0)

    lats = [c[0] for c in coordinates]
    lons = [c[1] for c in coordinates]

    min_lat, max_lat = min(lats), max(lats)
    min_lon, max_lon = min(lons), max(lons)

    # Approximate degrees for padding
    # 1 degree latitude ~ 111 km
    # 1 degree longitude varies by latitude
    lat_padding = padding_km / 111
    avg_lat = (min_lat + max_lat) / 2
    cos_lat = math.cos(math.radians(avg_lat))
    lon_padding = padding_km / (111 * cos_lat) if cos_lat > 0 else padding_km / 111

    return (
        min_lat - lat_padding,
        min_lon - lon_padding,
        max_lat + lat_padding,
        max_lon + lon_padding,
    )


def format_distance(meters: int) -> str:
    """Format distance for display."""
    if meters < 1000:
        return f"{meters}m"
    km = meters / 1000
    return f"{km:.1f}km"


def format_duration(seconds: int) -> str:
    """Format duration for display."""
    if seconds < 60:
        return f"{seconds}s"
    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}min"
    hours = minutes // 60
    mins = minutes % 60
    return f"{hours}h {mins}min"


def meters_to_miles(meters: int) -> float:
    """Convert meters to miles."""
    return meters / 1609.344


def calculate_center(
    coordinates: List[Tuple[float, float]]
) -> Optional[Tuple[float, float]]:
    """Calculate geographic center of coordinates."""
    if not coordinates:
        return None

    avg_lat = sum(c[0] for c in coordinates) / len(coordinates)
    avg_lon = sum(c[1] for c in coordinates) / len(coordinates)
    return (avg_lat, avg_lon)
