import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';

/// Client list item widget with avatar, name, status, and quick actions.
/// Updated by Agent U3 (2025-11-28) - Uses design system primitives
class ClientListItem extends StatelessWidget {
  const ClientListItem({
    super.key,
    required this.client,
    required this.onTap,
    required this.onQuickAction,
    this.nextAppointment,
  });

  final Client client;
  final VoidCallback onTap;
  final VoidCallback onQuickAction;
  final DateTime? nextAppointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar with initials - using AppIconSize
            CircleAvatar(
              radius: AppIconSize.md / 2,
              backgroundColor: Color(client.lifecycleColorValue)
                  .withValues(alpha: 0.2),
              child: Text(
                client.initials,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Color(client.lifecycleColorValue),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      HSpace.xs,
                      // Lifecycle badge using StatusPill
                      StatusPill(
                        label: client.lifecycleDisplay,
                        color: Color(client.lifecycleColorValue),
                        backgroundColor: Color(client.lifecycleColorValue)
                            .withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                  VSpace.xxs,
                  // Contact info
                  Row(
                    children: [
                      if (client.hasEmail) ...[
                        Icon(
                          Icons.email_outlined,
                          size: AppIconSize.xs,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        HSpace.xxs,
                        Flexible(
                          child: Text(
                            client.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (client.hasEmail && client.hasPhone) HSpace.md,
                      if (client.hasPhone) ...[
                        Icon(
                          Icons.phone_outlined,
                          size: AppIconSize.xs,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        HSpace.xxs,
                        Text(
                          client.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (client.lastAppointmentDate != null) ...[
                    VSpace.xxs,
                    Text(
                      'Last visit: ${DateFormat.yMMMd().format(client.lastAppointmentDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (nextAppointment != null) ...[
                    VSpace.xxs,
                    Text(
                      'Next: ${DateFormat.yMMMd().format(nextAppointment!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // Tags - using design tokens
                  if (client.tags.isNotEmpty) ...[
                    VSpace.xs,
                    Wrap(
                      spacing: AppSpacing.xxs,
                      runSpacing: AppSpacing.xxs,
                      children: client.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            HSpace.xs,
            // Quick action button
            IconButton(
              icon: const Icon(Icons.more_vert),
              iconSize: AppIconSize.md,
              onPressed: onQuickAction,
            ),
          ],
        ),
      ),
    );
  }
}
