import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/client.dart';
import '../../../data/models/client_note.dart';
import '../../../data/models/audit_log.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/audit_log_repository.dart';

/// Repository for sales-facing client notes.
///
/// Scope:
/// - Read/write client notes for the current business
/// - Restrict access to sales/admin/manager roles
/// - Audit PHI access per HIPAA requirements
class SalesNotesRepository {
  SalesNotesRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Stream client notes for a specific client (newest first).
  Stream<List<ClientNote>> watchClientNotes(
    SecurityContext context,
    String clientId,
  ) {
    _assertSalesAccess(context);

    final query = _businessClientNotes(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true);

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => _mapNote(
                    doc: doc,
                  ),
                )
                .toList(),
          ),
      context: context,
      entityType: 'ClientNote',
      metadata: {
        'source': 'salesNotes.watchClientNotes',
        'clientId': clientId,
      },
    );
  }

  /// Add a sales note for a client.
  Future<void> addNote(
    SecurityContext context, {
    required String clientId,
    required String content,
    required NoteType type,
  }) async {
    _assertSalesAccess(context);

    final docRef = _businessClientNotes(context.businessId).doc();
    final createdAt = FieldValue.serverTimestamp();

    await docRef.set({
      'clientId': clientId,
      'content': content,
      'type': type.name,
      'createdByUserId': context.userId,
      'createdByName': context.userFullName ?? 'Sales',
      'createdAt': createdAt,
    });

    // Audit log (best effort, no PHI values in metadata)
    unawaited(_auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'ClientNote',
        entityId: docRef.id,
        metadata: {
          'source': 'salesNotes.addNote',
          'clientId': clientId,
          'type': type.name,
        },
      ),
    ));
  }

  /// Get recent clients the salesperson has interacted with via notes.
  Future<List<Client>> getRecentClients(
    SecurityContext context, {
    int limit = 10,
  }) async {
    _assertSalesAccess(context);

    final notesSnapshot = await _businessClientNotes(context.businessId)
        .where('createdByUserId', isEqualTo: context.userId)
        .orderBy('createdAt', descending: true)
        .limit(limit * 3)
        .get();

    final seen = <String>{};
    final clientIds = <String>[];
    for (final doc in notesSnapshot.docs) {
      final clientId = doc.data()['clientId'] as String?;
      if (clientId == null) continue;
      if (seen.add(clientId)) {
        clientIds.add(clientId);
      }
      if (clientIds.length >= limit) break;
    }

    if (clientIds.isEmpty) return const [];

    final clients = <Client>[];
    final chunks = _chunk(clientIds, 10);
    for (final chunk in chunks) {
      final snapshot = await _businessClients(context.businessId)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      clients.addAll(
        snapshot.docs.map(
          (doc) => Client.fromJson({'id': doc.id, ...doc.data()}),
        ),
      );
    }

    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Client',
      entityId: context.businessId,
      metadata: {
        'source': 'salesNotes.getRecentClients',
        'count': clients.length,
        'limit': limit,
      },
    )));

    return clients;
  }

  /// Count notes created today by the current sales rep (optionally filtered by type).
  Stream<int> watchTodayNoteCount(
    SecurityContext context, {
    NoteType? type,
  }) {
    _assertSalesAccess(context);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    Query<Map<String, dynamic>> query = _businessClientNotes(context.businessId)
        .where('createdByUserId', isEqualTo: context.userId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        );

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    var hasLogged = false;
    return query.snapshots().map((snapshot) {
      if (!hasLogged) {
        hasLogged = true;
        unawaited(_auditLogRepository.logEvent(AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: 'ClientNote',
          entityId: context.businessId,
          metadata: {
            'source': 'salesNotes.watchTodayNoteCount',
            'type': type?.name ?? 'all',
            'count': snapshot.size,
          },
        )));
      }
      return snapshot.size;
    });
  }

  ClientNote _mapNote({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data();
    return ClientNote.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': data['createdAt'] ?? Timestamp.now(),
    });
  }

  CollectionReference<Map<String, dynamic>> _businessClientNotes(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clientNotes');
  }

  CollectionReference<Map<String, dynamic>> _businessClients(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clients');
  }

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
          entityId: context.businessId,
          metadata: {...metadata, 'count': data.length},
        )));
      }
      return data;
    });
  }

  void _assertSalesAccess(SecurityContext context) {
    final role = context.role;
    final hasAccess = role == UserRole.sales || role.canManageClients;
    if (!hasAccess) {
      throw SecurityException('Sales or admin role required to access client notes');
    }
  }

  List<List<String>> _chunk(List<String> input, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < input.length; i += size) {
      chunks.add(
        input.sublist(
          i,
          i + size > input.length ? input.length : i + size,
        ),
      );
    }
    return chunks;
  }
}
