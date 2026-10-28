/// Base exception class for time clock related errors.
abstract class TimeClockException implements Exception {
  const TimeClockException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when attempting to clock in while already clocked in.
class AlreadyClockedInException extends TimeClockException {
  const AlreadyClockedInException([
    super.message = 'Already clocked in. Please clock out first.',
  ]);
}

/// Thrown when attempting to clock out or take a break without being clocked in.
class NotClockedInException extends TimeClockException {
  const NotClockedInException([
    super.message = 'Not currently clocked in.',
  ]);
}

/// Thrown when attempting to start a break while already on break.
class AlreadyOnBreakException extends TimeClockException {
  const AlreadyOnBreakException([
    super.message = 'Already on break. Please end break first.',
  ]);
}

/// Thrown when attempting to end a break without being on break.
class NotOnBreakException extends TimeClockException {
  const NotOnBreakException([
    super.message = 'Not currently on break.',
  ]);
}

/// Thrown when location permission is denied.
class LocationPermissionDeniedException extends TimeClockException {
  const LocationPermissionDeniedException([
    super.message = 'Location permission denied. Please enable location access.',
  ]);
}

/// Thrown when location services are disabled.
class LocationServiceDisabledException extends TimeClockException {
  const LocationServiceDisabledException([
    super.message = 'Location services are disabled. Please enable GPS.',
  ]);
}

/// Thrown when unable to get current location within timeout.
class LocationTimeoutException extends TimeClockException {
  const LocationTimeoutException([
    super.message = 'Could not get location in time. Please try again.',
  ]);
}

/// Thrown when time entry is not found in the database.
class TimeEntryNotFoundException extends TimeClockException {
  const TimeEntryNotFoundException([
    super.message = 'Time entry not found.',
  ]);
}

/// Thrown when attempting to modify an approved time entry.
class TimeEntryAlreadyApprovedException extends TimeClockException {
  const TimeEntryAlreadyApprovedException([
    super.message = 'Cannot modify an approved time entry.',
  ]);
}

/// Thrown when a business location cannot be found for geofence validation.
class BusinessLocationNotFoundException extends TimeClockException {
  const BusinessLocationNotFoundException([
    super.message = 'Business location not found for geofence validation.',
  ]);
}
