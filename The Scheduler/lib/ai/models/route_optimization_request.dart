import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_optimization_request.freezed.dart';
part 'route_optimization_request.g.dart';

/// Optimization objective - what to minimize.
enum OptimizationObjective {
  /// Minimize total travel time
  minimizeTime,

  /// Minimize total distance
  minimizeDistance,

  /// Balance time and distance
  balanced,

  /// Minimize latest arrival (finish early)
  minimizeLatestArrival,
}

/// A location to visit during route optimization.
@freezed
abstract class RouteWaypoint with _$RouteWaypoint {
  const factory RouteWaypoint({
    /// Unique identifier (usually appointment ID)
    required String id,

    /// Display name
    required String name,

    /// Latitude
    required double latitude,

    /// Longitude
    required double longitude,

    /// Earliest arrival time (window start)
    required DateTime windowStart,

    /// Latest arrival time (window end)
    required DateTime windowEnd,

    /// Service duration at this location (minutes)
    required int serviceDurationMinutes,

    /// Priority (higher = more important to visit on time)
    @Default(1) int priority,

    /// Whether this waypoint is required (vs optional)
    @Default(true) bool isRequired,

    /// Associated client ID
    String? clientId,

    /// Associated appointment ID
    String? appointmentId,
  }) = _RouteWaypoint;

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) =>
      _$RouteWaypointFromJson(json);
}

/// Request to optimize a route.
@freezed
abstract class RouteOptimizationRequest with _$RouteOptimizationRequest {
  const factory RouteOptimizationRequest({
    /// Business ID
    required String businessId,

    /// Provider ID
    required String providerId,

    /// Date for this route
    required DateTime routeDate,

    // ============ Start/End Locations ============

    /// Starting location (depot) latitude
    required double depotLatitude,

    /// Starting location (depot) longitude
    required double depotLongitude,

    /// Depot address for display
    required String depotAddress,

    /// Whether to return to depot at end
    @Default(true) bool returnToDepot,

    /// End location if different from depot
    double? endLatitude,
    double? endLongitude,
    String? endAddress,

    // ============ Waypoints ============

    /// Locations to visit
    required List<RouteWaypoint> waypoints,

    // ============ Time Constraints ============

    /// Earliest departure time from depot
    required DateTime earliestDeparture,

    /// Latest return time to depot
    required DateTime latestReturn,

    /// Maximum driving time per day (minutes)
    int? maxDrivingMinutes,

    // ============ Preferences ============

    /// What to optimize for
    @Default(OptimizationObjective.minimizeTime)
    OptimizationObjective objective,

    /// Include breaks (lunch, etc.)
    @Default(false) bool includeBreaks,

    /// Break duration in minutes (if includeBreaks)
    @Default(30) int breakDurationMinutes,

    /// Preferred break time window start
    DateTime? breakWindowStart,

    /// Preferred break time window end
    DateTime? breakWindowEnd,

    // ============ Vehicle Constraints ============

    /// Average speed in km/h (for time estimates without routing API)
    @Default(40) int averageSpeedKmh,

    /// Buffer time between appointments (minutes)
    @Default(5) int bufferBetweenStopsMinutes,
  }) = _RouteOptimizationRequest;

  factory RouteOptimizationRequest.fromJson(Map<String, dynamic> json) =>
      _$RouteOptimizationRequestFromJson(json);
}

/// Extension methods for RouteOptimizationRequest.
extension RouteOptimizationRequestExtensions on RouteOptimizationRequest {
  /// Total number of waypoints
  int get waypointCount => waypoints.length;

  /// Total service time needed (minutes)
  int get totalServiceMinutes =>
      waypoints.fold(0, (sum, w) => sum + w.serviceDurationMinutes);

  /// Available time window (minutes)
  int get availableMinutes =>
      latestReturn.difference(earliestDeparture).inMinutes;

  /// Whether this request is valid (has waypoints, valid times)
  bool get isValid =>
      waypoints.isNotEmpty &&
      earliestDeparture.isBefore(latestReturn) &&
      waypoints.every((w) => w.windowStart.isBefore(w.windowEnd));
}
