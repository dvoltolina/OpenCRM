import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/messaging_repository.dart';
import '../../../messaging/presentation/conversation_detail_page.dart';
import '../../../messaging/presentation/conversations_list_page.dart';
import '../../../messaging/presentation/new_conversation_page.dart';
import '../../../messaging/presentation/widgets/conversation_thread.dart';

/// Messaging workspace embedded on the Communications page.
class MessagingPortalCard extends ConsumerStatefulWidget {
  const MessagingPortalCard({super.key, required this.securityContext});

  final SecurityContext securityContext;

  @override
  ConsumerState<MessagingPortalCard> createState() =>
      _MessagingPortalCardState();
}

class _MessagingPortalCardState extends ConsumerState<MessagingPortalCard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;
  String? _selectedConversationId;

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = ref.watch(messagingRepositoryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat, color: theme.colorScheme.primary),
              HSpace.xs,
              Flexible(
                child: Text(
                  'Messaging Portal',
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              HSpace.sm,
              FilterChip(
                selected: _showArchived,
                onSelected: (value) => setState(() => _showArchived = value),
                label: const Text('Show archived'),
              ),
            ],
          ),
          VSpace.xs,
          Text(
            'Respond to client chats and internal messages without leaving this screen.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          VSpace.md,
          _buildToolbar(context),
          VSpace.md,
          SizedBox(
            height: 520,
            child: StreamBuilder<List<Conversation>>(
              stream: repository.watchConversations(
                context: widget.securityContext,
                includeArchived: _showArchived,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load conversations'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations = _filterConversations(
                  snapshot.data!,
                  _searchQuery,
                );

                if (conversations.isEmpty) {
                  return _buildEmptyState(context);
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final selected = _resolveSelection(conversations, isWide);

                    if (!isWide) {
                      return _buildConversationList(
                        context,
                        conversations,
                        compact: true,
                        onTap: (conversation) =>
                            _openConversationDetail(conversation),
                      );
                    }

                    return Row(
                      children: [
                        SizedBox(
                          width: 320,
                          child: _buildConversationList(
                            context,
                            conversations,
                            onTap: (conversation) {
                              setState(
                                () => _selectedConversationId = conversation.id,
                              );
                            },
                            selectedConversationId: selected?.id,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: selected == null
                              ? Center(
                                  child: Text(
                                    'Select a conversation',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.disabledColor,
                                    ),
                                  ),
                                )
                              : ConversationThread(
                                  securityContext: widget.securityContext,
                                  conversation: selected,
                                  compact: true,
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name, subject, or keyword',
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
        ),
        HSpace.sm,
        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('New message'),
          onPressed: () => _startNewConversation(context),
        ),
      ],
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    List<Conversation> conversations, {
    bool compact = false,
    String? selectedConversationId,
    required ValueChanged<Conversation> onTap,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            itemCount: conversations.length,
            separatorBuilder: (_, index) => VSpace.xs,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final isSelected = conversation.id == selectedConversationId;
              final unreadCount = conversation.unreadCountFor(
                widget.securityContext.userId,
              );

              return _ConversationListTile(
                conversation: conversation,
                currentUserId: widget.securityContext.userId,
                unreadCount: unreadCount,
                isSelected: isSelected,
                onTap: () => onTap(conversation),
                onArchive: () => _toggleArchive(conversation),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppIconSize.xl,
              color: theme.disabledColor,
            ),
            VSpace.md,
            Text(
              'No conversations yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            VSpace.xs,
            Text(
              'Reach out to a client or staff member to start messaging.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            VSpace.lg,
            FilledButton.icon(
              onPressed: () => _startNewConversation(context),
              icon: const Icon(Icons.edit),
              label: const Text('Start a conversation'),
            ),
          ],
        ),
      ),
    );
  }

  List<Conversation> _filterConversations(
    List<Conversation> conversations,
    String query,
  ) {
    if (query.isEmpty) return conversations;
    final normalized = query.toLowerCase();

    return conversations.where((conversation) {
      final other = conversation.otherParticipant(
        widget.securityContext.userId,
      );
      final name = (other?.name ?? '').toLowerCase();
      final subject = (conversation.subject ?? '').toLowerCase();
      final lastMessage = (conversation.lastMessageText ?? '').toLowerCase();
      return name.contains(normalized) ||
          subject.contains(normalized) ||
          lastMessage.contains(normalized);
    }).toList();
  }

  Conversation? _resolveSelection(
    List<Conversation> conversations,
    bool isWide,
  ) {
    if (!isWide) return null;

    var selected = conversations.firstWhere(
      (c) => c.id == _selectedConversationId,
      orElse: () => conversations.first,
    );

    if (_selectedConversationId != selected.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedConversationId = selected.id);
        }
      });
    }

    return selected;
  }

  Future<void> _startNewConversation(BuildContext context) async {
    final isWide = MediaQuery.of(context).size.width >= 900;

    await showModalBottomSheet<void>(
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              VSpace.md,
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Message a Client'),
                subtitle: const Text('Send a direct message to a client'),
                onTap: () {
                  Navigator.pop(context);
                  _openNewConversation(ConversationType.client, isWide);
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Message Staff'),
                subtitle: const Text('Internal message to a team member'),
                onTap: () {
                  Navigator.pop(context);
                  _openNewConversation(ConversationType.staff, isWide);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNewConversation(ConversationType type, bool isWide) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => NewConversationPage(
          securityContext: widget.securityContext,
          conversationType: type,
          openConversation: !isWide,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedConversationId = result);
    }
  }

  Future<void> _toggleArchive(Conversation conversation) async {
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

  void _openConversationDetail(Conversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationDetailPage(
          securityContext: widget.securityContext,
          conversationId: conversation.id,
        ),
      ),
    );
  }
}

class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.conversation,
    required this.currentUserId,
    required this.unreadCount,
    required this.onTap,
    required this.onArchive,
    this.isSelected = false,
  });

  final Conversation conversation;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final other = conversation.otherParticipant(currentUserId);
    final hasUnread = unreadCount > 0;

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _initials(other?.name ?? 'U'),
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              HSpace.sm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            other?.name ??
                                conversation.subject ??
                                'Conversation',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _formatTime(conversation.lastMessageAt!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    VSpace.xxs,
                    Text(
                      conversation.lastMessageText ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              HSpace.xs,
              if (hasUnread)
                Container(
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
              IconButton(
                tooltip: conversation.isArchived ? 'Unarchive' : 'Archive',
                icon: Icon(
                  conversation.isArchived
                      ? Icons.unarchive
                      : Icons.archive_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onArchive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
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
