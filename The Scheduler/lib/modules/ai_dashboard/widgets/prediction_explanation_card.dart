import 'package:flutter/material.dart';

import '../../../ai/models/prediction_explanation.dart';
import '../../../core/ui/accessibility_helpers.dart';

/// Widget that displays human-readable explanation for a no-show prediction.
///
/// Shows:
/// - Summary sentence explaining the prediction
/// - Top factors with impact indicators (increases/decreases risk)
/// - Expandable details section
///
/// **Usage:**
/// ```dart
/// PredictionExplanationCard(
///   explanation: explanation,
///   onFactorTap: (factor) => showFactorDetails(factor),
/// )
/// ```
///
/// Agent AI-19: Prediction Explainability
class PredictionExplanationCard extends StatefulWidget {
  const PredictionExplanationCard({
    super.key,
    required this.explanation,
    this.onFactorTap,
    this.initiallyExpanded = false,
    this.showSummary = true,
    this.compact = false,
  });

  /// The prediction explanation to display.
  final PredictionExplanation explanation;

  /// Called when a factor is tapped (optional).
  final void Function(ExplanationFactor factor)? onFactorTap;

  /// Whether the card starts in expanded state.
  final bool initiallyExpanded;

  /// Whether to show the summary section.
  final bool showSummary;

  /// Use compact layout for inline display.
  final bool compact;

  @override
  State<PredictionExplanationCard> createState() =>
      _PredictionExplanationCardState();
}

class _PredictionExplanationCardState extends State<PredictionExplanationCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SemanticWrapper(
      label: 'Prediction explanation: ${widget.explanation.summary}',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with "Why this prediction?" and expand toggle
            _buildHeader(context),

            // Summary section
            if (widget.showSummary && widget.explanation.summary.isNotEmpty)
              _buildSummary(context),

            // Factors list (always visible or only when expanded)
            if (_isExpanded || widget.initiallyExpanded)
              _buildFactorsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SemanticWrapper(
      label: 'Prediction explanation',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why this prediction?',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.explanation.shortExplanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Why this prediction?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final riskColor = _getRiskColor(colorScheme);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getRiskIcon(),
            color: riskColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.explanation.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Factors',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.explanation.topFactors.map(
            (factor) => _buildFactorItem(context, factor),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorItem(BuildContext context, ExplanationFactor factor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIncreasing = factor.impact == 'increases';
    final impactColor = isIncreasing
        ? colorScheme.error
        : Colors.green.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.onFactorTap != null
            ? () => widget.onFactorTap!(factor)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Impact indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncreasing
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: impactColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Factor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factor.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIncreasing ? 'Increases risk' : 'Decreases risk',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: impactColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Magnitude indicator
              _buildMagnitudeIndicator(context, factor.magnitude, impactColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagnitudeIndicator(
    BuildContext context,
    double magnitude,
    Color color,
  ) {
    // Show 1-5 dots based on magnitude
    final dotCount = (magnitude * 5).ceil().clamp(1, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < dotCount;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? color
                : color.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }

  Color _getRiskColor(ColorScheme colorScheme) {
    switch (widget.explanation.riskLevel.toLowerCase()) {
      case 'high':
        return colorScheme.error;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getRiskIcon() {
    switch (widget.explanation.riskLevel.toLowerCase()) {
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline;
      case 'low':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }
}

/// Simple inline widget showing just the primary explanation factor.
///
/// Use this for compact displays like list items or tooltips.
class PredictionExplanationChip extends StatelessWidget {
  const PredictionExplanationChip({
    super.key,
    required this.explanation,
    this.onTap,
  });

  final PredictionExplanation explanation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryFactor = explanation.primaryFactor;

    if (primaryFactor == null) {
      return const SizedBox.shrink();
    }

    final isIncreasing = primaryFactor.impact == 'increases';
    final color = isIncreasing
        ? colorScheme.error
        : Colors.green.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIncreasing ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                primaryFactor.explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tooltip content for prediction explanations.
class PredictionExplanationTooltip extends StatelessWidget {
  const PredictionExplanationTooltip({
    super.key,
    required this.explanation,
  });

  final PredictionExplanation explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why ${explanation.probabilityPercent} no-show risk?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation.summary,
            style: theme.textTheme.bodySmall,
          ),
          if (explanation.topFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...explanation.topFactors.take(3).map((factor) {
              final isIncreasing = factor.impact == 'increases';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isIncreasing ? Icons.add : Icons.remove,
                      size: 12,
                      color: isIncreasing ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        factor.explanation,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
