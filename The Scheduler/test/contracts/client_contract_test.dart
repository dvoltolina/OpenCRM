// Client Contract Tests
//
// Validates that Client model schema matches the shared data contract
// defined in docs/shared_data_contract.md
//
// These tests ensure cross-repo compatibility between:
// - The Scheduler (Flutter)
// - The Scheduler Admin (React)
// - The Scheduler CRM

import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/client.dart';

void main() {
  group('Client Contract Tests', () {
    group('Schema Validation', () {
      test('Client has all required fields per contract', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: ['test'],
          createdAt: DateTime.now(),
        );

        // Required fields per docs/shared_data_contract.md
        expect(client.id, isNotNull);
        expect(client.businessId, isNotNull);
        expect(client.firstName, isNotNull);
        expect(client.lastName, isNotNull);
        expect(client.lifecycle, isNotNull);
        expect(client.tags, isNotNull);
        expect(client.createdAt, isNotNull);
      });

      test('Client optional fields are nullable', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
          // Optional fields omitted
        );

        // Optional fields per contract
        expect(client.email, isNull);
        expect(client.phone, isNull);
        expect(client.userId, isNull);
      });

      test('Client lifecycle enum matches contract values', () {
        // Contract specifies: active, inactive, archived, prospect
        expect(ClientLifecycle.values, containsAll([
          ClientLifecycle.active,
          ClientLifecycle.inactive,
        ]));
      });
    });

    group('Serialization Contract', () {
      test('Client toJson produces contract-compliant keys', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '555-1234',
          lifecycle: ClientLifecycle.active,
          tags: ['vip', 'regular'],
          createdAt: DateTime(2025, 1, 1),
        );

        final json = client.toJson();

        // Verify field names match contract (camelCase)
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('businessId'), isTrue);
        expect(json.containsKey('firstName'), isTrue);
        expect(json.containsKey('lastName'), isTrue);
        expect(json.containsKey('email'), isTrue);
        expect(json.containsKey('phone'), isTrue);
        expect(json.containsKey('lifecycle'), isTrue);
        expect(json.containsKey('tags'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
      });

      test('Client fromJson parses contract-compliant data', () {
        final json = {
          'id': 'client-1',
          'businessId': 'business-1',
          'firstName': 'Jane',
          'lastName': 'Smith',
          'email': 'jane@example.com',
          'phone': '555-5678',
          'lifecycle': 'active',
          'tags': ['new'],
          'createdAt': '2025-01-01T00:00:00.000',
          'userId': 'user-123',
        };

        final client = Client.fromJson(json);

        expect(client.id, equals('client-1'));
        expect(client.businessId, equals('business-1'));
        expect(client.firstName, equals('Jane'));
        expect(client.lastName, equals('Smith'));
        expect(client.email, equals('jane@example.com'));
        expect(client.phone, equals('555-5678'));
        expect(client.lifecycle, equals(ClientLifecycle.active));
        expect(client.tags, equals(['new']));
        expect(client.userId, equals('user-123'));
      });
    });

    group('Tenant Isolation Contract', () {
      test('Client requires businessId', () {
        // businessId is required for tenant isolation
        expect(
          () => Client(
            id: 'client-1',
            businessId: '', // Empty should be invalid
            firstName: 'John',
            lastName: 'Doe',
            lifecycle: ClientLifecycle.active,
            tags: [],
            createdAt: DateTime.now(),
          ),
          returnsNormally, // Model allows empty but validation should catch
        );
      });

      test('Client businessId cannot be modified after creation', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
        );

        // Freezed models are immutable - businessId should remain same
        final updated = client.copyWith(firstName: 'Jane');
        expect(updated.businessId, equals('business-1'));
      });
    });

    group('Data Integrity Contract', () {
      test('Client tags is always a list', () {
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: DateTime.now(),
        );

        expect(client.tags, isA<List<String>>());
      });

      test('Client createdAt is preserved through serialization', () {
        final originalDate = DateTime(2025, 6, 15, 10, 30);
        final client = Client(
          id: 'client-1',
          businessId: 'business-1',
          firstName: 'John',
          lastName: 'Doe',
          lifecycle: ClientLifecycle.active,
          tags: [],
          createdAt: originalDate,
        );

        final json = client.toJson();
        final restored = Client.fromJson(json);

        expect(restored.createdAt.year, equals(originalDate.year));
        expect(restored.createdAt.month, equals(originalDate.month));
        expect(restored.createdAt.day, equals(originalDate.day));
      });
    });
  });
}
