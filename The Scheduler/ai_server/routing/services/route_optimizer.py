"""
Route Optimizer using Google OR-Tools.

REQUIREMENTS:
1. Solve Vehicle Routing Problem with Time Windows (VRPTW)
2. Respect appointment time windows
3. Minimize total travel time or distance
4. Support optional return to depot
5. Handle solver timeouts gracefully
"""

import logging
import time
from datetime import datetime, timedelta
from typing import Optional, List

from dataclasses import dataclass
from ortools.constraint_solver import routing_enums_pb2
from ortools.constraint_solver import pywrapcp

from .matrix_service import DistanceMatrix
from ..config import settings
from ..models.requests import RouteOptimizationRequest, OptimizationObjective

logger = logging.getLogger(__name__)


@dataclass
class OptimizationResult:
    """Result from route optimization."""
    success: bool
    route_order: List[int]  # Indices into original locations
    total_distance: int  # meters
    total_duration: int  # seconds
    arrival_times: List[datetime]  # Scheduled arrival at each stop
    solver_status: str
    computation_time_ms: int
    is_partial: bool = False  # True if timeout with partial solution


class RouteOptimizer:
    """
    Vehicle Routing Problem solver using OR-Tools.

    Solves the problem of finding the optimal order to visit
    a set of locations with time windows.
    """

    def __init__(
        self,
        time_limit_seconds: Optional[int] = None,
        solution_limit: Optional[int] = None,
    ):
        self.time_limit = time_limit_seconds or settings.solver_time_limit_seconds
        self.solution_limit = solution_limit or settings.solver_solution_limit

    def optimize(
        self,
        request: RouteOptimizationRequest,
        matrix: DistanceMatrix,
    ) -> OptimizationResult:
        """
        Optimize route for the given request.

        Args:
            request: Optimization request with constraints
            matrix: Distance/duration matrix (depot at index 0)

        Returns:
            OptimizationResult with optimized route order
        """
        start_time = time.time()

        n = len(matrix.locations)
        if n < 2:
            return OptimizationResult(
                success=True,
                route_order=list(range(n)),
                total_distance=0,
                total_duration=0,
                arrival_times=[request.earliest_departure] if n > 0 else [],
                solver_status="TRIVIAL",
                computation_time_ms=0,
            )

        # Create routing model
        manager = pywrapcp.RoutingIndexManager(n, 1, 0)  # n locations, 1 vehicle, depot=0
        routing = pywrapcp.RoutingModel(manager)

        # Distance callback
        def distance_callback(from_index: int, to_index: int) -> int:
            from_node = manager.IndexToNode(from_index)
            to_node = manager.IndexToNode(to_index)
            return matrix.distances[from_node][to_node]

        transit_callback_index = routing.RegisterTransitCallback(distance_callback)

        # Time callback for dimension
        def time_callback(from_index: int, to_index: int) -> int:
            from_node = manager.IndexToNode(from_index)
            to_node = manager.IndexToNode(to_index)
            return matrix.durations[from_node][to_node]

        time_callback_index = routing.RegisterTransitCallback(time_callback)

        # Set arc cost based on objective
        if request.objective == OptimizationObjective.MINIMIZE_DISTANCE:
            routing.SetArcCostEvaluatorOfAllVehicles(transit_callback_index)
        else:
            # Default: minimize time
            routing.SetArcCostEvaluatorOfAllVehicles(time_callback_index)

        # Add time dimension for time windows
        def time_callback_with_service(from_index: int, to_index: int) -> int:
            from_node = manager.IndexToNode(from_index)
            to_node = manager.IndexToNode(to_index)
            travel = matrix.durations[from_node][to_node]
            service = self._get_service_time(from_node, request)
            return travel + service

        time_dim_callback = routing.RegisterTransitCallback(time_callback_with_service)

        # Max time = full day in seconds
        max_time = 24 * 3600
        routing.AddDimension(
            time_dim_callback,
            max_time,  # slack (waiting time)
            max_time,  # max time per vehicle
            False,  # Don't force start cumul to zero
            "Time",
        )
        time_dimension = routing.GetDimensionOrDie("Time")

        # Set time windows
        base_time = request.earliest_departure
        for i, waypoint in enumerate(request.waypoints):
            index = manager.NodeToIndex(i + 1)  # +1 because depot is index 0

            # Convert time windows to seconds from base_time
            window_start = int((waypoint.window_start - base_time).total_seconds())
            window_end = int((waypoint.window_end - base_time).total_seconds())

            # Ensure valid window
            window_start = max(0, window_start)
            window_end = max(window_start + 1, window_end)

            time_dimension.CumulVar(index).SetRange(window_start, window_end)

        # Set depot time window
        depot_start = 0
        depot_end = int((request.latest_return - base_time).total_seconds())
        time_dimension.CumulVar(manager.NodeToIndex(0)).SetRange(depot_start, depot_end)

        # Handle return to depot
        if not request.return_to_depot:
            routing.SetFixedCostOfAllVehicles(0)

        # Set search parameters
        search_parameters = pywrapcp.DefaultRoutingSearchParameters()
        search_parameters.first_solution_strategy = (
            routing_enums_pb2.FirstSolutionStrategy.PATH_CHEAPEST_ARC
        )
        search_parameters.local_search_metaheuristic = (
            routing_enums_pb2.LocalSearchMetaheuristic.GUIDED_LOCAL_SEARCH
        )
        search_parameters.time_limit.seconds = self.time_limit
        search_parameters.solution_limit = self.solution_limit

        # Solve
        solution = routing.SolveWithParameters(search_parameters)

        computation_time = int((time.time() - start_time) * 1000)

        if not solution:
            return OptimizationResult(
                success=False,
                route_order=[],
                total_distance=0,
                total_duration=0,
                arrival_times=[],
                solver_status=self._get_solver_status(routing.status()),
                computation_time_ms=computation_time,
            )

        # Extract solution
        route_order = []
        arrival_times = []
        index = routing.Start(0)

        while not routing.IsEnd(index):
            node = manager.IndexToNode(index)
            route_order.append(node)

            time_var = time_dimension.CumulVar(index)
            arrival_seconds = solution.Value(time_var)
            arrival_times.append(base_time + timedelta(seconds=arrival_seconds))

            index = solution.Value(routing.NextVar(index))

        # Add end depot if returning
        if request.return_to_depot:
            node = manager.IndexToNode(index)
            route_order.append(node)
            time_var = time_dimension.CumulVar(index)
            arrival_seconds = solution.Value(time_var)
            arrival_times.append(base_time + timedelta(seconds=arrival_seconds))

        # Calculate totals
        total_distance = 0
        total_duration = 0
        for i in range(len(route_order) - 1):
            from_node = route_order[i]
            to_node = route_order[i + 1]
            total_distance += matrix.distances[from_node][to_node]
            total_duration += matrix.durations[from_node][to_node]

        return OptimizationResult(
            success=True,
            route_order=route_order,
            total_distance=total_distance,
            total_duration=total_duration,
            arrival_times=arrival_times,
            solver_status=self._get_solver_status(routing.status()),
            computation_time_ms=computation_time,
            is_partial=routing.status() == 3,  # ROUTING_FAIL_TIMEOUT
        )

    def _get_service_time(self, node: int, request: RouteOptimizationRequest) -> int:
        """Get service time in seconds for a node."""
        if node == 0:  # Depot
            return 0
        waypoint_idx = node - 1
        if 0 <= waypoint_idx < len(request.waypoints):
            minutes = request.waypoints[waypoint_idx].service_duration_minutes
            buffer = request.buffer_between_stops_minutes
            return (minutes + buffer) * 60
        return 0

    def _get_solver_status(self, status: int) -> str:
        """Convert OR-Tools status code to string."""
        status_map = {
            0: "ROUTING_NOT_SOLVED",
            1: "ROUTING_SUCCESS",
            2: "ROUTING_PARTIAL_SUCCESS_LOCAL_OPTIMUM_NOT_REACHED",
            3: "ROUTING_FAIL_TIMEOUT",
            4: "ROUTING_INVALID",
        }
        return status_map.get(status, f"UNKNOWN_{status}")


# Singleton
_optimizer: Optional[RouteOptimizer] = None


def get_route_optimizer() -> RouteOptimizer:
    """Get singleton route optimizer instance."""
    global _optimizer
    if _optimizer is None:
        _optimizer = RouteOptimizer()
    return _optimizer
