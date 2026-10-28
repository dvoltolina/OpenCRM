import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/services/time_clock_exceptions.dart';
import 'package:staff_app/core/services/time_clock_service.dart';
import 'package:staff_app/modules/time_clock/models/clock_state.dart';

import '../helpers/database_helper.dart';
import '../helpers/mock_location_service.dart';
import '../helpers/test_factories.dart';

void main() {
  late TestDatabaseHelper dbHelper;
  late MockLocationService mockLocationService;
  late TimeClockService service;

  setUp(() async {
    dbHelper = TestDatabaseHelper();
    mockLocationService = MockLocationService();

    // Set default mock location
    mockLocationService.setMockLocation(
      TestConstants.testLatitude,
      TestConstants.testLongitude,
      TestConstants.testAddress,
    );

    service = TimeClockService(
      db: dbHelper.db,
      locationService: mockLocationService,
      staffId: TestConstants.staffId,
      businessId: TestConstants.businessId,
    );
  });

  tearDown(() async {
    await dbHelper.dispose();
  });

  group('TimeClockService', () {
    group('clockIn', () {
      test('successfully creates a time entry when not clocked in', () async {
        // Act
        final entry = await service.clockIn();

        // Assert
        expect(entry.id, isNotEmpty);
        expect(entry.staffId, equals(TestConstants.staffId));
        expect(entry.businessId, equals(TestConstants.businessId));
        expect(entry.status, equals('active'));
        expect(entry.clockOutTime, isNull);
        expect(entry.clockInLatitude, equals(TestConstants.testLatitude));
        expect(entry.clockInLongitude, equals(TestConstants.testLongitude));
        expect(entry.clockInAddress, equals(TestConstants.testAddress));
        expect(entry.pendingSync, isTrue);
        expect(entry.syncAction, equals('clock_in'));
      });

      test('throws AlreadyClockedInException when already clocked in', () async {
        // Arrange
        await service.clockIn();

        // Act & Assert
        expect(
          () => service.clockIn(),
          throwsA(isA<AlreadyClockedInException>()),
        );
      });

      test('records location data when available', () async {
        // Arrange
        mockLocationService.setMockLocation(40.7128, -74.0060, 'New York');

        // Act
        final entry = await service.clockIn();

        // Assert
        expect(entry.clockInLatitude, equals(40.7128));
        expect(entry.clockInLongitude, equals(-74.0060));
        expect(entry.clockInAddress, equals('New York'));
      });

      test('succeeds without location when location unavailable', () async {
        // Arrange
        mockLocationService.clearMockLocation();

        // Act
        final entry = await service.clockIn();

        // Assert
        expect(entry.id, isNotEmpty);
        expect(entry.clockInLatitude, isNull);
        expect(entry.clockInLongitude, isNull);
        expect(entry.clockInAddress, isNull);
        expect(entry.status, equals('active'));
      });

      test('queues sync action on clock in', () async {
        // Act
        await service.clockIn();

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(1));
      });

      test('sets geofence flags correctly when inside business location', () async {
        // Arrange
        final businessLocations = [
          BusinessLocationFactory.createDefault(),
        ];

        final serviceWithGeofence = TimeClockService(
          db: dbHelper.db,
          locationService: mockLocationService,
          staffId: TestConstants.staffId,
          businessId: TestConstants.businessId,
          businessLocations: businessLocations,
        );

        // Act
        final entry = await serviceWithGeofence.clockIn();

        // Assert
        expect(entry.clockInLocationId, equals(TestConstants.locationId));
        expect(entry.clockInOutsideGeofence, isFalse);
      });

      test('sets geofence flags correctly when outside business location', () async {
        // Arrange
        mockLocationService.setMockLocation(0.0, 0.0, 'Far away');
        final businessLocations = [
          BusinessLocationFactory.createDefault(),
        ];

        final serviceWithGeofence = TimeClockService(
          db: dbHelper.db,
          locationService: mockLocationService,
          staffId: TestConstants.staffId,
          businessId: TestConstants.businessId,
          businessLocations: businessLocations,
        );

        // Act
        final entry = await serviceWithGeofence.clockIn();

        // Assert
        expect(entry.clockInLocationId, isNull);
        expect(entry.clockInOutsideGeofence, isTrue);
      });
    });

    group('clockOut', () {
      test('successfully clocks out when clocked in', () async {
        // Arrange
        await service.clockIn();

        // Act
        final entry = await service.clockOut();

        // Assert
        expect(entry.clockOutTime, isNotNull);
        expect(entry.status, equals('pending'));
        expect(entry.totalMinutes, isNotNull);
        expect(entry.workedMinutes, isNotNull);
        expect(entry.breakMinutes, equals(0));
      });

      test('throws NotClockedInException when not clocked in', () async {
        // Act & Assert
        expect(
          () => service.clockOut(),
          throwsA(isA<NotClockedInException>()),
        );
      });

      test('throws AlreadyOnBreakException when on break', () async {
        // Arrange
        await service.clockIn();
        await service.startBreak(BreakType.meal);

        // Act & Assert
        expect(
          () => service.clockOut(),
          throwsA(isA<AlreadyOnBreakException>()),
        );
      });

      test('calculates totals correctly', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'test-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'active',
        );

        final serviceWithExisting = TimeClockService(
          db: dbHelper.db,
          locationService: mockLocationService,
          staffId: TestConstants.staffId,
          businessId: TestConstants.businessId,
        );

        // Act
        final entry = await serviceWithExisting.clockOut();

        // Assert
        expect(entry.totalMinutes, greaterThanOrEqualTo(119)); // ~2 hours
        expect(entry.workedMinutes, equals(entry.totalMinutes)); // No breaks
        expect(entry.breakMinutes, equals(0));
      });

      test('includes notes when provided', () async {
        // Arrange
        await service.clockIn();
        const testNotes = 'Test shift notes';

        // Act
        final entry = await service.clockOut(notes: testNotes);

        // Assert
        expect(entry.staffNotes, equals(testNotes));
      });

      test('records location data on clock out', () async {
        // Arrange
        await service.clockIn();
        mockLocationService.setMockLocation(40.7128, -74.0060, 'Clock out location');

        // Act
        final entry = await service.clockOut();

        // Assert
        expect(entry.clockOutLatitude, equals(40.7128));
        expect(entry.clockOutLongitude, equals(-74.0060));
        expect(entry.clockOutAddress, equals('Clock out location'));
      });

      test('queues sync action on clock out', () async {
        // Arrange
        await service.clockIn();

        // Act
        await service.clockOut();

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(2)); // clock_in + clock_out
      });
    });

    group('startBreak', () {
      test('successfully starts a meal break when clocked in', () async {
        // Arrange
        await service.clockIn();

        // Act
        await service.startBreak(BreakType.meal);

        // Assert
        final state = await service.getClockState();
        expect(state.isOnBreak, isTrue);
        expect(state.currentBreakType, equals('meal'));
      });

      test('successfully starts a rest break when clocked in', () async {
        // Arrange
        await service.clockIn();

        // Act
        await service.startBreak(BreakType.rest);

        // Assert
        final state = await service.getClockState();
        expect(state.isOnBreak, isTrue);
        expect(state.currentBreakType, equals('rest'));
      });

      test('throws NotClockedInException when not clocked in', () async {
        // Act & Assert
        expect(
          () => service.startBreak(BreakType.meal),
          throwsA(isA<NotClockedInException>()),
        );
      });

      test('throws AlreadyOnBreakException when already on break', () async {
        // Arrange
        await service.clockIn();
        await service.startBreak(BreakType.meal);

        // Act & Assert
        expect(
          () => service.startBreak(BreakType.rest),
          throwsA(isA<AlreadyOnBreakException>()),
        );
      });

      test('queues sync action on start break', () async {
        // Arrange
        await service.clockIn();

        // Act
        await service.startBreak(BreakType.meal);

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(2)); // clock_in + start_break
      });
    });

    group('endBreak', () {
      test('successfully ends a break', () async {
        // Arrange
        await service.clockIn();
        await service.startBreak(BreakType.meal);

        // Act
        await service.endBreak();

        // Assert
        final state = await service.getClockState();
        expect(state.isOnBreak, isFalse);
        expect(state.isClockedIn, isTrue);
        expect(state.totalBreakMinutes, greaterThanOrEqualTo(0));
      });

      test('throws NotClockedInException when not clocked in', () async {
        // Act & Assert
        expect(
          () => service.endBreak(),
          throwsA(isA<NotClockedInException>()),
        );
      });

      test('throws NotOnBreakException when not on break', () async {
        // Arrange
        await service.clockIn();

        // Act & Assert
        expect(
          () => service.endBreak(),
          throwsA(isA<NotOnBreakException>()),
        );
      });

      test('queues sync action on end break', () async {
        // Arrange
        await service.clockIn();
        await service.startBreak(BreakType.meal);

        // Act
        await service.endBreak();

        // Assert
        final queueCount = await dbHelper.getSyncQueueCount();
        expect(queueCount, equals(3)); // clock_in + start_break + end_break
      });
    });

    group('getActiveEntry', () {
      test('returns null when not clocked in', () async {
        // Act
        final entry = await service.getActiveEntry();

        // Assert
        expect(entry, isNull);
      });

      test('returns entry when clocked in', () async {
        // Arrange
        await service.clockIn();

        // Act
        final entry = await service.getActiveEntry();

        // Assert
        expect(entry, isNotNull);
        expect(entry!.status, equals('active'));
      });
    });

    group('getClockState', () {
      test('returns not clocked in state when no active entry', () async {
        // Act
        final state = await service.getClockState();

        // Assert
        expect(state.isClockedIn, isFalse);
        expect(state.isOnBreak, isFalse);
        expect(state.activeEntryId, isNull);
      });

      test('returns clocked in state when active entry exists', () async {
        // Arrange
        final entry = await service.clockIn();

        // Act
        final state = await service.getClockState();

        // Assert
        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.activeEntryId, equals(entry.id));
        expect(state.clockInTime, isNotNull);
      });

      test('returns on break state when on break', () async {
        // Arrange
        await service.clockIn();
        await service.startBreak(BreakType.meal);

        // Act
        final state = await service.getClockState();

        // Assert
        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isTrue);
        expect(state.currentBreakType, equals('meal'));
        expect(state.currentBreakStart, isNotNull);
      });
    });

    group('getTodayEntries', () {
      test('returns empty list when no entries', () async {
        // Act
        final entries = await service.getTodayEntries();

        // Assert
        expect(entries, isEmpty);
      });

      test('returns today entries', () async {
        // Arrange
        await service.clockIn();
        await service.clockOut();
        await service.clockIn();

        // Act
        final entries = await service.getTodayEntries();

        // Assert
        expect(entries.length, equals(2));
      });

      test('excludes entries from other days', () async {
        // Arrange - insert an entry from yesterday
        await dbHelper.insertTimeEntry(
          id: 'yesterday-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(days: 1)),
          clockOutTime: DateTime.now().subtract(const Duration(days: 1)),
          status: 'pending',
        );

        // Act
        final entries = await service.getTodayEntries();

        // Assert
        expect(entries, isEmpty);
      });
    });

    group('updateNotes', () {
      test('updates notes on an entry', () async {
        // Arrange
        final entry = await service.clockIn();
        const newNotes = 'Updated notes';

        // Act
        await service.updateNotes(entry.id, newNotes);

        // Assert
        final updated = await dbHelper.db.timeEntriesDao.getTimeEntryById(entry.id);
        expect(updated?.staffNotes, equals(newNotes));
      });

      test('throws TimeEntryNotFoundException for non-existent entry', () async {
        // Act & Assert
        expect(
          () => service.updateNotes('non-existent-id', 'notes'),
          throwsA(isA<TimeEntryNotFoundException>()),
        );
      });

      test('throws TimeEntryAlreadyApprovedException for approved entry', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'approved-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(hours: 2)),
          clockOutTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'approved',
        );

        // Act & Assert
        expect(
          () => service.updateNotes('approved-entry', 'new notes'),
          throwsA(isA<TimeEntryAlreadyApprovedException>()),
        );
      });
    });

    group('getEntriesInRange', () {
      test('returns entries within date range', () async {
        // Arrange
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        await dbHelper.insertTimeEntry(
          id: 'entry-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: now,
          status: 'pending',
        );

        // Act
        final entries = await service.getEntriesInRange(yesterday, tomorrow);

        // Assert
        expect(entries.length, equals(1));
        expect(entries.first.id, equals('entry-1'));
      });

      test('excludes entries outside date range', () async {
        // Arrange
        await dbHelper.insertTimeEntry(
          id: 'old-entry',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clockInTime: DateTime.now().subtract(const Duration(days: 10)),
          status: 'pending',
        );

        // Act
        final now = DateTime.now();
        final entries = await service.getEntriesInRange(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        // Assert
        expect(entries, isEmpty);
      });
    });

    group('full workflow', () {
      test('complete shift with breaks calculates correctly', () async {
        // Clock in
        await service.clockIn();

        // Start and end a meal break
        await service.startBreak(BreakType.meal);
        await service.endBreak();

        // Start and end a rest break
        await service.startBreak(BreakType.rest);
        await service.endBreak();

        // Verify state before clock out
        final stateBeforeClockOut = await service.getClockState();
        expect(stateBeforeClockOut.isClockedIn, isTrue);
        expect(stateBeforeClockOut.isOnBreak, isFalse);

        // Clock out
        final entry = await service.clockOut(notes: 'Full shift completed');

        // Verify final state
        expect(entry.status, equals('pending'));
        expect(entry.staffNotes, equals('Full shift completed'));
        expect(entry.clockOutTime, isNotNull);
        expect(entry.totalMinutes, isNotNull);
        expect(entry.workedMinutes, isNotNull);
      });
    });
  });
}
