import 'package:flutter/material.dart';

import '../../../../data/models/security_context.dart';

class InvitesTab extends StatelessWidget {
  const InvitesTab({
    super.key,
    required this.securityContext,
    required this.onSendInvite,
  });

  final SecurityContext securityContext;
  final VoidCallback onSendInvite;

  @override
  Widget build(BuildContext context) {
    // TODO(RW2): Uncomment when repository is available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Email Invites',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Send personalized email invitations to specific staff members.\n\n'
              'Note: Invite management requires models and repository implementation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSendInvite,
            icon: const Icon(Icons.send),
            label: const Text('Send Invite'),
          ),
        ],
      ),
    );

    // Actual implementation (uncomment when repository is available):
    /*
    final invitesAsync = ref.watch(invitesStreamProvider);

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No invites sent yet'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onSendInvite,
                  icon: const Icon(Icons.send),
                  label: const Text('Send First Invite'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];
            return InviteListTile(
              invite: invite,
              onRevoke: () => _revokeInvite(context, securityContext, invite),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        SafeErrorHandler.handle(error, context: 'Loading invites', stackTrace: stackTrace);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(UserMessages.loadError),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(invitesStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
    */
  }
}
