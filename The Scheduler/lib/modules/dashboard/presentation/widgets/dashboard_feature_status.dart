import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';

/// Grid showing enabled/disabled feature flags with warm Ember styling.
/// Enabled features use a gradient pill, disabled use a muted chip.
class DashboardFeatureStatus extends StatelessWidget {
  const DashboardFeatureStatus({required this.status, super.key});

  final Map<String, bool> status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Feature Readiness',
          subtitle: 'Enabled features for your practice',
          padding: EdgeInsets.zero,
        ),
        VSpace.md,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: status.entries.map((entry) {
            final enabled = entry.value;
            // Enabled features use gradient pill with ember glow
            if (enabled) {
              return GradientPill(
                label: entry.key,
                icon: Icons.check_circle,
              );
            }
            // Disabled features use muted chip
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pending,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
