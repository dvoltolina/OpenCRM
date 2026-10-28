import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/modules/time_clock/models/clock_state.dart';

import '../helpers/test_factories.dart';

void main() {
  group('ClockState', () {
    group('ClockState.notClockedIn', () {
      test('creates state with all defaults', () {
        const state = ClockState.notClockedIn();

        expect(state.isClockedIn, isFalse);
        expect(state.isOnBreak, isFalse);
        expect(state.clockInTime, isNull);
        expect(state.currentBreakStart, isNull);
        expect(state.currentBreakType, isNull);
        expect(state.activeEntryId, isNull);
        expect(state.totalBreakMinutes, equals(0));
      });
    });

    group('ClockState.fromEntry', () {
      test('returns notClockedIn when entry is null', () {
        final state = ClockState.fromEntry(null);

        expect(state.isClockedIn, isFalse);
        expect(state.isOnBreak, isFalse);
      });

      test('creates clocked in state from valid entry', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 1));
        final entry = MockTimeEntry(
          id: 'entry-1',
          clockInTime: clockInTime,
        );

        final state = ClockState.fromEntry(entry);

        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.clockInTime, equals(clockInTime));
        expect(state.activeEntryId, equals('entry-1'));
      });

      test('detects active break', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 2));
        final entry = MockTimeEntry(
          id: 'entry-1',
          clockInTime: clockInTime,
          breaksJson: TimeEntryFactory.createBreaksJsonWithActiveBreak(
            type: 'meal',
          ),
        );

        final state = ClockState.fromEntry(entry);

        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isTrue);
        expect(state.currentBreakType, equals('meal'));
        expect(state.currentBreakStart, isNotNull);
      });

      test('calculates total break minutes from completed breaks', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 4));
        final breakStart = clockInTime.add(const Duration(hours: 1));
        final breakEnd = breakStart.add(const Duration(minutes: 30));

        final entry = MockTimeEntry(
          id: 'entry-1',
          clockInTime: clockInTime,
          breaksJson: TimeEntryFactory.createBreaksJsonWithCompletedBreak(
            startTime: breakStart,
            endTime: breakEnd,
          ),
        );

        final state = ClockState.fromEntry(entry);

        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.totalBreakMinutes, equals(30));
      });

      test('handles multiple breaks', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 6));
        final breaks = [
          (
            start: clockInTime.add(const Duration(hours: 2)),
            end: clockInTime.add(const Duration(hours: 2, minutes: 15)),
            type: 'rest',
          ),
          (
            start: clockInTime.add(const Duration(hours: 4)),
            end: clockInTime.add(const Duration(hours: 4, minutes: 30)),
            type: 'meal',
          ),
        ];

        final entry = MockTimeEntry(
          id: 'entry-1',
          clockInTime: clockInTime,
          breaksJson: TimeEntryFactory.createBreaksJsonWithMultiple(breaks: breaks),
        );

        final state = ClockState.fromEntry(entry);

        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.totalBreakMinutes, equals(45)); // 15 + 30 = 45
      });

      test('handles malformed breaks JSON gracefully', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 1));
        final entry = MockTimeEntry(
          id: 'entry-1',
          clockInTime: clockInTime,
          breaksJson: 'invalid json',
        );

        final state = ClockState.fromEntry(entry);

        expect(state.isClockedIn, isTrue);
        expect(state.isOnBreak, isFalse);
        expect(state.totalBreakMinutes, equals(0));
      });
    });

    group('computed properties', () {
      test('elapsedDuration returns zero when not clocked in', () {
        const state = ClockState.notClockedIn();
        expect(state.elapsedDuration, equals(Duration.zero));
      });

      test('elapsedDuration calculates correctly when clocked in', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 2, minutes: 30));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
        );

        // Allow some tolerance for test execution time
        expect(state.elapsedDuration.inMinutes, greaterThanOrEqualTo(149));
        expect(state.elapsedDuration.inMinutes, lessThanOrEqualTo(151));
      });

      test('currentBreakDuration returns zero when not on break', () {
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: DateTime.now(),
          activeEntryId: 'entry-1',
        );

        expect(state.currentBreakDuration, equals(Duration.zero));
      });

      test('currentBreakDuration calculates correctly when on break', () {
        final breakStart = DateTime.now().subtract(const Duration(minutes: 15));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: true,
          clockInTime: DateTime.now().subtract(const Duration(hours: 2)),
          currentBreakStart: breakStart,
          currentBreakType: 'meal',
          activeEntryId: 'entry-1',
        );

        // Allow some tolerance
        expect(state.currentBreakDuration.inMinutes, greaterThanOrEqualTo(14));
        expect(state.currentBreakDuration.inMinutes, lessThanOrEqualTo(16));
      });

      test('elapsedHours returns correct decimal', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 2, minutes: 30));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
        );

        expect(state.elapsedHours, closeTo(2.5, 0.1));
      });

      test('workedDuration subtracts breaks', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 4));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
          totalBreakMinutes: 30,
        );

        // 4 hours - 30 min breaks = 3.5 hours
        expect(state.workedDuration.inMinutes, closeTo(210, 5));
      });
    });

    group('formatting methods', () {
      test('elapsedFormatted returns HH:MM:SS format', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 1, minutes: 30, seconds: 45));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
        );

        expect(state.elapsedFormatted, matches(RegExp(r'01:30:\d{2}')));
      });

      test('workedFormatted returns HH:MM:SS format', () {
        final clockInTime = DateTime.now().subtract(const Duration(hours: 2));
        final state = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
          totalBreakMinutes: 30,
        );

        expect(state.workedFormatted, matches(RegExp(r'01:30:\d{2}')));
      });
    });

    group('equality', () {
      test('two identical states are equal', () {
        final clockInTime = DateTime(2024, 1, 1, 9, 0);

        final state1 = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
        );

        final state2 = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: clockInTime,
          activeEntryId: 'entry-1',
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('different states are not equal', () {
        final state1 = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: DateTime.now(),
          activeEntryId: 'entry-1',
        );

        const state2 = ClockState.notClockedIn();

        expect(state1, isNot(equals(state2)));
      });
    });

    group('toString', () {
      test('includes clocked status', () {
        const state = ClockState.notClockedIn();
        expect(state.toString(), contains('clocked=out'));

        final clockedIn = ClockState(
          isClockedIn: true,
          isOnBreak: false,
          clockInTime: DateTime.now(),
          activeEntryId: 'entry-1',
        );
        expect(clockedIn.toString(), contains('clocked=in'));
      });

      test('includes break status', () {
        final onBreak = ClockState(
          isClockedIn: true,
          isOnBreak: true,
          clockInTime: DateTime.now(),
          currentBreakStart: DateTime.now(),
          currentBreakType: 'meal',
          activeEntryId: 'entry-1',
        );
        expect(onBreak.toString(), contains('break=true'));
      });
    });
  });

  group('BreakType', () {
    test('meal has correct value', () {
      expect(BreakType.meal.value, equals('meal'));
      expect(BreakType.meal.displayName, equals('Meal Break'));
    });

    test('rest has correct value', () {
      expect(BreakType.rest.value, equals('rest'));
      expect(BreakType.rest.displayName, equals('Rest Break'));
    });
  });

  group('breakTypeFromString', () {
    test('parses meal correctly', () {
      expect(breakTypeFromString('meal'), equals(BreakType.meal));
    });

    test('parses rest correctly', () {
      expect(breakTypeFromString('rest'), equals(BreakType.rest));
    });

    test('returns null for unknown value', () {
      expect(breakTypeFromString('unknown'), isNull);
      expect(breakTypeFromString(null), isNull);
    });
  });
}
