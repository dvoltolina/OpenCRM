import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/app_notification.dart';

/// Repository for managing in-app notifications.
/// Notifications are stored per-user (not per-business).
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userNotifications(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  /// Watch notifications for a user, ordered by creation date.
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int limit = 50,
    bool unreadOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _userNotifications(
      userId,
    ).orderBy('createdAt', descending: true);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppNotification.fromJson({'id': doc.id, ...doc.data()}),
              )
              .where((n) => !n.isExpired)
              .toList(),
        );
  }

  /// Get unread notification count for a user.
  Stream<int> watchUnreadCount(String userId) {
    return _userNotifications(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppNotification.fromJson({'id': doc.id, ...doc.data()}),
              )
              .where((n) => !n.isExpired)
              .length,
        );
  }

  /// Create a new notification.
  Future<AppNotification> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? businessId,
    NotificationPriority priority = NotificationPriority.normal,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? data,
    Duration? expiresIn,
  }) async {
    DemoGuardService.assertReadOnly('create notification', showMessage: false);
    final now = DateTime.now();
    final id = _userNotifications(userId).doc().id;

    final notification = AppNotification(
      id: id,
      userId: userId,
      businessId: businessId,
      type: type,
      title: title,
      body: body,
      priority: priority,
      createdAt: now,
      targetType: targetType,
      targetId: targetId,
      data: data ?? {},
      expiresAt: expiresIn != null ? now.add(expiresIn) : null,
    );

    await _userNotifications(userId).doc(id).set(notification.toJson());
    return notification;
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String userId, String notificationId) async {
    DemoGuardService.assertReadOnly('mark notification read');
    await _userNotifications(userId).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    DemoGuardService.assertReadOnly('mark notifications read');
    final batch = _firestore.batch();
    final unread = await _userNotifications(
      userId,
    ).where('isRead', isEqualTo: false).get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Delete a notification.
  Future<void> deleteNotification(String userId, String notificationId) async {
    DemoGuardService.assertReadOnly('delete notification');
    await _userNotifications(userId).doc(notificationId).delete();
  }

  /// Delete all read notifications older than [age].
  Future<int> deleteOldNotifications(
    String userId, {
    Duration? olderThan,
  }) async {
    DemoGuardService.assertReadOnly('delete notifications', showMessage: false);
    final cutoff = DateTime.now().subtract(
      olderThan ?? const Duration(days: 30),
    );
    final old = await _userNotifications(userId)
        .where('isRead', isEqualTo: true)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    final batch = _firestore.batch();
    for (final doc in old.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return old.docs.length;
  }

  /// Create notification from FCM message data.
  Future<AppNotification> createFromFcmData({
    required String userId,
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) async {
    final type = _parseNotificationType(data['type'] as String?);
    return createNotification(
      userId: userId,
      type: type,
      title: title ?? data['title'] as String? ?? 'Notification',
      body: body ?? data['body'] as String? ?? '',
      businessId: data['businessId'] as String?,
      targetType: data['targetType'] as String?,
      targetId: data['targetId'] as String? ?? data['appointmentId'] as String?,
      data: data,
    );
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'appointment_confirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointment_cancelled':
        return NotificationType.appointmentCancelled;
      case 'appointment_rescheduled':
        return NotificationType.appointmentRescheduled;
      case 'waitlist_available':
        return NotificationType.waitlistAvailable;
      case 'new_message':
        return NotificationType.newMessage;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'intake_form_required':
        return NotificationType.intakeFormRequired;
      default:
        return NotificationType.general;
    }
  }
}
