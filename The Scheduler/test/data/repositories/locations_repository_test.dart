import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('LocationsRepository', () {
    late MockLocationsRepository repository;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockLocationsRepository();
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

    group('upsertLocation', () {
      test('creates new location', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
          name: 'Main Office',
        );

        await repository.upsertLocation(
          context: adminContext,
          location: location,
        );

        expect(repository.count, 1);
      });

      test('updates existing location', () async {
        final original = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
          name: 'Main Office',
          address: '123 Main St',
        );

        await repository.upsertLocation(
          context: adminContext,
          location: original,
        );

        final updated = original.copyWith(phone: '555-9999');

        await repository.upsertLocation(
          context: adminContext,
          location: updated,
        );

        expect(repository.count, 1);
        final saved = await repository.getLocation(
          context: adminContext,
          locationId: 'location-1',
        );
        expect(saved?.phone, '555-9999');
      });

      test('throws SecurityException when businessId mismatch', () async {
        final location = TestData.location(businessId: 'different-business');

        expect(
          () => repository.upsertLocation(
            context: adminContext,
            location: location,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot create locations', () async {
        final location = TestData.location(businessId: 'test-business');

        expect(
          () => repository.upsertLocation(
            context: staffContext,
            location: location,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('getLocation', () {
      test('retrieves existing location', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
          name: 'Downtown Office',
        );

        await repository.upsertLocation(
          context: adminContext,
          location: location,
        );

        final retrieved = await repository.getLocation(
          context: adminContext,
          locationId: 'location-1',
        );

        expect(retrieved, isNotNull);
        expect(retrieved?.name, 'Downtown Office');
      });

      test('returns null for non-existent location', () async {
        final retrieved = await repository.getLocation(
          context: adminContext,
          locationId: 'non-existent',
        );

        expect(retrieved, isNull);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );

        repository.addLocation(location);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.getLocation(
            context: otherBusinessContext,
            locationId: 'location-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('watchLocations', () {
      test('returns stream of all locations', () async {
        final location1 = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );
        final location2 = TestData.location(
          id: 'location-2',
          businessId: 'test-business',
        );

        repository.addLocation(location1);
        repository.addLocation(location2);

        final stream = repository.watchLocations(adminContext);

        expect(await stream.first, hasLength(2));
      });

      test('filters by business ID', () async {
        final location1 = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );
        final location2 = TestData.location(
          id: 'location-2',
          businessId: 'other-business',
        );

        repository.addLocation(location1);
        repository.addLocation(location2);

        final stream = repository.watchLocations(adminContext);

        expect(await stream.first, hasLength(1));
      });

      test('staff can view all locations', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );

        repository.addLocation(location);

        final stream = repository.watchLocations(staffContext);

        expect(await stream.first, hasLength(1));
      });
    });

    group('deleteLocation', () {
      test('deletes existing location', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );

        repository.addLocation(location);
        expect(repository.count, 1);

        await repository.deleteLocation(
          context: adminContext,
          locationId: 'location-1',
        );

        expect(repository.count, 0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );

        repository.addLocation(location);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.deleteLocation(
            context: otherBusinessContext,
            locationId: 'location-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot delete locations', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
        );

        repository.addLocation(location);

        expect(
          () => repository.deleteLocation(
            context: staffContext,
            locationId: 'location-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Multi-Tenant Isolation', () {
      test('locations from different businesses are isolated', () async {
        final business1Location = TestData.location(
          id: 'location-1',
          businessId: 'business-1',
        );
        final business2Location = TestData.location(
          id: 'location-2',
          businessId: 'business-2',
        );

        repository.addLocation(business1Location);
        repository.addLocation(business2Location);

        final business1Context = TestData.securityContext(
          businessId: 'business-1',
          role: UserRole.admin,
        );

        final stream = repository.watchLocations(business1Context);
        final locations = await stream.first;

        expect(locations, hasLength(1));
        expect(locations.first.businessId, 'business-1');
      });
    });

    group('Real-World Scenarios', () {
      test('multi-location dental practice', () async {
        final locations = [
          TestData.location(
            id: 'location-1',
            businessId: 'dental-practice',
            name: 'Downtown Office',
            address: '123 Main St',
            city: 'Springfield',
            state: 'IL',
            zipCode: '62701',
            phone: '555-0100',
          ),
          TestData.location(
            id: 'location-2',
            businessId: 'dental-practice',
            name: 'Westside Office',
            address: '456 Oak Ave',
            city: 'Springfield',
            state: 'IL',
            zipCode: '62702',
            phone: '555-0200',
          ),
          TestData.location(
            id: 'location-3',
            businessId: 'dental-practice',
            name: 'Suburban Office',
            address: '789 Elm Dr',
            city: 'Greenfield',
            state: 'IL',
            zipCode: '62703',
            phone: '555-0300',
          ),
        ];

        for (final location in locations) {
          repository.addLocation(location);
        }

        final context = TestData.securityContext(
          businessId: 'dental-practice',
          role: UserRole.admin,
        );

        final stream = repository.watchLocations(context);
        final retrieved = await stream.first;

        expect(retrieved, hasLength(3));
      });

      test('location address update', () async {
        var location = TestData.location(
          id: 'location-1',
          businessId: 'test-business',
          name: 'Main Office',
          address: '123 Old St',
        );

        await repository.upsertLocation(
          context: adminContext,
          location: location,
        );

        // Office moved
        location = location.copyWith(
          address: '456 New St',
          city: 'New City',
          zipCode: '99999',
        );

        await repository.upsertLocation(
          context: adminContext,
          location: location,
        );

        final updated = await repository.getLocation(
          context: adminContext,
          locationId: 'location-1',
        );

        expect(updated?.address, '456 New St');
        expect(updated?.city, 'New City');
        expect(updated?.zipCode, '99999');
      });

      test('single location business', () async {
        final location = TestData.location(
          id: 'location-1',
          businessId: 'small-business',
          name: 'Main Office',
          address: '123 Main St',
          city: 'Smalltown',
          state: 'TX',
          zipCode: '75001',
        );

        repository.addLocation(location);

        final context = TestData.securityContext(
          businessId: 'small-business',
          role: UserRole.admin,
        );

        final stream = repository.watchLocations(context);
        final locations = await stream.first;

        expect(locations, hasLength(1));
        expect(locations.first.name, 'Main Office');
      });
    });
  });
}
