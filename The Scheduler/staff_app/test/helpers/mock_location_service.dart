import 'package:staff_app/core/services/location_service.dart';
import 'package:staff_app/core/services/time_clock_exceptions.dart';

/// Mock implementation of [LocationService] for testing.
///
/// Allows controlling location behavior in tests without
/// actual GPS hardware.
///
/// ## Usage
/// ```dart
/// final mockLocation = MockLocationService();
/// mockLocation.setMockLocation(37.7749, -122.4194, '123 Main St');
///
/// final timeClockService = TimeClockService(
///   db: testDb,
///   locationService: mockLocation,
///   staffId: 'staff-1',
///   businessId: 'biz-1',
/// );
/// ```
class MockLocationService extends LocationService {
  MockLocationService() : super();

  LocationData? _mockLocation;
  bool _shouldFail = false;
  Exception? _failureException;
  bool _serviceEnabled = true;
  bool _permissionGranted = true;

  /// Sets the mock location to be returned.
  void setMockLocation(
    double latitude,
    double longitude, [
    String? address,
  ]) {
    _mockLocation = LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      accuracy: 10.0,
      timestamp: DateTime.now(),
    );
  }

  /// Sets the mock location using [LocationData].
  void setMockLocationData(LocationData? location) {
    _mockLocation = location;
  }

  /// Clears any mock location, causing [tryGetCurrentLocation] to return null.
  void clearMockLocation() {
    _mockLocation = null;
  }

  /// Configures the mock to throw an exception on location requests.
  void setFailure(Exception exception) {
    _shouldFail = true;
    _failureException = exception;
  }

  /// Clears any configured failure.
  void clearFailure() {
    _shouldFail = false;
    _failureException = null;
  }

  /// Sets whether location services are enabled.
  void setServiceEnabled(bool enabled) {
    _serviceEnabled = enabled;
  }

  /// Sets whether location permission is granted.
  void setPermissionGranted(bool granted) {
    _permissionGranted = granted;
  }

  @override
  Future<LocationData> getCurrentLocation({
    Duration? timeout,
    bool includeAddress = true,
  }) async {
    if (_shouldFail && _failureException != null) {
      throw _failureException!;
    }

    if (!_serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    if (!_permissionGranted) {
      throw const LocationPermissionDeniedException();
    }

    if (_mockLocation == null) {
      throw const LocationTimeoutException();
    }

    return _mockLocation!;
  }

  @override
  Future<LocationData?> tryGetCurrentLocation({
    Duration? timeout,
    bool includeAddress = true,
  }) async {
    if (_shouldFail) {
      return null;
    }
    return _mockLocation;
  }

  @override
  Future<bool> hasPermission() async {
    return _permissionGranted;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _serviceEnabled;
  }

  @override
  Future<bool> requestPermission() async {
    return _permissionGranted;
  }

  @override
  Future<bool> openLocationSettings() async {
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Creates a default mock location in San Francisco.
LocationData createMockLocationSF() {
  return LocationData(
    latitude: 37.7749,
    longitude: -122.4194,
    address: '123 Market St, San Francisco, CA',
    accuracy: 10.0,
    timestamp: DateTime.now(),
  );
}

/// Creates a mock location in New York.
LocationData createMockLocationNY() {
  return LocationData(
    latitude: 40.7128,
    longitude: -74.0060,
    address: '456 Broadway, New York, NY',
    accuracy: 15.0,
    timestamp: DateTime.now(),
  );
}
