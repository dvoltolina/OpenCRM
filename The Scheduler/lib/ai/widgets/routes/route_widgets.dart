/// Route visualization widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/optimized_route.dart';
import '../../models/route_stop.dart';

/// Card displaying a single route stop.
class RouteStopCard extends StatelessWidget {
  const RouteStopCard({
    super.key,
    required this.stop,
    this.isCurrentStop = false,
    this.isCompleted = false,
    this.showConnector = true,
    this.onTap,
    this.onComplete,
    this.onSkip,
  });

  final RouteStop stop;
  final bool isCurrentStop;
  final bool isCompleted;
  final bool showConnector;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            _TimelineNode(
              isCompleted: isCompleted,
              isCurrent: isCurrentStop,
              stopType: stop.stopType,
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 60,
                color: isCompleted
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),

        // Stop content
        Expanded(
          child: Card(
            color: isCurrentStop
                ? colorScheme.primaryContainer
                : isCompleted
                    ? colorScheme.surfaceContainerLow
                    : null,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stop.clientName != null)
                                Text(
                                  stop.clientName!,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              if (stop.serviceName != null)
                                Text(
                                  stop.serviceName!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        _StopStatusBadge(
                          isCompleted: isCompleted,
                          isLate: stop.isLate,
                          isCurrent: isCurrentStop,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Time and address
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatTimeWindow(stop),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            stop.address,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Actions for current stop
                    if (isCurrentStop && (onComplete != null || onSkip != null)) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onSkip != null)
                            TextButton(
                              onPressed: onSkip,
                              child: const Text('Skip'),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          if (onComplete != null)
                            FilledButton(
                              onPressed: onComplete,
                              child: const Text('Complete'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeWindow(RouteStop stop) {
    final start = _formatTime(stop.scheduledArrival);
    final end = _formatTime(stop.scheduledDeparture);
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.isCompleted,
    required this.isCurrent,
    required this.stopType,
  });

  final bool isCompleted;
  final bool isCurrent;
  final RouteStopType stopType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    if (isCompleted) {
      backgroundColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
      icon = Icons.check;
    } else if (isCurrent) {
      backgroundColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
      icon = _getStopIcon();
    } else {
      backgroundColor = colorScheme.surfaceContainerHigh;
      iconColor = colorScheme.onSurfaceVariant;
      icon = _getStopIcon();
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: colorScheme.primary, width: 3)
            : null,
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  IconData _getStopIcon() {
    return switch (stopType) {
      RouteStopType.depot || RouteStopType.endDepot => Icons.home_outlined,
      RouteStopType.appointment => Icons.event_outlined,
      RouteStopType.breakStop => Icons.coffee_outlined,
    };
  }
}

class _StopStatusBadge extends StatelessWidget {
  const _StopStatusBadge({
    required this.isCompleted,
    required this.isLate,
    required this.isCurrent,
  });

  final bool isCompleted;
  final bool isLate;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (isCompleted) {
      label = 'Done';
      color = AppColors.success;
    } else if (isLate) {
      label = 'Late';
      color = AppColors.error;
    } else if (isCurrent) {
      label = 'Next';
      color = Theme.of(context).colorScheme.primary;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Timeline view of route stops.
class RouteTimeline extends StatelessWidget {
  const RouteTimeline({
    super.key,
    required this.route,
    this.onStopTap,
    this.onStopComplete,
    this.onStopSkip,
  });

  final OptimizedRoute route;
  final void Function(RouteStop stop)? onStopTap;
  final void Function(RouteStop stop)? onStopComplete;
  final void Function(RouteStop stop)? onStopSkip;

  @override
  Widget build(BuildContext context) {
    final currentStop = route.currentStop;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: route.stops.length,
      itemBuilder: (context, index) {
        final stop = route.stops[index];
        final isCurrentStop = currentStop?.id == stop.id;
        final isLast = index == route.stops.length - 1;

        return RouteStopCard(
          stop: stop,
          isCurrentStop: isCurrentStop,
          isCompleted: stop.isCompleted,
          showConnector: !isLast,
          onTap: onStopTap != null ? () => onStopTap!(stop) : null,
          onComplete: isCurrentStop && onStopComplete != null
              ? () => onStopComplete!(stop)
              : null,
          onSkip: isCurrentStop && onStopSkip != null
              ? () => onStopSkip!(stop)
              : null,
        );
      },
    );
  }
}

/// Summary header for a route.
class RouteHeader extends StatelessWidget {
  const RouteHeader({
    super.key,
    required this.route,
    this.onStartRoute,
    this.onStopRoute,
  });

  final OptimizedRoute route;
  final VoidCallback? onStartRoute;
  final VoidCallback? onStopRoute;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.providerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _formatDate(route.routeDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _RouteStatusBadge(status: route.status),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Stats row
            Row(
              children: [
                _RouteStat(
                  icon: Icons.location_on_outlined,
                  value: '${route.appointmentCount}',
                  label: 'Stops',
                ),
                _RouteStat(
                  icon: Icons.straighten_outlined,
                  value: '${route.totalDistanceMiles.toStringAsFixed(1)} mi',
                  label: 'Distance',
                ),
                _RouteStat(
                  icon: Icons.schedule_outlined,
                  value: '${route.totalTravelTimeMinutes.round()} min',
                  label: 'Travel',
                ),
                if (route.hasSignificantSavings)
                  _RouteStat(
                    icon: Icons.savings_outlined,
                    value: route.formattedSavings,
                    label: 'Saved',
                    valueColor: AppColors.success,
                  ),
              ],
            ),

            // Progress bar
            if (route.status == RouteStatus.inProgress) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: LinearProgressIndicator(
                        value: route.progressPercent,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${route.completedStopsCount}/${route.appointmentCount}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ],

            // Action buttons
            if (onStartRoute != null || onStopRoute != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (route.status == RouteStatus.planned && onStartRoute != null)
                    FilledButton.icon(
                      onPressed: onStartRoute,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Route'),
                    ),
                  if (route.status == RouteStatus.inProgress && onStopRoute != null)
                    OutlinedButton.icon(
                      onPressed: onStopRoute,
                      icon: const Icon(Icons.stop),
                      label: const Text('End Route'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _RouteStatusBadge extends StatelessWidget {
  const _RouteStatusBadge({required this.status});

  final RouteStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      RouteStatus.planned => ('Planned', AppColors.info, Icons.schedule_outlined),
      RouteStatus.inProgress => ('In Progress', AppColors.success, Icons.directions_car),
      RouteStatus.completed => ('Completed', Theme.of(context).colorScheme.onSurfaceVariant, Icons.check_circle_outline),
      RouteStatus.cancelled => ('Cancelled', AppColors.error, Icons.cancel_outlined),
      RouteStatus.needsReoptimization => ('Needs Update', AppColors.warning, Icons.refresh),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
