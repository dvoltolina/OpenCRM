import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/appointment.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Appointment Model', () {
    group('JSON Serialization', () {
      test('creates appointment from JSON', () {
        final json = {
          'id': 'appt-123',
          'businessId': 'business-456',
          'clientId': 'client-789',
          'providerId': 'provider-101',
          'serviceId': 'service-202',
          'locationId': 'location-303',
          'startTime': '2025-12-01T09:00:00.000Z',
          'endTime': '2025-12-01T10:00:00.000Z',
          'date': '2025-12-01T00:00:00.000Z',
          'status': 'confirmed',
          'createdAt': '2025-11-01T00:00:00.000Z',
        };

        final appointment = Appointment.fromJson(json);

        expect(appointment.id, 'appt-123');
        expect(appointment.businessId, 'business-456');
        expect(appointment.clientId, 'client-789');
        expect(appointment.providerId, 'provider-101');
        expect(appointment.serviceId, 'service-202');
        expect(appointment.locationId, 'location-303');
        expect(appointment.status, AppointmentStatus.confirmed);
        expect(appointment.startTime.year, 2025);
        expect(appointment.startTime.month, 12);
        expect(appointment.startTime.day, 1);
        expect(appointment.startTime.hour, 9);
      });

      test('converts appointment to JSON', () {
        final appointment = TestData.appointment(
          id: 'appt-123',
          businessId: 'business-456',
          status: AppointmentStatus.confirmed,
        );

        final json = appointment.toJson();

        expect(json['id'], 'appt-123');
        expect(json['businessId'], 'business-456');
        expect(json['status'], 'confirmed');
        expect(json.containsKey('clientId'), true);
        expect(json.containsKey('providerId'), true);
        expect(json.containsKey('serviceId'), true);
      });

      test('handles all appointment statuses', () {
        for (final status in AppointmentStatus.values) {
          final appointment = TestData.appointment(status: status);
          final json = appointment.toJson();
          final deserialized = Appointment.fromJson(json);

          expect(deserialized.status, status);
        }
      });

      test('handles null optional fields', () {
        final appointment = TestData.appointment(notes: null);
        final json = appointment.toJson();
        final deserialized = Appointment.fromJson(json);

        expect(deserialized.notes, null);
        expect(deserialized.paymentId, null);
        expect(deserialized.cancellationReason, null);
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final original = TestData.appointment(
          status: AppointmentStatus.pending,
        );

        final updated = original.copyWith(
          status: AppointmentStatus.confirmed,
        );

        expect(updated.status, AppointmentStatus.confirmed);
        expect(updated.id, original.id);
        expect(updated.clientId, original.clientId);
        expect(updated.providerId, original.providerId);
      });

      test('copies with new times', () {
        final original = TestData.appointment();
        final newStart = DateTime(2025, 12, 15, 14, 0);
        final newEnd = DateTime(2025, 12, 15, 15, 0);

        final updated = original.copyWith(
          startTime: newStart,
          endTime: newEnd,
        );

        expect(updated.startTime, newStart);
        expect(updated.endTime, newEnd);
        expect(updated.id, original.id);
      });

      test('copies with cancellation', () {
        final original = TestData.appointment(
          status: AppointmentStatus.confirmed,
        );

        final updated = original.copyWith(
          status: AppointmentStatus.cancelled,
          cancellationReason: 'Client requested',
        );

        expect(updated.status, AppointmentStatus.cancelled);
        expect(updated.cancellationReason, 'Client requested');
      });

      test('preserves all fields when no changes', () {
        final original = TestData.appointment();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.clientId, original.clientId);
        expect(copy.providerId, original.providerId);
        expect(copy.serviceId, original.serviceId);
        expect(copy.locationId, original.locationId);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.status, original.status);
      });
    });

    group('AppointmentStatus enum', () {
      test('has all expected values', () {
        expect(AppointmentStatus.values, [
          AppointmentStatus.pending,
          AppointmentStatus.confirmed,
          AppointmentStatus.cancelled,
          AppointmentStatus.completed,
          AppointmentStatus.noShow,
        ]);
      });

      test('serializes to correct strings', () {
        final appointment = TestData.appointment();

        expect(
          appointment.copyWith(status: AppointmentStatus.pending).toJson()['status'],
          'pending',
        );
        expect(
          appointment.copyWith(status: AppointmentStatus.confirmed).toJson()['status'],
          'confirmed',
        );
        expect(
          appointment.copyWith(status: AppointmentStatus.cancelled).toJson()['status'],
          'cancelled',
        );
        expect(
          appointment.copyWith(status: AppointmentStatus.completed).toJson()['status'],
          'completed',
        );
        expect(
          appointment.copyWith(status: AppointmentStatus.noShow).toJson()['status'],
          'noShow',
        );
      });
    });

    group('Validation & Business Logic', () {
      test('appointment duration is calculated correctly', () {
        final appointment = TestData.appointment(
          startTime: DateTime(2025, 12, 1, 9, 0),
          endTime: DateTime(2025, 12, 1, 10, 30),
        );

        final duration = appointment.endTime.difference(appointment.startTime);

        expect(duration.inMinutes, 90);
      });

      test('appointment is on correct date', () {
        final appointment = TestData.appointment(
          startTime: DateTime(2025, 12, 1, 9, 0),
        );

        expect(appointment.date.year, 2025);
        expect(appointment.date.month, 12);
        expect(appointment.date.day, 1);
      });

      test('supports multi-tenant isolation', () {
        final business1 = TestData.appointment(businessId: 'business-1');
        final business2 = TestData.appointment(businessId: 'business-2');

        expect(business1.businessId, isNot(equals(business2.businessId)));
        expect(business1.businessId, 'business-1');
        expect(business2.businessId, 'business-2');
      });
    });

    group('Test Data Factory', () {
      test('creates appointment with defaults', () {
        final appointment = TestData.appointment();

        expect(appointment.id, isNotEmpty);
        expect(appointment.businessId, isNotEmpty);
        expect(appointment.clientId, isNotEmpty);
        expect(appointment.providerId, isNotEmpty);
        expect(appointment.serviceId, isNotEmpty);
        expect(appointment.locationId, isNotEmpty);
        expect(appointment.status, AppointmentStatus.confirmed);
      });

      test('creates appointment with custom values', () {
        final customStart = DateTime(2026, 1, 1, 10, 0);
        final customEnd = DateTime(2026, 1, 1, 11, 0);

        final appointment = TestData.appointment(
          id: 'custom-id',
          businessId: 'custom-business',
          clientId: 'custom-client',
          startTime: customStart,
          endTime: customEnd,
          status: AppointmentStatus.pending,
          notes: 'Custom notes',
        );

        expect(appointment.id, 'custom-id');
        expect(appointment.businessId, 'custom-business');
        expect(appointment.clientId, 'custom-client');
        expect(appointment.startTime, customStart);
        expect(appointment.endTime, customEnd);
        expect(appointment.status, AppointmentStatus.pending);
        expect(appointment.notes, 'Custom notes');
      });

      test('creates multiple appointments', () {
        final appointments = TestData.appointments(count: 5);

        expect(appointments.length, 5);
        expect(appointments[0].id, 'appointment-1');
        expect(appointments[4].id, 'appointment-5');

        // Each should be on different days
        for (int i = 0; i < 5; i++) {
          expect(
            appointments[i].startTime,
            TestData.testDate.add(Duration(days: i)),
          );
        }
      });
    });
  });
}
