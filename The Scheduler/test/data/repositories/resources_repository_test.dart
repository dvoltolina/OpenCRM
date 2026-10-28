import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/resource.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('ResourcesRepository', () {
    late MockResourcesRepository repository;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockResourcesRepository();
      adminContext = TestData.securityContext(
        userId: 'admin-user',
        businessId: 'test-business',
        role: UserRole.admin,
      );
      staffContext = TestData.securityContext(
        userId: 'staff-user',
        businessId: 'test-business',
        role: UserRole.staff,
        providerId: 'provider-1',
      );
    });

    tearDown(() {
      repository.clear();
    });

    group('upsertResource', () {
      test('creates new resource', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          name: 'Treatment Room 1',
        );

        await repository.upsertResource(
          context: adminContext,
          resource: resource,
        );

        expect(repository.count, 1);
      });

      test('updates existing resource', () async {
        final original = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          name: 'Treatment Room 1',
          capacity: 2,
        );

        await repository.upsertResource(
          context: adminContext,
          resource: original,
        );

        final updated = original.copyWith(capacity: 4);

        await repository.upsertResource(
          context: adminContext,
          resource: updated,
        );

        expect(repository.count, 1);
        final saved = await repository.getResource(
          context: adminContext,
          resourceId: 'resource-1',
        );
        expect(saved?.capacity, 4);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final resource = TestData.resource(businessId: 'different-business');

        expect(
          () => repository.upsertResource(
            context: adminContext,
            resource: resource,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot create resources', () async {
        final resource = TestData.resource(businessId: 'test-business');

        expect(
          () => repository.upsertResource(
            context: staffContext,
            resource: resource,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('getResource', () {
      test('retrieves existing resource', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          name: 'X-Ray Machine',
        );

        await repository.upsertResource(
          context: adminContext,
          resource: resource,
        );

        final retrieved = await repository.getResource(
          context: adminContext,
          resourceId: 'resource-1',
        );

        expect(retrieved, isNotNull);
        expect(retrieved?.name, 'X-Ray Machine');
      });

      test('returns null for non-existent resource', () async {
        final retrieved = await repository.getResource(
          context: adminContext,
          resourceId: 'non-existent',
        );

        expect(retrieved, isNull);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
        );

        repository.addResource(resource);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.getResource(
            context: otherBusinessContext,
            resourceId: 'resource-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('watchResources', () {
      test('returns stream of all resources', () async {
        final resource1 = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );
        final resource2 = TestData.resource(
          id: 'resource-2',
          businessId: 'test-business',
          locationId: 'location-1',
        );

        repository.addResource(resource1);
        repository.addResource(resource2);

        final stream = repository.watchResources(adminContext);

        expect(await stream.first, hasLength(2));
      });

      test('filters by business ID', () async {
        final resource1 = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );
        final resource2 = TestData.resource(
          id: 'resource-2',
          businessId: 'other-business',
          locationId: 'location-1',
        );

        repository.addResource(resource1);
        repository.addResource(resource2);

        final stream = repository.watchResources(adminContext);

        expect(await stream.first, hasLength(1));
      });

      test('filters by location', () async {
        final location1Resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );
        final location2Resource = TestData.resource(
          id: 'resource-2',
          businessId: 'test-business',
          locationId: 'location-2',
        );

        repository.addResource(location1Resource);
        repository.addResource(location2Resource);

        final stream = repository.watchResourcesByLocation(
          context: adminContext,
          locationId: 'location-1',
        );

        final resources = await stream.first;
        expect(resources, hasLength(1));
        expect(resources.first.locationId, 'location-1');
      });

      test('staff can view all resources', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );

        repository.addResource(resource);

        final stream = repository.watchResources(staffContext);

        expect(await stream.first, hasLength(1));
      });
    });

    group('deleteResource', () {
      test('deletes existing resource', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );

        repository.addResource(resource);
        expect(repository.count, 1);

        await repository.deleteResource(
          context: adminContext,
          resourceId: 'resource-1',
        );

        expect(repository.count, 0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );

        repository.addResource(resource);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.deleteResource(
            context: otherBusinessContext,
            resourceId: 'resource-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot delete resources', () async {
        final resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          locationId: 'location-1',
        );

        repository.addResource(resource);

        expect(
          () => repository.deleteResource(
            context: staffContext,
            resourceId: 'resource-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Multi-Tenant Isolation', () {
      test('resources from different businesses are isolated', () async {
        final business1Resource = TestData.resource(
          id: 'resource-1',
          businessId: 'business-1',
          locationId: 'location-1',
        );
        final business2Resource = TestData.resource(
          id: 'resource-2',
          businessId: 'business-2',
          locationId: 'location-1',
        );

        repository.addResource(business1Resource);
        repository.addResource(business2Resource);

        final business1Context = TestData.securityContext(
          businessId: 'business-1',
          role: UserRole.admin,
        );

        final stream = repository.watchResources(business1Context);
        final resources = await stream.first;

        expect(resources, hasLength(1));
        expect(resources.first.businessId, 'business-1');
      });
    });

    group('Real-World Scenarios', () {
      test('dental clinic resources', () async {
        final resources = [
          TestData.resource(
            id: 'resource-1',
            businessId: 'dental-clinic',
            name: 'Treatment Room 1',
            type: ResourceType.room,
            locationId: 'location-1',
            capacity: 2,
            isActive: true,
          ),
          TestData.resource(
            id: 'resource-2',
            businessId: 'dental-clinic',
            name: 'Treatment Room 2',
            type: ResourceType.room,
            locationId: 'location-1',
            capacity: 2,
            isActive: true,
          ),
          TestData.resource(
            id: 'resource-3',
            businessId: 'dental-clinic',
            name: 'X-Ray Machine',
            type: ResourceType.equipment,
            locationId: 'location-1',
            capacity: 1,
            isActive: true,
          ),
        ];

        for (final resource in resources) {
          repository.addResource(resource);
        }

        final context = TestData.securityContext(
          businessId: 'dental-clinic',
          role: UserRole.admin,
        );

        final stream = repository.watchResourcesByLocation(
          context: context,
          locationId: 'location-1',
        );
        final retrieved = await stream.first;

        expect(retrieved, hasLength(3));
      });

      test('resource deactivation for maintenance', () async {
        var resource = TestData.resource(
          id: 'resource-1',
          businessId: 'test-business',
          name: 'MRI Machine',
          type: ResourceType.equipment,
          locationId: 'location-1',
          isActive: true,
        );

        await repository.upsertResource(
          context: adminContext,
          resource: resource,
        );

        // Deactivate for maintenance
        resource = resource.copyWith(isActive: false);
        await repository.upsertResource(
          context: adminContext,
          resource: resource,
        );

        final updated = await repository.getResource(
          context: adminContext,
          resourceId: 'resource-1',
        );

        expect(updated?.isActive, false);
      });

      test('multi-location resources', () async {
        final location1Resources = [
          TestData.resource(
            id: 'resource-1',
            businessId: 'multi-loc-clinic',
            name: 'Room A',
            type: ResourceType.room,
            locationId: 'location-1',
          ),
          TestData.resource(
            id: 'resource-2',
            businessId: 'multi-loc-clinic',
            name: 'Room B',
            type: ResourceType.room,
            locationId: 'location-1',
          ),
        ];

        final location2Resources = [
          TestData.resource(
            id: 'resource-3',
            businessId: 'multi-loc-clinic',
            name: 'Room C',
            type: ResourceType.room,
            locationId: 'location-2',
          ),
        ];

        for (final resource in [...location1Resources, ...location2Resources]) {
          repository.addResource(resource);
        }

        final context = TestData.securityContext(
          businessId: 'multi-loc-clinic',
          role: UserRole.admin,
        );

        // Location 1 resources
        final loc1Stream = repository.watchResourcesByLocation(
          context: context,
          locationId: 'location-1',
        );
        expect(await loc1Stream.first, hasLength(2));

        // Location 2 resources
        final loc2Stream = repository.watchResourcesByLocation(
          context: context,
          locationId: 'location-2',
        );
        expect(await loc2Stream.first, hasLength(1));
      });
    });
  });
}
