import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/provider.dart' as provider_model;

/// Enhanced provider list item widget with modern card styling.
/// Updated by Agent (2025-11-30) - Fixed hardcoded values, enhanced styling
class ProviderListItem extends ConsumerWidget {
  final provider_model.Provider provider;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<String> serviceNames;
  final List<String> locationNames;

  const ProviderListItem({
    super.key,
    required this.provider,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.serviceNames = const [],
    this.locationNames = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);
    final colorInt = int.tryParse(provider.colorHex, radix: 16);
    final providerColor =
        colorInt != null ? Color(0xFF000000 | colorInt) : branding.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                // Avatar with gradient
                _buildAvatar(providerColor, theme),
                HSpace.md,

                // Provider info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        provider.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: branding.primaryColor,
                        ),
                      ),
                      VSpace.xxs,

                      // Contact info
                      _buildContactInfo(theme),

                      // Locations
                      if (locationNames.isNotEmpty) ...[
                        VSpace.xs,
                        _buildChips(
                          theme: theme,
                          items: locationNames,
                          icon: Icons.location_on_outlined,
                          color: branding.accentColor,
                        ),
                      ],

                      // Services
                      if (serviceNames.isNotEmpty) ...[
                        VSpace.xs,
                        _buildChips(
                          theme: theme,
                          items: serviceNames,
                          icon: Icons.design_services,
                          color: branding.primaryColor,
                        ),
                      ],

                      // Specializations
                      if (provider.specializations.isNotEmpty) ...[
                        VSpace.xs,
                        _buildSpecializations(theme, branding),
                      ],
                    ],
                  ),
                ),

                // Actions menu
                _buildActionsMenu(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color providerColor, ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            providerColor,
            providerColor.withValues(alpha: 0.7),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: providerColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          provider.initials,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(ThemeData theme) {
    final hasEmail = provider.email != null && provider.email!.isNotEmpty;
    final hasPhone = provider.phone != null && provider.phone!.isNotEmpty;

    if (!hasEmail && !hasPhone) return const SizedBox.shrink();

    final details = <String>[];
    if (hasEmail) details.add(provider.email!);
    if (hasPhone) details.add(provider.phone!);

    return Text(
      details.join(' • '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildChips({
    required ThemeData theme,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: items.take(3).map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIconSize.xs,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  item,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecializations(ThemeData theme, AppBranding branding) {
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: provider.specializations.take(3).map((spec) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            spec,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsMenu(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: AppIconSize.sm),
              HSpace.sm,
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: AppIconSize.sm,
                color: AppColors.error,
              ),
              HSpace.sm,
              Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
    );
  }
}
