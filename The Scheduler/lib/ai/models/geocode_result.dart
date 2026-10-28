import 'package:freezed_annotation/freezed_annotation.dart';

part 'geocode_result.freezed.dart';
part 'geocode_result.g.dart';

/// Source of geocoding data.
enum GeocodeProvider {
  /// Google Places/Geocoding API
  google,

  /// OpenStreetMap Nominatim
  openStreetMap,

  /// Manual entry by user
  manual,

  /// Imported from external system
  imported,
}

/// Accuracy level of geocoded coordinates.
enum GeocodeAccuracy {
  /// Exact address match (rooftop level)
  rooftop,

  /// Interpolated along street
  rangeInterpolated,

  /// Center of street
  geometricCenter,

  /// Approximate (city/region level)
  approximate,

  /// Unknown accuracy
  unknown,
}

/// Geographic bounds for viewport.
@freezed
abstract class GeocodeBounds with _$GeocodeBounds {
  const factory GeocodeBounds({
    required double northeastLat,
    required double northeastLng,
    required double southwestLat,
    required double southwestLng,
  }) = _GeocodeBounds;

  factory GeocodeBounds.fromJson(Map<String, dynamic> json) =>
      _$GeocodeBoundsFromJson(json);
}

/// Result of geocoding an address to coordinates.
@freezed
abstract class GeocodeResult with _$GeocodeResult {
  const factory GeocodeResult({
    /// Unique identifier for this geocode result
    required String id,

    /// Original address that was geocoded
    required String originalAddress,

    /// Formatted/standardized address from geocoder
    String? formattedAddress,

    /// Latitude coordinate
    required double latitude,

    /// Longitude coordinate
    required double longitude,

    /// Place ID (Google) or OSM ID for future reference
    String? placeId,

    /// Geocoding provider used
    required GeocodeProvider provider,

    /// Accuracy level of the result
    required GeocodeAccuracy accuracy,

    /// Confidence score (0.0-1.0) if available
    double? confidence,

    /// When this geocoding was performed
    required DateTime geocodedAt,

    /// When this cache entry expires
    required DateTime expiresAt,

    /// Address components (street, city, state, zip, country)
    Map<String, String>? addressComponents,

    /// Timezone at this location (e.g., "America/New_York")
    String? timezone,

    /// Viewport bounds for map display
    GeocodeBounds? viewport,
  }) = _GeocodeResult;

  factory GeocodeResult.fromJson(Map<String, dynamic> json) =>
      _$GeocodeResultFromJson(json);
}

/// Extension methods for GeocodeResult.
extension GeocodeResultExtensions on GeocodeResult {
  /// Whether this result has expired and should be refreshed
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this result is accurate enough for routing
  bool get isSufficientForRouting =>
      accuracy == GeocodeAccuracy.rooftop ||
      accuracy == GeocodeAccuracy.rangeInterpolated ||
      accuracy == GeocodeAccuracy.geometricCenter;

  /// Get coordinates as a tuple
  (double lat, double lng) get coordinates => (latitude, longitude);
}
