import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local/staff_database.dart';

/// Helper function to queue an action for offline sync.
///
/// Adds an item to the sync queue that will be processed when
/// the device comes back online.
///
/// ## Parameters
/// - [db]: The local database instance
/// - [entityType]: Type of entity ('appointment', 'time_entry', 'session_note')
/// - [entityId]: ID of the entity being modified
/// - [action]: Action being performed (e.g., 'check_in', 'complete', 'clock_out')
/// - [payload]: Optional data to include with the action
///
/// ## Example
/// ```dart
/// await queueAction(
///   db: database,
///   entityType: 'appointment',
///   entityId: 'apt_123',
///   action: 'check_in',
/// );
/// ```
Future<void> queueAction({
  required StaffDatabase db,
  required String entityType,
  required String entityId,
  required String action,
  Map<String, dynamic>? payload,
}) async {
  debugPrint('QueueAction: Queuing $action for $entityType:$entityId');

  await db.syncQueueDao.addToQueue(
    SyncQueueTableCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload != null ? jsonEncode(payload) : '{}',
      createdAt: DateTime.now(),
    ),
  );
}

/// Helper function to queue an appointment action.
///
/// Convenience wrapper around [queueAction] for appointment actions.
Future<void> queueAppointmentAction({
  required StaffDatabase db,
  required String appointmentId,
  required String action,
  Map<String, dynamic>? payload,
}) async {
  await queueAction(
    db: db,
    entityType: 'appointment',
    entityId: appointmentId,
    action: action,
    payload: payload,
  );
}

/// Helper function to queue a time entry action.
///
/// Convenience wrapper around [queueAction] for time entry actions.
Future<void> queueTimeEntryAction({
  required StaffDatabase db,
  required String entryId,
  required String action,
  Map<String, dynamic>? payload,
}) async {
  await queueAction(
    db: db,
    entityType: 'time_entry',
    entityId: entryId,
    action: action,
    payload: payload,
  );
}

/// Helper function to queue a session note action.
///
/// Convenience wrapper around [queueAction] for session note actions.
Future<void> queueSessionNoteAction({
  required StaffDatabase db,
  required String noteId,
  required String action,
  Map<String, dynamic>? payload,
}) async {
  await queueAction(
    db: db,
    entityType: 'session_note',
    entityId: noteId,
    action: action,
    payload: payload,
  );
}

/// Helper to queue a check-in action for an appointment.
Future<void> queueCheckIn({
  required StaffDatabase db,
  required String appointmentId,
}) async {
  await queueAppointmentAction(
    db: db,
    appointmentId: appointmentId,
    action: 'check_in',
  );
}

/// Helper to queue a completion action for an appointment.
Future<void> queueComplete({
  required StaffDatabase db,
  required String appointmentId,
}) async {
  await queueAppointmentAction(
    db: db,
    appointmentId: appointmentId,
    action: 'complete',
  );
}

/// Helper to queue a no-show action for an appointment.
Future<void> queueNoShow({
  required StaffDatabase db,
  required String appointmentId,
}) async {
  await queueAppointmentAction(
    db: db,
    appointmentId: appointmentId,
    action: 'no_show',
  );
}

/// Helper to queue a notes update for an appointment.
Future<void> queueUpdateNotes({
  required StaffDatabase db,
  required String appointmentId,
  required String notes,
}) async {
  await queueAppointmentAction(
    db: db,
    appointmentId: appointmentId,
    action: 'update_notes',
    payload: {'notes': notes},
  );
}

/// Helper to queue a clock-in action.
Future<void> queueClockIn({
  required StaffDatabase db,
  required String entryId,
  required DateTime clockInTime,
  double? latitude,
  double? longitude,
  String? address,
  String? locationId,
  bool outsideGeofence = false,
}) async {
  await queueTimeEntryAction(
    db: db,
    entryId: entryId,
    action: 'clock_in',
    payload: {
      'clockInTime': clockInTime.toIso8601String(),
      'clockInLatitude': latitude,
      'clockInLongitude': longitude,
      'clockInAddress': address,
      'clockInLocationId': locationId,
      'clockInOutsideGeofence': outsideGeofence,
    },
  );
}

/// Helper to queue a clock-out action.
Future<void> queueClockOut({
  required StaffDatabase db,
  required String entryId,
  required DateTime clockOutTime,
  required int totalMinutes,
  required int breakMinutes,
  required int workedMinutes,
  double? latitude,
  double? longitude,
  String? address,
  String? locationId,
  bool outsideGeofence = false,
  String? notes,
}) async {
  await queueTimeEntryAction(
    db: db,
    entryId: entryId,
    action: 'clock_out',
    payload: {
      'clockOutTime': clockOutTime.toIso8601String(),
      'clockOutLatitude': latitude,
      'clockOutLongitude': longitude,
      'clockOutAddress': address,
      'clockOutLocationId': locationId,
      'clockOutOutsideGeofence': outsideGeofence,
      'totalMinutes': totalMinutes,
      'breakMinutes': breakMinutes,
      'workedMinutes': workedMinutes,
      'notes': notes,
    },
  );
}

/// Helper to queue a start break action.
Future<void> queueStartBreak({
  required StaffDatabase db,
  required String entryId,
  required DateTime startTime,
  required String breakType,
}) async {
  await queueTimeEntryAction(
    db: db,
    entryId: entryId,
    action: 'start_break',
    payload: {
      'startTime': startTime.toIso8601String(),
      'type': breakType,
    },
  );
}

/// Helper to queue an end break action.
Future<void> queueEndBreak({
  required StaffDatabase db,
  required String entryId,
  required DateTime endTime,
}) async {
  await queueTimeEntryAction(
    db: db,
    entryId: entryId,
    action: 'end_break',
    payload: {
      'endTime': endTime.toIso8601String(),
    },
  );
}

/// Extension on StaffDatabase for convenient sync queue access.
extension SyncQueueExtension on StaffDatabase {
  /// Queues an action for offline sync.
  Future<void> queueSyncAction({
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    await queueAction(
      db: this,
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
    );
  }
}
