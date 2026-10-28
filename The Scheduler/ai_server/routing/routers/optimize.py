"""
Route optimization endpoints.

REQUIREMENTS:
1. POST /optimize - Main optimization endpoint
2. Secure API key authentication
3. HIPAA-compliant audit logging
4. No PHI in logs or error responses
"""

import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status

from ..config import settings
from ..models.requests import RouteOptimizationRequest
from ..models.responses import (
    OptimizedRouteResponse,
    RouteStopResponse,
    TravelSegmentResponse,
    RouteStopType,
    RouteStatus,
    ErrorResponse,
)
from ..services.matrix_service import MatrixService, Location, get_matrix_service
from ..services.route_optimizer import RouteOptimizer, get_route_optimizer
from ..security import (
    generate_correlation_id,
    get_security_context,
    require_tenant_access,
    SecurityContext,
)
from ..audit import audit_logger

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/routes", tags=["Route Optimization"])


@router.post(
    "/optimize",
    response_model=OptimizedRouteResponse,
    responses={
        400: {"model": ErrorResponse},
        401: {"model": ErrorResponse},
        429: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
    },
)
async def optimize_route(
    request: RouteOptimizationRequest,
    http_request: Request,
    security: SecurityContext = Depends(get_security_context),
    matrix_service: MatrixService = Depends(get_matrix_service),
    optimizer: RouteOptimizer = Depends(get_route_optimizer),
) -> OptimizedRouteResponse:
    """
    Optimize a route for a set of appointments.

    Takes a list of waypoints with time windows and returns
    the optimal visiting order that minimizes travel time
    while respecting all constraints.
    """
    require_tenant_access(security, request.business_id)

    start_time = datetime.utcnow()
    correlation_id = generate_correlation_id()
    route_id = correlation_id
    routing_source = None

    matrix = None
    try:
        # Build location list (depot first, then waypoints)
        # NOTE: Names/addresses are only used for response, not logged
        locations = [
            Location(
                id="depot",
                latitude=request.depot_latitude,
                longitude=request.depot_longitude,
                name="Depot",
            )
        ]
        for wp in request.waypoints:
            locations.append(
                Location(
                    id=wp.id,
                    latitude=wp.latitude,
                    longitude=wp.longitude,
                    name=wp.name,
                )
            )

        # Build distance/duration matrix
        matrix = await matrix_service.build_matrix(
            locations,
            departure_time=request.earliest_departure,
        )
        routing_source = matrix.source
        # Log only safe metadata (no PHI)
        logger.debug(
            f"Matrix built: source={matrix.source}, locations={len(locations)}"
        )

        # HIPAA Audit: Log request (no PHI - only counts and masked IDs)
        audit_logger.log_optimize_request(
            request=http_request,
            business_id=request.business_id,
            provider_id=request.provider_id,
            correlation_id=correlation_id,
            waypoint_count=len(request.waypoints),
            user_id=security.user_id,
            routing_source=routing_source,
            request_id=security.request_id,
        )

        # Optimize
        result = optimizer.optimize(request, matrix)

        if not result.success:
            # Log failure without PHI
            logger.warning(
                f"Optimization failed: correlation_id={correlation_id}, "
                f"status={result.solver_status}"
            )
            audit_logger.log_optimize_failure(
                request=http_request,
                business_id=request.business_id,
                provider_id=request.provider_id,
                correlation_id=correlation_id,
                error_type="SOLVER_FAILURE",
                http_status=status.HTTP_400_BAD_REQUEST,
                routing_source=routing_source,
                request_id=security.request_id,
                user_id=security.user_id,
                processing_time_ms=int(
                    (datetime.utcnow() - start_time).total_seconds() * 1000
                ),
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not find valid route",  # Generic message, no details
            )

        # Build response
        stops = []
        segments = []

        for i, node_idx in enumerate(result.route_order):
            loc = locations[node_idx]
            arrival = (
                result.arrival_times[i]
                if i < len(result.arrival_times)
                else request.earliest_departure
            )

            if node_idx == 0:
                # Depot
                stop_type = RouteStopType.END_DEPOT if i > 0 else RouteStopType.DEPOT
                stop = RouteStopResponse(
                    id=f"{route_id}_stop_{i}",
                    sequence_order=i if stop_type == RouteStopType.DEPOT else 9999,
                    stop_type=stop_type,
                    name="Depot" if stop_type == RouteStopType.DEPOT else "Return",
                    address=request.depot_address,
                    latitude=loc.latitude,
                    longitude=loc.longitude,
                    window_start=request.earliest_departure,
                    window_end=request.latest_return,
                    scheduled_arrival=arrival,
                    service_duration_minutes=0,
                )
            else:
                # Appointment
                wp = request.waypoints[node_idx - 1]
                stop = RouteStopResponse(
                    id=f"{route_id}_stop_{i}",
                    sequence_order=i,
                    stop_type=RouteStopType.APPOINTMENT,
                    name=wp.name,
                    address="",  # Would need to be passed in request
                    latitude=loc.latitude,
                    longitude=loc.longitude,
                    window_start=wp.window_start,
                    window_end=wp.window_end,
                    scheduled_arrival=arrival,
                    service_duration_minutes=wp.service_duration_minutes,
                    buffer_minutes=request.buffer_between_stops_minutes,
                    appointment_id=wp.appointment_id,
                    client_id=wp.client_id,
                )

            stops.append(stop)

            # Create travel segment to next stop
            if i < len(result.route_order) - 1:
                next_idx = result.route_order[i + 1]
                next_loc = locations[next_idx]

                # Get route details for this segment
                leg = await matrix_service.get_single_route(
                    loc,
                    next_loc,
                    preferred_source=matrix.source,
                    departure_time=request.earliest_departure,
                )

                segment = TravelSegmentResponse(
                    id=f"{route_id}_seg_{i}",
                    route_id=route_id,
                    from_stop_id=stop.id,
                    to_stop_id=f"{route_id}_stop_{i+1}",
                    sequence_order=i,
                    distance_meters=leg.distance_meters,
                    estimated_duration_seconds=leg.duration_seconds,
                    from_latitude=loc.latitude,
                    from_longitude=loc.longitude,
                    to_latitude=next_loc.latitude,
                    to_longitude=next_loc.longitude,
                    encoded_polyline=leg.polyline,
                    calculated_at=datetime.utcnow(),
                    routing_source=leg.source,
                )
                segments.append(segment)

                # Update stop with travel info
                stop.travel_to_next_minutes = leg.duration_seconds // 60
                stop.distance_to_next_meters = leg.distance_meters

        # Calculate totals
        total_service_seconds = sum(
            wp.service_duration_minutes * 60 for wp in request.waypoints
        )

        # Calculate original (unoptimized) route time
        original_order = list(range(len(locations)))
        original_distance = sum(
            matrix.distances[original_order[i]][original_order[i + 1]]
            for i in range(len(original_order) - 1)
        )
        original_duration = sum(
            matrix.durations[original_order[i]][original_order[i + 1]]
            for i in range(len(original_order) - 1)
        )

        distance_saved = original_distance - result.total_distance
        time_saved = original_duration - result.total_duration
        improvement = (
            (time_saved / original_duration * 100) if original_duration > 0 else 0
        )

        response = OptimizedRouteResponse(
            id=correlation_id,
            business_id=request.business_id,
            provider_id=request.provider_id,
            route_date=request.route_date,
            status=RouteStatus.PARTIAL if result.is_partial else RouteStatus.PLANNED,
            stops=stops,
            segments=segments,
            start_time=request.earliest_departure,
            expected_end_time=(
                result.arrival_times[-1]
                if result.arrival_times
                else request.latest_return
            ),
            total_distance_meters=result.total_distance,
            total_travel_time_seconds=result.total_duration,
            total_service_time_seconds=total_service_seconds,
            original_distance_meters=original_distance,
            original_travel_time_seconds=original_duration,
            distance_saved_meters=max(0, distance_saved),
            time_saved_seconds=max(0, time_saved),
            optimization_improvement_percent=max(0, improvement),
            optimizer_version=settings.service_version,
            optimized_at=datetime.utcnow(),
            computation_time_ms=result.computation_time_ms,
            solver_status=result.solver_status,
        )

        # HIPAA Audit: Log success (no PHI - only metrics)
        processing_ms = int(
            (datetime.utcnow() - start_time).total_seconds() * 1000
        )
        audit_logger.log_optimize_success(
            request=http_request,
            business_id=request.business_id,
            provider_id=request.provider_id,
            correlation_id=correlation_id,
            stop_count=len(stops),
            computation_time_ms=result.computation_time_ms,
            time_saved_seconds=max(0, time_saved),
            improvement_percent=max(0, improvement),
            routing_source=routing_source,
            status_code=status.HTTP_200_OK,
            request_id=security.request_id,
            user_id=security.user_id,
            processing_time_ms=processing_ms,
        )

        return response

    except HTTPException as exc:
        audit_logger.log_optimize_failure(
            request=http_request,
            business_id=request.business_id,
            provider_id=request.provider_id,
            correlation_id=correlation_id,
            error_type=type(exc).__name__,
            http_status=exc.status_code,
            routing_source=routing_source,
            request_id=security.request_id,
            user_id=security.user_id,
            processing_time_ms=int(
                (datetime.utcnow() - start_time).total_seconds() * 1000
            ),
        )
        raise
    except Exception as e:
        # Log error without exposing details
        logger.exception(
            f"Optimization error: correlation_id={correlation_id}"
        )
        audit_logger.log_optimize_failure(
            request=http_request,
            business_id=request.business_id,
            provider_id=request.provider_id,
            correlation_id=correlation_id,
            error_type=type(e).__name__,
            http_status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            routing_source=routing_source,
            request_id=security.request_id,
            user_id=security.user_id,
            processing_time_ms=int(
                (datetime.utcnow() - start_time).total_seconds() * 1000
            ),
        )
        # Return generic error message - never expose exception details
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An internal error occurred. Please try again.",
        )
