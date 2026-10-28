import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_data_factories.dart';

void main() {
  group('Multi-Tenant Isolation', () {
    late MockAppointmentsRepository appointmentsRepo;
    late MockClientsRepository clientsRepo;
    late MockProvidersRepository providersRepo;

    setUp(() {
      appointmentsRepo = MockAppointmentsRepository();
      clientsRepo = MockClientsRepository();
      providersRepo = MockProvidersRepository();
    });

    tearDown(() {
      appointmentsRepo.clear();
      clientsRepo.clear();
      providersRepo.clear();
    });

    group('Appointments Isolation', () {
      test('business A cannot access business B appointments', () async {
        final businessA = TestData.securityContext(
          userId: 'user-a',
          businessId: 'business-a',
          role: UserRole.admin,
        );
        final businessB = TestData.securityContext(
          userId: 'user-b',
          businessId: 'business-b',
          role: UserRole.admin,
        );

        // Business A creates appointment
        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'appt-a',
            businessId: 'business-a',
          ),
        );

        // Business B creates appointment
        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'appt-b',
            businessId: 'business-b',
          ),
        );

        // Business A can only see their own appointment
        final businessAAppointments =
            await appointmentsRepo.loadAppointmentsInRange(
          context: businessA,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(businessAAppointments.length, 1);
        expect(businessAAppointments[0].businessId, 'business-a');

        // Business B can only see their own appointment
        final businessBAppointments =
            await appointmentsRepo.loadAppointmentsInRange(
          context: businessB,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        );

        expect(businessBAppointments.length, 1);
        expect(businessBAppointments[0].businessId, 'business-b');
      });

      test('throws SecurityException when businessId mismatch on create', () async {
        final businessA = TestData.securityContext(
          businessId: 'business-a',
        );

        final appointmentForB = TestData.appointment(
          businessId: 'business-b',
        );

        expect(
          () => appointmentsRepo.upsertAppointment(
            context: businessA,
            appointment: appointmentForB,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Clients Isolation', () {
      test('business A cannot access business B clients', () async {
        final businessA = TestData.securityContext(
          businessId: 'business-a',
        );
        final businessB = TestData.securityContext(
          businessId: 'business-b',
        );

        // Add clients to both businesses
        clientsRepo.addClient(
          TestData.client(id: 'client-a', businessId: 'business-a'),
        );
        clientsRepo.addClient(
          TestData.client(id: 'client-b', businessId: 'business-b'),
        );

        // Business A tries to access Business B's client
        expect(
          () => clientsRepo.getClient(
            context: businessA,
            clientId: 'client-b',
          ),
          throwsA(isA<SecurityException>()),
        );

        // Business B tries to access Business A's client
        expect(
          () => clientsRepo.getClient(
            context: businessB,
            clientId: 'client-a',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('throws SecurityException when creating client for different business', () async {
        final businessA = TestData.securityContext(
          businessId: 'business-a',
        );

        final clientForB = TestData.client(businessId: 'business-b');

        expect(
          () => clientsRepo.upsertClient(
            context: businessA,
            client: clientForB,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('throws SecurityException when deleting client from different business', () async {
        final businessA = TestData.securityContext(
          businessId: 'business-a',
        );

        // Add client for business B
        clientsRepo.addClient(
          TestData.client(id: 'client-b', businessId: 'business-b'),
        );

        // Business A tries to delete Business B's client
        expect(
          () => clientsRepo.deleteClient(
            context: businessA,
            clientId: 'client-b',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Providers Isolation', () {
      test('business A cannot access business B providers', () async {
        final businessA = TestData.securityContext(
          businessId: 'business-a',
        );
        final businessB = TestData.securityContext(
          businessId: 'business-b',
        );

        // Add providers to both businesses
        providersRepo.addProvider(
          TestData.provider(id: 'provider-a', businessId: 'business-a'),
        );
        providersRepo.addProvider(
          TestData.provider(id: 'provider-b', businessId: 'business-b'),
        );

        // Business A tries to access Business B's provider
        expect(
          () => providersRepo.getProvider(
            context: businessA,
            providerId: 'provider-b',
          ),
          throwsA(isA<SecurityException>()),
        );

        // Business B tries to access Business A's provider
        expect(
          () => providersRepo.getProvider(
            context: businessB,
            providerId: 'provider-a',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Cross-Entity Data Leakage Prevention', () {
      test('cannot access appointments via client from different business', () async {
        final businessB = TestData.securityContext(
          businessId: 'business-b',
        );

        // Business A has appointment for client-a
        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'appt-a',
            businessId: 'business-a',
            clientId: 'client-a',
          ),
        );

        // Business B tries to query by client-a
        final appointments = await appointmentsRepo.loadAppointmentsInRange(
          context: businessB,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
          clientId: 'client-a',
        );

        // Should not find any appointments (filtered by businessId first)
        expect(appointments, isEmpty);
      });

      test('cannot access appointments via provider from different business', () async {
        final businessB = TestData.securityContext(
          businessId: 'business-b',
        );

        // Business A has appointment with provider-a
        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'appt-a',
            businessId: 'business-a',
            providerId: 'provider-a',
          ),
        );

        // Business B tries to query by provider-a
        final appointments = await appointmentsRepo.loadAppointmentsInRange(
          context: businessB,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
          providerId: 'provider-a',
        );

        // Should not find any appointments (filtered by businessId first)
        expect(appointments, isEmpty);
      });
    });

    group('SecurityContext Validation', () {
      test('all repositories require valid SecurityContext', () {
        final context = TestData.securityContext();

        // These should not throw
        expect(
          () => appointmentsRepo.loadAppointmentsInRange(
            context: context,
            start: DateTime(2025, 1, 1),
            end: DateTime(2025, 12, 31),
          ),
          returnsNormally,
        );

        expect(
          () => clientsRepo.getClient(
            context: context,
            clientId: 'client-1',
          ),
          returnsNormally,
        );

        expect(
          () => providersRepo.getProvider(
            context: context,
            providerId: 'provider-1',
          ),
          returnsNormally,
        );
      });

      test('SecurityContext contains required fields', () {
        final context = TestData.securityContext(
          userId: 'user-123',
          businessId: 'business-456',
          role: UserRole.admin,
        );

        expect(context.userId, 'user-123');
        expect(context.businessId, 'business-456');
        expect(context.role, UserRole.admin);
      });
    });

    group('Real-World Multi-Tenant Scenarios', () {
      test('dental clinic A and therapy clinic B have complete isolation', () async {
        // Setup two different clinics
        final dentalClinic = TestData.securityContext(
          userId: 'dental-admin',
          businessId: 'dental-clinic-123',
          role: UserRole.admin,
        );

        final therapyClinic = TestData.securityContext(
          userId: 'therapy-admin',
          businessId: 'therapy-clinic-456',
          role: UserRole.admin,
        );

        // Each clinic adds their own data
        clientsRepo.addClient(
          TestData.client(
            id: 'dental-patient-1',
            businessId: 'dental-clinic-123',
            firstName: 'Dental',
            lastName: 'Patient',
          ),
        );

        clientsRepo.addClient(
          TestData.client(
            id: 'therapy-client-1',
            businessId: 'therapy-clinic-456',
            firstName: 'Therapy',
            lastName: 'Client',
          ),
        );

        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'dental-appt-1',
            businessId: 'dental-clinic-123',
            clientId: 'dental-patient-1',
          ),
        );

        appointmentsRepo.addAppointment(
          TestData.appointment(
            id: 'therapy-appt-1',
            businessId: 'therapy-clinic-456',
            clientId: 'therapy-client-1',
          ),
        );

        // Verify dental clinic can only see their own data
        final dentalClient = await clientsRepo.getClient(
          context: dentalClinic,
          clientId: 'dental-patient-1',
        );
        expect(dentalClient, isNotNull);
        expect(dentalClient!.firstName, 'Dental');

        final dentalAppointments =
            await appointmentsRepo.loadAppointmentsInRange(
          context: dentalClinic,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        );
        expect(dentalAppointments.length, 1);
        expect(dentalAppointments[0].id, 'dental-appt-1');

        // Verify therapy clinic can only see their own data
        final therapyClient = await clientsRepo.getClient(
          context: therapyClinic,
          clientId: 'therapy-client-1',
        );
        expect(therapyClient, isNotNull);
        expect(therapyClient!.firstName, 'Therapy');

        final therapyAppointments =
            await appointmentsRepo.loadAppointmentsInRange(
          context: therapyClinic,
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 12, 31),
        );
        expect(therapyAppointments.length, 1);
        expect(therapyAppointments[0].id, 'therapy-appt-1');

        // Verify no cross-contamination
        expect(
          () => clientsRepo.getClient(
            context: dentalClinic,
            clientId: 'therapy-client-1',
          ),
          throwsA(isA<SecurityException>()),
        );

        expect(
          () => clientsRepo.getClient(
            context: therapyClinic,
            clientId: 'dental-patient-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('100 businesses with 10 appointments each remain isolated', () async {
        // Simulate a SaaS environment with many businesses
        for (int i = 0; i < 100; i++) {
          final businessId = 'business-$i';
          for (int j = 0; j < 10; j++) {
            appointmentsRepo.addAppointment(
              TestData.appointment(
                id: 'appt-$i-$j',
                businessId: businessId,
              ),
            );
          }
        }

        // Total appointments: 1000
        expect(appointmentsRepo.count, 1000);

        // Each business should only see their own 10 appointments
        for (int i = 0; i < 100; i++) {
          final context = TestData.securityContext(
            businessId: 'business-$i',
          );

          final appointments = await appointmentsRepo.loadAppointmentsInRange(
            context: context,
            start: DateTime(2025, 1, 1),
            end: DateTime(2025, 12, 31),
          );

          expect(appointments.length, 10);
          for (final appt in appointments) {
            expect(appt.businessId, 'business-$i');
          }
        }
      });
    });
  });
}
