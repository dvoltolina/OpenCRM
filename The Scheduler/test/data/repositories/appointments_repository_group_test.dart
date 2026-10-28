import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('AppointmentsRepository group sessions', () {
    late AppointmentsRepository repository;
    late FakeFirebaseFirestore firestore;
    final adminContext = TestData.securityContext(role: UserRole.admin);
    final clientContext = TestData.securityContext(
      role: UserRole.client,
      clientId: 'client-123',
    );

    setUp(() {
      firestore = FakeFirebaseFirestore();
      final auditLogRepository = AuditLogRepository(firestore: firestore);
      repository = AppointmentsRepository(
        firestore: firestore,
        recurrenceService: RecurrenceService(firestore: firestore),
        groupAttendeesRepository: GroupAttendeesRepository(
          firestore: firestore,
          auditLogRepository: auditLogRepository,
        ),
        auditLogRepository: auditLogRepository,
      );
    });

    Future<Appointment> seedSession({
      String id = 'group-1',
      int capacity = 2,
      List<String> attendeeIds = const [],
      DateTime? registrationDeadline,
    }) async {
      final session = TestData.appointment(
        id: id,
        clientId: 'host-client',
      ).copyWith(
        isGroupSession: true,
        capacity: capacity,
        attendeeIds: attendeeIds,
        registrationDeadline: registrationDeadline,
      );
      await repository.upsertAppointment(
        context: adminContext,
        appointment: session,
      );
      return session;
    }

    test('addAttendeeToGroupSession appends attendee until capacity reached',
        () async {
      final session = await seedSession();

      await repository.addAttendeeToGroupSession(
        context: adminContext,
        appointmentId: session.id,
        clientId: 'client-a',
      );

      await repository.addAttendeeToGroupSession(
        context: adminContext,
        appointmentId: session.id,
        clientId: 'client-b',
      );

      final updated = await repository.getAppointment(
        context: adminContext,
        appointmentId: session.id,
      );

      expect(updated?.attendeeIds, containsAll(['client-a', 'client-b']));
      expect(updated?.isFull, isTrue);
    });

    test('addAttendeeToGroupSession throws when session is full', () async {
      final session = await seedSession(
        id: 'group-capacity',
        capacity: 1,
        attendeeIds: const ['client-a'],
      );

      expect(
        () => repository.addAttendeeToGroupSession(
          context: adminContext,
          appointmentId: session.id,
          clientId: 'client-b',
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('client cannot join on behalf of another client', () async {
      final session = await seedSession(id: 'group-client');

      expect(
        () => repository.addAttendeeToGroupSession(
          context: clientContext,
          appointmentId: session.id,
          clientId: 'other-client',
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('removeAttendeeFromGroupSession enforces client ownership', () async {
      final session = await seedSession(
        id: 'group-remove',
        attendeeIds: const ['client-123'],
      );

      expect(
        () => repository.removeAttendeeFromGroupSession(
          context: clientContext.copyWith(clientId: 'client-xyz'),
          appointmentId: session.id,
          clientId: 'client-123',
        ),
        throwsA(isA<SecurityException>()),
      );

      await repository.removeAttendeeFromGroupSession(
        context: clientContext,
        appointmentId: session.id,
        clientId: 'client-123',
      );

      final updated = await repository.getAppointment(
        context: adminContext,
        appointmentId: session.id,
      );

      expect(updated?.attendeeIds, isEmpty);
    });

    test('addAttendeeToGroupSession prevents duplicate registrations',
        () async {
      final session = await seedSession(
        id: 'group-duplicate',
        attendeeIds: const ['client-dupe'],
      );

      expect(
        () => repository.addAttendeeToGroupSession(
          context: adminContext,
          appointmentId: session.id,
          clientId: 'client-dupe',
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('addAttendeeToGroupSession enforces registration deadlines',
        () async {
      final session = await seedSession(
        id: 'group-deadline',
        registrationDeadline: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(
        () => repository.addAttendeeToGroupSession(
          context: adminContext,
          appointmentId: session.id,
          clientId: 'late-client',
        ),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
