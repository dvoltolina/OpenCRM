import '../../data/models/client.dart';

/// Extension data for routing on Client model.
///
/// These fields are stored in a separate Firestore subcollection:
/// businesses/{businessId}/clients/{clientId}/routing/data
class ClientRoutingData {
  // ============ Service Address ============

  /// Whether provider travels to client (vs client comes to business)
  final bool requiresMobileService;

  /// Service address line 1
  final String? serviceAddress;

  /// Service address line 2 (apt, suite, etc.)
  final String? serviceAddress2;

  /// Service city
  final String? serviceCity;

  /// Service state
  final String? serviceState;

  /// Service zip code
  final String? serviceZipCode;

  /// Service country
  final String? serviceCountry;

  // ============ Geocoded Coordinates ============

  /// Service address latitude
  final double? serviceLatitude;

  /// Service address longitude
  final double? serviceLongitude;

  /// Google Place ID for service address
  final String? servicePlaceId;

  // ============ Service Logistics ============

  /// Special arrival instructions (gate code, parking, etc.)
  final String? arrivalNotes;

  /// Preferred arrival window start time (e.g., "09:00")
  final String? preferredWindowStart;

  /// Preferred arrival window end time (e.g., "17:00")
  final String? preferredWindowEnd;

  /// Days of week available (1=Mon, 7=Sun)
  final List<int>? availableDays;

  /// Average service duration at this client (minutes)
  /// Overrides default service duration for routing
  final int? averageServiceDurationMinutes;

  /// Extra buffer time needed at this client (minutes)
  final int? extraBufferMinutes;

  // ============ Metadata ============

  /// When service address was last geocoded
  final DateTime? lastGeocodedAt;

  /// Whether geocoding failed
  final bool geocodingFailed;

  /// Geocoding error message
  final String? geocodingError;

  ClientRoutingData({
    this.requiresMobileService = false,
    this.serviceAddress,
    this.serviceAddress2,
    this.serviceCity,
    this.serviceState,
    this.serviceZipCode,
    this.serviceCountry,
    this.serviceLatitude,
    this.serviceLongitude,
    this.servicePlaceId,
    this.arrivalNotes,
    this.preferredWindowStart,
    this.preferredWindowEnd,
    this.availableDays,
    this.averageServiceDurationMinutes,
    this.extraBufferMinutes,
    this.lastGeocodedAt,
    this.geocodingFailed = false,
    this.geocodingError,
  });

  /// Whether this client has a valid service address
  bool get hasServiceAddress =>
      serviceAddress != null && serviceAddress!.isNotEmpty;

  /// Whether service address has valid coordinates
  bool get hasServiceCoordinates =>
      serviceLatitude != null && serviceLongitude != null;

  /// Whether geocoding should be attempted
  bool get needsGeocoding =>
      hasServiceAddress && !hasServiceCoordinates && !geocodingFailed;

  /// Service coordinates as tuple (or null)
  (double, double)? get serviceCoordinates =>
      hasServiceCoordinates ? (serviceLatitude!, serviceLongitude!) : null;

  /// Full service address for display
  String get fullServiceAddress {
    final parts = <String>[];
    if (serviceAddress != null) parts.add(serviceAddress!);
    if (serviceAddress2 != null) parts.add(serviceAddress2!);
    if (serviceCity != null) parts.add(serviceCity!);
    if (serviceState != null && serviceZipCode != null) {
      parts.add('${serviceState!} ${serviceZipCode!}');
    } else if (serviceState != null) {
      parts.add(serviceState!);
    }
    return parts.join(', ');
  }

  /// Full service address for geocoding
  String get addressForGeocoding {
    final parts = <String>[];
    if (serviceAddress != null) parts.add(serviceAddress!);
    if (serviceCity != null) parts.add(serviceCity!);
    if (serviceState != null) parts.add(serviceState!);
    if (serviceZipCode != null) parts.add(serviceZipCode!);
    if (serviceCountry != null) parts.add(serviceCountry!);
    return parts.join(', ');
  }

  factory ClientRoutingData.fromJson(Map<String, dynamic> json) {
    return ClientRoutingData(
      requiresMobileService: json['requiresMobileService'] as bool? ?? false,
      serviceAddress: json['serviceAddress'] as String?,
      serviceAddress2: json['serviceAddress2'] as String?,
      serviceCity: json['serviceCity'] as String?,
      serviceState: json['serviceState'] as String?,
      serviceZipCode: json['serviceZipCode'] as String?,
      serviceCountry: json['serviceCountry'] as String?,
      serviceLatitude: (json['serviceLatitude'] as num?)?.toDouble(),
      serviceLongitude: (json['serviceLongitude'] as num?)?.toDouble(),
      servicePlaceId: json['servicePlaceId'] as String?,
      arrivalNotes: json['arrivalNotes'] as String?,
      preferredWindowStart: json['preferredWindowStart'] as String?,
      preferredWindowEnd: json['preferredWindowEnd'] as String?,
      availableDays: (json['availableDays'] as List?)?.cast<int>(),
      averageServiceDurationMinutes:
          json['averageServiceDurationMinutes'] as int?,
      extraBufferMinutes: json['extraBufferMinutes'] as int?,
      lastGeocodedAt: json['lastGeocodedAt'] != null
          ? DateTime.parse(json['lastGeocodedAt'] as String)
          : null,
      geocodingFailed: json['geocodingFailed'] as bool? ?? false,
      geocodingError: json['geocodingError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresMobileService': requiresMobileService,
      'serviceAddress': serviceAddress,
      'serviceAddress2': serviceAddress2,
      'serviceCity': serviceCity,
      'serviceState': serviceState,
      'serviceZipCode': serviceZipCode,
      'serviceCountry': serviceCountry,
      'serviceLatitude': serviceLatitude,
      'serviceLongitude': serviceLongitude,
      'servicePlaceId': servicePlaceId,
      'arrivalNotes': arrivalNotes,
      'preferredWindowStart': preferredWindowStart,
      'preferredWindowEnd': preferredWindowEnd,
      'availableDays': availableDays,
      'averageServiceDurationMinutes': averageServiceDurationMinutes,
      'extraBufferMinutes': extraBufferMinutes,
      'lastGeocodedAt': lastGeocodedAt?.toIso8601String(),
      'geocodingFailed': geocodingFailed,
      'geocodingError': geocodingError,
    };
  }

  ClientRoutingData copyWith({
    bool? requiresMobileService,
    String? serviceAddress,
    String? serviceAddress2,
    String? serviceCity,
    String? serviceState,
    String? serviceZipCode,
    String? serviceCountry,
    double? serviceLatitude,
    double? serviceLongitude,
    String? servicePlaceId,
    String? arrivalNotes,
    String? preferredWindowStart,
    String? preferredWindowEnd,
    List<int>? availableDays,
    int? averageServiceDurationMinutes,
    int? extraBufferMinutes,
    DateTime? lastGeocodedAt,
    bool? geocodingFailed,
    String? geocodingError,
  }) {
    return ClientRoutingData(
      requiresMobileService: requiresMobileService ?? this.requiresMobileService,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      serviceAddress2: serviceAddress2 ?? this.serviceAddress2,
      serviceCity: serviceCity ?? this.serviceCity,
      serviceState: serviceState ?? this.serviceState,
      serviceZipCode: serviceZipCode ?? this.serviceZipCode,
      serviceCountry: serviceCountry ?? this.serviceCountry,
      serviceLatitude: serviceLatitude ?? this.serviceLatitude,
      serviceLongitude: serviceLongitude ?? this.serviceLongitude,
      servicePlaceId: servicePlaceId ?? this.servicePlaceId,
      arrivalNotes: arrivalNotes ?? this.arrivalNotes,
      preferredWindowStart: preferredWindowStart ?? this.preferredWindowStart,
      preferredWindowEnd: preferredWindowEnd ?? this.preferredWindowEnd,
      availableDays: availableDays ?? this.availableDays,
      averageServiceDurationMinutes:
          averageServiceDurationMinutes ?? this.averageServiceDurationMinutes,
      extraBufferMinutes: extraBufferMinutes ?? this.extraBufferMinutes,
      lastGeocodedAt: lastGeocodedAt ?? this.lastGeocodedAt,
      geocodingFailed: geocodingFailed ?? this.geocodingFailed,
      geocodingError: geocodingError ?? this.geocodingError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientRoutingData &&
        other.requiresMobileService == requiresMobileService &&
        other.serviceAddress == serviceAddress &&
        other.serviceLatitude == serviceLatitude &&
        other.serviceLongitude == serviceLongitude &&
        other.geocodingFailed == geocodingFailed;
  }

  @override
  int get hashCode => Object.hash(
        requiresMobileService,
        serviceAddress,
        serviceLatitude,
        serviceLongitude,
        geocodingFailed,
      );
}

/// Extension methods for Client model with routing data.
extension ClientRoutingExtension on Client {
  /// Whether this client has service location coordinates from the base model
  /// Note: The Client model already has serviceLatitude/serviceLongitude fields
  bool get hasServiceLocationCoordinates =>
      serviceLatitude != null && serviceLongitude != null;

  /// Get service coordinates from the base Client model
  (double, double)? get serviceLocationCoordinates =>
      hasServiceLocationCoordinates
          ? (serviceLatitude!, serviceLongitude!)
          : null;
}
