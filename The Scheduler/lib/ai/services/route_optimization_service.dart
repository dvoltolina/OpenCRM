import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../core/config/ai_config.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/ai_exceptions.dart';
import '../models/optimized_route.dart';
import '../models/route_optimization_request.dart';
import '../models/route_stop.dart';
import '../models/travel_segment.dart';
import '../repositories/route_repository.dart';
import 'ai_client.dart';

/// Service for optimizing routes via the Python AI backend.
///
/// **HIPAA Compliance:**
/// - All route optimizations are logged for audit
/// - Client location data is PHI when linked to appointments
/// - SecurityContext ensures multi-tenant isolation
/// - API calls include businessId for server-side validation
///
/// **Offline Support:**
/// - Queues requests when offline
/// - Returns cached routes when available
/// - Syncs queued requests when connectivity restored
class RouteOptimizationService {
  final AIClient _aiClient;
  final AIConfig _config;
  final RouteRepository _routeRepository;
  final AuditLogRepository _auditLogRepository;

  /// Pending offline requests (in-memory queue)
  final List<_PendingRouteRequest> _offlineQueue = [];

  /// Whether currently processing offline queue
  bool _processingQueue = false;

  RouteOptimizationService({
    required AIClient aiClient,
    required AIConfig config,
    RouteRepository? routeRepository,
    AuditLogRepository? auditLogRepository,
  })  : _aiClient = aiClient,
        _config = config,
        _routeRepository = routeRepository ?? RouteRepository(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  // ============ Route Optimization ============

  /// Optimize a route for a provider's day.
  ///
  /// Returns an [OptimizedRoute] with stops in optimal order.
  /// Throws [AIException] variants on failure.
  ///
  /// **HIPAA**: Logs route optimization request for audit.
  Future<OptimizedRoute> optimizeRoute(
    SecurityContext context,
    RouteOptimizationRequest request,
  ) async {
    // Verify business access
    context.verifyBusinessAccess(request.businessId);

    // Validate request
    if (!request.isValid) {
      throw AIValidationException(
        message: 'Invalid route optimization request',
        endpoint: _config.routeEndpoint,
        validationErrors: _validateRequest(request),
      );
    }

    try {
      // Build API request body
      final body = _buildRequestBody(request);

      // Call route optimization API
      final response = await _aiClient.post(
        _config.routeEndpoint,
        body,
        timeoutMs: _config.readTimeoutMs,
        additionalHeaders: {
          'X-Business-ID': context.businessId,
        },
      );

      // Parse response
      final route = _parseRouteResponse(response, request);

      // Save to repository
      await _routeRepository.saveRoute(context, route);

      // Log audit event
      await _logAudit(
        context: context,
        action: 'ai_route_optimization_success',
        entityType: 'optimizedRoute',
        entityId: route.id,
        details: {
          'provider_id': request.providerId,
          'waypoints_count': request.waypoints.length,
          'total_distance_meters': route.totalDistanceMeters,
          'time_saved_seconds': route.timeSavedSeconds,
          'optimization_improvement_percent': route.optimizationImprovementPercent,
        },
      );

      return route;
    } on AICircuitBreakerOpenException {
      // Try to return cached route
      return _handleOfflineOptimization(context, request);
    } on AIServerUnavailableException {
      // Queue for later and return cached route
      return _handleOfflineOptimization(context, request);
    } on AITimeoutException catch (e) {
      // Log timeout
      await _logAudit(
        context: context,
        action: 'ai_route_optimization_timeout',
        entityType: 'optimizedRoute',
        entityId: request.providerId,
        details: {
          'timeout_ms': e.timeoutMs,
          'waypoints_count': request.waypoints.length,
        },
      );
      rethrow;
    } catch (e) {
      // Log failure
      await _logAudit(
        context: context,
        action: 'ai_route_optimization_failed',
        entityType: 'optimizedRoute',
        entityId: request.providerId,
        details: {
          'error': e.toString(),
          'waypoints_count': request.waypoints.length,
        },
      );
      rethrow;
    }
  }

  /// Re-optimize an existing route (e.g., after schedule change).
  ///
  /// Updates the existing route with new optimization.
  Future<OptimizedRoute> reoptimizeRoute(
    SecurityContext context,
    String routeId,
    RouteOptimizationRequest request,
  ) async {
    // Get existing route
    final existingRoute = await _routeRepository.getRoute(context, routeId);
    if (existingRoute == null) {
      throw AIException(
        message: 'Route not found',
        endpoint: _config.routeEndpoint,
      );
    }

    // Optimize with new request
    final newRoute = await optimizeRoute(context, request);

    // Return with original ID for continuity
    return newRoute.copyWith(
      id: routeId,
      notes: 'Re-optimized from previous route',
    );
  }

  /// Get cached route for a provider's day (when offline).
  Future<OptimizedRoute?> getCachedRoute(
    SecurityContext context,
    String providerId,
    DateTime date,
  ) async {
    return _routeRepository.getRouteForProviderDate(
      context,
      providerId,
      date,
    );
  }

  // ============ Offline Queue Management ============

  /// Process queued offline requests when connectivity restored.
  Future<void> processOfflineQueue(SecurityContext context) async {
    if (_processingQueue || _offlineQueue.isEmpty) return;

    _processingQueue = true;
    try {
      final pending = List<_PendingRouteRequest>.from(_offlineQueue);
      _offlineQueue.clear();

      for (final item in pending) {
        try {
          await optimizeRoute(context, item.request);
          debugPrint(
            'RouteOptimizationService: Processed queued request for ${item.request.providerId}',
          );
        } catch (e) {
          // Re-queue if still failing
          if (e is AIServerUnavailableException ||
              e is AICircuitBreakerOpenException) {
            _offlineQueue.add(item);
          }
          debugPrint(
            'RouteOptimizationService: Failed to process queued request: $e',
          );
        }
      }
    } finally {
      _processingQueue = false;
    }
  }

  /// Number of requests waiting in offline queue.
  int get pendingQueueCount => _offlineQueue.length;

  /// Clear offline queue (e.g., on logout).
  void clearOfflineQueue() {
    _offlineQueue.clear();
  }

  // ============ Route Status Updates ============

  /// Start following a route.
  Future<void> startRoute(SecurityContext context, String routeId) async {
    await _routeRepository.updateRouteStatus(
      context,
      routeId,
      RouteStatus.inProgress,
    );

    await _logAudit(
      context: context,
      action: 'ai_route_started',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {'started_at': DateTime.now().toIso8601String()},
    );
  }

  /// Complete a route.
  Future<void> completeRoute(SecurityContext context, String routeId) async {
    await _routeRepository.updateRouteStatus(
      context,
      routeId,
      RouteStatus.completed,
    );

    await _logAudit(
      context: context,
      action: 'ai_route_completed',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {'completed_at': DateTime.now().toIso8601String()},
    );
  }

  /// Cancel a route.
  Future<void> cancelRoute(
    SecurityContext context,
    String routeId, {
    String? reason,
  }) async {
    await _routeRepository.updateRouteStatus(
      context,
      routeId,
      RouteStatus.cancelled,
    );

    await _logAudit(
      context: context,
      action: 'ai_route_cancelled',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {
        'cancelled_at': DateTime.now().toIso8601String(),
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Mark route as needing re-optimization.
  Future<void> markNeedsReoptimization(
    SecurityContext context,
    String routeId, {
    String? reason,
  }) async {
    await _routeRepository.updateRouteStatus(
      context,
      routeId,
      RouteStatus.needsReoptimization,
    );

    await _logAudit(
      context: context,
      action: 'ai_route_needs_reoptimization',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {
        'flagged_at': DateTime.now().toIso8601String(),
        if (reason != null) 'reason': reason,
      },
    );
  }

  // ============ Stop Status Updates ============

  /// Update stop status (arrived, completed, etc.).
  Future<void> updateStopStatus(
    SecurityContext context,
    String routeId,
    String stopId,
    RouteStopStatus status, {
    DateTime? arrivalTime,
    DateTime? departureTime,
    String? notes,
  }) async {
    await _routeRepository.updateStopStatus(
      context,
      routeId,
      stopId,
      status,
      actualArrival: arrivalTime,
      actualDeparture: departureTime,
      notes: notes,
    );
  }

  // ============ Private Methods ============

  /// Build request body for API call.
  Map<String, dynamic> _buildRequestBody(RouteOptimizationRequest request) {
    return {
      'business_id': request.businessId,
      'provider_id': request.providerId,
      'route_date': request.routeDate.toIso8601String(),
      'depot_latitude': request.depotLatitude,
      'depot_longitude': request.depotLongitude,
      'depot_address': request.depotAddress,
      'return_to_depot': request.returnToDepot,
      if (request.endLatitude != null) 'end_latitude': request.endLatitude,
      if (request.endLongitude != null) 'end_longitude': request.endLongitude,
      if (request.endAddress != null) 'end_address': request.endAddress,
      'waypoints': request.waypoints
          .map((w) => {
                'id': w.id,
                'name': w.name,
                'latitude': w.latitude,
                'longitude': w.longitude,
                'window_start': w.windowStart.toIso8601String(),
                'window_end': w.windowEnd.toIso8601String(),
                'service_duration_minutes': w.serviceDurationMinutes,
                'priority': w.priority,
                'is_required': w.isRequired,
                if (w.clientId != null) 'client_id': w.clientId,
                if (w.appointmentId != null) 'appointment_id': w.appointmentId,
              })
          .toList(),
      'earliest_departure': request.earliestDeparture.toIso8601String(),
      'latest_return': request.latestReturn.toIso8601String(),
      if (request.maxDrivingMinutes != null)
        'max_driving_minutes': request.maxDrivingMinutes,
      'objective': request.objective.name,
      'include_breaks': request.includeBreaks,
      'break_duration_minutes': request.breakDurationMinutes,
      if (request.breakWindowStart != null)
        'break_window_start': request.breakWindowStart!.toIso8601String(),
      if (request.breakWindowEnd != null)
        'break_window_end': request.breakWindowEnd!.toIso8601String(),
      'buffer_between_stops_minutes': request.bufferBetweenStopsMinutes,
    };
  }

  /// Parse API response into OptimizedRoute.
  OptimizedRoute _parseRouteResponse(
    Map<String, dynamic> response,
    RouteOptimizationRequest request,
  ) {
    final now = DateTime.now();

    // Parse stops
    final stopsJson = response['stops'] as List<dynamic>? ?? [];
    final stops = stopsJson.map((s) => _parseStop(s as Map<String, dynamic>)).toList();

    // Parse segments
    final segmentsJson = response['segments'] as List<dynamic>? ?? [];
    final segments = segmentsJson
        .map((s) => _parseSegment(s as Map<String, dynamic>, response['id'] as String))
        .toList();

    return OptimizedRoute(
      id: response['id'] as String? ?? 'route_${now.millisecondsSinceEpoch}',
      businessId: request.businessId,
      providerId: request.providerId,
      providerName: response['provider_name'] as String? ?? '',
      routeDate: request.routeDate,
      status: RouteStatus.planned,
      stops: stops,
      segments: segments,
      startTime: DateTime.parse(
        response['start_time'] as String? ?? request.earliestDeparture.toIso8601String(),
      ),
      expectedEndTime: DateTime.parse(
        response['expected_end_time'] as String? ?? request.latestReturn.toIso8601String(),
      ),
      totalDistanceMeters: response['total_distance_meters'] as int? ?? 0,
      totalTravelTimeSeconds: response['total_travel_time_seconds'] as int? ?? 0,
      totalServiceTimeSeconds: response['total_service_time_seconds'] as int? ??
          request.waypoints.fold(0, (sum, w) => sum + w.serviceDurationMinutes * 60),
      originalDistanceMeters: response['original_distance_meters'] as int?,
      originalTravelTimeSeconds: response['original_travel_time_seconds'] as int?,
      distanceSavedMeters: response['distance_saved_meters'] as int?,
      timeSavedSeconds: response['time_saved_seconds'] as int?,
      optimizationImprovementPercent:
          (response['optimization_improvement_percent'] as num?)?.toDouble(),
      objective: request.objective,
      optimizerVersion: response['optimizer_version'] as String? ?? '1.0.0',
      optimizedAt: now,
      updatedAt: now,
    );
  }

  /// Parse a stop from API response.
  RouteStop _parseStop(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String,
      sequenceOrder: json['sequence_order'] as int,
      stopType: _parseStopType(json['stop_type'] as String?),
      status: RouteStopStatus.pending,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      arrivalNotes: json['arrival_notes'] as String?,
      windowStart: DateTime.parse(json['window_start'] as String),
      windowEnd: DateTime.parse(json['window_end'] as String),
      scheduledArrival: DateTime.parse(json['scheduled_arrival'] as String),
      serviceDurationMinutes: json['service_duration_minutes'] as int? ?? 0,
      bufferMinutes: json['buffer_minutes'] as int? ?? 0,
      appointmentId: json['appointment_id'] as String?,
      clientId: json['client_id'] as String?,
      serviceId: json['service_id'] as String?,
      serviceName: json['service_name'] as String?,
      travelToNextMinutes: json['travel_to_next_minutes'] as int?,
      distanceToNextMeters: json['distance_to_next_meters'] as int?,
      updatedAt: DateTime.now(),
    );
  }

  /// Parse stop type from string.
  RouteStopType _parseStopType(String? type) {
    switch (type) {
      case 'depot':
        return RouteStopType.depot;
      case 'appointment':
        return RouteStopType.appointment;
      case 'breakStop':
      case 'break':
        return RouteStopType.breakStop;
      case 'endDepot':
      case 'end_depot':
        return RouteStopType.endDepot;
      default:
        return RouteStopType.appointment;
    }
  }

  /// Parse a segment from API response.
  TravelSegment _parseSegment(Map<String, dynamic> json, String routeId) {
    return TravelSegment(
      id: json['id'] as String? ?? 'seg_${DateTime.now().millisecondsSinceEpoch}',
      routeId: routeId,
      fromStopId: json['from_stop_id'] as String,
      toStopId: json['to_stop_id'] as String,
      sequenceOrder: json['sequence_order'] as int,
      distanceMeters: json['distance_meters'] as int,
      estimatedDurationSeconds: json['estimated_duration_seconds'] as int,
      trafficCondition: TrafficCondition.unknown,
      encodedPolyline: json['encoded_polyline'] as String?,
      fromLatitude: (json['from_latitude'] as num).toDouble(),
      fromLongitude: (json['from_longitude'] as num).toDouble(),
      toLatitude: (json['to_latitude'] as num).toDouble(),
      toLongitude: (json['to_longitude'] as num).toDouble(),
      calculatedAt: DateTime.now(),
      routingSource: json['routing_source'] as String? ?? 'osrm',
    );
  }

  /// Handle optimization when offline - queue and return cached.
  Future<OptimizedRoute> _handleOfflineOptimization(
    SecurityContext context,
    RouteOptimizationRequest request,
  ) async {
    // Queue for later
    _offlineQueue.add(_PendingRouteRequest(
      request: request,
      queuedAt: DateTime.now(),
    ));

    // Try to return cached route
    final cached = await getCachedRoute(
      context,
      request.providerId,
      request.routeDate,
    );

    if (cached != null) {
      // Mark as needing re-optimization
      return cached.copyWith(status: RouteStatus.needsReoptimization);
    }

    // No cached route available
    throw AIServerUnavailableException(
      endpoint: _config.routeEndpoint,
      originalError: 'No cached route available for offline use',
    );
  }

  /// Validate request and return errors.
  List<String> _validateRequest(RouteOptimizationRequest request) {
    final errors = <String>[];

    if (request.waypoints.isEmpty) {
      errors.add('At least one waypoint is required');
    }

    if (!request.earliestDeparture.isBefore(request.latestReturn)) {
      errors.add('Earliest departure must be before latest return');
    }

    for (final waypoint in request.waypoints) {
      if (!waypoint.windowStart.isBefore(waypoint.windowEnd)) {
        errors.add('Waypoint ${waypoint.id}: window start must be before end');
      }
    }

    return errors;
  }

  /// Log audit event (best-effort, non-blocking).
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
        source: 'RouteOptimizationService',
      );
    } catch (e) {
      developer.log(
        'RouteOptimizationService: Failed to log audit event: $e',
        name: 'RouteOptimizationService',
      );
    }
  }
}

/// Pending route request for offline queue.
class _PendingRouteRequest {
  final RouteOptimizationRequest request;
  final DateTime queuedAt;

  _PendingRouteRequest({
    required this.request,
    required this.queuedAt,
  });
}

/// Validation exception with specific errors.
class AIValidationException extends AIException {
  final List<String> validationErrors;

  AIValidationException({
    required super.message,
    required super.endpoint,
    required this.validationErrors,
  });

  @override
  String toString() =>
      'AIValidationException: $message - ${validationErrors.join(', ')}';
}
