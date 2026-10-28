import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/optimized_route.dart';
import '../models/route_stop.dart';
import '../extensions/location_routing_extension.dart';
import '../extensions/client_routing_extension.dart';

/// Repository for optimized routes.
///
/// **CRITICAL HIPAA COMPLIANCE**:
/// - All route operations are logged for HIPAA compliance
/// - Location data is PHI when linked to client appointments
/// - Client service addresses are PHI and require audit logging
/// - Multi-tenant isolation is enforced via SecurityContext
class RouteRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  RouteRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  // ============ Collection References ============

  CollectionReference<Map<String, dynamic>> _routesCollection(
      String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('optimizedRoutes');
  }

  CollectionReference<Map<String, dynamic>> _locationRoutingCollection(
    String businessId,
    String locationId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('locations')
        .doc(locationId)
        .collection('routing');
  }

  CollectionReference<Map<String, dynamic>> _clientRoutingCollection(
    String businessId,
    String clientId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clients')
        .doc(clientId)
        .collection('routing');
  }

  // ============ Audit Logging Helpers ============

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
        source: 'RouteRepository',
      );
    } catch (e) {
      developer.log(
        'RouteRepository: Failed to log audit event: $e',
        name: 'RouteRepository',
      );
    }
  }

  // ============ Route Operations ============

  /// Save an optimized route.
  /// **CRITICAL**: Logs route creation/update for HIPAA compliance.
  Future<void> saveRoute(SecurityContext context, OptimizedRoute route) async {
    // Verify business access
    context.verifyBusinessAccess(route.businessId);

    await _routesCollection(context.businessId).doc(route.id).set(_routeToJson(route));

    // **CRITICAL: Log route optimization for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_write',
      entityType: 'optimizedRoute',
      entityId: route.id,
      details: {
        'provider_id': route.providerId,
        'route_date': route.routeDate.toIso8601String(),
        'stops_count': route.stops.length,
        'total_distance_meters': route.totalDistanceMeters,
        'route_status': route.status.name,
      },
    );
  }

  /// Convert route to JSON, handling nested objects
  Map<String, dynamic> _routeToJson(OptimizedRoute route) {
    final json = route.toJson();
    // Ensure stops and segments are properly serialized
    json['stops'] = route.stops.map((s) => s.toJson()).toList();
    json['segments'] = route.segments.map((s) => s.toJson()).toList();
    return json;
  }

  /// Get a route by ID.
  /// **CRITICAL**: Logs PHI read for HIPAA compliance.
  Future<OptimizedRoute?> getRoute(
    SecurityContext context,
    String routeId,
  ) async {
    final doc = await _routesCollection(context.businessId).doc(routeId).get();
    if (!doc.exists || doc.data() == null) return null;

    final route = OptimizedRoute.fromJson(doc.data()!);

    // Verify provider access (staff can only see their own routes unless admin)
    _verifyProviderAccess(context, route.providerId);

    // **CRITICAL: Log PHI read for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_read',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {
        'provider_id': route.providerId,
        'route_date': route.routeDate.toIso8601String(),
        'stops_count': route.stops.length,
      },
    );

    return route;
  }

  /// Verify the caller has access to the specified provider's data.
  void _verifyProviderAccess(SecurityContext context, String providerId) {
    // Admins and owners can access any provider
    if (context.isAdmin || context.isOwner) return;

    // Staff members can only access their own data
    if (context.providerId != null && context.providerId != providerId) {
      throw SecurityException(
        'Access denied: User cannot access provider $providerId routes',
      );
    }
  }

  /// Get route for a provider on a specific date.
  /// **CRITICAL**: Logs PHI read for HIPAA compliance.
  Future<OptimizedRoute?> getRouteForProviderDate(
    SecurityContext context,
    String providerId,
    DateTime date,
  ) async {
    // Verify provider access
    _verifyProviderAccess(context, providerId);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _routesCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('routeDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('routeDate', isLessThan: endOfDay.toIso8601String())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final route = OptimizedRoute.fromJson(snapshot.docs.first.data());

    // **CRITICAL: Log PHI read for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_read',
      entityType: 'optimizedRoute',
      entityId: route.id,
      details: {
        'provider_id': providerId,
        'route_date': date.toIso8601String(),
        'query_type': 'by_provider_date',
      },
    );

    return route;
  }

  /// Get all routes for a provider in a date range.
  /// **CRITICAL**: Logs batch PHI read for HIPAA compliance.
  Future<List<OptimizedRoute>> getRoutesForProvider(
    SecurityContext context,
    String providerId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Verify provider access
    _verifyProviderAccess(context, providerId);

    final snapshot = await _routesCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('routeDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('routeDate', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('routeDate')
        .get();

    final routes = snapshot.docs
        .map((doc) => OptimizedRoute.fromJson(doc.data()))
        .toList();

    // **CRITICAL: Log batch PHI read for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_read_batch',
      entityType: 'optimizedRoute',
      entityId: providerId,
      details: {
        'provider_id': providerId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'routes_returned': routes.length,
      },
    );

    return routes;
  }

  /// Update route status.
  /// **CRITICAL**: Logs status update for HIPAA compliance.
  Future<void> updateRouteStatus(
    SecurityContext context,
    String routeId,
    RouteStatus status,
  ) async {
    // Verify the route exists and user has access
    final existingRoute = await getRoute(context, routeId);
    if (existingRoute == null) return;

    await _routesCollection(context.businessId).doc(routeId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // **CRITICAL: Log status update for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_status_update',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {
        'new_status': status.name,
        'provider_id': existingRoute.providerId,
      },
    );
  }

  /// Update a stop's status.
  /// **CRITICAL**: Logs stop status update for HIPAA compliance.
  Future<void> updateStopStatus(
    SecurityContext context,
    String routeId,
    String stopId,
    RouteStopStatus status, {
    DateTime? actualArrival,
    DateTime? actualDeparture,
    String? notes,
  }) async {
    final route = await getRoute(context, routeId);
    if (route == null) return;

    final updatedStops = route.stops.map((stop) {
      if (stop.id == stopId) {
        return stop.copyWith(
          status: status,
          actualArrival: actualArrival ?? stop.actualArrival,
          actualDeparture: actualDeparture ?? stop.actualDeparture,
          providerNotes: notes ?? stop.providerNotes,
          updatedAt: DateTime.now(),
        );
      }
      return stop;
    }).toList();

    await _routesCollection(context.businessId).doc(routeId).update({
      'stops': updatedStops.map((s) => s.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // **CRITICAL: Log stop status update for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_stop_update',
      entityType: 'routeStop',
      entityId: stopId,
      details: {
        'route_id': routeId,
        'new_status': status.name,
        'has_arrival_time': actualArrival != null,
        'has_departure_time': actualDeparture != null,
      },
    );
  }

  /// Delete a route.
  /// **CRITICAL**: Logs deletion for HIPAA compliance.
  Future<void> deleteRoute(SecurityContext context, String routeId) async {
    // Verify the route exists and user has access (also logs the read)
    final existingRoute = await getRoute(context, routeId);
    if (existingRoute == null) return;

    await _routesCollection(context.businessId).doc(routeId).delete();

    // **CRITICAL: Log deletion for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'ai_route_delete',
      entityType: 'optimizedRoute',
      entityId: routeId,
      details: {
        'provider_id': existingRoute.providerId,
        'route_date': existingRoute.routeDate.toIso8601String(),
      },
    );
  }

  // ============ Location Routing Data ============

  /// Get routing data for a location.
  Future<LocationRoutingData?> getLocationRoutingData(
    SecurityContext context,
    String locationId,
  ) async {
    final doc =
        await _locationRoutingCollection(context.businessId, locationId)
            .doc('data')
            .get();
    if (!doc.exists || doc.data() == null) return null;
    return LocationRoutingData.fromJson(doc.data()!);
  }

  /// Save routing data for a location.
  Future<void> saveLocationRoutingData(
    SecurityContext context,
    String locationId,
    LocationRoutingData data,
  ) async {
    await _locationRoutingCollection(context.businessId, locationId)
        .doc('data')
        .set(data.toJson());
  }

  /// Get routing data for multiple locations.
  Future<Map<String, LocationRoutingData>> getLocationRoutingDataBatch(
    SecurityContext context,
    List<String> locationIds,
  ) async {
    final results = <String, LocationRoutingData>{};

    for (final locationId in locationIds) {
      final data = await getLocationRoutingData(context, locationId);
      if (data != null) {
        results[locationId] = data;
      }
    }

    return results;
  }

  // ============ Client Routing Data ============

  /// Get routing data for a client.
  /// **CRITICAL**: Client service addresses are PHI - logs access.
  Future<ClientRoutingData?> getClientRoutingData(
    SecurityContext context,
    String clientId,
  ) async {
    final doc = await _clientRoutingCollection(context.businessId, clientId)
        .doc('data')
        .get();
    if (!doc.exists || doc.data() == null) return null;

    final data = ClientRoutingData.fromJson(doc.data()!);

    // **CRITICAL: Log PHI read for HIPAA compliance**
    // Client service addresses are PHI
    await _logAudit(
      context: context,
      action: 'client_routing_read',
      entityType: 'clientRoutingData',
      entityId: clientId,
      details: {
        'has_service_address': data.hasServiceAddress,
        'has_coordinates': data.hasServiceCoordinates,
        'requires_mobile_service': data.requiresMobileService,
      },
    );

    return data;
  }

  /// Save routing data for a client.
  /// **CRITICAL**: Client service addresses are PHI - logs write.
  Future<void> saveClientRoutingData(
    SecurityContext context,
    String clientId,
    ClientRoutingData data,
  ) async {
    await _clientRoutingCollection(context.businessId, clientId)
        .doc('data')
        .set(data.toJson());

    // **CRITICAL: Log PHI write for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'client_routing_write',
      entityType: 'clientRoutingData',
      entityId: clientId,
      details: {
        'has_service_address': data.hasServiceAddress,
        'has_coordinates': data.hasServiceCoordinates,
        'requires_mobile_service': data.requiresMobileService,
      },
    );
  }

  /// Get routing data for multiple clients.
  /// **CRITICAL**: Client service addresses are PHI - logs batch access.
  Future<Map<String, ClientRoutingData>> getClientRoutingDataBatch(
    SecurityContext context,
    List<String> clientIds,
  ) async {
    final results = <String, ClientRoutingData>{};

    for (final clientId in clientIds) {
      // Each individual read is logged
      final data = await getClientRoutingData(context, clientId);
      if (data != null) {
        results[clientId] = data;
      }
    }

    // **CRITICAL: Log batch access summary for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'client_routing_read_batch',
      entityType: 'clientRoutingData',
      entityId: 'batch',
      details: {
        'clients_requested': clientIds.length,
        'clients_returned': results.length,
      },
    );

    return results;
  }

  /// Get all clients that need mobile service.
  /// **CRITICAL**: Accessing client data - logs the query.
  Future<List<String>> getMobileServiceClientIds(
    SecurityContext context,
  ) async {
    final clientsSnapshot = await _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('clients')
        .get();

    final mobileClientIds = <String>[];

    for (final clientDoc in clientsSnapshot.docs) {
      final routingDoc = await _clientRoutingCollection(
        context.businessId,
        clientDoc.id,
      ).doc('data').get();

      if (routingDoc.exists && routingDoc.data() != null) {
        final data = ClientRoutingData.fromJson(routingDoc.data()!);
        if (data.requiresMobileService) {
          mobileClientIds.add(clientDoc.id);
        }
      }
    }

    // **CRITICAL: Log mobile client query for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'mobile_clients_query',
      entityType: 'clientRoutingData',
      entityId: 'mobile_service_query',
      details: {
        'total_clients_scanned': clientsSnapshot.docs.length,
        'mobile_clients_found': mobileClientIds.length,
      },
    );

    return mobileClientIds;
  }

  /// Stream routes for a provider on a specific date (real-time updates).
  /// Note: Stream access is logged on initial subscription only.
  Stream<OptimizedRoute?> watchRouteForProviderDate(
    SecurityContext context,
    String providerId,
    DateTime date,
  ) {
    // Verify provider access synchronously
    _verifyProviderAccess(context, providerId);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Log stream subscription
    _logAudit(
      context: context,
      action: 'ai_route_stream_subscribe',
      entityType: 'optimizedRoute',
      entityId: providerId,
      details: {
        'provider_id': providerId,
        'route_date': date.toIso8601String(),
        'stream_type': 'realtime',
      },
    );

    return _routesCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('routeDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('routeDate', isLessThan: endOfDay.toIso8601String())
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return OptimizedRoute.fromJson(snapshot.docs.first.data());
    });
  }
}
