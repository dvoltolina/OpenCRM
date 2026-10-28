import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:geocoding/geocoding.dart';

import '../config/staff_app_config.dart';
import 'time_clock_exceptions.dart';

/// Represents location data captured at a point in time.
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.timestamp,
  });

  /// GPS latitude coordinate.
  final double latitude;

  /// GPS longitude coordinate.
  final double longitude;

  /// Human-readable address (reverse geocoded).
  final String? address;

  /// Location accuracy in meters.
  final double? accuracy;

  /// When this location was captured.
  final DateTime timestamp;

  /// Formats coordinates as a string.
  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  String toString() =>
      'LocationData($coordinatesString, accuracy: ${accuracy?.toStringAsFixed(1)}m)';
}

/// Represents a business location for geofence validation.
class BusinessLocationPoint {
  const BusinessLocationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
  });

  /// Location ID from Firestore.
  final String id;

  /// Display name of the location.
  final String name;

  /// GPS latitude coordinate.
  final double latitude;

  /// GPS longitude coordinate.
  final double longitude;

  /// Geofence radius in meters (default 100m).
  final double radiusMeters;
}

/// Service for handling GPS location operations.
///
/// Provides methods for:
/// - Getting current location with permission handling
/// - Reverse geocoding coordinates to addresses
/// - Geofence validation against business locations
///
/// ## Usage
/// ```dart
/// final locationService = LocationService();
/// final location = await locationService.getCurrentLocation();
/// ```
class LocationService {
  LocationService({
    GeolocatorPlatform? geolocator,
  }) : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  /// Gets the current GPS location.
  ///
  /// Requests permission if not already granted.
  /// Reverse geocodes the coordinates to get an address.
  ///
  /// Throws:
  /// - [LocationPermissionDeniedException] if permission is denied
  /// - [LocationServiceDisabledException] if GPS is disabled
  /// - [LocationTimeoutException] if location cannot be obtained in time
  Future<LocationData> getCurrentLocation({
    Duration? timeout,
    bool includeAddress = true,
  }) async {
    final effectiveTimeout = timeout ?? StaffAppConfig.gpsTimeout;

    // Check if location services are enabled
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // Check and request permission
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(
        'Location permission permanently denied. Please enable in settings.',
      );
    }

    // Get current position
    try {
      final position = await _geolocator
          .getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          )
          .timeout(effectiveTimeout);

      String? address;
      if (includeAddress) {
        address = await _reverseGeocode(position.latitude, position.longitude);
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } on TimeoutException {
      throw const LocationTimeoutException();
    }
  }

  /// Attempts to get current location without throwing on failure.
  ///
  /// Returns null if location cannot be obtained.
  /// Useful when location is optional.
  Future<LocationData?> tryGetCurrentLocation({
    Duration? timeout,
    bool includeAddress = true,
  }) async {
    try {
      return await getCurrentLocation(
        timeout: timeout,
        includeAddress: includeAddress,
      );
    } catch (e) {
      debugPrint('LocationService: Failed to get location: $e');
      return null;
    }
  }

  /// Checks if the device has location permission.
  Future<bool> hasPermission() async {
    final permission = await _geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return _geolocator.isLocationServiceEnabled();
  }

  /// Requests location permission from the user.
  ///
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    var permission = await _geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Opens the device's location settings.
  ///
  /// Useful when permission is permanently denied.
  Future<bool> openLocationSettings() async {
    return _geolocator.openLocationSettings();
  }

  /// Opens the app's permission settings.
  ///
  /// Useful when permission is permanently denied.
  Future<bool> openAppSettings() async {
    return _geolocator.openAppSettings();
  }

  /// Checks if the given coordinates are within any business location geofence.
  ///
  /// Returns the matching [BusinessLocationPoint] if within geofence,
  /// or null if outside all geofences.
  BusinessLocationPoint? checkGeofence({
    required double latitude,
    required double longitude,
    required List<BusinessLocationPoint> locations,
  }) {
    for (final location in locations) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        location.latitude,
        location.longitude,
      );

      if (distance <= location.radiusMeters) {
        debugPrint(
          'LocationService: Within geofence of ${location.name} '
          '(${distance.toStringAsFixed(0)}m from center)',
        );
        return location;
      }
    }

    debugPrint('LocationService: Outside all geofences');
    return null;
  }

  /// Calculates distance between two coordinates in meters.
  ///
  /// Uses the Haversine formula for accuracy.
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Reverse geocodes coordinates to a human-readable address.
  ///
  /// Returns null if geocoding fails.
  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[
        if (place.street?.isNotEmpty == true) place.street!,
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
      ];

      return parts.isNotEmpty ? parts.join(', ') : null;
    } catch (e) {
      debugPrint('LocationService: Reverse geocoding failed: $e');
      return null;
    }
  }

  /// Gets a formatted address from coordinates.
  ///
  /// Public method for manual reverse geocoding.
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return _reverseGeocode(latitude, longitude);
  }
}
