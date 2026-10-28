import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:staff_app/data/local/staff_database.dart';

/// Creates an in-memory database for testing.
///
/// Each call returns a fresh database instance.
/// The database is automatically destroyed when [dispose] is called.
///
/// ## Usage
/// ```dart
/// late StaffDatabase db;
///
/// setUp(() {
///   db = createTestDatabase();
/// });
///
/// tearDown(() {
///   db.close();
/// });
/// ```
StaffDatabase createTestDatabase() {
  return StaffDatabase.forTesting(
    NativeDatabase.memory(),
  );
}

/// Helper class for managing test database lifecycle.
class TestDatabaseHelper {
  TestDatabaseHelper() : db = createTestDatabase();

  final StaffDatabase db;

  /// Clears all data from the database.
  Future<void> clearAll() async {
    await db.clearAllData();
  }

  /// Closes the database connection.
  Future<void> dispose() async {
    await db.close();
  }

  /// Inserts a time entry into the database.
  Future<void> insertTimeEntry({
    required String id,
    required String businessId,
    required String staffId,
    required DateTime clockInTime,
    DateTime? clockOutTime,
    double? clockInLatitude,
    double? clockInLongitude,
    String? clockInAddress,
    String breaksJson = '[]',
    int? totalMinutes,
    int? breakMinutes,
    int? workedMinutes,
    String status = 'active',
    bool pendingSync = false,
    String? syncAction,
  }) async {
    await db.timeEntriesDao.insertTimeEntry(
      TimeEntriesTableCompanion.insert(
        id: id,
        businessId: businessId,
        staffId: staffId,
        clockInTime: clockInTime,
        clockOutTime: Value(clockOutTime),
        clockInLatitude: Value(clockInLatitude),
        clockInLongitude: Value(clockInLongitude),
        clockInAddress: Value(clockInAddress),
        breaksJson: Value(breaksJson),
        totalMinutes: Value(totalMinutes),
        breakMinutes: Value(breakMinutes),
        workedMinutes: Value(workedMinutes),
        status: status,
        createdAt: DateTime.now(),
        pendingSync: Value(pendingSync),
        syncAction: Value(syncAction),
      ),
    );
  }

  /// Inserts an appointment into the database.
  Future<void> insertAppointment({
    required String id,
    required String businessId,
    required String staffId,
    required String clientId,
    required String serviceId,
    required String locationId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
    String? serviceName,
    int? serviceDurationMinutes,
    String? locationName,
    String? notes,
    String? staffNotes,
    bool requiresPayment = false,
    String? paymentStatus,
    DateTime? checkedInAt,
    String? checkedInByStaffId,
    DateTime? completedAt,
    String? completedByStaffId,
    bool pendingSync = false,
    String? syncAction,
  }) async {
    await db.appointmentsDao.upsertAppointments([
      AppointmentsTableCompanion.insert(
        id: id,
        businessId: businessId,
        staffId: Value(staffId),
        clientId: clientId,
        serviceId: serviceId,
        locationId: locationId,
        startTime: startTime,
        endTime: endTime,
        status: status,
        clientName: Value(clientName),
        clientPhone: Value(clientPhone),
        clientEmail: Value(clientEmail),
        clientAddress: Value(clientAddress),
        serviceName: Value(serviceName),
        serviceDurationMinutes: Value(serviceDurationMinutes),
        locationName: Value(locationName),
        notes: Value(notes),
        staffNotes: Value(staffNotes),
        requiresPayment: Value(requiresPayment),
        paymentStatus: Value(paymentStatus),
        checkedInAt: Value(checkedInAt),
        checkedInByStaffId: Value(checkedInByStaffId),
        completedAt: Value(completedAt),
        completedByStaffId: Value(completedByStaffId),
        pendingSync: Value(pendingSync),
        syncAction: Value(syncAction),
      ),
    ]);
  }

  /// Inserts a client into the database.
  Future<void> insertClient({
    required String id,
    required String businessId,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? notes,
  }) async {
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.clientsTable, [
        ClientsTableCompanion.insert(
          id: id,
          businessId: businessId,
          name: name,
          email: Value(email),
          phone: Value(phone),
          address: Value(address),
          notes: Value(notes),
          lastSyncedAt: DateTime.now(),
        ),
      ]);
    });
  }

  /// Adds an item to the sync queue.
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String action,
    String payload = '{}',
    int retryCount = 0,
  }) async {
    await db.syncQueueDao.addToQueue(
      SyncQueueTableCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        action: action,
        payload: payload,
        createdAt: DateTime.now(),
        retryCount: Value(retryCount),
      ),
    );
  }

  /// Gets the count of items in the sync queue.
  Future<int> getSyncQueueCount() async {
    return db.syncQueueDao.getQueueCount();
  }
}
