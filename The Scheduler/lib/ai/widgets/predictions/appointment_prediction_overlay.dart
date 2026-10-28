/// Overlay widget showing prediction indicators on calendar appointments.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/security_context.dart';
import '../../models/noshow_prediction.dart';
import '../../providers/prediction_providers.dart';
import 'prediction_widgets.dart';

/// Overlay that shows prediction indicator on an appointment widget.
///
/// Wraps any appointment widget and adds a prediction badge/indicator.
class AppointmentPredictionOverlay extends ConsumerWidget {
  const AppointmentPredictionOverlay({
    super.key,
    required this.securityContext,
    required this.appointment,
    required this.child,
    this.position = OverlayPosition.topRight,
    this.showOnlyHighRisk = false,
    this.onPredictionTap,
  });

  final SecurityContext securityContext;
  final Appointment appointment;
  final Widget child;
  final OverlayPosition position;
  final bool showOnlyHighRisk;
  final VoidCallback? onPredictionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(
      appointmentPredictionProvider((
        context: securityContext,
        appointment: appointment,
      )),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: position.isTop ? -4 : null,
          bottom: position.isTop ? null : -4,
          left: position.isLeft ? -4 : null,
          right: position.isLeft ? null : -4,
          child: predictionAsync.when(
            data: (prediction) {
              if (!prediction.isAvailable) return const SizedBox.shrink();
              if (showOnlyHighRisk && prediction.riskLevel == RiskLevel.low) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: onPredictionTap,
                child: _PredictionBadge(
                  prediction: prediction,
                  small: true,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Position for the prediction overlay.
enum OverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get isTop => this == topLeft || this == topRight;
  bool get isLeft => this == topLeft || this == bottomLeft;
}

/// Small prediction badge for calendar overlay.
class _PredictionBadge extends StatelessWidget {
  const _PredictionBadge({
    required this.prediction,
    this.small = false,
  });

  final NoshowPrediction prediction;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = Color(prediction.riskLevel.colorValue);
    final size = small ? 16.0 : 24.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${prediction.probabilityPercent}',
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 7 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Calendar cell with integrated prediction display.
class PredictionAwareCalendarCell extends ConsumerWidget {
  const PredictionAwareCalendarCell({
    super.key,
    required this.securityContext,
    required this.appointment,
    required this.onTap,
    this.isSelected = false,
    this.compact = false,
  });

  final SecurityContext securityContext;
  final Appointment appointment;
  final VoidCallback onTap;
  final bool isSelected;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final predictionAsync = ref.watch(
      appointmentPredictionProvider((
        context: securityContext,
        appointment: appointment,
      )),
    );

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.sm),
          child: Row(
            children: [
              // Time
              if (!compact) ...[
                Text(
                  _formatTime(appointment.startTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              // Client name
              Expanded(
                child: Text(
                  appointment.clientName ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Prediction indicator
              predictionAsync.when(
                data: (prediction) {
                  if (!prediction.isAvailable) {
                    return const SizedBox.shrink();
                  }
                  return RiskLevelChip(
                    riskLevel: prediction.riskLevel,
                    small: true,
                  );
                },
                loading: () => SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Batch prediction loader for calendar views.
///
/// Preloads predictions for multiple appointments efficiently.
class CalendarPredictionLoader extends ConsumerWidget {
  const CalendarPredictionLoader({
    super.key,
    required this.securityContext,
    required this.appointments,
    required this.builder,
  });

  final SecurityContext securityContext;
  final List<Appointment> appointments;
  final Widget Function(
    BuildContext context,
    Map<String, NoshowPrediction> predictions,
  ) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return builder(context, {});
    }

    final predictionsAsync = ref.watch(
      batchPredictionsProvider((
        context: securityContext,
        appointments: appointments,
      )),
    );

    return predictionsAsync.when(
      data: (predictions) => builder(context, predictions),
      loading: () => builder(context, {}),
      error: (_, __) => builder(context, {}),
    );
  }
}

/// Summary card showing high-risk appointments for the day.
class DailyRiskSummary extends ConsumerWidget {
  const DailyRiskSummary({
    super.key,
    required this.securityContext,
    required this.appointments,
    this.onAppointmentTap,
  });

  final SecurityContext securityContext;
  final List<Appointment> appointments;
  final void Function(Appointment)? onAppointmentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    final predictionsAsync = ref.watch(
      batchPredictionsProvider((
        context: securityContext,
        appointments: appointments,
      )),
    );

    return predictionsAsync.when(
      data: (predictions) {
        // Filter to high/medium risk only
        final riskyAppointments = appointments.where((apt) {
          final prediction = predictions[apt.id];
          return prediction != null &&
              prediction.isAvailable &&
              prediction.riskLevel.isConcerning;
        }).toList();

        if (riskyAppointments.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${riskyAppointments.length} At-Risk Appointment${riskyAppointments.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...riskyAppointments.take(3).map((apt) {
                  final prediction = predictions[apt.id]!;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: InkWell(
                      onTap: onAppointmentTap != null
                          ? () => onAppointmentTap!(apt)
                          : null,
                      child: Row(
                        children: [
                          Text(
                            '${prediction.probabilityPercent}%',
                            style: TextStyle(
                              color: Color(prediction.riskLevel.colorValue),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${apt.clientName ?? "Unknown"} at ${_formatTime(apt.startTime)}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (riskyAppointments.length > 3) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '+ ${riskyAppointments.length - 3} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
