import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('ProvidersRepository', () {
    late MockProvidersRepository repository;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockProvidersRepository();
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

    group('upsertProvider', () {
      test('creates new provider', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
          firstName: 'Dr.',
          lastName: 'Smith',
        );

        await repository.upsertProvider(
          context: adminContext,
          provider: provider,
        );

        expect(repository.count, 1);
      });

      test('updates existing provider', () async {
        final original = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
          firstName: 'Dr.',
          lastName: 'Smith',
        );

        await repository.upsertProvider(
          context: adminContext,
          provider: original,
        );

        final updated = original.copyWith(phone: '555-9999');

        await repository.upsertProvider(
          context: adminContext,
          provider: updated,
        );

        expect(repository.count, 1);
        final saved = await repository.getProvider(
          context: adminContext,
          providerId: 'provider-1',
        );
        expect(saved?.phone, '555-9999');
      });

      test('throws SecurityException when businessId mismatch', () async {
        final provider = TestData.provider(businessId: 'different-business');

        expect(
          () => repository.upsertProvider(
            context: adminContext,
            provider: provider,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot create providers', () async {
        final provider = TestData.provider(businessId: 'test-business');

        expect(
          () => repository.upsertProvider(
            context: staffContext,
            provider: provider,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff can update own profile', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
          firstName: 'Dr.',
          lastName: 'Smith',
        );

        repository.addProvider(provider);

        final updated = provider.copyWith(bio: 'Updated bio');

        await repository.upsertProvider(
          context: staffContext,
          provider: updated,
        );

        final saved = await repository.getProvider(
          context: staffContext,
          providerId: 'provider-1',
        );
        expect(saved?.bio, 'Updated bio');
      });
    });

    group('getProvider', () {
      test('retrieves existing provider', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
          firstName: 'Dr.',
          lastName: 'Johnson',
        );

        await repository.upsertProvider(
          context: adminContext,
          provider: provider,
        );

        final retrieved = await repository.getProvider(
          context: adminContext,
          providerId: 'provider-1',
        );

        expect(retrieved, isNotNull);
        expect(retrieved?.fullName, 'Dr. Johnson');
      });

      test('returns null for non-existent provider', () async {
        final retrieved = await repository.getProvider(
          context: adminContext,
          providerId: 'non-existent',
        );

        expect(retrieved, isNull);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );

        repository.addProvider(provider);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.getProvider(
            context: otherBusinessContext,
            providerId: 'provider-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('watchProviders', () {
      test('returns stream of all providers', () async {
        final provider1 = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );
        final provider2 = TestData.provider(
          id: 'provider-2',
          businessId: 'test-business',
        );

        repository.addProvider(provider1);
        repository.addProvider(provider2);

        final stream = repository.watchProviders(adminContext);

        expect(await stream.first, hasLength(2));
      });

      test('filters by business ID', () async {
        final provider1 = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );
        final provider2 = TestData.provider(
          id: 'provider-2',
          businessId: 'other-business',
        );

        repository.addProvider(provider1);
        repository.addProvider(provider2);

        final stream = repository.watchProviders(adminContext);

        expect(await stream.first, hasLength(1));
      });

      test('filters by location', () async {
        final location1Provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
          locationIds: ['location-1'],
        );
        final location2Provider = TestData.provider(
          id: 'provider-2',
          businessId: 'test-business',
          locationIds: ['location-2'],
        );

        repository.addProvider(location1Provider);
        repository.addProvider(location2Provider);

        final stream = repository.watchProviders(
          adminContext,
          locationId: 'location-1',
        );

        final providers = await stream.first;
        expect(providers, hasLength(1));
        expect(providers.first.locationIds, contains('location-1'));
      });
    });

    group('deleteProvider', () {
      test('deletes existing provider', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );

        repository.addProvider(provider);
        expect(repository.count, 1);

        await repository.deleteProvider(
          context: adminContext,
          providerId: 'provider-1',
        );

        expect(repository.count, 0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );

        repository.addProvider(provider);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.deleteProvider(
            context: otherBusinessContext,
            providerId: 'provider-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot delete providers', () async {
        final provider = TestData.provider(
          id: 'provider-1',
          businessId: 'test-business',
        );

        repository.addProvider(provider);

        expect(
          () => repository.deleteProvider(
            context: staffContext,
            providerId: 'provider-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Multi-Tenant Isolation', () {
      test('providers from different businesses are isolated', () async {
        final business1Provider = TestData.provider(
          id: 'provider-1',
          businessId: 'business-1',
        );
        final business2Provider = TestData.provider(
          id: 'provider-2',
          businessId: 'business-2',
        );

        repository.addProvider(business1Provider);
        repository.addProvider(business2Provider);

        final business1Context = TestData.securityContext(
          businessId: 'business-1',
          role: UserRole.admin,
        );

        final stream = repository.watchProviders(business1Context);
        final providers = await stream.first;

        expect(providers, hasLength(1));
        expect(providers.first.businessId, 'business-1');
      });
    });

    group('Real-World Scenarios', () {
      test('dental clinic with multiple dentists', () async {
        final providers = [
          TestData.provider(
            id: 'provider-1',
            businessId: 'dental-clinic',
            firstName: 'Dr.',
            lastName: 'Smith',
            specializations: ['General Dentistry', 'Cosmetic'],
            locationIds: ['location-1'],
          ),
          TestData.provider(
            id: 'provider-2',
            businessId: 'dental-clinic',
            firstName: 'Dr.',
            lastName: 'Johnson',
            specializations: ['Orthodontics'],
            locationIds: ['location-1', 'location-2'],
          ),
          TestData.provider(
            id: 'provider-3',
            businessId: 'dental-clinic',
            firstName: 'Dr.',
            lastName: 'Williams',
            specializations: ['Endodontics'],
            locationIds: ['location-2'],
          ),
        ];

        for (final provider in providers) {
          repository.addProvider(provider);
        }

        final context = TestData.securityContext(
          businessId: 'dental-clinic',
          role: UserRole.admin,
        );

        // All providers
        final allStream = repository.watchProviders(context);
        expect(await allStream.first, hasLength(3));

        // Providers at location 1
        final location1Stream = repository.watchProviders(
          context,
          locationId: 'location-1',
        );
        final location1Providers = await location1Stream.first;
        expect(location1Providers, hasLength(2));
      });
    });
  });
}
