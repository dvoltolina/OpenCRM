import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/recurrence_pattern.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('RecurrenceService.generateRecurringInstances', () {
    late FakeFirebaseFirestore firestore;
    late RecurrenceService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RecurrenceService(firestore: firestore);
    });

    test('generates weekly instances on selected days and skips exclusions',
        () {
      final parentStart = DateTime.utc(2025, 1, 6, 10); // Monday
      final pattern = RecurrencePattern(
        id: 'rec-1',
        frequency: RecurrenceFrequency.weekly,
        daysOfWeek: const [DayOfWeek.monday, DayOfWeek.wednesday],
        endType: RecurrenceEndType.afterOccurrences,
        numberOfOccurrences: 4,
        exclusionDates: [DateTime.utc(2025, 1, 8)], // Skip first Wednesday
        createdAt: DateTime.utc(2025, 1, 1),
      );

      final parent = TestData.appointment(
        id: pattern.id,
        startTime: parentStart,
        endTime: parentStart.add(const Duration(hours: 1)),
      ).copyWith(
        isRecurring: true,
        recurrenceId: pattern.id,
        recurrencePattern: pattern,
      );

      final instances = service.generateRecurringInstances(
        parentAppointment: parent,
        pattern: pattern,
      );

      expect(instances.length, 2);
      expect(instances.first.startTime, DateTime.utc(2025, 1, 13, 10));
      expect(instances.last.startTime, DateTime.utc(2025, 1, 15, 10));
      expect(instances.every((a) => a.recurrenceId == parent.id), isTrue);
      expect(instances.every((a) => a.recurrencePattern == null), isTrue);
    });

    test('stops generating when end date is reached', () {
      final start = DateTime.utc(2025, 1, 1, 9);
      final pattern = RecurrencePattern(
        id: 'daily-1',
        frequency: RecurrenceFrequency.daily,
        endType: RecurrenceEndType.onDate,
        endDate: DateTime.utc(2025, 1, 2),
        createdAt: DateTime.utc(2024, 12, 31),
      );

      final parent = TestData.appointment(
        id: pattern.id,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      ).copyWith(
        isRecurring: true,
        recurrenceId: pattern.id,
        recurrencePattern: pattern,
      );

      final instances = service.generateRecurringInstances(
        parentAppointment: parent,
        pattern: pattern,
      );

      expect(instances.length, 1);
      expect(instances.single.startTime, DateTime.utc(2025, 1, 2, 9));
    });

    test('caps generation at 52 total occurrences to prevent abuse', () {
      final start = DateTime.utc(2025, 1, 1, 9);
      final pattern = RecurrencePattern(
        id: 'cap-1',
        frequency: RecurrenceFrequency.weekly,
        endType: RecurrenceEndType.afterOccurrences,
        numberOfOccurrences: 80,
        createdAt: DateTime.utc(2024, 12, 31),
      );

      final parent = TestData.appointment(
        id: pattern.id,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      ).copyWith(
        isRecurring: true,
        recurrenceId: pattern.id,
        recurrencePattern: pattern,
      );

      final instances = service.generateRecurringInstances(
        parentAppointment: parent,
        pattern: pattern,
      );

      // 52 total occurrences including the parent = 51 generated instances
      expect(instances.length, 51);
      expect(
        instances.last.startTime.isBefore(start.add(const Duration(days: 370))),
        isTrue,
      );
    });

    test('generates biweekly instances on configured days of week', () {
      final start = DateTime.utc(2025, 1, 1, 9); // Wednesday
      final pattern = RecurrencePattern(
        id: 'biweekly-1',
        frequency: RecurrenceFrequency.biweekly,
        daysOfWeek: const [DayOfWeek.wednesday],
        endType: RecurrenceEndType.afterOccurrences,
        numberOfOccurrences: 3,
        createdAt: DateTime.utc(2024, 12, 1),
      );
      final parent = TestData.appointment(
        id: pattern.id,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      ).copyWith(
        isRecurring: true,
        recurrenceId: pattern.id,
        recurrencePattern: pattern,
      );

      final instances = service.generateRecurringInstances(
        parentAppointment: parent,
        pattern: pattern,
      );

      expect(instances.length, 2);
      expect(instances.first.startTime, DateTime.utc(2025, 1, 15, 9));
      expect(instances.last.startTime, DateTime.utc(2025, 1, 29, 9));
    });

    test('monthly recurrence clamps overflow days safely', () {
      final start = DateTime.utc(2025, 1, 31, 14);
      final pattern = RecurrencePattern(
        id: 'monthly-1',
        frequency: RecurrenceFrequency.monthly,
        endType: RecurrenceEndType.afterOccurrences,
        numberOfOccurrences: 3,
        createdAt: DateTime.utc(2024, 12, 1),
      );

      final parent = TestData.appointment(
        id: pattern.id,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
      ).copyWith(
        isRecurring: true,
        recurrenceId: pattern.id,
        recurrencePattern: pattern,
      );

      final instances = service.generateRecurringInstances(
        parentAppointment: parent,
        pattern: pattern,
      );

      expect(instances.length, 2);
      expect(instances.first.startTime, DateTime.utc(2025, 2, 28, 14));
      expect(instances.last.startTime, DateTime.utc(2025, 3, 28, 14));
    });
  });

  group('RecurrenceService.checkRecurrenceConflicts', () {
    test('returns overlapping appointments for same provider', () async {
      final firestore = FakeFirebaseFirestore();
      final service = RecurrenceService(firestore: firestore);
      const businessId = 'biz-1';
      const providerId = 'prov-1';

      final existing = TestData.appointment(
        id: 'existing',
        businessId: businessId,
        providerId: providerId,
        serviceId: 'svc-1',
        startTime: DateTime.utc(2025, 1, 10, 10),
        endTime: DateTime.utc(2025, 1, 10, 11),
        status: AppointmentStatus.confirmed,
      ).copyWith(date: DateTime.utc(2025, 1, 10));

      await firestore
          .collection('businesses')
          .doc(businessId)
          .collection('appointments')
          .doc(existing.id)
          .set(existing.toJson());

      final proposed = existing.copyWith(
        id: 'proposed',
        startTime: DateTime.utc(2025, 1, 10, 10, 30),
        endTime: DateTime.utc(2025, 1, 10, 11, 30),
        date: DateTime.utc(2025, 1, 10),
      );

      final conflicts = await service.checkRecurrenceConflicts(
        businessId: businessId,
        providerId: providerId,
        proposedInstances: [proposed],
      );

      expect(conflicts.length, 1);
      expect(conflicts.single.id, existing.id);
    });
  });
}
