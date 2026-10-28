import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/security_context.dart';
import '../models/waitlist_entry.dart';

/// Repository for managing waitlist entries with multi-tenant isolation.
class WaitlistRepository {
  WaitlistRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('waitlist_entries');
  }

  /// Create or update a waitlist entry.
  Future<void> upsertEntry({
    required SecurityContext context,
    required WaitlistEntry entry,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save waitlist entry');
    }
    entry.enforceAccess(context);

    await _entries(entry.businessId)
        .doc(entry.id)
        .set(entry.toFirestore(), SetOptions(merge: true));
  }

  /// Watch waitlist entries visible to the current actor.
  Stream<List<WaitlistEntry>> watchEntries({
    required SecurityContext context,
    String? serviceId,
    String? providerId,
    WaitlistStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _entries(context.businessId)
        .orderBy('createdAt', descending: false);

    if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }
    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (!context.role.canManageClients && context.clientId != null) {
      query = query.where('clientId', isEqualTo: context.clientId);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => WaitlistEntry.fromFirestore(
                  data: doc.data(),
                  documentId: doc.id,
                ),
              )
              .toList(),
        );
  }

  /// Load entries for matching logic. When a context is provided, access is
  /// restricted to actors that can manage clients. Clients cannot enumerate
  /// other entries.
  Future<List<WaitlistEntry>> loadEntries({
    SecurityContext? context,
    required String businessId,
    String? serviceId,
    String? providerId,
    WaitlistStatus status = WaitlistStatus.active,
    DateTime? notExpiredBefore,
  }) async {
    if (context != null) {
      context.verifyBusinessAccess(businessId);
      if (!context.role.canManageClients) {
        // Clients should not enumerate other waitlist entries.
        if (context.clientId == null) {
          return [];
        }
        return _loadEntriesForClient(
          businessId: businessId,
          clientId: context.clientId!,
          status: status,
        );
      }
    }

    Query<Map<String, dynamic>> query = _entries(businessId)
        .where('status', isEqualTo: status.name);

    if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }
    if (providerId != null) {
      query = query.where('providerId', isEqualTo: providerId);
    }
    if (notExpiredBefore != null) {
      query = query.where(
        'latestDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(notExpiredBefore),
      );
    }

    final snapshot = await query.orderBy('createdAt').get();
    return snapshot.docs
        .map(
          (doc) => WaitlistEntry.fromFirestore(
            data: doc.data(),
            documentId: doc.id,
          ),
        )
        .toList();
  }

  /// Update status and audit timestamps.
  Future<void> updateStatus({
    required String businessId,
    required String entryId,
    required WaitlistStatus status,
    DateTime? lastNotifiedAt,
    DateTime? responseExpiresAt,
    DateTime? expiresAt,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update waitlist entry');
    }
    await _entries(businessId).doc(entryId).update({
      'status': status.name,
      'lastNotifiedAt':
          lastNotifiedAt != null ? Timestamp.fromDate(lastNotifiedAt) : null,
      'responseExpiresAt': responseExpiresAt != null
          ? Timestamp.fromDate(responseExpiresAt)
          : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove entries when they are no longer valid.
  Future<void> deleteEntry({
    required SecurityContext context,
    required WaitlistEntry entry,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete waitlist entry');
    }
    entry.enforceAccess(context);
    await _entries(entry.businessId).doc(entry.id).delete();
  }

  Future<List<WaitlistEntry>> _loadEntriesForClient({
    required String businessId,
    required String clientId,
    required WaitlistStatus status,
  }) async {
    final snapshot = await _entries(businessId)
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map(
          (doc) => WaitlistEntry.fromFirestore(
            data: doc.data(),
            documentId: doc.id,
          ),
        )
        .toList();
  }
}
