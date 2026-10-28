import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/service_providers.dart';

/// Banner widget displayed when device is offline.
///
/// Shows at the top of the screen with:
/// - Warning icon
/// - Offline message
/// - Pending writes count (if any)
/// - Dismiss action
///
/// Automatically shows/hides based on connectivity state.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final queueSizeAsync = ref.watch(offlineQueueSizeProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        // Reset dismissed flag when coming back online
        if (isOnline && _dismissed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _dismissed = false);
            }
          });
        }

        // Don't show if online or dismissed
        if (isOnline || _dismissed) {
          return const SizedBox.shrink();
        }

        // Get queue size for display
        final queueSize = queueSizeAsync.valueOrNull ?? 0;

        return MaterialBanner(
          backgroundColor: Colors.orange.shade100,
          leading: Icon(
            Icons.cloud_off,
            color: Colors.orange.shade900,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are offline',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                queueSize > 0
                    ? '$queueSize pending change${queueSize == 1 ? '' : 's'} will sync when online'
                    : 'Some features may be limited',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _dismissed = true);
              },
              child: Text(
                'DISMISS',
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Simpler offline indicator icon for use in app bars.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();

        return Tooltip(
          message: 'Offline',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.cloud_off,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
