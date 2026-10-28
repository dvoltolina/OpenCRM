import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/sync_record.dart';

void main() {
  group('SyncRecord Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final record = SyncRecord(
          id: 'sync-123',
          businessId: 'biz-456',
          connectionId: 'conn-789',
          localId: 'payment-abc',
          localType: SyncLocalType.payment,
          remoteId: 'qb-invoice-123',
          remoteType: SyncRemoteType.invoice,
          syncedAt: DateTime(2025, 1, 15, 14, 30),
          syncDirection: SyncDirection.toAccounting,
          status: SyncStatus.success,
          errorMessage: null,
          retryCount: 0,
          metadata: {'amountCents': 5000, 'reference': 'INV-001'},
          createdAt: DateTime(2025, 1, 15, 14, 30),
          updatedAt: DateTime(2025, 1, 15, 14, 30),
        );

        final json = record.toJson();
        final restored = SyncRecord.fromJson(json);

        expect(restored.id, record.id);
        expect(restored.businessId, record.businessId);
        expect(restored.connectionId, record.connectionId);
        expect(restored.localId, record.localId);
        expect(restored.localType, record.localType);
        expect(restored.remoteId, record.remoteId);
        expect(restored.remoteType, record.remoteType);
        expect(restored.syncDirection, record.syncDirection);
        expect(restored.status, record.status);
        expect(restored.retryCount, record.retryCount);
        expect(restored.metadata, record.metadata);
      });

      test('handles null optional fields', () {
        final record = SyncRecord(
          id: 'sync-123',
          businessId: 'biz-456',
          connectionId: 'conn-789',
          localId: 'payment-abc',
          localType: SyncLocalType.payment,
          remoteType: SyncRemoteType.payment,
          syncedAt: DateTime(2025, 1, 15),
          syncDirection: SyncDirection.toAccounting,
        );

        final json = record.toJson();
        final restored = SyncRecord.fromJson(json);

        expect(restored.remoteId, isNull);
        expect(restored.errorMessage, isNull);
        expect(restored.metadata, isNull);
        expect(restored.createdAt, isNull);
        expect(restored.updatedAt, isNull);
      });

      test('handles all SyncLocalType values', () {
        for (final type in SyncLocalType.values) {
          final record = _createSyncRecord(localType: type);

          final json = record.toJson();
          final restored = SyncRecord.fromJson(json);

          expect(restored.localType, type);
        }
      });

      test('handles all SyncRemoteType values', () {
        for (final type in SyncRemoteType.values) {
          final record = _createSyncRecord(remoteType: type);

          final json = record.toJson();
          final restored = SyncRecord.fromJson(json);

          expect(restored.remoteType, type);
        }
      });

      test('handles all SyncDirection values', () {
        for (final direction in SyncDirection.values) {
          final record = _createSyncRecord(syncDirection: direction);

          final json = record.toJson();
          final restored = SyncRecord.fromJson(json);

          expect(restored.syncDirection, direction);
        }
      });

      test('handles all SyncStatus values', () {
        for (final status in SyncStatus.values) {
          final record = _createSyncRecord(status: status);

          final json = record.toJson();
          final restored = SyncRecord.fromJson(json);

          expect(restored.status, status);
        }
      });

      test('serializes with error message', () {
        final record = _createSyncRecord(
          status: SyncStatus.failed,
          errorMessage: 'Connection timeout',
          retryCount: 2,
        );

        final json = record.toJson();
        final restored = SyncRecord.fromJson(json);

        expect(restored.status, SyncStatus.failed);
        expect(restored.errorMessage, 'Connection timeout');
        expect(restored.retryCount, 2);
      });
    });

    group('Status Helpers', () {
      test('isSuccess returns true for success status', () {
        final record = _createSyncRecord(status: SyncStatus.success);
        expect(record.isSuccess, isTrue);
      });

      test('isSuccess returns false for other statuses', () {
        expect(_createSyncRecord(status: SyncStatus.pending).isSuccess, isFalse);
        expect(_createSyncRecord(status: SyncStatus.failed).isSuccess, isFalse);
        expect(_createSyncRecord(status: SyncStatus.skipped).isSuccess, isFalse);
      });

      test('isFailed returns true for failed status', () {
        final record = _createSyncRecord(status: SyncStatus.failed);
        expect(record.isFailed, isTrue);
      });

      test('isFailed returns false for other statuses', () {
        expect(_createSyncRecord(status: SyncStatus.pending).isFailed, isFalse);
        expect(_createSyncRecord(status: SyncStatus.success).isFailed, isFalse);
        expect(_createSyncRecord(status: SyncStatus.skipped).isFailed, isFalse);
      });
    });

    group('Retry Logic', () {
      test('canRetry returns true when failed with low retry count', () {
        final record = _createSyncRecord(
          status: SyncStatus.failed,
          retryCount: 0,
        );
        expect(record.canRetry, isTrue);
      });

      test('canRetry returns true at retry count 2', () {
        final record = _createSyncRecord(
          status: SyncStatus.failed,
          retryCount: 2,
        );
        expect(record.canRetry, isTrue);
      });

      test('canRetry returns false at retry count 3', () {
        final record = _createSyncRecord(
          status: SyncStatus.failed,
          retryCount: 3,
        );
        expect(record.canRetry, isFalse);
      });

      test('canRetry returns false for successful syncs', () {
        final record = _createSyncRecord(
          status: SyncStatus.success,
          retryCount: 0,
        );
        expect(record.canRetry, isFalse);
      });

      test('canRetry returns false for pending syncs', () {
        final record = _createSyncRecord(
          status: SyncStatus.pending,
          retryCount: 0,
        );
        expect(record.canRetry, isFalse);
      });
    });

    group('Display Helpers', () {
      test('displaySummary shows correct format', () {
        final record = _createSyncRecord(
          localType: SyncLocalType.payment,
          remoteType: SyncRemoteType.invoice,
          syncDirection: SyncDirection.toAccounting,
        );
        expect(record.displaySummary, 'Payment → Invoice');
      });

      test('displaySummary shows correct format for from accounting', () {
        final record = _createSyncRecord(
          localType: SyncLocalType.client,
          remoteType: SyncRemoteType.customer,
          syncDirection: SyncDirection.fromAccounting,
        );
        expect(record.displaySummary, 'Client ← Customer');
      });

      test('syncedAtDisplay shows "Just now" for recent sync', () {
        final record = _createSyncRecord(
          syncedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(record.syncedAtDisplay, 'Just now');
      });

      test('syncedAtDisplay shows minutes ago', () {
        final record = _createSyncRecord(
          syncedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        );
        expect(record.syncedAtDisplay, '15m ago');
      });

      test('syncedAtDisplay shows hours ago', () {
        final record = _createSyncRecord(
          syncedAt: DateTime.now().subtract(const Duration(hours: 5)),
        );
        expect(record.syncedAtDisplay, '5h ago');
      });

      test('syncedAtDisplay shows days ago', () {
        final record = _createSyncRecord(
          syncedAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        expect(record.syncedAtDisplay, '3d ago');
      });
    });

    group('SyncLocalType Extension', () {
      test('displayName returns correct strings', () {
        expect(SyncLocalType.payment.displayName, 'Payment');
        expect(SyncLocalType.client.displayName, 'Client');
        expect(SyncLocalType.invoice.displayName, 'Invoice');
        expect(SyncLocalType.appointment.displayName, 'Appointment');
        expect(SyncLocalType.product.displayName, 'Product');
        expect(SyncLocalType.service.displayName, 'Service');
      });
    });

    group('SyncRemoteType Extension', () {
      test('displayName returns correct strings', () {
        expect(SyncRemoteType.invoice.displayName, 'Invoice');
        expect(SyncRemoteType.payment.displayName, 'Payment');
        expect(SyncRemoteType.customer.displayName, 'Customer');
        expect(SyncRemoteType.salesReceipt.displayName, 'Sales Receipt');
        expect(SyncRemoteType.item.displayName, 'Item');
        expect(SyncRemoteType.contact.displayName, 'Contact');
      });
    });

    group('SyncDirection Extension', () {
      test('displayName returns correct strings', () {
        expect(SyncDirection.toAccounting.displayName, 'To Accounting');
        expect(SyncDirection.fromAccounting.displayName, 'From Accounting');
      });

      test('icon returns correct arrows', () {
        expect(SyncDirection.toAccounting.icon, '→');
        expect(SyncDirection.fromAccounting.icon, '←');
      });
    });

    group('SyncStatus Extension', () {
      test('displayName returns correct strings', () {
        expect(SyncStatus.pending.displayName, 'Pending');
        expect(SyncStatus.success.displayName, 'Success');
        expect(SyncStatus.failed.displayName, 'Failed');
        expect(SyncStatus.skipped.displayName, 'Skipped');
      });

      test('isSuccess returns true only for success', () {
        expect(SyncStatus.success.isSuccess, isTrue);
        expect(SyncStatus.pending.isSuccess, isFalse);
        expect(SyncStatus.failed.isSuccess, isFalse);
        expect(SyncStatus.skipped.isSuccess, isFalse);
      });

      test('isFailed returns true only for failed', () {
        expect(SyncStatus.failed.isFailed, isTrue);
        expect(SyncStatus.pending.isFailed, isFalse);
        expect(SyncStatus.success.isFailed, isFalse);
        expect(SyncStatus.skipped.isFailed, isFalse);
      });
    });
  });

  group('SyncRecordFilter', () {
    test('can be constructed with all parameters', () {
      final filter = SyncRecordFilter(
        connectionId: 'conn-123',
        localType: SyncLocalType.payment,
        remoteType: SyncRemoteType.invoice,
        status: SyncStatus.success,
        syncDirection: SyncDirection.toAccounting,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        limit: 50,
      );

      expect(filter.connectionId, 'conn-123');
      expect(filter.localType, SyncLocalType.payment);
      expect(filter.remoteType, SyncRemoteType.invoice);
      expect(filter.status, SyncStatus.success);
      expect(filter.syncDirection, SyncDirection.toAccounting);
      expect(filter.startDate, DateTime(2025, 1, 1));
      expect(filter.endDate, DateTime(2025, 1, 31));
      expect(filter.limit, 50);
    });

    test('can be constructed with minimal parameters', () {
      const filter = SyncRecordFilter();

      expect(filter.connectionId, isNull);
      expect(filter.localType, isNull);
      expect(filter.remoteType, isNull);
      expect(filter.status, isNull);
      expect(filter.syncDirection, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.limit, isNull);
    });
  });
}

/// Helper function to create a test sync record with sensible defaults
SyncRecord _createSyncRecord({
  String id = 'sync-123',
  String businessId = 'biz-456',
  String connectionId = 'conn-789',
  String localId = 'local-abc',
  SyncLocalType localType = SyncLocalType.payment,
  String? remoteId,
  SyncRemoteType remoteType = SyncRemoteType.payment,
  DateTime? syncedAt,
  SyncDirection syncDirection = SyncDirection.toAccounting,
  SyncStatus status = SyncStatus.success,
  String? errorMessage,
  int retryCount = 0,
}) {
  return SyncRecord(
    id: id,
    businessId: businessId,
    connectionId: connectionId,
    localId: localId,
    localType: localType,
    remoteId: remoteId,
    remoteType: remoteType,
    syncedAt: syncedAt ?? DateTime(2025, 1, 15, 14, 30),
    syncDirection: syncDirection,
    status: status,
    errorMessage: errorMessage,
    retryCount: retryCount,
  );
}
