import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_stop.freezed.dart';
part 'route_stop.g.dart';

/// Type of stop in a route.
enum RouteStopType {
  /// Starting location (provider's home/office)
  depot,

  /// Client appointment
  appointment,

  /// Break/lunch stop
  breakStop,

  /// Ending location (may differ from depot)
  endDepot,
}

/// Status of a route stop.
enum RouteStopStatus {
  /// Not yet started
  pending,

  /// Provider en route to this stop
  enRoute,

  /// Provider has arrived
  arrived,

  /// Service in progress
  inProgress,

  /// Service completed
  completed,

  /// Stop was skipped
  skipped,

  /// Client was not available (no-show)
  clientNoShow,
}

/// A single stop in an optimized route.
@freezed
abstract class RouteStop with _$RouteStop {
  const factory RouteStop({
    /// Unique identifier for this stop
    required String id,

    /// Position in the route (0 = first stop after depot)
    required int sequenceOrder,

    /// Type of stop
    required RouteStopType stopType,

    /// Status of this stop
    @Default(RouteStopStatus.pending) RouteStopStatus status,

    // ============ Location ============

    /// Display name for this stop
    required String name,

    /// Full address
    required String address,

    /// Latitude
    required double latitude,

    /// Longitude
    required double longitude,

    /// Special instructions (gate code, parking, etc.)
    String? arrivalNotes,

    // ============ Timing ============

    /// Earliest allowed arrival time
    required DateTime windowStart,

    /// Latest allowed arrival time
    required DateTime windowEnd,

    /// Scheduled/suggested arrival time (from optimizer)
    required DateTime scheduledArrival,

    /// Actual arrival time (filled when provider arrives)
    DateTime? actualArrival,

    /// Expected service duration in minutes
    required int serviceDurationMinutes,

    /// Buffer time after service before next stop (minutes)
    @Default(0) int bufferMinutes,

    /// Actual departure time (filled when provider leaves)
    DateTime? actualDeparture,

    // ============ References ============

    /// Linked appointment ID (for appointment stops)
    String? appointmentId,

    /// Linked client ID
    String? clientId,

    /// Service being performed
    String? serviceId,

    /// Service name for display
    String? serviceName,

    // ============ Travel to Next Stop ============

    /// Estimated travel time to next stop (minutes)
    int? travelToNextMinutes,

    /// Estimated distance to next stop (meters)
    int? distanceToNextMeters,

    // ============ Metadata ============

    /// Provider notes about this stop
    String? providerNotes,

    /// When this stop was last updated
    required DateTime updatedAt,
  }) = _RouteStop;

  factory RouteStop.fromJson(Map<String, dynamic> json) =>
      _$RouteStopFromJson(json);
}

/// Extension methods for RouteStop.
extension RouteStopExtensions on RouteStop {
  /// Create a depot stop (start/end location).
  static RouteStop depot({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required DateTime departureTime,
    bool isEndDepot = false,
  }) =>
      RouteStop(
        id: id,
        sequenceOrder: isEndDepot ? 9999 : -1,
        stopType: isEndDepot ? RouteStopType.endDepot : RouteStopType.depot,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        windowStart: departureTime,
        windowEnd: departureTime.add(const Duration(hours: 1)),
        scheduledArrival: departureTime,
        serviceDurationMinutes: 0,
        updatedAt: DateTime.now(),
      );

  /// Whether this stop is an appointment (not depot/break)
  bool get isAppointment => stopType == RouteStopType.appointment;

  /// Whether this stop has been completed
  bool get isCompleted =>
      status == RouteStopStatus.completed ||
      status == RouteStopStatus.skipped ||
      status == RouteStopStatus.clientNoShow;

  /// Scheduled departure time
  DateTime get scheduledDeparture =>
      scheduledArrival.add(Duration(minutes: serviceDurationMinutes + bufferMinutes));

  /// Time until window closes (negative if past)
  Duration get timeUntilWindowEnd => windowEnd.difference(DateTime.now());

  /// Whether currently within the arrival window
  bool get isWithinWindow {
    final now = DateTime.now();
    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  /// Whether running late (past window end and not arrived)
  bool get isLate =>
      status == RouteStopStatus.pending && DateTime.now().isAfter(windowEnd);

  /// Coordinates as tuple
  (double lat, double lng) get coordinates => (latitude, longitude);
}
