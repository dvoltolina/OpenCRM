import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/ai_config.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/models/security_context.dart';
import '../models/ai_health_status.dart';
import '../models/geocode_result.dart';
import '../models/optimized_route.dart';
import '../models/route_optimization_request.dart';
import '../models/route_stop.dart';
import '../repositories/geocode_cache_repository.dart';
import '../repositories/route_repository.dart';
import '../services/ai_client.dart';
import '../services/geocoding_service.dart';
import '../services/gps_location_service.dart';
import '../services/route_optimization_service.dart';
import '../services/route_tracking_service.dart';
import 'prediction_providers.dart';

// ============ Service Providers ============

/// Provider for geocoding configuration.
final geocodingConfigProvider = Provider<GeocodingConfig>((ref) {
  // Use development config by default
  // Override in production with Google API key
  return GeocodingConfig.development();
});

/// Provider for geocode cache repository.
final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  );
});

/// Provider for route repository.
final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  );
});

/// Provider for geocoding service.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final config = ref.watch(geocodingConfigProvider);
  final cacheRepo = ref.watch(geocodeCacheRepositoryProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);

  final service = GeocodingService(
    config: config,
    cacheRepository: cacheRepo,
    auditLogRepository: auditLog,
  );

  ref.onDispose(() => service.close());

  return service;
});

/// Provider for route optimization service.
final routeOptimizationServiceProvider =
    Provider<RouteOptimizationService>((ref) {
  final aiClient = ref.watch(aiClientProvider);
  final aiConfig = ref.watch(aiConfigProvider);
  final routeRepo = ref.watch(routeRepositoryProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);

  return RouteOptimizationService(
    aiClient: aiClient,
    config: aiConfig,
    routeRepository: routeRepo,
    auditLogRepository: auditLog,
  );
});

/// Provider for route tracking configuration.
final routeTrackingConfigProvider = Provider<RouteTrackingConfig>((ref) {
  return const RouteTrackingConfig();
});

/// Provider for route tracking service.
final routeTrackingServiceProvider = Provider<RouteTrackingService>((ref) {
  final config = ref.watch(routeTrackingConfigProvider);
  final routeRepo = ref.watch(routeRepositoryProvider);
  final geocoding = ref.watch(geocodingServiceProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);

  final service = RouteTrackingService(
    config: config,
    routeRepository: routeRepo,
    geocodingService: geocoding,
    auditLogRepository: auditLog,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

// ============ GPS Location Providers ============

/// Provider for GPS location service configuration.
final gpsLocationConfigProvider = Provider<GpsLocationConfig>((ref) {
  return GpsLocationConfig.routeTracking;
});

/// Provider for GPS location service.
final gpsLocationServiceProvider = Provider<GpsLocationService>((ref) {
  final config = ref.watch(gpsLocationConfigProvider);
  final service = GpsLocationService(config: config);

  ref.onDispose(() => service.dispose());

  return service;
});

/// Stream provider for GPS location updates.
final gpsLocationStreamProvider = StreamProvider<CurrentLocation>((ref) {
  final service = ref.watch(gpsLocationServiceProvider);
  return service.locationStream;
});

/// Provider for current GPS permission status.
final gpsPermissionStatusProvider = FutureProvider<LocationPermissionStatus>((ref) async {
  final service = ref.watch(gpsLocationServiceProvider);
  return service.checkPermissionStatus();
});

// ============ Route Optimization Providers ============

/// Parameters for route optimization request.
typedef RouteOptimizationParams = ({
  SecurityContext context,
  RouteOptimizationRequest request,
});

/// Family provider for route optimization.
///
/// Usage:
/// ```dart
/// final result = await ref.read(
///   optimizeRouteProvider((
///     context: securityContext,
///     request: routeRequest,
///   )).future,
/// );
/// ```
final optimizeRouteProvider =
    FutureProvider.family<OptimizedRoute, RouteOptimizationParams>(
  (ref, params) async {
    final service = ref.watch(routeOptimizationServiceProvider);
    return service.optimizeRoute(params.context, params.request);
  },
);

/// Parameters for fetching a provider's route.
typedef ProviderRouteParams = ({
  SecurityContext context,
  String providerId,
  DateTime date,
});

/// Family provider for fetching a provider's route for a date.
///
/// Usage:
/// ```dart
/// final route = ref.watch(
///   providerRouteProvider((
///     context: securityContext,
///     providerId: 'provider_123',
///     date: DateTime.now(),
///   )),
/// );
/// ```
final providerRouteProvider =
    FutureProvider.family<OptimizedRoute?, ProviderRouteParams>(
  (ref, params) async {
    final routeRepo = ref.watch(routeRepositoryProvider);
    return routeRepo.getRouteForProviderDate(
      params.context,
      params.providerId,
      params.date,
    );
  },
);

/// Stream provider for real-time route updates.
///
/// Usage:
/// ```dart
/// final routeAsync = ref.watch(
///   providerRouteStreamProvider((
///     context: securityContext,
///     providerId: 'provider_123',
///     date: DateTime.now(),
///   )),
/// );
/// ```
final providerRouteStreamProvider =
    StreamProvider.family<OptimizedRoute?, ProviderRouteParams>(
  (ref, params) {
    final routeRepo = ref.watch(routeRepositoryProvider);
    return routeRepo.watchRouteForProviderDate(
      params.context,
      params.providerId,
      params.date,
    );
  },
);

// ============ Active Route State ============

/// State for the currently active route being tracked.
class ActiveRouteState {
  final OptimizedRoute? route;
  final bool isTracking;
  final CurrentLocation? lastLocation;
  final EtaUpdate? currentEta;
  final String? error;

  const ActiveRouteState({
    this.route,
    this.isTracking = false,
    this.lastLocation,
    this.currentEta,
    this.error,
  });

  ActiveRouteState copyWith({
    OptimizedRoute? route,
    bool? isTracking,
    CurrentLocation? lastLocation,
    EtaUpdate? currentEta,
    String? error,
  }) {
    return ActiveRouteState(
      route: route ?? this.route,
      isTracking: isTracking ?? this.isTracking,
      lastLocation: lastLocation ?? this.lastLocation,
      currentEta: currentEta ?? this.currentEta,
      error: error,
    );
  }

  /// Current stop (first non-completed stop).
  RouteStop? get currentStop => route?.currentStop;

  /// Next stop after current.
  RouteStop? get nextStop => route?.nextStop;

  /// Progress percentage (0.0-1.0).
  double get progressPercent => route?.progressPercent ?? 0.0;

  /// Whether route is complete.
  bool get isComplete => route?.status == RouteStatus.completed;

  /// Whether running late.
  bool get isRunningLate => route?.isRunningLate ?? false;
}

/// StateNotifier for active route management.
class ActiveRouteNotifier extends StateNotifier<ActiveRouteState> {
  final RouteTrackingService _trackingService;
  final RouteOptimizationService _optimizationService;
  final RouteRepository _routeRepository;

  StreamSubscription<EtaUpdate>? _etaSubscription;
  StreamSubscription<CurrentLocation>? _locationSubscription;
  StreamSubscription<GeofenceTrigger>? _geofenceSubscription;

  ActiveRouteNotifier({
    required RouteTrackingService trackingService,
    required RouteOptimizationService optimizationService,
    required RouteRepository routeRepository,
  })  : _trackingService = trackingService,
        _optimizationService = optimizationService,
        _routeRepository = routeRepository,
        super(const ActiveRouteState()) {
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _etaSubscription = _trackingService.etaUpdates.listen((eta) {
      state = state.copyWith(currentEta: eta);
    });

    _locationSubscription = _trackingService.locationUpdates.listen((loc) {
      state = state.copyWith(lastLocation: loc);
    });

    _geofenceSubscription = _trackingService.geofenceEvents.listen((trigger) {
      // Refresh route on geofence events
      if (state.route != null) {
        _refreshRoute();
      }
    });
  }

  /// Start tracking a route.
  Future<void> startTracking(
    SecurityContext context,
    OptimizedRoute route,
  ) async {
    try {
      await _trackingService.startTracking(context, route);

      // Update route status to in progress
      await _optimizationService.startRoute(context, route.id);

      // Refresh to get updated status
      final updated = await _routeRepository.getRoute(context, route.id);

      state = state.copyWith(
        route: updated ?? route,
        isTracking: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stop tracking.
  Future<void> stopTracking(SecurityContext context) async {
    await _trackingService.stopTracking(context);
    state = state.copyWith(isTracking: false);
  }

  /// Complete the route.
  Future<void> completeRoute(SecurityContext context) async {
    if (state.route == null) return;

    try {
      await _optimizationService.completeRoute(context, state.route!.id);
      await _trackingService.stopTracking(context);

      final updated = await _routeRepository.getRoute(context, state.route!.id);
      state = state.copyWith(
        route: updated,
        isTracking: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Cancel the route.
  Future<void> cancelRoute(SecurityContext context, {String? reason}) async {
    if (state.route == null) return;

    try {
      await _optimizationService.cancelRoute(
        context,
        state.route!.id,
        reason: reason,
      );
      await _trackingService.stopTracking(context);

      state = const ActiveRouteState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update location.
  Future<void> updateLocation(
    SecurityContext context,
    CurrentLocation location,
  ) async {
    await _trackingService.updateLocation(context, location);
  }

  /// Mark current stop as completed.
  Future<void> completeCurrentStop(
    SecurityContext context, {
    String? notes,
  }) async {
    final current = state.currentStop;
    if (current == null) return;

    await _trackingService.markStopCompleted(
      context,
      current.id,
      notes: notes,
    );
    await _refreshRoute();
  }

  /// Skip current stop.
  Future<void> skipCurrentStop(
    SecurityContext context, {
    String? reason,
  }) async {
    final current = state.currentStop;
    if (current == null) return;

    await _trackingService.markStopSkipped(
      context,
      current.id,
      reason: reason,
    );
    await _refreshRoute();
  }

  /// Mark current stop as no-show.
  Future<void> markNoShow(SecurityContext context, {String? notes}) async {
    final current = state.currentStop;
    if (current == null) return;

    await _trackingService.markStopNoShow(context, current.id, notes: notes);
    await _refreshRoute();
  }

  Future<void> _refreshRoute() async {
    final updatedRoute = _trackingService.activeRoute;
    if (updatedRoute != null) {
      state = state.copyWith(route: updatedRoute);
    }
  }

  @override
  void dispose() {
    _etaSubscription?.cancel();
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for active route state.
final activeRouteProvider =
    StateNotifierProvider<ActiveRouteNotifier, ActiveRouteState>((ref) {
  final trackingService = ref.watch(routeTrackingServiceProvider);
  final optimizationService = ref.watch(routeOptimizationServiceProvider);
  final routeRepo = ref.watch(routeRepositoryProvider);

  return ActiveRouteNotifier(
    trackingService: trackingService,
    optimizationService: optimizationService,
    routeRepository: routeRepo,
  );
});

// ============ Geocoding Providers ============

/// Parameters for geocoding.
typedef GeocodeParams = ({
  SecurityContext context,
  String address,
  String? clientId,
});

/// Family provider for geocoding addresses.
///
/// Usage:
/// ```dart
/// final result = await ref.read(
///   geocodeAddressProvider((
///     context: securityContext,
///     address: '123 Main St, City, ST',
///     clientId: 'client_123',
///   )).future,
/// );
/// ```
final geocodeAddressProvider =
    FutureProvider.family<GeocodeResult?, GeocodeParams>(
  (ref, params) async {
    final service = ref.watch(geocodingServiceProvider);
    return service.geocodeAddress(
      params.context,
      params.address,
      clientId: params.clientId,
    );
  },
);

/// Parameters for reverse geocoding.
typedef ReverseGeocodeParams = ({
  SecurityContext context,
  double latitude,
  double longitude,
});

/// Family provider for reverse geocoding.
final reverseGeocodeProvider =
    FutureProvider.family<GeocodeResult?, ReverseGeocodeParams>(
  (ref, params) async {
    final service = ref.watch(geocodingServiceProvider);
    return service.reverseGeocode(
      params.context,
      params.latitude,
      params.longitude,
    );
  },
);

// ============ Helper Providers ============

/// Provider for offline queue count.
final offlineQueueCountProvider = Provider<int>((ref) {
  final service = ref.watch(routeOptimizationServiceProvider);
  return service.pendingQueueCount;
});

/// Provider to check if route optimization is available.
final routeOptimizationAvailableProvider = FutureProvider<bool>((ref) async {
  final aiClient = ref.watch(aiClientProvider);
  try {
    final health = await aiClient.checkHealth();
    return health.routingService.isHealthy;
  } catch (_) {
    return false;
  }
});
