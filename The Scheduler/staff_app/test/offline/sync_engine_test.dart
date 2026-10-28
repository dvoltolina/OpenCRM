import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/offline/sync_engine.dart';

import '../helpers/database_helper.dart';
import '../helpers/test_factories.dart';

/// Tests for SyncEngine.
///
/// Note: Full integration tests with Firestore require Firebase emulator.
/// These unit tests focus on local database operations and state management.
void main() {
  late TestDatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = TestDatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.dispose();
  });

  group('SyncEngine', () {
    group('SyncEngineStatus', () {
      test('has all expected status values', () {
        // Verify all status enum values exist
        expect(SyncEngineStatus.values, contains(SyncEngineStatus.uninitialized));
        expect(SyncEngineStatus.values, contains(SyncEngineStatus.idle));
        expect(SyncEngineStatus.values, contains(SyncEngineStatus.syncing));
        expect(SyncEngineStatus.values, contains(SyncEngineStatus.error));
        expect(SyncEngineStatus.values, contains(SyncEngineStatus.offline));
      });
    });

    group('Sync Queue Operations', () {
      test('queue items are added correctly', () async {
        // Arrange & Act
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_in',
          payload: '{"clockInTime": "2024-01-01T09:00:00Z"}',
        );

        // Assert
        final count = await dbHelper.getSyncQueueCount();
        expect(count, equals(1));
      });

      test('multiple queue items are tracked', () async {
        // Arrange & Act
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_in',
        );
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'start_break',
        );
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'end_break',
        );

        // Assert
        final count = await dbHelper.getSyncQueueCount();
        expect(count, equals(3));
      });

      test('queue can be cleared', () async {
        // Arrange
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_in',
        );
        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_out',
        );

        // Act
        await dbHelper.clearAll();

        // Assert
        final count = await dbHelper.getSyncQueueCount();
        expect(count, equals(0));
      });

      test('retry count is tracked', () async {
        // Arrange
        await dbHelper.addToSyncQueue(
          entityType: 'appointment',
          entityId: 'apt-1',
          action: 'check_in',
          retryCount: 3,
        );

        // Assert
        final items = await dbHelper.db.syncQueueDao.getPendingItems();
        expect(items.length, equals(1));
        expect(items.first.retryCount, equals(3));
      });
    });

    group('Time Entry Sync Queue Integration', () {
      test('clock in creates sync queue entry', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now(),
          status: 'active',
          pendingSync: true,
          syncAction: 'clock_in',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_in',
        );

        // Assert
        final pendingEntries = await dbHelper.db.timeEntriesDao.getPendingSyncEntries();
        expect(pendingEntries.length, equals(1));
        expect(pendingEntries.first.syncAction, equals('clock_in'));

        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(1));
      });

      test('clock out creates sync queue entry', () async {
        // Arrange
        final clockIn = DateTime.now().subtract(const Duration(hours: 8));
        final clockOut = DateTime.now();

        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: clockIn,
          clockOutTime: clockOut,
          totalMinutes: 480,
          breakMinutes: 30,
          workedMinutes: 450,
          status: 'pending',
          pendingSync: true,
          syncAction: 'clock_out',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_out',
        );

        // Assert
        final pendingEntries = await dbHelper.db.timeEntriesDao.getPendingSyncEntries();
        expect(pendingEntries.length, equals(1));
        expect(pendingEntries.first.syncAction, equals('clock_out'));
      });

      test('break actions create sync queue entries', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(hours: 2)),
          breaksJson: TimeEntryFactory.createBreaksJsonWithActiveBreak(),
          status: 'active',
          pendingSync: true,
          syncAction: 'start_break',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'start_break',
        );

        // Assert
        final pendingEntries = await dbHelper.db.timeEntriesDao.getPendingSyncEntries();
        expect(pendingEntries.length, equals(1));
        expect(pendingEntries.first.syncAction, equals('start_break'));
      });
    });

    group('Appointment Sync Queue Integration', () {
      test('appointment check-in creates sync queue entry', () async {
        // Arrange
        await dbHelper.insertAppointment(
          id: 'apt-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
          checkedInAt: DateTime.now(),
          pendingSync: true,
          syncAction: 'check_in',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'appointment',
          entityId: 'apt-1',
          action: 'check_in',
        );

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(1));
      });

      test('appointment completion creates sync queue entry', () async {
        // Arrange
        await dbHelper.insertAppointment(
          id: 'apt-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          status: 'completed',
          completedAt: DateTime.now(),
          pendingSync: true,
          syncAction: 'complete',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'appointment',
          entityId: 'apt-1',
          action: 'complete',
        );

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(1));
      });
    });

    group('Database Consistency', () {
      test('pending sync entries are queryable', () async {
        // Arrange - insert entries with different sync states
        await dbHelper.insertTimeEntry(
          id: 'entry-synced',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(hours: 4)),
          clockOutTime: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'approved',
          pendingSync: false,
        );

        await dbHelper.insertTimeEntry(
          id: 'entry-pending',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now(),
          status: 'active',
          pendingSync: true,
          syncAction: 'clock_in',
        );

        // Act
        final pendingEntries = await dbHelper.db.timeEntriesDao.getPendingSyncEntries();

        // Assert
        expect(pendingEntries.length, equals(1));
        expect(pendingEntries.first.id, equals('entry-pending'));
      });

      test('clearing pending sync updates entry', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now(),
          status: 'active',
          pendingSync: true,
          syncAction: 'clock_in',
        );

        // Act
        await dbHelper.db.timeEntriesDao.clearPendingSync('entry-1');

        // Assert
        final entry = await dbHelper.db.timeEntriesDao.getTimeEntryById('entry-1');
        expect(entry?.pendingSync, isFalse);
        expect(entry?.syncAction, isNull);
        expect(entry?.lastSyncedAt, isNotNull);
      });
    });

    group('Data Retention', () {
      test('old entries can be deleted', () async {
        // Arrange
        final oldDate = DateTime.now().subtract(const Duration(days: 100));
        final recentDate = DateTime.now().subtract(const Duration(days: 5));

        await dbHelper.insertTimeEntry(
          id: 'old-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: oldDate,
          clockOutTime: oldDate.add(const Duration(hours: 8)),
          status: 'approved',
          pendingSync: false,
        );

        await dbHelper.insertTimeEntry(
          id: 'recent-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: recentDate,
          clockOutTime: recentDate.add(const Duration(hours: 8)),
          status: 'approved',
          pendingSync: false,
        );

        // Act
        final deletedCount = await dbHelper.db.timeEntriesDao.deleteOldEntries(30);

        // Assert
        expect(deletedCount, equals(1));

        final remaining = await dbHelper.db.timeEntriesDao.getEntriesInRange(
          TestConstants.staffId,
          DateTime.now().subtract(const Duration(days: 200)),
          DateTime.now(),
        );
        expect(remaining.length, equals(1));
        expect(remaining.first.id, equals('recent-entry'));
      });

      test('pending sync entries are not deleted even if old', () async {
        // Arrange
        final oldDate = DateTime.now().subtract(const Duration(days: 100));

        await dbHelper.insertTimeEntry(
          id: 'old-pending-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: oldDate,
          clockOutTime: oldDate.add(const Duration(hours: 8)),
          status: 'pending',
          pendingSync: true, // This should prevent deletion
          syncAction: 'clock_out',
        );

        // Act
        final deletedCount = await dbHelper.db.timeEntriesDao.deleteOldEntries(30);

        // Assert
        expect(deletedCount, equals(0));
      });
    });

    group('Record Counts', () {
      test('getRecordCounts returns correct counts', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now(),
          status: 'active',
        );

        await dbHelper.insertAppointment(
          id: 'apt-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
        );

        await dbHelper.insertClient(
          id: 'client-1',
          businessId: TestConstants.businessId,
          name: 'Test Client',
        );

        await dbHelper.addToSyncQueue(
          entityType: 'time_entry',
          entityId: 'entry-1',
          action: 'clock_in',
        );

        // Act
        final counts = await dbHelper.db.getRecordCounts();

        // Assert
        expect(counts['timeEntries'], equals(1));
        expect(counts['appointments'], equals(1));
        expect(counts['clients'], equals(1));
        expect(counts['syncQueue'], equals(1));
      });
    });
  });
}
