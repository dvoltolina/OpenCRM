import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/waitlist_entry.dart';
import '../../../../core/providers/providers.dart';
import '../../providers/front_desk_providers.dart';
import '../../services/front_desk_service.dart';
import '../dialogs/walk_in_booking_dialog.dart';

/// Waitlist panel for managing clients waiting for service.
///
/// Shows queue position, wait time, and "Seat Now" buttons.
class WaitlistPanel extends ConsumerWidget {
  const WaitlistPanel({super.key});

  String _getWaitTime(DateTime addedAt) {
    final now = DateTime.now();
    final difference = now.difference(addedAt);
    final minutes = difference.inMinutes;

    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  Future<void> _seatClient(
    BuildContext context,
    WidgetRef ref,
    WaitlistEntry entry,
  ) async {
    final providersAsync = ref.read(todayProvidersProvider).valueOrNull;
    if (providersAsync == null || providersAsync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No providers available')),
      );
      return;
    }

    // Show provider selection dialog
    final selectedProviderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: providersAsync.map((provider) {
            return ListTile(
              title: Text(provider.fullName),
              onTap: () => Navigator.pop(context, provider.id),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedProviderId == null || !context.mounted) return;

    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      final now = DateTime.now();
      // Default 30-minute appointment
      await service.seatFromWaitlist(
        securityContext,
        entry.id,
        selectedProviderId,
        now,
        30,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client seated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to seat client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromWaitlist(
    BuildContext context,
    WidgetRef ref,
    WaitlistEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Waitlist'),
        content: Text(
          'Remove ${entry.clientName} from the waitlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) return;

    final service = FrontDeskService(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      waitlistRepository: ref.read(waitlistRepositoryProvider),
    );

    try {
      await service.removeFromWaitlist(securityContext, entry.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from waitlist')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from waitlist')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlistAsync = ref.watch(waitlistProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Waitlist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const WalkInBookingDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Walk-In'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Waitlist
        Expanded(
          child: waitlistAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No clients waiting',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildWaitlistCard(context, ref, entry, index + 1);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text('Error loading waitlist'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitlistCard(
    BuildContext context,
    WidgetRef ref,
    WaitlistEntry entry,
    int position,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Position number
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '$position',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.serviceName ?? 'Service',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (entry.providerName != null)
                    Text(
                      'Prefers: ${entry.providerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Wait time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        _getWaitTime(entry.createdAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _removeFromWaitlist(context, ref, entry),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Remove'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _seatClient(context, ref, entry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Seat Now'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
