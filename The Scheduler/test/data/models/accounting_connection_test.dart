import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/accounting_connection.dart';

void main() {
  group('AccountingConnection Model', () {
    group('JSON Serialization', () {
      test('serializes to JSON and back', () {
        final connection = AccountingConnection(
          id: 'conn-123',
          businessId: 'biz-456',
          provider: AccountingProvider.quickbooks,
          providerCompanyId: 'realm-789',
          providerCompanyName: 'Test Company LLC',
          accessToken: 'access_token_encrypted',
          refreshToken: 'refresh_token_encrypted',
          tokenExpiresAt: DateTime(2025, 1, 15, 15, 0),
          syncInvoices: true,
          syncPayments: true,
          syncClients: true,
          syncProducts: false,
          incomeAccountId: 'income-1',
          incomeAccountName: 'Services Revenue',
          depositAccountId: 'deposit-1',
          depositAccountName: 'Business Checking',
          taxCodeId: 'tax-1',
          taxCodeName: 'Standard Tax',
          status: ConnectionStatus.active,
          lastSyncAt: DateTime(2025, 1, 15, 14, 30),
          connectedAt: DateTime(2025, 1, 1, 10, 0),
          connectedByUserId: 'user-abc',
          createdAt: DateTime(2025, 1, 1, 10, 0),
          updatedAt: DateTime(2025, 1, 15, 14, 30),
        );

        final json = connection.toJson();
        final restored = AccountingConnection.fromJson(json);

        expect(restored.id, connection.id);
        expect(restored.businessId, connection.businessId);
        expect(restored.provider, connection.provider);
        expect(restored.providerCompanyId, connection.providerCompanyId);
        expect(restored.providerCompanyName, connection.providerCompanyName);
        expect(restored.accessToken, connection.accessToken);
        expect(restored.refreshToken, connection.refreshToken);
        expect(restored.syncInvoices, connection.syncInvoices);
        expect(restored.syncPayments, connection.syncPayments);
        expect(restored.syncClients, connection.syncClients);
        expect(restored.syncProducts, connection.syncProducts);
        expect(restored.incomeAccountId, connection.incomeAccountId);
        expect(restored.depositAccountId, connection.depositAccountId);
        expect(restored.taxCodeId, connection.taxCodeId);
        expect(restored.status, connection.status);
        expect(restored.connectedByUserId, connection.connectedByUserId);
      });

      test('handles null optional fields', () {
        final connection = AccountingConnection(
          id: 'conn-123',
          businessId: 'biz-456',
          provider: AccountingProvider.xero,
          providerCompanyId: 'tenant-789',
          accessToken: 'token',
          refreshToken: 'refresh',
          tokenExpiresAt: DateTime(2025, 1, 15),
          connectedAt: DateTime(2025, 1, 1),
        );

        final json = connection.toJson();
        final restored = AccountingConnection.fromJson(json);

        expect(restored.providerCompanyName, isNull);
        expect(restored.incomeAccountId, isNull);
        expect(restored.incomeAccountName, isNull);
        expect(restored.depositAccountId, isNull);
        expect(restored.depositAccountName, isNull);
        expect(restored.taxCodeId, isNull);
        expect(restored.taxCodeName, isNull);
        expect(restored.lastSyncAt, isNull);
        expect(restored.lastSyncError, isNull);
        expect(restored.connectedByUserId, isNull);
      });

      test('handles all provider values', () {
        for (final provider in AccountingProvider.values) {
          final connection = _createConnection(provider: provider);

          final json = connection.toJson();
          final restored = AccountingConnection.fromJson(json);

          expect(restored.provider, provider);
        }
      });

      test('handles all status values', () {
        for (final status in ConnectionStatus.values) {
          final connection = _createConnection(status: status);

          final json = connection.toJson();
          final restored = AccountingConnection.fromJson(json);

          expect(restored.status, status);
        }
      });
    });

    group('Token Expiration', () {
      test('isTokenExpired returns true when expired', () {
        final connection = _createConnection(
          tokenExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(connection.isTokenExpired, isTrue);
      });

      test('isTokenExpired returns false when not expired', () {
        final connection = _createConnection(
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(connection.isTokenExpired, isFalse);
      });

      test('isTokenExpiringSoon returns true within 5 minutes', () {
        final connection = _createConnection(
          tokenExpiresAt: DateTime.now().add(const Duration(minutes: 3)),
        );
        expect(connection.isTokenExpiringSoon, isTrue);
      });

      test('isTokenExpiringSoon returns false beyond 5 minutes', () {
        final connection = _createConnection(
          tokenExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
        expect(connection.isTokenExpiringSoon, isFalse);
      });
    });

    group('Health Status', () {
      test('needsReauth returns true when status is not active', () {
        final connection = _createConnection(
          status: ConnectionStatus.expired,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(connection.needsReauth, isTrue);
      });

      test('needsReauth returns true when token expired', () {
        final connection = _createConnection(
          status: ConnectionStatus.active,
          tokenExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(connection.needsReauth, isTrue);
      });

      test('needsReauth returns false when healthy', () {
        final connection = _createConnection(
          status: ConnectionStatus.active,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(connection.needsReauth, isFalse);
      });

      test('isHealthy returns true when active and not expired', () {
        final connection = _createConnection(
          status: ConnectionStatus.active,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(connection.isHealthy, isTrue);
      });

      test('isHealthy returns false when not active', () {
        final connection = _createConnection(
          status: ConnectionStatus.error,
          tokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );
        expect(connection.isHealthy, isFalse);
      });

      test('isHealthy returns false when token expired', () {
        final connection = _createConnection(
          status: ConnectionStatus.active,
          tokenExpiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(connection.isHealthy, isFalse);
      });
    });

    group('Display Helpers', () {
      test('displayName returns company name when available', () {
        final connection = _createConnection(
          providerCompanyName: 'My Company LLC',
        );
        expect(connection.displayName, 'My Company LLC');
      });

      test('displayName falls back to provider name', () {
        final connection = _createConnection(
          provider: AccountingProvider.quickbooks,
          providerCompanyName: null,
        );
        expect(connection.displayName, 'QuickBooks Online Connection');
      });

      test('syncSummary lists enabled sync options', () {
        final connection = _createConnection(
          syncInvoices: true,
          syncPayments: true,
          syncClients: false,
          syncProducts: false,
        );
        expect(connection.syncSummary, 'Invoices, Payments');
      });

      test('syncSummary returns Nothing when all disabled', () {
        final connection = _createConnection(
          syncInvoices: false,
          syncPayments: false,
          syncClients: false,
          syncProducts: false,
        );
        expect(connection.syncSummary, 'Nothing');
      });

      test('syncSummary lists all options', () {
        final connection = _createConnection(
          syncInvoices: true,
          syncPayments: true,
          syncClients: true,
          syncProducts: true,
        );
        expect(connection.syncSummary, 'Invoices, Payments, Clients, Products');
      });

      test('lastSyncDisplay returns null when no last sync', () {
        final connection = _createConnection(lastSyncAt: null);
        expect(connection.lastSyncDisplay, isNull);
      });

      test('lastSyncDisplay shows "Just now" for recent sync', () {
        final connection = _createConnection(
          lastSyncAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(connection.lastSyncDisplay, 'Just now');
      });

      test('lastSyncDisplay shows minutes ago', () {
        final connection = _createConnection(
          lastSyncAt: DateTime.now().subtract(const Duration(minutes: 15)),
        );
        expect(connection.lastSyncDisplay, '15m ago');
      });

      test('lastSyncDisplay shows hours ago', () {
        final connection = _createConnection(
          lastSyncAt: DateTime.now().subtract(const Duration(hours: 5)),
        );
        expect(connection.lastSyncDisplay, '5h ago');
      });

      test('lastSyncDisplay shows days ago', () {
        final connection = _createConnection(
          lastSyncAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        expect(connection.lastSyncDisplay, '3d ago');
      });
    });

    group('AccountingProvider Extension', () {
      test('displayName returns correct strings', () {
        expect(AccountingProvider.quickbooks.displayName, 'QuickBooks Online');
        expect(AccountingProvider.xero.displayName, 'Xero');
      });

      test('iconAsset returns correct paths', () {
        expect(
          AccountingProvider.quickbooks.iconAsset,
          'assets/icons/quickbooks.png',
        );
        expect(AccountingProvider.xero.iconAsset, 'assets/icons/xero.png');
      });
    });

    group('ConnectionStatus Extension', () {
      test('displayName returns correct strings', () {
        expect(ConnectionStatus.active.displayName, 'Connected');
        expect(ConnectionStatus.expired.displayName, 'Token Expired');
        expect(ConnectionStatus.error.displayName, 'Error');
        expect(ConnectionStatus.disconnected.displayName, 'Disconnected');
      });

      test('isHealthy returns true only for active', () {
        expect(ConnectionStatus.active.isHealthy, isTrue);
        expect(ConnectionStatus.expired.isHealthy, isFalse);
        expect(ConnectionStatus.error.isHealthy, isFalse);
        expect(ConnectionStatus.disconnected.isHealthy, isFalse);
      });
    });
  });
}

/// Helper function to create a test connection with sensible defaults
AccountingConnection _createConnection({
  String id = 'conn-123',
  String businessId = 'biz-456',
  AccountingProvider provider = AccountingProvider.quickbooks,
  String providerCompanyId = 'company-789',
  String? providerCompanyName,
  ConnectionStatus status = ConnectionStatus.active,
  DateTime? tokenExpiresAt,
  bool syncInvoices = true,
  bool syncPayments = true,
  bool syncClients = true,
  bool syncProducts = false,
  DateTime? lastSyncAt,
}) {
  return AccountingConnection(
    id: id,
    businessId: businessId,
    provider: provider,
    providerCompanyId: providerCompanyId,
    providerCompanyName: providerCompanyName,
    accessToken: 'test_access_token',
    refreshToken: 'test_refresh_token',
    tokenExpiresAt: tokenExpiresAt ?? DateTime.now().add(const Duration(hours: 1)),
    syncInvoices: syncInvoices,
    syncPayments: syncPayments,
    syncClients: syncClients,
    syncProducts: syncProducts,
    status: status,
    lastSyncAt: lastSyncAt,
    connectedAt: DateTime(2025, 1, 1),
  );
}
