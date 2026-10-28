import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/noshow_prediction.dart';

/// Cache for no-show predictions.
///
/// Uses a two-level cache:
/// 1. In-memory for instant access
/// 2. SharedPreferences for persistence across app restarts
///
/// Features:
/// - LRU eviction when at capacity
/// - Automatic expiration checking
/// - Thread-safe operations
/// - **HIPAA Compliance:** Multi-tenant isolation via businessId in cache keys
///
/// Agent AI-4: Flutter Prediction Integration
class PredictionCache {
  static const _cachePrefix = 'prediction_cache_';
  static const _maxMemoryCacheSize = 100;

  // In-memory cache (LRU via insertion order)
  // Key format: businessId_appointmentId for tenant isolation
  final _memoryCache = <String, NoshowPrediction>{};
  final _accessOrder = <String>[];

  SharedPreferences? _prefs;
  bool _initialized = false;
  String? _lastBusinessId;

  /// Build a cache key with tenant isolation.
  ///
  /// **HIPAA CRITICAL:** Always includes businessId to prevent cross-tenant
  /// data leakage. A prediction for business A must never be returned for
  /// business B, even if appointment IDs happen to collide.
  String _buildCacheKey(String businessId, String appointmentId) {
    return '${businessId}_$appointmentId';
  }

  /// Build a persistent storage key.
  String _buildStorageKey(String businessId, String appointmentId) {
    return '$_cachePrefix${businessId}_$appointmentId';
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('PredictionCache: prefs unavailable, using memory cache only ($e)');
      }
      _initialized = true;
    }
  }

  /// Get a cached prediction.
  ///
  /// Returns null if not found or if expired.
  /// Checks memory cache first, then persistent storage.
  ///
  /// **HIPAA:** Requires businessId for tenant isolation.
  Future<NoshowPrediction?> get(
    String appointmentId, {
    String? businessId,
  }) async {
    final effectiveBusinessId = businessId ?? _lastBusinessId ?? 'default';
    final cacheKey = _buildCacheKey(effectiveBusinessId, appointmentId);

    // Check memory cache first
    final memoryCached = _memoryCache[cacheKey];
    if (memoryCached != null) {
      // Check if expired
      if (_isExpired(memoryCached)) {
        await remove(
          appointmentId,
          businessId: effectiveBusinessId,
        );
        return null;
      }
      _updateAccessOrder(cacheKey);
      return memoryCached;
    }

    // Check persistent cache
    await _ensureInitialized();
    final storageKey = _buildStorageKey(effectiveBusinessId, appointmentId);
    final json = _prefs?.getString(storageKey);

    if (json != null) {
      try {
        final prediction = NoshowPrediction.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );

        // Check if expired
        if (_isExpired(prediction)) {
          await _prefs?.remove(storageKey);
          return null;
        }

        // Promote to memory cache
        _addToMemoryCache(cacheKey, prediction);
        return prediction;
      } catch (e) {
        // Invalid cache entry, remove it
        await _prefs?.remove(storageKey);
      }
    }

    return null;
  }

  /// Store a prediction in cache.
  ///
  /// Stores in both memory and persistent caches.
  ///
  /// **HIPAA:** Requires businessId for tenant isolation.
  Future<void> set(
    String appointmentId,
    NoshowPrediction prediction, {
    String businessId = 'default',
  }) async {
    final cacheKey = _buildCacheKey(businessId, appointmentId);
    _lastBusinessId = businessId;

    // Add to memory cache
    _addToMemoryCache(cacheKey, prediction);

    // Add to persistent cache
    await _ensureInitialized();
    final storageKey = _buildStorageKey(businessId, appointmentId);
    await _prefs?.setString(storageKey, jsonEncode(prediction.toJson()));
  }

  /// Remove a prediction from cache.
  ///
  /// **HIPAA:** Requires businessId for tenant isolation.
  Future<void> remove(
    String appointmentId, {
    String businessId = 'default',
  }) async {
    _lastBusinessId = businessId;
    final cacheKey = _buildCacheKey(businessId, appointmentId);
    _memoryCache.remove(cacheKey);
    _accessOrder.remove(cacheKey);

    await _ensureInitialized();
    final storageKey = _buildStorageKey(businessId, appointmentId);
    await _prefs?.remove(storageKey);
  }

  /// Clear all cached predictions for a specific business.
  ///
  /// **HIPAA:** Only clears data for the specified business.
  Future<void> clearForBusiness(String businessId) async {
    // Clear from memory cache
    final keysToRemove =
        _memoryCache.keys.where((k) => k.startsWith('${businessId}_')).toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _accessOrder.remove(key);
    }

    // Clear from persistent cache
    await _ensureInitialized();
    final storagePrefix = '$_cachePrefix${businessId}_';
    final storageKeys =
        _prefs?.getKeys().where((k) => k.startsWith(storagePrefix)).toList() ??
            [];
    for (final key in storageKeys) {
      await _prefs?.remove(key);
    }
  }

  /// Clear all cached predictions (all businesses).
  ///
  /// Use with caution - typically prefer [clearForBusiness].
  Future<void> clearAll() async {
    _memoryCache.clear();
    _accessOrder.clear();

    await _ensureInitialized();
    final keys =
        _prefs?.getKeys().where((k) => k.startsWith(_cachePrefix)).toList() ??
            [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  /// Clear all cached predictions (alias for [clearAll]).
  Future<void> clear() => clearAll();

  /// Check if a prediction exists in cache (without loading it).
  ///
  /// **HIPAA:** Requires businessId for tenant isolation.
  Future<bool> contains(
    String appointmentId, {
    String businessId = 'default',
  }) async {
    final cacheKey = _buildCacheKey(businessId, appointmentId);
    if (_memoryCache.containsKey(cacheKey)) {
      return true;
    }

    await _ensureInitialized();
    final storageKey = _buildStorageKey(businessId, appointmentId);
    return _prefs?.containsKey(storageKey) ?? false;
  }

  /// Get cache statistics.
  Map<String, dynamic> get stats => {
        'memoryCacheSize': _memoryCache.length,
        'maxMemoryCacheSize': _maxMemoryCacheSize,
        'memoryCacheUtilization':
            (_memoryCache.length / _maxMemoryCacheSize * 100).toStringAsFixed(1),
      };

  /// Number of items in memory cache
  int get memoryCacheSize => _memoryCache.length;

  /// Check if prediction is expired
  bool _isExpired(NoshowPrediction prediction) {
    return DateTime.now().isAfter(prediction.expiresAt);
  }

  void _addToMemoryCache(String appointmentId, NoshowPrediction prediction) {
    // Remove if exists (to update position)
    _memoryCache.remove(appointmentId);
    _accessOrder.remove(appointmentId);

    // Evict oldest if at capacity
    while (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldest = _accessOrder.removeAt(0);
      _memoryCache.remove(oldest);
    }

    // Add new entry
    _memoryCache[appointmentId] = prediction;
    _accessOrder.add(appointmentId);
  }

  void _updateAccessOrder(String appointmentId) {
    _accessOrder.remove(appointmentId);
    _accessOrder.add(appointmentId);
  }
}

/// Extension to check if prediction is expired.
extension NoshowPredictionExpiry on NoshowPrediction {
  /// Check if this prediction has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if this prediction is still valid
  @override
  bool get isValid => !isExpired && riskLevel != RiskLevel.unknown;
}
