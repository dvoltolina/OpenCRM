import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/service.dart';

class GroupSessionFiltersRow extends StatelessWidget {
  const GroupSessionFiltersRow({
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.onReset,
    required this.services,
    required this.providers,
    required this.locations,
    required this.onServiceChanged,
    required this.onProviderChanged,
    required this.onLocationChanged,
    this.serviceValue,
    this.providerValue,
    this.locationValue,
    super.key,
  });

  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final VoidCallback onReset;
  final List<Service> services;
  final List<Provider> providers;
  final List<Location> locations;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String?> onLocationChanged;
  final String? serviceValue;
  final String? providerValue;
  final String? locationValue;

  @override
  Widget build(BuildContext context) {
    final hasFilters = serviceValue != null ||
                       providerValue != null ||
                       locationValue != null;

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
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 1)),
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
                selected: serviceValue == service.id,
                onSelected: (selected) => onServiceChanged(selected ? service.id : null),
              )),
              if (providers.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ...providers.map((provider) => AppFilterChip(
                  label: provider.fullName,
                  selected: providerValue == provider.id,
                  icon: Icons.person,
                  onSelected: (selected) => onProviderChanged(selected ? provider.id : null),
                )),
              ],
              if (locations.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ...locations.map((location) => AppFilterChip(
                  label: location.name ?? location.id,
                  selected: locationValue == location.id,
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

class GroupSessionCard extends StatelessWidget {
  const GroupSessionCard({
    required this.appointment,
    required this.services,
    required this.providers,
    required this.locations,
    required this.attendeesBuilder,
    required this.onCopyIcs,
    this.materialsBuilder,
    super.key,
  });

  final Appointment appointment;
  final List<Service> services;
  final List<Provider> providers;
  final List<Location> locations;
  final WidgetBuilder attendeesBuilder;
  final VoidCallback onCopyIcs;
  final WidgetBuilder? materialsBuilder;

  @override
  Widget build(BuildContext context) {
    final serviceName =
        _resolveServiceName(appointment.serviceId, services);
    final providerName =
        _resolveProviderName(appointment.providerId, providers);
    final locationName =
        _resolveLocationName(appointment.locationId, locations);
    final remaining = appointment.remainingSeats;
    final capacity = appointment.capacity;

    return AppCard(
      child: ExpansionTile(
        title: Text(serviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VSpace.xxs,
            Row(
              children: [
                Icon(Icons.schedule, size: AppIconSize.xs, color: Theme.of(context).colorScheme.onSurfaceVariant),
                HSpace.xxs,
                Text(DateFormat.yMMMd().add_jm().format(appointment.startTime)),
              ],
            ),
            VSpace.xxs,
            Row(
              children: [
                Icon(Icons.person, size: AppIconSize.xs, color: Theme.of(context).colorScheme.onSurfaceVariant),
                HSpace.xxs,
                Text(providerName),
              ],
            ),
            VSpace.xxs,
            Row(
              children: [
                Icon(Icons.location_on, size: AppIconSize.xs, color: Theme.of(context).colorScheme.onSurfaceVariant),
                HSpace.xxs,
                Text(locationName),
              ],
            ),
            if (capacity != null) ...[
              VSpace.xxs,
              Row(
                children: [
                  Icon(Icons.people, size: AppIconSize.xs, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  HSpace.xxs,
                  Text('${remaining ?? 0} / $capacity seats'),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          tooltip: 'Copy ICS',
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: onCopyIcs,
        ),
        children: [
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            Padding(
              padding: AppSpacing.cardPadding,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appointment.notes ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          attendeesBuilder(context),
          if (materialsBuilder != null) materialsBuilder!(context),
        ],
      ),
    );
  }

  static String _resolveServiceName(String id, List<Service> services) {
    final match = services.where((service) => service.id == id);
    if (match.isEmpty) return id;
    return match.first.name;
  }

  static String _resolveProviderName(String id, List<Provider> providers) {
    final match = providers.where((provider) => provider.id == id);
    if (match.isEmpty) return id;
    return match.first.fullName;
  }

  static String _resolveLocationName(String id, List<Location> locations) {
    final match = locations.where((location) => location.id == id);
    if (match.isEmpty) return id;
    return match.first.name ?? id;
  }
}

class SessionDropdownFilter extends StatelessWidget {
  const SessionDropdownFilter({super.key, 
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All'),
          ),
          ...items,
        ],
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
