import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/user_role.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: AppIconSize.lg,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              HSpace.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName ?? 'User',
                      style: theme.textTheme.titleLarge,
                    ),
                    VSpace.xxs,
                    Text(
                      profile.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    VSpace.xxs,
                    Chip(
                      label: Text(_getRoleDisplayName(profile.role)),
                      avatar: Icon(
                        _getRoleIcon(profile.role),
                        size: AppIconSize.xs,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          VSpace.md,
          const SpacedDivider(spacing: AppSpacing.xs),
          AppListTile(
            leading: const Icon(Icons.business, size: AppIconSize.sm),
            title: 'Business ID',
            subtitle: profile.businessId,
            dense: true,
            padding: EdgeInsets.zero,
          ),
          if (profile.providerId != null)
            AppListTile(
              leading: const Icon(Icons.medical_services, size: AppIconSize.sm),
              title: 'Provider ID',
              subtitle: profile.providerId!,
              dense: true,
              padding: EdgeInsets.zero,
            ),
          if (profile.clientId != null)
            AppListTile(
              leading: const Icon(Icons.person_outline, size: AppIconSize.sm),
              title: 'Client ID',
              subtitle: profile.clientId!,
              dense: true,
              padding: EdgeInsets.zero,
            ),
          VSpace.xs,
          // Debug: Copy Firebase Auth Token - Full Width
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Force refresh to ensure a fresh, non-expired token with latest claims.
                  final token = await user.getIdToken(true);
                  if (token != null) {
                    await Clipboard.setData(ClipboardData(text: token));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Auth token copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.copy, size: AppIconSize.xs),
              label: const Text('Copy Auth Token (Debug)'),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.sales:
        return 'Sales';
      case UserRole.provider:
        return 'Provider';
      case UserRole.frontDesk:
        return 'Front Desk';
      case UserRole.staff:
        return 'Staff Member';
      case UserRole.client:
        return 'Client';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.manager:
        return Icons.supervisor_account;
      case UserRole.sales:
        return Icons.trending_up;
      case UserRole.provider:
        return Icons.medical_services_outlined;
      case UserRole.frontDesk:
        return Icons.receipt_long;
      case UserRole.staff:
        return Icons.badge;
      case UserRole.client:
        return Icons.person;
    }
  }
}
