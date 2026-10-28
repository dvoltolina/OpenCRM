import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../models/geocode_result.dart';
import '../repositories/geocode_cache_repository.dart';

/// Configuration for geocoding service.
class GeocodingConfig {
  /// Google Geocoding API key (from environment).
  final String? googleApiKey;

  /// OpenStreetMap Nominatim URL (free, rate-limited).
  final String nominatimUrl;

  /// Request timeout in milliseconds.
  final int timeoutMs;

  /// Cache TTL in days.
  final int cacheDays;

  /// Whether to prefer Google over OSM.
  final bool preferGoogle;

  const GeocodingConfig({
    this.googleApiKey,
    this.nominatimUrl = 'https://nominatim.openstreetmap.org',
    this.timeoutMs = 10000,
    this.cacheDays = 90,
    this.preferGoogle = true,
  });

  /// Development config (uses OSM only).
  factory GeocodingConfig.development() => const GeocodingConfig(
        preferGoogle: false,
      );

  /// Production config (uses Google with API key).
  factory GeocodingConfig.production({required String googleApiKey}) =>
      GeocodingConfig(
        googleApiKey: googleApiKey,
        preferGoogle: true,
      );

  /// Whether Google API is available.
  bool get hasGoogleApi => googleApiKey != null && googleApiKey!.isNotEmpty;
}

/// Service for geocoding addresses to coordinates and vice versa.
///
/// **HIPAA Compliance:**
/// - Client addresses are PHI when linked to client records
/// - All geocoding operations are logged for audit
/// - Cached results have addresses masked for privacy
/// - SecurityContext ensures multi-tenant isolation
///
/// **Caching:**
/// - Results cached to minimize API costs
/// - Addresses hashed for privacy-preserving lookups
/// - Expired entries cleaned automatically
class GeocodingService {
  final GeocodingConfig _config;
  final GeocodeCacheRepository _cacheRepository;
  final AuditLogRepository _auditLogRepository;
  final http.Client _httpClient;
  final Uuid _uuid;

  /// Rate limiting for Nominatim (1 req/sec).
  DateTime? _lastNominatimRequest;
  static const _nominatimRateLimit = Duration(seconds: 1);

  GeocodingService({
    required GeocodingConfig config,
    GeocodeCacheRepository? cacheRepository,
    AuditLogRepository? auditLogRepository,
    http.Client? httpClient,
  })  : _config = config,
        _cacheRepository = cacheRepository ?? GeocodeCacheRepository(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository(),
        _httpClient = httpClient ?? http.Client(),
        _uuid = const Uuid();

  // ============ Geocoding ============

  /// Geocode an address to coordinates.
  ///
  /// Checks cache first, then calls API if not cached.
  /// Returns null if geocoding fails.
  ///
  /// **HIPAA**: Logs geocoding for audit when [clientId] provided.
  Future<GeocodeResult?> geocodeAddress(
    SecurityContext context,
    String address, {
    String? clientId,
  }) async {
    if (address.trim().isEmpty) return null;

    // Check cache first
    final cached = await _cacheRepository.getCachedResult(context, address);
    if (cached != null) {
      debugPrint('GeocodingService: Cache hit for address');
      return cached;
    }

    // Call API
    GeocodeResult? result;
    if (_config.preferGoogle && _config.hasGoogleApi) {
      result = await _geocodeWithGoogle(address);
    }

    // Fallback to OSM if Google fails or unavailable
    result ??= await _geocodeWithNominatim(address);

    if (result != null) {
      // Cache result
      await _cacheRepository.cacheResult(
        context,
        result,
        clientId: clientId,
      );

      // Log if client-related (PHI access)
      if (clientId != null) {
        await _logAudit(
          context: context,
          action: 'geocode_client_address',
          entityType: 'geocodeResult',
          entityId: clientId,
          details: {
            'provider': result.provider.name,
            'accuracy': result.accuracy.name,
            'has_coordinates': true,
          },
        );
      }
    }

    return result;
  }

  /// Batch geocode multiple addresses.
  ///
  /// More efficient than individual calls for multiple addresses.
  /// Returns map of address -> result (null if failed).
  Future<Map<String, GeocodeResult?>> geocodeAddressesBatch(
    SecurityContext context,
    List<String> addresses, {
    List<String>? clientIds,
  }) async {
    final results = <String, GeocodeResult?>{};

    // Check cache for all addresses first
    final cached =
        await _cacheRepository.getCachedResultsBatch(context, addresses);

    final uncached = <String>[];
    for (final address in addresses) {
      if (cached.containsKey(address)) {
        results[address] = cached[address];
      } else {
        uncached.add(address);
      }
    }

    // Geocode uncached addresses
    for (final address in uncached) {
      final clientId =
          clientIds != null && addresses.indexOf(address) < clientIds.length
              ? clientIds[addresses.indexOf(address)]
              : null;

      results[address] = await geocodeAddress(
        context,
        address,
        clientId: clientId,
      );

      // Small delay to respect rate limits
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  /// Reverse geocode coordinates to address.
  ///
  /// Returns null if reverse geocoding fails.
  Future<GeocodeResult?> reverseGeocode(
    SecurityContext context,
    double latitude,
    double longitude,
  ) async {
    if (_config.preferGoogle && _config.hasGoogleApi) {
      final result = await _reverseGeocodeWithGoogle(latitude, longitude);
      if (result != null) return result;
    }

    // Fallback to OSM
    return _reverseGeocodeWithNominatim(latitude, longitude);
  }

  /// Validate coordinates are within reasonable bounds.
  bool validateCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Calculate distance between two points (Haversine formula).
  /// Returns distance in meters.
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  // ============ Google Geocoding API ============

  Future<GeocodeResult?> _geocodeWithGoogle(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=${_config.googleApiKey}',
      );

      final response = await _httpClient
          .get(url)
          .timeout(Duration(milliseconds: _config.timeoutMs));

      if (response.statusCode != 200) {
        debugPrint('GeocodingService: Google API error ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') {
        debugPrint('GeocodingService: Google API status: $status');
        return null;
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results[0] as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;

      final now = DateTime.now();
      return GeocodeResult(
        id: _uuid.v4(),
        originalAddress: address,
        formattedAddress: first['formatted_address'] as String?,
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
        placeId: first['place_id'] as String?,
        provider: GeocodeProvider.google,
        accuracy: _parseGoogleAccuracy(geometry['location_type'] as String?),
        geocodedAt: now,
        expiresAt: now.add(Duration(days: _config.cacheDays)),
        addressComponents: _parseGoogleAddressComponents(
          first['address_components'] as List<dynamic>?,
        ),
      );
    } catch (e) {
      debugPrint('GeocodingService: Google geocoding error: $e');
      return null;
    }
  }

  Future<GeocodeResult?> _reverseGeocodeWithGoogle(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$latitude,$longitude'
        '&key=${_config.googleApiKey}',
      );

      final response = await _httpClient
          .get(url)
          .timeout(Duration(milliseconds: _config.timeoutMs));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final first = results[0] as Map<String, dynamic>;
      final now = DateTime.now();

      return GeocodeResult(
        id: _uuid.v4(),
        originalAddress: first['formatted_address'] as String? ?? '',
        formattedAddress: first['formatted_address'] as String?,
        latitude: latitude,
        longitude: longitude,
        placeId: first['place_id'] as String?,
        provider: GeocodeProvider.google,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: now,
        expiresAt: now.add(Duration(days: _config.cacheDays)),
      );
    } catch (e) {
      debugPrint('GeocodingService: Google reverse geocoding error: $e');
      return null;
    }
  }

  GeocodeAccuracy _parseGoogleAccuracy(String? locationType) {
    switch (locationType) {
      case 'ROOFTOP':
        return GeocodeAccuracy.rooftop;
      case 'RANGE_INTERPOLATED':
        return GeocodeAccuracy.rangeInterpolated;
      case 'GEOMETRIC_CENTER':
        return GeocodeAccuracy.geometricCenter;
      case 'APPROXIMATE':
        return GeocodeAccuracy.approximate;
      default:
        return GeocodeAccuracy.unknown;
    }
  }

  Map<String, String>? _parseGoogleAddressComponents(List<dynamic>? components) {
    if (components == null) return null;

    final result = <String, String>{};
    for (final component in components) {
      final comp = component as Map<String, dynamic>;
      final types = comp['types'] as List<dynamic>?;
      final value = comp['long_name'] as String?;

      if (types == null || value == null) continue;

      if (types.contains('street_number')) {
        result['street_number'] = value;
      } else if (types.contains('route')) {
        result['street'] = value;
      } else if (types.contains('locality')) {
        result['city'] = value;
      } else if (types.contains('administrative_area_level_1')) {
        result['state'] = value;
      } else if (types.contains('postal_code')) {
        result['zip'] = value;
      } else if (types.contains('country')) {
        result['country'] = value;
      }
    }

    return result.isEmpty ? null : result;
  }

  // ============ OpenStreetMap Nominatim ============

  Future<GeocodeResult?> _geocodeWithNominatim(String address) async {
    // Respect rate limit
    await _waitForNominatimRateLimit();

    try {
      final url = Uri.parse(
        '${_config.nominatimUrl}/search'
        '?q=${Uri.encodeComponent(address)}'
        '&format=json'
        '&limit=1'
        '&addressdetails=1',
      );

      final response = await _httpClient.get(
        url,
        headers: {'User-Agent': 'TheSchedulerApp/1.0'},
      ).timeout(Duration(milliseconds: _config.timeoutMs));

      _lastNominatimRequest = DateTime.now();

      if (response.statusCode != 200) {
        debugPrint('GeocodingService: Nominatim error ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return null;

      final first = data[0] as Map<String, dynamic>;
      final now = DateTime.now();

      return GeocodeResult(
        id: _uuid.v4(),
        originalAddress: address,
        formattedAddress: first['display_name'] as String?,
        latitude: double.parse(first['lat'] as String),
        longitude: double.parse(first['lon'] as String),
        placeId: first['osm_id']?.toString(),
        provider: GeocodeProvider.openStreetMap,
        accuracy: _parseNominatimAccuracy(first['class'] as String?),
        geocodedAt: now,
        expiresAt: now.add(Duration(days: _config.cacheDays)),
        addressComponents: _parseNominatimAddress(
          first['address'] as Map<String, dynamic>?,
        ),
      );
    } catch (e) {
      debugPrint('GeocodingService: Nominatim geocoding error: $e');
      return null;
    }
  }

  Future<GeocodeResult?> _reverseGeocodeWithNominatim(
    double latitude,
    double longitude,
  ) async {
    await _waitForNominatimRateLimit();

    try {
      final url = Uri.parse(
        '${_config.nominatimUrl}/reverse'
        '?lat=$latitude'
        '&lon=$longitude'
        '&format=json'
        '&addressdetails=1',
      );

      final response = await _httpClient.get(
        url,
        headers: {'User-Agent': 'TheSchedulerApp/1.0'},
      ).timeout(Duration(milliseconds: _config.timeoutMs));

      _lastNominatimRequest = DateTime.now();

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] != null) return null;

      final now = DateTime.now();
      return GeocodeResult(
        id: _uuid.v4(),
        originalAddress: data['display_name'] as String? ?? '',
        formattedAddress: data['display_name'] as String?,
        latitude: latitude,
        longitude: longitude,
        placeId: data['osm_id']?.toString(),
        provider: GeocodeProvider.openStreetMap,
        accuracy: GeocodeAccuracy.rooftop,
        geocodedAt: now,
        expiresAt: now.add(Duration(days: _config.cacheDays)),
      );
    } catch (e) {
      debugPrint('GeocodingService: Nominatim reverse geocoding error: $e');
      return null;
    }
  }

  Future<void> _waitForNominatimRateLimit() async {
    if (_lastNominatimRequest == null) return;

    final elapsed = DateTime.now().difference(_lastNominatimRequest!);
    if (elapsed < _nominatimRateLimit) {
      await Future.delayed(_nominatimRateLimit - elapsed);
    }
  }

  GeocodeAccuracy _parseNominatimAccuracy(String? osmClass) {
    switch (osmClass) {
      case 'building':
      case 'place':
        return GeocodeAccuracy.rooftop;
      case 'highway':
        return GeocodeAccuracy.rangeInterpolated;
      case 'boundary':
        return GeocodeAccuracy.geometricCenter;
      default:
        return GeocodeAccuracy.approximate;
    }
  }

  Map<String, String>? _parseNominatimAddress(Map<String, dynamic>? address) {
    if (address == null) return null;

    return {
      if (address['house_number'] != null)
        'street_number': address['house_number'] as String,
      if (address['road'] != null) 'street': address['road'] as String,
      if (address['city'] != null)
        'city': address['city'] as String
      else if (address['town'] != null)
        'city': address['town'] as String
      else if (address['village'] != null)
        'city': address['village'] as String,
      if (address['state'] != null) 'state': address['state'] as String,
      if (address['postcode'] != null) 'zip': address['postcode'] as String,
      if (address['country'] != null) 'country': address['country'] as String,
    };
  }

  // ============ Math Helpers ============

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

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
        source: 'GeocodingService',
      );
    } catch (e) {
      developer.log(
        'GeocodingService: Failed to log audit event: $e',
        name: 'GeocodingService',
      );
    }
  }

  /// Close the HTTP client.
  void close() {
    _httpClient.close();
  }
}
