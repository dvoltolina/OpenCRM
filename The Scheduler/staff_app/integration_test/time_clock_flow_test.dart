import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:drift/native.dart';

import 'package:staff_app/core/services/time_clock_service.dart';
import 'package:staff_app/data/local/staff_database.dart';
import 'package:staff_app/modules/time_clock/models/clock_state.dart';

/// Helper to create mock location service for integration tests.
import '../test/helpers/mock_location_service.dart';

/// Integration tests for the full clock in/out workflow.
///
/// These tests verify the complete workflow from clock in to clock out,
/// including breaks and queue processing.
///
/// Note: Tests requiring actual Firestore sync need Firebase emulator.
/// Run with: flutter test integration_test --dart-define=USE_EMULATOR=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late StaffDatabase db;
  late MockLocationService locationService;
  late TimeClockService timeClockService;

  const businessId = 'test-business-integration';
  const staffId = 'test-staff-integration';

  setUp(() async {
    // Create in-memory database for integration tests
    db = StaffDatabase.forTesting(NativeDatabase.memory());

    // Create mock location service
    locationService = MockLocationService();
    locationService.setMockLocation(37.7749, -122.4194, '123 Main St, SF');

    // Create time clock service
    timeClockService = TimeClockService(
      db: db,
      locationService: locationService,
      staffId: staffId,
      businessId: businessId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Clock In/Out Flow', () {
    testWidgets('full shift workflow completes successfully', (tester) async {
      // === CLOCK IN ===
      final clockInEntry = await timeClockService.clockIn();

      // Verify clock in state
      expect(clockInEntry.status, equals('active'));
      expect(clockInEntry.clockOutTime, isNull);
      expect(clockInEntry.clockInLatitude, equals(37.7749));
      expect(clockInEntry.clockInLongitude, equals(-122.4194));
      expect(clockInEntry.pendingSync, isTrue);

      // Verify sync queue has clock_in action
      final queueCount1 = await db.syncQueueDao.getQueueCount();
      expect(queueCount1, equals(1));

      // Verify clock state
      var clockState = await timeClockService.getClockState();
      expect(clockState.isClockedIn, isTrue);
      expect(clockState.isOnBreak, isFalse);

      // === TAKE MEAL BREAK ===
      await timeClockService.startBreak(BreakType.meal);

      // Verify break state
      clockState = await timeClockService.getClockState();
      expect(clockState.isClockedIn, isTrue);
      expect(clockState.isOnBreak, isTrue);
      expect(clockState.currentBreakType, equals('meal'));

      // Verify sync queue has start_break action
      final queueCount2 = await db.syncQueueDao.getQueueCount();
      expect(queueCount2, equals(2));

      // === END MEAL BREAK ===
      await timeClockService.endBreak();

      // Verify break ended
      clockState = await timeClockService.getClockState();
      expect(clockState.isClockedIn, isTrue);
      expect(clockState.isOnBreak, isFalse);
      expect(clockState.totalBreakMinutes, greaterThanOrEqualTo(0));

      // Verify sync queue has end_break action
      final queueCount3 = await db.syncQueueDao.getQueueCount();
      expect(queueCount3, equals(3));

      // === TAKE REST BREAK ===
      await timeClockService.startBreak(BreakType.rest);

      clockState = await timeClockService.getClockState();
      expect(clockState.isOnBreak, isTrue);
      expect(clockState.currentBreakType, equals('rest'));

      // === END REST BREAK ===
      await timeClockService.endBreak();

      clockState = await timeClockService.getClockState();
      expect(clockState.isOnBreak, isFalse);

      // === CLOCK OUT ===
      locationService.setMockLocation(37.7850, -122.4090, '456 Market St, SF');
      final clockOutEntry = await timeClockService.clockOut(notes: 'Full shift completed');

      // Verify clock out state
      expect(clockOutEntry.status, equals('pending'));
      expect(clockOutEntry.clockOutTime, isNotNull);
      expect(clockOutEntry.totalMinutes, isNotNull);
      expect(clockOutEntry.workedMinutes, isNotNull);
      expect(clockOutEntry.breakMinutes, isNotNull);
      expect(clockOutEntry.staffNotes, equals('Full shift completed'));
      expect(clockOutEntry.clockOutLatitude, equals(37.7850));

      // Verify final clock state
      clockState = await timeClockService.getClockState();
      expect(clockState.isClockedIn, isFalse);

      // Verify sync queue has all actions
      final finalQueueCount = await db.syncQueueDao.getQueueCount();
      expect(finalQueueCount, equals(6)); // clock_in, start_break x2, end_break x2, clock_out
    });

    testWidgets('handles multiple shifts in one day', (tester) async {
      // === FIRST SHIFT ===
      await timeClockService.clockIn();
      await timeClockService.clockOut(notes: 'Morning shift');

      var todayEntries = await timeClockService.getTodayEntries();
      expect(todayEntries.length, equals(1));

      // === SECOND SHIFT ===
      await timeClockService.clockIn();
      await timeClockService.startBreak(BreakType.meal);
      await timeClockService.endBreak();
      await timeClockService.clockOut(notes: 'Afternoon shift');

      todayEntries = await timeClockService.getTodayEntries();
      expect(todayEntries.length, equals(2));

      // Verify both entries have correct notes
      final notes = todayEntries.map((e) => e.staffNotes).toList();
      expect(notes, containsAll(['Morning shift', 'Afternoon shift']));
    });

    testWidgets('location unavailable does not block clock in', (tester) async {
      // Clear location to simulate unavailable GPS
      locationService.clearMockLocation();

      // Clock in should succeed without location
      final entry = await timeClockService.clockIn();

      expect(entry.status, equals('active'));
      expect(entry.clockInLatitude, isNull);
      expect(entry.clockInLongitude, isNull);
      expect(entry.clockInAddress, isNull);

      // Clock out should also succeed
      await timeClockService.clockOut();

      final clockState = await timeClockService.getClockState();
      expect(clockState.isClockedIn, isFalse);
    });
  });

  group('Error Handling', () {
    testWidgets('prevents double clock in', (tester) async {
      await timeClockService.clockIn();

      expect(
        () => timeClockService.clockIn(),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('prevents clock out when not clocked in', (tester) async {
      expect(
        () => timeClockService.clockOut(),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('prevents starting break when not clocked in', (tester) async {
      expect(
        () => timeClockService.startBreak(BreakType.meal),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('prevents ending break when not on break', (tester) async {
      await timeClockService.clockIn();

      expect(
        () => timeClockService.endBreak(),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('prevents clock out while on break', (tester) async {
      await timeClockService.clockIn();
      await timeClockService.startBreak(BreakType.meal);

      expect(
        () => timeClockService.clockOut(),
        throwsA(isA<Exception>()),
      );

      // End break first, then clock out
      await timeClockService.endBreak();
      await timeClockService.clockOut();
    });
  });

  group('Sync Queue Management', () {
    testWidgets('actions are queued in order', (tester) async {
      await timeClockService.clockIn();
      await timeClockService.startBreak(BreakType.meal);
      await timeClockService.endBreak();
      await timeClockService.clockOut();

      final queueItems = await db.syncQueueDao.getPendingItems();

      expect(queueItems.length, equals(4));
      expect(queueItems[0].action, equals('clock_in'));
      expect(queueItems[1].action, equals('start_break'));
      expect(queueItems[2].action, equals('end_break'));
      expect(queueItems[3].action, equals('clock_out'));
    });

    testWidgets('queue can be cleared', (tester) async {
      await timeClockService.clockIn();
      await timeClockService.clockOut();

      var count = await db.syncQueueDao.getQueueCount();
      expect(count, greaterThan(0));

      await db.syncQueueDao.clearAll();

      count = await db.syncQueueDao.getQueueCount();
      expect(count, equals(0));
    });
  });

  group('Data Persistence', () {
    testWidgets('entries persist after service recreation', (tester) async {
      // Create initial entry
      await timeClockService.clockIn();
      final initialEntry = await timeClockService.getActiveEntry();

      // Recreate service with same database
      final newService = TimeClockService(
        db: db,
        locationService: locationService,
        staffId: staffId,
        businessId: businessId,
      );

      // Verify entry is still accessible
      final recoveredEntry = await newService.getActiveEntry();

      expect(recoveredEntry, isNotNull);
      expect(recoveredEntry!.id, equals(initialEntry!.id));
      expect(recoveredEntry.clockInTime, equals(initialEntry.clockInTime));
    });
  });
}
