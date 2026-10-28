import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/providers/route_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/repositories/time_entry_repository.dart';
import '../services/time_clock_geofence_service.dart';
import '../services/time_clock_service.dart';

/// Provider for TimeEntryRepository.
final timeEntryRepositoryProvider = Provider<TimeEntryRepository>((ref) {
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return TimeEntryRepository(auditLogRepository: auditLog);
});

/// Provider for TimeClockService.
final timeClockServiceProvider = Provider<TimeClockService>((ref) {
  final repository = ref.watch(timeEntryRepositoryProvider);
  return TimeClockService(timeEntryRepository: repository);
});

/// Provider for geofence validator used during clock in/out.
final timeClockGeofenceServiceProvider = Provider<TimeClockGeofenceService>((
  ref,
) {
  final locationsRepository = ref.watch(locationsRepositoryProvider);
  final routeRepository = ref.watch(routeRepositoryProvider);
  final gpsService = ref.watch(gpsLocationServiceProvider);

  return TimeClockGeofenceService(
    locationsRepository: locationsRepository,
    routeRepository: routeRepository,
    gpsLocationService: gpsService,
  );
});

/// Provider for active time entry stream.
///
/// Usage:
/// ```dart
/// final activeEntry = ref.watch(activeTimeEntryProvider(securityContext));
/// ```
final activeTimeEntryProvider =
    StreamProvider.family<TimeEntry?, SecurityContext>((ref, context) {
      final service = ref.watch(timeClockServiceProvider);
      return service.watchActiveEntry(context);
    });

/// State notifier for time clock actions.
class TimeClockNotifier extends StateNotifier<TimeClockState> {
  TimeClockNotifier(this._service, this._geofenceService)
    : super(const TimeClockState());

  final TimeClockService _service;
  final TimeClockGeofenceService _geofenceService;

  /// Clock in.
  Future<void> clockIn({
    required SecurityContext context,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final geofence = await _geofenceService.ensureWithinGeofence(context);
      final entry = await _service.clockIn(
        context: context,
        latitude: geofence.latitude,
        longitude: geofence.longitude,
        address: geofence.locationName,
        locationId: geofence.locationId,
        outsideGeofence: !geofence.isWithinGeofence,
        enforceGeofence: true,
      );
      state = state.copyWith(
        isLoading: false,
        activeEntry: entry,
        lastAction: TimeClockAction.clockIn,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clock out.
  Future<void> clockOut({
    required SecurityContext context,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final geofence = await _geofenceService.ensureWithinGeofence(context);
      final entry = await _service.clockOut(
        context: context,
        latitude: geofence.latitude,
        longitude: geofence.longitude,
        address: geofence.locationName,
        locationId: geofence.locationId,
        outsideGeofence: !geofence.isWithinGeofence,
        enforceGeofence: true,
      );
      state = state.copyWith(
        isLoading: false,
        activeEntry: null,
        lastCompletedEntry: entry,
        lastAction: TimeClockAction.clockOut,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start a meal break.
  Future<void> startMealBreak(SecurityContext context) async {
    await _startBreak(context, BreakType.meal);
  }

  /// Start a rest break.
  Future<void> startRestBreak(SecurityContext context) async {
    await _startBreak(context, BreakType.rest);
  }

  Future<void> _startBreak(SecurityContext context, BreakType type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = await _service.startBreak(context: context, type: type);
      state = state.copyWith(
        isLoading: false,
        activeEntry: entry,
        lastAction: type == BreakType.meal
            ? TimeClockAction.startMealBreak
            : TimeClockAction.startRestBreak,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// End the current break.
  Future<void> endBreak(SecurityContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = await _service.endBreak(context: context);
      state = state.copyWith(
        isLoading: false,
        activeEntry: entry,
        lastAction: TimeClockAction.endBreak,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load the current active entry.
  Future<void> loadActiveEntry(SecurityContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entry = await _service.getActiveEntry(context);
      state = state.copyWith(isLoading: false, activeEntry: entry);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear any error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Actions that can be performed on the time clock.
enum TimeClockAction {
  clockIn,
  clockOut,
  startMealBreak,
  startRestBreak,
  endBreak,
}

/// State for the time clock.
class TimeClockState {
  const TimeClockState({
    this.isLoading = false,
    this.activeEntry,
    this.lastCompletedEntry,
    this.lastAction,
    this.error,
  });

  final bool isLoading;
  final TimeEntry? activeEntry;
  final TimeEntry? lastCompletedEntry;
  final TimeClockAction? lastAction;
  final String? error;

  TimeClockState copyWith({
    bool? isLoading,
    TimeEntry? activeEntry,
    TimeEntry? lastCompletedEntry,
    TimeClockAction? lastAction,
    String? error,
  }) {
    return TimeClockState(
      isLoading: isLoading ?? this.isLoading,
      activeEntry: activeEntry ?? this.activeEntry,
      lastCompletedEntry: lastCompletedEntry ?? this.lastCompletedEntry,
      lastAction: lastAction ?? this.lastAction,
      error: error,
    );
  }
}

/// Provider for TimeClockNotifier.
final timeClockNotifierProvider =
    StateNotifierProvider<TimeClockNotifier, TimeClockState>((ref) {
      final service = ref.watch(timeClockServiceProvider);
      final geofenceService = ref.watch(timeClockGeofenceServiceProvider);
      return TimeClockNotifier(service, geofenceService);
    });
