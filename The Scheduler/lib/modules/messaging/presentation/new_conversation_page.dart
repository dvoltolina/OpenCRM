import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/client.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/provider.dart' as provider_model;
import '../../../data/models/security_context.dart';
import '../../../data/repositories/messaging_repository.dart';
import 'conversation_detail_page.dart';
import 'conversations_list_page.dart';

/// Page to start a new conversation by selecting a recipient.
class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({
    super.key,
    required this.securityContext,
    required this.conversationType,
    this.openConversation = true,
  });

  final SecurityContext securityContext;
  final ConversationType conversationType;
  final bool openConversation;

  @override
  ConsumerState<NewConversationPage> createState() =>
      _NewConversationPageState();
}

class _NewConversationPageState extends ConsumerState<NewConversationPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;

  MessagingRepository get _messagingRepository =>
      ref.read(messagingRepositoryProvider);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClientType = widget.conversationType == ConversationType.client;
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isClientType ? 'Message Client' : 'Message Staff'),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [branding.primaryColor, branding.accentColor],
            ),
          ),
        ),
      ),
      backgroundColor: branding.backgroundColor,
      body: Column(
        children: [
          // Search bar with modern styling
          Container(
            padding: AppSpacing.pagePadding,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isClientType
                    ? 'Search clients...'
                    : 'Search staff...',
                prefixIcon: Icon(Icons.search,
                  color: theme.colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // List of recipients
          Expanded(
            child: isClientType ? _buildClientsList() : _buildStaffList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    final clientsAsync = ref.watch(
      clientsStreamProvider(widget.securityContext),
    );

    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading clients: $error')),
      data: (clients) {
        final filtered = clients.where((c) {
          if (_searchQuery.isEmpty) return true;
          final name = '${c.firstName} ${c.lastName}'.toLowerCase();
          final email = (c.email ?? '').toLowerCase();
          final phone = (c.phone ?? '').toLowerCase();
          return name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              phone.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search,
            title: _searchQuery.isEmpty ? 'No clients' : 'No clients found',
            subtitle: _searchQuery.isEmpty
                ? 'Add clients to start messaging them'
                : 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final client = filtered[index];
            return _RecipientTile(
              name: '${client.firstName} ${client.lastName}',
              subtitle: client.email ?? client.phone ?? '',
              avatarColor: Theme.of(context).colorScheme.primaryContainer,
              isLoading: _isCreating,
              onTap: () => _startConversationWithClient(client),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffList() {
    final providersAsync = ref.watch(
      providersStreamProvider(widget.securityContext),
    );

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading staff: $error')),
      data: (providers) {
        // Filter out current user
        final filtered = providers.where((p) {
          if (p.id == widget.securityContext.userId) return false;
          if (_searchQuery.isEmpty) return true;
          final name = p.fullName.toLowerCase();
          final email = (p.email ?? '').toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.group_off,
            title: _searchQuery.isEmpty ? 'No other staff' : 'No staff found',
            subtitle: _searchQuery.isEmpty
                ? 'You are the only staff member'
                : 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final staff = filtered[index];
            return _RecipientTile(
              name: staff.fullName,
              subtitle: staff.email ?? '',
              avatarColor: Theme.of(context).colorScheme.secondaryContainer,
              isLoading: _isCreating,
              onTap: () => _startConversationWithStaff(staff),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.disabledColor),
          VSpace.md,
          Text(title, style: theme.textTheme.titleMedium),
          VSpace.xs,
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversationWithClient(Client client) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final conversation = await _messagingRepository
          .getOrCreateDirectConversation(
            context: widget.securityContext,
            otherParticipant: ConversationParticipant(
              id: client.id,
              name: '${client.firstName} ${client.lastName}',
              isStaff: false,
            ),
          );

      if (!mounted) return;

      if (!widget.openConversation) {
        Navigator.of(context).pop(conversation.id);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConversationDetailPage(
            securityContext: widget.securityContext,
            conversationId: conversation.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start conversation: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _startConversationWithStaff(
    provider_model.Provider staff,
  ) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final conversation = await _messagingRepository
          .getOrCreateDirectConversation(
            context: widget.securityContext,
            otherParticipant: ConversationParticipant(
              id: staff.id,
              name: staff.fullName,
              isStaff: true,
            ),
          );

      if (!mounted) return;

      if (!widget.openConversation) {
        Navigator.of(context).pop(conversation.id);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConversationDetailPage(
            securityContext: widget.securityContext,
            conversationId: conversation.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start conversation: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}

class _RecipientTile extends ConsumerWidget {
  const _RecipientTile({
    required this.name,
    required this.subtitle,
    required this.avatarColor,
    required this.isLoading,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final Color avatarColor;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [branding.primaryColor, branding.accentColor],
            ),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(name),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: branding.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(branding.primaryColor),
                ),
              )
            : Icon(Icons.chevron_right, color: branding.accentColor),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
