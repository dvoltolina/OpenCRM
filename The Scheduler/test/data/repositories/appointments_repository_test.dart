import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('AppointmentsRepository', () {
    late MockAppointmentsRepository repository;
    late SecurityContext adminContext;

    setUp(() {
      repository = MockAppointmentsRepository();
      adminContext = TestData.securityContext(
        userId: 'admin-user',
        businessId: 'test-business',
        role: UserRole.admin,
      );
    });

    tearDown(() {
      repository.clear();
    });

    group('upsertAppointment', () {
      test('creates new appointment', () async {
        final appointment = TestData.appointment(
          id: 'appt-1',
          businessId: 'test-business',
        );

        await repository.upsertAppointment(
          context: adminContext,
          appointment: appointment,
        );

        expect(repository.count, 1);
      });

      test('updates existing appointment', () async {
        final original = TestData.appointment(
          id: 'appt-1',
          businessId: 'test-business',
          status: AppointmentStatus.pending,
        );

        await repository.upsertAppointment(
          context: adminContext,
          appointment: original,
        );

        final updated = original.copyWith(status: AppointmentStatus.confirmed);

        await repository.upsertAppointment(
          context: adminContext,
          appointment: updated,
        );

        expect(repository.count, 1); // Should still be 1 (updated, not added)
      });

      test('throws SecurityException when businessId mismatch', () async {
        final appointment = TestData.appointment(
          businessId: 'wrong-business',
        );

        expect(
          () => repository.upsertAppointment(
            context: adminContext,
            appointment: appointment,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('loadAppointmentsInRange', () {
      test('returns appointments in date range', () async {
        // Add appointments across different dates
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            startTime: DateTime(2025, 12, 15, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-3',
            businessId: 'test-business',
            startTime: DateTime(2025, 12, 25, 10, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 10),
          end: DateTime(2025, 12, 20),
        );

        expect(appointments.length, 1);
        expect(appointments[0].id, 'appt-2');
      });

      test('filters by businessId for multi-tenant isolation', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'other-business',
            startTime: DateTime(2025, 12, 1, 11, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(appointments.length, 1);
        expect(appointments[0].businessId, 'test-business');
      });

      test('filters by providerId when specified', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            providerId: 'provider-1',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            providerId: 'provider-2',
            startTime: DateTime(2025, 12, 1, 11, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
          providerId: 'provider-1',
        );

        expect(appointments.length, 1);
        expect(appointments[0].providerId, 'provider-1');
      });

      test('filters by clientId when specified', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            clientId: 'client-1',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            clientId: 'client-2',
            startTime: DateTime(2025, 12, 1, 11, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
          clientId: 'client-1',
        );

        expect(appointments.length, 1);
        expect(appointments[0].clientId, 'client-1');
      });

      test('filters by locationId when specified', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            locationId: 'location-1',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            locationId: 'location-2',
            startTime: DateTime(2025, 12, 1, 11, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
          locationId: 'location-1',
        );

        expect(appointments.length, 1);
        expect(appointments[0].locationId, 'location-1');
      });

      test('supports combining multiple filters', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            providerId: 'provider-1',
            clientId: 'client-1',
            locationId: 'location-1',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            providerId: 'provider-1',
            clientId: 'client-2', // Different client
            locationId: 'location-1',
            startTime: DateTime(2025, 12, 1, 11, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
          providerId: 'provider-1',
          clientId: 'client-1',
          locationId: 'location-1',
        );

        expect(appointments.length, 1);
        expect(appointments[0].id, 'appt-1');
      });

      test('returns empty list when no appointments match', () async {
        repository.addAppointment(
          TestData.appointment(
            businessId: 'test-business',
            startTime: DateTime(2025, 11, 1, 10, 0),
          ),
        );

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(appointments, isEmpty);
      });
    });

    group('getAppointmentsForDate', () {
      test('returns appointments for specific date', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            providerId: 'provider-1',
            startTime: DateTime(2025, 12, 1, 9, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            providerId: 'provider-1',
            startTime: DateTime(2025, 12, 1, 14, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-3',
            businessId: 'test-business',
            providerId: 'provider-1',
            startTime: DateTime(2025, 12, 2, 10, 0), // Different day
          ),
        );

        final appointments = await repository.getAppointmentsForDate(
          context: adminContext,
          providerId: 'provider-1',
          date: DateTime(2025, 12, 1),
        );

        expect(appointments.length, 2);
        expect(appointments[0].id, 'appt-1');
        expect(appointments[1].id, 'appt-2');
      });

      test('filters by provider', () async {
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-1',
            businessId: 'test-business',
            providerId: 'provider-1',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );
        repository.addAppointment(
          TestData.appointment(
            id: 'appt-2',
            businessId: 'test-business',
            providerId: 'provider-2',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );

        final appointments = await repository.getAppointmentsForDate(
          context: adminContext,
          providerId: 'provider-1',
          date: DateTime(2025, 12, 1),
        );

        expect(appointments.length, 1);
        expect(appointments[0].providerId, 'provider-1');
      });
    });

    group('Multi-Tenant Security', () {
      test('different businesses cannot access each others appointments', () async {
        final businessAContext = TestData.securityContext(
          businessId: 'business-a',
        );
        final businessBContext = TestData.securityContext(
          businessId: 'business-b',
        );

        // Business A creates appointment
        await repository.upsertAppointment(
          context: businessAContext,
          appointment: TestData.appointment(
            id: 'appt-a',
            businessId: 'business-a',
          ),
        );

        // Business B tries to load appointments
        final appointments = await repository.loadAppointmentsInRange(
          context: businessBContext,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(appointments, isEmpty);
      });

      test('throws SecurityException when trying to create appointment for different business', () async {
        final wrongBusinessAppointment = TestData.appointment(
          businessId: 'wrong-business',
        );

        expect(
          () => repository.upsertAppointment(
            context: adminContext,
            appointment: wrongBusinessAppointment,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Batch Operations', () {
      test('can load multiple appointments efficiently', () async {
        // Add 100 appointments
        for (int i = 0; i < 100; i++) {
          repository.addAppointment(
            TestData.appointment(
              id: 'appt-$i',
              businessId: 'test-business',
              startTime: DateTime(2025, 12, 1).add(Duration(hours: i)),
            ),
          );
        }

        expect(repository.count, 100);

        final appointments = await repository.loadAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(appointments.length, 100);
      });
    });

    group('Stream Support', () {
      test('watchAppointmentsInRange returns stream', () async {
        repository.addAppointment(
          TestData.appointment(
            businessId: 'test-business',
            startTime: DateTime(2025, 12, 1, 10, 0),
          ),
        );

        final stream = repository.watchAppointmentsInRange(
          context: adminContext,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 31),
        );

        final appointments = await stream.first;
        expect(appointments.length, 1);
      });
    });
  });
}
