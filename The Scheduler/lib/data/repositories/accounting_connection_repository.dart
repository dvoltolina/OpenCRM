import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/accounting_connection.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';
import '../models/sync_record.dart';
import '../../core/services/encryption_service.dart';
import 'audit_log_repository.dart';

/// Repository for managing accounting software connections.
///
/// Handles OAuth connection storage, token management, and sync tracking
/// for QuickBooks and Xero integrations.
///
/// HIPAA COMPLIANCE: OAuth tokens are encrypted at rest using AES-256-GCM.
/// Tokens are encrypted before storage and decrypted when read.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
class AccountingConnectionRepository {
  AccountingConnectionRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
    EncryptionService? encryptionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository(),
       _encryptionService = encryptionService;

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;
  final EncryptionService? _encryptionService;

  // ============================================================
  // Token Encryption Helpers (HIPAA Compliance)
  // ============================================================

  /// Encrypt a token for storage.
  /// Requires encryption service to be configured for HIPAA compliance.
  String _encryptToken(String token) {
    final service = _encryptionService;
    if (service == null) {
      throw StateError(
        'EncryptionService is required for accounting tokens. '
        'Ensure encryption is configured before creating connections.',
      );
    }
    return service.encrypt(token);
  }

  /// Decrypt a token from storage.
  /// Handles both encrypted and legacy unencrypted tokens.
  String _decryptToken(String encryptedToken) {
    final service = _encryptionService;
    if (service == null) {
      throw StateError(
        'EncryptionService is required to decrypt accounting tokens. '
        'Ensure encryption is configured before reading connections.',
      );
    }

    // Check if token looks encrypted (contains ':' separator from IV:DATA format)
    if (!encryptedToken.contains(':')) {
      // Legacy unencrypted token - return as-is but log warning
      debugPrint(
        'Found unencrypted OAuth token; consider migrating to encrypted storage.',
      );
      return encryptedToken;
    }

    try {
      return service.decrypt(encryptedToken);
    } catch (_) {
      // If decryption fails, token might be unencrypted legacy data
      // Return as-is to avoid breaking existing connections
      debugPrint(
        'Token decryption failed; returning raw value for compatibility.',
      );
      return encryptedToken;
    }
  }

  /// Convert Firestore document to AccountingConnection with decrypted tokens.
  AccountingConnection _fromFirestore(Map<String, dynamic> data) {
    // Decrypt tokens before creating model
    final decryptedData = Map<String, dynamic>.from(data);
    if (data['accessToken'] != null) {
      decryptedData['accessToken'] = _decryptToken(
        data['accessToken'] as String,
      );
    }
    if (data['refreshToken'] != null) {
      decryptedData['refreshToken'] = _decryptToken(
        data['refreshToken'] as String,
      );
    }
    return AccountingConnection.fromJson(decryptedData);
  }

  // ============================================================
  // Collection References
  // ============================================================

  CollectionReference<Map<String, dynamic>> _connectionsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('accountingConnections');
  }

  CollectionReference<Map<String, dynamic>> _syncRecordsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('syncRecords');
  }

  // ============================================================
  // Connection CRUD Operations
  // ============================================================

  /// Create a new accounting connection.
  ///
  /// Called after successful OAuth flow to store connection details.
  /// HIPAA: OAuth tokens are encrypted before storage.
  Future<AccountingConnection> createConnection({
    required SecurityContext context,
    required AccountingProvider provider,
    required String providerCompanyId,
    String? providerCompanyName,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiresAt,
  }) async {
    DemoGuardService.assertReadOnly('connect accounting integration');
    context.verifyBusinessAccess();

    final now = DateTime.now();
    final docRef = _connectionsCollection(context.businessId).doc();

    // HIPAA: Encrypt tokens before storage
    final encryptedAccessToken = _encryptToken(accessToken);
    final encryptedRefreshToken = _encryptToken(refreshToken);

    // Create connection model with plain tokens (for return value)
    final connection = AccountingConnection(
      id: docRef.id,
      businessId: context.businessId,
      provider: provider,
      providerCompanyId: providerCompanyId,
      providerCompanyName: providerCompanyName,
      accessToken: accessToken, // Return plain token to caller
      refreshToken: refreshToken, // Return plain token to caller
      tokenExpiresAt: tokenExpiresAt,
      status: ConnectionStatus.active,
      connectedAt: now,
      connectedByUserId: context.userId,
      createdAt: now,
    );

    // Store with encrypted tokens
    final dataToStore = connection.toJson();
    dataToStore['accessToken'] = encryptedAccessToken;
    dataToStore['refreshToken'] = encryptedRefreshToken;

    await docRef.set(dataToStore);

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connection.id,
        metadata: {
          'action': 'create',
          'provider': provider.name,
          'companyId': providerCompanyId,
        },
      ),
    );

    return connection;
  }

  /// Get the active connection for a business.
  ///
  /// Returns null if no active connection exists.
  /// HIPAA: Tokens are decrypted when reading from storage.
  Future<AccountingConnection?> getActiveConnection({
    required SecurityContext context,
  }) async {
    context.verifyBusinessAccess();

    final query = await _connectionsCollection(
      context.businessId,
    ).where('status', isEqualTo: 'active').limit(1).get();

    if (query.docs.isEmpty) return null;

    return _fromFirestore(query.docs.first.data());
  }

  /// Get a connection by ID.
  /// HIPAA: Tokens are decrypted when reading from storage.
  Future<AccountingConnection?> getConnection({
    required SecurityContext context,
    required String connectionId,
  }) async {
    context.verifyBusinessAccess();

    final doc = await _connectionsCollection(
      context.businessId,
    ).doc(connectionId).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    return _fromFirestore(data);
  }

  /// Get connection for a specific provider.
  /// HIPAA: Tokens are decrypted when reading from storage.
  Future<AccountingConnection?> getConnectionByProvider({
    required SecurityContext context,
    required AccountingProvider provider,
  }) async {
    context.verifyBusinessAccess();

    final query = await _connectionsCollection(
      context.businessId,
    ).where('provider', isEqualTo: provider.name).limit(1).get();

    if (query.docs.isEmpty) return null;

    return _fromFirestore(query.docs.first.data());
  }

  /// Update connection settings.
  Future<AccountingConnection> updateConnection({
    required SecurityContext context,
    required String connectionId,
    bool? syncInvoices,
    bool? syncPayments,
    bool? syncClients,
    bool? syncProducts,
    String? incomeAccountId,
    String? incomeAccountName,
    String? depositAccountId,
    String? depositAccountName,
    String? taxCodeId,
    String? taxCodeName,
  }) async {
    DemoGuardService.assertReadOnly('update accounting integration');
    context.verifyBusinessAccess();

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (syncInvoices != null) updates['syncInvoices'] = syncInvoices;
    if (syncPayments != null) updates['syncPayments'] = syncPayments;
    if (syncClients != null) updates['syncClients'] = syncClients;
    if (syncProducts != null) updates['syncProducts'] = syncProducts;
    if (incomeAccountId != null) updates['incomeAccountId'] = incomeAccountId;
    if (incomeAccountName != null) {
      updates['incomeAccountName'] = incomeAccountName;
    }
    if (depositAccountId != null) {
      updates['depositAccountId'] = depositAccountId;
    }
    if (depositAccountName != null) {
      updates['depositAccountName'] = depositAccountName;
    }
    if (taxCodeId != null) updates['taxCodeId'] = taxCodeId;
    if (taxCodeName != null) updates['taxCodeName'] = taxCodeName;

    await _connectionsCollection(
      context.businessId,
    ).doc(connectionId).update(updates);

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'updateSettings', ...updates},
      ),
    );

    final updated = await getConnection(
      context: context,
      connectionId: connectionId,
    );
    return updated!;
  }

  /// Update OAuth tokens after refresh.
  /// HIPAA: Tokens are encrypted before storage.
  Future<AccountingConnection> updateTokens({
    required SecurityContext context,
    required String connectionId,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiresAt,
  }) async {
    DemoGuardService.assertReadOnly(
      'refresh accounting tokens',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    // HIPAA: Encrypt tokens before storage
    final encryptedAccessToken = _encryptToken(accessToken);
    final encryptedRefreshToken = _encryptToken(refreshToken);

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'accessToken': encryptedAccessToken,
      'refreshToken': encryptedRefreshToken,
      'tokenExpiresAt': tokenExpiresAt.toIso8601String(),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Don't log token values for security
    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'tokenRefresh'},
      ),
    );

    final updated = await getConnection(
      context: context,
      connectionId: connectionId,
    );
    return updated!;
  }

  /// Update last sync status.
  Future<void> updateSyncStatus({
    required SecurityContext context,
    required String connectionId,
    required DateTime lastSyncAt,
    String? lastSyncError,
  }) async {
    DemoGuardService.assertReadOnly(
      'update accounting sync status',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'lastSyncAt': lastSyncAt.toIso8601String(),
      'lastSyncError': lastSyncError,
      'status': lastSyncError != null ? 'error' : 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update connection status.
  Future<void> updateStatus({
    required SecurityContext context,
    required String connectionId,
    required ConnectionStatus status,
    String? errorMessage,
  }) async {
    DemoGuardService.assertReadOnly('update accounting connection');
    context.verifyBusinessAccess();

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'status': status.name,
      'lastSyncError': errorMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'updateStatus', 'status': status.name},
      ),
    );
  }

  /// Disconnect an accounting connection.
  ///
  /// Sets status to disconnected and clears tokens.
  Future<void> disconnectConnection({
    required SecurityContext context,
    required String connectionId,
  }) async {
    DemoGuardService.assertReadOnly('disconnect accounting integration');
    context.verifyBusinessAccess();

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'status': 'disconnected',
      'accessToken': '',
      'refreshToken': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'disconnect'},
      ),
    );
  }

  /// Delete a connection record.
  ///
  /// Requires admin privileges.
  Future<void> deleteConnection({
    required SecurityContext context,
    required String connectionId,
  }) async {
    DemoGuardService.assertReadOnly('delete accounting integration');
    context.verifyBusinessAccess();

    if (!context.isAdmin) {
      throw SecurityException('Admin access required to delete connections');
    }

    await _connectionsCollection(context.businessId).doc(connectionId).delete();

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'delete'},
      ),
    );
  }

  // ============================================================
  // HIPAA Compliance Operations
  // ============================================================

  /// Update HIPAA mode setting.
  ///
  /// When enabled, client data will be de-identified before syncing
  /// unless a BAA has been verified.
  Future<AccountingConnection> updateHipaaMode({
    required SecurityContext context,
    required String connectionId,
    required bool hipaaMode,
  }) async {
    DemoGuardService.assertReadOnly('update accounting HIPAA mode');
    context.verifyBusinessAccess();

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'hipaaMode': hipaaMode,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {'action': 'updateHipaaMode', 'hipaaMode': hipaaMode},
      ),
    );

    final updated = await getConnection(
      context: context,
      connectionId: connectionId,
    );
    return updated!;
  }

  /// Verify BAA (Business Associate Agreement) for HIPAA compliance.
  ///
  /// This is a critical compliance action that allows full PHI sync.
  /// Only QuickBooks supports BAA - Xero does not.
  ///
  /// IMPORTANT: The admin verifying BAA is attesting that a signed
  /// BAA exists with the accounting provider. This should only be
  /// done after confirming the actual BAA paperwork is in place.
  Future<AccountingConnection> verifyBaa({
    required SecurityContext context,
    required String connectionId,
  }) async {
    DemoGuardService.assertReadOnly('verify accounting BAA');
    context.verifyBusinessAccess();

    if (!context.isAdmin) {
      throw SecurityException('Admin access required to verify BAA');
    }

    // Get current connection to check provider
    final connection = await getConnection(
      context: context,
      connectionId: connectionId,
    );

    if (connection == null) {
      throw Exception('Connection not found');
    }

    // Warn if provider doesn't support BAA (Xero)
    if (connection.provider == AccountingProvider.xero) {
      throw Exception(
        'Xero does not currently offer Business Associate Agreements (BAA). '
        'Client data will remain de-identified for HIPAA compliance.',
      );
    }

    final now = DateTime.now();

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'baaVerified': true,
      'baaVerifiedAt': now.toIso8601String(),
      'baaVerifiedByUserId': context.userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // CRITICAL: Log BAA verification for compliance audit trail
    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {
          'action': 'verifyBaa',
          'provider': connection.provider.name,
          'verifiedAt': now.toIso8601String(),
          'verifiedByUserId': context.userId,
          // This is a compliance-critical event
          'complianceEvent': 'BAA_VERIFICATION',
        },
      ),
    );

    final updated = await getConnection(
      context: context,
      connectionId: connectionId,
    );
    return updated!;
  }

  /// Revoke BAA verification.
  ///
  /// Use this if the BAA is no longer valid or was verified in error.
  /// After revocation, data will be de-identified again.
  Future<AccountingConnection> revokeBaaVerification({
    required SecurityContext context,
    required String connectionId,
    required String reason,
  }) async {
    DemoGuardService.assertReadOnly('revoke accounting BAA');
    context.verifyBusinessAccess();

    if (!context.isAdmin) {
      throw SecurityException('Admin access required to revoke BAA');
    }

    await _connectionsCollection(context.businessId).doc(connectionId).update({
      'baaVerified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log revocation for compliance audit trail
    _auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'AccountingConnection',
        entityId: connectionId,
        metadata: {
          'action': 'revokeBaa',
          'reason': reason,
          'revokedByUserId': context.userId,
          'complianceEvent': 'BAA_REVOCATION',
        },
      ),
    );

    final updated = await getConnection(
      context: context,
      connectionId: connectionId,
    );
    return updated!;
  }

  // ============================================================
  // Sync Record Operations
  // ============================================================

  /// Create a sync record.
  Future<SyncRecord> createSyncRecord({
    required SecurityContext context,
    required String connectionId,
    required String localId,
    required SyncLocalType localType,
    required SyncRemoteType remoteType,
    required SyncDirection syncDirection,
    String? remoteId,
    SyncStatus status = SyncStatus.pending,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    DemoGuardService.assertReadOnly(
      'create accounting sync record',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    final now = DateTime.now();
    final docRef = _syncRecordsCollection(context.businessId).doc();

    final record = SyncRecord(
      id: docRef.id,
      businessId: context.businessId,
      connectionId: connectionId,
      localId: localId,
      localType: localType,
      remoteId: remoteId,
      remoteType: remoteType,
      syncedAt: now,
      syncDirection: syncDirection,
      status: status,
      errorMessage: errorMessage,
      metadata: metadata,
      createdAt: now,
    );

    await docRef.set(record.toJson());
    return record;
  }

  /// Get sync record for a local entity.
  ///
  /// Used to check if an entity has already been synced.
  Future<SyncRecord?> getSyncRecord({
    required SecurityContext context,
    required String localId,
    required SyncLocalType localType,
  }) async {
    context.verifyBusinessAccess();

    final query = await _syncRecordsCollection(context.businessId)
        .where('localId', isEqualTo: localId)
        .where('localType', isEqualTo: localType.name)
        .where('status', isEqualTo: 'success')
        .orderBy('syncedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return SyncRecord.fromJson(query.docs.first.data());
  }

  /// Check if an entity has been successfully synced.
  Future<bool> isSynced({
    required SecurityContext context,
    required String localId,
    required SyncLocalType localType,
  }) async {
    final record = await getSyncRecord(
      context: context,
      localId: localId,
      localType: localType,
    );
    return record != null && record.isSuccess;
  }

  /// Update sync record status.
  Future<SyncRecord> updateSyncRecord({
    required SecurityContext context,
    required String recordId,
    required SyncStatus status,
    String? remoteId,
    String? errorMessage,
  }) async {
    DemoGuardService.assertReadOnly(
      'update accounting sync record',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (remoteId != null) updates['remoteId'] = remoteId;
    if (errorMessage != null) updates['errorMessage'] = errorMessage;

    await _syncRecordsCollection(
      context.businessId,
    ).doc(recordId).update(updates);

    final doc = await _syncRecordsCollection(
      context.businessId,
    ).doc(recordId).get();

    return SyncRecord.fromJson(doc.data()!);
  }

  /// Get sync history for an entity.
  Future<List<SyncRecord>> getSyncHistory({
    required SecurityContext context,
    required String localId,
    int limit = 10,
  }) async {
    context.verifyBusinessAccess();

    final query = await _syncRecordsCollection(context.businessId)
        .where('localId', isEqualTo: localId)
        .orderBy('syncedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((d) => SyncRecord.fromJson(d.data())).toList();
  }

  /// Get recent sync records (for sync dashboard).
  Future<List<SyncRecord>> getRecentSyncRecords({
    required SecurityContext context,
    SyncRecordFilter? filter,
  }) async {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _syncRecordsCollection(
      context.businessId,
    );

    if (filter?.connectionId != null) {
      query = query.where('connectionId', isEqualTo: filter!.connectionId);
    }
    if (filter?.localType != null) {
      query = query.where('localType', isEqualTo: filter!.localType!.name);
    }
    if (filter?.status != null) {
      query = query.where('status', isEqualTo: filter!.status!.name);
    }
    if (filter?.startDate != null) {
      query = query.where(
        'syncedAt',
        isGreaterThanOrEqualTo: filter!.startDate!.toIso8601String(),
      );
    }
    if (filter?.endDate != null) {
      query = query.where(
        'syncedAt',
        isLessThanOrEqualTo: filter!.endDate!.toIso8601String(),
      );
    }

    query = query.orderBy('syncedAt', descending: true);
    query = query.limit(filter?.limit ?? 50);

    final result = await query.get();
    return result.docs.map((d) => SyncRecord.fromJson(d.data())).toList();
  }

  /// Get failed sync records that can be retried.
  Future<List<SyncRecord>> getFailedSyncRecords({
    required SecurityContext context,
    required String connectionId,
    int limit = 20,
  }) async {
    context.verifyBusinessAccess();

    final query = await _syncRecordsCollection(context.businessId)
        .where('connectionId', isEqualTo: connectionId)
        .where('status', isEqualTo: 'failed')
        .where('retryCount', isLessThan: 3)
        .orderBy('retryCount')
        .orderBy('syncedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((d) => SyncRecord.fromJson(d.data())).toList();
  }

  /// Increment retry count for a failed sync.
  Future<void> incrementRetryCount({
    required SecurityContext context,
    required String recordId,
  }) async {
    DemoGuardService.assertReadOnly(
      'retry accounting sync',
      showMessage: false,
    );
    context.verifyBusinessAccess();

    await _syncRecordsCollection(context.businessId).doc(recordId).update({
      'retryCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
