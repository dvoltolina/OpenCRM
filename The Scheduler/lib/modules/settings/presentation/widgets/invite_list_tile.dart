import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';

// TODO(RW1): Uncomment when Invite model is available
// import '../../../../data/models/invite.dart';

/// Widget for displaying invite list items with modern styling.
/// Clean, modern list items with proper spacing and sophisticated blue colors.
///
/// Displays invite information:
/// - Email address
/// - Role (staff|admin)
/// - Status (pending|accepted|revoked|expired)
/// - Creation and expiration dates
/// - Acceptance date (if accepted)
/// - Optional notes
///
/// Actions:
/// - Revoke invite (if pending)
///
/// HIPAA: Email is not PHI, safe to display
class InviteListTile extends ConsumerWidget {
  // TODO(RW1): Replace dynamic with Invite when model is available
  final dynamic invite;
  final VoidCallback onRevoke;

  const InviteListTile({
    required this.invite,
    required this.onRevoke,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;

    // TODO(RW1): Uncomment when Invite model is available
    // This is the actual implementation ready to use
    /*
    final isPending = invite.status == 'pending';
    final isExpired = invite.expiresAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(context, invite.status),
          child: Icon(
            _getStatusIcon(invite.status),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invite.email,
                style: theme.textTheme.titleMedium,
              ),
            ),
            _buildStatusChip(context, invite.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Role: ${_formatRole(invite.role)}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.send, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Sent: ${_formatDate(invite.createdAt)}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  isExpired
                      ? 'Expired ${_formatDate(invite.expiresAt)}'
                      : 'Expires ${_formatDate(invite.expiresAt)}',
                  style: TextStyle(
                    color: isExpired ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
            if (invite.acceptedAt != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Accepted ${_formatDate(invite.acceptedAt!)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            if (invite.notes != null && invite.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.note_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      invite.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: isPending
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'revoke',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text('Revoke', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'revoke') {
                    onRevoke();
                  }
                },
              )
            : null,
      ),
    );
    */

    // Placeholder implementation (remove when model is available)
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(context, 'pending'),
            child: const Icon(Icons.mail_outline, color: Colors.white),
          ),
          title: Row(
            children: [
              const Expanded(child: Text('staff@example.com')),
              HSpace.xs,
              _buildStatusChip(context, 'pending'),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.xxs,
              const Text('Role: Staff'),
              Text('Sent: ${DateFormat.yMMMd().format(DateTime.now())}'),
              Text('Expires: ${DateFormat.yMMMd().format(DateTime.now().add(const Duration(days: 7)))}'),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'revoke',
                child: ListTile(
                  leading: Icon(Icons.block, color: Colors.red),
                  title: Text('Revoke', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'revoke') {
                onRevoke();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context, status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    /* Original Chip implementation - kept for reference
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getStatusColor(context, status),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
    */
  }

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'revoked':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return theme.colorScheme.primary;
    }
  }
}
