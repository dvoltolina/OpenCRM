import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/staff_database.dart';
import '../../data/sync/queue_action.dart';
import '../../modules/time_clock/models/clock_state.dart';
import 'location_service.dart';
import 'time_clock_exceptions.dart';

/// Service for managing time clock operations (clock in/out, breaks).
///
/// This service handles all time clock business logic including:
/// - Clocking in and out with GPS location
/// - Starting and ending breaks
/// - Calculating worked hours and break time
/// - Queuing changes for offline sync
///
/// ## Usage
/// ```dart
/// final service = TimeClockService(
///   db: database,
///   locationService: LocationService(),
///   staffId: currentUser.providerId,
///   businessId: currentUser.businessId,
/// );
///
/// // Clock in
/// final entry = await service.clockIn();
///
/// // Take a break
/// await service.startBreak(BreakType.meal);
/// await service.endBreak();
///
/// // Clock out
/// await service.clockOut(notes: 'Completed all tasks');
/// ```
class TimeClockService {
  TimeClockService({
    required StaffDatabase db,
    required LocationService locationService,
    required String staffId,
    required String businessId,
    List<BusinessLocationPoint>? businessLocations,
  })  : _db = db,
        _locationService = locationService,
        _staffId = staffId,
        _businessId = businessId,
        _businessLocations = businessLocations ?? [];

  final StaffDatabase _db;
  final LocationService _locationService;
  final String _staffId;
  final String _businessId;
  final List<BusinessLocationPoint> _businessLocations;

  static const _uuid = Uuid();

  /// Clocks in the staff member.
  ///
  /// Creates a new time entry with the current time and location.
  /// Queues the action for sync to Firestore.
  ///
  /// Throws [AlreadyClockedInException] if already clocked in.
  Future<TimeEntriesTableData> clockIn() async {
    debugPrint('TimeClockService: Attempting clock in for $_staffId');

    // Check for existing active entry
    final existing = await _db.timeEntriesDao.getActiveTimeEntry(_staffId);
    if (existing != null) {
      throw const AlreadyClockedInException();
    }

    // Get current location (optional - don't fail if unavailable)
    final location = await _locationService.tryGetCurrentLocation();

    // Check geofence if location available
    String? locationId;
    bool outsideGeofence = false;
    if (location != null && _businessLocations.isNotEmpty) {
      final matchedLocation = _locationService.checkGeofence(
        latitude: location.latitude,
        longitude: location.longitude,
        locations: _businessLocations,
      );
      locationId = matchedLocation?.id;
      outsideGeofence = matchedLocation == null;
    }

    // Create new time entry
    final now = DateTime.now();
    final entryId = _uuid.v4();

    final entry = TimeEntriesTableCompanion.insert(
      id: entryId,
      businessId: _businessId,
      staffId: _staffId,
      clockInTime: now,
      clockInLatitude: Value(location?.latitude),
      clockInLongitude: Value(location?.longitude),
      clockInAddress: Value(location?.address),
      clockInLocationId: Value(locationId),
      clockInOutsideGeofence: Value(outsideGeofence),
      status: 'active',
      createdAt: now,
      pendingSync: const Value(true),
      syncAction: const Value('clock_in'),
    );

    await _db.timeEntriesDao.insertTimeEntry(entry);

    // Queue sync action
    await queueClockIn(
      db: _db,
      entryId: entryId,
      clockInTime: now,
      latitude: location?.latitude,
      longitude: location?.longitude,
      address: location?.address,
      locationId: locationId,
      outsideGeofence: outsideGeofence,
    );

    debugPrint('TimeClockService: Clocked in successfully - entry: $entryId');

    // Return the created entry
    return (await _db.timeEntriesDao.getTimeEntryById(entryId))!;
  }

  /// Clocks out the staff member.
  ///
  /// Updates the active time entry with clock out time and location.
  /// Calculates total worked minutes and break minutes.
  /// Queues the action for sync to Firestore.
  ///
  /// Throws [NotClockedInException] if not clocked in.
  /// Throws [AlreadyOnBreakException] if currently on break.
  Future<TimeEntriesTableData> clockOut({String? notes}) async {
    debugPrint('TimeClockService: Attempting clock out for $_staffId');

    // Get active entry
    final activeEntry = await _db.timeEntriesDao.getActiveTimeEntry(_staffId);
    if (activeEntry == null) {
      throw const NotClockedInException();
    }

    // Check if on break - must end break first
    final clockState = ClockState.fromEntry(activeEntry);
    if (clockState.isOnBreak) {
      throw const AlreadyOnBreakException(
        'Please end your break before clocking out.',
      );
    }

    // Get current location
    final location = await _locationService.tryGetCurrentLocation();

    // Check geofence
    String? locationId;
    bool outsideGeofence = false;
    if (location != null && _businessLocations.isNotEmpty) {
      final matchedLocation = _locationService.checkGeofence(
        latitude: location.latitude,
        longitude: location.longitude,
        locations: _businessLocations,
      );
      locationId = matchedLocation?.id;
      outsideGeofence = matchedLocation == null;
    }

    // Calculate totals
    final clockOutTime = DateTime.now();
    final totalMinutes =
        clockOutTime.difference(activeEntry.clockInTime).inMinutes;
    final breakMinutes = clockState.totalBreakMinutes;
    final workedMinutes = totalMinutes - breakMinutes;

    // Update the entry
    await _db.timeEntriesDao.clockOut(
      activeEntry.id,
      clockOutTime: clockOutTime,
      latitude: location?.latitude,
      longitude: location?.longitude,
      address: location?.address,
      locationId: locationId,
      outsideGeofence: outsideGeofence,
      totalMinutes: totalMinutes,
      breakMinutes: breakMinutes,
      workedMinutes: workedMinutes,
      notes: notes,
    );

    // Mark pending sync
    await _db.timeEntriesDao.markPendingSync(activeEntry.id, action: 'clock_out');

    // Queue sync action
    await queueClockOut(
      db: _db,
      entryId: activeEntry.id,
      clockOutTime: clockOutTime,
      totalMinutes: totalMinutes,
      breakMinutes: breakMinutes,
      workedMinutes: workedMinutes,
      latitude: location?.latitude,
      longitude: location?.longitude,
      address: location?.address,
      locationId: locationId,
      outsideGeofence: outsideGeofence,
      notes: notes,
    );

    debugPrint(
      'TimeClockService: Clocked out successfully - '
      'worked: $workedMinutes min, breaks: $breakMinutes min',
    );

    // Return the updated entry
    return (await _db.timeEntriesDao.getTimeEntryById(activeEntry.id))!;
  }

  /// Starts a break of the specified type.
  ///
  /// Updates the active time entry's breaks JSON.
  /// Queues the action for sync to Firestore.
  ///
  /// Throws [NotClockedInException] if not clocked in.
  /// Throws [AlreadyOnBreakException] if already on break.
  Future<void> startBreak(BreakType type) async {
    debugPrint('TimeClockService: Starting ${type.value} break for $_staffId');

    // Get active entry
    final activeEntry = await _db.timeEntriesDao.getActiveTimeEntry(_staffId);
    if (activeEntry == null) {
      throw const NotClockedInException();
    }

    // Check if already on break
    final clockState = ClockState.fromEntry(activeEntry);
    if (clockState.isOnBreak) {
      throw const AlreadyOnBreakException();
    }

    // Parse existing breaks
    List<Map<String, dynamic>> breaks = [];
    try {
      breaks = (jsonDecode(activeEntry.breaksJson) as List)
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('TimeClockService: Failed to parse breaks: $e');
    }

    // Add new break
    final breakStart = DateTime.now();
    breaks.add({
      'startTime': breakStart.toIso8601String(),
      'type': type.value,
    });

    // Update the entry
    await _db.timeEntriesDao.updateBreaks(activeEntry.id, jsonEncode(breaks));
    await _db.timeEntriesDao.markPendingSync(activeEntry.id, action: 'start_break');

    // Queue sync action
    await queueStartBreak(
      db: _db,
      entryId: activeEntry.id,
      startTime: breakStart,
      breakType: type.value,
    );

    debugPrint('TimeClockService: Started ${type.value} break');
  }

  /// Ends the current break.
  ///
  /// Updates the active time entry's breaks JSON with end time.
  /// Queues the action for sync to Firestore.
  ///
  /// Throws [NotClockedInException] if not clocked in.
  /// Throws [NotOnBreakException] if not on break.
  Future<void> endBreak() async {
    debugPrint('TimeClockService: Ending break for $_staffId');

    // Get active entry
    final activeEntry = await _db.timeEntriesDao.getActiveTimeEntry(_staffId);
    if (activeEntry == null) {
      throw const NotClockedInException();
    }

    // Check if on break
    final clockState = ClockState.fromEntry(activeEntry);
    if (!clockState.isOnBreak) {
      throw const NotOnBreakException();
    }

    // Parse existing breaks
    List<Map<String, dynamic>> breaks = [];
    try {
      breaks = (jsonDecode(activeEntry.breaksJson) as List)
          .cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('TimeClockService: Failed to parse breaks: $e');
      throw const NotOnBreakException();
    }

    // End the last break
    if (breaks.isEmpty) {
      throw const NotOnBreakException();
    }

    final breakEnd = DateTime.now();
    breaks.last['endTime'] = breakEnd.toIso8601String();

    // Update the entry
    await _db.timeEntriesDao.updateBreaks(activeEntry.id, jsonEncode(breaks));
    await _db.timeEntriesDao.markPendingSync(activeEntry.id, action: 'end_break');

    // Queue sync action
    await queueEndBreak(
      db: _db,
      entryId: activeEntry.id,
      endTime: breakEnd,
    );

    debugPrint('TimeClockService: Ended break');
  }

  /// Gets the current active time entry, if any.
  Future<TimeEntriesTableData?> getActiveEntry() async {
    return _db.timeEntriesDao.getActiveTimeEntry(_staffId);
  }

  /// Watches the current active time entry.
  Stream<TimeEntriesTableData?> watchActiveEntry() {
    return _db.timeEntriesDao.watchActiveTimeEntry(_staffId);
  }

  /// Gets today's time entries for this staff member.
  Future<List<TimeEntriesTableData>> getTodayEntries() async {
    return _db.timeEntriesDao.getTodayEntries(_staffId);
  }

  /// Watches today's time entries for real-time updates.
  Stream<List<TimeEntriesTableData>> watchTodayEntries() {
    return _db.timeEntriesDao.watchTodayEntries(_staffId);
  }

  /// Gets time entries for a date range.
  Future<List<TimeEntriesTableData>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async {
    return _db.timeEntriesDao.getEntriesInRange(_staffId, start, end);
  }

  /// Gets the current clock state.
  Future<ClockState> getClockState() async {
    final entry = await getActiveEntry();
    return ClockState.fromEntry(entry);
  }

  /// Watches the clock state for real-time UI updates.
  Stream<ClockState> watchClockState() {
    return watchActiveEntry().map((entry) => ClockState.fromEntry(entry));
  }

  /// Updates the notes on an active or pending time entry.
  Future<void> updateNotes(String entryId, String notes) async {
    debugPrint('TimeClockService: Updating notes for entry $entryId');

    final entry = await _db.timeEntriesDao.getTimeEntryById(entryId);
    if (entry == null) {
      throw const TimeEntryNotFoundException();
    }

    if (entry.status == 'approved') {
      throw const TimeEntryAlreadyApprovedException();
    }

    await _db.timeEntriesDao.updateTimeEntry(
      entryId,
      TimeEntriesTableCompanion(
        staffNotes: Value(notes),
        updatedAt: Value(DateTime.now()),
        pendingSync: const Value(true),
        syncAction: const Value('update_notes'),
      ),
    );

    await queueTimeEntryAction(
      db: _db,
      entryId: entryId,
      action: 'update_notes',
      payload: {'notes': notes},
    );
  }

  /// Staff ID this service is configured for.
  String get staffId => _staffId;

  /// Business ID this service is configured for.
  String get businessId => _businessId;
}
