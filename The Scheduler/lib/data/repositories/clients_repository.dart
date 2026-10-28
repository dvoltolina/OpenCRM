import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/client.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing clients with multi-tenant isolation.
/// All operations enforce businessId filtering and RBAC permissions.
///
/// PHI Access Logging: All read operations are audit logged per HIPAA
/// requirements. Single-entity reads log `phiRead`; list/stream reads
/// log `phiReadList` once per logical action (not per document).
class ClientsRepository {
  ClientsRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Create or update a client
  Future<void> upsertClient({
    required SecurityContext context,
    required Client client,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save client');
    }
    // Verify business access and permissions
    context.verifyBusinessAccess(client.businessId);
    if (!context.role.canManageClients) {
      throw SecurityException('Insufficient permissions to modify clients');
    }

    await _businessClients(
      client.businessId,
    ).doc(client.id).set(client.toJson(), SetOptions(merge: true));
  }

  /// Default limit for client list queries to control Firebase costs.
  static const int defaultLimit = 100;

  /// Watch all clients for a business (admin/staff only)
  ///
  /// [limit] controls max documents returned (default: 100).
  /// Use [startAfter] for pagination with the last client's createdAt.
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<Client>> watchClients(
    SecurityContext context, {
    int limit = defaultLimit,
    DateTime? startAfter,
    bool allowSalesRead = false,
  }) {
    if (!_canReadClients(context, allowSalesRead: allowSalesRead)) {
      throw SecurityException('Insufficient permissions to view all clients');
    }

    Query<Map<String, dynamic>> query = _businessClients(context.businessId)
        .orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }

    query = query.limit(limit);

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => Client.fromJson({'id': doc.id, ...doc.data()}))
                .toList(),
          ),
      context: context,
      entityType: 'Client',
      metadata: {'source': 'watchClients', 'mode': 'list', 'limit': limit},
    );
  }

  /// Get a single client by ID
  ///
  /// Audit: Logs one `phiRead` event when client data is retrieved.
  Future<Client?> getClient({
    required SecurityContext context,
    required String clientId,
    bool allowSalesRead = false,
  }) async {
    final doc = await _businessClients(context.businessId).doc(clientId).get();
    if (!doc.exists) return null;

    final client = Client.fromJson({'id': doc.id, ...doc.data()!});
    if (!(allowSalesRead && context.role == UserRole.sales)) {
      context.verifyClientAccess(client.id, client.businessId);
    }

    // Log PHI read access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'Client',
      entityId: clientId,
      metadata: {'source': 'getClient'},
    )));

    return client;
  }

  /// Search clients by name or email
  ///
  /// [limit] controls max documents fetched from Firestore (default: 100).
  /// Note: Due to Firestore limitations, full-text search requires client-side
  /// filtering. For better search, consider adding a `searchTerms` array field
  /// to clients and using `array-contains-any`, or integrating Algolia/Typesense.
  ///
  /// Audit: Logs one `phiReadList` event on first emission (search query
  /// is not logged to avoid capturing PHI).
  Stream<List<Client>> searchClients({
    required SecurityContext context,
    required String query,
    int limit = defaultLimit,
    bool allowSalesRead = false,
  }) {
    if (!_canReadClients(context, allowSalesRead: allowSalesRead)) {
      throw SecurityException('Insufficient permissions to search clients');
    }

    final queryLower = query.toLowerCase();

    // Fetch limited set ordered by recent activity for better UX
    return _withAuditLogOnFirstEmission(
      stream: _businessClients(context.businessId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Client.fromJson({'id': doc.id, ...doc.data()}))
                .where(
                  (client) =>
                      client.fullName.toLowerCase().contains(queryLower) ||
                      (client.email?.toLowerCase().contains(queryLower) ??
                          false),
                )
                .toList(),
          ),
      context: context,
      entityType: 'Client',
      metadata: {'source': 'searchClients', 'mode': 'search', 'limit': limit},
    );
  }

  /// Fetch clients for a business with pagination support.
  ///
  /// [limit] controls max documents returned (default: 100).
  /// Use [startAfterId] for cursor-based pagination.
  ///
  /// Audit: Logs one `phiReadList` event when client data is retrieved.
  Future<List<Client>> getClients(
    SecurityContext context, {
    int limit = defaultLimit,
    String? startAfterId,
    bool allowSalesRead = false,
  }) async {
    if (!_canReadClients(context, allowSalesRead: allowSalesRead)) {
      throw SecurityException('Insufficient permissions to view all clients');
    }

    Query<Map<String, dynamic>> query = _businessClients(context.businessId)
        .orderBy('createdAt', descending: true);

    if (startAfterId != null) {
      final startDoc =
          await _businessClients(context.businessId).doc(startAfterId).get();
      if (startDoc.exists) {
        query = query.startAfterDocument(startDoc);
      }
    }

    final snapshot = await query.limit(limit).get();
    final clients = snapshot.docs
        .map((doc) => Client.fromJson({'id': doc.id, ...doc.data()}))
        .toList();

    // Log PHI read list access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Client',
      entityId: context.businessId, // High-level identifier for list reads
      metadata: {
        'source': 'getClients',
        'mode': 'list',
        'count': clients.length,
        'limit': limit,
      },
    )));

    return clients;
  }

  /// Delete a client (admin only)
  Future<void> deleteClient({
    required SecurityContext context,
    required String clientId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete client');
    }
    if (!context.role.canManageClients) {
      throw SecurityException('Insufficient permissions to delete clients');
    }

    await _businessClients(context.businessId).doc(clientId).delete();
  }

  /// Create a new client
  Future<void> createClient({
    required SecurityContext context,
    required Client client,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create client');
    }
    context.verifyBusinessAccess(client.businessId);
    if (!context.role.canManageClients) {
      throw SecurityException('Insufficient permissions to create clients');
    }

    await _businessClients(client.businessId)
        .doc(client.id)
        .set(client.toJson());
  }

  /// Update an existing client
  Future<void> updateClient({
    required SecurityContext context,
    required Client client,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update client');
    }
    context.verifyBusinessAccess(client.businessId);
    if (!context.role.canManageClients && context.clientId != client.id) {
      throw SecurityException('Insufficient permissions to update this client');
    }

    await _businessClients(client.businessId)
        .doc(client.id)
        .update(client.toJson());
  }

  /// Get client by Firebase Auth userId
  ///
  /// Used for customer portal authentication to find client profile
  /// linked to Firebase Auth account.
  ///
  /// Audit: Logs one `phiRead` event when client data is retrieved.
  ///
  /// Note: Requires Firestore index on userId field:
  /// businesses/{businessId}/clients - userId (ASC)
  Future<Client?> getClientByUserId({
    required SecurityContext context,
    required String userId,
  }) async {
    final snapshot = await _businessClients(context.businessId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final client = Client.fromJson({'id': doc.id, ...doc.data()});

    // Log PHI read access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'Client',
      entityId: client.id,
      metadata: {'source': 'getClientByUserId'},
    )));

    return client;
  }

  CollectionReference<Map<String, dynamic>> _businessClients(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clients');
  }

  /// Wraps a stream to log one audit event on first emission.
  ///
  /// This is used for HIPAA-compliant logging of list/stream reads,
  /// logging once per logical action rather than per document.
  Stream<List<T>> _withAuditLogOnFirstEmission<T>({
    required Stream<List<T>> stream,
    required SecurityContext context,
    required String entityType,
    required Map<String, dynamic> metadata,
  }) {
    var hasLogged = false;
    return stream.map((data) {
      if (!hasLogged) {
        hasLogged = true;
        unawaited(_auditLogRepository.logEvent(AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: entityType,
          entityId: context.businessId, // High-level identifier for list reads
          metadata: {...metadata, 'count': data.length},
        )));
      }
      return data;
    });
  }

  bool _canReadClients(
    SecurityContext context, {
    bool allowSalesRead = false,
  }) {
    if (context.role.canManageClients) return true;
    if (allowSalesRead && context.role == UserRole.sales) return true;
    return false;
  }
}
