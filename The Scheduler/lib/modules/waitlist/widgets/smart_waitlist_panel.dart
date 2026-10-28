import 'package:flutter/material.dart';

import '../../../ai/models/waitlist_score.dart';
import '../../../core/ui/components/components.dart';

/// Panel displaying AI-ranked waitlist candidates.
///
/// Shows top candidates for a cancelled slot with match scores
/// and enables quick offer sending.
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
class SmartWaitlistPanel extends StatelessWidget {
  const SmartWaitlistPanel({
    super.key,
    required this.result,
    required this.onSendOffer,
    required this.onSelectCandidate,
    this.onDismiss,
  });

  /// Waitlist match result.
  final WaitlistMatchResult result;

  /// Called when sending offer to a candidate.
  final void Function(RankedWaitlistEntry candidate) onSendOffer;

  /// Called when selecting a candidate for details.
  final void Function(RankedWaitlistEntry candidate) onSelectCandidate;

  /// Called to dismiss the panel.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!result.hasCandidates) {
      return _buildEmptyState(context);
    }

    return AppCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: AppIconSize.md,
                ),
                HSpace.sm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Waitlist Match',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${result.candidateCount} candidates found',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          // Top candidates
          if (result.topCandidates.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: AppIconSize.sm,
                        color: AppColors.warning,
                      ),
                      HSpace.xs,
                      Text(
                        'Top Candidates',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  VSpace.sm,
                  ...result.topCandidates.map((candidate) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CandidateCard(
                        candidate: candidate,
                        isTop: true,
                        onSendOffer: () => onSendOffer(candidate),
                        onTap: () => onSelectCandidate(candidate),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          // Other candidates
          if (result.candidates.length > result.topCandidates.length) ...[
            const Divider(height: 1),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              title: Text(
                'Other Candidates (${result.candidates.length - result.topCandidates.length})',
                style: theme.textTheme.titleSmall,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: result.candidates
                        .skip(result.topCandidates.length)
                        .map((candidate) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _CandidateCard(
                          candidate: candidate,
                          isTop: false,
                          onSendOffer: () => onSendOffer(candidate),
                          onTap: () => onSelectCandidate(candidate),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                VSpace.sm,
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: AppIconSize.lg,
              color: theme.disabledColor,
            ),
            VSpace.md,
            Text(
              'No Waitlist Matches',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            VSpace.xs,
            Text(
              result.noMatchReason ?? 'No candidates found for this slot',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual candidate card.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.isTop,
    required this.onSendOffer,
    required this.onTap,
  });

  final RankedWaitlistEntry candidate;
  final bool isTop;
  final VoidCallback onSendOffer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = candidate.score;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isTop ? AppColors.riskLowBg : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isTop ? AppColors.riskLowBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isTop ? AppColors.riskLow : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${candidate.rank}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            HSpace.sm,
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        candidate.clientName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      HSpace.xs,
                      _ScoreBadge(score: score.overallScore),
                    ],
                  ),
                  VSpace.xs,
                  Text(
                    candidate.serviceName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (candidate.matchReasoning != null) ...[
                    VSpace.xs,
                    Text(
                      candidate.matchReasoning!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isTop
                            ? AppColors.riskLow
                            : theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            if (!candidate.offerSent)
              FilledButton.tonal(
                onPressed: onSendOffer,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                child: const Text('Send Offer'),
              )
            else
              Chip(
                label: Text(
                  candidate.offerResponse ?? 'Sent',
                  style: theme.textTheme.labelSmall,
                ),
                backgroundColor: AppColors.surfaceSubtle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Score badge widget.
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score >= 70
        ? AppColors.riskLow
        : score >= 50
            ? AppColors.warning
            : AppColors.textSecondary;
    final bg = score >= 70
        ? AppColors.riskLowBg
        : score >= 50
            ? AppColors.riskMediumBg
            : AppColors.riskUnknownBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '${score.round()}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Waitlist score breakdown widget.
class WaitlistScoreBreakdown extends StatelessWidget {
  const WaitlistScoreBreakdown({
    super.key,
    required this.score,
  });

  final WaitlistScore score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Match Score',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  score.scoreDisplay,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: score.isStrongMatch
                        ? AppColors.riskLow
                        : score.isGoodMatch
                            ? AppColors.warning
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Factor breakdown
            ...score.factors.map((factor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FactorRow(factor: factor),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Factor row in breakdown.
class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final WaitlistScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = factor.percentOfMax;
    final color = percent >= 70
        ? AppColors.riskLow
        : percent >= 40
            ? AppColors.warning
            : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIcon(factor.factorType),
              size: AppIconSize.sm,
              color: color,
            ),
            HSpace.sm,
            Text(
              _getLabel(factor.factorType),
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '${factor.impact.toStringAsFixed(1)}/${factor.maxImpact.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        VSpace.xs,
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: AppColors.riskUnknownBg,
          valueColor: AlwaysStoppedAnimation(color),
        ),
        VSpace.xs,
        Text(
          factor.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getIcon(WaitlistFactorType type) {
    switch (type) {
      case WaitlistFactorType.timeFlexibility:
        return Icons.schedule;
      case WaitlistFactorType.proximity:
        return Icons.location_on;
      case WaitlistFactorType.confirmRate:
        return Icons.check_circle;
      case WaitlistFactorType.revenue:
        return Icons.attach_money;
      case WaitlistFactorType.fairness:
        return Icons.hourglass_empty;
      case WaitlistFactorType.serviceMatch:
        return Icons.spa;
      case WaitlistFactorType.providerPreference:
        return Icons.person;
    }
  }

  String _getLabel(WaitlistFactorType type) {
    switch (type) {
      case WaitlistFactorType.timeFlexibility:
        return 'Time Match';
      case WaitlistFactorType.proximity:
        return 'Location';
      case WaitlistFactorType.confirmRate:
        return 'Accept Rate';
      case WaitlistFactorType.revenue:
        return 'Value';
      case WaitlistFactorType.fairness:
        return 'Wait Time';
      case WaitlistFactorType.serviceMatch:
        return 'Service';
      case WaitlistFactorType.providerPreference:
        return 'Provider';
    }
  }
}
