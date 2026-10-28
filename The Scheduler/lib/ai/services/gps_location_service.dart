/// GPS location service for route tracking.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'route_tracking_service.dart';

/// Configuration for GPS location tracking.
class GpsLocationConfig {
  const GpsLocationConfig({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.timeLimit = const Duration(seconds: 15),
  });

  /// Desired accuracy level.
  final LocationAccuracy accuracy;

  /// Minimum distance (in meters) before an update is triggered.
  final int distanceFilter;

  /// Time limit for getting initial position.
  final Duration timeLimit;

  /// Default config for route tracking (high accuracy, frequent updates).
  static const routeTracking = GpsLocationConfig(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  /// Battery-saving config (lower accuracy, less frequent).
  static const batterySaving = GpsLocationConfig(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 50, // Update every 50 meters
  );
}

/// Result of a permission check.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Service for GPS location tracking.
///
/// Provides methods for:
/// - Getting current location
/// - Streaming location updates
/// - Permission handling
class GpsLocationService {
  GpsLocationService({
    GpsLocationConfig? config,
  }) : _config = config ?? GpsLocationConfig.routeTracking;

  final GpsLocationConfig _config;

  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<CurrentLocation>.broadcast();

  /// Stream of location updates.
  Stream<CurrentLocation> get locationStream => _locationController.stream;

  /// Whether currently tracking location.
  bool get isTracking => _positionSubscription != null;

  /// Check current permission status.
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Check permission
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  /// Request location permission.
  Future<LocationPermissionStatus> requestPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Check current permission
    var permission = await Geolocator.checkPermission();

    // Request if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }

  /// Open device location settings.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission denied forever).
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Get current location once.
  Future<CurrentLocation?> getCurrentLocation() async {
    final status = await requestPermission();
    if (status != LocationPermissionStatus.granted) {
      debugPrint('GpsLocationService: Permission not granted: $status');
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _config.accuracy,
          timeLimit: _config.timeLimit,
        ),
      );

      return _positionToCurrentLocation(position);
    } catch (e) {
      debugPrint('GpsLocationService: Failed to get location: $e');
      return null;
    }
  }

  /// Start streaming location updates.
  Future<bool> startTracking() async {
    if (_positionSubscription != null) {
      debugPrint('GpsLocationService: Already tracking');
      return true;
    }

    final status = await requestPermission();
    if (status != LocationPermissionStatus.granted) {
      debugPrint('GpsLocationService: Permission not granted: $status');
      return false;
    }

    final locationSettings = LocationSettings(
      accuracy: _config.accuracy,
      distanceFilter: _config.distanceFilter,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        final location = _positionToCurrentLocation(position);
        _locationController.add(location);
        debugPrint(
          'GpsLocationService: Location update - '
          '${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)} '
          '(accuracy: ${location.accuracyMeters?.toStringAsFixed(0)}m)',
        );
      },
      onError: (error) {
        debugPrint('GpsLocationService: Stream error: $error');
      },
    );

    debugPrint('GpsLocationService: Started tracking');
    return true;
  }

  /// Stop streaming location updates.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('GpsLocationService: Stopped tracking');
  }

  CurrentLocation _positionToCurrentLocation(Position position) {
    return CurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedMps: position.speed >= 0 ? position.speed : null,
      headingDegrees: position.heading >= 0 ? position.heading : null,
      timestamp: position.timestamp,
    );
  }

  /// Dispose of resources.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
