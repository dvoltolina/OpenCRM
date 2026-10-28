/// Routes tab showing route optimization and tracking.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/security_context.dart';
import '../../models/optimized_route.dart';
import '../../providers/route_providers.dart';
import '../maps/live_tracking_screen.dart';
import '../maps/route_map_widget.dart';
import 'route_widgets.dart';

/// Tab showing route optimization overview.
class RoutesTab extends ConsumerStatefulWidget {
  const RoutesTab({
    super.key,
    required this.securityContext,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends ConsumerState<RoutesTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final routeAvailable = ref.watch(routeOptimizationAvailableProvider);

    return routeAvailable.when(
      data: (available) {
        if (!available) {
          return _buildUnavailableState(context);
        }
        return _buildContent(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableState(context),
    );
  }

  Widget _buildUnavailableState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Route Optimization Unavailable',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The route optimization service is temporarily unavailable.\nPlease try again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => ref.invalidate(routeOptimizationAvailableProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final activeRoute = ref.watch(activeRouteProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(routeOptimizationAvailableProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Date selector
          SliverToBoxAdapter(
            child: _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
              },
            ),
          ),

          // Active route tracking
          if (activeRoute.route != null && activeRoute.isTracking)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _ActiveRouteCard(
                  route: activeRoute.route!,
                  currentStop: activeRoute.currentStop,
                  eta: activeRoute.currentEta?.estimatedArrival,
                  onViewDetails: () => _showRouteDetails(activeRoute.route!),
                ),
              ),
            ),

          // Routes list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    'Routes for ${_formatDate(_selectedDate)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create New Route',
                    onPressed: _createNewRoute,
                  ),
                ],
              ),
            ),
          ),

          _RoutesList(
            securityContext: widget.securityContext,
            date: _selectedDate,
            onRouteTap: _showRouteDetails,
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xxl)),
        ],
      ),
    );
  }

  void _showRouteDetails(OptimizedRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _RouteDetailsSheet(
            route: route,
            scrollController: scrollController,
            securityContext: widget.securityContext,
          );
        },
      ),
    );
  }

  void _createNewRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route optimization coming soon'),
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
    return '${date.month}/${date.day}';
  }
}

/// Date selector for route view.
class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              onTap: () => onDateChanged(date),
            ),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdays[date.weekday - 1],
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Active route tracking card.
class _ActiveRouteCard extends StatelessWidget {
  const _ActiveRouteCard({
    required this.route,
    required this.currentStop,
    required this.eta,
    required this.onViewDetails,
  });

  final OptimizedRoute route;
  final dynamic currentStop;
  final DateTime? eta;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.navigation,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Active Route',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${route.completedStopsCount}/${route.appointmentCount} stops',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
              if (currentStop != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Next: ${currentStop.clientName ?? "Stop"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                if (eta != null)
                  Text(
                    'ETA: ${_formatTime(eta!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: route.progressPercent,
                  minHeight: 6,
                  backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
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

/// List of routes for a given date.
class _RoutesList extends ConsumerWidget {
  const _RoutesList({
    required this.securityContext,
    required this.date,
    required this.onRouteTap,
  });

  final SecurityContext securityContext;
  final DateTime date;
  final void Function(OptimizedRoute) onRouteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would fetch routes from repository
    // For demo, show empty state
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.route_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No routes scheduled',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create a new route to get started',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Route details bottom sheet.
class _RouteDetailsSheet extends ConsumerWidget {
  const _RouteDetailsSheet({
    required this.route,
    required this.scrollController,
    required this.securityContext,
  });

  final OptimizedRoute route;
  final ScrollController scrollController;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: RouteHeader(
            route: route,
            onStartRoute: route.status == RouteStatus.planned
                ? () => _startRoute(context, ref)
                : null,
            onStopRoute: route.status == RouteStatus.inProgress
                ? () => _stopRoute(context, ref)
                : null,
          ),
        ),

        // Map Preview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _MapPreviewCard(
            route: route,
            onViewMap: () => _openMapView(context),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Timeline
        Expanded(
          child: RouteTimeline(
            route: route,
            onStopComplete: (stop) => _completeStop(context, ref, stop),
            onStopSkip: (stop) => _skipStop(context, ref, stop),
          ),
        ),
      ],
    );
  }

  void _openMapView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(
          securityContext: securityContext,
          route: route,
        ),
      ),
    );
  }

  Future<void> _startRoute(BuildContext context, WidgetRef ref) async {
    await ref.read(activeRouteProvider.notifier).startTracking(
          securityContext,
          route,
        );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _stopRoute(BuildContext context, WidgetRef ref) async {
    await ref.read(activeRouteProvider.notifier).completeRoute(securityContext);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _completeStop(BuildContext context, WidgetRef ref, dynamic stop) async {
    await ref.read(activeRouteProvider.notifier).completeCurrentStop(securityContext);
  }

  Future<void> _skipStop(BuildContext context, WidgetRef ref, dynamic stop) async {
    await ref.read(activeRouteProvider.notifier).skipCurrentStop(
          securityContext,
          reason: 'User skipped',
        );
  }
}

/// Card showing map preview with "View Map" button.
class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.route,
    required this.onViewMap,
  });

  final OptimizedRoute route;
  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map preview
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RouteMapPreview(route: route),
                // Gradient overlay at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                // View map button
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: FilledButton.icon(
                    onPressed: onViewMap,
                    icon: const Icon(Icons.fullscreen, size: 18),
                    label: const Text('View Map'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
