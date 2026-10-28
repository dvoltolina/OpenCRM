import '../../data/models/location.dart';

/// Extension data for routing on Location model.
///
/// These fields are stored in a separate Firestore subcollection:
/// businesses/{businessId}/locations/{locationId}/routing/data
class LocationRoutingData {
  /// Geocoded latitude (null if not geocoded)
  final double? latitude;

  /// Geocoded longitude (null if not geocoded)
  final double? longitude;

  /// Google Place ID for accurate geocoding
  final String? placeId;

  /// Whether this location supports mobile services
  final bool isMobileServiceBase;

  /// Default travel buffer when leaving this location (minutes)
  final int defaultTravelBufferMinutes;

  /// Timezone at this location (e.g., "America/New_York")
  final String? timezone;

  /// Service radius from this location (km) for mobile services
  final double? serviceRadiusKm;

  /// When geocoding was last performed
  final DateTime? lastGeocodedAt;

  /// Whether geocoding failed (to avoid repeated attempts)
  final bool geocodingFailed;

  /// Error message if geocoding failed
  final String? geocodingError;

  LocationRoutingData({
    this.latitude,
    this.longitude,
    this.placeId,
    this.isMobileServiceBase = false,
    this.defaultTravelBufferMinutes = 10,
    this.timezone,
    this.serviceRadiusKm,
    this.lastGeocodedAt,
    this.geocodingFailed = false,
    this.geocodingError,
  });

  /// Whether this location has valid coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Whether geocoding should be attempted
  bool get needsGeocoding => !hasCoordinates && !geocodingFailed;

  /// Coordinates as tuple (or null)
  (double, double)? get coordinates =>
      hasCoordinates ? (latitude!, longitude!) : null;

  factory LocationRoutingData.fromJson(Map<String, dynamic> json) {
    return LocationRoutingData(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['placeId'] as String?,
      isMobileServiceBase: json['isMobileServiceBase'] as bool? ?? false,
      defaultTravelBufferMinutes:
          json['defaultTravelBufferMinutes'] as int? ?? 10,
      timezone: json['timezone'] as String?,
      serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toDouble(),
      lastGeocodedAt: json['lastGeocodedAt'] != null
          ? DateTime.parse(json['lastGeocodedAt'] as String)
          : null,
      geocodingFailed: json['geocodingFailed'] as bool? ?? false,
      geocodingError: json['geocodingError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'isMobileServiceBase': isMobileServiceBase,
      'defaultTravelBufferMinutes': defaultTravelBufferMinutes,
      'timezone': timezone,
      'serviceRadiusKm': serviceRadiusKm,
      'lastGeocodedAt': lastGeocodedAt?.toIso8601String(),
      'geocodingFailed': geocodingFailed,
      'geocodingError': geocodingError,
    };
  }

  LocationRoutingData copyWith({
    double? latitude,
    double? longitude,
    String? placeId,
    bool? isMobileServiceBase,
    int? defaultTravelBufferMinutes,
    String? timezone,
    double? serviceRadiusKm,
    DateTime? lastGeocodedAt,
    bool? geocodingFailed,
    String? geocodingError,
  }) {
    return LocationRoutingData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      isMobileServiceBase: isMobileServiceBase ?? this.isMobileServiceBase,
      defaultTravelBufferMinutes:
          defaultTravelBufferMinutes ?? this.defaultTravelBufferMinutes,
      timezone: timezone ?? this.timezone,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      lastGeocodedAt: lastGeocodedAt ?? this.lastGeocodedAt,
      geocodingFailed: geocodingFailed ?? this.geocodingFailed,
      geocodingError: geocodingError ?? this.geocodingError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationRoutingData &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.placeId == placeId &&
        other.isMobileServiceBase == isMobileServiceBase &&
        other.defaultTravelBufferMinutes == defaultTravelBufferMinutes &&
        other.timezone == timezone &&
        other.serviceRadiusKm == serviceRadiusKm &&
        other.geocodingFailed == geocodingFailed;
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        placeId,
        isMobileServiceBase,
        defaultTravelBufferMinutes,
        timezone,
        serviceRadiusKm,
        geocodingFailed,
      );
}

/// Extension methods for Location model with routing data.
extension LocationRoutingExtension on Location {
  /// Build full address string for geocoding
  String get fullAddressForGeocoding {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode.isNotEmpty) parts.add(zipCode);
    return parts.join(', ');
  }

  /// Whether this location has enough address info for geocoding
  bool get hasAddressForGeocoding =>
      address.isNotEmpty || (city.isNotEmpty && state.isNotEmpty);
}
