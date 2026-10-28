import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/business.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Business Model', () {
    group('JSON Serialization', () {
      test('creates business from JSON', () {
        final json = {
          'id': 'business-1',
          'name': 'Acme Dental Clinic',
          'description': 'Full-service dental practice',
          'contactEmail': 'contact@example.com',
          'contactPhone': '555-0100',
          'createdAt': '2025-12-01T10:00:00.000Z',
        };

        final business = Business.fromJson(json);

        expect(business.id, 'business-1');
        expect(business.name, 'Acme Dental Clinic');
        expect(business.description, 'Full-service dental practice');
        expect(business.contactEmail, 'contact@example.com');
        expect(business.contactPhone, '555-0100');
      });

      test('converts business to JSON', () {
        final business = TestData.business(
          id: 'business-1',
          name: 'Test Clinic',
        );

        final json = business.toJson();

        expect(json['id'], 'business-1');
        expect(json['name'], 'Test Clinic');
        expect(json.containsKey('createdAt'), true);
      });

      test('handles null optional fields', () {
        final business = Business(
          id: 'business-1',
          name: 'Minimal Business',
          createdAt: DateTime(2025, 12, 1),
        );

        expect(business.description, null);
        expect(business.contactEmail, null);
        expect(business.contactPhone, null);
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final business = TestData.business(name: 'Old Name');
        final updated = business.copyWith(name: 'New Name');

        expect(updated.name, 'New Name');
        expect(updated.id, business.id);
      });

      test('copies with contact information', () {
        final business = TestData.business();
        final updated = business.copyWith(
          contactEmail: 'new@example.com',
          contactPhone: '555-9999',
        );

        expect(updated.contactEmail, 'new@example.com');
        expect(updated.contactPhone, '555-9999');
      });

      test('preserves all fields when no changes', () {
        final business = TestData.business(
          id: 'business-1',
          name: 'Test Clinic',
        );
        final copy = business.copyWith();

        expect(copy.id, business.id);
        expect(copy.name, business.name);
        expect(copy.createdAt, business.createdAt);
      });
    });

    group('Real-World Examples', () {
      test('dental clinic', () {
        final clinic = Business(
          id: 'dental-1',
          name: 'Bright Smile Dental',
          description: 'Family dentistry and cosmetic procedures',
          contactEmail: 'info@example.com',
          contactPhone: '555-SMILE',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(clinic.name, 'Bright Smile Dental');
        expect(clinic.description, contains('Family dentistry'));
      });

      test('therapy practice', () {
        final practice = Business(
          id: 'therapy-1',
          name: 'Mindful Therapy Center',
          description: 'Licensed therapists specializing in CBT and EMDR',
          contactEmail: 'contact@example.com',
          contactPhone: '555-1234',
          createdAt: DateTime(2025, 1, 15),
        );

        expect(practice.name, 'Mindful Therapy Center');
        expect(practice.description, contains('CBT'));
      });

      test('medical clinic', () {
        final clinic = Business(
          id: 'medical-1',
          name: 'Downtown Medical Associates',
          description: 'Primary care and urgent care services',
          contactEmail: 'appointments@example.com',
          contactPhone: '555-5678',
          createdAt: DateTime(2025, 2, 1),
        );

        expect(clinic.name, 'Downtown Medical Associates');
        expect(clinic.description, contains('Primary care'));
      });

      test('salon', () {
        final salon = Business(
          id: 'salon-1',
          name: 'Elegance Hair Salon',
          description: 'Hair styling, coloring, and treatments',
          contactEmail: 'book@example.com',
          contactPhone: '555-HAIR',
          createdAt: DateTime(2025, 3, 1),
        );

        expect(salon.name, 'Elegance Hair Salon');
        expect(salon.description, contains('Hair styling'));
      });

      test('consulting firm', () {
        final firm = Business(
          id: 'consulting-1',
          name: 'Strategic Business Consultants',
          description: 'Business strategy and management consulting',
          contactEmail: 'hello@example.com',
          contactPhone: '555-CONSULT',
          createdAt: DateTime(2025, 4, 1),
        );

        expect(firm.name, 'Strategic Business Consultants');
        expect(firm.description, contains('consulting'));
      });
    });

    group('Multi-Tenant Isolation', () {
      test('each business has unique ID', () {
        final business1 = TestData.business(id: 'business-1');
        final business2 = TestData.business(id: 'business-2');

        expect(business1.id, isNot(business2.id));
      });

      test('businesses are independent entities', () {
        final dentalClinic = Business(
          id: 'dental-1',
          name: 'Dental Clinic',
          contactEmail: 'dental@example.com',
          createdAt: DateTime(2025, 1, 1),
        );

        final therapyCenter = Business(
          id: 'therapy-1',
          name: 'Therapy Center',
          contactEmail: 'therapy@example.com',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(dentalClinic.id, 'dental-1');
        expect(therapyCenter.id, 'therapy-1');
        expect(dentalClinic.contactEmail, isNot(therapyCenter.contactEmail));
      });
    });

    group('Test Data Factory', () {
      test('creates business with defaults', () {
        final business = TestData.business();

        expect(business.id, isNotEmpty);
        expect(business.id, TestData.businessId);
        expect(business.name, isNotEmpty);
        expect(business.createdAt, isNotNull);
      });

      test('creates business with custom values', () {
        final business = TestData.business(
          id: 'custom-business',
          name: 'Custom Clinic',
          contactEmail: 'custom@example.com',
        );

        expect(business.id, 'custom-business');
        expect(business.name, 'Custom Clinic');
        expect(business.contactEmail, 'custom@example.com');
      });
    });
  });
}
