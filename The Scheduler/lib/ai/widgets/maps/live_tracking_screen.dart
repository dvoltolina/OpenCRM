/// Live route tracking screen with real-time map updates.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../models/optimized_route.dart';
import '../../models/route_stop.dart';
import '../../providers/route_providers.dart';
import '../../services/gps_location_service.dart';
import '../../services/route_tracking_service.dart';
import '../../utils/maps_launcher.dart';
import 'route_map_widget.dart';

/// Full-screen live tracking view for an active route.
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.securityContext,
    required this.route,
  });

  final SecurityContext securityContext;
  final OptimizedRoute route;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final GlobalKey<RouteMapWidgetState> _mapKey = GlobalKey();
  RouteStop? _selectedStop;
  bool _showStopInfo = false;
  bool _gpsStarted = false;
  StreamSubscription<CurrentLocation>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    // Start GPS tracking after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGpsTracking();
    });
  }

  @override
  void dispose() {
    _stopGpsTracking();
    super.dispose();
  }

  Future<void> _startGpsTracking() async {
    final gpsService = ref.read(gpsLocationServiceProvider);

    // Check/request permission
    final status = await gpsService.requestPermission();
    if (status != LocationPermissionStatus.granted) {
      if (mounted) {
        _showPermissionDialog(status);
      }
      return;
    }

    // Start tracking
    final started = await gpsService.startTracking();
    if (!started) {
      debugPrint('LiveTrackingScreen: Failed to start GPS tracking');
      return;
    }

    setState(() => _gpsStarted = true);

    // Listen to location updates and forward to route tracking
    _locationSubscription = gpsService.locationStream.listen((location) {
      // Update route tracking service
      ref.read(activeRouteProvider.notifier).updateLocation(
            widget.securityContext,
            location,
          );
    });

    debugPrint('LiveTrackingScreen: GPS tracking started');
  }

  void _stopGpsTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    final gpsService = ref.read(gpsLocationServiceProvider);
    gpsService.stopTracking();

    debugPrint('LiveTrackingScreen: GPS tracking stopped');
  }

  void _showPermissionDialog(LocationPermissionStatus status) {
    final message = switch (status) {
      LocationPermissionStatus.denied =>
        'Location permission is required to track your route. Please grant permission.',
      LocationPermissionStatus.deniedForever =>
        'Location permission was permanently denied. Please enable it in Settings.',
      LocationPermissionStatus.serviceDisabled =>
        'Location services are disabled. Please enable GPS.',
      LocationPermissionStatus.granted => '',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final gpsService = ref.read(gpsLocationServiceProvider);
              if (status == LocationPermissionStatus.deniedForever) {
                await gpsService.openAppSettings();
              } else if (status == LocationPermissionStatus.serviceDisabled) {
                await gpsService.openLocationSettings();
              } else {
                _startGpsTracking();
              }
            },
            child: Text(
              status == LocationPermissionStatus.serviceDisabled
                  ? 'Open Settings'
                  : status == LocationPermissionStatus.deniedForever
                      ? 'Open App Settings'
                      : 'Try Again',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = ref.watch(activeRouteProvider);
    final currentRoute = activeRoute.route ?? widget.route;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: const [AppShadows.card],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          // GPS status indicator
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: const [AppShadows.card],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _gpsStarted ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: _gpsStarted ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  _gpsStarted ? 'GPS' : 'No GPS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _gpsStarted ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          // Recenter button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: const [AppShadows.card],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Center on location',
              onPressed: () {
                final mapState = _mapKey.currentState;
                if (mapState != null && activeRoute.lastLocation != null) {
                  mapState.focusOnCurrentLocation();
                }
              },
            ),
          ),
          // Fit all stops button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: const [AppShadows.card],
            ),
            child: IconButton(
              icon: const Icon(Icons.fit_screen),
              tooltip: 'Fit all stops',
              onPressed: () {
                final mapState = _mapKey.currentState;
                mapState?.fitAllStops();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          RouteMapWidget(
            key: _mapKey,
            route: currentRoute,
            currentLocation: activeRoute.lastLocation,
            selectedStopId: _selectedStop?.id,
            onStopTap: _onStopTapped,
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomInfoPanel(
              route: currentRoute,
              activeRouteState: activeRoute,
              selectedStop: _selectedStop,
              showStopInfo: _showStopInfo,
              onDismissStopInfo: () {
                setState(() {
                  _showStopInfo = false;
                  _selectedStop = null;
                });
              },
              onNavigateToStop: _navigateToStop,
              onCompleteStop: _completeCurrentStop,
              onSkipStop: _skipCurrentStop,
              securityContext: widget.securityContext,
            ),
          ),
        ],
      ),
    );
  }

  void _onStopTapped(RouteStop stop) {
    setState(() {
      if (_selectedStop?.id == stop.id) {
        // Toggle off if same stop
        _showStopInfo = !_showStopInfo;
      } else {
        _selectedStop = stop;
        _showStopInfo = true;
      }
    });
  }

  Future<void> _navigateToStop(RouteStop stop) async {
    try {
      await openInMaps(
        latitude: stop.latitude,
        longitude: stop.longitude,
        addressLabel: stop.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  Future<void> _completeCurrentStop() async {
    await ref.read(activeRouteProvider.notifier).completeCurrentStop(
          widget.securityContext,
        );
    setState(() {
      _showStopInfo = false;
      _selectedStop = null;
    });
  }

  Future<void> _skipCurrentStop() async {
    await ref.read(activeRouteProvider.notifier).skipCurrentStop(
          widget.securityContext,
          reason: 'Skipped by provider',
        );
    setState(() {
      _showStopInfo = false;
      _selectedStop = null;
    });
  }
}

/// Bottom panel showing current stop info and ETA.
class _BottomInfoPanel extends StatelessWidget {
  const _BottomInfoPanel({
    required this.route,
    required this.activeRouteState,
    required this.selectedStop,
    required this.showStopInfo,
    required this.onDismissStopInfo,
    required this.onNavigateToStop,
    required this.onCompleteStop,
    required this.onSkipStop,
    required this.securityContext,
  });

  final OptimizedRoute route;
  final ActiveRouteState activeRouteState;
  final RouteStop? selectedStop;
  final bool showStopInfo;
  final VoidCallback onDismissStopInfo;
  final Future<void> Function(RouteStop) onNavigateToStop;
  final VoidCallback onCompleteStop;
  final VoidCallback onSkipStop;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show selected stop info or current stop info
    final stopToShow = selectedStop ?? activeRouteState.currentStop;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
        boxShadow: const [AppShadows.modal],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _RouteProgressBar(
                completedStops: route.completedStopsCount,
                totalStops: route.appointmentCount,
                progress: route.progressPercent,
              ),
            ),

            // Current/selected stop info
            if (stopToShow != null) ...[
              const Divider(height: 1),
              _StopInfoCard(
                stop: stopToShow,
                isCurrentStop: stopToShow.id == activeRouteState.currentStop?.id,
                eta: activeRouteState.currentEta,
                onNavigate: () => onNavigateToStop(stopToShow),
                onComplete: stopToShow.id == activeRouteState.currentStop?.id
                    ? onCompleteStop
                    : null,
                onSkip: stopToShow.id == activeRouteState.currentStop?.id
                    ? onSkipStop
                    : null,
              ),
            ],

            // Route summary
            const Divider(height: 1),
            _RouteSummary(route: route),
          ],
        ),
      ),
    );
  }
}

/// Progress bar showing completed/total stops.
class _RouteProgressBar extends StatelessWidget {
  const _RouteProgressBar({
    required this.completedStops,
    required this.totalStops,
    required this.progress,
  });

  final int completedStops;
  final int totalStops;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route Progress',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '$completedStops of $totalStops stops',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card showing current stop details.
class _StopInfoCard extends StatelessWidget {
  const _StopInfoCard({
    required this.stop,
    required this.isCurrentStop,
    this.eta,
    this.onNavigate,
    this.onComplete,
    this.onSkip,
  });

  final RouteStop stop;
  final bool isCurrentStop;
  final EtaUpdate? eta;
  final VoidCallback? onNavigate;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Row(
            children: [
              if (isCurrentStop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'NEXT STOP',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              Expanded(
                child: Text(
                  stop.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Service and time
          if (stop.serviceName != null)
            Text(
              stop.serviceName!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),

          const SizedBox(height: AppSpacing.xs),

          // Address
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
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

          // ETA
          if (eta != null && isCurrentStop) ...[
            const SizedBox(height: AppSpacing.sm),
            _EtaDisplay(eta: eta!),
          ],

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
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
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
          if (!stop.isCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Navigate button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Navigate'),
                  ),
                ),

                if (isCurrentStop) ...[
                  const SizedBox(width: AppSpacing.sm),

                  // Skip button
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      child: const Text('Skip'),
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Complete button
                  if (onComplete != null)
                    FilledButton(
                      onPressed: onComplete,
                      child: const Text('Complete'),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Display ETA with late indicator.
class _EtaDisplay extends StatelessWidget {
  const _EtaDisplay({required this.eta});

  final EtaUpdate eta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: eta.isLate
                ? AppColors.error.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: eta.isLate ? AppColors.error : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'ETA ${_formatTime(eta.estimatedArrival)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: eta.isLate ? AppColors.error : null,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatDuration(eta.durationSeconds),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(${_formatDistance(eta.distanceMeters)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        if (eta.isLate && eta.minutesLate != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${eta.minutesLate} min late',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '${meters}m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)}km';
  }
}

/// Route summary stats.
class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route});

  final OptimizedRoute route;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.straighten_outlined,
            label: 'Distance',
            value: '${route.totalDistanceMiles.toStringAsFixed(1)} mi',
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant,
          ),
          _SummaryItem(
            icon: Icons.schedule_outlined,
            label: 'Travel time',
            value: '${route.totalTravelTimeMinutes.round()} min',
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant,
          ),
          _SummaryItem(
            icon: Icons.flag_outlined,
            label: 'Finish',
            value: _formatTime(route.expectedEndTime),
          ),
        ],
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

