import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/modification_request.dart';
import '../models/security_context.dart';

/// Repository for persisting reschedule/cancellation modification requests.
class ModificationRequestsRepository {
  ModificationRequestsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Creates or updates a modification request.
  Future<void> saveRequest({
    required SecurityContext context,
    required ModificationRequest request,
  }) async {
    DemoGuardService.assertReadOnly('save modification request');
    if (request.businessId != context.businessId) {
      throw SecurityException('Cannot write request for another business');
    }

    await _collection(
      context.businessId,
    ).doc(request.id).set(request.toJson(), SetOptions(merge: true));
  }

  /// Updates request status and decision details.
  Future<void> updateRequestStatus({
    required SecurityContext context,
    required String requestId,
    required ModificationRequestStatus status,
    String? decidedBy,
    String? decisionNotes,
    bool? feeCollected,
  }) async {
    DemoGuardService.assertReadOnly('update modification request');
    final data = <String, dynamic>{
      'status': status.name,
      'decisionAt': FieldValue.serverTimestamp(),
      'decidedBy': decidedBy,
      'decisionNotes': decisionNotes,
      if (feeCollected != null) 'feeCollected': feeCollected,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    data.removeWhere((key, value) => value == null);

    await _collection(context.businessId).doc(requestId).update(data);
  }

  /// Retrieves a single request.
  Future<ModificationRequest?> getRequest({
    required SecurityContext context,
    required String requestId,
  }) async {
    final doc = await _collection(context.businessId).doc(requestId).get();
    if (!doc.exists) return null;
    return ModificationRequest.fromJson(doc.data()!);
  }

  /// Watches pending requests for admin/staff dashboards.
  Stream<List<ModificationRequest>> watchPendingRequests({
    required SecurityContext context,
  }) {
    return _collection(context.businessId)
        .where('status', isEqualTo: ModificationRequestStatus.pending.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ModificationRequest.fromJson(doc.data()))
              .toList(),
        );
  }

  CollectionReference<Map<String, dynamic>> _collection(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('modification_requests');
  }
}
