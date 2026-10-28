import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/appointment.dart';
import '../../data/models/security_context.dart';
import '../models/noshow_prediction.dart';
import '../providers/prediction_providers.dart';

/// Builder widget that handles prediction loading states.
///
/// Automatically fetches predictions for an appointment and handles:
/// - Loading state (shows spinner or custom widget)
/// - Error state (shows fallback or custom widget)
/// - Unavailable state (when AI service is down)
/// - Data state (calls builder with prediction)
///
/// Usage:
/// ```dart
/// PredictionAwareBuilder(
///   securityContext: context,
///   appointment: appointment,
///   builder: (context, prediction) {
///     return RiskBadge(prediction: prediction);
///   },
/// )
/// ```
///
/// Agent AI-4: Flutter Prediction Integration
class PredictionAwareBuilder extends ConsumerWidget {
  const PredictionAwareBuilder({
    super.key,
    required this.securityContext,
    required this.appointment,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.unavailableWidget,
    this.showLoadingIndicator = true,
  });

  /// Security context for multi-tenant isolation
  final SecurityContext securityContext;

  /// Appointment to get prediction for
  final Appointment appointment;

  /// Builder called when prediction is available
  final Widget Function(BuildContext context, NoshowPrediction prediction)
      builder;

  /// Widget to show while loading (default: small spinner)
  final Widget? loadingWidget;

  /// Widget to show on error (default: empty)
  final Widget? errorWidget;

  /// Widget to show when prediction unavailable (default: empty)
  final Widget? unavailableWidget;

  /// Whether to show loading indicator (default: true)
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(appointmentPredictionProvider((
      context: securityContext,
      appointment: appointment,
    )));

    return predictionAsync.when(
      data: (prediction) {
        // Check if prediction is actually available
        if (prediction.riskLevel == RiskLevel.unknown) {
          return unavailableWidget ?? const SizedBox.shrink();
        }
        return builder(context, prediction);
      },
      loading: () {
        if (!showLoadingIndicator) return const SizedBox.shrink();
        return loadingWidget ??
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
      },
      error: (error, stack) {
        return errorWidget ?? const SizedBox.shrink();
      },
    );
  }
}

/// Builder for batch predictions (e.g., list views, calendar).
///
/// Fetches predictions for multiple appointments at once,
/// which is more efficient than individual requests.
///
/// Usage:
/// ```dart
/// BatchPredictionBuilder(
///   securityContext: context,
///   appointments: appointmentsList,
///   builder: (context, predictions) {
///     return ListView.builder(
///       itemCount: appointments.length,
///       itemBuilder: (context, index) {
///         final prediction = predictions[appointments[index].id];
///         return AppointmentTile(
///           appointment: appointments[index],
///           prediction: prediction,
///         );
///       },
///     );
///   },
/// )
/// ```
class BatchPredictionBuilder extends ConsumerWidget {
  const BatchPredictionBuilder({
    super.key,
    required this.securityContext,
    required this.appointments,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  /// Security context for multi-tenant isolation
  final SecurityContext securityContext;

  /// Appointments to get predictions for
  final List<Appointment> appointments;

  /// Builder called when predictions are loaded
  /// The map keys are appointment IDs
  final Widget Function(
          BuildContext context, Map<String, NoshowPrediction> predictions)
      builder;

  /// Widget to show while loading
  final Widget? loadingWidget;

  /// Builder for error state (receives error and stack trace)
  final Widget Function(Object error, StackTrace stack)? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync = ref.watch(batchPredictionsProvider((
      context: securityContext,
      appointments: appointments,
    )));

    return predictionsAsync.when(
      data: (predictions) => builder(context, predictions),
      loading: () => loadingWidget ?? const SizedBox.shrink(),
      error: (error, stack) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stack);
        }
        // On error, still call builder with empty map
        return builder(context, {});
      },
    );
  }
}

/// A simple risk indicator badge widget.
///
/// Shows colored badge based on risk level.
/// Use this as a quick way to display risk or build your own with
/// [PredictionAwareBuilder].
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.prediction,
    this.showProbability = false,
    this.size = RiskBadgeSize.small,
  });

  final NoshowPrediction prediction;
  final bool showProbability;
  final RiskBadgeSize size;

  @override
  Widget build(BuildContext context) {
    if (prediction.riskLevel == RiskLevel.unknown) {
      return const SizedBox.shrink();
    }

    final color = Color(prediction.riskLevel.colorValue);
    final iconData = _getIcon(prediction.riskLevel);

    final fontSize = size == RiskBadgeSize.small ? 10.0 : 12.0;
    final iconSize = size == RiskBadgeSize.small ? 12.0 : 16.0;
    final padding = size == RiskBadgeSize.small
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            showProbability
                ? '${prediction.probabilityPercent}%'
                : prediction.riskLevel.shortLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.unknown:
        return Icons.help_outline;
    }
  }
}

/// Size options for risk badge
enum RiskBadgeSize {
  small,
  medium,
}

/// Widget that shows prediction details in an expandable card.
///
/// Use for detailed view of why an appointment is flagged.
class PredictionDetailCard extends StatelessWidget {
  const PredictionDetailCard({
    super.key,
    required this.prediction,
    this.onActionTap,
  });

  final NoshowPrediction prediction;
  final void Function(RecommendedAction action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    if (!prediction.isAvailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with risk badge
            Row(
              children: [
                RiskBadge(
                  prediction: prediction,
                  showProbability: true,
                  size: RiskBadgeSize.medium,
                ),
                const Spacer(),
                Text(
                  'Confidence: ${prediction.confidencePercent}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Top contributing factors
            if (prediction.topFeatures.isNotEmpty) ...[
              Text(
                'Contributing Factors',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...prediction.topFeatures.take(3).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          f.increasesRisk
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 16,
                          color: f.increasesRisk ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.featureDisplayName,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Recommended actions
            if (prediction.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommended Actions',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...prediction.recommendedActions.take(3).map((action) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      action.automatable ? Icons.auto_awesome : Icons.touch_app,
                      size: 20,
                    ),
                    title: Text(action.title),
                    subtitle: Text(
                      action.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: action.automatable
                        ? TextButton(
                            onPressed: () => onActionTap?.call(action),
                            child: const Text('Run'),
                          )
                        : null,
                    onTap: () => onActionTap?.call(action),
                  )),
            ],

            // Model info
            const SizedBox(height: 8),
            Text(
              'Model: ${prediction.modelVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
