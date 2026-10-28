import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/security_context.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('ServicesRepository', () {
    late MockServicesRepository repository;
    late SecurityContext adminContext;
    late SecurityContext staffContext;

    setUp(() {
      repository = MockServicesRepository();
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

    group('upsertService', () {
      test('creates new service', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Dental Cleaning',
        );

        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        expect(repository.count, 1);
      });

      test('updates existing service', () async {
        final original = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Dental Cleaning',
          price: 100.0,
        );

        await repository.upsertService(
          context: adminContext,
          service: original,
        );

        final updated = original.copyWith(price: 120.0);

        await repository.upsertService(
          context: adminContext,
          service: updated,
        );

        expect(repository.count, 1);
        final saved = await repository.getService(
          context: adminContext,
          serviceId: 'service-1',
        );
        expect(saved?.price, 120.0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final service = TestData.service(businessId: 'different-business');

        expect(
          () => repository.upsertService(
            context: adminContext,
            service: service,
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot create services', () async {
        final service = TestData.service(businessId: 'test-business');

        expect(
          () => repository.upsertService(
            context: staffContext,
            service: service,
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('getService', () {
      test('retrieves existing service', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Root Canal',
          price: 800.0,
        );

        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        final retrieved = await repository.getService(
          context: adminContext,
          serviceId: 'service-1',
        );

        expect(retrieved, isNotNull);
        expect(retrieved?.name, 'Root Canal');
        expect(retrieved?.price, 800.0);
      });

      test('returns null for non-existent service', () async {
        final retrieved = await repository.getService(
          context: adminContext,
          serviceId: 'non-existent',
        );

        expect(retrieved, isNull);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
        );

        repository.addService(service);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.getService(
            context: otherBusinessContext,
            serviceId: 'service-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('watchServices', () {
      test('returns stream of all services', () async {
        final service1 = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Service 1',
        );
        final service2 = TestData.service(
          id: 'service-2',
          businessId: 'test-business',
          name: 'Service 2',
        );

        repository.addService(service1);
        repository.addService(service2);

        final stream = repository.watchServices(adminContext);

        expect(await stream.first, hasLength(2));
      });

      test('filters by business ID', () async {
        final service1 = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
        );
        final service2 = TestData.service(
          id: 'service-2',
          businessId: 'other-business',
        );

        repository.addService(service1);
        repository.addService(service2);

        final stream = repository.watchServices(adminContext);

        expect(await stream.first, hasLength(1));
      });

      test('filters by category', () async {
        final dental = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          category: 'Dental',
        );
        final cosmetic = TestData.service(
          id: 'service-2',
          businessId: 'test-business',
          category: 'Cosmetic',
        );

        repository.addService(dental);
        repository.addService(cosmetic);

        final stream = repository.watchServices(
          adminContext,
          category: 'Dental',
        );

        final services = await stream.first;
        expect(services, hasLength(1));
        expect(services.first.category, 'Dental');
      });

      test('filters by provider', () async {
        final provider1Service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          providerIds: ['provider-1'],
        );
        final provider2Service = TestData.service(
          id: 'service-2',
          businessId: 'test-business',
          providerIds: ['provider-2'],
        );

        repository.addService(provider1Service);
        repository.addService(provider2Service);

        final stream = repository.watchServices(
          adminContext,
          providerId: 'provider-1',
        );

        final services = await stream.first;
        expect(services, hasLength(1));
        expect(services.first.providerIds, contains('provider-1'));
      });
    });

    group('deleteService', () {
      test('deletes existing service', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
        );

        repository.addService(service);
        expect(repository.count, 1);

        await repository.deleteService(
          context: adminContext,
          serviceId: 'service-1',
        );

        expect(repository.count, 0);
      });

      test('throws SecurityException when businessId mismatch', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
        );

        repository.addService(service);

        final otherBusinessContext = TestData.securityContext(
          businessId: 'other-business',
          role: UserRole.admin,
        );

        expect(
          () => repository.deleteService(
            context: otherBusinessContext,
            serviceId: 'service-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });

      test('staff cannot delete services', () async {
        final service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
        );

        repository.addService(service);

        expect(
          () => repository.deleteService(
            context: staffContext,
            serviceId: 'service-1',
          ),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('Multi-Tenant Isolation', () {
      test('services from different businesses are isolated', () async {
        final business1Service = TestData.service(
          id: 'service-1',
          businessId: 'business-1',
        );
        final business2Service = TestData.service(
          id: 'service-2',
          businessId: 'business-2',
        );

        repository.addService(business1Service);
        repository.addService(business2Service);

        final business1Context = TestData.securityContext(
          businessId: 'business-1',
          role: UserRole.admin,
        );

        final stream = repository.watchServices(business1Context);
        final services = await stream.first;

        expect(services, hasLength(1));
        expect(services.first.businessId, 'business-1');
      });
    });

    group('Real-World Scenarios', () {
      test('dental clinic services', () async {
        final services = [
          TestData.service(
            id: 'service-1',
            businessId: 'dental-clinic',
            name: 'Dental Cleaning',
            durationMinutes: 60,
            price: 100.0,
            category: 'Preventive',
            providerIds: ['provider-1', 'provider-2'],
          ),
          TestData.service(
            id: 'service-2',
            businessId: 'dental-clinic',
            name: 'Root Canal',
            durationMinutes: 90,
            price: 800.0,
            category: 'Endodontics',
            providerIds: ['provider-1'],
          ),
          TestData.service(
            id: 'service-3',
            businessId: 'dental-clinic',
            name: 'Teeth Whitening',
            durationMinutes: 60,
            price: 300.0,
            category: 'Cosmetic',
            providerIds: ['provider-2'],
          ),
        ];

        for (final service in services) {
          repository.addService(service);
        }

        final context = TestData.securityContext(
          businessId: 'dental-clinic',
          role: UserRole.admin,
        );

        // All services
        final allStream = repository.watchServices(context);
        expect(await allStream.first, hasLength(3));

        // Preventive services
        final preventiveStream = repository.watchServices(
          context,
          category: 'Preventive',
        );
        expect(await preventiveStream.first, hasLength(1));

        // Provider 1 services
        final provider1Stream = repository.watchServices(
          context,
          providerId: 'provider-1',
        );
        expect(await provider1Stream.first, hasLength(2));
      });

      test('service price update', () async {
        var service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Consultation',
          price: 50.0,
        );

        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        // Price increase
        service = service.copyWith(price: 75.0);
        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        final updated = await repository.getService(
          context: adminContext,
          serviceId: 'service-1',
        );

        expect(updated?.price, 75.0);
      });

      test('service duration update', () async {
        var service = TestData.service(
          id: 'service-1',
          businessId: 'test-business',
          name: 'Therapy Session',
          durationMinutes: 50,
        );

        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        // Extend to 60 minutes
        service = service.copyWith(durationMinutes: 60);
        await repository.upsertService(
          context: adminContext,
          service: service,
        );

        final updated = await repository.getService(
          context: adminContext,
          serviceId: 'service-1',
        );

        expect(updated?.durationMinutes, 60);
      });
    });
  });
}
