import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/service.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Service Model', () {
    group('JSON Serialization', () {
      test('creates service from JSON', () {
        final json = {
          'id': 'service-123',
          'businessId': 'business-456',
          'name': 'Dental Cleaning',
          'durationMinutes': 60,
          'price': 100.0,
          'description': 'Professional dental cleaning',
          'category': 'Preventive Care',
          'providerIds': ['provider-1', 'provider-2'],
          'requiredResources': ['room-1'],
          'bufferMinutes': 10,
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final service = Service.fromJson(json);

        expect(service.id, 'service-123');
        expect(service.businessId, 'business-456');
        expect(service.name, 'Dental Cleaning');
        expect(service.durationMinutes, 60);
        expect(service.price, 100.0);
        expect(service.description, 'Professional dental cleaning');
        expect(service.category, 'Preventive Care');
        expect(service.providerIds, ['provider-1', 'provider-2']);
        expect(service.requiredResources, ['room-1']);
        expect(service.bufferMinutes, 10);
      });

      test('converts service to JSON', () {
        final service = TestData.service(
          id: 'service-123',
          businessId: 'business-456',
          name: 'Test Service',
          durationMinutes: 30,
          price: 50.0,
        );

        final json = service.toJson();

        expect(json['id'], 'service-123');
        expect(json['businessId'], 'business-456');
        expect(json['name'], 'Test Service');
        expect(json['durationMinutes'], 30);
        expect(json['price'], 50.0);
      });

      test('handles null optional fields', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Basic Service',
          durationMinutes: 60,
          price: 100.0,
          createdAt: DateTime.now(),
        );

        final json = service.toJson();
        final deserialized = Service.fromJson(json);

        expect(deserialized.description, null);
        expect(deserialized.category, null);
        expect(deserialized.intakeFormTemplateId, null);
        expect(deserialized.bufferMinutes, null);
        expect(deserialized.updatedAt, null);
        expect(deserialized.providerIds, isEmpty);
        expect(deserialized.requiredResources, isEmpty);
      });

      test('handles lists correctly', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Multi-Provider Service',
          durationMinutes: 60,
          price: 100.0,
          providerIds: ['provider-1', 'provider-2', 'provider-3'],
          requiredResources: ['room-1', 'equipment-1'],
          createdAt: DateTime.now(),
        );

        final json = service.toJson();
        final deserialized = Service.fromJson(json);

        expect(deserialized.providerIds.length, 3);
        expect(deserialized.requiredResources.length, 2);
      });
    });

    group('copyWith', () {
      test('copies with new name and price', () {
        final original = TestData.service(
          name: 'Old Service',
          price: 100.0,
        );

        final updated = original.copyWith(
          name: 'New Service',
          price: 150.0,
        );

        expect(updated.name, 'New Service');
        expect(updated.price, 150.0);
        expect(updated.id, original.id);
      });

      test('copies with new duration', () {
        final original = TestData.service(durationMinutes: 60);

        final updated = original.copyWith(durationMinutes: 90);

        expect(updated.durationMinutes, 90);
        expect(updated.id, original.id);
      });

      test('copies with new category', () {
        final original = TestData.service(category: 'Old Category');

        final updated = original.copyWith(category: 'New Category');

        expect(updated.category, 'New Category');
        expect(updated.id, original.id);
      });

      test('copies with new provider assignments', () {
        final original = TestData.service(
          providerIds: ['provider-1'],
        );

        final updated = original.copyWith(
          providerIds: ['provider-1', 'provider-2', 'provider-3'],
        );

        expect(updated.providerIds.length, 3);
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.service();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.name, original.name);
        expect(copy.durationMinutes, original.durationMinutes);
        expect(copy.price, original.price);
        expect(copy.category, original.category);
      });
    });

    group('Helper Methods', () {
      test('durationDisplay formats hours and minutes', () {
        expect(
          TestData.service(durationMinutes: 90).durationDisplay,
          '1h 30m',
        );
      });

      test('durationDisplay formats hours only', () {
        expect(
          TestData.service(durationMinutes: 120).durationDisplay,
          '2h',
        );
      });

      test('durationDisplay formats minutes only', () {
        expect(
          TestData.service(durationMinutes: 45).durationDisplay,
          '45m',
        );
      });

      test('durationDisplay handles various durations', () {
        expect(
          TestData.service(durationMinutes: 30).durationDisplay,
          '30m',
        );
        expect(
          TestData.service(durationMinutes: 60).durationDisplay,
          '1h',
        );
        expect(
          TestData.service(durationMinutes: 75).durationDisplay,
          '1h 15m',
        );
        expect(
          TestData.service(durationMinutes: 180).durationDisplay,
          '3h',
        );
      });

      test('priceDisplay formats as currency', () {
        expect(
          TestData.service(price: 100.0).priceDisplay,
          '\$100.00',
        );
      });

      test('priceDisplay handles decimals', () {
        expect(
          TestData.service(price: 99.99).priceDisplay,
          '\$99.99',
        );
        expect(
          TestData.service(price: 150.5).priceDisplay,
          '\$150.50',
        );
        expect(
          TestData.service(price: 75.0).priceDisplay,
          '\$75.00',
        );
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Service = TestData.service(businessId: 'business-1');
        final business2Service = TestData.service(businessId: 'business-2');

        expect(business1Service.businessId, 'business-1');
        expect(business2Service.businessId, 'business-2');
        expect(
          business1Service.businessId,
          isNot(equals(business2Service.businessId)),
        );
      });

      test('can be assigned to multiple providers', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Popular Service',
          durationMinutes: 60,
          price: 100.0,
          providerIds: [
            'provider-1',
            'provider-2',
            'provider-3',
            'provider-4',
          ],
          createdAt: DateTime.now(),
        );

        expect(service.providerIds.length, 4);
      });

      test('can require multiple resources', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Complex Procedure',
          durationMinutes: 120,
          price: 500.0,
          requiredResources: [
            'exam-room-1',
            'x-ray-machine',
            'sterilization-equipment',
          ],
          createdAt: DateTime.now(),
        );

        expect(service.requiredResources.length, 3);
        expect(service.requiredResources.contains('x-ray-machine'), true);
      });

      test('buffer time allows scheduling gaps', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Surgery',
          durationMinutes: 90,
          price: 1000.0,
          bufferMinutes: 30, // 30 min cleanup time
          createdAt: DateTime.now(),
        );

        // Total time needed = duration + buffer
        final totalMinutes = service.durationMinutes + (service.bufferMinutes ?? 0);
        expect(totalMinutes, 120); // 90 + 30
      });

      test('can link to intake form template', () {
        final service = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'New Patient Exam',
          durationMinutes: 60,
          price: 150.0,
          intakeFormTemplateId: 'intake-form-123',
          createdAt: DateTime.now(),
        );

        expect(service.intakeFormTemplateId, 'intake-form-123');
      });

      test('categorization helps service organization', () {
        final preventive = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Cleaning',
          durationMinutes: 60,
          price: 100.0,
          category: 'Preventive Care',
          createdAt: DateTime.now(),
        );

        final cosmetic = Service(
          id: 'service-2',
          businessId: 'business-1',
          name: 'Whitening',
          durationMinutes: 90,
          price: 300.0,
          category: 'Cosmetic',
          createdAt: DateTime.now(),
        );

        expect(preventive.category, 'Preventive Care');
        expect(cosmetic.category, 'Cosmetic');
        expect(preventive.category, isNot(equals(cosmetic.category)));
      });
    });

    group('Pricing Scenarios', () {
      test('handles various price ranges', () {
        final basic = TestData.service(price: 50.0);
        final standard = TestData.service(price: 100.0);
        final premium = TestData.service(price: 500.0);

        expect(basic.price, lessThan(standard.price));
        expect(standard.price, lessThan(premium.price));
      });

      test('price can be fractional', () {
        final service = TestData.service(price: 99.95);

        expect(service.price, 99.95);
        expect(service.priceDisplay, '\$99.95');
      });

      test('free services supported', () {
        final freeConsultation = Service(
          id: 'service-1',
          businessId: 'business-1',
          name: 'Free Consultation',
          durationMinutes: 30,
          price: 0.0,
          createdAt: DateTime.now(),
        );

        expect(freeConsultation.price, 0.0);
        expect(freeConsultation.priceDisplay, '\$0.00');
      });
    });

    group('Duration Scenarios', () {
      test('supports various service lengths', () {
        final quick = TestData.service(durationMinutes: 15); // Quick check
        final standard = TestData.service(durationMinutes: 60); // Standard
        final extended = TestData.service(durationMinutes: 120); // Long procedure
        final dayLong = TestData.service(durationMinutes: 480); // 8 hours

        expect(quick.durationDisplay, '15m');
        expect(standard.durationDisplay, '1h');
        expect(extended.durationDisplay, '2h');
        expect(dayLong.durationDisplay, '8h');
      });

      test('unusual durations handled correctly', () {
        final service1 = TestData.service(durationMinutes: 37);
        final service2 = TestData.service(durationMinutes: 105);

        expect(service1.durationDisplay, '37m');
        expect(service2.durationDisplay, '1h 45m');
      });
    });

    group('Test Data Factory', () {
      test('creates service with defaults', () {
        final service = TestData.service();

        expect(service.id, isNotEmpty);
        expect(service.businessId, isNotEmpty);
        expect(service.name, isNotEmpty);
        expect(service.durationMinutes, greaterThan(0));
        expect(service.price, greaterThan(0));
      });

      test('creates service with custom values', () {
        final service = TestData.service(
          id: 'custom-id',
          businessId: 'custom-business',
          name: 'Custom Service',
          durationMinutes: 45,
          price: 75.0,
          category: 'Custom Category',
        );

        expect(service.id, 'custom-id');
        expect(service.businessId, 'custom-business');
        expect(service.name, 'Custom Service');
        expect(service.durationMinutes, 45);
        expect(service.price, 75.0);
        expect(service.category, 'Custom Category');
      });
    });

    group('Real-World Service Examples', () {
      test('dental cleaning service', () {
        final cleaning = Service(
          id: 'service-dental-cleaning',
          businessId: 'dental-clinic-1',
          name: 'Professional Cleaning',
          description: 'Comprehensive dental cleaning and polishing',
          durationMinutes: 60,
          price: 120.0,
          category: 'Preventive Care',
          providerIds: ['hygienist-1', 'hygienist-2'],
          bufferMinutes: 10,
          createdAt: DateTime.now(),
        );

        expect(cleaning.durationDisplay, '1h');
        expect(cleaning.priceDisplay, '\$120.00');
        expect(cleaning.category, 'Preventive Care');
      });

      test('therapy session service', () {
        final therapy = Service(
          id: 'service-therapy',
          businessId: 'therapy-clinic-1',
          name: 'Individual Therapy Session',
          description: '50-minute therapy session',
          durationMinutes: 50,
          price: 150.0,
          category: 'Mental Health',
          providerIds: ['therapist-1'],
          intakeFormTemplateId: 'mental-health-intake',
          bufferMinutes: 10,
          createdAt: DateTime.now(),
        );

        expect(therapy.durationDisplay, '50m');
        expect(therapy.priceDisplay, '\$150.00');
        expect(therapy.intakeFormTemplateId, isNotNull);
      });

      test('real estate showing service', () {
        final showing = Service(
          id: 'service-showing',
          businessId: 'realty-firm-1',
          name: 'Property Showing',
          description: 'In-person property tour',
          durationMinutes: 45,
          price: 0.0, // Free for clients
          category: 'Showings',
          providerIds: ['agent-1', 'agent-2', 'agent-3'],
          bufferMinutes: 15, // Travel time
          createdAt: DateTime.now(),
        );

        expect(showing.price, 0.0);
        expect(showing.bufferMinutes, 15);
        expect(showing.providerIds.length, 3);
      });
    });
  });
}
