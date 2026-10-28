import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/messaging_repository.dart';

/// Reusable message thread widget with composer + stream of messages.
class ConversationThread extends ConsumerStatefulWidget {
  const ConversationThread({
    super.key,
    required this.securityContext,
    required this.conversation,
    this.compact = false,
  });

  final SecurityContext securityContext;
  final Conversation conversation;
  final bool compact;

  @override
  ConsumerState<ConversationThread> createState() => _ConversationThreadState();
}

class _ConversationThreadState extends ConsumerState<ConversationThread> {
  late final TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _markConversationAsRead();
  }

  @override
  void didUpdateWidget(covariant ConversationThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _messageController.clear();
      _scrollController.jumpTo(0);
      _markConversationAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markConversationAsRead() async {
    await _repository.markConversationAsRead(
      context: widget.securityContext,
      conversationId: widget.conversation.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _repository.watchMessages(
              context: widget.securityContext,
              conversationId: widget.conversation.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(SecureErrorHandler.loadingFailed));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;

              if (messages.isEmpty) {
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
                          'No messages yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                        VSpace.xs,
                        Text(
                          'Send a message to start the conversation',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
                  vertical: widget.compact ? AppSpacing.sm : AppSpacing.md,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  final isMe =
                      message.senderId == widget.securityContext.userId;
                  final showSender =
                      !isMe && widget.conversation.participants.length > 2;

                  return _MessageBubble(
                    message: message,
                    isMe: isMe,
                    showSender: showSender,
                    onEdit: isMe ? () => _editMessage(message) : null,
                    onDelete: isMe ? () => _deleteMessage(message) : null,
                  );
                },
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(
                widget.compact ? AppSpacing.sm : AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  HSpace.xs,
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? SizedBox(
                            width: AppIconSize.sm,
                            height: AppIconSize.sm,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      await _repository.sendMessage(
        context: widget.securityContext,
        conversationId: widget.conversation.id,
        content: content,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SecureErrorHandler.saveFailed)));
        _messageController.text = content;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != message.content) {
      await _repository.editMessage(
        context: widget.securityContext,
        conversationId: widget.conversation.id,
        messageId: message.id,
        newContent: result,
      );
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('This message will be deleted for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteMessage(
        context: widget.securityContext,
        conversationId: widget.conversation.id,
        messageId: message.id,
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    this.onEdit,
    this.onDelete,
  });

  final Message message;
  final bool isMe;
  final bool showSender;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'This message was deleted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Center(
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: isMe ? () => _showMessageActions(context) : null,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.md),
                topRight: const Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(isMe ? AppRadius.md : AppRadius.xs),
                bottomRight: Radius.circular(
                  isMe ? AppRadius.xs : AppRadius.md,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isMe
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                VSpace.xxs,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isMe
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                            : theme.disabledColor,
                      ),
                    ),
                    if (message.isEdited) ...[
                      HSpace.xxs,
                      Text(
                        '(edited)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.7,
                                )
                              : theme.disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
