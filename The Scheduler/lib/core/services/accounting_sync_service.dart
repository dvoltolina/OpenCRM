import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/accounting_connection.dart';
import '../../data/models/client.dart';
import '../../data/models/payment.dart';
import '../../data/models/security_context.dart';
import '../../data/models/sync_record.dart';
import '../../data/repositories/accounting_connection_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/payment_repository.dart';
import 'accounting_oauth_service.dart';

/// Result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.items,
    this.error,
    this.duration,
  });

  final int successCount;
  final int failedCount;
  final int skippedCount;
  final List<SyncItemResult> items;
  final String? error;
  final Duration? duration;

  bool get hasErrors => failedCount > 0 || error != null;
  int get totalCount => successCount + failedCount + skippedCount;

  String get summary {
    if (error != null) return 'Sync failed: $error';
    return 'Synced $successCount, failed $failedCount, skipped $skippedCount';
  }
}

/// Result of syncing a single item.
class SyncItemResult {
  const SyncItemResult({
    required this.localId,
    required this.localType,
    required this.status,
    this.remoteId,
    this.error,
  });

  final String localId;
  final SyncLocalType localType;
  final SyncStatus status;
  final String? remoteId;
  final String? error;

  bool get isSuccess => status == SyncStatus.success;
  bool get isFailed => status == SyncStatus.failed;
  bool get isSkipped => status == SyncStatus.skipped;
}

/// Service for syncing data to accounting systems (QuickBooks, Xero).
///
/// Handles:
/// - Syncing clients/customers (with HIPAA-compliant de-identification)
/// - Syncing payments as invoices + payments (with generic descriptions)
/// - Tracking sync status via SyncRecords
/// - Error handling and retry logic
///
/// HIPAA COMPLIANCE:
/// When `connection.requiresDeidentification` is true (default for healthcare):
/// - Client data is anonymized: "Client-XXXXXXXX" format
/// - No emails, phones, or addresses are synced
/// - Invoice descriptions use generic text: "Professional Services"
/// - Service/treatment names are NEVER included
///
/// Full data sync only occurs when:
/// - HIPAA mode is disabled, OR
/// - BAA is verified AND provider is QuickBooks (Xero has no BAA)
///
/// All API calls go through Cloud Functions to protect OAuth secrets.
class AccountingSyncService {
  AccountingSyncService({
    AccountingConnectionRepository? connectionRepository,
    AccountingOAuthService? oauthService,
    ClientsRepository? clientsRepository,
    PaymentRepository? paymentRepository,
    FirebaseFunctions? functions,
  })  : _connectionRepo = connectionRepository ?? AccountingConnectionRepository(),
        _oauthService = oauthService ?? AccountingOAuthService(),
        _clientsRepo = clientsRepository ?? ClientsRepository(),
        _paymentRepo = paymentRepository ?? PaymentRepository(),
        _functions = functions ?? FirebaseFunctions.instance;

  final AccountingConnectionRepository _connectionRepo;
  final AccountingOAuthService _oauthService;
  final ClientsRepository _clientsRepo;
  final PaymentRepository _paymentRepo;
  final FirebaseFunctions _functions;

  // ============================================================
  // Main Sync Flow
  // ============================================================

  /// Sync all enabled data to accounting system.
  ///
  /// Syncs clients first (needed for payment customer references),
  /// then syncs payments.
  Future<SyncResult> syncToAccounting({
    required SecurityContext context,
  }) async {
    final stopwatch = Stopwatch()..start();
    final items = <SyncItemResult>[];

    try {
      // Get active connection
      final connection = await _oauthService.getActiveConnection(
        context: context,
      );

      if (connection == null) {
        return SyncResult(
          successCount: 0,
          failedCount: 0,
          skippedCount: 0,
          items: [],
          error: 'No active accounting connection',
          duration: stopwatch.elapsed,
        );
      }

      // Ensure token is valid
      final validConnection = await _oauthService.ensureValidToken(
        context: context,
        connection: connection,
      );

      // Sync clients first (needed for payment customer references)
      if (validConnection.syncClients) {
        final clientResults = await _syncClients(
          context: context,
          connection: validConnection,
        );
        items.addAll(clientResults);
      }

      // Sync payments
      if (validConnection.syncPayments) {
        final paymentResults = await _syncPayments(
          context: context,
          connection: validConnection,
        );
        items.addAll(paymentResults);
      }

      // Update last sync time
      await _connectionRepo.updateSyncStatus(
        context: context,
        connectionId: validConnection.id,
        lastSyncAt: DateTime.now(),
      );

      stopwatch.stop();

      final successCount = items.where((i) => i.isSuccess).length;
      final failedCount = items.where((i) => i.isFailed).length;
      final skippedCount = items.where((i) => i.isSkipped).length;

      return SyncResult(
        successCount: successCount,
        failedCount: failedCount,
        skippedCount: skippedCount,
        items: items,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Sync failed');

      return SyncResult(
        successCount: items.where((i) => i.isSuccess).length,
        failedCount: items.where((i) => i.isFailed).length,
        skippedCount: items.where((i) => i.isSkipped).length,
        items: items,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync a single payment manually.
  Future<SyncItemResult> syncSinglePayment({
    required SecurityContext context,
    required String paymentId,
  }) async {
    final connection = await _oauthService.getActiveConnection(context: context);
    if (connection == null) {
      return SyncItemResult(
        localId: paymentId,
        localType: SyncLocalType.payment,
        status: SyncStatus.failed,
        error: 'No active accounting connection',
      );
    }

    final validConnection = await _oauthService.ensureValidToken(
      context: context,
      connection: connection,
    );

    final payment = await _paymentRepo.getPaymentById(context, paymentId);

    if (payment == null) {
      return SyncItemResult(
        localId: paymentId,
        localType: SyncLocalType.payment,
        status: SyncStatus.failed,
        error: 'Payment not found',
      );
    }

    return _syncSinglePayment(
      context: context,
      connection: validConnection,
      payment: payment,
    );
  }

  // ============================================================
  // HIPAA De-identification Helpers
  // ============================================================

  /// Creates a de-identified customer record for HIPAA compliance.
  ///
  /// When PHI cannot be synced (no BAA or Xero provider), this method
  /// creates an anonymized customer record that protects client identity.
  Map<String, dynamic> _createDeidentifiedClient(Client client) {
    // Use first 8 characters of ID for readable but anonymous identifier
    final anonymousId = client.id.length >= 8
        ? client.id.substring(0, 8)
        : client.id;

    return {
      'id': client.id,
      'displayName': 'Client-$anonymousId',
      // DO NOT include email, phone, firstName, lastName, address
      // These are PHI when associated with a healthcare client
      'email': null,
      'phone': null,
      'firstName': null,
      'lastName': null,
      'notes': 'Internal Reference: ${client.id}',
      'isDeidentified': true,
    };
  }

  /// Creates a full customer record (only when BAA is verified).
  Map<String, dynamic> _createFullClient(Client client) {
    return {
      'id': client.id,
      'displayName': client.fullName,
      'email': client.email,
      'phone': client.phone,
      'firstName': client.firstName,
      'lastName': client.lastName,
      'isDeidentified': false,
    };
  }

  /// Creates a de-identified payment/invoice record for HIPAA compliance.
  ///
  /// Service names and treatment details are replaced with generic text.
  Map<String, dynamic> _createDeidentifiedPayment(Payment payment, String? customerId) {
    return {
      'id': payment.id,
      'amountCents': payment.amountCents,
      // HIPAA: Use generic description, NEVER include service/treatment names
      'description': 'Professional Services',
      'appointmentId': payment.appointmentId,
      'date': payment.createdAt.toIso8601String(),
      'type': payment.type.name,
      'customerId': customerId,
      'isDeidentified': true,
    };
  }

  /// Creates a full payment record (only when BAA is verified).
  Map<String, dynamic> _createFullPayment(Payment payment, String? customerId) {
    return {
      'id': payment.id,
      'amountCents': payment.amountCents,
      'description': payment.paymentMethodDescription ?? 'Service Payment',
      'appointmentId': payment.appointmentId,
      'date': payment.createdAt.toIso8601String(),
      'type': payment.type.name,
      'customerId': customerId,
      'isDeidentified': false,
    };
  }

  // ============================================================
  // Client Sync
  // ============================================================

  /// Sync clients to accounting system as customers.
  ///
  /// HIPAA: When `connection.requiresDeidentification` is true,
  /// client data is anonymized before sending to the accounting system.
  Future<List<SyncItemResult>> _syncClients({
    required SecurityContext context,
    required AccountingConnection connection,
  }) async {
    final results = <SyncItemResult>[];

    try {
      // Get clients that haven't been synced
      final clients = await _getUnsyncedClients(context);

      for (final client in clients) {
        try {
          final result = await _syncSingleClient(
            context: context,
            connection: connection,
            client: client,
          );
          results.add(result);

          // Rate limiting - small delay between items
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          results.add(SyncItemResult(
            localId: client.id,
            localType: SyncLocalType.client,
            status: SyncStatus.failed,
            error: e.toString(),
          ));
        }
      }
    } catch (e) {
      debugPrint('Failed to sync clients');
    }

    return results;
  }

  Future<SyncItemResult> _syncSingleClient({
    required SecurityContext context,
    required AccountingConnection connection,
    required Client client,
  }) async {
    // Check if already synced
    final existingSync = await _connectionRepo.getSyncRecord(
      context: context,
      localId: client.id,
      localType: SyncLocalType.client,
    );

    if (existingSync != null && existingSync.isSuccess) {
      return SyncItemResult(
        localId: client.id,
        localType: SyncLocalType.client,
        status: SyncStatus.skipped,
        remoteId: existingSync.remoteId,
      );
    }

    // HIPAA: Determine if de-identification is required
    final requiresDeidentification = connection.requiresDeidentification;

    // Create sync record in pending state
    // HIPAA: Only log non-PHI metadata when de-identification is required
    final syncRecord = await _connectionRepo.createSyncRecord(
      context: context,
      connectionId: connection.id,
      localId: client.id,
      localType: SyncLocalType.client,
      remoteType: connection.provider == AccountingProvider.xero
          ? SyncRemoteType.contact
          : SyncRemoteType.customer,
      syncDirection: SyncDirection.toAccounting,
      status: SyncStatus.pending,
      metadata: requiresDeidentification
          ? {'deidentified': true}
          : {'email': client.email, 'name': client.fullName},
    );

    try {
      // HIPAA: Use appropriate client data based on de-identification requirement
      final clientData = requiresDeidentification
          ? _createDeidentifiedClient(client)
          : _createFullClient(client);

      debugPrint(
        'Syncing client (deidentified: $requiresDeidentification, '
        'hipaaMode: ${connection.hipaaMode}, '
        'baaVerified: ${connection.baaVerified})',
      );

      // Call Cloud Function to create customer
      final callable = _functions.httpsCallable('syncClientToAccounting');
      final result = await callable.call<Map<String, dynamic>>({
        'provider': connection.provider.name,
        'accessToken': connection.accessToken,
        'companyId': connection.providerCompanyId,
        'client': clientData,
        'hipaaMode': connection.hipaaMode,
        'isDeidentified': requiresDeidentification,
      });

      final data = result.data;

      if (data['error'] != null) {
        await _connectionRepo.updateSyncRecord(
          context: context,
          recordId: syncRecord.id,
          status: SyncStatus.failed,
          errorMessage: data['error'] as String,
        );

        return SyncItemResult(
          localId: client.id,
          localType: SyncLocalType.client,
          status: SyncStatus.failed,
          error: data['error'] as String,
        );
      }

      // Update sync record with success
      final remoteId = data['customerId'] as String;
      await _connectionRepo.updateSyncRecord(
        context: context,
        recordId: syncRecord.id,
        status: SyncStatus.success,
        remoteId: remoteId,
      );

      return SyncItemResult(
        localId: client.id,
        localType: SyncLocalType.client,
        status: SyncStatus.success,
        remoteId: remoteId,
      );
    } catch (e) {
      await _connectionRepo.updateSyncRecord(
        context: context,
        recordId: syncRecord.id,
        status: SyncStatus.failed,
        errorMessage: e.toString(),
      );

      return SyncItemResult(
        localId: client.id,
        localType: SyncLocalType.client,
        status: SyncStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<List<Client>> _getUnsyncedClients(SecurityContext context) async {
    // Get all clients
    final clients = await _clientsRepo.getClients(context);

    // Filter out already synced ones
    final unsynced = <Client>[];
    for (final client in clients) {
      final isSynced = await _connectionRepo.isSynced(
        context: context,
        localId: client.id,
        localType: SyncLocalType.client,
      );
      if (!isSynced) {
        unsynced.add(client);
      }
    }

    return unsynced;
  }

  // ============================================================
  // Payment Sync
  // ============================================================

  /// Sync payments to accounting system.
  Future<List<SyncItemResult>> _syncPayments({
    required SecurityContext context,
    required AccountingConnection connection,
  }) async {
    final results = <SyncItemResult>[];

    try {
      // Get payments that haven't been synced
      final payments = await _getUnsyncedPayments(context);

      for (final payment in payments) {
        try {
          final result = await _syncSinglePayment(
            context: context,
            connection: connection,
            payment: payment,
          );
          results.add(result);

          // Rate limiting
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          results.add(SyncItemResult(
            localId: payment.id,
            localType: SyncLocalType.payment,
            status: SyncStatus.failed,
            error: e.toString(),
          ));
        }
      }
    } catch (e) {
      debugPrint('Failed to sync payments');
    }

    return results;
  }

  Future<SyncItemResult> _syncSinglePayment({
    required SecurityContext context,
    required AccountingConnection connection,
    required Payment payment,
  }) async {
    // Check if already synced
    final existingSync = await _connectionRepo.getSyncRecord(
      context: context,
      localId: payment.id,
      localType: SyncLocalType.payment,
    );

    if (existingSync != null && existingSync.isSuccess) {
      return SyncItemResult(
        localId: payment.id,
        localType: SyncLocalType.payment,
        status: SyncStatus.skipped,
        remoteId: existingSync.remoteId,
      );
    }

    // Get customer ID from synced client
    final clientSync = await _connectionRepo.getSyncRecord(
      context: context,
      localId: payment.clientId,
      localType: SyncLocalType.client,
    );
    final customerId = clientSync?.remoteId;

    // HIPAA: Determine if de-identification is required
    final requiresDeidentification = connection.requiresDeidentification;

    // Create sync record in pending state
    final syncRecord = await _connectionRepo.createSyncRecord(
      context: context,
      connectionId: connection.id,
      localId: payment.id,
      localType: SyncLocalType.payment,
      remoteType: SyncRemoteType.payment,
      syncDirection: SyncDirection.toAccounting,
      status: SyncStatus.pending,
      metadata: {
        'amount': payment.amountCents,
        'appointmentId': payment.appointmentId,
        'deidentified': requiresDeidentification,
      },
    );

    try {
      // HIPAA: Use appropriate payment data based on de-identification requirement
      final paymentData = requiresDeidentification
          ? _createDeidentifiedPayment(payment, customerId)
          : _createFullPayment(payment, customerId);

      final hasDescription =
          (paymentData['description'] as String?)?.isNotEmpty ?? false;
      debugPrint(
        'Syncing payment (deidentified: $requiresDeidentification, '
        'hasDescription: $hasDescription)',
      );

      // Call Cloud Function to create invoice + payment
      final callable = _functions.httpsCallable('syncPaymentToAccounting');
      final result = await callable.call<Map<String, dynamic>>({
        'provider': connection.provider.name,
        'accessToken': connection.accessToken,
        'companyId': connection.providerCompanyId,
        'incomeAccountId': connection.incomeAccountId,
        'depositAccountId': connection.depositAccountId,
        'taxCodeId': connection.taxCodeId,
        'payment': paymentData,
        'hipaaMode': connection.hipaaMode,
        'isDeidentified': requiresDeidentification,
      });

      final data = result.data;

      if (data['error'] != null) {
        await _connectionRepo.updateSyncRecord(
          context: context,
          recordId: syncRecord.id,
          status: SyncStatus.failed,
          errorMessage: data['error'] as String,
        );

        return SyncItemResult(
          localId: payment.id,
          localType: SyncLocalType.payment,
          status: SyncStatus.failed,
          error: data['error'] as String,
        );
      }

      // Update sync record with success
      final remoteId = data['paymentId'] as String;
      await _connectionRepo.updateSyncRecord(
        context: context,
        recordId: syncRecord.id,
        status: SyncStatus.success,
        remoteId: remoteId,
      );

      return SyncItemResult(
        localId: payment.id,
        localType: SyncLocalType.payment,
        status: SyncStatus.success,
        remoteId: remoteId,
      );
    } catch (e) {
      await _connectionRepo.updateSyncRecord(
        context: context,
        recordId: syncRecord.id,
        status: SyncStatus.failed,
        errorMessage: e.toString(),
      );

      return SyncItemResult(
        localId: payment.id,
        localType: SyncLocalType.payment,
        status: SyncStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<List<Payment>> _getUnsyncedPayments(SecurityContext context) async {
    // Get all payments
    final payments = await _paymentRepo.fetchPayments(context);

    // Filter to completed and not synced
    final unsynced = <Payment>[];
    for (final payment in payments) {
      if (payment.status != PaymentStatus.completed) continue;

      final isSynced = await _connectionRepo.isSynced(
        context: context,
        localId: payment.id,
        localType: SyncLocalType.payment,
      );
      if (!isSynced) {
        unsynced.add(payment);
      }
    }

    return unsynced;
  }

  // ============================================================
  // Retry Failed Syncs
  // ============================================================

  /// Retry failed sync records.
  Future<SyncResult> retryFailedSyncs({
    required SecurityContext context,
  }) async {
    final stopwatch = Stopwatch()..start();
    final items = <SyncItemResult>[];

    try {
      final connection = await _oauthService.getActiveConnection(context: context);
      if (connection == null) {
        return SyncResult(
          successCount: 0,
          failedCount: 0,
          skippedCount: 0,
          items: [],
          error: 'No active accounting connection',
          duration: stopwatch.elapsed,
        );
      }

      final validConnection = await _oauthService.ensureValidToken(
        context: context,
        connection: connection,
      );

      // Get failed records that can be retried
      final failedRecords = await _connectionRepo.getFailedSyncRecords(
        context: context,
        connectionId: validConnection.id,
      );

      for (final record in failedRecords) {
        // Increment retry count
        await _connectionRepo.incrementRetryCount(
          context: context,
          recordId: record.id,
        );

        // Retry based on type
        SyncItemResult? result;
        switch (record.localType) {
          case SyncLocalType.client:
            final client = await _clientsRepo.getClient(
              context: context,
              clientId: record.localId,
            );
            if (client != null) {
              result = await _syncSingleClient(
                context: context,
                connection: validConnection,
                client: client,
              );
            }
            break;

          case SyncLocalType.payment:
            final payment = await _paymentRepo.getPaymentById(
              context,
              record.localId,
            );
            if (payment != null) {
              result = await _syncSinglePayment(
                context: context,
                connection: validConnection,
                payment: payment,
              );
            }
            break;

          default:
            result = SyncItemResult(
              localId: record.localId,
              localType: record.localType,
              status: SyncStatus.skipped,
              error: 'Unsupported sync type for retry',
            );
        }

        if (result != null) {
          items.add(result);
        }

        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      stopwatch.stop();

      return SyncResult(
        successCount: items.where((i) => i.isSuccess).length,
        failedCount: items.where((i) => i.isFailed).length,
        skippedCount: items.where((i) => i.isSkipped).length,
        items: items,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return SyncResult(
        successCount: 0,
        failedCount: 0,
        skippedCount: 0,
        items: items,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  // ============================================================
  // Sync Status
  // ============================================================

  /// Get sync status summary for dashboard.
  Future<SyncStatusSummary> getSyncStatus({
    required SecurityContext context,
  }) async {
    final connection = await _oauthService.getActiveConnection(context: context);

    if (connection == null) {
      return const SyncStatusSummary(
        isConnected: false,
        provider: null,
        lastSyncAt: null,
        pendingCount: 0,
        failedCount: 0,
      );
    }

    // Get counts
    final recentRecords = await _connectionRepo.getRecentSyncRecords(
      context: context,
      filter: SyncRecordFilter(connectionId: connection.id, limit: 100),
    );

    final pendingCount = recentRecords.where((r) => r.status == SyncStatus.pending).length;
    final failedCount = recentRecords.where((r) => r.status == SyncStatus.failed).length;

    return SyncStatusSummary(
      isConnected: connection.isHealthy,
      provider: connection.provider,
      lastSyncAt: connection.lastSyncAt,
      pendingCount: pendingCount,
      failedCount: failedCount,
      lastError: connection.lastSyncError,
      connectionStatus: connection.status,
      // HIPAA compliance info
      hipaaMode: connection.hipaaMode,
      baaVerified: connection.baaVerified,
      requiresDeidentification: connection.requiresDeidentification,
    );
  }
}

/// Summary of sync status for dashboard display.
class SyncStatusSummary {
  const SyncStatusSummary({
    required this.isConnected,
    required this.provider,
    required this.lastSyncAt,
    required this.pendingCount,
    required this.failedCount,
    this.lastError,
    this.connectionStatus,
    this.hipaaMode = true,
    this.baaVerified = false,
    this.requiresDeidentification = true,
  });

  final bool isConnected;
  final AccountingProvider? provider;
  final DateTime? lastSyncAt;
  final int pendingCount;
  final int failedCount;
  final String? lastError;
  final ConnectionStatus? connectionStatus;

  // HIPAA Compliance Status
  final bool hipaaMode;
  final bool baaVerified;
  final bool requiresDeidentification;

  bool get hasIssues => failedCount > 0 || lastError != null;
  bool get needsAttention => !isConnected || hasIssues;

  String get statusText {
    if (!isConnected) return 'Not connected';
    if (connectionStatus == ConnectionStatus.expired) return 'Token expired';
    if (connectionStatus == ConnectionStatus.error) return 'Connection error';
    if (failedCount > 0) return '$failedCount sync failures';
    return 'Connected';
  }

  /// HIPAA compliance status text for display.
  String get hipaaStatusText {
    if (!hipaaMode) return 'HIPAA mode disabled';
    if (baaVerified) return 'BAA verified - full sync enabled';
    return 'De-identified sync (BAA not verified)';
  }

  /// Whether the provider supports BAA.
  bool get providerSupportsBaa => provider == AccountingProvider.quickbooks;
}
