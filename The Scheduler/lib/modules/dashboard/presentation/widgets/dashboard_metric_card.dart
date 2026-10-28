import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';

/// Data model for metric cards
class MetricCardData {
  const MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? trend; // Percentage change, positive = increase
}

/// Metric card displaying a key performance indicator.
/// Updated with Modern Sophisticated Blue design system - soft shadows and gradient icon background.
class DashboardMetricCard extends ConsumerWidget {
  const DashboardMetricCard({required this.data, super.key});

  final MetricCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final semanticLabel = '${data.title}: ${data.value}, ${data.subtitle}';

    return Semantics(
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          // Soft layered shadows with blue tint
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: branding.accentColor.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.color.withValues(alpha: 0.15),
                          data.color.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: AppIconSize.md,
                    ),
                  ),
                  HSpace.sm,
                  Expanded(
                    child: Text(
                      data.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (data.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: data.trend! > 0
                              ? [
                                  AppColors.error.withValues(alpha: 0.12),
                                  AppColors.error.withValues(alpha: 0.08),
                                ]
                              : [
                                  AppColors.success.withValues(alpha: 0.12),
                                  AppColors.success.withValues(alpha: 0.08),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.trend! > 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: AppIconSize.xs,
                            color: data.trend! > 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          HSpace.xxs,
                          Text(
                            '${data.trend!.abs().toStringAsFixed(1)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: data.trend! > 0
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              VSpace.md,
              Text(
                data.value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              VSpace.xs,
              Text(
                data.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
