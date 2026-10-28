import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/external_portal_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../crm/utils/web_links.dart';

class SalesSettingsPage extends ConsumerWidget {
  const SalesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final securityContext = ref.watch(securityContextProvider).valueOrNull;
    final crmConfigured = ExternalPortalConfig.hasCrmPortal;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileAsync.when(
              data: (profile) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? 'Sales user',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (profile?.email != null)
                      Text(
                        profile!.email!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (securityContext != null)
                      Text(
                        'Role: ${securityContext.role.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, _) => const SizedBox.shrink(),
            ),
            VSpace.md,
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.open_in_browser_outlined),
                  HSpace.md,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRM Web App',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          crmConfigured
                              ? 'Leads, deals, routes, and reporting stay in the CRM web app.'
                              : 'CRM web handoff is not configured for this build.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            VSpace.md,
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open CRM Web App'),
              onPressed: securityContext == null || !crmConfigured
                  ? null
                  : () => _openCrm(context, securityContext.businessId),
            ),
            VSpace.md,
            TextButton.icon(
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

  Future<void> _openCrm(BuildContext context, String businessId) async {
    final launched = await CrmWebLinks.openDashboard(businessId);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open CRM web app right now.')),
      );
    }
  }
}
