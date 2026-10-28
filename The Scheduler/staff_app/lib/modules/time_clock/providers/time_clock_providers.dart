import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/time_clock_service.dart';
import '../../../data/local/staff_database.dart';
import '../models/clock_state.dart';

/// Provider for the location service.
///
/// Used by the time clock service to capture GPS coordinates.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for the time clock service.
///
/// Requires authenticated user (staffId and businessId).
/// Returns null if user is not authenticated.
final timeClockServiceProvider = Provider<TimeClockService?>((ref) {
  final db = ref.watch(databaseProvider);
  final locationService = ref.watch(locationServiceProvider);
  final staffUser = ref.watch(currentStaffUserProvider);

  final user = staffUser.valueOrNull;
  if (user == null) {
    return null;
  }

  return TimeClockService(
    db: db,
    locationService: locationService,
    staffId: user.providerId,
    businessId: user.businessId,
  );
});

/// Stream provider for the active time entry.
///
/// Emits null when not clocked in.
final activeTimeEntryProvider =
    StreamProvider<TimeEntriesTableData?>((ref) async* {
  final service = ref.watch(timeClockServiceProvider);
  if (service == null) {
    yield null;
    return;
  }

  yield* service.watchActiveEntry();
});

/// Stream provider for the current clock state.
///
/// Provides real-time clock state updates for the UI.
final clockStateProvider = StreamProvider<ClockState>((ref) async* {
  final service = ref.watch(timeClockServiceProvider);
  if (service == null) {
    yield const ClockState.notClockedIn();
    return;
  }

  yield* service.watchClockState();
});

/// Provider for whether the user is currently clocked in.
///
/// Derived from [clockStateProvider].
final isClockedInProvider = Provider<bool>((ref) {
  final clockState = ref.watch(clockStateProvider);
  return clockState.valueOrNull?.isClockedIn ?? false;
});

/// Provider for whether the user is currently on break.
///
/// Derived from [clockStateProvider].
final isOnBreakProvider = Provider<bool>((ref) {
  final clockState = ref.watch(clockStateProvider);
  return clockState.valueOrNull?.isOnBreak ?? false;
});

/// Stream provider for today's time entries.
///
/// Provides real-time updates as entries are added or modified.
final todayTimeEntriesProvider =
    StreamProvider<List<TimeEntriesTableData>>((ref) async* {
  final service = ref.watch(timeClockServiceProvider);
  if (service == null) {
    yield [];
    return;
  }

  yield* service.watchTodayEntries();
});

/// Provider for elapsed time since clock in.
///
/// Updates every second when clocked in.
/// Returns Duration.zero when not clocked in.
final elapsedTimeProvider = StreamProvider<Duration>((ref) async* {
  final clockState = ref.watch(clockStateProvider);
  final state = clockState.valueOrNull;

  if (state == null || !state.isClockedIn || state.clockInTime == null) {
    yield Duration.zero;
    return;
  }

  // Emit current elapsed time immediately
  yield DateTime.now().difference(state.clockInTime!);

  // Update every second
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().difference(state.clockInTime!),
  );
});

/// Provider for formatted elapsed time string (HH:MM:SS).
///
/// Derived from [elapsedTimeProvider].
final elapsedTimeFormattedProvider = Provider<String>((ref) {
  final elapsed = ref.watch(elapsedTimeProvider);
  final duration = elapsed.valueOrNull ?? Duration.zero;
  return _formatDuration(duration);
});

/// Provider for worked time (elapsed minus breaks).
///
/// Updates every second when clocked in.
final workedTimeProvider = StreamProvider<Duration>((ref) async* {
  final clockState = ref.watch(clockStateProvider);
  final state = clockState.valueOrNull;

  if (state == null || !state.isClockedIn || state.clockInTime == null) {
    yield Duration.zero;
    return;
  }

  // Emit current worked time immediately
  yield state.workedDuration;

  // Update every second
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => ClockState.fromEntry(ref.read(activeTimeEntryProvider).valueOrNull)
        .workedDuration,
  );
});

/// Provider for formatted worked time string (HH:MM:SS).
///
/// Derived from [workedTimeProvider].
final workedTimeFormattedProvider = Provider<String>((ref) {
  final worked = ref.watch(workedTimeProvider);
  final duration = worked.valueOrNull ?? Duration.zero;
  return _formatDuration(duration);
});

/// Provider for current break duration.
///
/// Updates every second when on break.
/// Returns Duration.zero when not on break.
final breakTimeProvider = StreamProvider<Duration>((ref) async* {
  final clockState = ref.watch(clockStateProvider);
  final state = clockState.valueOrNull;

  if (state == null || !state.isOnBreak || state.currentBreakStart == null) {
    yield Duration.zero;
    return;
  }

  // Emit current break time immediately
  yield DateTime.now().difference(state.currentBreakStart!);

  // Update every second
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().difference(state.currentBreakStart!),
  );
});

/// Provider for formatted break time string (HH:MM:SS).
final breakTimeFormattedProvider = Provider<String>((ref) {
  final breakTime = ref.watch(breakTimeProvider);
  final duration = breakTime.valueOrNull ?? Duration.zero;
  return _formatDuration(duration);
});

/// Provider for total today's worked hours.
///
/// Sums completed entries plus current entry if clocked in.
final todayTotalHoursProvider = Provider<double>((ref) {
  final entries = ref.watch(todayTimeEntriesProvider).valueOrNull ?? [];
  final clockState = ref.watch(clockStateProvider).valueOrNull;

  double totalMinutes = 0;

  // Sum completed entries
  for (final entry in entries) {
    if (entry.workedMinutes != null) {
      totalMinutes += entry.workedMinutes!;
    }
  }

  // Add current session if clocked in
  if (clockState != null && clockState.isClockedIn) {
    totalMinutes += clockState.workedDuration.inMinutes;
  }

  return totalMinutes / 60.0;
});

/// Provider for location permission status.
///
/// Checks if the app has location permission.
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.hasPermission();
});

/// Provider for location services enabled status.
final locationServicesEnabledProvider = FutureProvider<bool>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.isLocationServiceEnabled();
});

/// Helper to format Duration as HH:MM:SS.
String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Notifier for handling time clock actions with loading/error state.
///
/// Use this for triggering clock in/out and break actions from the UI.
class TimeClockActionsNotifier extends StateNotifier<TimeClockActionState> {
  TimeClockActionsNotifier(this._ref) : super(const TimeClockActionState.idle());

  final Ref _ref;

  TimeClockService? get _service => _ref.read(timeClockServiceProvider);

  /// Clocks in the user.
  Future<void> clockIn() async {
    if (_service == null) return;

    state = const TimeClockActionState.loading();
    try {
      await _service!.clockIn();
      state = const TimeClockActionState.success('Clocked in successfully');
    } catch (e) {
      state = TimeClockActionState.error(e.toString());
    }
  }

  /// Clocks out the user.
  Future<void> clockOut({String? notes}) async {
    if (_service == null) return;

    state = const TimeClockActionState.loading();
    try {
      await _service!.clockOut(notes: notes);
      state = const TimeClockActionState.success('Clocked out successfully');
    } catch (e) {
      state = TimeClockActionState.error(e.toString());
    }
  }

  /// Starts a break.
  Future<void> startBreak(BreakType type) async {
    if (_service == null) return;

    state = const TimeClockActionState.loading();
    try {
      await _service!.startBreak(type);
      state = TimeClockActionState.success('${type.displayName} started');
    } catch (e) {
      state = TimeClockActionState.error(e.toString());
    }
  }

  /// Ends the current break.
  Future<void> endBreak() async {
    if (_service == null) return;

    state = const TimeClockActionState.loading();
    try {
      await _service!.endBreak();
      state = const TimeClockActionState.success('Break ended');
    } catch (e) {
      state = TimeClockActionState.error(e.toString());
    }
  }

  /// Resets the action state to idle.
  void reset() {
    state = const TimeClockActionState.idle();
  }
}

/// State for time clock actions.
class TimeClockActionState {
  const TimeClockActionState._({
    required this.isLoading,
    this.errorMessage,
    this.successMessage,
  });

  const TimeClockActionState.idle()
      : this._(isLoading: false, errorMessage: null, successMessage: null);

  const TimeClockActionState.loading()
      : this._(isLoading: true, errorMessage: null, successMessage: null);

  const TimeClockActionState.success(String message)
      : this._(isLoading: false, errorMessage: null, successMessage: message);

  const TimeClockActionState.error(String message)
      : this._(isLoading: false, errorMessage: message, successMessage: null);

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;
}

/// Provider for time clock action notifier.
final timeClockActionsProvider =
    StateNotifierProvider<TimeClockActionsNotifier, TimeClockActionState>(
  (ref) => TimeClockActionsNotifier(ref),
);

/// Alias for today's entries (for UI consistency).
final todaysEntriesProvider = todayTimeEntriesProvider;

/// Provider for count of entries pending sync.
final pendingSyncCountProvider = StreamProvider<int>((ref) async* {
  final db = ref.watch(databaseProvider);
  yield* db.timeEntriesDao.watchPendingSyncCount();
});
