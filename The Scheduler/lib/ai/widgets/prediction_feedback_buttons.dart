import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prediction_feedback.dart';

/// Callback for when feedback is submitted.
typedef FeedbackCallback = Future<void> Function(
  FeedbackType type, {
  NegativeFeedbackReason? reason,
  String? comment,
});

/// Widget for collecting user feedback on predictions.
///
/// Displays thumbs up/down buttons and handles feedback flow.
/// Supports experiment tracking through optional assignment IDs.
///
/// Agent AI-18: A/B Testing & Feedback Loop Framework
class PredictionFeedbackButtons extends ConsumerStatefulWidget {
  const PredictionFeedbackButtons({
    super.key,
    required this.onFeedback,
    this.existingFeedback,
    this.compact = false,
    this.showSkip = false,
    this.label,
    this.experimentAssignmentId,
  });

  /// Callback when feedback is submitted
  final FeedbackCallback onFeedback;

  /// Existing feedback to show (if already submitted)
  final FeedbackType? existingFeedback;

  /// Use compact layout
  final bool compact;

  /// Show skip option
  final bool showSkip;

  /// Label to display above buttons
  final String? label;

  /// Experiment assignment ID for tracking
  final String? experimentAssignmentId;

  @override
  ConsumerState<PredictionFeedbackButtons> createState() =>
      _PredictionFeedbackButtonsState();
}

class _PredictionFeedbackButtonsState
    extends ConsumerState<PredictionFeedbackButtons> {
  FeedbackType? _selectedType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingFeedback;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedType != null && _selectedType != FeedbackType.skipped) {
      return _buildSubmittedState();
    }

    if (widget.compact) {
      return _buildCompactButtons();
    }

    return _buildFullButtons();
  }

  Widget _buildSubmittedState() {
    final theme = Theme.of(context);
    final isPositive = _selectedType == FeedbackType.positive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isPositive
            ? theme.colorScheme.primary
            : theme.colorScheme.error)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.thumb_up : Icons.thumb_down,
            size: 16,
            color: isPositive
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            isPositive ? 'Thanks for feedback!' : 'Thanks for feedback',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
        _buildIconButton(
          icon: Icons.thumb_up_outlined,
          selectedIcon: Icons.thumb_up,
          type: FeedbackType.positive,
          isPositive: true,
        ),
        const SizedBox(width: 4),
        _buildIconButton(
          icon: Icons.thumb_down_outlined,
          selectedIcon: Icons.thumb_down,
          type: FeedbackType.negative,
          isPositive: false,
        ),
        if (widget.showSkip) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: _isSubmitting ? null : () => _submitFeedback(FeedbackType.skipped),
            icon: const Icon(Icons.skip_next_outlined),
            iconSize: 20,
            tooltip: 'Skip',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildFullButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildFeedbackButton(
                icon: Icons.thumb_up_outlined,
                label: 'Helpful',
                type: FeedbackType.positive,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeedbackButton(
                icon: Icons.thumb_down_outlined,
                label: 'Not Helpful',
                type: FeedbackType.negative,
                isPositive: false,
              ),
            ),
          ],
        ),
        if (widget.showSkip)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitFeedback(FeedbackType.skipped),
                child: const Text('Skip'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required IconData selectedIcon,
    required FeedbackType type,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    final color = isPositive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return IconButton(
      onPressed: _isSubmitting ? null : () => _handleFeedback(type),
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon),
      isSelected: _selectedType == type,
      color: _selectedType == type ? color : null,
      iconSize: 20,
      tooltip: isPositive ? 'Helpful' : 'Not helpful',
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required FeedbackType type,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;
    final color = isPositive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return OutlinedButton.icon(
      onPressed: _isSubmitting ? null : () => _handleFeedback(type),
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : color,
        backgroundColor: isSelected ? color : null,
        side: BorderSide(color: color),
      ),
    );
  }

  Future<void> _handleFeedback(FeedbackType type) async {
    if (type == FeedbackType.negative) {
      final result = await _showNegativeFeedbackDialog();
      if (result != null) {
        await _submitFeedback(
          FeedbackType.negative,
          reason: result.reason,
          comment: result.comment,
        );
      }
    } else {
      await _submitFeedback(type);
    }
  }

  Future<_NegativeFeedbackResult?> _showNegativeFeedbackDialog() async {
    return showDialog<_NegativeFeedbackResult>(
      context: context,
      builder: (context) => const _NegativeFeedbackDialog(),
    );
  }

  Future<void> _submitFeedback(
    FeedbackType type, {
    NegativeFeedbackReason? reason,
    String? comment,
  }) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onFeedback(
        type,
        reason: reason,
        comment: comment,
      );

      if (mounted) {
        setState(() {
          _selectedType = type;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Dialog for collecting negative feedback details.
class _NegativeFeedbackDialog extends StatefulWidget {
  const _NegativeFeedbackDialog();

  @override
  State<_NegativeFeedbackDialog> createState() => _NegativeFeedbackDialogState();
}

class _NegativeFeedbackDialogState extends State<_NegativeFeedbackDialog> {
  NegativeFeedbackReason? _selectedReason;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What went wrong?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve by telling us why this prediction was not helpful.',
            ),
            const SizedBox(height: 16),
            ...NegativeFeedbackReason.values.map((reason) {
              return RadioListTile<NegativeFeedbackReason>(
                title: Text(reason.displayName),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Additional comments (optional)',
                hintText: 'Any other details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.of(context).pop(
                    _NegativeFeedbackResult(
                      reason: _selectedReason!,
                      comment: _commentController.text.isNotEmpty
                          ? _commentController.text
                          : null,
                    ),
                  );
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

/// Result from the negative feedback dialog.
class _NegativeFeedbackResult {
  const _NegativeFeedbackResult({
    required this.reason,
    this.comment,
  });

  final NegativeFeedbackReason reason;
  final String? comment;
}

/// Inline feedback prompt for predictions.
class PredictionFeedbackPrompt extends StatelessWidget {
  const PredictionFeedbackPrompt({
    super.key,
    required this.onFeedback,
    this.predictionLabel = 'prediction',
  });

  final FeedbackCallback onFeedback;
  final String predictionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Was this $predictionLabel helpful?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            PredictionFeedbackButtons(
              onFeedback: onFeedback,
              compact: true,
              showSkip: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge showing feedback status.
class FeedbackStatusBadge extends StatelessWidget {
  const FeedbackStatusBadge({
    super.key,
    required this.feedbackType,
  });

  final FeedbackType feedbackType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (feedbackType) {
      case FeedbackType.positive:
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        foregroundColor = theme.colorScheme.primary;
        icon = Icons.thumb_up;
        label = 'Helpful';
        break;
      case FeedbackType.negative:
        backgroundColor = theme.colorScheme.error.withValues(alpha: 0.1);
        foregroundColor = theme.colorScheme.error;
        icon = Icons.thumb_down;
        label = 'Not Helpful';
        break;
      case FeedbackType.skipped:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.skip_next;
        label = 'Skipped';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
