import 'package:flutter/material.dart';

import '../../../../data/models/staff_invite.dart';

class PendingInviteCard extends StatelessWidget {
  const PendingInviteCard({
    super.key,
    required this.invite,
    this.onCopyCode,
    this.onCopyLink,
    this.onRevoke,
  });

  final StaffInvite invite;
  final VoidCallback? onCopyCode;
  final VoidCallback? onCopyLink;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpenInvite = invite.email == null || invite.email!.isEmpty;
    final usesText = '${invite.remainingUses}/${invite.maxUses} uses left';
    final expiresText =
        'Expires: ${invite.expiresAt.toLocal().toIso8601String().split('T').first}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isOpenInvite ? Icons.link : Icons.mail_outline,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isOpenInvite ? 'Open Invite' : (invite.email ?? 'Invite'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Chip(
              label: Text(_statusLabel(invite.status)),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(color: theme.colorScheme.primary),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: ${invite.assignedRole.name} • $expiresText • $usesText',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'code':
                onCopyCode?.call();
                break;
              case 'link':
                onCopyLink?.call();
                break;
              case 'revoke':
                onRevoke?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            if (onCopyCode != null)
              const PopupMenuItem(
                value: 'code',
                child: Text('Copy code'),
              ),
            if (onCopyLink != null)
              const PopupMenuItem(
                value: 'link',
                child: Text('Copy link'),
              ),
            if (onRevoke != null)
              const PopupMenuItem(
                value: 'revoke',
                child: Text('Revoke'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(StaffInviteStatus status) {
    switch (status) {
      case StaffInviteStatus.pending:
        return 'Pending';
      case StaffInviteStatus.active:
        return 'Active';
      case StaffInviteStatus.revoked:
        return 'Revoked';
      case StaffInviteStatus.expired:
        return 'Expired';
      case StaffInviteStatus.exhausted:
        return 'Exhausted';
    }
  }
}
