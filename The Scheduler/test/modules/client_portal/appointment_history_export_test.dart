import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/location.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;
import 'package:the_scheduler/data/models/service.dart';
import 'package:the_scheduler/modules/client_portal/presentation/widgets/appointment_history_export.dart';

void main() {
  group('AppointmentHistoryExport', () {
    test('buildCsvRows sorts and formats values', () {
      final appointments = _buildAppointments();
      final rows = AppointmentHistoryExport.buildCsvRows(
        appointments: appointments,
        servicesCache: _services,
        providersCache: _providers,
        locationsCache: _locations,
      );

      // Header + 2 rows
      expect(rows.length, 3);
      expect(rows.first, containsAllInOrder(['Date', 'Time', 'Status']));

      // Sorted by start time ascending
      expect(rows[1][0], '2025-01-01');
      expect(rows[2][0], '2025-01-02');

      // Uses cached names
      expect(rows[1][3], 'Therapy');
      expect(rows[1][4], 'Dr. Provider');
      expect(rows[1][5], 'Main Clinic');
    });

    test('buildPdfTableData returns formatted rows', () {
      final appointments = _buildAppointments();
      final data = AppointmentHistoryExport.buildPdfTableData(
        appointments: appointments,
        servicesCache: _services,
        providersCache: _providers,
        locationsCache: _locations,
        dateFormat: DateFormat('MMM d, yyyy'),
      );

      expect(data.length, 2);
      expect(data.first[2], 'Therapy');
      expect(data.first[3], 'Dr. Provider');
      expect(data.first[4], 'Main Clinic');
    });
  });
}

List<Appointment> _buildAppointments() {
  return [
    Appointment(
      id: 'apt-1',
      businessId: 'biz',
      clientId: 'client',
      providerId: 'prov',
      serviceId: 'svc',
      locationId: 'loc',
      startTime: DateTime(2025, 1, 1, 10, 0),
      endTime: DateTime(2025, 1, 1, 11, 0),
      date: DateTime(2025, 1, 1),
      status: AppointmentStatus.confirmed,
      createdAt: DateTime(2024, 12, 31),
    ),
    Appointment(
      id: 'apt-2',
      businessId: 'biz',
      clientId: 'client',
      providerId: 'prov',
      serviceId: 'svc',
      locationId: 'loc',
      startTime: DateTime(2025, 1, 2, 9, 0),
      endTime: DateTime(2025, 1, 2, 10, 0),
      date: DateTime(2025, 1, 2),
      status: AppointmentStatus.completed,
      createdAt: DateTime(2024, 12, 31),
    ),
  ];
}

final _services = <String, Service>{
  'svc': Service(
    id: 'svc',
    businessId: 'biz',
    name: 'Therapy',
    durationMinutes: 60,
    price: 150,
    createdAt: DateTime(2024, 1, 1),
  ),
};

final _providers = <String, provider_model.Provider>{
  'prov': provider_model.Provider(
    id: 'prov',
    businessId: 'biz',
    firstName: 'Dr.',
    lastName: 'Provider',
    createdAt: DateTime(2024, 1, 1),
  ),
};

final _locations = <String, Location>{
  'loc': Location(
    id: 'loc',
    businessId: 'biz',
    name: 'Main Clinic',
    address: '123 Main',
    city: 'City',
    state: 'ST',
    zipCode: '00000',
    phone: '555',
    createdAt: DateTime(2024, 1, 1),
  ),
};
