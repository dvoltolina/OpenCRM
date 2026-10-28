import 'package:flutter/material.dart';

import '../../../ai/models/slot_suggestion.dart';
import '../../../core/ui/components/components.dart';

/// Visual indicator for slot no-show risk level.
///
/// Shows risk as colored badge, icon, or detailed breakdown
/// depending on the display mode.
///
/// Agent AI-20: Smart Scheduling Suggestions
class SlotRiskIndicator extends StatelessWidget {
  const SlotRiskIndicator({
    super.key,
    required this.slot,
    this.mode = RiskDisplayMode.badge,
    this.showPercentage = true,
    this.onTap,
  });

  /// The scored slot to display risk for.
  final ScoredSlot slot;

  /// Display mode (badge, icon, or detailed).
  final RiskDisplayMode mode;

  /// Whether to show percentage in badge mode.
  final bool showPercentage;

  /// Called when indicator is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case RiskDisplayMode.badge:
        return _buildBadge(context);
      case RiskDisplayMode.icon:
        return _buildIcon(context);
      case RiskDisplayMode.detailed:
        return _buildDetailed(context);
      case RiskDisplayMode.mini:
        return _buildMini(context);
    }
  }

  Widget _buildBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getRiskColors(slot.riskLevel);
    final riskPercent = (slot.predictedNoshowRisk * 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              colors.icon,
              size: AppIconSize.xs,
              color: colors.foreground,
            ),
            HSpace.xs,
            Text(
              showPercentage ? '$riskPercent% risk' : _getRiskLabel(slot.riskLevel),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colors = _getRiskColors(slot.riskLevel);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: '${(slot.predictedNoshowRisk * 100).toStringAsFixed(0)}% no-show risk',
        child: Icon(
          colors.icon,
          size: AppIconSize.sm,
          color: colors.foreground,
        ),
      ),
    );
  }

  Widget _buildMini(BuildContext context) {
    final colors = _getRiskColors(slot.riskLevel);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colors.foreground,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDetailed(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getRiskColors(slot.riskLevel);
    final riskPercent = (slot.predictedNoshowRisk * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                colors.icon,
                size: AppIconSize.sm,
                color: colors.foreground,
              ),
              HSpace.xs,
              Text(
                '${_getRiskLabel(slot.riskLevel)} Risk',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$riskPercent%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Factors
          if (slot.scoreFactors.isNotEmpty) ...[
            VSpace.xs,
            ...slot.scoreFactors.take(3).map((factor) {
              final isPositive = factor.impact > 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.add_circle : Icons.remove_circle,
                      size: AppIconSize.xs,
                      color: isPositive
                          ? AppColors.riskLow
                          : AppColors.riskHigh,
                    ),
                    HSpace.xs,
                    Expanded(
                      child: Text(
                        factor.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Recommendation reason
          if (slot.recommendationReason != null) ...[
            VSpace.xs,
            Text(
              slot.recommendationReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.foreground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _RiskColors _getRiskColors(SlotRiskLevel level) {
    switch (level) {
      case SlotRiskLevel.low:
        return _RiskColors(
          background: AppColors.riskLowBg,
          foreground: AppColors.riskLow,
          border: AppColors.riskLowBorder,
          icon: Icons.check_circle,
        );
      case SlotRiskLevel.medium:
        return _RiskColors(
          background: AppColors.riskMediumBg,
          foreground: AppColors.riskMedium,
          border: AppColors.riskMediumBorder,
          icon: Icons.warning_amber,
        );
      case SlotRiskLevel.high:
        return _RiskColors(
          background: AppColors.riskHighBg,
          foreground: AppColors.riskHigh,
          border: AppColors.riskHighBorder,
          icon: Icons.error,
        );
      case SlotRiskLevel.unknown:
        return _RiskColors(
          background: AppColors.riskUnknownBg,
          foreground: AppColors.riskUnknown,
          border: AppColors.riskUnknownBorder,
          icon: Icons.help_outline,
        );
    }
  }

  String _getRiskLabel(SlotRiskLevel level) {
    switch (level) {
      case SlotRiskLevel.low:
        return 'Low';
      case SlotRiskLevel.medium:
        return 'Medium';
      case SlotRiskLevel.high:
        return 'High';
      case SlotRiskLevel.unknown:
        return 'Unknown';
    }
  }
}

class _RiskColors {
  const _RiskColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final IconData icon;
}

enum RiskDisplayMode {
  /// Colored badge with text
  badge,

  /// Icon only
  icon,

  /// Full breakdown with factors
  detailed,

  /// Tiny colored dot
  mini,
}

/// Warning banner for high-risk slots.
class HighRiskSlotWarning extends StatelessWidget {
  const HighRiskSlotWarning({
    super.key,
    required this.slot,
    this.alternatives = const [],
    this.onSelectAlternative,
    this.onDismiss,
  });

  final ScoredSlot slot;
  final List<ScoredSlot> alternatives;
  final void Function(ScoredSlot)? onSelectAlternative;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.riskHighBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning header
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: AppIconSize.sm,
                color: AppColors.riskHigh,
              ),
              HSpace.xs,
              Expanded(
                child: Text(
                  'Higher No-Show Risk',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.riskHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: AppIconSize.xs),
                  onPressed: onDismiss,
                  color: AppColors.riskHigh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          VSpace.xs,
          // Reason
          Text(
            slot.recommendationReason ??
                'This time slot has higher no-show risk based on client history.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.riskHigh,
            ),
          ),
          // Alternatives
          if (alternatives.isNotEmpty && onSelectAlternative != null) ...[
            VSpace.sm,
            Text(
              'Consider these alternatives:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.riskHigh,
                fontWeight: FontWeight.w500,
              ),
            ),
            VSpace.xs,
            ...alternatives.take(2).map((alt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => onSelectAlternative!(alt),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.riskLowBg,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: AppIconSize.xs,
                          color: AppColors.riskLow,
                        ),
                        HSpace.xs,
                        Expanded(
                          child: Text(
                            '${alt.formattedTime} with ${alt.providerName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.riskLow,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: AppIconSize.sm,
                          color: AppColors.riskLow,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Risk comparison chip showing improvement/degradation.
class RiskComparisonChip extends StatelessWidget {
  const RiskComparisonChip({
    super.key,
    required this.differencePercent,
  });

  final double differencePercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImprovement = differencePercent < 0;
    final color = isImprovement ? AppColors.riskLow : AppColors.riskHigh;
    final bg = isImprovement ? AppColors.riskLowBg : AppColors.riskHighBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImprovement ? Icons.trending_down : Icons.trending_up,
            size: AppIconSize.xs,
            color: color,
          ),
          HSpace.xxs,
          Text(
            '${differencePercent.abs().toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
