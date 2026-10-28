/// Custom map markers for route visualization.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../models/route_stop.dart';
import 'map_config.dart';

/// Marker widget for a route stop.
class StopMarker extends StatelessWidget {
  const StopMarker({
    super.key,
    required this.stop,
    this.isCurrent = false,
    this.isSelected = false,
  });

  final RouteStop stop;
  final bool isCurrent;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final size = isCurrent
        ? MapMarkerSizes.currentStopMarker
        : MapMarkerSizes.stopMarker;

    // Get color based on stop status
    Color markerColor = _getMarkerColor();
    IconData icon = _getMarkerIcon();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection ring
          if (isSelected)
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
            ),

          // Pulse animation for current stop
          if (isCurrent) _PulseAnimation(color: markerColor, size: size),

          // Main marker
          Container(
            width: size - 4,
            height: size - 4,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: markerColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: (size - 4) * 0.5,
            ),
          ),

          // Sequence number badge
          if (stop.stopType == RouteStopType.appointment && !stop.isCompleted)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: markerColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${stop.sequenceOrder + 1}',
                    style: TextStyle(
                      color: markerColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMarkerColor() {
    if (stop.isCompleted) {
      return stop.status == RouteStopStatus.clientNoShow
          ? MapColors.stopNoShow
          : stop.status == RouteStopStatus.skipped
              ? MapColors.stopSkipped
              : MapColors.stopCompleted;
    }

    if (isCurrent) {
      return MapColors.stopCurrent;
    }

    if (stop.stopType == RouteStopType.depot ||
        stop.stopType == RouteStopType.endDepot) {
      return MapColors.depot;
    }

    return MapColors.stopPending;
  }

  IconData _getMarkerIcon() {
    if (stop.isCompleted) {
      return stop.status == RouteStopStatus.clientNoShow
          ? Icons.person_off_outlined
          : stop.status == RouteStopStatus.skipped
              ? Icons.skip_next_outlined
              : Icons.check;
    }

    return switch (stop.stopType) {
      RouteStopType.depot || RouteStopType.endDepot => Icons.home_outlined,
      RouteStopType.appointment => Icons.event_outlined,
      RouteStopType.breakStop => Icons.coffee_outlined,
    };
  }
}

/// Animated pulse effect for current location/stop.
class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: _opacityAnimation.value),
            ),
          ),
        );
      },
    );
  }
}

/// Current location marker with heading indicator.
class CurrentLocationMarker extends StatefulWidget {
  const CurrentLocationMarker({
    super.key,
    this.heading,
  });

  /// Heading in degrees (0-360, null if unknown).
  final double? heading;

  @override
  State<CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<CurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.5);
            final opacity = 1.0 - _pulseController.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: MapMarkerSizes.locationPulseRadius,
                height: MapMarkerSizes.locationPulseRadius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MapColors.currentLocationPulse.withValues(alpha: opacity),
                ),
              ),
            );
          },
        ),

        // Inner accuracy circle
        Container(
          width: MapMarkerSizes.locationPulseRadius * 0.7,
          height: MapMarkerSizes.locationPulseRadius * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MapColors.currentLocation.withValues(alpha: 0.15),
          ),
        ),

        // Heading indicator (if available)
        if (widget.heading != null)
          Transform.rotate(
            angle: (widget.heading! * math.pi / 180),
            child: CustomPaint(
              size: Size(
                MapMarkerSizes.currentLocation * 2,
                MapMarkerSizes.currentLocation * 2,
              ),
              painter: _HeadingPainter(
                color: MapColors.currentLocation,
              ),
            ),
          ),

        // Center dot
        Container(
          width: MapMarkerSizes.currentLocation,
          height: MapMarkerSizes.currentLocation,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MapColors.currentLocation,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: MapColors.currentLocation.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints heading direction indicator.
class _HeadingPainter extends CustomPainter {
  _HeadingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a small triangle pointing up (heading direction)
    final path = Path()
      ..moveTo(center.dx, center.dy - radius + 4)
      ..lineTo(center.dx - 6, center.dy - radius + 16)
      ..lineTo(center.dx + 6, center.dy - radius + 16)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Info popup widget for stop markers.
class StopInfoPopup extends StatelessWidget {
  const StopInfoPopup({
    super.key,
    required this.stop,
    this.onNavigate,
    this.onComplete,
    this.onSkip,
  });

  final RouteStop stop;
  final VoidCallback? onNavigate;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 8,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _StopTypeIcon(stopType: stop.stopType),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.serviceName != null)
                        Text(
                          stop.serviceName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: AppSpacing.lg),

            // Details
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _formatTimeWindow(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Arrival notes
            if (stop.arrivalNotes != null && stop.arrivalNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        stop.arrivalNotes!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (!stop.isCompleted && (onNavigate != null || onComplete != null)) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onNavigate != null)
                    TextButton.icon(
                      onPressed: onNavigate,
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Navigate'),
                    ),
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      child: const Text('Skip'),
                    ),
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
    );
  }

  String _formatTimeWindow() {
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

class _StopTypeIcon extends StatelessWidget {
  const _StopTypeIcon({required this.stopType});

  final RouteStopType stopType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (stopType) {
      RouteStopType.depot || RouteStopType.endDepot => (
          Icons.home_outlined,
          MapColors.depot
        ),
      RouteStopType.appointment => (
          Icons.event_outlined,
          colorScheme.primary
        ),
      RouteStopType.breakStop => (
          Icons.coffee_outlined,
          AppColors.warning
        ),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
