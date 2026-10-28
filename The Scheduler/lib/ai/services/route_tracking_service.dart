import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/optimized_route.dart';
import '../models/route_stop.dart';
import '../repositories/route_repository.dart';
import 'geocoding_service.dart';

/// Configuration for route tracking.
class RouteTrackingConfig {
  /// Geofence radius in meters to detect arrival.
  final double arrivalRadiusMeters;

  /// Geofence radius for "near" detection.
  final double nearRadiusMeters;

  /// Minimum accuracy for GPS readings (meters).
  final double minAccuracyMeters;

  /// How often to update ETA (seconds).
  final int etaUpdateIntervalSeconds;

  /// Average speed for ETA when no route data (km/h).
  final double defaultSpeedKmh;

  const RouteTrackingConfig({
    this.arrivalRadiusMeters = 50.0,
    this.nearRadiusMeters = 200.0,
    this.minAccuracyMeters = 100.0,
    this.etaUpdateIntervalSeconds = 30,
    this.defaultSpeedKmh = 30.0,
  });
}

/// Current location with metadata.
class CurrentLocation {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedMps;
  final double? headingDegrees;
  final DateTime timestamp;

  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.speedMps,
    this.headingDegrees,
    required this.timestamp,
  });

  /// Speed in km/h.
  double? get speedKmh => speedMps != null ? speedMps! * 3.6 : null;

  /// Whether accuracy is acceptable.
  bool isAccurate(double threshold) =>
      accuracyMeters == null || accuracyMeters! <= threshold;
}

/// ETA update for a stop.
class EtaUpdate {
  final String stopId;
  final DateTime estimatedArrival;
  final int distanceMeters;
  final int durationSeconds;
  final bool isLate;
  final int? minutesLate;

  const EtaUpdate({
    required this.stopId,
    required this.estimatedArrival,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isLate,
    this.minutesLate,
  });
}

/// Geofence event type.
enum GeofenceEvent {
  /// Entered arrival radius.
  arrivedAtStop,

  /// Entered near radius.
  approachingStop,

  /// Left stop area.
  departedStop,
}

/// Geofence trigger.
class GeofenceTrigger {
  final GeofenceEvent event;
  final String stopId;
  final RouteStop stop;
  final DateTime timestamp;
  final double distanceMeters;

  const GeofenceTrigger({
    required this.event,
    required this.stopId,
    required this.stop,
    required this.timestamp,
    required this.distanceMeters,
  });
}

/// Service for real-time route tracking with geofencing.
///
/// **Features:**
/// - Track provider's real-time location during route
/// - Calculate ETA updates based on current position
/// - Detect arrival at stops via geofencing
/// - Update stop status automatically
///
/// **HIPAA Compliance:**
/// - Location tracking logged for audit
/// - SecurityContext for multi-tenant isolation
class RouteTrackingService {
  final RouteTrackingConfig _config;
  final RouteRepository _routeRepository;
  final GeocodingService _geocodingService;
  final AuditLogRepository _auditLogRepository;

  /// Currently tracked route.
  OptimizedRoute? _activeRoute;

  /// Last known location.
  CurrentLocation? _lastLocation;

  /// Stops that have been geofence-triggered (to avoid duplicates).
  final Set<String> _arrivedStopIds = {};
  final Set<String> _approachedStopIds = {};

  /// Stream controllers for events.
  final _etaController = StreamController<EtaUpdate>.broadcast();
  final _geofenceController = StreamController<GeofenceTrigger>.broadcast();
  final _locationController = StreamController<CurrentLocation>.broadcast();

  /// Timer for periodic ETA updates.
  Timer? _etaUpdateTimer;

  RouteTrackingService({
    RouteTrackingConfig? config,
    RouteRepository? routeRepository,
    GeocodingService? geocodingService,
    AuditLogRepository? auditLogRepository,
  })  : _config = config ?? const RouteTrackingConfig(),
        _routeRepository = routeRepository ?? RouteRepository(),
        _geocodingService = geocodingService ??
            GeocodingService(config: GeocodingConfig.development()),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  // ============ Streams ============

  /// Stream of ETA updates for stops.
  Stream<EtaUpdate> get etaUpdates => _etaController.stream;

  /// Stream of geofence events.
  Stream<GeofenceTrigger> get geofenceEvents => _geofenceController.stream;

  /// Stream of location updates.
  Stream<CurrentLocation> get locationUpdates => _locationController.stream;

  // ============ State ============

  /// Currently active route being tracked.
  OptimizedRoute? get activeRoute => _activeRoute;

  /// Last known location.
  CurrentLocation? get lastLocation => _lastLocation;

  /// Whether tracking is active.
  bool get isTracking => _activeRoute != null;

  // ============ Tracking Control ============

  /// Start tracking a route.
  Future<void> startTracking(
    SecurityContext context,
    OptimizedRoute route,
  ) async {
    // Stop any existing tracking
    await stopTracking(context);

    _activeRoute = route;
    _arrivedStopIds.clear();
    _approachedStopIds.clear();

    // Mark completed stops as already arrived
    for (final stop in route.stops) {
      if (stop.isCompleted) {
        _arrivedStopIds.add(stop.id);
        _approachedStopIds.add(stop.id);
      }
    }

    // Start ETA update timer
    _etaUpdateTimer = Timer.periodic(
      Duration(seconds: _config.etaUpdateIntervalSeconds),
      (_) => _updateEtas(),
    );

    await _logAudit(
      context: context,
      action: 'route_tracking_started',
      entityType: 'optimizedRoute',
      entityId: route.id,
      details: {
        'provider_id': route.providerId,
        'stops_count': route.stops.length,
      },
    );

    debugPrint('RouteTrackingService: Started tracking route ${route.id}');
  }

  /// Stop tracking.
  Future<void> stopTracking(SecurityContext? context) async {
    final routeId = _activeRoute?.id;

    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;
    _activeRoute = null;
    _lastLocation = null;
    _arrivedStopIds.clear();
    _approachedStopIds.clear();

    if (context != null && routeId != null) {
      await _logAudit(
        context: context,
        action: 'route_tracking_stopped',
        entityType: 'optimizedRoute',
        entityId: routeId,
        details: {},
      );
    }

    debugPrint('RouteTrackingService: Stopped tracking');
  }

  /// Update current location.
  ///
  /// Call this method from location provider/GPS updates.
  Future<void> updateLocation(
    SecurityContext context,
    CurrentLocation location,
  ) async {
    _lastLocation = location;
    _locationController.add(location);

    if (_activeRoute == null) return;

    // Check accuracy
    if (!location.isAccurate(_config.minAccuracyMeters)) {
      debugPrint(
        'RouteTrackingService: Ignoring inaccurate location '
        '(${location.accuracyMeters}m)',
      );
      return;
    }

    // Check geofences for all non-completed stops
    await _checkGeofences(context, location);

    // Update ETAs
    _updateEtas();
  }

  // ============ ETA Calculation ============

  /// Get current ETA to a specific stop.
  EtaUpdate? getEtaToStop(String stopId) {
    if (_activeRoute == null || _lastLocation == null) return null;

    final stop = _activeRoute!.stops.firstWhere(
      (s) => s.id == stopId,
      orElse: () => throw ArgumentError('Stop not found'),
    );

    return _calculateEta(_lastLocation!, stop);
  }

  /// Get ETAs to all remaining stops.
  List<EtaUpdate> getAllEtas() {
    if (_activeRoute == null || _lastLocation == null) return [];

    final remaining = _activeRoute!.stops.where((s) => !s.isCompleted);
    return remaining.map((s) => _calculateEta(_lastLocation!, s)).toList();
  }

  void _updateEtas() {
    if (_activeRoute == null || _lastLocation == null) return;

    final currentStop = _activeRoute!.currentStop;
    if (currentStop != null) {
      final eta = _calculateEta(_lastLocation!, currentStop);
      _etaController.add(eta);
    }
  }

  EtaUpdate _calculateEta(CurrentLocation location, RouteStop stop) {
    final distanceMeters = _calculateDistance(
      location.latitude,
      location.longitude,
      stop.latitude,
      stop.longitude,
    );

    // Use current speed if available, otherwise default
    final speedKmh = location.speedKmh ?? _config.defaultSpeedKmh;
    final speedMps = speedKmh / 3.6;

    final durationSeconds =
        speedMps > 0 ? (distanceMeters / speedMps).round() : 0;

    final estimatedArrival =
        DateTime.now().add(Duration(seconds: durationSeconds));

    final isLate = estimatedArrival.isAfter(stop.windowEnd);
    final minutesLate = isLate
        ? estimatedArrival.difference(stop.windowEnd).inMinutes
        : null;

    return EtaUpdate(
      stopId: stop.id,
      estimatedArrival: estimatedArrival,
      distanceMeters: distanceMeters.round(),
      durationSeconds: durationSeconds,
      isLate: isLate,
      minutesLate: minutesLate,
    );
  }

  // ============ Geofencing ============

  Future<void> _checkGeofences(
    SecurityContext context,
    CurrentLocation location,
  ) async {
    if (_activeRoute == null) return;

    for (final stop in _activeRoute!.stops) {
      // Skip completed or already processed stops
      if (stop.isCompleted) continue;

      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        stop.latitude,
        stop.longitude,
      );

      // Check arrival (innermost geofence)
      if (distance <= _config.arrivalRadiusMeters &&
          !_arrivedStopIds.contains(stop.id)) {
        _arrivedStopIds.add(stop.id);
        _approachedStopIds.add(stop.id);

        final trigger = GeofenceTrigger(
          event: GeofenceEvent.arrivedAtStop,
          stopId: stop.id,
          stop: stop,
          timestamp: DateTime.now(),
          distanceMeters: distance,
        );

        _geofenceController.add(trigger);

        // Auto-update stop status
        await _onArrival(context, stop);
      }
      // Check approaching (outer geofence)
      else if (distance <= _config.nearRadiusMeters &&
          !_approachedStopIds.contains(stop.id)) {
        _approachedStopIds.add(stop.id);

        final trigger = GeofenceTrigger(
          event: GeofenceEvent.approachingStop,
          stopId: stop.id,
          stop: stop,
          timestamp: DateTime.now(),
          distanceMeters: distance,
        );

        _geofenceController.add(trigger);
      }
    }
  }

  Future<void> _onArrival(SecurityContext context, RouteStop stop) async {
    if (_activeRoute == null) return;

    // Update stop status to arrived
    await _routeRepository.updateStopStatus(
      context,
      _activeRoute!.id,
      stop.id,
      RouteStopStatus.arrived,
      actualArrival: DateTime.now(),
    );

    await _logAudit(
      context: context,
      action: 'route_stop_arrival_detected',
      entityType: 'routeStop',
      entityId: stop.id,
      details: {
        'route_id': _activeRoute!.id,
        'stop_type': stop.stopType.name,
        'scheduled_arrival': stop.scheduledArrival.toIso8601String(),
        'actual_arrival': DateTime.now().toIso8601String(),
      },
    );

    debugPrint('RouteTrackingService: Arrived at stop ${stop.id}');
  }

  // ============ Manual Stop Updates ============

  /// Mark stop as in progress (service started).
  Future<void> markStopInProgress(
    SecurityContext context,
    String stopId,
  ) async {
    if (_activeRoute == null) return;

    await _routeRepository.updateStopStatus(
      context,
      _activeRoute!.id,
      stopId,
      RouteStopStatus.inProgress,
    );

    // Refresh active route
    _activeRoute = await _routeRepository.getRoute(context, _activeRoute!.id);
  }

  /// Mark stop as completed.
  Future<void> markStopCompleted(
    SecurityContext context,
    String stopId, {
    String? notes,
  }) async {
    if (_activeRoute == null) return;

    await _routeRepository.updateStopStatus(
      context,
      _activeRoute!.id,
      stopId,
      RouteStopStatus.completed,
      actualDeparture: DateTime.now(),
      notes: notes,
    );

    _arrivedStopIds.add(stopId);

    // Send departure event
    final stop = _activeRoute!.stops.firstWhere((s) => s.id == stopId);
    _geofenceController.add(GeofenceTrigger(
      event: GeofenceEvent.departedStop,
      stopId: stopId,
      stop: stop,
      timestamp: DateTime.now(),
      distanceMeters: 0,
    ));

    // Refresh active route
    _activeRoute = await _routeRepository.getRoute(context, _activeRoute!.id);

    await _logAudit(
      context: context,
      action: 'route_stop_completed',
      entityType: 'routeStop',
      entityId: stopId,
      details: {
        'route_id': _activeRoute!.id,
        'has_notes': notes != null,
      },
    );
  }

  /// Mark stop as skipped.
  Future<void> markStopSkipped(
    SecurityContext context,
    String stopId, {
    String? reason,
  }) async {
    if (_activeRoute == null) return;

    await _routeRepository.updateStopStatus(
      context,
      _activeRoute!.id,
      stopId,
      RouteStopStatus.skipped,
      notes: reason,
    );

    _arrivedStopIds.add(stopId);

    // Refresh active route
    _activeRoute = await _routeRepository.getRoute(context, _activeRoute!.id);

    await _logAudit(
      context: context,
      action: 'route_stop_skipped',
      entityType: 'routeStop',
      entityId: stopId,
      details: {
        'route_id': _activeRoute!.id,
        'reason': reason,
      },
    );
  }

  /// Mark stop as client no-show.
  Future<void> markStopNoShow(
    SecurityContext context,
    String stopId, {
    String? notes,
  }) async {
    if (_activeRoute == null) return;

    await _routeRepository.updateStopStatus(
      context,
      _activeRoute!.id,
      stopId,
      RouteStopStatus.clientNoShow,
      notes: notes,
    );

    _arrivedStopIds.add(stopId);

    // Refresh active route
    _activeRoute = await _routeRepository.getRoute(context, _activeRoute!.id);

    await _logAudit(
      context: context,
      action: 'route_stop_noshow',
      entityType: 'routeStop',
      entityId: stopId,
      details: {
        'route_id': _activeRoute!.id,
      },
    );
  }

  // ============ Distance Calculation ============

  /// Calculate distance between two points using Haversine formula.
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _geocodingService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  // ============ Audit Logging ============

  Future<void> _logAudit({
    required SecurityContext context,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _auditLogRepository.log(
        context: context,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        source: 'RouteTrackingService',
      );
    } catch (e) {
      developer.log(
        'RouteTrackingService: Failed to log audit event: $e',
        name: 'RouteTrackingService',
      );
    }
  }

  // ============ Cleanup ============

  /// Dispose of resources.
  void dispose() {
    _etaUpdateTimer?.cancel();
    _etaController.close();
    _geofenceController.close();
    _locationController.close();
  }
}
