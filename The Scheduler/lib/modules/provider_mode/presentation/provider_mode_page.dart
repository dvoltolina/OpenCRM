import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/constants/user_messages.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/user_role.dart';
import 'my_schedule_page.dart';
import 'my_clients_page.dart';
import 'my_tasks_page.dart';
import 'my_payments_page.dart';
import 'scan_docs_page.dart';
import 'quick_notes_page.dart';

/// Provider Mode landing page - role-gated access for staff.
///
/// This is the main entry point for Provider Mode, which consolidates
/// provider-facing features from the standalone staff app into the main app.
/// Access is gated by role (owner/admin/staff) and feature flag.
///
/// Surfaces available:
/// - My Schedule: Day/week agenda with appointment actions
/// - My Clients: Provider-scoped client list
/// - My Tasks: Lightweight task list
/// - My Payments: Provider-facing payment ledger
/// - Scan Docs: Upload files to client records
/// - Quick Notes: Provider-only encrypted notes
class ProviderModePage extends ConsumerWidget {
  const ProviderModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      data: (securityContext) {
        if (securityContext == null) {
          return const _NotAuthenticatedView();
        }

        // Role check: only owner/admin/staff can access Provider Mode
        if (!_hasProviderAccess(securityContext.role)) {
          return const _AccessDeniedView();
        }

        return _ProviderModeHomeView(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          providerId: securityContext.providerId,
          role: securityContext.role,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text(UserMessages.loadError)),
    );
  }

  bool _hasProviderAccess(UserRole role) {
    // Provider Mode is the live provider/staff experience.
    return role == UserRole.owner ||
        role == UserRole.admin ||
        role == UserRole.provider ||
        role == UserRole.staff;
  }
}

class _NotAuthenticatedView extends StatelessWidget {
  const _NotAuthenticatedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
          VSpace.md,
          Text('Authentication Required', style: theme.textTheme.titleLarge),
          VSpace.xs,
          Text(
            'Please sign in to access Provider Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_accounts_outlined,
            size: 64,
            color: theme.colorScheme.error,
          ),
          VSpace.md,
          Text('Access Denied', style: theme.textTheme.titleLarge),
          VSpace.xs,
          Text(
            'Provider Mode is only available to providers and staff',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          VSpace.xxs,
          Text(
            'Contact your administrator for access',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderModeHomeView extends StatelessWidget {
  const _ProviderModeHomeView({
    required this.businessId,
    required this.userId,
    required this.providerId,
    required this.role,
  });

  final String businessId;
  final String userId;
  final String? providerId;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Provider Dashboard'),
          automaticallyImplyLeading: false,
        ),
        SliverPadding(
          padding: AppSpacing.pagePadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          HSpace.md,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to Provider Mode',
                                  style: theme.textTheme.titleMedium,
                                ),
                                VSpace.xxs,
                                Text(
                                  'Manage your schedule, clients, and tasks',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      VSpace.md,
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(role.name.toUpperCase()),
                            avatar: const Icon(Icons.badge, size: 16),
                          ),
                          if (providerId != null)
                            Chip(
                              label: const Text('Provider'),
                              avatar: const Icon(Icons.person, size: 16),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                VSpace.lg,

                // Quick actions grid
                Text('Quick Actions', style: theme.textTheme.titleMedium),
                VSpace.sm,
                _QuickActionsGrid(
                  businessId: businessId,
                  providerId: providerId,
                ),

                VSpace.lg,

                // Info card
                AppCard(
                  color: theme.colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      HSpace.md,
                      Expanded(
                        child: Text(
                          'Provider Mode includes all the tools you need: schedule management, '
                          'client records, tasks, payment ledger, document uploads, and quick notes.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.businessId, required this.providerId});

  final String businessId;
  final String? providerId;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_today,
        label: 'My Schedule',
        description: 'View appointments',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MySchedulePage()),
        ),
      ),
      _QuickAction(
        icon: Icons.people_outline,
        label: 'My Clients',
        description: 'Client list',
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyClientsPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.checklist_outlined,
        label: 'My Tasks',
        description: 'Task list',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyTasksPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.payment_outlined,
        label: 'My Payments',
        description: 'Payment ledger',
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPaymentsPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.document_scanner_outlined,
        label: 'Scan Docs',
        description: 'Upload files',
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanDocsPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.note_add_outlined,
        label: 'Quick Notes',
        description: 'Add notes',
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuickNotesPage()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: actions
          .map((action) => _buildActionCard(context, action))
          .toList(),
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(action.icon, color: action.color, size: 28),
          VSpace.xs,
          Text(
            action.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VSpace.xxs,
          Text(
            action.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
}
