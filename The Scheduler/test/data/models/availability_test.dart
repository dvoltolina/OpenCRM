import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/availability.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Availability Models', () {
    group('TimeBlock', () {
      test('creates time block from hour/minute values', () {
        final block = TimeBlock(
          startHour: 9,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
        );

        expect(block.startHour, 9);
        expect(block.startMinute, 0);
        expect(block.endHour, 17);
        expect(block.endMinute, 0);
      });

      test('creates time block from strings', () {
        final block = TimeBlock.fromStrings('09:30', '17:45');

        expect(block.startHour, 9);
        expect(block.startMinute, 30);
        expect(block.endHour, 17);
        expect(block.endMinute, 45);
      });

      test('displayTime formats correctly', () {
        final morningBlock = TimeBlock.fromStrings('09:00', '12:00');
        final afternoonBlock = TimeBlock.fromStrings('14:30', '18:45');

        expect(morningBlock.displayTime, '9:00 AM - 12:00 PM');
        expect(afternoonBlock.displayTime, '2:30 PM - 6:45 PM');
      });

      test('durationMinutes calculates correctly', () {
        final oneHour = TimeBlock.fromStrings('09:00', '10:00');
        final twoHours = TimeBlock.fromStrings('09:00', '11:00');
        final halfHour = TimeBlock.fromStrings('09:00', '09:30');
        final fullDay = TimeBlock.fromStrings('08:00', '17:00');

        expect(oneHour.durationMinutes, 60);
        expect(twoHours.durationMinutes, 120);
        expect(halfHour.durationMinutes, 30);
        expect(fullDay.durationMinutes, 540); // 9 hours = 540 minutes
      });

      test('converts to DateTime for specific date', () {
        final block = TimeBlock.fromStrings('14:30', '16:00');
        final date = DateTime(2025, 12, 1);

        final start = block.toStartDateTime(date);
        final end = block.toEndDateTime(date);

        expect(start.year, 2025);
        expect(start.month, 12);
        expect(start.day, 1);
        expect(start.hour, 14);
        expect(start.minute, 30);

        expect(end.hour, 16);
        expect(end.minute, 0);
      });

      test('handles midnight and noon', () {
        final midnight = TimeBlock.fromStrings('00:00', '01:00');
        final noon = TimeBlock.fromStrings('12:00', '13:00');

        expect(midnight.startHour, 0);
        expect(noon.startHour, 12);
      });

      test('test data factory creates valid blocks', () {
        final block = TestData.timeBlock();

        expect(block.startHour, greaterThanOrEqualTo(0));
        expect(block.startHour, lessThan(24));
        expect(block.endHour, greaterThanOrEqualTo(0));
        expect(block.endHour, lessThan(24));
      });
    });

    group('DayOfWeek enum', () {
      test('has all seven days', () {
        expect(DayOfWeek.values.length, 7);
        expect(DayOfWeek.values, [
          DayOfWeek.monday,
          DayOfWeek.tuesday,
          DayOfWeek.wednesday,
          DayOfWeek.thursday,
          DayOfWeek.friday,
          DayOfWeek.saturday,
          DayOfWeek.sunday,
        ]);
      });

      test('fromDateTime maps correctly', () {
        // Monday = 1, Sunday = 7 in DateTime
        final monday = DateTime(2025, 12, 1); // Known Monday
        final tuesday = DateTime(2025, 12, 2);
        final sunday = DateTime(2025, 12, 7);

        expect(DayOfWeek.fromDateTime(monday), DayOfWeek.monday);
        expect(DayOfWeek.fromDateTime(tuesday), DayOfWeek.tuesday);
        expect(DayOfWeek.fromDateTime(sunday), DayOfWeek.sunday);
      });

      test('weekdayValue returns correct index', () {
        expect(DayOfWeek.monday.weekdayValue, 1);
        expect(DayOfWeek.tuesday.weekdayValue, 2);
        expect(DayOfWeek.wednesday.weekdayValue, 3);
        expect(DayOfWeek.thursday.weekdayValue, 4);
        expect(DayOfWeek.friday.weekdayValue, 5);
        expect(DayOfWeek.saturday.weekdayValue, 6);
        expect(DayOfWeek.sunday.weekdayValue, 7);
      });

      test('displayName returns formatted name', () {
        expect(DayOfWeek.monday.displayName, 'Monday');
        expect(DayOfWeek.friday.displayName, 'Friday');
        expect(DayOfWeek.sunday.displayName, 'Sunday');
      });
    });

    group('AvailabilityType enum', () {
      test('has all expected types', () {
        expect(AvailabilityType.values, [
          AvailabilityType.available,
          AvailabilityType.blocked,
          AvailabilityType.override,
        ]);
      });

      test('serializes to strings correctly', () {
        final available = TestData.availability(type: AvailabilityType.available);
        final blocked = TestData.availability(type: AvailabilityType.blocked);
        final override = TestData.availability(type: AvailabilityType.override);

        final availableJson = available.toJson();
        final blockedJson = blocked.toJson();
        final overrideJson = override.toJson();

        expect(availableJson['type'], 'available');
        expect(blockedJson['type'], 'blocked');
        expect(overrideJson['type'], 'override');
      });
    });

    group('WeeklySchedule Model', () {
      test('creates weekly schedule from JSON', () {
        final json = {
          'id': 'schedule-123',
          'providerId': 'provider-456',
          'locationId': 'location-789',
          'dayOfWeek': 'monday',
          'timeBlocks': [
            {
              'startHour': 9,
              'startMinute': 0,
              'endHour': 17,
              'endMinute': 0,
            }
          ],
          'isActive': true,
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final schedule = WeeklySchedule.fromJson(json);

        expect(schedule.id, 'schedule-123');
        expect(schedule.providerId, 'provider-456');
        expect(schedule.locationId, 'location-789');
        expect(schedule.dayOfWeek, DayOfWeek.monday);
        expect(schedule.timeBlocks.length, 1);
        expect(schedule.isActive, true);
      });

      test('can have multiple time blocks per day', () {
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock.fromStrings('08:00', '12:00'), // Morning shift
            TimeBlock.fromStrings('13:00', '17:00'), // Afternoon shift
          ],
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(schedule.timeBlocks.length, 2);
        expect(schedule.timeBlocks[0].durationMinutes, 240); // 4 hours
        expect(schedule.timeBlocks[1].durationMinutes, 240); // 4 hours
      });

      test('can be marked inactive', () {
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.friday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: false, // Provider not working Fridays anymore
          createdAt: DateTime.now(),
        );

        expect(schedule.isActive, false);
      });

      test('test data factory creates valid schedule', () {
        final schedule = TestData.weeklySchedule();

        expect(schedule.id, isNotEmpty);
        expect(schedule.providerId, isNotEmpty);
        expect(schedule.locationId, isNotEmpty);
        expect(schedule.timeBlocks, isNotEmpty);
        expect(schedule.isActive, true);
      });
    });

    group('Availability Model', () {
      test('creates availability from JSON', () {
        final json = {
          'id': 'avail-123',
          'providerId': 'provider-456',
          'locationId': 'location-789',
          'startTime': '2025-12-25T00:00:00.000Z',
          'endTime': '2025-12-25T23:59:00.000Z',
          'type': 'blocked',
          'reason': 'Christmas Day',
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final availability = Availability.fromJson(json);

        expect(availability.id, 'avail-123');
        expect(availability.providerId, 'provider-456');
        expect(availability.type, AvailabilityType.blocked);
        expect(availability.reason, 'Christmas Day');
      });

      test('oneTime factory creates one-time availability', () {
        final vacation = Availability.oneTime(
          id: 'availability-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 25, 0, 0),
          endTime: DateTime(2025, 12, 25, 23, 59),
          type: AvailabilityType.blocked,
          reason: 'Christmas Holiday',
        );

        expect(vacation.type, AvailabilityType.blocked);
        expect(vacation.reason, 'Christmas Holiday');
        expect(vacation.startTime.day, 25);
        expect(vacation.endTime.day, 25);
      });

      test('blocked factory creates blocked time', () {
        final blocked = Availability.blocked(
          id: 'availability-2',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 9, 0),
          endTime: DateTime(2025, 12, 1, 10, 0),
          reason: 'Staff Meeting',
        );

        expect(blocked.type, AvailabilityType.blocked);
        expect(blocked.reason, 'Staff Meeting');
        expect(blocked.durationMinutes, 60);
      });

      test('isOnDate helper works correctly', () {
        final availability = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 15, 9, 0),
          endTime: DateTime(2025, 12, 15, 17, 0),
          type: AvailabilityType.available,
          createdAt: DateTime.now(),
        );

        expect(availability.isOnDate(DateTime(2025, 12, 15)), true);
        expect(availability.isOnDate(DateTime(2025, 12, 14)), false);
        expect(availability.isOnDate(DateTime(2025, 12, 16)), false);
      });

      test('durationMinutes calculates correctly', () {
        final oneHour = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 10, 0),
          endTime: DateTime(2025, 12, 1, 11, 0),
          type: AvailabilityType.available,
          createdAt: DateTime.now(),
        );

        expect(oneHour.durationMinutes, 60);
      });

      test('timeDisplay formats time range', () {
        final availability = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 9, 30),
          endTime: DateTime(2025, 12, 1, 14, 45),
          type: AvailabilityType.available,
          createdAt: DateTime.now(),
        );

        expect(availability.timeDisplay, contains('9:30 AM'));
        expect(availability.timeDisplay, contains('2:45 PM'));
      });
    });

    group('Real-World Scheduling Scenarios', () {
      test('standard office hours (9-5 weekdays)', () {
        final weekdaySchedules = [
          DayOfWeek.monday,
          DayOfWeek.tuesday,
          DayOfWeek.wednesday,
          DayOfWeek.thursday,
          DayOfWeek.friday,
        ].map((day) => WeeklySchedule(
              id: 'schedule-$day',
              providerId: 'provider-1',
              locationId: 'location-1',
              dayOfWeek: day,
              timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
              isActive: true,
              createdAt: DateTime.now(),
            )).toList();

        expect(weekdaySchedules.length, 5);
        expect(weekdaySchedules.every((s) => s.isActive), true);
      });

      test('split shift schedule', () {
        final splitShift = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock.fromStrings('07:00', '11:00'), // Morning
            TimeBlock.fromStrings('15:00', '19:00'), // Evening
          ],
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(splitShift.timeBlocks.length, 2);
      });

      test('vacation block (multi-day)', () {
        final vacationDays = [
          DateTime(2025, 12, 22),
          DateTime(2025, 12, 23),
          DateTime(2025, 12, 24),
          DateTime(2025, 12, 25),
          DateTime(2025, 12, 26),
        ];

        final vacationBlocks = vacationDays
            .asMap()
            .entries
            .map((entry) => Availability.oneTime(
                  id: 'vacation-${entry.key}',
                  providerId: 'provider-1',
                  locationId: 'location-1',
                  startTime: DateTime(entry.value.year, entry.value.month, entry.value.day, 0, 0),
                  endTime: DateTime(entry.value.year, entry.value.month, entry.value.day, 23, 59),
                  type: AvailabilityType.blocked,
                  reason: 'Holiday Vacation',
                ))
            .toList();

        expect(vacationBlocks.length, 5);
        expect(
          vacationBlocks.every((v) => v.type == AvailabilityType.blocked),
          true,
        );
      });

      test('lunch break blocked time', () {
        final lunchBreak = Availability.blocked(
          id: 'lunch-break',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 12, 0),
          endTime: DateTime(2025, 12, 1, 13, 0),
          reason: 'Lunch Break',
        );

        expect(lunchBreak.durationMinutes, 60);
        expect(lunchBreak.type, AvailabilityType.blocked);
      });

      test('extended hours for special event', () {
        final extendedHours = Availability(
          id: 'avail-special',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 15, 8, 0), // Start earlier
          endTime: DateTime(2025, 12, 15, 20, 0), // End later
          type: AvailabilityType.override, // Override normal schedule
          reason: 'Special Event Day',
          createdAt: DateTime.now(),
        );

        expect(extendedHours.type, AvailabilityType.override);
        expect(extendedHours.durationMinutes, 720); // 12 hours
      });

      test('provider works at multiple locations', () {
        final mondayMainOffice = WeeklySchedule(
          id: 'schedule-mon-main',
          providerId: 'provider-1',
          locationId: 'location-main',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        final tuesdayBranch = WeeklySchedule(
          id: 'schedule-tue-branch',
          providerId: 'provider-1',
          locationId: 'location-branch',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        expect(mondayMainOffice.providerId, tuesdayBranch.providerId);
        expect(mondayMainOffice.locationId, isNot(tuesdayBranch.locationId));
      });
    });
  });
}
