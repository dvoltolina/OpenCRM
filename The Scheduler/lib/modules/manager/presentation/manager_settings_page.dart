import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../time_clock/widgets/time_clock_widget.dart';

class ManagerSettingsPage extends ConsumerWidget {
  const ManagerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final securityContext = ref.watch(securityContextProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: ListView(
          children: [
            profileAsync.when(
              data: (profile) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(profile?.displayName ?? 'Manager'),
                  subtitle: Text(profile?.email ?? ''),
                  trailing: Text(profile?.role.name ?? 'manager'),
                ),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Clock',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (securityContext != null)
                      TimeClockWidget(
                        securityContext: securityContext,
                        compact: true,
                      )
                    else
                      const Text('Sign in to access time clock'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () => _signOut(ref, context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authStateServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
