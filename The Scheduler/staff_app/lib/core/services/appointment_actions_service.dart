import 'package:flutter/foundation.dart';

import '../../data/local/staff_database.dart';
import '../../data/sync/queue_action.dart';

/// Handles appointment actions (check-in, complete, no-show, notes) with offline support.
class AppointmentActionsService {
  AppointmentActionsService({
    required StaffDatabase db,
    required String staffId,
  })  : _db = db,
        _staffId = staffId;

  final StaffDatabase _db;
  final String _staffId;

  Future<void> checkIn(String appointmentId) async {
    await _db.appointmentsDao.checkIn(appointmentId, _staffId);
    await _db.appointmentsDao.markPendingSync(appointmentId, 'check_in');
    await queueCheckIn(db: _db, appointmentId: appointmentId);
    debugPrint('AppointmentActionsService: queued check-in for $appointmentId');
  }

  Future<void> complete(String appointmentId) async {
    await _db.appointmentsDao.complete(appointmentId, _staffId);
    await _db.appointmentsDao.markPendingSync(appointmentId, 'complete');
    await queueComplete(db: _db, appointmentId: appointmentId);
    debugPrint(
        'AppointmentActionsService: queued completion for $appointmentId');
  }

  Future<void> markNoShow(String appointmentId) async {
    await _db.appointmentsDao.updateStatus(appointmentId, 'noShow');
    await _db.appointmentsDao.markPendingSync(appointmentId, 'no_show');
    await queueNoShow(db: _db, appointmentId: appointmentId);
    debugPrint('AppointmentActionsService: queued no-show for $appointmentId');
  }

  Future<void> updateNotes(String appointmentId, String notes) async {
    await _db.appointmentsDao.updateStaffNotes(appointmentId, notes);
    await _db.appointmentsDao.markPendingSync(appointmentId, 'update_notes');
    await queueUpdateNotes(db: _db, appointmentId: appointmentId, notes: notes);
    debugPrint(
        'AppointmentActionsService: queued notes update for $appointmentId');
  }
}
