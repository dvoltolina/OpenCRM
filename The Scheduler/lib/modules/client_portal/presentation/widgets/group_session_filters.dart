import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/service.dart';

class GroupSessionFilters extends StatelessWidget {
  const GroupSessionFilters({
    super.key,
    required this.services,
    required this.providers,
    required this.locations,
    required this.serviceFilter,
    required this.providerFilter,
    required this.locationFilter,
    required this.dateRange,
    required this.onServiceChanged,
    required this.onProviderChanged,
    required this.onLocationChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  final List<Service> services;
  final List<Provider> providers;
  final List<Location> locations;
  final String? serviceFilter;
  final String? providerFilter;
  final String? locationFilter;
  final DateTimeRange dateRange;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasFilters = serviceFilter != null ||
                       providerFilter != null ||
                       locationFilter != null;

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, size: AppIconSize.xs),
                label: Text(
                  '${DateFormat.Md().format(dateRange.start)} - ${DateFormat.Md().format(dateRange.end)}',
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: dateRange,
                  );
                  if (picked != null) {
                    onDateRangeChanged(picked);
                  }
                },
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.clear, size: AppIconSize.xs),
                  label: const Text('Clear'),
                ),
            ],
          ),
          VSpace.xs,
          AppChipGroup(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            chips: [
              ...services.map((service) => AppFilterChip(
                label: service.name,
                selected: serviceFilter == service.id,
                onSelected: (selected) => onServiceChanged(selected ? service.id : null),
              )),
              if (providers.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ...providers.map((provider) => AppFilterChip(
                  label: provider.fullName,
                  selected: providerFilter == provider.id,
                  icon: Icons.person,
                  onSelected: (selected) => onProviderChanged(selected ? provider.id : null),
                )),
              ],
              if (locations.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ...locations.map((location) => AppFilterChip(
                  label: location.name ?? location.id,
                  selected: locationFilter == location.id,
                  icon: Icons.location_on,
                  onSelected: (selected) => onLocationChanged(selected ? location.id : null),
                )),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
