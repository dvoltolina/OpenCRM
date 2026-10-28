import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/security_context.dart';
import '../models/user_role.dart';
import 'audit_log_repository.dart';

/// Repository for managing user profiles and RBAC.
/// Enforces multi-tenant isolation via businessId.
///
/// Security events (role changes, user deletion) are audit-logged
/// for HIPAA compliance.
class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  /// Get user profile by Firebase Auth UID
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return _fromDocument(doc);
  }

  /// Create or update user profile.
  ///
  /// Logs a `securityEvent` if the user role is changed or a new user is created.
  Future<void> upsertUserProfile({
    required SecurityContext context,
    required UserProfile profile,
  }) async {
    DemoGuardService.assertReadOnly('save user profile');
    // Only owners can create/modify user profiles
    if (!context.isOwner && profile.id != context.userId) {
      throw SecurityException('Only owners can modify other user profiles');
    }

    // Ensure business isolation
    if (profile.businessId != context.businessId) {
      throw SecurityException('Cannot create users for other businesses');
    }

    // Check if user existed and if role changed (for audit logging)
    final existingProfile = await getUserProfile(profile.id);
    final isNewUser = existingProfile == null;
    final roleChanged =
        existingProfile != null && existingProfile.role != profile.role;

    final data = profile.toJson();
    if (data['createdAt'] is DateTime) {
      data['createdAt'] = Timestamp.fromDate(data['createdAt'] as DateTime);
    }
    if (data['lastLoginAt'] is DateTime) {
      data['lastLoginAt'] = Timestamp.fromDate(data['lastLoginAt'] as DateTime);
    }

    await _firestore
        .collection('users')
        .doc(profile.id)
        .set(data, SetOptions(merge: true));

    // Audit log new user creation or role changes (non-blocking)
    // Skip audit for 'pending' businessId - the createWorkspace Cloud Function
    // handles audit logging after the workspace is properly created (HIPAA compliant)
    if (context.businessId != 'pending') {
      if (isNewUser) {
        await _logSecurityEvent(
          context: context,
          targetUserId: profile.id,
          event: 'userCreated',
          newRole: profile.role.name,
        );
      } else if (roleChanged) {
        await _logSecurityEvent(
          context: context,
          targetUserId: profile.id,
          event: 'roleChange',
          oldRole: existingProfile.role.name,
          newRole: profile.role.name,
        );
      }
    }
  }

  /// List all users in a business (admin only)
  Stream<List<UserProfile>> watchBusinessUsers(SecurityContext context) {
    if (!context.isAdmin) {
      throw SecurityException('Only admins can view all users');
    }

    return _firestore
        .collection('users')
        .where('businessId', isEqualTo: context.businessId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_fromDocument)
              .whereType<UserProfile>()
              .toList(),
        );
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    DemoGuardService.assertReadOnly(
      'update login activity',
      showMessage: false,
    );
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete user profile (owner only).
  ///
  /// Logs a `securityEvent` for the deletion.
  Future<void> deleteUserProfile({
    required SecurityContext context,
    required String targetUserId,
  }) async {
    DemoGuardService.assertReadOnly('delete user profile');
    if (!context.isOwner) {
      throw SecurityException('Only owners can delete user profiles');
    }

    // Get target user to verify same business and capture role for audit
    final targetUser = await getUserProfile(targetUserId);
    if (targetUser == null) return;

    context.verifyBusinessAccess(targetUser.businessId);

    await _firestore.collection('users').doc(targetUserId).delete();

    // Audit log user deletion (non-blocking)
    await _logSecurityEvent(
      context: context,
      targetUserId: targetUserId,
      event: 'userDeleted',
      oldRole: targetUser.role.name,
    );
  }

  /// Logs a security event for HIPAA audit trail.
  ///
  /// Errors are swallowed to ensure user operations are non-blocking.
  Future<void> _logSecurityEvent({
    required SecurityContext context,
    required String targetUserId,
    required String event,
    String? oldRole,
    String? newRole,
  }) async {
    try {
      final metadata = <String, dynamic>{'event': event};
      if (oldRole != null) {
        metadata['oldRole'] = oldRole;
      }
      if (newRole != null) {
        metadata['newRole'] = newRole;
      }

      await _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.securityEvent,
          entityType: 'User',
          entityId: targetUserId,
          metadata: metadata,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to log security event (non-blocking)',
        name: 'UserRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  UserProfile? _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data();
    if (raw == null) return null;

    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return UserProfile(
      id: doc.id,
      businessId: raw['businessId'] as String,
      role: parseUserRole(raw['role']),
      providerId: raw['providerId'] as String?,
      clientId: raw['clientId'] as String?,
      email: raw['email'] as String?,
      displayName: raw['displayName'] as String?,
      createdAt: toDate(raw['createdAt']),
      lastLoginAt: raw['lastLoginAt'] != null
          ? toDate(raw['lastLoginAt'])
          : null,
    );
  }
}
