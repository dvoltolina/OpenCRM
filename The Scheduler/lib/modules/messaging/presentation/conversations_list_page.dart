import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/messaging_repository.dart';
import 'conversation_detail_page.dart';
import 'new_conversation_page.dart';

/// List of conversations for the current user.
/// Used by both clients and staff.
/// Updated by Agent U5 (2025-11-29) - Uses design tokens, HIPAA-compliant errors
class ConversationsListPage extends ConsumerStatefulWidget {
  const ConversationsListPage({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<ConversationsListPage> createState() =>
      _ConversationsListPageState();
}

class _ConversationsListPageState extends ConsumerState<ConversationsListPage> {
  bool _showArchived = false;

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);

  @override
  Widget build(BuildContext context) {
    ref.watch(securityContextProvider);
    final repository = ref.watch(messagingRepositoryProvider);
    final theme = Theme.of(context);

    return AppPageScaffold(
      title: 'Messages',
      showBackButton: false,
      body: StreamBuilder<List<Conversation>>(
        stream: repository.watchConversations(
          context: widget.securityContext,
          includeArchived: _showArchived,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(SecureErrorHandler.loadingFailed));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: AppIconSize.xl, color: theme.disabledColor),
                    VSpace.md,
                    Text(
                      'No conversations yet',
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                    ),
                    VSpace.xs,
                    Text(
                      'Send a message to a client or team member',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                      textAlign: TextAlign.center,
                    ),
                    VSpace.lg,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showNewConversationOptions(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Start Conversation'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: conversations.length,
            separatorBuilder: (_, _) => VSpace.sm,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(
                conversation: conversation,
                currentUserId: widget.securityContext.userId,
                onTap: () => _openConversation(conversation),
                onArchive: () => _archiveConversation(conversation),
              );
            },
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
          tooltip: _showArchived ? 'Hide archived' : 'Show archived',
          onPressed: () => setState(() => _showArchived = !_showArchived),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewConversationOptions(context),
        icon: const Icon(Icons.edit),
        label: const Text('New Message'),
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationDetailPage(
          securityContext: widget.securityContext,
          conversationId: conversation.id,
        ),
      ),
    );
  }

  Future<void> _archiveConversation(Conversation conversation) async {
    if (conversation.isArchived) {
      await _repository.unarchiveConversation(
        context: widget.securityContext,
        conversationId: conversation.id,
      );
    } else {
      await _repository.archiveConversation(
        context: widget.securityContext,
        conversationId: conversation.id,
      );
    }
  }

  void _showNewConversationOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Conversation',
                style: theme.textTheme.titleLarge,
              ),
              VSpace.md,
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: const Text('Message a Client'),
                subtitle: const Text('Send a direct message to a client'),
                onTap: () {
                  Navigator.pop(context);
                  _startNewConversation(ConversationType.client);
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.group, color: theme.colorScheme.onSecondaryContainer),
                ),
                title: const Text('Message Staff'),
                subtitle: const Text('Internal message to a team member'),
                onTap: () {
                  Navigator.pop(context);
                  _startNewConversation(ConversationType.staff);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewConversation(ConversationType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewConversationPage(
          securityContext: widget.securityContext,
          conversationType: type,
        ),
      ),
    );
  }
}

enum ConversationType { client, staff }

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    required this.onArchive,
  });

  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = conversation.unreadCountFor(currentUserId);
    final hasUnread = unreadCount > 0;
    final other = conversation.otherParticipant(currentUserId);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onArchive();
        return false; // Don't actually dismiss, just archive
      },
      background: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Icon(
          conversation.isArchived ? Icons.unarchive : Icons.archive,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: AppCard(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              _getInitials(other?.name ?? 'U'),
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  other?.name ?? conversation.subject ?? 'Conversation',
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conversation.lastMessageAt != null)
                Text(
                  _formatTime(conversation.lastMessageAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasUnread ? theme.colorScheme.primary : theme.disabledColor,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessageText ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? theme.colorScheme.onSurface : theme.disabledColor,
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${dateTime.month}/${dateTime.day}';
  }
}
