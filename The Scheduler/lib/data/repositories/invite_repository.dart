import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/staff_invite.dart';
import '../models/security_context.dart';

class InviteResult {
  const InviteResult({
    required this.inviteId,
    required this.code,
    required this.link,
    required this.expiresAt,
  });

  final String inviteId;
  final String code;
  final String link;
  final DateTime expiresAt;
}

/// Repository for staff invite management (admin/owner).
class InviteRepository {
  InviteRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  void _verifyAdmin(SecurityContext context) {
    if (!context.role.canManageUsers) {
      throw SecurityException('Only owners/admins can manage invites');
    }
  }

  Stream<List<StaffInvite>> watchPendingInvites(SecurityContext context) {
    _verifyAdmin(context);

    return _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('invites')
        .where(
          'status',
          whereIn: [
            StaffInviteStatus.pending.name,
            StaffInviteStatus.active.name,
          ],
        )
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StaffInvite.fromFirestore)
              .toList(growable: false),
        )
        .handleError((_) => throw SecurityException('Failed to load invites'));
  }

  Future<InviteResult> createStaffInvite(
    SecurityContext context, {
    String? email,
    required UserRole role,
    required Duration expiresIn,
    required int maxUses,
  }) async {
    DemoGuardService.assertReadOnly('create staff invite');
    _verifyAdmin(context);

    final callable = _functions.httpsCallable('createStaffInvite');
    final result = await callable.call<Map<String, dynamic>>({
      'businessId': context.businessId,
      'email': email,
      'role': role.name,
      'expiresInDays': expiresIn.inDays,
      'maxUses': maxUses,
    });

    final data = result.data;
    final inviteId = data['inviteId'] as String?;
    final code = data['code'] as String?;
    final link =
        (data['link'] as String?) ?? (code != null ? getInviteLink(code) : '');
    final expiresAtRaw = data['expiresAt'];

    if (inviteId == null || code == null || expiresAtRaw == null) {
      throw Exception('Invalid response from createStaffInvite');
    }

    final expiresAt =
        DateTime.tryParse(expiresAtRaw.toString()) ??
        DateTime.now().add(expiresIn);

    return InviteResult(
      inviteId: inviteId,
      code: code,
      link: link,
      expiresAt: expiresAt,
    );
  }

  Future<void> revokeInvite(SecurityContext context, String inviteId) async {
    DemoGuardService.assertReadOnly('revoke staff invite');
    _verifyAdmin(context);
    final callable = _functions.httpsCallable('revokeStaffInvite');
    await callable.call<Map<String, dynamic>>({
      'businessId': context.businessId,
      'inviteId': inviteId,
    });
  }

  String getInviteLink(String code) {
    return 'https://app.example.com/join/$code';
  }
}
