import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/services/export_service.dart';
import 'package:the_scheduler/data/models/audit_log.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';

import '../../helpers/test_data_factories.dart';

/// Mock audit log repository for testing (no-op implementation).
class MockAuditLogRepository extends AuditLogRepository {
  MockAuditLogRepository() : super(firestore: FakeFirebaseFirestore());

  final List<AuditLogEntry> loggedEvents = [];

  @override
  Future<void> logEvent(AuditLogEntry entry) async {
    loggedEvents.add(entry);
  }
}

void main() {
  group('ExportService', () {
    test('creates CSV with provider and service breakdowns', () async {
      final tempDir = await Directory.systemTemp.createTemp('export_service');
      final metrics = TestData.analyticsMetrics();
      final mockAuditLogRepository = MockAuditLogRepository();
      final exportService = ExportService(
        auditLogRepository: mockAuditLogRepository,
      );
      final context = TestData.securityContext();

      final file = await exportService.exportToCsv(
        metrics,
        filename: 'analytics.csv',
        context: context,
        outputDirectory: tempDir,
      );

      final csv = await file.readAsString();

      expect(csv, contains('Total Appointments'));
      expect(csv, contains('Provider,Appointments'));
      expect(csv, contains('Service,Appointments'));
      expect(csv, contains('provider-1'));
      expect(csv, contains('service-1'));
      
      // Verify audit log was recorded
      expect(mockAuditLogRepository.loggedEvents.length, 1);
      expect(mockAuditLogRepository.loggedEvents.first.actionType, AuditActionType.dataExport);
    });
  });
}
