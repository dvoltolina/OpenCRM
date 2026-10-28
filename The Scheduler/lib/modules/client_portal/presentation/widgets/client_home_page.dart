import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import 'quick_action_card.dart';

/// Home page shown to clients with quick actions and overview.
class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({
    required this.client,
    required this.securityContext,
    required this.onNavigate,
    required this.config,
    super.key,
  });

  final Client client;
  final SecurityContext securityContext;
  final ValueChanged<int> onNavigate;
  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure portal surfaces stay tied to the active security context.
    ref.watch(securityContextProvider);

    final theme = Theme.of(context);
    final branding = config.branding;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            _getGreeting(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          VSpace.xxs,
          Text(
            client.firstName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: branding.primaryColor,
            ),
          ),
          VSpace.xl,

          // Quick actions grid
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          VSpace.md,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              QuickActionCard(
                icon: Icons.add_circle,
                title: 'Book Appointment',
                subtitle: 'Schedule a new visit',
                color: branding.primaryColor,
                onTap: () => onNavigate(2), // Book tab
              ),
              QuickActionCard(
                icon: Icons.event,
                title: 'My Appointments',
                subtitle: 'View upcoming visits',
                color: theme.colorScheme.tertiary,
                onTap: () => onNavigate(1), // Appointments tab
              ),
              QuickActionCard(
                icon: Icons.groups,
                title: 'Browse Classes',
                subtitle: 'Join group sessions',
                color: theme.colorScheme.secondary,
                onTap: () => onNavigate(3), // Classes tab
              ),
              QuickActionCard(
                icon: Icons.assignment,
                title: 'Intake Forms',
                subtitle: 'Complete your forms',
                color: theme.colorScheme.tertiaryContainer,
                onTap: () => onNavigate(4), // Forms tab
              ),
            ],
          ),
          VSpace.xl,

          // Info cards
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  HSpace.sm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          'Contact us for any questions about your appointments or account.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
