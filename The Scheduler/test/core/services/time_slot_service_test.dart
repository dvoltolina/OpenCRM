import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/services/time_slot_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('TimeSlotService', () {
    late TimeSlotService service;
    late MockAvailabilityRepository availabilityRepo;
    late MockAppointmentsRepository appointmentsRepo;
    late BookingPolicies policies;
    late SecurityContext context;

    setUp(() {
      availabilityRepo = MockAvailabilityRepository();
      appointmentsRepo = MockAppointmentsRepository();
      policies = const BookingPolicies(
        defaultSlotLength: Duration(minutes: 30),
        bufferBetweenAppointments: Duration(minutes: 15),
        cancellationWindow: Duration(hours: 24),
        minimumBookingNotice: Duration(hours: 24),
        maximumAdvanceBooking: Duration(days: 90),
      );
      service = TimeSlotService(
        availabilityRepository: availabilityRepo,
        appointmentsRepository: appointmentsRepo,
        bookingPolicies: policies,
      );
      context = TestData.securityContext(
        businessId: 'test-business',
        role: UserRole.admin,
      );
    });

    group('generateSlots', () {
      test('generates slots from weekly schedule', () async {
        final date = DateTime(2025, 12, 1); // Monday
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock.fromStrings('09:00', '12:00'),
            TimeBlock.fromStrings('13:00', '17:00'),
          ],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        expect(slots, isNotEmpty);
        expect(slots.first.startTime.hour, 9);
        expect(slots.any((s) => s.startTime.hour == 13), true);
      });

      test('respects service duration', () async {
        final date = DateTime(2025, 12, 1);
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '11:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        // 60-minute service
        final slots60 = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        // 30-minute service
        final slots30 = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 30),
        );

        expect(slots30.length, greaterThan(slots60.length));
      });

      test('applies buffer between appointments', () async {
        final date = DateTime(2025, 12, 1);
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '12:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        if (slots.length >= 2) {
          final firstSlotEnd = slots[0].endTime;
          final secondSlotStart = slots[1].startTime;
          final gap = secondSlotStart.difference(firstSlotEnd);

          expect(gap.inMinutes, greaterThanOrEqualTo(15)); // Buffer time
        }
      });

      test('marks slots with existing appointments as unavailable', () async {
        final date = DateTime(2025, 12, 1);
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        // Add existing appointment at 10:00
        final appointment = TestData.appointment(
          businessId: 'test-business',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 10, 0),
          endTime: DateTime(2025, 12, 1, 11, 0),
          status: AppointmentStatus.confirmed,
        );

        appointmentsRepo.addAppointment(appointment);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        final slot10am = slots.firstWhere(
          (s) => s.startTime.hour == 10,
          orElse: () => slots.first,
        );

        expect(slot10am.isAvailable, false);
      });

      test('handles blocked time periods', () async {
        final date = DateTime(2025, 12, 1);
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        // Block lunch hour 12:00-13:00
        final lunchBreak = Availability.blocked(
          id: 'lunch-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 12, 0),
          endTime: DateTime(2025, 12, 1, 13, 0),
          reason: 'Lunch',
        );

        await availabilityRepo.upsertAvailability(context, lunchBreak);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        // No slots should start at noon
        final noonSlots = slots.where((s) => s.startTime.hour == 12);
        expect(noonSlots, isEmpty);
      });

      test('adds one-time available blocks', () async {
        final date = DateTime(2025, 12, 1);

        // No weekly schedule, but add a one-time block
        final oneTime = Availability.oneTime(
          id: 'onetime-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 14, 0),
          endTime: DateTime(2025, 12, 1, 16, 0),
          type: AvailabilityType.available,
        );

        await availabilityRepo.upsertAvailability(context, oneTime);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        expect(slots, isNotEmpty);
        expect(slots.any((s) => s.startTime.hour == 14), true);
      });

      test('returns empty list when no availability', () async {
        final date = DateTime(2025, 12, 1);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        expect(slots, isEmpty);
      });
    });

    group('generateSlotsForProviders', () {
      test('generates slots for multiple providers', () async {
        final date = DateTime(2025, 12, 1);
        final providers = [
          TestData.provider(id: 'provider-1', businessId: 'test-business'),
          TestData.provider(id: 'provider-2', businessId: 'test-business'),
        ];

        // Add schedules for both providers
        for (final provider in providers) {
          final schedule = WeeklySchedule(
            id: 'schedule-${provider.id}',
            providerId: provider.id,
            locationId: 'location-1',
            dayOfWeek: DayOfWeek.monday,
            timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
            isActive: true,
            createdAt: DateTime.now(),
          );
          await availabilityRepo.upsertWeeklySchedule(context, schedule);
        }

        final result = await service.generateSlotsForProviders(
          context: context,
          providers: providers,
          locationId: 'location-1',
          date: date,
          serviceDuration: const Duration(minutes: 60),
        );

        expect(result.keys, hasLength(2));
        expect(result['provider-1'], isNotEmpty);
        expect(result['provider-2'], isNotEmpty);
      });
    });

    group('findNextAvailableSlot', () {
      test('finds next available slot', () async {
        final startDate = DateTime(2025, 12, 1);

        // Provider has availability on Dec 3rd
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'provider-1',
          locationId: 'location-1',
          dayOfWeek: DayOfWeek.wednesday,
          timeBlocks: [TimeBlock.fromStrings('09:00', '17:00')],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        final nextSlot = await service.findNextAvailableSlot(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          startDate: startDate,
          serviceDuration: const Duration(minutes: 60),
          maxDaysToSearch: 7,
        );

        expect(nextSlot, isNotNull);
        expect(nextSlot?.isAvailable, true);
      });

      test('returns null when no slots found within search window', () async {
        final startDate = DateTime(2025, 12, 1);

        final nextSlot = await service.findNextAvailableSlot(
          context: context,
          providerId: 'provider-1',
          locationId: 'location-1',
          startDate: startDate,
          serviceDuration: const Duration(minutes: 60),
          maxDaysToSearch: 3,
        );

        expect(nextSlot, isNull);
      });
    });

    group('Real-World Scenarios', () {
      test('dental cleaning appointment slots', () async {
        final date = DateTime(2025, 12, 1); // Monday
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'dentist-1',
          locationId: 'clinic-main',
          dayOfWeek: DayOfWeek.monday,
          timeBlocks: [
            TimeBlock.fromStrings('08:00', '12:00'), // Morning
            TimeBlock.fromStrings('13:00', '17:00'), // Afternoon
          ],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'dentist-1',
          locationId: 'clinic-main',
          date: date,
          serviceDuration: const Duration(minutes: 60), // 1-hour cleaning
        );

        expect(slots, isNotEmpty);
        expect(slots.any((s) => s.startTime.hour >= 8 && s.startTime.hour < 12),
            true);
        expect(slots.any((s) => s.startTime.hour >= 13 && s.startTime.hour < 17),
            true);
      });

      test('therapy session with specific availability', () async {
        final date = DateTime(2025, 12, 2); // Tuesday
        final schedule = WeeklySchedule(
          id: 'schedule-1',
          providerId: 'therapist-1',
          locationId: 'therapy-office',
          dayOfWeek: DayOfWeek.tuesday,
          timeBlocks: [
            TimeBlock.fromStrings('10:00', '18:00'), // 10 AM - 6 PM
          ],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await availabilityRepo.upsertWeeklySchedule(context, schedule);

        final slots = await service.generateSlots(
          context: context,
          providerId: 'therapist-1',
          locationId: 'therapy-office',
          date: date,
          serviceDuration: const Duration(minutes: 50), // 50-min session
        );

        expect(slots, isNotEmpty);
        expect(slots.first.startTime.hour, 10);
      });
    });
  });
}
