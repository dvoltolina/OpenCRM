// Appointment Contract Tests
//
// Validates that Appointment model schema matches the shared data contract
// defined in docs/shared_data_contract.md
//
// Contract path: businesses/{businessId}/appointments/{appointmentId}

import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/recurrence_pattern.dart';

void main() {
  group('Appointment Contract Tests', () {
    group('Schema Validation', () {
      test('Appointment has all required fields per contract', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 10, 0),
          endTime: DateTime(2025, 12, 1, 11, 0),
          date: DateTime(2025, 12, 1),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        // Required fields per docs/shared_data_contract.md
        expect(appointment.id, isNotNull);
        expect(appointment.businessId, isNotNull);
        expect(appointment.clientId, isNotNull);
        expect(appointment.providerId, isNotNull);
        expect(appointment.serviceId, isNotNull);
        expect(appointment.locationId, isNotNull);
        expect(appointment.startTime, isNotNull);
        expect(appointment.endTime, isNotNull);
        expect(appointment.date, isNotNull);
        expect(appointment.status, isNotNull);
        expect(appointment.createdAt, isNotNull);
      });

      test('Appointment status enum matches contract values', () {
        // Contract: pending, confirmed, cancelled, completed, noShow
        expect(AppointmentStatus.values, containsAll([
          AppointmentStatus.pending,
          AppointmentStatus.confirmed,
          AppointmentStatus.cancelled,
          AppointmentStatus.completed,
          AppointmentStatus.noShow,
        ]));
      });

      test('Group session fields are optional', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        // Group session fields optional per contract
        expect(appointment.isGroupSession, isFalse);
        expect(appointment.capacity, isNull);
        expect(appointment.attendeeIds, isEmpty);
      });

      test('Group session appointment has required group fields', () {
        final groupSession = Appointment(
          id: 'group-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          isGroupSession: true,
          capacity: 10,
          attendeeIds: ['client-1', 'client-2'],
          createdAt: DateTime.now(),
        );

        expect(groupSession.isGroupSession, isTrue);
        expect(groupSession.capacity, equals(10));
        expect(groupSession.attendeeIds, hasLength(2));
      });
    });

    group('Serialization Contract', () {
      test('Appointment toJson produces contract-compliant keys', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime(2025, 12, 1, 10, 0),
          endTime: DateTime(2025, 12, 1, 11, 0),
          date: DateTime(2025, 12, 1),
          status: AppointmentStatus.confirmed,
          notes: 'Test notes',
          createdAt: DateTime.now(),
        );

        final json = appointment.toJson();

        // Contract field names
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('businessId'), isTrue);
        expect(json.containsKey('clientId'), isTrue);
        expect(json.containsKey('providerId'), isTrue);
        expect(json.containsKey('serviceId'), isTrue);
        expect(json.containsKey('locationId'), isTrue);
        expect(json.containsKey('startTime'), isTrue);
        expect(json.containsKey('endTime'), isTrue);
        expect(json.containsKey('date'), isTrue);
        expect(json.containsKey('status'), isTrue);
        expect(json.containsKey('notes'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
      });

      test('Appointment fromJson parses contract-compliant data', () {
        final json = {
          'id': 'appt-1',
          'businessId': 'business-1',
          'clientId': 'client-1',
          'providerId': 'provider-1',
          'serviceId': 'service-1',
          'locationId': 'location-1',
          'startTime': '2025-12-01T10:00:00.000',
          'endTime': '2025-12-01T11:00:00.000',
          'date': '2025-12-01T00:00:00.000',
          'status': 'confirmed',
          'isGroupSession': false,
          'createdAt': '2025-01-01T00:00:00.000',
        };

        final appointment = Appointment.fromJson(json);

        expect(appointment.id, equals('appt-1'));
        expect(appointment.businessId, equals('business-1'));
        expect(appointment.clientId, equals('client-1'));
        expect(appointment.providerId, equals('provider-1'));
        expect(appointment.serviceId, equals('service-1'));
        expect(appointment.locationId, equals('location-1'));
        expect(appointment.status, equals(AppointmentStatus.confirmed));
      });
    });

    group('Referential Integrity Contract', () {
      test('Appointment references are non-empty strings', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        expect(appointment.clientId, isNotEmpty);
        expect(appointment.providerId, isNotEmpty);
        expect(appointment.serviceId, isNotEmpty);
        expect(appointment.locationId, isNotEmpty);
      });
    });

    group('Recurrence Contract', () {
      test('Recurrence fields are optional', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        expect(appointment.isRecurring, isFalse);
        expect(appointment.recurrenceId, isNull);
        expect(appointment.recurrencePattern, isNull);
        expect(appointment.isRecurrenceException, isFalse);
        expect(appointment.originalStartTime, isNull);
      });

      test('Recurring appointment has series fields', () {
        final recurringAppt = Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          isRecurring: true,
          recurrenceId: 'appt-1',
          recurrencePattern: RecurrencePattern(
            id: 'pattern-1',
            frequency: RecurrenceFrequency.weekly,
            daysOfWeek: const [DayOfWeek.monday, DayOfWeek.wednesday],
            endType: RecurrenceEndType.afterOccurrences,
            numberOfOccurrences: 6,
            createdAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        );

        expect(recurringAppt.isRecurring, isTrue);
        expect(recurringAppt.recurrenceId, equals('appt-1'));
        expect(recurringAppt.recurrencePattern, isNotNull);
        expect(recurringAppt.isRecurrenceParent, isTrue);
      });
    });

    group('Tenant Isolation Contract', () {
      test('Appointment businessId required for tenant scoping', () {
        final appointment = Appointment(
          id: 'appt-1',
          businessId: 'tenant-123',
          clientId: 'client-1',
          providerId: 'provider-1',
          serviceId: 'service-1',
          locationId: 'location-1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          date: DateTime.now(),
          status: AppointmentStatus.confirmed,
          createdAt: DateTime.now(),
        );

        expect(appointment.businessId, equals('tenant-123'));
        expect(appointment.businessId, isNotEmpty);
      });
    });
  });
}
