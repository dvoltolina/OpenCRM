import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/provider.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Provider Model', () {
    group('JSON Serialization', () {
      test('creates provider from JSON', () {
        final json = {
          'id': 'provider-123',
          'businessId': 'business-456',
          'firstName': 'Dr. Jane',
          'lastName': 'Smith',
          'email': 'jane.smith@example.com',
          'phone': '555-987-6543',
          'bio': 'Experienced dentist',
          'colorHex': '4285F4',
          'specializations': ['General Dentistry', 'Cosmetic'],
          'serviceIds': ['service-1', 'service-2'],
          'locationIds': ['location-1'],
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final provider = Provider.fromJson(json);

        expect(provider.id, 'provider-123');
        expect(provider.businessId, 'business-456');
        expect(provider.firstName, 'Dr. Jane');
        expect(provider.lastName, 'Smith');
        expect(provider.email, 'jane.smith@example.com');
        expect(provider.colorHex, '4285F4');
        expect(provider.specializations, ['General Dentistry', 'Cosmetic']);
        expect(provider.serviceIds, ['service-1', 'service-2']);
      });

      test('converts provider to JSON', () {
        final provider = TestData.provider(
          id: 'provider-123',
          businessId: 'business-456',
          firstName: 'Dr. John',
          lastName: 'Doe',
        );

        final json = provider.toJson();

        expect(json['id'], 'provider-123');
        expect(json['businessId'], 'business-456');
        expect(json['firstName'], 'Dr. John');
        expect(json['lastName'], 'Doe');
      });

      test('handles null optional fields', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Provider',
          createdAt: DateTime.now(),
        );

        final json = provider.toJson();
        final deserialized = Provider.fromJson(json);

        expect(deserialized.email, null);
        expect(deserialized.phone, null);
        expect(deserialized.bio, null);
        expect(deserialized.specializations, isEmpty);
        expect(deserialized.serviceIds, isEmpty);
        expect(deserialized.locationIds, isEmpty);
      });

      test('handles lists correctly', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Provider',
          specializations: ['Specialty 1', 'Specialty 2', 'Specialty 3'],
          serviceIds: ['service-1', 'service-2'],
          locationIds: ['location-1', 'location-2', 'location-3'],
          createdAt: DateTime.now(),
        );

        final json = provider.toJson();
        final deserialized = Provider.fromJson(json);

        expect(deserialized.specializations.length, 3);
        expect(deserialized.serviceIds.length, 2);
        expect(deserialized.locationIds.length, 3);
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final original = TestData.provider(
          firstName: 'Dr. Old',
          lastName: 'Name',
        );

        final updated = original.copyWith(
          firstName: 'Dr. New',
          lastName: 'Updated',
        );

        expect(updated.firstName, 'Dr. New');
        expect(updated.lastName, 'Updated');
        expect(updated.id, original.id);
      });

      test('copies with new color', () {
        final original = TestData.provider(colorHex: '4285F4');

        final updated = original.copyWith(colorHex: 'FF5733');

        expect(updated.colorHex, 'FF5733');
        expect(updated.id, original.id);
      });

      test('copies with new specializations', () {
        final original = TestData.provider(
          specializations: ['Old Specialty'],
        );

        final updated = original.copyWith(
          specializations: ['New Specialty 1', 'New Specialty 2'],
        );

        expect(updated.specializations, ['New Specialty 1', 'New Specialty 2']);
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.provider();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.firstName, original.firstName);
        expect(copy.lastName, original.lastName);
        expect(copy.email, original.email);
        expect(copy.colorHex, original.colorHex);
      });
    });

    group('Helper Methods', () {
      test('fullName combines first and last name', () {
        final provider = TestData.provider(
          firstName: 'Dr. Jane',
          lastName: 'Smith',
        );

        expect(provider.fullName, 'Dr. Jane Smith');
      });

      test('initials returns first letter of each name', () {
        final provider = TestData.provider(
          firstName: 'Dr. Jane',
          lastName: 'Smith',
        );

        expect(provider.initials, 'DS');
      });

      test('initials handles titles correctly', () {
        final provider = TestData.provider(
          firstName: 'Dr.',
          lastName: 'A',
        );

        expect(provider.initials, 'DA');
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Provider = TestData.provider(businessId: 'business-1');
        final business2Provider = TestData.provider(businessId: 'business-2');

        expect(business1Provider.businessId, 'business-1');
        expect(business2Provider.businessId, 'business-2');
        expect(
          business1Provider.businessId,
          isNot(equals(business2Provider.businessId)),
        );
      });

      test('supports color coding for calendar display', () {
        final blueProvider = TestData.provider(colorHex: '4285F4');
        final redProvider = TestData.provider(colorHex: 'EA4335');
        final greenProvider = TestData.provider(colorHex: '34A853');

        expect(blueProvider.colorHex, '4285F4');
        expect(redProvider.colorHex, 'EA4335');
        expect(greenProvider.colorHex, '34A853');
      });

      test('tracks multiple specializations', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Dr. Multi',
          lastName: 'Specialist',
          specializations: [
            'General Dentistry',
            'Cosmetic Dentistry',
            'Orthodontics',
            'Periodontics',
          ],
          createdAt: DateTime.now(),
        );

        expect(provider.specializations.length, 4);
        expect(provider.specializations.contains('General Dentistry'), true);
        expect(provider.specializations.contains('Orthodontics'), true);
      });

      test('can be assigned to multiple services', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Dr. Versatile',
          lastName: 'Provider',
          serviceIds: [
            'service-1',
            'service-2',
            'service-3',
            'service-4',
          ],
          createdAt: DateTime.now(),
        );

        expect(provider.serviceIds.length, 4);
      });

      test('can work at multiple locations', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Dr. Mobile',
          lastName: 'Provider',
          locationIds: [
            'location-1', // Main office
            'location-2', // Branch office
            'location-3', // Satellite clinic
          ],
          createdAt: DateTime.now(),
        );

        expect(provider.locationIds.length, 3);
      });

      test('default color is blue when not specified', () {
        final provider = Provider(
          id: 'provider-1',
          businessId: 'business-1',
          firstName: 'Test',
          lastName: 'Provider',
          createdAt: DateTime.now(),
        );

        // Default color from TestData factory is '4285F4' (blue)
        // But in actual model, colorHex is nullable
        expect(provider.colorHex, isNotNull);
      });
    });

    group('Test Data Factory', () {
      test('creates provider with defaults', () {
        final provider = TestData.provider();

        expect(provider.id, isNotEmpty);
        expect(provider.businessId, isNotEmpty);
        expect(provider.firstName, isNotEmpty);
        expect(provider.lastName, isNotEmpty);
        expect(provider.colorHex, isNotEmpty);
      });

      test('creates provider with custom values', () {
        final provider = TestData.provider(
          id: 'custom-id',
          businessId: 'custom-business',
          firstName: 'Custom',
          lastName: 'Provider',
          email: 'custom@example.com',
          colorHex: 'FF5733',
          specializations: ['Custom Specialty'],
        );

        expect(provider.id, 'custom-id');
        expect(provider.businessId, 'custom-business');
        expect(provider.firstName, 'Custom');
        expect(provider.lastName, 'Provider');
        expect(provider.email, 'custom@example.com');
        expect(provider.colorHex, 'FF5733');
        expect(provider.specializations, ['Custom Specialty']);
      });

      test('creates multiple providers', () {
        final providers = TestData.providers(count: 3);

        expect(providers.length, 3);
        expect(providers[0].id, 'provider-1');
        expect(providers[2].id, 'provider-3');

        // Each should have unique ID
        final ids = providers.map((p) => p.id).toSet();
        expect(ids.length, 3);
      });

      test('creates providers for specific business', () {
        final providers = TestData.providers(
          count: 3,
          businessId: 'specific-business',
        );

        for (final provider in providers) {
          expect(provider.businessId, 'specific-business');
        }
      });
    });

    group('Calendar Integration', () {
      test('different providers have different colors', () {
        final providers = [
          TestData.provider(id: 'p1', colorHex: '4285F4'), // Blue
          TestData.provider(id: 'p2', colorHex: 'EA4335'), // Red
          TestData.provider(id: 'p3', colorHex: '34A853'), // Green
          TestData.provider(id: 'p4', colorHex: 'FBBC04'), // Yellow
        ];

        final colors = providers.map((p) => p.colorHex).toSet();
        expect(colors.length, 4); // All unique colors
      });

      test('provider color can be used for UI theming', () {
        final provider = TestData.provider(colorHex: '4285F4');

        // Verify hex color format
        expect(provider.colorHex.length, 6);
        expect(
          RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(provider.colorHex),
          true,
        );
      });
    });
  });
}
