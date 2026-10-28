import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/modules/schedule/providers/schedule_providers.dart';

import '../helpers/database_helper.dart';
import '../helpers/test_factories.dart';

/// Tests for appointment display extensions.
///
/// These tests verify the AppointmentDisplayExtension on AppointmentsTableData
/// which is used by the AppointmentCard widget.
void main() {
  late TestDatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = TestDatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.dispose();
  });

  group('AppointmentDisplayExtension', () {
    group('timeRange', () {
      test('formats time range correctly', () async {
        // Arrange
        final startTime = DateTime(2024, 1, 15, 9, 0); // 9:00 AM
        final endTime = DateTime(2024, 1, 15, 10, 30); // 10:30 AM

        await dbHelper.insertAppointment(
          id: 'apt-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        // Act - get the appointment by ID
        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-1');

        // Assert
        expect(apt, isNotNull);
        expect(apt!.timeRange, equals('9:00 AM - 10:30 AM'));
      });
    });

    group('time formatting', () {
      test('startTimeFormatted formats AM time correctly', () async {
        final startTime = DateTime(2024, 1, 15, 9, 0);
        final endTime = DateTime(2024, 1, 15, 10, 0);

        await dbHelper.insertAppointment(
          id: 'apt-1',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-1');
        expect(apt, isNotNull);
        expect(apt!.startTimeFormatted, equals('9:00 AM'));
      });

      test('startTimeFormatted formats PM time correctly', () async {
        final startTime = DateTime(2024, 1, 15, 14, 30);
        final endTime = DateTime(2024, 1, 15, 15, 30);

        await dbHelper.insertAppointment(
          id: 'apt-2',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-2');
        expect(apt, isNotNull);
        expect(apt!.startTimeFormatted, equals('2:30 PM'));
      });

      test('startTimeFormatted formats noon correctly', () async {
        final startTime = DateTime(2024, 1, 15, 12, 0);
        final endTime = DateTime(2024, 1, 15, 13, 0);

        await dbHelper.insertAppointment(
          id: 'apt-3',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-3');
        expect(apt, isNotNull);
        expect(apt!.startTimeFormatted, equals('12:00 PM'));
      });

      test('startTimeFormatted formats midnight correctly', () async {
        final startTime = DateTime(2024, 1, 15, 0, 0);
        final endTime = DateTime(2024, 1, 15, 1, 0);

        await dbHelper.insertAppointment(
          id: 'apt-4',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-4');
        expect(apt, isNotNull);
        expect(apt!.startTimeFormatted, equals('12:00 AM'));
      });
    });

    group('durationMinutes', () {
      test('calculates duration correctly', () async {
        final startTime = DateTime(2024, 1, 15, 9, 0);
        final endTime = DateTime(2024, 1, 15, 10, 30);

        await dbHelper.insertAppointment(
          id: 'apt-5',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: startTime,
          endTime: endTime,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('apt-5');
        expect(apt, isNotNull);
        expect(apt!.durationMinutes, equals(90));
      });
    });

    group('status checks', () {
      test('isPast returns true for past appointments', () async {
        final pastStart = DateTime.now().subtract(const Duration(hours: 3));
        final pastEnd = DateTime.now().subtract(const Duration(hours: 2));

        await dbHelper.insertAppointment(
          id: 'past-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: pastStart,
          endTime: pastEnd,
          status: 'completed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('past-apt');
        expect(apt, isNotNull);
        expect(apt!.isPast, isTrue);
        expect(apt.isCurrent, isFalse);
        expect(apt.isUpcoming, isFalse);
      });

      test('isCurrent returns true for current appointments', () async {
        final currentStart = DateTime.now().subtract(const Duration(minutes: 30));
        final currentEnd = DateTime.now().add(const Duration(minutes: 30));

        await dbHelper.insertAppointment(
          id: 'current-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: currentStart,
          endTime: currentEnd,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('current-apt');
        expect(apt, isNotNull);
        expect(apt!.isPast, isFalse);
        expect(apt.isCurrent, isTrue);
        expect(apt.isUpcoming, isFalse);
      });

      test('isUpcoming returns true for future appointments', () async {
        final futureStart = DateTime.now().add(const Duration(hours: 2));
        final futureEnd = DateTime.now().add(const Duration(hours: 3));

        await dbHelper.insertAppointment(
          id: 'future-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: futureStart,
          endTime: futureEnd,
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('future-apt');
        expect(apt, isNotNull);
        expect(apt!.isPast, isFalse);
        expect(apt.isCurrent, isFalse);
        expect(apt.isUpcoming, isTrue);
      });

      test('isCheckedIn returns true when checked in', () async {
        await dbHelper.insertAppointment(
          id: 'checkedin-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
          checkedInAt: DateTime.now(),
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('checkedin-apt');
        expect(apt, isNotNull);
        expect(apt!.isCheckedIn, isTrue);
      });

      test('isCheckedIn returns false when not checked in', () async {
        await dbHelper.insertAppointment(
          id: 'notcheckedin-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('notcheckedin-apt');
        expect(apt, isNotNull);
        expect(apt!.isCheckedIn, isFalse);
      });

      test('isCompleted returns true for completed status', () async {
        await dbHelper.insertAppointment(
          id: 'completed-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          endTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'completed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('completed-apt');
        expect(apt, isNotNull);
        expect(apt!.isCompleted, isTrue);
      });

      test('isNoShow returns true for noShow status', () async {
        await dbHelper.insertAppointment(
          id: 'noshow-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          endTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'noShow',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('noshow-apt');
        expect(apt, isNotNull);
        expect(apt!.isNoShow, isTrue);
      });

      test('isCancelled returns true for cancelled status', () async {
        await dbHelper.insertAppointment(
          id: 'cancelled-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'cancelled',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('cancelled-apt');
        expect(apt, isNotNull);
        expect(apt!.isCancelled, isTrue);
      });
    });

    group('display names', () {
      test('displayName returns client name when available', () async {
        await dbHelper.insertAppointment(
          id: 'named-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
          clientName: 'John Smith',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('named-apt');
        expect(apt, isNotNull);
        expect(apt!.displayName, equals('John Smith'));
      });

      test('displayName returns fallback when client name is null', () async {
        await dbHelper.insertAppointment(
          id: 'unnamed-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('unnamed-apt');
        expect(apt, isNotNull);
        expect(apt!.displayName, equals('Unknown Client'));
      });

      test('displayService returns service name when available', () async {
        await dbHelper.insertAppointment(
          id: 'service-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
          serviceName: 'Haircut',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('service-apt');
        expect(apt, isNotNull);
        expect(apt!.displayService, equals('Haircut'));
      });

      test('displayService returns fallback when service name is null', () async {
        await dbHelper.insertAppointment(
          id: 'noservice-apt',
          businessId: TestConstants.businessId,
          staffId: TestConstants.staffId,
          clientId: TestConstants.clientId,
          serviceId: TestConstants.serviceId,
          locationId: TestConstants.locationId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: 'confirmed',
        );

        final apt = await dbHelper.db.appointmentsDao.getAppointmentById('noservice-apt');
        expect(apt, isNotNull);
        expect(apt!.displayService, equals('Service'));
      });
    });
  });
}
