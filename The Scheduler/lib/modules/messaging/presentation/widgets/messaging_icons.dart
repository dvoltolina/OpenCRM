import 'package:flutter/material.dart';

import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/messaging_repository.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../conversations_list_page.dart';
import '../notification_inbox_page.dart';

/// AppBar icons for notifications and messages with unread badges.
class MessagingIcons extends StatelessWidget {
  const MessagingIcons({
    super.key,
    required this.userId,
    required this.securityContext,
  });

  final String userId;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notifications icon
        _NotificationIcon(
          userId: userId,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationInboxPage(
                userId: userId,
                onNotificationTap: (notification) {
                  // Handle navigation based on notification type
                  Navigator.of(context).pop();
                  _handleNotificationTap(context, notification);
                },
              ),
            ),
          ),
        ),
        // Messages icon
        _MessagesIcon(
          securityContext: securityContext,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationsListPage(
                securityContext: securityContext,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleNotificationTap(BuildContext context, dynamic notification) {
    // TODO: Implement deep linking based on notification.targetType
    // e.g., navigate to appointment details, conversation, etc.
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.userId,
    required this.onTap,
  });

  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repository = NotificationRepository();

    return StreamBuilder<int>(
      stream: repository.watchUnreadCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : count.toString()),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: onTap,
        );
      },
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  const _MessagesIcon({
    required this.securityContext,
    required this.onTap,
  });

  final SecurityContext securityContext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repository = MessagingRepository();

    return StreamBuilder<int>(
      stream: repository.watchTotalUnreadCount(context: securityContext),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          tooltip: 'Messages',
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : count.toString()),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          onPressed: onTap,
        );
      },
    );
  }
}

/// Standalone notification bell icon (for use in other places).
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    return _NotificationIcon(
      userId: userId,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NotificationInboxPage(userId: userId),
        ),
      ),
    );
  }
}

/// Standalone messages icon (for use in other places).
class MessagesBubbleIcon extends StatelessWidget {
  const MessagesBubbleIcon({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    return _MessagesIcon(
      securityContext: securityContext,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationsListPage(securityContext: securityContext),
        ),
      ),
    );
  }
}
