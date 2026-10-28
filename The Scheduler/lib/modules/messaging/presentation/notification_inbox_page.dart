// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/repositories/notification_repository.dart';

/// Notification inbox showing all notifications for the current user.
/// Used by both clients and staff.
class NotificationInboxPage extends ConsumerStatefulWidget {
  const NotificationInboxPage({
    super.key,
    required this.userId,
    this.onNotificationTap,
  });

  final String userId;
  final void Function(AppNotification notification)? onNotificationTap;

  @override
  ConsumerState<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends ConsumerState<NotificationInboxPage> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(notificationRepositoryProvider);
    ref.watch(securityContextProvider);
    final theme = Theme.of(context);

    return AppPageScaffold(
      title: 'Notifications',
      showBackButton: true,
      actions: [
        IconButton(
          icon: Icon(_showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
          tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
          onPressed: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'mark_all_read') {
              await repository.markAllAsRead(widget.userId);
            } else if (value == 'clear_old') {
              final count = await repository.deleteOldNotifications(widget.userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted $count old notifications')),
                );
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'mark_all_read',
              child: Text('Mark all as read'),
            ),
            PopupMenuItem(
              value: 'clear_old',
              child: Text('Clear old notifications'),
            ),
          ],
        ),
      ],
      body: StreamBuilder<List<AppNotification>>(
        stream: repository.watchNotifications(
          userId: widget.userId,
          unreadOnly: _showUnreadOnly,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(SecureErrorHandler.loadingFailed));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: AppIconSize.lg, color: theme.disabledColor),
                  VSpace.md,
                  Text(
                    _showUnreadOnly ? 'No unread notifications' : 'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleTap(notification, repository),
                onDismiss: () => repository.deleteNotification(
                  widget.userId,
                  notification.id,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(AppNotification notification, NotificationRepository repository) {
    // Mark as read
    if (!notification.isRead) {
      repository.markAsRead(widget.userId, notification.id);
    }

    // Call the tap handler for navigation
    widget.onNotificationTap?.call(notification);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = notification.isUnread;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread
              ? _getTypeColor(notification.type, theme)
              : theme.disabledColor.withValues(alpha: 0.3),
          child: Icon(
            _getTypeIcon(notification.type),
            color: isUnread ? Colors.white : theme.disabledColor,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
        return Icons.alarm;
      case NotificationType.appointmentConfirmed:
        return Icons.check_circle;
      case NotificationType.appointmentCancelled:
        return Icons.cancel;
      case NotificationType.appointmentRescheduled:
        return Icons.update;
      case NotificationType.waitlistAvailable:
        return Icons.hourglass_empty;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.intakeFormRequired:
        return Icons.assignment;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return AppColors.riskLow;
      case NotificationType.appointmentCancelled:
      case NotificationType.paymentFailed:
        return AppColors.riskHigh;
      case NotificationType.waitlistAvailable:
        return AppColors.warning;
      case NotificationType.newMessage:
        return theme.colorScheme.primary;
      case NotificationType.paymentReceived:
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
