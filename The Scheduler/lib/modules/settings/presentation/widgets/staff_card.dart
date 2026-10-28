import 'package:flutter/material.dart';

import '../../../../data/models/staff_member.dart';
import '../../../../data/models/user_role.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.member,
    this.onEdit,
    this.onDeactivate,
    this.onReactivate,
    this.onViewActivity,
  });

  final StaffMember member;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onViewActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusChip = _buildStatusChip(theme);
    final roleChip = _buildRoleChip(theme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            _initials(member.displayName),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName
                    : member.email,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (roleChip != null) roleChip,
            const SizedBox(width: 8),
            statusChip,
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.email,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _lastActiveText(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'deactivate':
                onDeactivate?.call();
                break;
              case 'reactivate':
                onReactivate?.call();
                break;
              case 'activity':
                onViewActivity?.call();
                break;
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit role/permissions'),
                ),
              if (onViewActivity != null)
                const PopupMenuItem(
                  value: 'activity',
                  child: Text('View activity'),
                ),
            ];

            if (member.isDeactivated) {
              if (onReactivate != null) {
                items.add(
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reactivate'),
                  ),
                );
              }
            } else if (onDeactivate != null) {
              items.add(
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate'),
                ),
              );
            }

            return items;
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color color;
    String label;
    switch (member.status) {
      case StaffStatus.active:
        color = theme.colorScheme.primary;
        label = 'Active';
        break;
      case StaffStatus.pending:
        color = theme.colorScheme.tertiary;
        label = 'Pending';
        break;
      case StaffStatus.deactivated:
        color = theme.colorScheme.error;
        label = 'Deactivated';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildRoleChip(ThemeData theme) {
    final color = theme.colorScheme.secondary;
    final label = _roleLabel(member.role);
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.sales:
        return 'Sales';
      case UserRole.provider:
      case UserRole.staff:
        return 'Provider';
      case UserRole.frontDesk:
        return 'Front Desk';
      case UserRole.client:
        return 'Client';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _lastActiveText() {
    final DateTime? lastActive = member.lastLoginAt ?? member.createdAt;
    if (lastActive == null) return 'No activity recorded';
    final now = DateTime.now();
    final diff = now.difference(lastActive);
    if (diff.inMinutes < 60) {
      return 'Last active: ${diff.inMinutes}m ago';
    } else if (diff.inHours < 48) {
      return 'Last active: ${diff.inHours}h ago';
    } else {
      return 'Last active: ${lastActive.toLocal().toIso8601String().split('T').first}';
    }
  }
}
