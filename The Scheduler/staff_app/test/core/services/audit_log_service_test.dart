import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/services/audit_log_service.dart';

void main() {
  group('AuditEventType', () {
    test('has all expected values', () {
      expect(AuditEventType.values, [
        AuditEventType.authentication,
        AuditEventType.dataAccess,
        AuditEventType.dataModification,
        AuditEventType.security,
        AuditEventType.sync,
        AuditEventType.system,
      ]);
    });
  });

  group('AuditSeverity', () {
    test('has all expected values', () {
      expect(AuditSeverity.values, [
        AuditSeverity.info,
        AuditSeverity.warning,
        AuditSeverity.error,
        AuditSeverity.critical,
      ]);
    });
  });

  group('AuditLogEntry', () {
    test('creates entry with required parameters', () {
      final entry = AuditLogEntry(
        type: AuditEventType.authentication,
        action: 'Login successful',
        severity: AuditSeverity.info,
      );

      expect(entry.id, isNotEmpty);
      expect(entry.timestamp, isNotNull);
      expect(entry.type, AuditEventType.authentication);
      expect(entry.action, 'Login successful');
      expect(entry.severity, AuditSeverity.info);
    });

    test('creates entry with all parameters', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final entry = AuditLogEntry(
        id: 'custom-id',
        timestamp: timestamp,
        type: AuditEventType.security,
        action: 'Security event',
        severity: AuditSeverity.warning,
        details: 'Some details',
        userId: 'user123',
        deviceInfo: 'iPhone 14',
        ipAddress: '192.168.1.1',
      );

      expect(entry.id, 'custom-id');
      expect(entry.timestamp, timestamp);
      expect(entry.details, 'Some details');
      expect(entry.userId, 'user123');
      expect(entry.deviceInfo, 'iPhone 14');
      expect(entry.ipAddress, '192.168.1.1');
    });

    test('toJson serializes all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final entry = AuditLogEntry(
        id: 'test-id',
        timestamp: timestamp,
        type: AuditEventType.dataAccess,
        action: 'Data accessed',
        severity: AuditSeverity.info,
        details: 'Details here',
      );

      final json = entry.toJson();

      expect(json['id'], 'test-id');
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['type'], AuditEventType.dataAccess.index);
      expect(json['action'], 'Data accessed');
      expect(json['severity'], AuditSeverity.info.index);
      expect(json['details'], 'Details here');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'from-json-id',
        'timestamp': '2024-01-15T10:30:00.000',
        'type': 1, // dataAccess
        'action': 'Data viewed',
        'severity': 0, // info
        'details': 'Viewed records',
        'userId': 'u1',
        'deviceInfo': null,
        'ipAddress': null,
      };

      final entry = AuditLogEntry.fromJson(json);

      expect(entry.id, 'from-json-id');
      expect(entry.type, AuditEventType.dataAccess);
      expect(entry.action, 'Data viewed');
      expect(entry.severity, AuditSeverity.info);
      expect(entry.details, 'Viewed records');
      expect(entry.userId, 'u1');
    });

    test('round-trip serialization preserves data', () {
      final original = AuditLogEntry(
        type: AuditEventType.sync,
        action: 'Sync completed',
        severity: AuditSeverity.info,
        details: '10 records synced',
      );

      final json = original.toJson();
      final restored = AuditLogEntry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.action, original.action);
      expect(restored.type, original.type);
      expect(restored.severity, original.severity);
      expect(restored.details, original.details);
    });
  });

  group('AuditLogService', () {
    test('singleton instance is consistent', () {
      final instance1 = AuditLogService.instance;
      final instance2 = AuditLogService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('setUserContext stores user info', () {
      final service = AuditLogService.instance;
      service.setUserContext(userId: 'user123', deviceInfo: 'Test Device');
      // Context is used in subsequent log calls
    });

    test('clearUserContext removes user info', () {
      final service = AuditLogService.instance;
      service.setUserContext(userId: 'user123');
      service.clearUserContext();
      // Context should be cleared
    });
  });

  group('AuditLogFilter', () {
    test('creates filter with no parameters', () {
      const filter = AuditLogFilter();

      expect(filter.type, isNull);
      expect(filter.severity, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.limit, isNull);
    });

    test('creates filter with all parameters', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final filter = AuditLogFilter(
        type: AuditEventType.authentication,
        severity: AuditSeverity.warning,
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      expect(filter.type, AuditEventType.authentication);
      expect(filter.severity, AuditSeverity.warning);
      expect(filter.startDate, startDate);
      expect(filter.endDate, endDate);
      expect(filter.limit, 100);
    });
  });
}
