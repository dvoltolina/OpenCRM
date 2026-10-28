import 'package:flutter/material.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';
import 'clients_filter_chip.dart';

/// Filter and sort options for the clients list with count badges.
/// Updated by Agent (2025-11-30) - Added count badges and coral accent for New
class ClientsFilters extends StatelessWidget {
  final ClientLifecycle? lifecycleFilter;
  final ValueChanged<ClientLifecycle?> onLifecycleChanged;
  final ClientSortOption sortOption;
  final ValueChanged<ClientSortOption> onSortChanged;
  final Set<String> availableTags;
  final String? tagFilter;
  final ValueChanged<String?> onTagChanged;
  final int totalCount;
  final int newCount;
  final int activeCount;
  final int inactiveCount;

  const ClientsFilters({
    super.key,
    required this.lifecycleFilter,
    required this.onLifecycleChanged,
    required this.sortOption,
    required this.onSortChanged,
    required this.availableTags,
    required this.tagFilter,
    required this.onTagChanged,
    this.totalCount = 0,
    this.newCount = 0,
    this.activeCount = 0,
    this.inactiveCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Lifecycle filters
            ClientsFilterChip(
              label: 'All Clients',
              isSelected: lifecycleFilter == null,
              onTap: () => onLifecycleChanged(null),
              count: totalCount,
            ),
            HSpace.xs,
            ClientsFilterChip(
              label: 'New',
              isSelected: lifecycleFilter == ClientLifecycle.newClient,
              onTap: () => onLifecycleChanged(ClientLifecycle.newClient),
              useCoralAccent: true,
              count: newCount,
            ),
            HSpace.xs,
            ClientsFilterChip(
              label: 'Active',
              isSelected: lifecycleFilter == ClientLifecycle.active,
              onTap: () => onLifecycleChanged(ClientLifecycle.active),
              color: AppColors.success,
              count: activeCount,
            ),
            HSpace.xs,
            ClientsFilterChip(
              label: 'Inactive',
              isSelected: lifecycleFilter == ClientLifecycle.inactive,
              onTap: () => onLifecycleChanged(ClientLifecycle.inactive),
              color: AppColors.warning,
              count: inactiveCount,
            ),
            HSpace.md,
            Container(
              height: 24,
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            HSpace.md,
            // Sort menu with improved styling
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: PopupMenuButton<ClientSortOption>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort,
                      size: AppIconSize.sm,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sort',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                tooltip: 'Sort by',
                onSelected: onSortChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                itemBuilder: (context) => [
                  _buildSortItem(
                    ClientSortOption.nameAsc,
                    'Name (A-Z)',
                    Icons.sort_by_alpha,
                  ),
                  _buildSortItem(
                    ClientSortOption.nameDesc,
                    'Name (Z-A)',
                    Icons.sort_by_alpha,
                  ),
                  _buildSortItem(
                    ClientSortOption.recentlyAdded,
                    'Recently Added',
                    Icons.schedule,
                  ),
                  _buildSortItem(
                    ClientSortOption.lastAppointment,
                    'Last Appointment',
                    Icons.history,
                  ),
                  _buildSortItem(
                    ClientSortOption.upcomingAppointment,
                    'Next Appointment',
                    Icons.event,
                  ),
                ],
              ),
            ),
            if (availableTags.isNotEmpty) ...[
              HSpace.md,
              Container(
                height: 24,
                width: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              HSpace.md,
              ...availableTags.map((tag) {
                final isSelected = tagFilter == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => onTagChanged(isSelected ? null : tag),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ClientSortOption> _buildSortItem(
    ClientSortOption option,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: sortOption == option ? AppColors.primary : null,
          ),
          HSpace.sm,
          Text(
            label,
            style: TextStyle(
              fontWeight: sortOption == option ? FontWeight.w600 : null,
              color: sortOption == option ? AppColors.primary : null,
            ),
          ),
          if (sortOption == option) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: AppIconSize.sm,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Sort options for client list
enum ClientSortOption {
  nameAsc,
  nameDesc,
  recentlyAdded,
  lastAppointment,
  upcomingAppointment,
}
