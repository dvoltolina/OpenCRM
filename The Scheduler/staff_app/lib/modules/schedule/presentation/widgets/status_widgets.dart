import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sync_providers.dart';

/// Widget showing current sync status in the app bar.
///
/// Displays:
/// - Green check when synced and online
/// - Orange spinner when syncing
/// - Red warning when error
/// - Gray cloud-off when offline
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return Tooltip(
      message: _getTooltipMessage(syncState),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _buildIcon(context, syncState),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, SyncState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!state.isOnline) {
      return Icon(
        Icons.cloud_off,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      );
    }

    if (state.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.orange,
        ),
      );
    }

    if (state.hasError) {
      return const Icon(
        Icons.sync_problem,
        color: Colors.red,
        size: 20,
      );
    }

    if (state.hasPendingSync) {
      return Badge(
        label: Text('${state.pendingCount}'),
        child: const Icon(
          Icons.sync,
          color: Colors.orange,
          size: 20,
        ),
      );
    }

    return const Icon(
      Icons.cloud_done,
      color: Colors.green,
      size: 20,
    );
  }

  String _getTooltipMessage(SyncState state) {
    if (!state.isOnline) return 'Offline - changes will sync when connected';
    if (state.isSyncing) return 'Syncing...';
    if (state.hasError) return 'Sync error - tap to retry';
    if (state.hasPendingSync) return '${state.pendingCount} changes pending';
    if (state.lastSyncTime != null) {
      return 'Last synced ${_formatRelativeTime(state.lastSyncTime!)}';
    }
    return 'Synced';
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Widget showing tappable sync status that triggers sync on tap.
class TappableSyncIndicator extends ConsumerWidget {
  const TappableSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const SyncStatusIndicator(),
      onPressed: () async {
        final forceSync = ref.read(forceSyncProvider);
        await forceSync();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync started'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      tooltip: 'Sync',
    );
  }
}

/// Badge showing appointment status.
///
/// Colors:
/// - pending: orange
/// - confirmed: blue
/// - completed: green
/// - cancelled: red
/// - noShow: gray
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getStatusInfo(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(small ? 4 : 6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: small ? 10 : null,
            ),
      ),
    );
  }

  (String, Color) _getStatusInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status.toLowerCase()) {
      case 'completed':
        return ('Completed', Colors.green);
      case 'cancelled':
        return ('Cancelled', Colors.red);
      case 'noshow':
      case 'no_show':
        return ('No Show', Colors.grey);
      case 'confirmed':
        return ('Confirmed', colorScheme.primary);
      case 'checkedin':
      case 'checked_in':
        return ('Checked In', colorScheme.tertiary);
      case 'pending':
      default:
        return ('Pending', Colors.orange);
    }
  }
}

/// Banner shown when device is offline.
///
/// Displays warning and information about offline mode.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pendingCount > 0
                    ? 'Offline - $pendingCount changes will sync when connected'
                    : 'Offline - changes will sync when connected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dismissible offline banner with additional actions.
class DismissibleOfflineBanner extends ConsumerStatefulWidget {
  const DismissibleOfflineBanner({super.key});

  @override
  ConsumerState<DismissibleOfflineBanner> createState() =>
      _DismissibleOfflineBannerState();
}

class _DismissibleOfflineBannerState
    extends ConsumerState<DismissibleOfflineBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    // Reset dismissed state when coming back online
    if (isOnline && _dismissed) {
      _dismissed = false;
    }

    if (isOnline || _dismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You are offline. Changes will sync when connected.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.onErrorContainer,
              ),
              onPressed: () => setState(() => _dismissed = true),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sync error banner with retry action.
class SyncErrorBanner extends ConsumerWidget {
  const SyncErrorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    if (!syncState.hasError || !syncState.isOnline) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.sync_problem,
              size: 18,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                syncState.error ?? 'Sync error occurred',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final forceSync = ref.read(forceSyncProvider);
                await forceSync();
              },
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
