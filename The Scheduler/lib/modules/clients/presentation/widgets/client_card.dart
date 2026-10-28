import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';

/// Card-based layout for displaying a client in the list.
/// Updated by Agent (2025-11-30) - Replaced table row with modern card design
class ClientCard extends ConsumerWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.nextAppointment,
    required this.onTap,
    required this.onQuickActions,
  });

  final Client client;
  final DateTime? nextAppointment;
  final VoidCallback onTap;
  final VoidCallback onQuickActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    final initials = client.fullName.isNotEmpty
        ? client.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .map((p) => p.isNotEmpty ? p[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    final nextDate = nextAppointment != null
        ? '${nextAppointment!.month}/${nextAppointment!.day}/${nextAppointment!.year}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(branding, theme, initials),
                  HSpace.md,
                  // Client info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: branding.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildLifecycleBadge(branding, theme),
                          ],
                        ),
                        VSpace.xs,
                        _buildClientDetails(theme, nextDate),
                        if (client.tags.isNotEmpty) ...[
                          VSpace.xs,
                          _buildTags(theme),
                        ],
                      ],
                    ),
                  ),
                  HSpace.sm,
                  // Quick actions button
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onQuickActions,
                    tooltip: 'Quick actions',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppBranding branding, ThemeData theme, String initials) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [branding.primaryColor, branding.accentColor],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLifecycleBadge(AppBranding branding, ThemeData theme) {
    final (color, bgColor) = _getLifecycleColors(branding);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        _getLifecycleLabel(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getLifecycleColors(AppBranding branding) {
    switch (client.lifecycle) {
      case ClientLifecycle.newClient:
        return (
          branding.effectiveCtaColor,
          branding.effectiveCtaColor.withValues(alpha: 0.12),
        );
      case ClientLifecycle.active:
        return (AppColors.success, AppColors.success.withValues(alpha: 0.12));
      case ClientLifecycle.inactive:
        return (AppColors.warning, AppColors.warning.withValues(alpha: 0.12));
      case ClientLifecycle.churned:
        return (
          AppColors.textSecondary,
          AppColors.textSecondary.withValues(alpha: 0.12),
        );
    }
  }

  String _getLifecycleLabel() {
    switch (client.lifecycle) {
      case ClientLifecycle.newClient:
        return 'New';
      case ClientLifecycle.active:
        return 'Active';
      case ClientLifecycle.inactive:
        return 'Inactive';
      case ClientLifecycle.churned:
        return 'Churned';
    }
  }

  Widget _buildClientDetails(ThemeData theme, String? nextDate) {
    final details = <String>[];

    if (client.email != null && client.email!.isNotEmpty) {
      details.add(client.email!);
    }

    if (client.phone != null && client.phone!.isNotEmpty) {
      details.add(client.phone!);
    }

    return Row(
      children: [
        if (details.isNotEmpty)
          Expanded(
            child: Text(
              details.join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (nextDate != null) ...[
          HSpace.sm,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: AppIconSize.xs,
                color: theme.colorScheme.primary,
              ),
              HSpace.xxs,
              Text(
                nextDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTags(ThemeData theme) {
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: client.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            tag,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
