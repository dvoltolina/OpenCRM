import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/audit_log.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/audit_log_repository.dart';

/// Service for handling emergency admin actions.
///
/// All actions require admin privileges and are audit logged.
/// HIPAA: No PHI in logs - only IDs and action types.
class EmergencyActionsService {
  EmergencyActionsService({
    required this.firestore,
    required this.auditLogRepository,
  });

  final FirebaseFirestore firestore;
  final AuditLogRepository auditLogRepository;

  /// Disable all online booking for the business (emergency).
  ///
  /// This sets a flag in the business document to prevent new bookings.
  /// Existing appointments are not affected.
  ///
  /// HIPAA: Audit logged with reason.
  Future<void> disableBooking(
    SecurityContext context, {
    required String reason,
    DateTime? until,
  }) async {
    // Verify admin access
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only admins can disable booking');
    }

    context.verifyBusinessAccess();

    // Update business document
    await firestore.collection('businesses').doc(context.businessId).update({
      'bookingEnabled': false,
      'bookingDisabledReason': reason,
      'bookingDisabledUntil': until,
      'bookingDisabledAt': FieldValue.serverTimestamp(),
      'bookingDisabledBy': context.userId,
    });

    // Audit log (no PHI)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Business',
        entityId: context.businessId,
        metadata: {
          'action': 'disable_booking',
          'reason': reason,
          'until': until?.toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Re-enable booking for the business.
  ///
  /// HIPAA: Audit logged.
  Future<void> enableBooking(SecurityContext context) async {
    // Verify admin access
    if (!context.role.canManageBusiness) {
      throw SecurityException('Only admins can enable booking');
    }

    context.verifyBusinessAccess();

    // Update business document
    await firestore.collection('businesses').doc(context.businessId).update({
      'bookingEnabled': true,
      'bookingDisabledReason': FieldValue.delete(),
      'bookingDisabledUntil': FieldValue.delete(),
      'bookingDisabledAt': FieldValue.delete(),
      'bookingDisabledBy': FieldValue.delete(),
      'bookingReenabledAt': FieldValue.serverTimestamp(),
      'bookingReenabledBy': context.userId,
    });

    // Audit log (no PHI)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Business',
        entityId: context.businessId,
        metadata: {
          'action': 'enable_booking',
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Force sign out all staff members.
  ///
  /// This is an emergency action that revokes all active sessions.
  /// Staff will need to sign in again.
  ///
  /// HIPAA: Audit logged with reason. No PHI.
  Future<void> forceSignOutAllStaff(
    SecurityContext context, {
    required String reason,
  }) async {
    // Verify admin access
    if (!context.role.canManageUsers) {
      throw SecurityException('Only admins can force sign out staff');
    }

    context.verifyBusinessAccess();

    // Get all staff members
    final staffSnapshot = await firestore
        .collection('staff')
        .where('businessId', isEqualTo: context.businessId)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = firestore.batch();
    int count = 0;

    // Set forceSignOut flag for each staff member
    for (final doc in staffSnapshot.docs) {
      batch.update(doc.reference, {
        'forceSignOut': true,
        'forceSignOutReason': reason,
        'forceSignOutAt': FieldValue.serverTimestamp(),
        'forceSignOutBy': context.userId,
      });
      count++;
    }

    await batch.commit();

    // Audit log (no PHI)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Staff',
        entityId: 'all',
        metadata: {
          'action': 'force_sign_out_all',
          'reason': reason,
          'affectedCount': count,
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Send emergency announcement to all staff.
  ///
  /// Creates a high-priority notification for all active staff members.
  ///
  /// HIPAA: No PHI in announcements. Generic messages only.
  Future<void> sendEmergencyAnnouncement(
    SecurityContext context, {
    required String message,
  }) async {
    // Verify admin access
    if (!context.role.canManageUsers) {
      throw SecurityException('Only admins can send emergency announcements');
    }

    context.verifyBusinessAccess();

    // Get all active staff members
    final staffSnapshot = await firestore
        .collection('staff')
        .where('businessId', isEqualTo: context.businessId)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = firestore.batch();
    int count = 0;

    // Create notification for each staff member
    for (final doc in staffSnapshot.docs) {
      final notificationRef = firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': doc.id,
        'businessId': context.businessId,
        'type': 'emergency_announcement',
        'title': 'Emergency Announcement',
        'message': message,
        'priority': 'high',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': context.userId,
      });
      count++;
    }

    await batch.commit();

    // Audit log (no PHI)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Notification',
        entityId: 'emergency_announcement',
        metadata: {
          'action': 'send_emergency_announcement',
          'recipientCount': count,
          // Don't log message content to keep audit log clean
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Lock a specific staff member account.
  ///
  /// Staff member will not be able to sign in until unlocked.
  ///
  /// HIPAA: Audit logged with reason. No PHI.
  Future<void> lockStaffAccount(
    SecurityContext context, {
    required String staffId,
    required String reason,
  }) async {
    // Verify admin access
    if (!context.role.canManageUsers) {
      throw SecurityException('Only admins can lock staff accounts');
    }

    context.verifyBusinessAccess();

    // Update staff document
    await firestore.collection('staff').doc(staffId).update({
      'accountLocked': true,
      'accountLockedReason': reason,
      'accountLockedAt': FieldValue.serverTimestamp(),
      'accountLockedBy': context.userId,
    });

    // Audit log (no PHI - only staffId)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Staff',
        entityId: staffId,
        metadata: {
          'action': 'lock_account',
          'reason': reason,
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Unlock a staff member account.
  ///
  /// HIPAA: Audit logged.
  Future<void> unlockStaffAccount(
    SecurityContext context, {
    required String staffId,
  }) async {
    // Verify admin access
    if (!context.role.canManageUsers) {
      throw SecurityException('Only admins can unlock staff accounts');
    }

    context.verifyBusinessAccess();

    // Update staff document
    await firestore.collection('staff').doc(staffId).update({
      'accountLocked': FieldValue.delete(),
      'accountLockedReason': FieldValue.delete(),
      'accountLockedAt': FieldValue.delete(),
      'accountLockedBy': FieldValue.delete(),
      'accountUnlockedAt': FieldValue.serverTimestamp(),
      'accountUnlockedBy': context.userId,
    });

    // Audit log (no PHI - only staffId)
    await auditLogRepository.logEvent(
      AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.securityEvent,
        entityType: 'Staff',
        entityId: staffId,
        metadata: {
          'action': 'unlock_account',
        },
        timestamp: DateTime.now(),
      ),
    );
  }
}
