import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/messaging_repository.dart';
import 'widgets/conversation_thread.dart';

/// Chat view for a single conversation.
/// Updated by Agent U5 (2025-11-29) - Uses design tokens, AppRadius.full for chat bubbles
class ConversationDetailPage extends ConsumerStatefulWidget {
  const ConversationDetailPage({
    super.key,
    required this.securityContext,
    required this.conversationId,
  });

  final SecurityContext securityContext;
  final String conversationId;

  @override
  ConsumerState<ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState
    extends ConsumerState<ConversationDetailPage> {
  late final MessagingRepository _repository;
  Conversation? _conversation;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(messagingRepositoryProvider);
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final conv = await _repository.getConversation(
      context: widget.securityContext,
      conversationId: widget.conversationId,
    );
    if (mounted) {
      setState(() => _conversation = conv);
      // Mark as read when entering
      if (conv != null) {
        await _repository.markConversationAsRead(
          context: widget.securityContext,
          conversationId: widget.conversationId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep Riverpod security context active for RBAC expectations.
    ref.watch(securityContextProvider);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    final other = _conversation?.otherParticipant(
      widget.securityContext.userId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(other?.name ?? _conversation?.subject ?? 'Conversation'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [branding.primaryColor, branding.accentColor],
            ),
          ),
        ),
        actions: [
          if (_conversation != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'archive') {
                  _repository.archiveConversation(
                    context: widget.securityContext,
                    conversationId: widget.conversationId,
                  );
                  Navigator.of(context).pop();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined),
                      SizedBox(width: 8),
                      Text('Archive conversation'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: branding.backgroundColor,
      body: Column(
        children: [
          if (_conversation == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ConversationThread(
                securityContext: widget.securityContext,
                conversation: _conversation!,
              ),
            ),
        ],
      ),
    );
  }
}
