import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/security_context.dart';
import '../models/staff_member.dart';

/// Repository for staff management (admin/owner only).
///
/// Reads come from Firestore `/users` filtered by businessId.
/// Mutations go through Cloud Functions for validation/audit logging.
class StaffRepository {
  StaffRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  void _verifyAdmin(SecurityContext context) {
    if (!context.role.canManageUsers) {
      throw SecurityException('Only owners/admins can manage staff');
    }
  }

  bool _canViewStaff(SecurityContext context) {
    return context.role.canManageUsers || context.role.canManageProviders;
  }

  Stream<List<StaffMember>> watchStaffMembers(SecurityContext context) {
    if (!_canViewStaff(context)) {
      throw SecurityException('Only managers or admins can view staff');
    }

    return _firestore
        .collection('users')
        .where('businessId', isEqualTo: context.businessId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffMember.fromFirestore(doc))
              .toList(),
        )
        .handleError((error, stack) {
      throw SecurityException('Failed to load staff');
    });
  }

  Future<StaffMember?> getStaffMember(
    SecurityContext context,
    String userId,
  ) async {
    if (!_canViewStaff(context)) {
      throw SecurityException('Only managers or admins can view staff');
    }
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final member = StaffMember.fromFirestore(doc);
    if (member.businessId.isNotEmpty &&
        member.businessId != context.businessId) {
      throw SecurityException('Access denied');
    }
    return member;
  }

  Future<void> updateStaffRole(
    SecurityContext context,
    String userId,
    UserRole newRole,
  ) async {
    _verifyAdmin(context);
    final callable = _functions.httpsCallable('updateStaffRole');
    await callable.call<Map<String, dynamic>>({
      'businessId': context.businessId,
      'userId': userId,
      'newRole': newRole.name,
    });
  }

  Future<void> deactivateStaff(SecurityContext context, String userId) async {
    _verifyAdmin(context);
    final callable = _functions.httpsCallable('deactivateStaff');
    await callable.call<Map<String, dynamic>>({
      'businessId': context.businessId,
      'userId': userId,
    });
  }

  Future<void> reactivateStaff(SecurityContext context, String userId) async {
    _verifyAdmin(context);
    final callable = _functions.httpsCallable('reactivateStaff');
    await callable.call<Map<String, dynamic>>({
      'businessId': context.businessId,
      'userId': userId,
    });
  }
}
