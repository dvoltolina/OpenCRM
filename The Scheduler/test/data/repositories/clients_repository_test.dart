import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/client.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('ClientsRepository', () {
    late MockClientsRepository repository;
    late SecurityContext adminContext;

    setUp(() {
      repository = MockClientsRepository();
      adminContext = TestData.securityContext(
        userId: 'admin-user',
        businessId: 'test-business',
        role: UserRole.admin,
      );
    });

    tearDown(() {
      repository.clear();
    });

    group('upsertClient', () {
      test('creates new client', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
        );

        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        expect(repository.count, 1);
      });

      test('updates existing client', () async {
        final original = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
          firstName: 'John',
          lastName: 'Doe',
        );

        await repository.upsertClient(
          context: adminContext,
          client: original,
        );

        final updated = original.copyWith(phone: '555-9999');

        await repository.upsertClient(
          context: adminContext,
          client: updated,
        );

        expect(repository.count, 1);
        final saved = await repository.getClient(
          context: adminContext,
          clientId: 'client-1',
        );
        expect(saved?.phone, '555-9999');
      });

      test('throws SecurityException when businessId mismatch', () async {
        final client = TestData.client(
          businessId: 'different-business',
        );

        expect(
          () => repository.upsertClient(
            context: adminContext,
            client: client,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('getClient', () {
      test('retrieves existing client', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
          firstName: 'Jane',
          lastName: 'Smith',
        );

        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        final retrieved = await repository.getClient(
          context: adminContext,
          clientId: 'client-1',
        );

        expect(retrieved, isNotNull);
        expect(retrieved?.firstName, 'Jane');
        expect(retrieved?.lastName, 'Smith');
      });

      test('returns null for non-existent client', () async {
        final retrieved = await repository.getClient(
          context: adminContext,
          clientId: 'non-existent',
        );

        expect(retrieved, isNull);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
        );

        repository.addClient(client);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.getClient(
            context: otherBusinessContext,
            clientId: 'client-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('deleteClient', () {
      test('deletes existing client', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
        );

        repository.addClient(client);
        expect(repository.count, 1);

        await repository.deleteClient(
          context: adminContext,
          clientId: 'client-1',
        );

        expect(repository.count, 0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
        );

        repository.addClient(client);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.deleteClient(
            context: otherBusinessContext,
            clientId: 'client-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Multi-Tenant Isolation', () {
      test('clients from different businesses are isolated', () async {
        final business1Client = TestData.client(
          id: 'client-1',
          businessId: 'business-1',
        );
        final business2Client = TestData.client(
          id: 'client-2',
          businessId: 'business-2',
        );

        repository.addClient(business1Client);
        repository.addClient(business2Client);

        // Both clients are added to repository
        expect(repository.count, 2);

        // Each context should only be able to access their business's clients
        final business1Context = TestData.securityContext(
          businessId: 'business-1',
          role: UserRole.admin,
        );

        final retrieved = await repository.getClient(
          context: business1Context,
          clientId: 'client-1',
        );
        expect(retrieved?.businessId, 'business-1');
      });

      test('cannot access clients from other business', () async {
        final client = TestData.client(
          id: 'client-1',
          businessId: 'business-1',
        );

        repository.addClient(client);

        final business2Context = TestData.securityContext(
          businessId: 'business-2',
          role: UserRole.admin,
        );

        expect(
          () => repository.getClient(
            context: business2Context,
            clientId: 'client-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Batch Operations', () {
      test('handles multiple clients', () async {
        final clients = List.generate(
          100,
          (i) => TestData.client(
            id: 'client-$i',
            businessId: 'test-business',
          ),
        );

        for (final client in clients) {
          repository.addClient(client);
        }

        expect(repository.count, 100);
      });
    });

    group('Real-World Scenarios', () {
      test('new client lifecycle', () async {
        // Create client as new
        var client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '555-0100',
          lifecycle: ClientLifecycle.newClient,
        );

        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        // Convert to active after first appointment
        client = client.copyWith(lifecycle: ClientLifecycle.active);
        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        final updated = await repository.getClient(
          context: adminContext,
          clientId: 'client-1',
        );

        expect(updated?.lifecycle, ClientLifecycle.active);
      });

      test('client becomes inactive', () async {
        var client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
          lifecycle: ClientLifecycle.active,
        );

        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        // Mark as inactive (no appointments for 6+ months)
        client = client.copyWith(lifecycle: ClientLifecycle.inactive);
        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        final updated = await repository.getClient(
          context: adminContext,
          clientId: 'client-1',
        );

        expect(updated?.lifecycle, ClientLifecycle.inactive);
      });

      test('client lifecycle to churned', () async {
        var client = TestData.client(
          id: 'client-1',
          businessId: 'test-business',
          lifecycle: ClientLifecycle.inactive,
        );

        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        // Mark as churned
        client = client.copyWith(lifecycle: ClientLifecycle.churned);
        await repository.upsertClient(
          context: adminContext,
          client: client,
        );

        final updated = await repository.getClient(
          context: adminContext,
          clientId: 'client-1',
        );

        expect(updated?.lifecycle, ClientLifecycle.churned);
      });
    });
  });
}
