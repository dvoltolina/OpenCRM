import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';

// TODO(RW1): Uncomment when JoinCode model is available
// import '../../../../data/models/join_code.dart';

/// Widget for displaying join code list items with modern styling.
/// Clean, modern list items with proper spacing and sophisticated blue colors.
///
/// Displays join code information:
/// - Role (staff|admin)
/// - Status (active|revoked|expired)
/// - Uses (current/max)
/// - Expiration date
/// - Optional notes
///
/// Actions:
/// - Copy code identifier (note: plaintext only shown at creation)
/// - Revoke code (if active)
///
/// HIPAA: Never displays plaintext codes, only hash identifiers
class JoinCodeListTile extends ConsumerWidget {
  // TODO(RW1): Replace dynamic with JoinCode when model is available
  final dynamic joinCode;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  const JoinCodeListTile({
    required this.joinCode,
    required this.onCopy,
    required this.onRevoke,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;

    // TODO(RW1): Uncomment when JoinCode model is available
    // This is the actual implementation ready to use
    /*
    final isActive = joinCode.status == 'active';
    final isExpired = joinCode.expiresAt.isBefore(DateTime.now());
    final remainingUses = joinCode.maxUses - joinCode.uses;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(context, joinCode.status),
          child: Icon(
            isActive ? Icons.qr_code_2 : Icons.block,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Code ••••${joinCode.codeHash.substring(joinCode.codeHash.length - 4)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            _buildStatusChip(context, joinCode.status),
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
                Text('Role: ${_formatRole(joinCode.role)}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Uses: ${joinCode.uses} / ${joinCode.maxUses}'),
                const SizedBox(width: 8),
                if (remainingUses > 0)
                  Text(
                    '($remainingUses remaining)',
                    style: TextStyle(color: theme.colorScheme.primary),
                  )
                else
                  Text(
                    '(depleted)',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  isExpired
                      ? 'Expired ${_formatDate(joinCode.expiresAt)}'
                      : 'Expires ${_formatDate(joinCode.expiresAt)}',
                  style: TextStyle(
                    color: isExpired ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
            if (joinCode.notes != null && joinCode.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.note_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      joinCode.notes!,
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
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy Identifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (isActive)
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
            if (value == 'copy') {
              onCopy();
            } else if (value == 'revoke') {
              onRevoke();
            }
          },
        ),
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
            backgroundColor: _getStatusColor(context, 'active'),
            child: const Icon(Icons.qr_code_2, color: Colors.white),
          ),
          title: Row(
            children: [
              Text('Join Code #${joinCode?.toString() ?? 'N/A'}'),
              HSpace.xs,
              _buildStatusChip(context, 'active'),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VSpace.xxs,
              const Text('Role: Staff'),
              const Text('Uses: 0 / 5'),
              Text('Expires: ${DateFormat.yMMMd().format(DateTime.now().add(const Duration(days: 7)))}'),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Code'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
              if (value == 'copy') {
                onCopy();
              } else if (value == 'revoke') {
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
      case 'active':
        return Colors.green;
      case 'revoked':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }
}
