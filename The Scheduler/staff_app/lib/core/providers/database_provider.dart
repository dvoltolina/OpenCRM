import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/staff_database.dart';

/// Provider for the local SQLite database instance.
///
/// This is overridden in main.dart with the actual database instance
/// after initialization. Use this provider to access the database
/// throughout the app.
///
/// Example:
/// ```dart
/// final db = ref.read(databaseProvider);
/// final appointments = await db.appointmentsDao.getTodayAppointments(staffId);
/// ```
final databaseProvider = Provider<StaffDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope with '
    'an initialized StaffDatabase instance.',
  );
});
