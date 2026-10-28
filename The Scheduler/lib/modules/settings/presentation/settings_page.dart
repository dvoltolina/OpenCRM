import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/user_role.dart';
import 'accounting_settings_page.dart';
import 'gift_cards_admin_page.dart';
import 'team_management_page.dart';
import 'staff_management_page.dart';
import 'widgets/branding_card.dart';
import 'widgets/feature_toggles_card.dart';
import 'widgets/integration_settings_panel.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/communication_channels_card.dart';

/// Main settings page with profile, branding, features, and integrations.
/// Updated by Agent U2 (2025-11-29) - HIPAA-compliant error handling
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authService = ref.read(authStateServiceProvider);
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(SecureErrorHandler.loadingFailed)),
      data: (securityContext) {
        if (securityContext == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Semantics(
          label: 'Settings page',
          child: ScrollablePageScaffold(
            title: 'Settings',
            showBackButton: false,
            showAppBar: false,
            body: FutureBuilder<UserProfile?>(
              future: authService.getCurrentUserProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final isProfileLoading = snapshot.connectionState == ConnectionState.waiting;
                final isAdminOrOwner =
                    securityContext.role == UserRole.owner || securityContext.role == UserRole.admin;

                if (snapshot.hasError) {
                  return Center(
                    child: Text(SecureErrorHandler.loadingFailed),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (DemoConfig.isDemoMode) ...[
                      const AppCard(
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: AppIconSize.md),
                            HSpace.sm,
                            Expanded(
                              child: Text(
                                'Demo mode is read-only. Settings changes and sign-out are disabled.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      VSpace.lg,
                    ],

                    // User Profile Section
                    if (isProfileLoading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Profile', padding: EdgeInsets.zero),
                          VSpace.xs,
                          const AppCard(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (profile != null) ...[
                      SectionHeader(title: 'Profile', padding: EdgeInsets.zero),
                      VSpace.xs,
                      UserProfileCard(profile: profile),
                    ],

                    VSpace.lg,

                    // Branding Section
                    BrandingCard(config: config),
                    VSpace.lg,

                    // Feature Toggles Section
                    FeatureTogglesCard(config: config),
                    VSpace.lg,

                    // Integrations Section
                    IntegrationSettingsPanel(config: config),
                    VSpace.lg,

                    // Communication Channels (Admin/Owner)
                    if (isAdminOrOwner) ...[
                      CommunicationChannelsCard(),
                      VSpace.lg,
                    ],

                    // Team Management section (Owner/Admin only)
                    if (isAdminOrOwner) ...[
                      CardSection(
                        title: 'Team',
                        child: Column(
                          children: [
                            AppListTile(
                              leading: const Icon(Icons.people, size: AppIconSize.md),
                              title: 'Team Management',
                              subtitle: 'Manage staff roles, invites, and status',
                              trailing: const Icon(Icons.chevron_right, size: AppIconSize.sm),
                              padding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const StaffManagementPage(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            AppListTile(
                              leading: const Icon(Icons.link, size: AppIconSize.md),
                              title: 'Staff Onboarding',
                              subtitle: 'Join codes, invites, and approvals',
                              trailing: const Icon(Icons.chevron_right, size: AppIconSize.sm),
                              padding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TeamManagementPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      VSpace.lg,
                    ],

                    // Gift Cards section
                    if (config.featureFlags.enablePayments && securityContext.role.canManagePayments) ...[
                      CardSection(
                        title: 'Commerce',
                        child: Column(
                          children: [
                            AppListTile(
                              leading: const Icon(Icons.card_giftcard, size: AppIconSize.md),
                              title: 'Gift Cards',
                              subtitle: 'Manage gift cards and templates',
                              trailing: const Icon(Icons.chevron_right, size: AppIconSize.sm),
                              padding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const GiftCardsAdminPage(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            AppListTile(
                              leading: const Icon(Icons.account_balance, size: AppIconSize.md),
                              title: 'Accounting',
                              subtitle: 'Connect QuickBooks or Xero',
                              trailing: const Icon(Icons.chevron_right, size: AppIconSize.sm),
                              padding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AccountingSettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      VSpace.lg,
                    ],

                    // Logout Button - Full width
                    if (!DemoConfig.isDemoMode)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Log Out'),
                                content: const Text('Are you sure you want to log out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Log Out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await authService.signOut();
                              // Navigation handled automatically by AuthGate
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Log Out'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
