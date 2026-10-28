import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/service.dart';

/// Enhanced service list item widget with modern card styling.
/// Updated by Agent (2025-11-30) - Fixed hardcoded values, enhanced styling
class ServiceListItem extends ConsumerWidget {
  final Service service;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<String> providerNames;
  final List<String> resourceNames;
  final String? intakeFormName;

  const ServiceListItem({
    super.key,
    required this.service,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.providerNames = const [],
    this.resourceNames = const [],
    this.intakeFormName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

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
                // Service icon with gradient
                _buildServiceIcon(branding, theme),
                HSpace.md,

                // Service info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: branding.primaryColor,
                              ),
                            ),
                          ),
                          if (service.category != null)
                            _buildCategoryBadge(theme, branding),
                        ],
                      ),
                      VSpace.xxs,

                      // Duration and price
                      _buildDurationPrice(theme, branding),

                      // Description preview
                      if (service.description != null &&
                          service.description!.isNotEmpty) ...[
                        VSpace.xxs,
                        Text(
                          service.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Providers
                      if (providerNames.isNotEmpty) ...[
                        VSpace.xs,
                        _buildChips(
                          theme: theme,
                          items: providerNames,
                          icon: Icons.person_outline,
                          color: branding.accentColor,
                        ),
                      ],

                      // Resources
                      if (resourceNames.isNotEmpty) ...[
                        VSpace.xs,
                        _buildChips(
                          theme: theme,
                          items: resourceNames,
                          icon: Icons.inventory_2_outlined,
                          color: branding.primaryColor,
                        ),
                      ],

                      // Intake form
                      if (intakeFormName != null) ...[
                        VSpace.xs,
                        _buildIntakeFormChip(theme, branding),
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

  Widget _buildServiceIcon(AppBranding branding, ThemeData theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            branding.primaryColor,
            branding.accentColor,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.design_services,
          color: Colors.white,
          size: AppIconSize.md,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ThemeData theme, AppBranding branding) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: branding.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        service.category!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: branding.accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDurationPrice(ThemeData theme, AppBranding branding) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: AppIconSize.xs,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          service.durationDisplay,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        HSpace.md,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_money,
                size: AppIconSize.xs,
                color: AppColors.success,
              ),
              Text(
                service.priceDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildIntakeFormChip(ThemeData theme, AppBranding branding) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: AppIconSize.xs,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Intake: $intakeFormName',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
