import 'package:freezed_annotation/freezed_annotation.dart';
import 'route_stop.dart';
import 'travel_segment.dart';
import 'route_optimization_request.dart';

part 'optimized_route.freezed.dart';
part 'optimized_route.g.dart';

/// Status of an optimized route.
enum RouteStatus {
  /// Route has been calculated but not started
  planned,

  /// Provider is actively following route
  inProgress,

  /// All stops completed
  completed,

  /// Route was cancelled
  cancelled,

  /// Route needs re-optimization (schedule changed)
  needsReoptimization,
}

/// An optimized route for a provider's day.
@freezed
abstract class OptimizedRoute with _$OptimizedRoute {
  const factory OptimizedRoute({
    /// Unique identifier
    required String id,

    /// Business ID (multi-tenant)
    required String businessId,

    /// Provider this route is for
    required String providerId,

    /// Provider name for display
    required String providerName,

    /// Date this route is for
    required DateTime routeDate,

    /// Current status
    @Default(RouteStatus.planned) RouteStatus status,

    // ============ Stops ============

    /// All stops in optimized order (including depot)
    required List<RouteStop> stops,

    /// Travel segments between stops
    required List<TravelSegment> segments,

    // ============ Timing ============

    /// When the route starts (departure from depot)
    required DateTime startTime,

    /// Expected end time (arrival back at depot or last stop)
    required DateTime expectedEndTime,

    /// Actual end time (filled when route completes)
    DateTime? actualEndTime,

    // ============ Metrics ============

    /// Total distance in meters
    required int totalDistanceMeters,

    /// Total estimated travel time in seconds
    required int totalTravelTimeSeconds,

    /// Total service time in seconds
    required int totalServiceTimeSeconds,

    // ============ Optimization Results ============

    /// Distance of original (unoptimized) route in meters
    int? originalDistanceMeters,

    /// Travel time of original route in seconds
    int? originalTravelTimeSeconds,

    /// Distance saved by optimization (meters)
    int? distanceSavedMeters,

    /// Time saved by optimization (seconds)
    int? timeSavedSeconds,

    /// Percentage improvement in travel time
    double? optimizationImprovementPercent,

    /// Optimization objective used
    OptimizationObjective? objective,

    // ============ Metadata ============

    /// Algorithm version used for optimization
    required String optimizerVersion,

    /// When this route was optimized
    required DateTime optimizedAt,

    /// When this route was last updated
    required DateTime updatedAt,

    /// Notes about this route
    String? notes,
  }) = _OptimizedRoute;

  factory OptimizedRoute.fromJson(Map<String, dynamic> json) =>
      _$OptimizedRouteFromJson(json);
}

/// Extension methods for OptimizedRoute.
extension OptimizedRouteExtensions on OptimizedRoute {
  /// Stops excluding depot (actual appointments)
  List<RouteStop> get appointmentStops =>
      stops.where((s) => s.isAppointment).toList();

  /// Number of appointment stops
  int get appointmentCount => appointmentStops.length;

  /// Current stop (first non-completed stop)
  RouteStop? get currentStop => stops
      .where((s) => !s.isCompleted && s.stopType != RouteStopType.depot)
      .firstOrNull;

  /// Next stop after current
  RouteStop? get nextStop {
    final current = currentStop;
    if (current == null) return null;
    final nextIndex = stops.indexOf(current) + 1;
    return nextIndex < stops.length ? stops[nextIndex] : null;
  }

  /// Completed stops count
  int get completedStopsCount =>
      stops.where((s) => s.isCompleted && s.isAppointment).length;

  /// Progress percentage (0.0-1.0)
  double get progressPercent {
    final total = appointmentCount;
    if (total == 0) return 1.0;
    return completedStopsCount / total;
  }

  /// Total distance in kilometers
  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  /// Total distance in miles
  double get totalDistanceMiles => totalDistanceMeters / 1609.344;

  /// Total travel time in minutes
  double get totalTravelTimeMinutes => totalTravelTimeSeconds / 60.0;

  /// Total service time in minutes
  double get totalServiceTimeMinutes => totalServiceTimeSeconds / 60.0;

  /// Total route duration (travel + service) in minutes
  double get totalDurationMinutes =>
      totalTravelTimeMinutes + totalServiceTimeMinutes;

  /// Time saved in minutes
  double get timeSavedMinutes => (timeSavedSeconds ?? 0) / 60.0;

  /// Whether optimization provided meaningful savings (>5 minutes)
  bool get hasSignificantSavings => (timeSavedSeconds ?? 0) > 300;

  /// Formatted savings string
  String get formattedSavings {
    final minutes = timeSavedMinutes.round();
    if (minutes < 60) {
      return '$minutes min saved';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min saved';
  }

  /// Whether route is running late (any stop past window)
  bool get isRunningLate => stops.any((s) => s.isLate);

  /// Estimated time of arrival at last stop
  DateTime get estimatedCompletion {
    if (stops.isEmpty) return expectedEndTime;
    final lastStop = stops.last;
    return lastStop.scheduledDeparture;
  }

  /// Whether route can be re-optimized (not completed/cancelled)
  bool get canReoptimize =>
      status == RouteStatus.planned || status == RouteStatus.needsReoptimization;
}
