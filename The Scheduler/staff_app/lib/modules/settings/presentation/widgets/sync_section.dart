import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/sync_providers.dart';

/// Sync settings section showing sync status and controls.
class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncState = ref.watch(syncStateProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sync',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Status indicator
            _SyncStatusRow(syncState: syncState),
            const SizedBox(height: 16),

            // Last sync time
            _LastSyncRow(lastSyncTime: syncState.lastSyncTime),
            const SizedBox(height: 16),

            // Pending items
            if (syncState.hasPendingSync) ...[
              _PendingItemsRow(count: syncState.pendingCount),
              const SizedBox(height: 16),
            ],

            // Sync interval setting
            _SyncIntervalRow(),
            const SizedBox(height: 16),

            // Sync button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: syncState.isOnline && !syncState.isSyncing
                    ? () => _forceSync(ref)
                    : null,
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
              ),
            ),

            // Offline warning
            if (!syncState.isOnline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are offline. Changes will sync when connection is restored.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _forceSync(WidgetRef ref) async {
    final forceSync = ref.read(forceSyncProvider);
    await forceSync();
  }
}

class _SyncStatusRow extends StatelessWidget {
  const _SyncStatusRow({required this.syncState});

  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!syncState.isOnline) {
      statusColor = Colors.orange;
      statusIcon = Icons.cloud_off;
      statusText = 'Offline';
    } else if (syncState.isSyncing) {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.sync;
      statusText = 'Syncing...';
    } else if (syncState.hasError) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error_outline;
      statusText = 'Sync Error';
    } else if (syncState.hasPendingSync) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = '${syncState.pendingCount} Pending';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Up to Date';
    }

    return Row(
      children: [
        Icon(statusIcon, size: 20, color: statusColor),
        const SizedBox(width: 8),
        Text(
          'Status:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _LastSyncRow extends StatelessWidget {
  const _LastSyncRow({required this.lastSyncTime});

  final DateTime? lastSyncTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String timeText;
    if (lastSyncTime == null) {
      timeText = 'Never';
    } else {
      final now = DateTime.now();
      final diff = now.difference(lastSyncTime!);

      if (diff.inMinutes < 1) {
        timeText = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeText = '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        timeText = '${diff.inHours} hours ago';
      } else {
        final formatter = DateFormat.MMMd().add_jm();
        timeText = formatter.format(lastSyncTime!);
      }
    }

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Last sync:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          timeText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PendingItemsRow extends StatelessWidget {
  const _PendingItemsRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.cloud_upload,
          size: 20,
          color: Colors.orange.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          'Pending uploads:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SyncIntervalRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentInterval = ref.watch(syncIntervalProvider);

    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Auto-sync:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        PopupMenuButton<SyncInterval>(
          initialValue: currentInterval,
          onSelected: (interval) {
            ref.read(updateSyncIntervalProvider)(interval);
          },
          itemBuilder: (context) => SyncInterval.values.map((interval) {
            return PopupMenuItem<SyncInterval>(
              value: interval,
              child: Row(
                children: [
                  if (interval == currentInterval)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(interval.displayName),
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentInterval.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
