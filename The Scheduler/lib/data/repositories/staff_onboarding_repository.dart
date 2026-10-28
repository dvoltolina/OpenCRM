import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/security_context.dart';
import 'audit_log_repository.dart';

// TODO: Import models when Agent RW1 completes them
// import '../models/join_code.dart';
// import '../models/invite.dart';
// import '../models/join_request.dart';

/// Repository for managing staff onboarding via join codes, invites, and join requests.
///
/// Security requirements:
/// - All mutation operations (create/revoke/review) MUST call Cloud Functions
///   for proper audit logging and validation
/// - Only owners/admins can manage join codes and invites
/// - Read operations use Firestore streams with SecurityContext enforcement
/// - No direct Firestore writes from client for mutations
///
/// HIPAA compliance:
/// - All operations are audit logged
/// - No PHI in join codes, invites, or requests
/// - Generic error messages to prevent user enumeration
class StaffOnboardingRepository {
  StaffOnboardingRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AuditLogRepository? auditLog,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auditLog = auditLog ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AuditLogRepository _auditLog;

  // ============================================================
  // JOIN CODES
  // ============================================================

  /// Watch all join codes for a business (owner/admin only).
  ///
  /// Returns a stream of all join codes ordered by creation date (newest first).
  /// Throws SecurityException if user is not an owner or admin.
  Stream<List<dynamic>> watchJoinCodes(SecurityContext context) {
    _verifyAdminAccess(context);

    // Log phiReadList for HIPAA compliance (non-blocking)
    _logReadAccess(
      context: context,
      entityType: 'JoinCode',
      entityId: 'list',
      action: 'watchJoinCodes',
    );

    return _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('join_codes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // TODO: Replace with JoinCode.fromFirestore when model is ready
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }).handleError((error, stackTrace) {
      developer.log(
        'Error watching join codes',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    });
  }

  /// Get a single join code by ID.
  ///
  /// Returns null if the code doesn't exist.
  /// Throws SecurityException if user is not an owner or admin.
  Future<Map<String, dynamic>?> getJoinCode(
    SecurityContext context,
    String codeId,
  ) async {
    _verifyAdminAccess(context);

    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('join_codes')
          .doc(codeId)
          .get();

      if (!doc.exists) return null;

      // Log phiRead for HIPAA compliance (non-blocking)
      _logReadAccess(
        context: context,
        entityType: 'JoinCode',
        entityId: codeId,
        action: 'getJoinCode',
      );

      // TODO: Replace with JoinCode.fromFirestore when model is ready
      final data = doc.data();
      if (data == null) return null;

      return {
        'id': doc.id,
        ...data,
      };
    } catch (error, stackTrace) {
      developer.log(
        'Error getting join code',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  /// Create a join code (calls Cloud Function, not direct write).
  ///
  /// Returns the join code ID on success.
  /// Throws SecurityException if user is not an owner or admin.
  ///
  /// Cloud Function handles:
  /// - Generating secure random code
  /// - Hashing code for storage
  /// - Audit logging
  /// - Validation
  Future<String> createJoinCode({
    required SecurityContext context,
    required String role,
    DateTime? expiresAt,
    int? maxUses,
    String? notes,
  }) async {
    _verifyAdminAccess(context);

    try {
      final callable = _functions.httpsCallable('createJoinCode');
      final result = await callable.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'role': role,
        'expiresAt': expiresAt?.toIso8601String(),
        'maxUses': maxUses,
        'notes': notes,
      });

      final data = result.data;
      if (data['codeId'] == null) {
        throw Exception('Invalid response from createJoinCode function');
      }

      return data['codeId'] as String;
    } catch (error, stackTrace) {
      developer.log(
        'Error creating join code',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  /// Revoke a join code (calls Cloud Function).
  ///
  /// Throws SecurityException if user is not an owner or admin.
  ///
  /// Cloud Function handles:
  /// - Validation
  /// - Updating status to 'revoked'
  /// - Audit logging
  Future<void> revokeJoinCode(SecurityContext context, String codeId) async {
    _verifyAdminAccess(context);

    try {
      final callable = _functions.httpsCallable('revokeJoinCode');
      await callable.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'codeId': codeId,
      });
    } catch (error, stackTrace) {
      developer.log(
        'Error revoking join code',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  // ============================================================
  // INVITES
  // ============================================================

  /// Watch all invites for a business.
  ///
  /// Returns a stream of all invites ordered by creation date (newest first).
  /// Throws SecurityException if user is not an owner or admin.
  Stream<List<dynamic>> watchInvites(SecurityContext context) {
    _verifyAdminAccess(context);

    // Log phiReadList for HIPAA compliance (non-blocking)
    _logReadAccess(
      context: context,
      entityType: 'Invite',
      entityId: 'list',
      action: 'watchInvites',
    );

    return _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // TODO: Replace with Invite.fromFirestore when model is ready
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }).handleError((error, stackTrace) {
      developer.log(
        'Error watching invites',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    });
  }

  /// Create an invite (calls Cloud Function).
  ///
  /// Returns the invite ID on success.
  /// Throws SecurityException if user is not an owner or admin.
  ///
  /// Cloud Function handles:
  /// - Generating secure random token
  /// - Hashing token for storage
  /// - Sending email to recipient
  /// - Audit logging
  /// - Validation
  Future<String> createInvite({
    required SecurityContext context,
    required String email,
    required String role,
    DateTime? expiresAt,
    String? notes,
  }) async {
    _verifyAdminAccess(context);

    try {
      final callable = _functions.httpsCallable('createInvite');
      final result = await callable.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'email': email,
        'role': role,
        'expiresAt': expiresAt?.toIso8601String(),
        'notes': notes,
      });

      final data = result.data;
      if (data['inviteId'] == null) {
        throw Exception('Invalid response from createInvite function');
      }

      return data['inviteId'] as String;
    } catch (error, stackTrace) {
      developer.log(
        'Error creating invite',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  /// Revoke an invite (calls Cloud Function).
  ///
  /// Throws SecurityException if user is not an owner or admin.
  ///
  /// Cloud Function handles:
  /// - Validation
  /// - Updating status to 'revoked'
  /// - Audit logging
  Future<void> revokeInvite(SecurityContext context, String inviteId) async {
    _verifyAdminAccess(context);

    try {
      final callable = _functions.httpsCallable('revokeInvite');
      await callable.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'inviteId': inviteId,
      });
    } catch (error, stackTrace) {
      developer.log(
        'Error revoking invite',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  // ============================================================
  // JOIN REQUESTS
  // ============================================================

  /// Watch pending join requests for a business.
  ///
  /// Returns a stream of pending join requests ordered by creation date (oldest first).
  /// Throws SecurityException if user is not an owner or admin.
  Stream<List<dynamic>> watchPendingRequests(SecurityContext context) {
    _verifyAdminAccess(context);

    // Log phiReadList for HIPAA compliance (non-blocking)
    _logReadAccess(
      context: context,
      entityType: 'JoinRequest',
      entityId: 'list',
      action: 'watchPendingRequests',
    );

    return _firestore
        .collection('businesses')
        .doc(context.businessId)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      // TODO: Replace with JoinRequest.fromFirestore when model is ready
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }).handleError((error, stackTrace) {
      developer.log(
        'Error watching pending join requests',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    });
  }

  /// Review (approve/deny) a join request (calls Cloud Function).
  ///
  /// Throws SecurityException if user is not an owner or admin.
  ///
  /// Cloud Function handles:
  /// - Validation
  /// - Creating/attaching user if approved
  /// - Updating request status
  /// - Audit logging
  /// - Sending notification to requestor
  Future<void> reviewJoinRequest({
    required SecurityContext context,
    required String requestId,
    required bool approve,
    String? reason,
  }) async {
    _verifyAdminAccess(context);

    try {
      final callable = _functions.httpsCallable('reviewJoinRequest');
      await callable.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'requestId': requestId,
        'approve': approve,
        'reason': reason,
      });
    } catch (error, stackTrace) {
      developer.log(
        'Error reviewing join request',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw _sanitizeError(error);
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Verify user has admin access (owner or admin role).
  ///
  /// Throws SecurityException if user is not authorized.
  void _verifyAdminAccess(SecurityContext context) {
    context.verifyBusinessAccess();
    if (!context.role.canManageUsers) {
      throw SecurityException(
        'Access denied: Only owners and admins can manage staff onboarding',
      );
    }
  }

  /// Log read access for HIPAA compliance (non-blocking).
  ///
  /// Failures are logged but not thrown to avoid blocking user operations.
  Future<void> _logReadAccess({
    required SecurityContext context,
    required String entityType,
    required String entityId,
    required String action,
  }) async {
    try {
      await _auditLog.log(
        context: context,
        action: entityId == 'list' ? 'phiReadList' : 'phiRead',
        entityType: entityType,
        entityId: entityId,
        details: {'action': action},
        source: 'StaffOnboardingRepository',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to log read access (non-blocking)',
        name: 'StaffOnboardingRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sanitize errors to prevent information leakage.
  ///
  /// Returns generic error messages to avoid user enumeration.
  Exception _sanitizeError(Object error) {
    // Preserve SecurityException for access control
    if (error is SecurityException) {
      return error;
    }

    // Return generic error for all other cases
    developer.log(
      'Sanitized error',
      name: 'StaffOnboardingRepository',
      error: error,
    );

    return Exception('Failed to complete operation. Please try again.');
  }
}
