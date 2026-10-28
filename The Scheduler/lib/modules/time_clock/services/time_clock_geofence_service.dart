import 'package:geolocator/geolocator.dart';

import '../../../ai/repositories/route_repository.dart';
import '../../../ai/services/gps_location_service.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/locations_repository.dart';

/// Result of a geofence validation check.
class TimeClockGeofenceResult {
  const TimeClockGeofenceResult({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.isWithinGeofence,
    this.accuracyMeters,
    this.locationId,
    this.locationName,
  });

  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double? accuracyMeters;
  final bool isWithinGeofence;
  final String? locationId;
  final String? locationName;
}

/// Thrown when geofence validation fails.
class TimeClockGeofenceException implements Exception {
  TimeClockGeofenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Validates that clock events occur within the configured office geofence.
class TimeClockGeofenceService {
  TimeClockGeofenceService({
    required LocationsRepository locationsRepository,
    required RouteRepository routeRepository,
    required GpsLocationService gpsLocationService,
    double? geofenceRadiusMeters,
  }) : _locationsRepository = locationsRepository,
       _routeRepository = routeRepository,
       _gpsLocationService = gpsLocationService,
       _geofenceRadiusMeters =
           geofenceRadiusMeters ?? _defaultRadiusFeet * _feetToMeters;

  final LocationsRepository _locationsRepository;
  final RouteRepository _routeRepository;
  final GpsLocationService _gpsLocationService;
  final double _geofenceRadiusMeters;

  static const double _feetToMeters = 0.3048;
  static const double _defaultRadiusFeet = 1000;
  static const double _gpsJitterBufferMeters = 20;

  /// Ensure the current device is within the allowed geofence.
  ///
  /// Returns the validated location (for storage on the time entry) or throws
  /// [TimeClockGeofenceException] with a user-friendly message when validation
  /// fails.
  Future<TimeClockGeofenceResult> ensureWithinGeofence(
    SecurityContext context,
  ) async {
    final currentLocation = await _gpsLocationService.getCurrentLocation();
    if (currentLocation == null) {
      final status = await _gpsLocationService.checkPermissionStatus();
      throw TimeClockGeofenceException(_permissionMessage(status));
    }

    final office = await _getNearestOffice(
      context,
      currentLocation.latitude,
      currentLocation.longitude,
    );
    final distanceMeters = office.distanceMeters;

    final effectiveRadius =
        _geofenceRadiusMeters +
        _gpsJitterBufferMeters +
        (currentLocation.accuracyMeters ?? 0).clamp(0, 35).toDouble();

    final isInside = distanceMeters <= effectiveRadius;

    if (!isInside) {
      final distanceFeet = (distanceMeters * (1 / _feetToMeters)).round();
      final locationLabel = office.name ?? 'the office';
      throw TimeClockGeofenceException(
        'Clock in/out requires being within $_defaultRadiusFeet ft of a '
        'business location. Nearest: $locationLabel '
        '($distanceFeet ft away).',
      );
    }

    return TimeClockGeofenceResult(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      accuracyMeters: currentLocation.accuracyMeters,
      distanceMeters: distanceMeters,
      isWithinGeofence: isInside,
      locationId: office.id,
      locationName: office.name,
    );
  }

  Future<_GeofencePoint> _getNearestOffice(
    SecurityContext context,
    double currentLatitude,
    double currentLongitude,
  ) async {
    final locations = await _locationsRepository.getLocations(context: context);
    if (locations.isEmpty) {
      throw TimeClockGeofenceException(
        'No business locations configured. Add at least one office location '
        'before using the time clock.',
      );
    }

    final routingData = await _routeRepository.getLocationRoutingDataBatch(
      context,
      locations.map((l) => l.id).toList(),
    );

    final points = <_GeofencePoint>[];
    for (final location in locations) {
      final routing = routingData[location.id];
      final coordinates = routing?.coordinates;
      if (coordinates != null) {
        points.add(
          _GeofencePoint(
            id: location.id,
            name: location.name?.trim().isNotEmpty == true
                ? location.name
                : location.address,
            latitude: coordinates.$1,
            longitude: coordinates.$2,
          ),
        );
      }
    }

    if (points.isEmpty) {
      throw TimeClockGeofenceException(
        'Business locations are missing latitude/longitude. Geocode your '
        'locations (routing data) to enable geofenced clock in/out.',
      );
    }

    _GeofencePoint? closest;
    var closestDistance = double.infinity;

    for (final point in points) {
      final distance = Geolocator.distanceBetween(
        currentLatitude,
        currentLongitude,
        point.latitude,
        point.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closest = point.copyWith(distanceMeters: distance);
      }
    }

    if (closest == null || closestDistance == double.infinity) {
      throw TimeClockGeofenceException(
        'Unable to match your location to a business office.',
      );
    }

    return closest;
  }

  String _permissionMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.serviceDisabled:
        return 'Turn on Location Services to clock in/out.';
      case LocationPermissionStatus.denied:
        return 'Location permission is required to clock in/out.';
      case LocationPermissionStatus.deniedForever:
        return 'Location permission is permanently denied. Enable it in '
            'Settings to use the time clock.';
      case LocationPermissionStatus.granted:
        // We failed even though permission is granted (timeout/other).
        return 'Unable to get your location. Move closer to the office and '
            'try again.';
    }
  }
}

class _GeofencePoint {
  const _GeofencePoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    this.distanceMeters = double.infinity,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? name;
  final double distanceMeters;

  _GeofencePoint copyWith({double? distanceMeters}) {
    return _GeofencePoint(
      id: id,
      latitude: latitude,
      longitude: longitude,
      name: name,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
