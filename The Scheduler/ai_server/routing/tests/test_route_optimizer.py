"""Tests for route optimizer."""

import pytest
from datetime import datetime, timedelta

from ..services.route_optimizer import RouteOptimizer
from ..services.matrix_service import DistanceMatrix, Location
from ..models.requests import (
    RouteOptimizationRequest,
    Waypoint,
    OptimizationObjective,
)


@pytest.fixture
def sample_request():
    """Create a sample optimization request."""
    now = datetime.now()
    return RouteOptimizationRequest(
        business_id="biz_123",
        provider_id="provider_456",
        route_date=now,
        depot_latitude=40.7128,
        depot_longitude=-74.0060,
        depot_address="New York, NY",
        waypoints=[
            Waypoint(
                id="wp_1",
                name="Client A",
                latitude=40.7589,
                longitude=-73.9851,
                window_start=now + timedelta(hours=1),
                window_end=now + timedelta(hours=2),
                service_duration_minutes=30,
            ),
            Waypoint(
                id="wp_2",
                name="Client B",
                latitude=40.7484,
                longitude=-73.9857,
                window_start=now + timedelta(hours=2),
                window_end=now + timedelta(hours=3),
                service_duration_minutes=45,
            ),
            Waypoint(
                id="wp_3",
                name="Client C",
                latitude=40.7282,
                longitude=-73.7949,
                window_start=now + timedelta(hours=3),
                window_end=now + timedelta(hours=4),
                service_duration_minutes=30,
            ),
        ],
        earliest_departure=now,
        latest_return=now + timedelta(hours=10),
        objective=OptimizationObjective.MINIMIZE_TIME,
    )


@pytest.fixture
def sample_matrix(sample_request):
    """Create a sample distance matrix."""
    locations = [
        Location(
            id="depot",
            latitude=sample_request.depot_latitude,
            longitude=sample_request.depot_longitude,
            name="Depot",
        ),
    ]
    for wp in sample_request.waypoints:
        locations.append(
            Location(
                id=wp.id,
                latitude=wp.latitude,
                longitude=wp.longitude,
                name=wp.name,
            )
        )

    n = len(locations)
    # Simple synthetic matrix
    durations = [[0] * n for _ in range(n)]
    distances = [[0] * n for _ in range(n)]

    for i in range(n):
        for j in range(n):
            if i != j:
                durations[i][j] = 600  # 10 minutes
                distances[i][j] = 5000  # 5 km

    return DistanceMatrix(
        locations=locations,
        durations=durations,
        distances=distances,
        source="test",
    )


def test_optimize_simple_route(sample_request, sample_matrix):
    """Test basic route optimization."""
    optimizer = RouteOptimizer(time_limit_seconds=10)
    result = optimizer.optimize(sample_request, sample_matrix)

    assert result.success is True
    assert len(result.route_order) >= len(sample_request.waypoints) + 1
    assert result.total_distance > 0
    assert result.total_duration > 0
    assert result.solver_status == "ROUTING_SUCCESS"


def test_optimize_trivial_single_waypoint():
    """Test optimization with single waypoint."""
    now = datetime.now()
    request = RouteOptimizationRequest(
        business_id="biz",
        provider_id="prov",
        route_date=now,
        depot_latitude=40.7128,
        depot_longitude=-74.0060,
        depot_address="NYC",
        waypoints=[
            Waypoint(
                id="wp_1",
                name="Single Client",
                latitude=40.7589,
                longitude=-73.9851,
                window_start=now + timedelta(hours=1),
                window_end=now + timedelta(hours=2),
                service_duration_minutes=30,
            ),
        ],
        earliest_departure=now,
        latest_return=now + timedelta(hours=10),
    )

    locations = [
        Location(id="depot", latitude=40.7128, longitude=-74.0060, name="Depot"),
        Location(id="wp_1", latitude=40.7589, longitude=-73.9851, name="Client"),
    ]

    matrix = DistanceMatrix(
        locations=locations,
        durations=[[0, 600], [600, 0]],
        distances=[[0, 5000], [5000, 0]],
        source="test",
    )

    optimizer = RouteOptimizer()
    result = optimizer.optimize(request, matrix)

    assert result.success is True
    assert 0 in result.route_order  # Depot included
    assert 1 in result.route_order  # Waypoint included


def test_optimize_empty_waypoints():
    """Test optimization with minimal waypoints."""
    now = datetime.now()
    request = RouteOptimizationRequest(
        business_id="biz",
        provider_id="prov",
        route_date=now,
        depot_latitude=40.7128,
        depot_longitude=-74.0060,
        depot_address="NYC",
        waypoints=[
            Waypoint(
                id="dummy",
                name="Dummy",
                latitude=40.7128,
                longitude=-74.0060,
                window_start=now,
                window_end=now + timedelta(hours=1),
                service_duration_minutes=0,
            ),
        ],
        earliest_departure=now,
        latest_return=now + timedelta(hours=10),
    )

    locations = [
        Location(id="depot", latitude=40.7128, longitude=-74.0060, name="Depot")
    ]
    matrix = DistanceMatrix(
        locations=locations, durations=[[0]], distances=[[0]], source="test"
    )

    optimizer = RouteOptimizer()
    result = optimizer.optimize(request, matrix)

    # Should handle trivially
    assert result.success is True
    assert result.solver_status == "TRIVIAL"


def test_optimize_minimize_distance(sample_request, sample_matrix):
    """Test optimization with distance objective."""
    sample_request_dict = sample_request.model_dump()
    sample_request_dict["objective"] = OptimizationObjective.MINIMIZE_DISTANCE
    request = RouteOptimizationRequest(**sample_request_dict)

    optimizer = RouteOptimizer(time_limit_seconds=10)
    result = optimizer.optimize(request, sample_matrix)

    assert result.success is True


def test_optimize_no_return_to_depot():
    """Test optimization without returning to depot."""
    now = datetime.now()
    request = RouteOptimizationRequest(
        business_id="biz",
        provider_id="prov",
        route_date=now,
        depot_latitude=40.7128,
        depot_longitude=-74.0060,
        depot_address="NYC",
        return_to_depot=False,
        waypoints=[
            Waypoint(
                id="wp_1",
                name="Client A",
                latitude=40.7589,
                longitude=-73.9851,
                window_start=now + timedelta(hours=1),
                window_end=now + timedelta(hours=2),
                service_duration_minutes=30,
            ),
            Waypoint(
                id="wp_2",
                name="Client B",
                latitude=40.7484,
                longitude=-73.9857,
                window_start=now + timedelta(hours=2),
                window_end=now + timedelta(hours=3),
                service_duration_minutes=30,
            ),
        ],
        earliest_departure=now,
        latest_return=now + timedelta(hours=10),
    )

    locations = [
        Location(id="depot", latitude=40.7128, longitude=-74.0060, name="Depot"),
        Location(id="wp_1", latitude=40.7589, longitude=-73.9851, name="A"),
        Location(id="wp_2", latitude=40.7484, longitude=-73.9857, name="B"),
    ]

    n = len(locations)
    durations = [[0] * n for _ in range(n)]
    distances = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            if i != j:
                durations[i][j] = 600
                distances[i][j] = 5000

    matrix = DistanceMatrix(
        locations=locations, durations=durations, distances=distances, source="test"
    )

    optimizer = RouteOptimizer(time_limit_seconds=10)
    result = optimizer.optimize(request, matrix)

    assert result.success is True


def test_get_service_time(sample_request):
    """Test service time calculation."""
    optimizer = RouteOptimizer()

    # Depot has 0 service time
    assert optimizer._get_service_time(0, sample_request) == 0

    # First waypoint: 30 min + 5 min buffer = 35 min = 2100 sec
    service_time = optimizer._get_service_time(1, sample_request)
    expected = (30 + 5) * 60  # service + buffer in seconds
    assert service_time == expected


def test_get_solver_status():
    """Test solver status conversion."""
    optimizer = RouteOptimizer()

    assert optimizer._get_solver_status(0) == "ROUTING_NOT_SOLVED"
    assert optimizer._get_solver_status(1) == "ROUTING_SUCCESS"
    assert optimizer._get_solver_status(3) == "ROUTING_FAIL_TIMEOUT"
    assert optimizer._get_solver_status(99) == "UNKNOWN_99"
