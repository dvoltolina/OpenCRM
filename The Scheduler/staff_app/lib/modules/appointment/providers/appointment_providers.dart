import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/appointment_actions_service.dart';
import '../../../data/local/staff_database.dart';

/// Appointment stream by ID.
final appointmentProvider =
    StreamProvider.family<AppointmentsTableData?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.appointmentsDao.watchAppointmentById(id);
});

/// Client lookup for an appointment.
final clientProvider =
    FutureProvider.family<ClientsTableData?, String>((ref, clientId) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clientsTable)
        ..where((c) => c.id.equals(clientId))
        ..limit(1))
      .getSingleOrNull();
});

/// Appointment actions service.
final appointmentActionsProvider = Provider<AppointmentActionsService?>((ref) {
  final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;
  if (staffUser == null) return null;
  final db = ref.watch(databaseProvider);
  return AppointmentActionsService(db: db, staffId: staffUser.providerId);
});
