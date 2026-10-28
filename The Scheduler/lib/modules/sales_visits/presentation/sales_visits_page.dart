import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../ai/models/route_stop.dart';
import '../../../ai/providers/route_providers.dart';
import '../../../ai/utils/maps_launcher.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/security_context.dart';

/// Lightweight sales visits view with map handoff.
class SalesVisitsPage extends ConsumerWidget {
  const SalesVisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContext = ref.watch(currentSecurityContextProvider);
    final branding = ref.watch(appConfigProvider).branding;

    if (securityContext == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (securityContext.role == UserRole.client) {
      return _buildGuardedState(
        context,
        branding: branding,
        message: 'Sales visits are only available to staff/admin roles.',
        icon: Icons.lock_outline,
      );
    }

    final providerId = securityContext.providerId;
    if (providerId == null) {
      return _buildGuardedState(
        context,
        branding: branding,
        message:
            'Add a providerId to this user in CRM/Admin to see assigned visits.',
        icon: Icons.badge_outlined,
      );
    }

    final today = DateTime.now();
    final routeAsync = ref.watch(
      providerRouteStreamProvider((
        context: securityContext,
        providerId: providerId,
        date: today,
      )),
    );

    return Scaffold(
      backgroundColor: branding.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: routeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _buildGuardedState(
            context,
            branding: branding,
            message: SecureErrorHandler.loadingFailed,
            icon: Icons.error_outline,
          ),
          data: (route) {
            if (route == null) {
              return _buildGuardedState(
                context,
                branding: branding,
                message:
                    'No route scheduled for today. Ask CRM/Admin to assign visits.',
                icon: Icons.route_outlined,
              );
            }

            final stops =
                route.stops
                    .where((s) => s.stopType == RouteStopType.appointment)
                    .toList()
                  ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

            if (stops.isEmpty) {
              return _buildGuardedState(
                context,
                branding: branding,
                message: 'No visits on this route.',
                icon: Icons.check_circle_outline,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today’s Visits',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: stops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      return _VisitCard(
                        stop: stop,
                        onOpenMaps: () => _openStopInMaps(context, stop),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuardedState(
    BuildContext context, {
    required AppBranding branding,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: branding.primaryColor),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStopInMaps(BuildContext context, RouteStop stop) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await openInMaps(
        latitude: stop.latitude,
        longitude: stop.longitude,
        addressLabel: stop.name,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not launch maps: $e')),
      );
    }
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.stop, required this.onOpenMaps});

  final RouteStop stop;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final window = _formatWindow(stop);
    final status = _formatStatus(stop.status);

    return SemanticWrapper(
      label: 'Visit ${stop.sequenceOrder + 1} for ${stop.name}',
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      '${stop.sequenceOrder + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          window,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(status.label),
                    backgroundColor: status.color.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stop.address,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Maps'),
                    onPressed: onOpenMaps,
                  ),
                  const Spacer(),
                  if (stop.arrivalNotes != null &&
                      stop.arrivalNotes!.trim().isNotEmpty)
                    Tooltip(
                      message: stop.arrivalNotes!,
                      child: const Icon(Icons.info_outline, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusChip _formatStatus(RouteStopStatus status) {
    switch (status) {
      case RouteStopStatus.pending:
        return const _StatusChip('Pending', Colors.blueGrey);
      case RouteStopStatus.enRoute:
        return const _StatusChip('En route', Colors.blue);
      case RouteStopStatus.arrived:
        return const _StatusChip('Arrived', Colors.teal);
      case RouteStopStatus.inProgress:
        return const _StatusChip('In progress', Colors.orange);
      case RouteStopStatus.completed:
        return const _StatusChip('Done', Colors.green);
      case RouteStopStatus.skipped:
        return const _StatusChip('Skipped', Colors.grey);
      case RouteStopStatus.clientNoShow:
        return const _StatusChip('No-show', Colors.redAccent);
    }
  }

  String _formatWindow(RouteStop stop) {
    final formatter = DateFormat('h:mm a');
    return '${formatter.format(stop.windowStart)} - ${formatter.format(stop.windowEnd)}';
  }
}

class _StatusChip {
  const _StatusChip(this.label, this.color);

  final String label;
  final Color color;
}
