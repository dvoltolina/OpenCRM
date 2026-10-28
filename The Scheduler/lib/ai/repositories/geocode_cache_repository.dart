import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/geocode_result.dart';

/// Repository for caching geocoding results.
///
/// **CRITICAL SECURITY**:
/// - Geocode cache is NOW business-scoped for multi-tenant isolation
/// - Client addresses being geocoded may be PHI
/// - Audit logging tracks geocoding operations
/// - Original addresses are NOT stored in cache (privacy protection)
///
/// Geocoding API calls are expensive - cache results to reduce costs.
/// Uses address hash as document ID for fast lookups.
class GeocodeCacheRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Default cache TTL (90 days)
  static const defaultCacheDuration = Duration(days: 90);

  GeocodeCacheRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  /// Get the business-scoped geocode cache collection.
  /// **CRITICAL**: Geocode cache is business-scoped for multi-tenant isolation.
  CollectionReference<Map<String, dynamic>> _cacheCollection(String businessId) =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('geocodeCache');

  /// Generate a hash for an address (used as document ID).
  /// **SECURITY**: This hash is used for lookups without exposing actual addresses.
  String _hashAddress(String address) {
    final normalized =
        address.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString().substring(0, 32);
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
        source: 'GeocodeCacheRepository',
      );
    } catch (e) {
      developer.log(
        'GeocodeCacheRepository: Failed to log audit event: $e',
        name: 'GeocodeCacheRepository',
      );
    }
  }

  /// Get cached geocode result for an address.
  /// **CRITICAL**: Requires SecurityContext for business-scoped access.
  Future<GeocodeResult?> getCachedResult(
    SecurityContext context,
    String address,
  ) async {
    final hash = _hashAddress(address);
    final doc = await _cacheCollection(context.businessId).doc(hash).get();

    if (!doc.exists || doc.data() == null) return null;

    final result = GeocodeResult.fromJson(doc.data()!);

    // Check expiration
    if (result.isExpired) {
      // Delete expired entry
      await _cacheCollection(context.businessId).doc(hash).delete();
      return null;
    }

    return result;
  }

  /// Cache a geocode result.
  /// **CRITICAL**: Original address is sanitized before storage.
  /// **CRITICAL**: Logs geocoding for HIPAA compliance.
  Future<void> cacheResult(
    SecurityContext context,
    GeocodeResult result, {
    String? clientId,
  }) async {
    final hash = _hashAddress(result.originalAddress);

    // **SECURITY**: Create a sanitized version without full original address
    // Store only a truncated/masked version for debugging
    final sanitizedResult = _sanitizeForStorage(result);

    await _cacheCollection(context.businessId).doc(hash).set(sanitizedResult.toJson());

    // **CRITICAL: Log geocoding for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'geocode_cache_write',
      entityType: 'geocodeCache',
      entityId: hash,
      details: {
        'provider': result.provider.name,
        'accuracy': result.accuracy.name,
        'client_id': clientId,
        'has_place_id': result.placeId != null,
      },
    );
  }

  /// Sanitize geocode result for storage.
  /// **SECURITY**: Masks the original address to prevent PHI exposure.
  GeocodeResult _sanitizeForStorage(GeocodeResult result) {
    // Mask the original address - keep only city/state for debugging
    final maskedAddress = _maskAddress(result.originalAddress);

    return GeocodeResult(
      id: result.id,
      originalAddress: maskedAddress, // Masked, not original
      formattedAddress: null, // Don't store formatted address
      latitude: result.latitude,
      longitude: result.longitude,
      placeId: result.placeId,
      provider: result.provider,
      accuracy: result.accuracy,
      confidence: result.confidence,
      geocodedAt: result.geocodedAt,
      expiresAt: result.expiresAt,
      addressComponents: null, // Don't store address components
      timezone: result.timezone,
      viewport: result.viewport,
    );
  }

  /// Mask an address for storage - keep only last part (city, state).
  /// **SECURITY**: This prevents storing full street addresses (PHI).
  String _maskAddress(String address) {
    final parts = address.split(',').map((p) => p.trim()).toList();
    if (parts.length <= 2) {
      return '***masked***';
    }
    // Keep only the last 2 parts (typically city, state/country)
    return '***,${parts.sublist(parts.length - 2).join(', ')}';
  }

  /// Delete cached result for an address.
  Future<void> deleteCachedResult(
    SecurityContext context,
    String address,
  ) async {
    final hash = _hashAddress(address);
    await _cacheCollection(context.businessId).doc(hash).delete();
  }

  /// Clean up expired cache entries.
  /// Call periodically (e.g., daily Cloud Function).
  Future<int> cleanExpiredEntries(
    SecurityContext context, {
    int batchSize = 500,
  }) async {
    final now = DateTime.now();
    final snapshot = await _cacheCollection(context.businessId)
        .where('expiresAt', isLessThan: now.toIso8601String())
        .limit(batchSize)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Log cleanup operation
    await _logAudit(
      context: context,
      action: 'geocode_cache_cleanup',
      entityType: 'geocodeCache',
      entityId: 'cleanup',
      details: {
        'entries_deleted': snapshot.docs.length,
      },
    );

    return snapshot.docs.length;
  }

  /// Get cache statistics.
  Future<Map<String, dynamic>> getCacheStats(SecurityContext context) async {
    final totalSnapshot =
        await _cacheCollection(context.businessId).count().get();
    final total = totalSnapshot.count ?? 0;

    final now = DateTime.now();
    final expiredSnapshot = await _cacheCollection(context.businessId)
        .where('expiresAt', isLessThan: now.toIso8601String())
        .count()
        .get();
    final expired = expiredSnapshot.count ?? 0;

    return {
      'totalEntries': total,
      'expiredEntries': expired,
      'validEntries': total - expired,
    };
  }

  /// Batch cache multiple results.
  /// **CRITICAL**: Logs batch geocoding for HIPAA compliance.
  Future<void> cacheResultsBatch(
    SecurityContext context,
    List<GeocodeResult> results,
  ) async {
    if (results.isEmpty) return;

    final batch = _firestore.batch();
    for (final result in results) {
      final hash = _hashAddress(result.originalAddress);
      final sanitized = _sanitizeForStorage(result);
      batch.set(_cacheCollection(context.businessId).doc(hash), sanitized.toJson());
    }
    await batch.commit();

    // **CRITICAL: Log batch geocoding for HIPAA compliance**
    await _logAudit(
      context: context,
      action: 'geocode_cache_write_batch',
      entityType: 'geocodeCache',
      entityId: 'batch',
      details: {
        'count': results.length,
      },
    );
  }

  /// Get multiple cached results by addresses.
  Future<Map<String, GeocodeResult>> getCachedResultsBatch(
    SecurityContext context,
    List<String> addresses,
  ) async {
    final results = <String, GeocodeResult>{};

    for (final address in addresses) {
      final hash = _hashAddress(address);
      final doc = await _cacheCollection(context.businessId).doc(hash).get();

      if (doc.exists && doc.data() != null) {
        final result = GeocodeResult.fromJson(doc.data()!);
        if (!result.isExpired) {
          results[address] = result;
        }
      }
    }

    return results;
  }

  /// Check if an address is cached (without fetching full result).
  Future<bool> isCached(SecurityContext context, String address) async {
    final hash = _hashAddress(address);
    final doc = await _cacheCollection(context.businessId).doc(hash).get();

    if (!doc.exists || doc.data() == null) return false;

    // Check expiration
    final expiresAtStr = doc.data()!['expiresAt'] as String?;
    if (expiresAtStr == null) return false;

    final expiresAt = DateTime.parse(expiresAtStr);
    return DateTime.now().isBefore(expiresAt);
  }

  /// Update cache entry with new expiration.
  Future<void> refreshExpiration(
    SecurityContext context,
    String address, {
    Duration? duration,
  }) async {
    final hash = _hashAddress(address);
    final doc = await _cacheCollection(context.businessId).doc(hash).get();

    if (!doc.exists || doc.data() == null) return;

    final newExpiration =
        DateTime.now().add(duration ?? defaultCacheDuration);

    await _cacheCollection(context.businessId).doc(hash).update({
      'expiresAt': newExpiration.toIso8601String(),
    });
  }
}
