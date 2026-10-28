import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/client.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Client Model', () {
    group('JSON Serialization', () {
      test('creates client from JSON', () {
        final json = {
          'id': 'client-123',
          'businessId': 'business-456',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john.doe@example.com',
          'phone': '555-123-4567',
          'tags': ['vip', 'regular'],
          'lifecycle': 'active',
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final client = Client.fromJson(json);

        expect(client.id, 'client-123');
        expect(client.businessId, 'business-456');
        expect(client.firstName, 'John');
        expect(client.lastName, 'Doe');
        expect(client.email, 'john.doe@example.com');
        expect(client.phone, '555-123-4567');
        expect(client.tags, ['vip', 'regular']);
        expect(client.lifecycle, ClientLifecycle.active);
      });

      test('converts client to JSON', () {
        final client = TestData.client(
          id: 'client-123',
          businessId: 'business-456',
          firstName: 'Jane',
          lastName: 'Smith',
        );

        final json = client.toJson();

        expect(json['id'], 'client-123');
        expect(json['businessId'], 'business-456');
        expect(json['firstName'], 'Jane');
        expect(json['lastName'], 'Smith');
      });

      test('handles all lifecycle states', () {
        for (final lifecycle in ClientLifecycle.values) {
          final client = TestData.client(lifecycle: lifecycle);
          final json = client.toJson();
          final deserialized = Client.fromJson(json);

          expect(deserialized.lifecycle, lifecycle);
        }
      });

      test('handles null optional fields', () {
        final client = TestData.client(
          email: null,
          phone: null,
          tags: [],
        );

        final json = client.toJson();
        final deserialized = Client.fromJson(json);

        expect(deserialized.email, null);
        expect(deserialized.phone, null);
        expect(deserialized.tags, isEmpty);
        expect(deserialized.address, null);
        expect(deserialized.birthDate, null);
        expect(deserialized.notes, null);
      });

      test('handles tags and custom fields', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Client',
          tags: ['vip', 'premium', 'regular'],
          customFields: {
            'referralSource': 'Google',
            'preferredTime': 'morning',
          },
          createdAt: DateTime.now(),
        );

        final json = client.toJson();
        final deserialized = Client.fromJson(json);

        expect(deserialized.tags, ['vip', 'premium', 'regular']);
        expect(deserialized.customFields['referralSource'], 'Google');
        expect(deserialized.customFields['preferredTime'], 'morning');
      });
    });

    group('copyWith', () {
      test('copies with new lifecycle', () {
        final original = TestData.client(lifecycle: ClientLifecycle.newClient);

        final updated = original.copyWith(lifecycle: ClientLifecycle.active);

        expect(updated.lifecycle, ClientLifecycle.active);
        expect(updated.id, original.id);
        expect(updated.firstName, original.firstName);
      });

      test('copies with new contact information', () {
        final original = TestData.client(
          email: 'old@example.com',
          phone: '555-111-1111',
        );

        final updated = original.copyWith(
          email: 'new@example.com',
          phone: '555-222-2222',
        );

        expect(updated.email, 'new@example.com');
        expect(updated.phone, '555-222-2222');
        expect(updated.id, original.id);
      });

      test('copies with new tags', () {
        final original = TestData.client(tags: ['old-tag']);

        final updated = original.copyWith(
          tags: ['new-tag', 'another-tag'],
        );

        expect(updated.tags, ['new-tag', 'another-tag']);
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.client();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.firstName, original.firstName);
        expect(copy.lastName, original.lastName);
        expect(copy.email, original.email);
        expect(copy.phone, original.phone);
        expect(copy.lifecycle, original.lifecycle);
      });
    });

    group('Helper Methods', () {
      test('fullName combines first and last name', () {
        final client = TestData.client(
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(client.fullName, 'John Doe');
      });

      test('initials returns first letter of each name', () {
        final client = TestData.client(
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(client.initials, 'JD');
      });

      test('initials handles single letter names', () {
        final client = TestData.client(
          firstName: 'A',
          lastName: 'B',
        );

        expect(client.initials, 'AB');
      });

      test('hasEmail returns true when email exists', () {
        final withEmail = TestData.client(email: 'test@example.com');
        final withoutEmail = TestData.client(email: null);

        expect(withEmail.hasEmail, true);
        expect(withoutEmail.hasEmail, false);
      });

      test('hasEmail returns false for empty string', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Client',
          email: '',
          createdAt: DateTime.now(),
        );

        expect(client.hasEmail, false);
      });

      test('hasPhone returns true when phone exists', () {
        final withPhone = TestData.client(phone: '555-123-4567');
        final withoutPhone = TestData.client(phone: null);

        expect(withPhone.hasPhone, true);
        expect(withoutPhone.hasPhone, false);
      });

      test('lifecycleDisplay returns correct labels', () {
        expect(
          TestData.client(lifecycle: ClientLifecycle.newClient)
              .lifecycleDisplay,
          'New',
        );
        expect(
          TestData.client(lifecycle: ClientLifecycle.active).lifecycleDisplay,
          'Active',
        );
        expect(
          TestData.client(lifecycle: ClientLifecycle.inactive)
              .lifecycleDisplay,
          'Inactive',
        );
        expect(
          TestData.client(lifecycle: ClientLifecycle.churned).lifecycleDisplay,
          'Churned',
        );
      });
    });

    group('ClientLifecycle enum', () {
      test('has all expected values', () {
        expect(ClientLifecycle.values, [
          ClientLifecycle.newClient,
          ClientLifecycle.active,
          ClientLifecycle.inactive,
          ClientLifecycle.churned,
        ]);
      });

      test('serializes to correct strings', () {
        final client = TestData.client();

        expect(
          client.copyWith(lifecycle: ClientLifecycle.newClient).toJson()['lifecycle'],
          'newClient',
        );
        expect(
          client.copyWith(lifecycle: ClientLifecycle.active).toJson()['lifecycle'],
          'active',
        );
        expect(
          client.copyWith(lifecycle: ClientLifecycle.inactive).toJson()['lifecycle'],
          'inactive',
        );
        expect(
          client.copyWith(lifecycle: ClientLifecycle.churned).toJson()['lifecycle'],
          'churned',
        );
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Client = TestData.client(businessId: 'business-1');
        final business2Client = TestData.client(businessId: 'business-2');

        expect(business1Client.businessId, 'business-1');
        expect(business2Client.businessId, 'business-2');
        expect(
          business1Client.businessId,
          isNot(equals(business2Client.businessId)),
        );
      });

      test('tracks engagement dates', () {
        final now = DateTime.now();
        final lastWeek = now.subtract(const Duration(days: 7));

        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Client',
          lastContactDate: lastWeek,
          lastAppointmentDate: now,
          createdAt: now,
        );

        expect(client.lastContactDate, lastWeek);
        expect(client.lastAppointmentDate, now);
      });

      test('supports custom fields for extensibility', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Client',
          customFields: {
            'insuranceProvider': 'Blue Cross',
            'policyNumber': '12345',
            'emergencyContact': 'Jane Doe',
            'preferredLanguage': 'Spanish',
          },
          createdAt: DateTime.now(),
        );

        expect(client.customFields['insuranceProvider'], 'Blue Cross');
        expect(client.customFields['policyNumber'], '12345');
        expect(client.customFields['emergencyContact'], 'Jane Doe');
        expect(client.customFields['preferredLanguage'], 'Spanish');
      });

      test('supports preferences map', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Client',
          preferences: {
            'emailNotifications': true,
            'smsReminders': false,
            'preferredDays': ['Monday', 'Wednesday'],
          },
          createdAt: DateTime.now(),
        );

        expect(client.preferences['emailNotifications'], true);
        expect(client.preferences['smsReminders'], false);
        expect(client.preferences['preferredDays'], ['Monday', 'Wednesday']);
      });
    });

    group('Test Data Factory', () {
      test('creates client with defaults', () {
        final client = TestData.client();

        expect(client.id, isNotEmpty);
        expect(client.businessId, isNotEmpty);
        expect(client.firstName, isNotEmpty);
        expect(client.lastName, isNotEmpty);
        expect(client.lifecycle, ClientLifecycle.active);
      });

      test('creates client with custom values', () {
        final client = TestData.client(
          id: 'custom-id',
          businessId: 'custom-business',
          firstName: 'Custom',
          lastName: 'Name',
          email: 'custom@example.com',
          lifecycle: ClientLifecycle.inactive,
          tags: ['custom-tag'],
        );

        expect(client.id, 'custom-id');
        expect(client.businessId, 'custom-business');
        expect(client.firstName, 'Custom');
        expect(client.lastName, 'Name');
        expect(client.email, 'custom@example.com');
        expect(client.lifecycle, ClientLifecycle.inactive);
        expect(client.tags, ['custom-tag']);
      });

      test('creates multiple clients', () {
        final clients = TestData.clients(count: 5);

        expect(clients.length, 5);
        expect(clients[0].id, 'client-1');
        expect(clients[4].id, 'client-5');

        // Each should have unique ID
        final ids = clients.map((c) => c.id).toSet();
        expect(ids.length, 5);
      });

      test('creates clients for specific business', () {
        final clients = TestData.clients(
          count: 3,
          businessId: 'specific-business',
        );

        for (final client in clients) {
          expect(client.businessId, 'specific-business');
        }
      });
    });
  });
}
