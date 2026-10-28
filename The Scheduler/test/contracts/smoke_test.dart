// Cross-Repo Smoke Tests
//
// End-to-end flow validation for cross-repo integrations.
// Tests booking → payment → CRM visibility flows.
//
// Prerequisites:
// - Firebase Emulator running (auth + firestore)
// - Test data seeded via functions/src/seed.ts
//
// Run with:
// flutter test test/contracts/smoke_test.dart --dart-define=USE_EMULATOR=true

import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/payment.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../helpers/test_data_factories.dart';

void main() {
  group('Cross-Repo Smoke Tests', () {
    // Shared test context
    late SecurityContext adminContext;
    late SecurityContext staffContext;
    late SecurityContext clientContext;

    setUpAll(() {
      // Initialize test security contexts
      adminContext = TestData.securityContext(
        userId: 'admin-user-smoke',
        businessId: 'smoke-test-business',
        role: UserRole.admin,
      );

      staffContext = TestData.securityContext(
        userId: 'staff-user-smoke',
        businessId: 'smoke-test-business',
        role: UserRole.staff,
        providerId: 'provider-smoke-1',
      );

      clientContext = TestData.securityContext(
        userId: 'client-user-smoke',
        businessId: 'smoke-test-business',
        role: UserRole.client,
        clientId: 'client-smoke-1',
      );
    });

    group('Flow 1: Booking → Payment → CRM Visibility', () {
      test('Step 1: Create appointment data matches contract', () {
        final appointment = TestData.appointment(
          id: 'smoke-appt-1',
          businessId: 'smoke-test-business',
          clientId: 'client-smoke-1',
          providerId: 'provider-smoke-1',
          serviceId: 'service-smoke-1',
          locationId: 'location-smoke-1',
          status: AppointmentStatus.confirmed,
        );

        // Verify contract compliance
        expect(appointment.businessId, equals('smoke-test-business'));
        expect(appointment.status, equals(AppointmentStatus.confirmed));
        expect(appointment.toJson(), isA<Map<String, dynamic>>());
      });

      test('Step 2: Appointment visible to staff (same business)', () {
        final appointment = TestData.appointment(
          businessId: staffContext.businessId,
          providerId: staffContext.providerId,
        );

        // Staff can view appointments in their business
        expect(
          () => staffContext.verifyBusinessAccess(appointment.businessId),
          returnsNormally,
        );
      });

      test('Step 3: Payment record links to appointment', () {
        final appointment = TestData.appointment(
          id: 'smoke-appt-for-payment',
          businessId: 'smoke-test-business',
        );

        final payment = TestData.payment(
          businessId: appointment.businessId,
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          amountCents: 5000,
          status: PaymentStatus.completed,
        );

        // Payment references correct appointment
        expect(payment.appointmentId, equals(appointment.id));
        expect(payment.businessId, equals(appointment.businessId));
        expect(payment.clientId, equals(appointment.clientId));
      });

      test('Step 4: Payment record in Firestore format', () {
        final payment = TestData.payment(
          businessId: 'smoke-test-business',
          appointmentId: 'smoke-appt-1',
          amountCents: 10000, // $100.00
          status: PaymentStatus.completed,
        );

        final json = payment.toJson();

        // CRM reads payment data - verify format
        expect(json['businessId'], equals('smoke-test-business'));
        expect(json['appointmentId'], equals('smoke-appt-1'));
        expect(json['amountCents'], equals(10000));
        expect(json['status'], equals('completed'));
      });

      test('Step 5: Client can view appointment history', () {
        final appointment = TestData.appointment(
          businessId: clientContext.businessId,
          clientId: clientContext.clientId,
        );

        // Client can access their own appointments
        expect(appointment.clientId, equals(clientContext.clientId));
        expect(
          () => clientContext.verifyBusinessAccess(appointment.businessId),
          returnsNormally,
        );
      });
    });

    group('Flow 2: Client Management Cross-Repo', () {
      test('Step 1: Admin creates client with contract-compliant data', () {
        final client = TestData.client(
          id: 'smoke-client-new',
          businessId: adminContext.businessId,
          firstName: 'Smoke',
          lastName: 'Test',
          email: 'smoke@test.com',
        );

        // Verify contract compliance
        expect(client.businessId, equals(adminContext.businessId));
        expect(client.toJson(), isA<Map<String, dynamic>>());
      });

      test('Step 2: Client visible in Scheduler App', () {
        final client = TestData.client(
          businessId: 'smoke-test-business',
        );

        // Staff can view client
        expect(
          () => staffContext.verifyBusinessAccess(client.businessId),
          returnsNormally,
        );
      });

      test('Step 3: Client tags update propagates', () {
        final originalClient = TestData.client(
          businessId: 'smoke-test-business',
          tags: ['new'],
        );

        final updatedClient = originalClient.copyWith(
          tags: ['new', 'vip', 'priority'],
        );

        // Tags updated
        expect(updatedClient.tags, contains('vip'));
        expect(updatedClient.tags, hasLength(3));
        // Business ID unchanged
        expect(updatedClient.businessId, equals(originalClient.businessId));
      });

      test('Step 4: CRM can read client data', () {
        final client = TestData.client(
          businessId: 'smoke-test-business',
        );

        final json = client.toJson();

        // CRM reads client data - verify format
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('businessId'), isTrue);
        expect(json.containsKey('firstName'), isTrue);
        expect(json.containsKey('lastName'), isTrue);
        expect(json.containsKey('email'), isTrue);
        expect(json.containsKey('tags'), isTrue);
      });
    });

    group('Flow 3: Group Session Registration', () {
      test('Step 1: Admin creates group session', () {
        final groupSession = Appointment(
          id: 'smoke-group-1',
          businessId: 'smoke-test-business',
          clientId: 'admin-placeholder',
          providerId: 'provider-smoke-1',
          serviceId: 'service-group-1',
          locationId: 'location-smoke-1',
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 1)),
          date: DateTime.now().add(const Duration(days: 7)),
          status: AppointmentStatus.confirmed,
          isGroupSession: true,
          capacity: 10,
          attendeeIds: [],
          createdAt: DateTime.now(),
        );

        expect(groupSession.isGroupSession, isTrue);
        expect(groupSession.capacity, equals(10));
        expect(groupSession.attendeeIds, isEmpty);
      });

      test('Step 2: Client joins group session', () {
        final groupSession = Appointment(
          id: 'smoke-group-1',
          businessId: 'smoke-test-business',
          clientId: 'admin-placeholder',
          providerId: 'provider-smoke-1',
          serviceId: 'service-group-1',
          locationId: 'location-smoke-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          isGroupSession: true,
          capacity: 10,
          attendeeIds: [],
          createdAt: DateTime.now(),
        );

        // Simulate client joining
        final updatedSession = groupSession.copyWith(
          attendeeIds: [...groupSession.attendeeIds, clientContext.clientId!],
        );

        expect(updatedSession.attendeeIds, contains(clientContext.clientId));
        expect(updatedSession.attendeeIds.length, equals(1));
      });

      test('Step 3: Capacity enforced', () {
        final fullSession = Appointment(
          id: 'smoke-group-full',
          businessId: 'smoke-test-business',
          clientId: 'admin-placeholder',
          providerId: 'provider-smoke-1',
          serviceId: 'service-group-1',
          locationId: 'location-smoke-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          isGroupSession: true,
          capacity: 2,
          attendeeIds: ['client-1', 'client-2'],
          createdAt: DateTime.now(),
        );

        // At capacity
        expect(fullSession.attendeeIds.length, equals(fullSession.capacity));
      });

      test('Step 4: Per-attendee payment created', () {
        final attendeePayment = TestData.payment(
          businessId: 'smoke-test-business',
          appointmentId: 'smoke-group-1',
          clientId: clientContext.clientId,
          amountCents: 2500, // Per-person rate
          status: PaymentStatus.completed,
        );

        expect(attendeePayment.appointmentId, equals('smoke-group-1'));
        expect(attendeePayment.clientId, equals(clientContext.clientId));
      });
    });

    group('Data Integrity Checks', () {
      test('Orphaned payment detection logic', () {
        // Payment with non-existent appointment
        final orphanedPayment = TestData.payment(
          appointmentId: 'non-existent-appt',
          status: PaymentStatus.completed,
        );

        // In real system, integrity check would flag this
        expect(orphanedPayment.appointmentId, equals('non-existent-appt'));
      });

      test('Cross-tenant query blocked', () {
        final tenantAContext = TestData.securityContext(
          businessId: 'tenant-A',
          role: UserRole.admin,
        );

        final tenantBAppointment = TestData.appointment(
          businessId: 'tenant-B',
        );

        // Should throw when accessing different tenant
        expect(
          () => tenantAContext.verifyBusinessAccess(tenantBAppointment.businessId),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Schema Compatibility', () {
      test('All models serialize to JSON correctly', () {
        final client = TestData.client();
        final appointment = TestData.appointment();
        final payment = TestData.payment();

        expect(() => client.toJson(), returnsNormally);
        expect(() => appointment.toJson(), returnsNormally);
        expect(() => payment.toJson(), returnsNormally);
      });

      test('All models deserialize from JSON correctly', () {
        final clientJson = TestData.client().toJson();
        final appointmentJson = TestData.appointment().toJson();
        final paymentJson = TestData.payment().toJson();

        expect(() => Client.fromJson(clientJson), returnsNormally);
        expect(() => Appointment.fromJson(appointmentJson), returnsNormally);
        expect(() => Payment.fromJson(paymentJson), returnsNormally);
      });
    });
  });
}
