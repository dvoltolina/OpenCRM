import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Availability Repository', () {
    late MockAvailabilityRepository repository;
    late SecurityContext adminContext;

    setUp(() {
      repository = MockAvailabilityRepository();
      adminContext = TestData.securityContext(
        role: UserRole.admin,
        businessId: 'test-business',
      );
    });

    group('Weekly Schedules CRUD', () {
      test('creates weekly schedule', () async {
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        await repository.upsertWeeklySchedule(adminContext, schedule);

        expect(repository.weeklyScheduleCount, 1);
      });

      test('updates existing weekly schedule', () async {
        final original = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        await repository.upsertWeeklySchedule(adminContext, original);

        final updated = original.copyWith(
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
        );

        await repository.upsertWeeklySchedule(adminContext, updated);

        expect(repository.weeklyScheduleCount, 1);
      });

      test('watches weekly schedules for provider', () async {
        final schedule1 = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        final schedule2 = WeeklySchedule(
          id: 'schedule-2',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.wednesday,
          timeBlocks: [
            TimeBlock(startHour: 10, startMinute: 0, endHour: 16, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        repository.addWeeklySchedule(schedule1);
        repository.addWeeklySchedule(schedule2);

        final stream = repository.watchWeeklySchedules(
          adminContext,
          'provider-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<WeeklySchedule>>((schedules) {
            return schedules.length == 2 &&
                schedules.any((s) => s.dayOfWeek == DayOfWeek.monday) &&
                schedules.any((s) => s.dayOfWeek == DayOfWeek.wednesday);
          })),
        );
      });

      test('filters schedules by location', () async {
        final schedule1 = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        final schedule2 = WeeklySchedule(
          id: 'schedule-2',
          providerId: 'provider-1',
          locationId: 'location-2',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [
            TimeBlock(startHour: 10, startMinute: 0, endHour: 16, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        repository.addWeeklySchedule(schedule1);
        repository.addWeeklySchedule(schedule2);

        final stream = repository.watchWeeklySchedules(
          adminContext,
          'provider-1',
          locationId: 'location-1',
        );

        await expectLater(
          stream,
          emits(predicate<List<WeeklySchedule>>((schedules) {
            return schedules.length == 1 &&
                schedules.first.locationId == 'location-1';
          })),
        );
      });

      test('gets weekly schedule for specific day', () async {
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.friday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        repository.addWeeklySchedule(schedule);

        final result = await repository.getWeeklySchedule(
          adminContext,
          'provider-1',
          DayOfWeek.friday,
        );

        expect(result, isNotNull);
        expect(result?.dayOfWeek, DayOfWeek.friday);
      });

      test('deletes weekly schedule', () async {
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.thursday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        repository.addWeeklySchedule(schedule);
        expect(repository.weeklyScheduleCount, 1);

        await repository.deleteWeeklySchedule(adminContext, 'schedule-1');

        expect(repository.weeklyScheduleCount, 0);
      });
    });

    group('One-Time Availability CRUD', () {
      test('creates availability block', () async {
        final now = DateTime.now();
        final availability = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: now,
          endTime: now.add(const Duration(hours: 2)),
          type: AvailabilityType.available,
          createdAt: now,
        );

        await repository.upsertAvailability(adminContext, availability);

        expect(repository.availabilityCount, 1);
      });

      test('creates blocked time', () async {
        final now = DateTime.now();
        final blocked = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          type: AvailabilityType.blocked,
          reason: 'Lunch break',
          createdAt: now,
        );

        await repository.upsertAvailability(adminContext, blocked);

        expect(repository.availabilityCount, 1);
      });

      test('watches availability in date range', () async {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final nextWeek = today.add(const Duration(days: 7));

        final avail1 = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: tomorrow,
          endTime: tomorrow.add(const Duration(hours: 2)),
          type: AvailabilityType.available,
          createdAt: today,
        );

        final avail2 = Availability(
          id: 'avail-2',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: nextWeek,
          endTime: nextWeek.add(const Duration(hours: 2)),
          type: AvailabilityType.available,
          createdAt: today,
        );

        repository.addAvailability(avail1);
        repository.addAvailability(avail2);

        final stream = repository.watchAvailability(
          adminContext,
          'provider-1',
          today,
          today.add(const Duration(days: 3)),
        );

        await expectLater(
          stream,
          emits(predicate<List<Availability>>((availabilities) {
            return availabilities.length == 1 &&
                availabilities.first.id == 'avail-1';
          })),
        );
      });

      test('gets availability for specific date', () async {
        final targetDate = DateTime(2025, 12, 15);
        final availability = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 15, 9, 0),
          endTime: DateTime(2025, 12, 15, 17, 0),
          type: AvailabilityType.available,
          createdAt: DateTime.now(),
        );

        repository.addAvailability(availability);

        final result = await repository.getAvailabilityForDate(
          adminContext,
          'provider-1',
          targetDate,
        );

        expect(result, hasLength(1));
        expect(result.first.id, 'avail-1');
      });

      test('deletes availability block', () async {
        final availability = Availability(
          id: 'avail-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
          type: AvailabilityType.available,
          createdAt: DateTime.now(),
        );

        repository.addAvailability(availability);
        expect(repository.availabilityCount, 1);

        await repository.deleteAvailability(adminContext, 'avail-1');

        expect(repository.availabilityCount, 0);
      });
    });

    group('TimeBlock Helpers', () {
      test('calculates duration in minutes', () {
        final block = TimeBlock(
          startHour: 9,
          startMinute: 0,
          endHour: 17,
          endMinute: 30,
        );

        expect(block.durationMinutes, 510); // 8.5 hours = 510 minutes
      });

      test('formats time display', () {
        final block = TimeBlock(
          startHour: 9,
          startMinute: 30,
          endHour: 17,
          endMinute: 0,
        );

        expect(block.displayTime, '9:30 AM - 5:00 PM');
      });

      test('converts to DateTime on specific date', () {
        final block = TimeBlock(
          startHour: 14,
          startMinute: 30,
          endHour: 16,
          endMinute: 0,
        );

        final date = DateTime(2025, 12, 15);
        final startDateTime = block.toStartDateTime(date);
        final endDateTime = block.toEndDateTime(date);

        expect(startDateTime, DateTime(2025, 12, 15, 14, 30));
        expect(endDateTime, DateTime(2025, 12, 15, 16, 0));
      });

      test('creates TimeBlock from time strings', () {
        final block = TimeBlock.fromStrings('09:30', '17:00');

        expect(block.startHour, 9);
        expect(block.startMinute, 30);
        expect(block.endHour, 17);
        expect(block.endMinute, 0);
      });
    });

    group('Batch Operations', () {
      test('batch creates multiple weekly schedules', () async {
        final schedules = [
          WeeklySchedule(
            id: 'schedule-mon',
            providerId: 'provider-1',
            locationId: 'location-1',
            dayOfWeek: DayOfWeek.monday,
            timeBlocks: [
              TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
            ],
            createdAt: DateTime.now(),
          ),
          WeeklySchedule(
            id: 'schedule-wed',
            providerId: 'provider-1',
            locationId: 'location-1',
            dayOfWeek: DayOfWeek.wednesday,
            timeBlocks: [
              TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
            ],
            createdAt: DateTime.now(),
          ),
          WeeklySchedule(
            id: 'schedule-fri',
            providerId: 'provider-1',
            locationId: 'location-1',
            dayOfWeek: DayOfWeek.friday,
            timeBlocks: [
              TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
            ],
            createdAt: DateTime.now(),
          ),
        ];

        await repository.batchCreateWeeklySchedules(adminContext, schedules);

        expect(repository.weeklyScheduleCount, 3);
      });
    });

    group('Real-World Scheduling Scenarios', () {
      test('dental hygienist with split schedule', () async {
        final morningBlock = WeeklySchedule(
          id: 'schedule-morning',
          providerId: 'hygienist-1',
          locationId: 'dental-location-1',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [
            TimeBlock(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        final afternoonBlock = WeeklySchedule(
          id: 'schedule-afternoon',
          providerId: 'hygienist-1',
          locationId: 'dental-location-1',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [
            TimeBlock(startHour: 13, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        await repository.upsertWeeklySchedule(adminContext, morningBlock);
        await repository.upsertWeeklySchedule(adminContext, afternoonBlock);

        expect(repository.weeklyScheduleCount, 2);
      });

      test('therapist blocks vacation time', () async {
        final vacationStart = DateTime(2025, 12, 20, 0, 0);
        final vacationEnd = DateTime(2025, 12, 31, 23, 59);

        final vacation = Availability(
          id: 'vacation-1',
          providerId: 'therapist-1',
          locationId: 'therapy-location-1',
          startTime: vacationStart,
          endTime: vacationEnd,
          type: AvailabilityType.blocked,
          reason: 'Holiday vacation',
          createdAt: DateTime.now(),
        );

        await repository.upsertAvailability(adminContext, vacation);

        expect(repository.availabilityCount, 1);
      });

      test('provider overrides schedule for specific date', () async {
        // Regular schedule: Monday 9-5
        final regularSchedule = WeeklySchedule(
          id: 'schedule-mon',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0),
          ],
          createdAt: DateTime.now(),
        );

        // Override for specific Monday (half day)
        final override = Availability(
          id: 'override-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 22, 9, 0),
          endTime: DateTime(2025, 12, 22, 12, 0),
          type: AvailabilityType.override,
          specificDate: DateTime(2025, 12, 22),
          reason: 'Half day - afternoon appointment',
          createdAt: DateTime.now(),
        );

        await repository.upsertWeeklySchedule(adminContext, regularSchedule);
        await repository.upsertAvailability(adminContext, override);

        expect(repository.weeklyScheduleCount, 1);
        expect(repository.availabilityCount, 1);
      });
    });

    group('DayOfWeek Enum Helpers', () {
      test('converts from DateTime weekday', () {
        final monday = DateTime(2025, 12, 15); // Monday
        expect(DayOfWeek.fromDateTime(monday), DayOfWeek.monday);

        final friday = DateTime(2025, 12, 19); // Friday
        expect(DayOfWeek.fromDateTime(friday), DayOfWeek.friday);
      });

      test('gets weekday value', () {
        expect(DayOfWeek.monday.weekdayValue, 1);
        expect(DayOfWeek.sunday.weekdayValue, 7);
      });

      test('has display names', () {
        expect(DayOfWeek.monday.displayName, 'Monday');
        expect(DayOfWeek.friday.displayName, 'Friday');
      });

      test('has short names', () {
        expect(DayOfWeek.monday.shortName, 'Mon');
        expect(DayOfWeek.wednesday.shortName, 'Wed');
      });
    });
  });
}
