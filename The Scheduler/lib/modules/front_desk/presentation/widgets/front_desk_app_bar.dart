import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/portal_selection_page.dart';
import '../../providers/front_desk_providers.dart';

/// App bar for front desk view showing location, time, and quick actions.
class FrontDeskAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const FrontDeskAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Sign out handled by auth providers
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortalSelectionPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTime = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
    final timeFormat = DateFormat.jm(); // e.g., "10:45 AM"
    const businessName = 'Front Desk';

    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.desk, size: 20),
          const SizedBox(width: 8),
          Text(businessName),
          const Spacer(),
          // Current time display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(currentTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // User menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          onSelected: (value) {
            if (value == 'signout') {
              _signOut(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
