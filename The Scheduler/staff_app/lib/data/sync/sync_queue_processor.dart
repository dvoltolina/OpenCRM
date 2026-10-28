import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../local/staff_database.dart';
import '../../core/config/staff_app_config.dart';

/// Processes the offline sync queue, pushing local changes to Firestore.
///
/// The queue processor handles different entity types and actions:
/// - Appointments: check_in, complete, update_notes, no_show
/// - Time entries: clock_in, clock_out, start_break, end_break
/// - Session notes: create, update
///
/// Failed items are retried up to [StaffAppConfig.maxSyncRetries] times.
class SyncQueueProcessor {
  SyncQueueProcessor({
    required StaffDatabase db,
    required FirebaseFirestore firestore,
    required String staffId,
    required String businessId,
  })  : _db = db,
        _firestore = firestore,
        _staffId = staffId,
        _businessId = businessId;

  final StaffDatabase _db;
  final FirebaseFirestore _firestore;
  final String _staffId;
  final String _businessId;

  bool _isProcessing = false;

  /// Whether the processor is currently processing items.
  bool get isProcessing => _isProcessing;

  /// Processes all pending items in the sync queue.
  ///
  /// Items are processed in FIFO order. Failed items have their
  /// retry count incremented and error recorded. Items exceeding
  /// max retries are removed from the queue.
  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint('SyncQueueProcessor: Already processing');
      return;
    }

    _isProcessing = true;

    try {
      final pendingItems = await _db.syncQueueDao
          .getPendingItemsWithRetryLimit(StaffAppConfig.maxSyncRetries);

      debugPrint(
          'SyncQueueProcessor: Processing ${pendingItems.length} items');

      for (final item in pendingItems) {
        try {
          await _processItem(item);
          await _db.syncQueueDao.removeFromQueue(item.id);
          debugPrint(
              'SyncQueueProcessor: Successfully processed item ${item.id}');
        } catch (e) {
          debugPrint(
              'SyncQueueProcessor: Failed to process item ${item.id}: $e');
          await _db.syncQueueDao.incrementRetryCount(item.id, e.toString());
        }
      }

      // Clean up items that have exceeded max retries
      final failedCount = await _db.syncQueueDao
          .clearOldFailedItems(StaffAppConfig.maxSyncRetries);
      if (failedCount > 0) {
        debugPrint(
            'SyncQueueProcessor: Cleared $failedCount permanently failed items');
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Processes a single queue item.
  Future<void> _processItem(SyncQueueTableData item) async {
    final payload = _decodePayload(item.payload);

    switch (item.entityType) {
      case 'appointment':
        await _processAppointmentAction(item.entityId, item.action, payload);
        break;
      case 'time_entry':
        await _processTimeEntryAction(item.entityId, item.action, payload);
        break;
      case 'session_note':
        await _processSessionNoteAction(item.entityId, item.action, payload);
        break;
      default:
        throw UnsupportedError('Unknown entity type: ${item.entityType}');
    }
  }

  /// Decodes JSON payload from queue item.
  Map<String, dynamic> _decodePayload(String payload) {
    if (payload.isEmpty) return {};
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('SyncQueueProcessor: Failed to decode payload: $e');
      return {};
    }
  }

  /// Processes appointment-related actions.
  Future<void> _processAppointmentAction(
    String appointmentId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    final docRef = _firestore
        .collection('businesses')
        .doc(_businessId)
        .collection('appointments')
        .doc(appointmentId);

    switch (action) {
      case 'check_in':
        await docRef.update({
          'checkedInAt': FieldValue.serverTimestamp(),
          'checkedInByStaffId': _staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Clear pending sync flag locally
        await _db.appointmentsDao.clearPendingSync(appointmentId);
        break;

      case 'complete':
        await docRef.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedByStaffId': _staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.appointmentsDao.clearPendingSync(appointmentId);
        break;

      case 'no_show':
        await docRef.update({
          'status': 'noShow',
          'markedNoShowAt': FieldValue.serverTimestamp(),
          'markedNoShowByStaffId': _staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.appointmentsDao.clearPendingSync(appointmentId);
        break;

      case 'update_notes':
        await docRef.update({
          'staffNotes': payload['notes'],
          'lastUpdatedByStaffId': _staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.appointmentsDao.clearPendingSync(appointmentId);
        break;

      case 'update_status':
        await docRef.update({
          'status': payload['status'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.appointmentsDao.clearPendingSync(appointmentId);
        break;

      default:
        throw UnsupportedError('Unknown appointment action: $action');
    }
  }

  /// Processes time entry-related actions.
  Future<void> _processTimeEntryAction(
    String entryId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    final collectionRef = _firestore
        .collection('businesses')
        .doc(_businessId)
        .collection('timeEntries');

    switch (action) {
      case 'clock_in':
        // Create new time entry document
        await collectionRef.doc(entryId).set({
          'id': entryId,
          'businessId': _businessId,
          'staffId': _staffId,
          'clockInTime': _parseDateTime(payload['clockInTime']),
          'clockInLatitude': payload['clockInLatitude'],
          'clockInLongitude': payload['clockInLongitude'],
          'clockInAddress': payload['clockInAddress'],
          'clockInLocationId': payload['clockInLocationId'],
          'clockInOutsideGeofence': payload['clockInOutsideGeofence'] ?? false,
          'status': 'active',
          'breaks': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Clear pending sync flag locally
        await _db.timeEntriesDao.clearPendingSync(entryId);
        break;

      case 'clock_out':
        await collectionRef.doc(entryId).update({
          'clockOutTime': _parseDateTime(payload['clockOutTime']),
          'clockOutLatitude': payload['clockOutLatitude'],
          'clockOutLongitude': payload['clockOutLongitude'],
          'clockOutAddress': payload['clockOutAddress'],
          'clockOutLocationId': payload['clockOutLocationId'],
          'clockOutOutsideGeofence': payload['clockOutOutsideGeofence'] ?? false,
          'totalMinutes': payload['totalMinutes'],
          'breakMinutes': payload['breakMinutes'],
          'workedMinutes': payload['workedMinutes'],
          'staffNotes': payload['notes'],
          'status': 'pending', // Pending approval
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.timeEntriesDao.clearPendingSync(entryId);
        break;

      case 'start_break':
        // Add break to the breaks array
        final breakData = {
          'startTime': _parseDateTime(payload['startTime']),
          'type': payload['type'],
        };
        await collectionRef.doc(entryId).update({
          'breaks': FieldValue.arrayUnion([breakData]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.timeEntriesDao.clearPendingSync(entryId);
        break;

      case 'end_break':
        // This is complex - need to update the last break's endTime
        // Fetch current breaks, update last one, write back
        final docSnapshot = await collectionRef.doc(entryId).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() ?? {};
          final breaks = List<Map<String, dynamic>>.from(
              (data['breaks'] as List?) ?? []);

          if (breaks.isNotEmpty) {
            // Update the last break's endTime
            breaks.last['endTime'] = _parseDateTime(payload['endTime']);

            await collectionRef.doc(entryId).update({
              'breaks': breaks,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        await _db.timeEntriesDao.clearPendingSync(entryId);
        break;

      case 'update_notes':
        await collectionRef.doc(entryId).update({
          'staffNotes': payload['notes'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _db.timeEntriesDao.clearPendingSync(entryId);
        break;

      default:
        throw UnsupportedError('Unknown time entry action: $action');
    }
  }

  /// Processes session note-related actions.
  Future<void> _processSessionNoteAction(
    String noteId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    final collectionRef = _firestore
        .collection('businesses')
        .doc(_businessId)
        .collection('session_notes');

    switch (action) {
      case 'create':
        await collectionRef.doc(noteId).set({
          ...payload,
          'id': noteId,
          'businessId': _businessId,
          'createdBy': _staffId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        break;

      case 'update':
        await collectionRef.doc(noteId).update({
          ...payload,
          'lastEditedBy': _staffId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        break;

      case 'delete':
        await collectionRef.doc(noteId).delete();
        break;

      default:
        throw UnsupportedError('Unknown session note action: $action');
    }
  }

  /// Parses a DateTime from various formats.
  Timestamp? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      final dt = DateTime.tryParse(value);
      return dt != null ? Timestamp.fromDate(dt) : null;
    }
    return null;
  }
}
