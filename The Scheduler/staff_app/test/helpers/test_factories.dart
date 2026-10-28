import 'dart:convert';

import 'package:staff_app/core/services/location_service.dart';

/// Test constants for consistent test data.
class TestConstants {
  static const String businessId = 'test-business-123';
  static const String staffId = 'test-staff-456';
  static const String clientId = 'test-client-789';
  static const String serviceId = 'test-service-101';
  static const String locationId = 'test-location-102';
  static const String appointmentId = 'test-appointment-201';
  static const String timeEntryId = 'test-entry-301';

  static const double testLatitude = 37.7749;
  static const double testLongitude = -122.4194;
  static const String testAddress = '123 Test St, Test City, TC';
}

/// Factory for creating test time entry data.
class TimeEntryFactory {
  /// Creates a mock time entry data map for testing ClockState.fromEntry.
  static Map<String, dynamic> createEntryMap({
    String? id,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String breaksJson = '[]',
    String status = 'active',
  }) {
    return {
      'id': id ?? TestConstants.timeEntryId,
      'businessId': TestConstants.businessId,
      'staffId': TestConstants.staffId,
      'clockInTime': clockInTime ?? DateTime.now(),
      'clockOutTime': clockOutTime,
      'breaksJson': breaksJson,
      'status': status,
    };
  }

  /// Creates a breaks JSON string with one completed break.
  static String createBreaksJsonWithCompletedBreak({
    DateTime? startTime,
    DateTime? endTime,
    String type = 'meal',
  }) {
    final start = startTime ?? DateTime.now().subtract(const Duration(hours: 1));
    final end = endTime ?? DateTime.now().subtract(const Duration(minutes: 30));

    return jsonEncode([
      {
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'type': type,
      }
    ]);
  }

  /// Creates a breaks JSON string with an active (ongoing) break.
  static String createBreaksJsonWithActiveBreak({
    DateTime? startTime,
    String type = 'meal',
  }) {
    final start = startTime ?? DateTime.now().subtract(const Duration(minutes: 10));

    return jsonEncode([
      {
        'startTime': start.toIso8601String(),
        'type': type,
      }
    ]);
  }

  /// Creates a breaks JSON string with multiple breaks.
  static String createBreaksJsonWithMultiple({
    required List<({DateTime start, DateTime? end, String type})> breaks,
  }) {
    return jsonEncode(
      breaks.map((b) => {
        'startTime': b.start.toIso8601String(),
        if (b.end != null) 'endTime': b.end!.toIso8601String(),
        'type': b.type,
      }).toList(),
    );
  }
}

/// Factory for creating test appointment data.
class AppointmentFactory {
  /// Creates a pending appointment starting now.
  static Map<String, dynamic> createPending({
    String? id,
    DateTime? startTime,
    int durationMinutes = 60,
  }) {
    final start = startTime ?? DateTime.now();
    return {
      'id': id ?? TestConstants.appointmentId,
      'businessId': TestConstants.businessId,
      'staffId': TestConstants.staffId,
      'clientId': TestConstants.clientId,
      'serviceId': TestConstants.serviceId,
      'locationId': TestConstants.locationId,
      'startTime': start,
      'endTime': start.add(Duration(minutes: durationMinutes)),
      'status': 'pending',
      'clientName': 'John Doe',
      'serviceName': 'Haircut',
    };
  }

  /// Creates a confirmed appointment.
  static Map<String, dynamic> createConfirmed({
    String? id,
    DateTime? startTime,
    int durationMinutes = 60,
  }) {
    final base = createPending(
      id: id,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
    return {...base, 'status': 'confirmed'};
  }

  /// Creates a completed appointment.
  static Map<String, dynamic> createCompleted({
    String? id,
    DateTime? startTime,
    int durationMinutes = 60,
  }) {
    final base = createPending(
      id: id,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
    return {
      ...base,
      'status': 'completed',
      'completedAt': DateTime.now(),
    };
  }

  /// Creates a cancelled appointment.
  static Map<String, dynamic> createCancelled({
    String? id,
    DateTime? startTime,
  }) {
    final base = createPending(id: id, startTime: startTime);
    return {...base, 'status': 'cancelled'};
  }

  /// Creates an appointment that is currently happening.
  static Map<String, dynamic> createCurrent({
    String? id,
    int minutesAgo = 15,
    int durationMinutes = 60,
  }) {
    final start = DateTime.now().subtract(Duration(minutes: minutesAgo));
    return createConfirmed(
      id: id,
      startTime: start,
      durationMinutes: durationMinutes,
    );
  }

  /// Creates a past appointment.
  static Map<String, dynamic> createPast({
    String? id,
    int hoursAgo = 2,
    int durationMinutes = 60,
  }) {
    final start = DateTime.now().subtract(Duration(hours: hoursAgo));
    return createCompleted(
      id: id,
      startTime: start,
      durationMinutes: durationMinutes,
    );
  }

  /// Creates a future appointment.
  static Map<String, dynamic> createFuture({
    String? id,
    int hoursFromNow = 2,
    int durationMinutes = 60,
  }) {
    final start = DateTime.now().add(Duration(hours: hoursFromNow));
    return createConfirmed(
      id: id,
      startTime: start,
      durationMinutes: durationMinutes,
    );
  }
}

/// Factory for creating test business location points.
class BusinessLocationFactory {
  /// Creates a business location at default coordinates.
  static BusinessLocationPoint createDefault({
    String? id,
    String? name,
    double radiusMeters = 100.0,
  }) {
    return BusinessLocationPoint(
      id: id ?? TestConstants.locationId,
      name: name ?? 'Main Office',
      latitude: TestConstants.testLatitude,
      longitude: TestConstants.testLongitude,
      radiusMeters: radiusMeters,
    );
  }

  /// Creates a business location at specific coordinates.
  static BusinessLocationPoint create({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    double radiusMeters = 100.0,
  }) {
    return BusinessLocationPoint(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  /// Creates multiple business locations.
  static List<BusinessLocationPoint> createMultiple(int count) {
    return List.generate(
      count,
      (i) => BusinessLocationPoint(
        id: 'loc-$i',
        name: 'Location $i',
        latitude: TestConstants.testLatitude + (i * 0.01),
        longitude: TestConstants.testLongitude + (i * 0.01),
        radiusMeters: 100.0,
      ),
    );
  }
}

/// Factory for creating sync queue test data.
class SyncQueueFactory {
  /// Creates a clock-in sync action payload.
  static Map<String, dynamic> createClockInPayload({
    DateTime? clockInTime,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return {
      'clockInTime': (clockInTime ?? DateTime.now()).toIso8601String(),
      'clockInLatitude': latitude ?? TestConstants.testLatitude,
      'clockInLongitude': longitude ?? TestConstants.testLongitude,
      'clockInAddress': address ?? TestConstants.testAddress,
      'clockInLocationId': null,
      'clockInOutsideGeofence': false,
    };
  }

  /// Creates a clock-out sync action payload.
  static Map<String, dynamic> createClockOutPayload({
    DateTime? clockOutTime,
    int totalMinutes = 480,
    int breakMinutes = 30,
    int workedMinutes = 450,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) {
    return {
      'clockOutTime': (clockOutTime ?? DateTime.now()).toIso8601String(),
      'clockOutLatitude': latitude ?? TestConstants.testLatitude,
      'clockOutLongitude': longitude ?? TestConstants.testLongitude,
      'clockOutAddress': address ?? TestConstants.testAddress,
      'clockOutLocationId': null,
      'clockOutOutsideGeofence': false,
      'totalMinutes': totalMinutes,
      'breakMinutes': breakMinutes,
      'workedMinutes': workedMinutes,
      'notes': notes,
    };
  }

  /// Creates a start-break sync action payload.
  static Map<String, dynamic> createStartBreakPayload({
    DateTime? startTime,
    String type = 'meal',
  }) {
    return {
      'startTime': (startTime ?? DateTime.now()).toIso8601String(),
      'type': type,
    };
  }

  /// Creates an end-break sync action payload.
  static Map<String, dynamic> createEndBreakPayload({
    DateTime? endTime,
  }) {
    return {
      'endTime': (endTime ?? DateTime.now()).toIso8601String(),
    };
  }
}

/// Extension for creating mock entry objects for ClockState.fromEntry.
class MockTimeEntry {
  MockTimeEntry({
    required this.id,
    required this.clockInTime,
    this.clockOutTime,
    this.breaksJson = '[]',
  });

  final String id;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final String breaksJson;
}
