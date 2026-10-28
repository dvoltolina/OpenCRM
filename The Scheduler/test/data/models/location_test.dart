import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/location.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Location Model', () {
    group('JSON Serialization', () {
      test('creates location from JSON', () {
        final json = {
          'id': 'location-123',
          'businessId': 'business-456',
          'name': 'Main Office',
          'address': '123 Main St',
          'city': 'Springfield',
          'state': 'IL',
          'zipCode': '62701',
          'phone': '555-123-4567',
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final location = Location.fromJson(json);

        expect(location.id, 'location-123');
        expect(location.businessId, 'business-456');
        expect(location.name, 'Main Office');
        expect(location.address, '123 Main St');
        expect(location.city, 'Springfield');
        expect(location.state, 'IL');
        expect(location.zipCode, '62701');
        expect(location.phone, '555-123-4567');
      });

      test('converts location to JSON', () {
        final location = TestData.location(
          id: 'location-123',
          businessId: 'business-456',
          name: 'Test Location',
        );

        final json = location.toJson();

        expect(json['id'], 'location-123');
        expect(json['businessId'], 'business-456');
        expect(json['name'], 'Test Location');
        expect(json.containsKey('address'), true);
        expect(json.containsKey('city'), true);
        expect(json.containsKey('state'), true);
        expect(json.containsKey('zipCode'), true);
      });

      test('handles null optional fields', () {
        final location = Location(
          id: 'location-1',
          businessId: 'business-1',
          address: '123 Test St',
          city: 'Testville',
          state: 'TS',
          zipCode: '12345',
          createdAt: DateTime.now(),
        );

        final json = location.toJson();
        final deserialized = Location.fromJson(json);

        expect(deserialized.name, null);
        expect(deserialized.phone, null);
      });
    });

    group('copyWith', () {
      test('copies with new address', () {
        final original = TestData.location(
          address: '123 Old St',
          city: 'Oldtown',
        );

        final updated = original.copyWith(
          address: '456 New Ave',
          city: 'Newtown',
        );

        expect(updated.address, '456 New Ave');
        expect(updated.city, 'Newtown');
        expect(updated.id, original.id);
      });

      test('copies with new phone', () {
        final original = TestData.location(phone: '555-111-1111');

        final updated = original.copyWith(phone: '555-222-2222');

        expect(updated.phone, '555-222-2222');
        expect(updated.id, original.id);
      });

      test('copies with new name', () {
        final original = TestData.location(name: 'Old Branch');

        final updated = original.copyWith(name: 'New Branch');

        expect(updated.name, 'New Branch');
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.location();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.name, original.name);
        expect(copy.address, original.address);
        expect(copy.city, original.city);
        expect(copy.state, original.state);
        expect(copy.zipCode, original.zipCode);
        expect(copy.phone, original.phone);
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Location = TestData.location(businessId: 'business-1');
        final business2Location = TestData.location(businessId: 'business-2');

        expect(business1Location.businessId, 'business-1');
        expect(business2Location.businessId, 'business-2');
        expect(
          business1Location.businessId,
          isNot(equals(business2Location.businessId)),
        );
      });

      test('business can have multiple locations', () {
        final locations = [
          Location(
            id: 'loc-1',
            businessId: 'business-1',
            name: 'Main Office',
            address: '123 Main St',
            city: 'Downtown',
            state: 'CA',
            zipCode: '90001',
            createdAt: DateTime.now(),
          ),
          Location(
            id: 'loc-2',
            businessId: 'business-1',
            name: 'North Branch',
            address: '456 North Ave',
            city: 'Uptown',
            state: 'CA',
            zipCode: '90002',
            createdAt: DateTime.now(),
          ),
          Location(
            id: 'loc-3',
            businessId: 'business-1',
            name: 'South Branch',
            address: '789 South Blvd',
            city: 'Southside',
            state: 'CA',
            zipCode: '90003',
            createdAt: DateTime.now(),
          ),
        ];

        // All locations belong to same business
        expect(locations.every((l) => l.businessId == 'business-1'), true);

        // But each has unique ID and address
        final ids = locations.map((l) => l.id).toSet();
        expect(ids.length, 3);
      });
    });

    group('Address Formatting', () {
      test('full US address components', () {
        final location = Location(
          id: 'loc-1',
          businessId: 'business-1',
          name: 'Headquarters',
          address: '1600 Pennsylvania Avenue NW',
          city: 'Washington',
          state: 'DC',
          zipCode: '20500',
          phone: '202-555-0111',
          createdAt: DateTime.now(),
        );

        // Verify all address components
        expect(location.address, '1600 Pennsylvania Avenue NW');
        expect(location.city, 'Washington');
        expect(location.state, 'DC');
        expect(location.zipCode, '20500');

        // Could format as: "1600 Pennsylvania Avenue NW, Washington, DC 20500"
        final fullAddress =
            '${location.address}, ${location.city}, ${location.state} ${location.zipCode}';
        expect(
          fullAddress,
          '1600 Pennsylvania Avenue NW, Washington, DC 20500',
        );
      });

      test('various state abbreviations', () {
        final states = ['CA', 'NY', 'TX', 'FL', 'IL', 'PA'];

        for (final state in states) {
          final location = Location(
            id: 'loc-$state',
            businessId: 'business-1',
            address: '123 Test St',
            city: 'Test City',
            state: state,
            zipCode: '12345',
            createdAt: DateTime.now(),
          );

          expect(location.state, state);
          expect(location.state.length, 2); // State abbreviations are 2 chars
        }
      });

      test('various zip code formats', () {
        final zipCodes = ['12345', '12345-6789', '90210', '02134'];

        for (final zip in zipCodes) {
          final location = Location(
            id: 'loc-$zip',
            businessId: 'business-1',
            address: '123 Test St',
            city: 'Test City',
            state: 'CA',
            zipCode: zip,
            createdAt: DateTime.now(),
          );

          expect(location.zipCode, zip);
        }
      });
    });

    group('Test Data Factory', () {
      test('creates location with defaults', () {
        final location = TestData.location();

        expect(location.id, isNotEmpty);
        expect(location.businessId, isNotEmpty);
        expect(location.address, isNotEmpty);
        expect(location.city, isNotEmpty);
        expect(location.state, isNotEmpty);
        expect(location.zipCode, isNotEmpty);
      });

      test('creates location with custom values', () {
        final location = TestData.location(
          id: 'custom-id',
          businessId: 'custom-business',
          name: 'Custom Office',
          address: '789 Custom Rd',
          city: 'CustomCity',
          state: 'CC',
          zipCode: '99999',
        );

        expect(location.id, 'custom-id');
        expect(location.businessId, 'custom-business');
        expect(location.name, 'Custom Office');
        expect(location.address, '789 Custom Rd');
        expect(location.city, 'CustomCity');
        expect(location.state, 'CC');
        expect(location.zipCode, '99999');
      });
    });

    group('Real-World Location Examples', () {
      test('dental clinic main office', () {
        final mainOffice = Location(
          id: 'dental-main',
          businessId: 'dental-clinic-1',
          name: 'Main Office',
          address: '456 Dental Drive',
          city: 'San Francisco',
          state: 'CA',
          zipCode: '94102',
          phone: '415-555-DENT',
          createdAt: DateTime.now(),
        );

        expect(mainOffice.name, 'Main Office');
        expect(mainOffice.city, 'San Francisco');
        expect(mainOffice.state, 'CA');
      });

      test('therapy practice with multiple locations', () {
        final locations = [
          Location(
            id: 'therapy-downtown',
            businessId: 'therapy-practice-1',
            name: 'Downtown Office',
            address: '100 Market St, Suite 500',
            city: 'Seattle',
            state: 'WA',
            zipCode: '98101',
            phone: '206-555-0001',
            createdAt: DateTime.now(),
          ),
          Location(
            id: 'therapy-bellevue',
            businessId: 'therapy-practice-1',
            name: 'Bellevue Office',
            address: '200 Bellevue Way NE',
            city: 'Bellevue',
            state: 'WA',
            zipCode: '98004',
            phone: '425-555-0002',
            createdAt: DateTime.now(),
          ),
        ];

        expect(locations.length, 2);
        expect(
          locations.every((l) => l.businessId == 'therapy-practice-1'),
          true,
        );
        expect(locations[0].city, 'Seattle');
        expect(locations[1].city, 'Bellevue');
      });

      test('real estate office locations', () {
        final realtyOffice = Location(
          id: 'realty-1',
          businessId: 'realty-firm-1',
          name: 'Premium Realty - Beverly Hills',
          address: '9255 Sunset Boulevard',
          city: 'Los Angeles',
          state: 'CA',
          zipCode: '90069',
          phone: '310-555-HOME',
          createdAt: DateTime.now(),
        );

        expect(realtyOffice.name, contains('Beverly Hills'));
        expect(realtyOffice.city, 'Los Angeles');
      });

      test('location without name (address-only)', () {
        final location = Location(
          id: 'loc-1',
          businessId: 'business-1',
          address: '123 Medical Plaza',
          city: 'Austin',
          state: 'TX',
          zipCode: '78701',
          createdAt: DateTime.now(),
        );

        // Name is optional - address can serve as identifier
        expect(location.name, null);
        expect(location.address, isNotEmpty);
      });

      test('mobile service without physical location', () {
        final mobileService = Location(
          id: 'mobile-1',
          businessId: 'mobile-service-1',
          name: 'Mobile Massage - Service Area: Downtown',
          address: 'Mobile Service - No Fixed Address',
          city: 'Various',
          state: 'CA',
          zipCode: '90000',
          phone: '555-MOBILE',
          createdAt: DateTime.now(),
        );

        expect(mobileService.name, contains('Mobile'));
        expect(mobileService.address, contains('Mobile Service'));
      });
    });

    group('Location Validation Scenarios', () {
      test('validates required fields', () {
        // All required fields must be present
        expect(
          () => Location(
            id: 'loc-1',
            businessId: 'business-1',
            address: '123 Test St',
            city: 'Test City',
            state: 'CA',
            zipCode: '12345',
            createdAt: DateTime.now(),
          ),
          returnsNormally,
        );
      });

      test('handles suite/apartment numbers in address', () {
        final locations = [
          TestData.location(address: '123 Main St, Suite 100'),
          TestData.location(address: '456 Oak Ave, Apt 5B'),
          TestData.location(address: '789 Elm Rd, Floor 3'),
        ];

        for (final location in locations) {
          expect(location.address, contains(','));
        }
      });

      test('international-style addresses', () {
        // While model is US-centric, it can handle various formats
        final locations = [
          TestData.location(address: '123 Main Street'),
          TestData.location(address: '456 Oak Avenue'),
          TestData.location(address: '789 Elm Boulevard'),
          TestData.location(address: '101 Pine Court'),
        ];

        expect(locations.length, 4);
        for (final location in locations) {
          expect(location.address, isNotEmpty);
        }
      });
    });
  });
}
