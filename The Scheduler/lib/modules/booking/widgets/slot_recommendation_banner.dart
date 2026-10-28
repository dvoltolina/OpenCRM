import 'package:flutter/material.dart';

import '../../../ai/models/slot_suggestion.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/ui/components/components.dart';

/// Banner displaying slot recommendation for a client.
///
/// Shows "Recommended for this client" badge with reasoning
/// on slots that have lower predicted no-show risk.
///
/// Agent AI-20: Smart Scheduling Suggestions
class SlotRecommendationBanner extends StatelessWidget {
  const SlotRecommendationBanner({
    super.key,
    required this.suggestion,
    this.onTap,
    this.compact = false,
  });

  /// The slot suggestion to display.
  final SlotSuggestion suggestion;

  /// Called when banner is tapped.
  final VoidCallback? onTap;

  /// Use compact layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactBanner(context);
    }

    return SemanticWrapper(
      label: 'Recommended slot: ${suggestion.headline}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.riskLowBg,
                AppColors.riskLowBg.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.riskLowBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.riskLow,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thumb_up,
                          size: AppIconSize.xs,
                          color: AppColors.surface,
                        ),
                        HSpace.xs,
                        Text(
                          suggestion.rank == 1
                              ? 'Best Match'
                              : 'Recommended',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (suggestion.confidence >= 0.7)
                    Icon(
                      Icons.verified,
                      size: AppIconSize.sm,
                      color: AppColors.riskLow,
                    ),
                ],
              ),
              VSpace.xs,
              // Headline
              Text(
                suggestion.headline,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.riskLow,
                ),
              ),
              VSpace.xs,
              // Reasoning
              Text(
                suggestion.reasoning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.riskLow,
                ),
              ),
              // Comparison text
              if (suggestion.comparisonText != null) ...[
                VSpace.xs,
                Row(
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: AppIconSize.xs,
                      color: AppColors.riskLow,
                    ),
                    HSpace.xs,
                    Expanded(
                      child: Text(
                        suggestion.comparisonText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.riskLow,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.riskLowBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.thumb_up,
            size: AppIconSize.xs,
            color: AppColors.riskLow,
          ),
          HSpace.xs,
          Text(
            'Recommended',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.riskLow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple "Recommended" badge for inline use.
class RecommendedBadge extends StatelessWidget {
  const RecommendedBadge({
    super.key,
    this.isBestMatch = false,
    this.size = BadgeSize.small,
  });

  final bool isBestMatch;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final padding = size == BadgeSize.small
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs)
        : const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs);

    final iconSize = size == BadgeSize.small ? AppIconSize.xs : AppIconSize.sm;
    final textStyle = size == BadgeSize.small
        ? theme.textTheme.labelSmall
        : theme.textTheme.labelMedium;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isBestMatch ? AppColors.riskLow : AppColors.riskLowBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        Icon(
          isBestMatch ? Icons.star : Icons.thumb_up,
          size: iconSize,
          color: isBestMatch ? AppColors.surface : AppColors.riskLow,
        ),
        HSpace.xs,
        Text(
          isBestMatch ? 'Best Match' : 'Recommended',
          style: textStyle?.copyWith(
            color: isBestMatch ? AppColors.surface : AppColors.riskLow,
            fontWeight: FontWeight.w600,
          ),
        ),
        ],
      ),
    );
  }
}

enum BadgeSize { small, medium }

/// Card showing top slot suggestions for a client.
class TopSuggestionsCard extends StatelessWidget {
  const TopSuggestionsCard({
    super.key,
    required this.result,
    required this.onSlotSelected,
    this.maxSuggestions = 3,
  });

  final SlotSuggestionResult result;
  final void Function(ScoredSlot slot) onSlotSelected;
  final int maxSuggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!result.hasRecommendations) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.riskLow,
                  size: AppIconSize.sm,
                ),
                HSpace.xs,
                Text(
                  'Recommended for This Client',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.riskLow,
                  ),
                ),
              ],
            ),
            if (!result.hasReliableHistory) ...[
              VSpace.xs,
              Text(
                result.insufficientHistoryMessage ?? 'Limited history available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            VSpace.sm,
            // Suggestions list
            ...result.topSuggestions.take(maxSuggestions).map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SuggestionRow(
                  suggestion: suggestion,
                  onTap: () => onSlotSelected(suggestion.slot),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.onTap,
  });

  final SlotSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = suggestion.slot;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.riskLowBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            // Rank indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: suggestion.rank == 1
                    ? AppColors.riskLow
                    : AppColors.riskLowBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${suggestion.rank}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: suggestion.rank == 1
                        ? Colors.white
                        : AppColors.riskLow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            HSpace.sm,
            // Slot info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.dayName}, ${slot.formattedDate} at ${slot.formattedTime}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${slot.providerName} • ${suggestion.reasoning}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.riskLow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColors.riskLow,
              size: AppIconSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}
