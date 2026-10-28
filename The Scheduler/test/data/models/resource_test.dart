import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/resource.dart';
import '../../helpers/test_data_factories.dart';

void main() {
  group('Resource Model', () {
    group('JSON Serialization', () {
      test('creates resource from JSON', () {
        final json = {
          'id': 'resource-1',
          'businessId': 'business-1',
          'name': 'Treatment Room 1',
          'type': 'room',
          'description': 'Main treatment room with dental chair',
          'locationId': 'location-1',
          'capacity': 2,
          'isActive': true,
          'maintenanceSchedule': ['2025-12-15', '2026-01-15'],
          'createdAt': '2025-12-01T10:00:00.000Z',
          'updatedAt': '2025-12-01T10:00:00.000Z',
        };

        final resource = Resource.fromJson(json);

        expect(resource.id, 'resource-1');
        expect(resource.businessId, 'business-1');
        expect(resource.name, 'Treatment Room 1');
        expect(resource.type, ResourceType.room);
        expect(resource.description, 'Main treatment room with dental chair');
        expect(resource.locationId, 'location-1');
        expect(resource.capacity, 2);
        expect(resource.isActive, true);
        expect(resource.maintenanceSchedule.length, 2);
      });

      test('converts resource to JSON', () {
        final resource = TestData.resource(
          id: 'resource-1',
          name: 'Exam Room 2',
          type: ResourceType.room,
        );

        final json = resource.toJson();

        expect(json['id'], 'resource-1');
        expect(json['name'], 'Exam Room 2');
        expect(json['type'], 'room');
        expect(json['isActive'], true);
        expect(json['capacity'], 1);
      });

      test('handles all resource types', () {
        expect(ResourceType.room.name, 'room');
        expect(ResourceType.equipment.name, 'equipment');
        expect(ResourceType.vehicle.name, 'vehicle');
        expect(ResourceType.other.name, 'other');
      });

      test('handles null optional fields', () {
        final resource = Resource(
          id: 'resource-1',
          businessId: 'business-1',
          name: 'Basic Room',
          type: ResourceType.room,
          locationId: 'location-1',
          createdAt: DateTime(2025, 12, 1),
        );

        expect(resource.description, null);
        expect(resource.updatedAt, null);
        expect(resource.capacity, 1); // default
        expect(resource.isActive, true); // default
        expect(resource.maintenanceSchedule, []); // default
      });
    });

    group('ResourceType enum', () {
      test('displayName returns correct names', () {
        expect(ResourceType.room.displayName, 'Room');
        expect(ResourceType.equipment.displayName, 'Equipment');
        expect(ResourceType.vehicle.displayName, 'Vehicle');
        expect(ResourceType.other.displayName, 'Other');
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final resource = TestData.resource(name: 'Room 1');
        final updated = resource.copyWith(name: 'Room 1A');

        expect(updated.name, 'Room 1A');
        expect(updated.id, resource.id);
        expect(updated.businessId, resource.businessId);
      });

      test('copies with new type', () {
        final resource = TestData.resource(type: ResourceType.room);
        final updated = resource.copyWith(type: ResourceType.equipment);

        expect(updated.type, ResourceType.equipment);
        expect(updated.id, resource.id);
      });

      test('copies with new capacity', () {
        final resource = TestData.resource(capacity: 1);
        final updated = resource.copyWith(capacity: 4);

        expect(updated.capacity, 4);
      });

      test('copies with deactivation', () {
        final resource = TestData.resource(isActive: true);
        final deactivated = resource.copyWith(
          isActive: false,
          updatedAt: DateTime(2025, 12, 15),
        );

        expect(deactivated.isActive, false);
        expect(deactivated.updatedAt, isNotNull);
      });

      test('copies with maintenance schedule', () {
        final resource = TestData.resource();
        final updated = resource.copyWith(
          maintenanceSchedule: ['2025-12-15', '2026-01-15', '2026-02-15'],
        );

        expect(updated.maintenanceSchedule.length, 3);
        expect(updated.maintenanceSchedule.first, '2025-12-15');
      });

      test('preserves all fields when no changes', () {
        final resource = TestData.resource(
          id: 'resource-1',
          name: 'Conference Room',
          capacity: 10,
        );
        final copy = resource.copyWith();

        expect(copy.id, resource.id);
        expect(copy.name, resource.name);
        expect(copy.capacity, resource.capacity);
      });
    });

    group('Helper Methods', () {
      test('capacityDisplay shows singular for 1 person', () {
        final resource = TestData.resource(capacity: 1);
        expect(resource.capacityDisplay, '1 person');
      });

      test('capacityDisplay shows plural for multiple people', () {
        final resource2 = TestData.resource(capacity: 2);
        final resource10 = TestData.resource(capacity: 10);
        final resource100 = TestData.resource(capacity: 100);

        expect(resource2.capacityDisplay, '2 people');
        expect(resource10.capacityDisplay, '10 people');
        expect(resource100.capacityDisplay, '100 people');
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final resource1 = TestData.resource(businessId: 'business-1');
        final resource2 = TestData.resource(businessId: 'business-2');

        expect(resource1.businessId, 'business-1');
        expect(resource2.businessId, 'business-2');
        expect(resource1.businessId, isNot(resource2.businessId));
      });

      test('resources belong to specific location', () {
        final resource = TestData.resource(locationId: 'location-main');
        expect(resource.locationId, 'location-main');
      });

      test('can be deactivated and reactivated', () {
        var resource = TestData.resource(isActive: true);
        expect(resource.isActive, true);

        // Deactivate
        resource = resource.copyWith(isActive: false);
        expect(resource.isActive, false);

        // Reactivate
        resource = resource.copyWith(isActive: true);
        expect(resource.isActive, true);
      });

      test('tracks maintenance schedule', () {
        final resource = Resource(
          id: 'resource-1',
          businessId: 'business-1',
          name: 'X-Ray Machine',
          type: ResourceType.equipment,
          locationId: 'location-1',
          maintenanceSchedule: [
            '2025-12-15',
            '2026-03-15',
            '2026-06-15',
            '2026-09-15',
          ],
          createdAt: DateTime(2025, 12, 1),
        );

        expect(resource.maintenanceSchedule.length, 4);
        expect(resource.maintenanceSchedule.first, '2025-12-15');
        expect(resource.maintenanceSchedule.last, '2026-09-15');
      });
    });

    group('Real-World Examples', () {
      test('dental treatment room', () {
        final treatmentRoom = Resource(
          id: 'room-1',
          businessId: 'dental-clinic-1',
          name: 'Treatment Room 1',
          type: ResourceType.room,
          description: 'Main treatment room with dental chair and equipment',
          locationId: 'location-main',
          capacity: 2, // dentist + patient
          isActive: true,
          createdAt: DateTime(2025, 12, 1),
        );

        expect(treatmentRoom.type, ResourceType.room);
        expect(treatmentRoom.capacity, 2);
        expect(treatmentRoom.capacityDisplay, '2 people');
      });

      test('therapy room', () {
        final therapyRoom = Resource(
          id: 'room-2',
          businessId: 'therapy-center-1',
          name: 'Therapy Room A',
          type: ResourceType.room,
          description: 'Private therapy room with comfortable seating',
          locationId: 'location-main',
          capacity: 3, // therapist + client + optional family member
          isActive: true,
          createdAt: DateTime(2025, 12, 1),
        );

        expect(therapyRoom.type, ResourceType.room);
        expect(therapyRoom.capacity, 3);
        expect(therapyRoom.capacityDisplay, '3 people');
      });

      test('medical equipment', () {
        final ultrasound = Resource(
          id: 'equipment-1',
          businessId: 'medical-clinic-1',
          name: 'Ultrasound Machine',
          type: ResourceType.equipment,
          description: 'Portable ultrasound for diagnostics',
          locationId: 'location-main',
          capacity: 1,
          isActive: true,
          maintenanceSchedule: ['2025-12-15', '2026-06-15', '2026-12-15'],
          createdAt: DateTime(2025, 12, 1),
        );

        expect(ultrasound.type, ResourceType.equipment);
        expect(ultrasound.maintenanceSchedule.length, 3);
      });

      test('conference room', () {
        final conferenceRoom = Resource(
          id: 'room-3',
          businessId: 'office-1',
          name: 'Main Conference Room',
          type: ResourceType.room,
          description: 'Large conference room with video conferencing',
          locationId: 'location-hq',
          capacity: 12,
          isActive: true,
          createdAt: DateTime(2025, 12, 1),
        );

        expect(conferenceRoom.capacity, 12);
        expect(conferenceRoom.capacityDisplay, '12 people');
      });

      test('company vehicle', () {
        final vehicle = Resource(
          id: 'vehicle-1',
          businessId: 'service-company-1',
          name: 'Service Van #1',
          type: ResourceType.vehicle,
          description: 'White cargo van for on-site services',
          locationId: 'location-main',
          capacity: 2, // driver + technician
          isActive: true,
          maintenanceSchedule: ['2025-12-01', '2026-03-01', '2026-06-01'],
          createdAt: DateTime(2025, 12, 1),
        );

        expect(vehicle.type, ResourceType.vehicle);
        expect(vehicle.maintenanceSchedule.length, 3);
      });

      test('inactive equipment under maintenance', () {
        final equipment = Resource(
          id: 'equipment-2',
          businessId: 'clinic-1',
          name: 'MRI Machine',
          type: ResourceType.equipment,
          description: 'Main MRI scanner',
          locationId: 'location-main',
          capacity: 1,
          isActive: false, // Under maintenance
          maintenanceSchedule: ['2025-12-10'],
          createdAt: DateTime(2025, 12, 1),
          updatedAt: DateTime(2025, 12, 8),
        );

        expect(equipment.isActive, false);
        expect(equipment.maintenanceSchedule.first, '2025-12-10');
      });
    });

    group('Test Data Factory', () {
      test('creates resource with defaults', () {
        final resource = TestData.resource();

        expect(resource.id, isNotEmpty);
        expect(resource.businessId, TestData.businessId);
        expect(resource.name, isNotEmpty);
        expect(resource.type, isNotNull);
        expect(resource.locationId, isNotEmpty);
        expect(resource.capacity, greaterThan(0));
        expect(resource.isActive, true);
      });

      test('creates resource with custom values', () {
        final resource = TestData.resource(
          id: 'custom-resource',
          name: 'Custom Room',
          type: ResourceType.equipment,
          capacity: 5,
        );

        expect(resource.id, 'custom-resource');
        expect(resource.name, 'Custom Room');
        expect(resource.type, ResourceType.equipment);
        expect(resource.capacity, 5);
      });
    });
  });
}
