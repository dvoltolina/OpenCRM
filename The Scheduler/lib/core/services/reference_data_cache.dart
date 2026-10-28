import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/location.dart';
import '../../data/models/provider.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/repositories/locations_repository.dart';
import '../../data/repositories/providers_repository.dart';
import '../../data/repositories/services_repository.dart';

/// Singleton cache for reference data (Services, Providers, Locations).
///
/// These collections rarely change and are accessed frequently throughout
/// the app. Caching them reduces Firebase reads significantly.
///
/// Features:
/// - TTL-based expiration (default 5 minutes)
/// - Automatic initialization on first access
/// - Business-aware: clears cache when switching businesses
/// - Memory-efficient: uses one-time fetches instead of streams
///
/// Usage:
/// ```dart
/// // In StreamBuilder - just pass context, cache handles the rest
/// StreamBuilder<List<Service>>(
///   stream: ReferenceDataCache.instance.watchServices(securityContext),
///   ...
/// )
/// ```
class ReferenceDataCache {
  ReferenceDataCache._();

  static final ReferenceDataCache instance = ReferenceDataCache._();

  /// Cache TTL - data refreshes after this duration
  static const Duration cacheTtl = Duration(minutes: 5);

  // Repositories
  final _servicesRepository = ServicesRepository();
  final _providersRepository = ProvidersRepository();
  final _locationsRepository = LocationsRepository();

  // Cached data with timestamps
  List<Service>? _servicesCache;
  List<Provider>? _providersCache;
  List<Location>? _locationsCache;
  DateTime? _servicesCacheTime;
  DateTime? _providersCacheTime;
  DateTime? _locationsCacheTime;

  // Stream controllers for broadcasting cached data
  StreamController<List<Service>>? _servicesController;
  StreamController<List<Provider>>? _providersController;
  StreamController<List<Location>>? _locationsController;

  // Track current business to detect switches
  String? _currentBusinessId;

  // Loading state to prevent duplicate fetches
  bool _loadingServices = false;
  bool _loadingProviders = false;
  bool _loadingLocations = false;

  /// Watch services with automatic caching.
  /// Pass the security context - cache handles initialization automatically.
  Stream<List<Service>> watchServices(SecurityContext context) {
    _ensureBusinessContext(context);
    _ensureServicesController();

    // Emit cached data immediately if available and valid
    if (_servicesCache != null && !_isCacheExpired(_servicesCacheTime)) {
      // Use microtask to emit after stream subscription
      Future.microtask(() => _servicesController?.add(_servicesCache!));
    } else {
      _refreshServices(context);
    }

    return _servicesController!.stream;
  }

  /// Watch providers with automatic caching.
  Stream<List<Provider>> watchProviders(SecurityContext context) {
    _ensureBusinessContext(context);
    _ensureProvidersController();

    if (_providersCache != null && !_isCacheExpired(_providersCacheTime)) {
      Future.microtask(() => _providersController?.add(_providersCache!));
    } else {
      _refreshProviders(context);
    }

    return _providersController!.stream;
  }

  /// Watch locations with automatic caching.
  Stream<List<Location>> watchLocations(SecurityContext context) {
    _ensureBusinessContext(context);
    _ensureLocationsController();

    if (_locationsCache != null && !_isCacheExpired(_locationsCacheTime)) {
      Future.microtask(() => _locationsController?.add(_locationsCache!));
    } else {
      _refreshLocations(context);
    }

    return _locationsController!.stream;
  }

  /// Get cached services synchronously (returns empty list if not loaded).
  List<Service> get cachedServices => _servicesCache ?? [];

  /// Get cached providers synchronously (returns empty list if not loaded).
  List<Provider> get cachedProviders => _providersCache ?? [];

  /// Get cached locations synchronously (returns empty list if not loaded).
  List<Location> get cachedLocations => _locationsCache ?? [];

  /// Force refresh all cached data.
  Future<void> refresh(SecurityContext context) async {
    _ensureBusinessContext(context);
    await Future.wait([
      _refreshServices(context, force: true),
      _refreshProviders(context, force: true),
      _refreshLocations(context, force: true),
    ]);
  }

  /// Invalidate cache for a specific type (call after mutations).
  void invalidateServices() {
    _servicesCacheTime = null;
    _servicesCache = null;
  }

  void invalidateProviders() {
    _providersCacheTime = null;
    _providersCache = null;
  }

  void invalidateLocations() {
    _locationsCacheTime = null;
    _locationsCache = null;
  }

  /// Clear all cached data (call on logout).
  void clear() {
    _clearCache();
    _currentBusinessId = null;
  }

  void _ensureBusinessContext(SecurityContext context) {
    if (_currentBusinessId != context.businessId) {
      // Business changed, clear cache
      _clearCache();
      _currentBusinessId = context.businessId;
      debugPrint('ReferenceDataCache: switched business context');
    }
  }

  void _ensureServicesController() {
    if (_servicesController == null || _servicesController!.isClosed) {
      _servicesController = StreamController<List<Service>>.broadcast();
    }
  }

  void _ensureProvidersController() {
    if (_providersController == null || _providersController!.isClosed) {
      _providersController = StreamController<List<Provider>>.broadcast();
    }
  }

  void _ensureLocationsController() {
    if (_locationsController == null || _locationsController!.isClosed) {
      _locationsController = StreamController<List<Location>>.broadcast();
    }
  }

  bool _isCacheExpired(DateTime? cacheTime) {
    if (cacheTime == null) return true;
    return DateTime.now().difference(cacheTime) > cacheTtl;
  }

  Future<void> _refreshServices(SecurityContext context, {bool force = false}) async {
    if (!force && !_isCacheExpired(_servicesCacheTime)) return;
    if (_loadingServices) return; // Prevent duplicate fetches

    _loadingServices = true;
    try {
      final services = await _servicesRepository.getServices(context: context);
      _servicesCache = services;
      _servicesCacheTime = DateTime.now();
      _servicesController?.add(services);
      debugPrint('ReferenceDataCache: services refreshed (${services.length} items)');
    } catch (e) {
      debugPrint('ReferenceDataCache: error refreshing services');
      // Emit cached data if available, or empty list
      _servicesController?.add(_servicesCache ?? []);
    } finally {
      _loadingServices = false;
    }
  }

  Future<void> _refreshProviders(SecurityContext context, {bool force = false}) async {
    if (!force && !_isCacheExpired(_providersCacheTime)) return;
    if (_loadingProviders) return;

    _loadingProviders = true;
    try {
      final providers = await _providersRepository.getProviders(context: context);
      _providersCache = providers;
      _providersCacheTime = DateTime.now();
      _providersController?.add(providers);
      debugPrint('ReferenceDataCache: providers refreshed (${providers.length} items)');
    } catch (e) {
      debugPrint('ReferenceDataCache: error refreshing providers');
      _providersController?.add(_providersCache ?? []);
    } finally {
      _loadingProviders = false;
    }
  }

  Future<void> _refreshLocations(SecurityContext context, {bool force = false}) async {
    if (!force && !_isCacheExpired(_locationsCacheTime)) return;
    if (_loadingLocations) return;

    _loadingLocations = true;
    try {
      final locations = await _locationsRepository.getLocations(context: context);
      _locationsCache = locations;
      _locationsCacheTime = DateTime.now();
      _locationsController?.add(locations);
      debugPrint('ReferenceDataCache: locations refreshed (${locations.length} items)');
    } catch (e) {
      debugPrint('ReferenceDataCache: error refreshing locations');
      _locationsController?.add(_locationsCache ?? []);
    } finally {
      _loadingLocations = false;
    }
  }

  void _clearCache() {
    _servicesController?.close();
    _providersController?.close();
    _locationsController?.close();
    _servicesController = null;
    _providersController = null;
    _locationsController = null;

    _servicesCache = null;
    _providersCache = null;
    _locationsCache = null;
    _servicesCacheTime = null;
    _providersCacheTime = null;
    _locationsCacheTime = null;
    _loadingServices = false;
    _loadingProviders = false;
    _loadingLocations = false;
  }
}
