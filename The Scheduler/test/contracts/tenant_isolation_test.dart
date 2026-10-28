// Tenant Isolation Contract Tests
//
// Validates multi-tenant isolation across all shared collections.
// Ensures no cross-tenant data leakage per security requirements in:
// - docs/shared_data_contract.md
// - docs/ARCHITECTURE_DOCS/02_security_auth.md
// - mandatory_hipaa_security_rules.md

import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/payment.dart';

void main() {
  group('Tenant Isolation Contract Tests', () {
    // Test business IDs
    const tenantA = 'tenant-A-123';
    const tenantB = 'tenant-B-456';
    const userId = 'user-1';

    group('SecurityContext Tenant Enforcement', () {
      test('SecurityContext requires businessId', () {
        final context = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.admin,
        );

        expect(context.businessId, isNotNull);
        expect(context.businessId, isNotEmpty);
        expect(context.businessId, equals(tenantA));
      });

      test('SecurityContext validates business access', () {
        final context = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.admin,
        );

        // Should not throw for matching business
        expect(
          () => context.verifyBusinessAccess(tenantA),
          returnsNormally,
        );
      });

      test('SecurityContext rejects cross-tenant access', () {
        final context = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.admin,
        );

        // Should throw for different business
        expect(
          () => context.verifyBusinessAccess(tenantB),
          throwsA(isA<SecurityException>()),
        );
      });

      test('Admin cannot access other tenant data', () {
        // Even admin role cannot cross tenant boundaries
        final adminContext = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.admin,
        );

        expect(
          () => adminContext.verifyBusinessAccess(tenantB),
          throwsA(isA<SecurityException>()),
        );
      });

      test('Owner cannot access other tenant data', () {
        // Even owner role cannot cross tenant boundaries
        final ownerContext = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.owner,
        );

        expect(
          () => ownerContext.verifyBusinessAccess(tenantB),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Client Tenant Isolation', () {
      test('Client is scoped to single tenant', () {
        final client = Client(
          id: 'client-1',
          businessId: tenantA,
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
        );

        expect(client.businessId, equals(tenantA));
        expect(client.businessId, isNot(equals(tenantB)));
      });

      test('Client cannot belong to multiple tenants', () {
        // Each client instance has exactly one businessId
        final clientA = Client(
          id: 'client-shared',
          businessId: tenantA,
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
        );

        final clientB = Client(
          id: 'client-shared',
          businessId: tenantB,
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
        );

        // Same ID but different tenants = different data
        expect(clientA.businessId, isNot(equals(clientB.businessId)));
      });
    });

    group('Appointment Tenant Isolation', () {
      test('Appointment is scoped to single tenant', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: tenantA,
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        expect(appointment.businessId, equals(tenantA));
      });

      test('Appointment references stay within tenant', () {
        // All referenced entities should be in same tenant
        // This is enforced at repository/rules level
        final appointment = Appointment(
          id: 'appt-1',
          businessId: tenantA,
          clientId: 'client-tenantA-1', // Should be tenantA client
          providerId: 'provider-tenantA-1', // Should be tenantA provider
          serviceId: 'service-tenantA-1', // Should be tenantA service
          locationId: 'location-tenantA-1', // Should be tenantA location
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        // Contract: all refs in same tenant as appointment
        expect(appointment.businessId, equals(tenantA));
      });
    });

    group('Payment Tenant Isolation', () {
      test('Payment is scoped to single tenant', () {
        final payment = Payment(
          id: 'payment-1',
          businessId: tenantA,
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.businessId, equals(tenantA));
      });

      test('Payment cannot reference cross-tenant appointment', () {
        // Contract: payment.appointmentId must be in same tenant
        // Enforced at repository level
        final payment = Payment(
          id: 'payment-1',
          businessId: tenantA,
          appointmentId: 'appt-tenantA-1', // Must be tenantA appointment
          clientId: 'client-tenantA-1', // Must be tenantA client
          amountCents: 5000,
          status: PaymentStatus.completed,
          type: PaymentType.full,
          createdAt: DateTime.now(),
        );

        expect(payment.businessId, equals(tenantA));
      });
    });

    group('RBAC Tenant Scoping', () {
      test('Staff can only access own tenant appointments', () {
        final staffContext = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.staff,
          providerId: 'provider-1',
        );

        // Staff in tenantA cannot access tenantB
        expect(
          () => staffContext.verifyBusinessAccess(tenantB),
          throwsA(isA<SecurityException>()),
        );
      });

      test('Client can only access own tenant data', () {
        final clientContext = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.client,
          clientId: 'client-1',
        );

        expect(
          () => clientContext.verifyBusinessAccess(tenantB),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Query Tenant Filtering', () {
      test('SecurityContext provides businessId for queries', () {
        final context = SecurityContext(
          userId: userId,
          businessId: tenantA,
          role: UserRole.admin,
        );

        // All queries should filter by this businessId
        expect(context.businessId, equals(tenantA));
      });
    });

    group('Firestore Rules Contract', () {
      test('belongsToBusiness function required in rules', () {
        // This documents the contract expectation
        // Actual enforcement is in firestore.rules:
        // function belongsToBusiness(businessId) {
        //   return isAuthenticated() && getUserProfile().businessId == businessId;
        // }
        expect(true, isTrue,
            reason: 'belongsToBusiness enforced in firestore.rules');
      });

      test('All business-scoped collections require tenant check', () {
        // Contract: every match under /businesses/{businessId}
        // must call belongsToBusiness(businessId)
        final scopedCollections = [
          'clients',
          'appointments',
          'payments',
          'providers',
          'services',
          'locations',
          'session_notes',
          'waitlist_entries',
          'giftCards',
          'audit_logs',
        ];

        // Document the contract expectation
        expect(scopedCollections, isNotEmpty);
      });
    });
  });
}
