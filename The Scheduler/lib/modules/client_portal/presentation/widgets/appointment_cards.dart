import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/provider.dart' as provider_model;
import '../../../../data/models/recurrence_pattern.dart';
import '../../../../data/models/service.dart';

class AppointmentCardTile extends StatelessWidget {
  const AppointmentCardTile({
    required this.appointment,
    required this.isUpcoming,
    this.service,
    this.provider,
    this.location,
    required this.onTap,
    super.key,
  });

  final Appointment appointment;
  final bool isUpcoming;
  final Service? service;
  final provider_model.Provider? provider;
  final Location? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(appointment.startTime),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(status: appointment.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${timeFormat.format(appointment.startTime)} - '
                    '${timeFormat.format(appointment.endTime)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (appointment.isRecurring) ...[
                const RecurringBadge(),
                const SizedBox(height: 8),
              ],
              if (service != null)
                _ListRow(
                  icon: Icons.design_services_outlined,
                  text: service!.name,
                ),
              const SizedBox(height: 8),
              if (provider != null)
                _ListRow(
                  icon: Icons.person_outline,
                  text: provider!.fullName,
                ),
              const SizedBox(height: 8),
              if (location != null)
                _ListRow(
                  icon: Icons.location_on_outlined,
                  text: location!.name ?? location!.address,
                ),
              if (isUpcoming &&
                  appointment.status != AppointmentStatus.cancelled) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RecurringSeriesCard extends StatelessWidget {
  const RecurringSeriesCard({
    required this.occurrences,
    required this.parent,
    required this.isUpcoming,
    required this.service,
    required this.providers,
    required this.locations,
    required this.onTap,
    super.key,
  });

  final List<Appointment> occurrences;
  final Appointment? parent;
  final bool isUpcoming;
  final Service? service;
  final Map<String, provider_model.Provider> providers;
  final Map<String, Location> locations;
  final ValueChanged<Appointment> onTap;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Appointment>.from(occurrences)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final firstOccurrence = sorted.first;
    final lastOccurrence = sorted.last;
    final RecurrencePattern? pattern = parent?.recurrencePattern;
    final subtitleParts = <String>[];
    if (pattern != null) {
      subtitleParts.add(pattern.description);
      subtitleParts.add(pattern.endDescription);
    }
    final chipLabel = '${sorted.length} shown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.repeat),
        title: Text(
          service?.name ?? 'Recurring appointment',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitleParts.isNotEmpty) Text(subtitleParts.join(' • ')),
            Text(
              '${DateFormat.yMMMd().format(firstOccurrence.startTime)}'
              ' → ${DateFormat.yMMMd().format(lastOccurrence.startTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(chipLabel)),
            ),
          ),
          const Divider(height: 0),
          ...sorted.map(
            (occurrence) => RecurringOccurrenceTile(
              appointment: occurrence,
              provider: providers[occurrence.providerId],
              location: locations[occurrence.locationId],
              service: servicesFor(occurrence),
              isUpcoming: isUpcoming,
              onTap: () => onTap(occurrence),
            ),
          ),
        ],
      ),
    );
  }

  Service? servicesFor(Appointment appointment) {
    return appointment.serviceId == service?.id ? service : service;
  }
}

class RecurringOccurrenceTile extends StatelessWidget {
  const RecurringOccurrenceTile({
    required this.appointment,
    required this.isUpcoming,
    required this.onTap,
    this.provider,
    this.location,
    this.service,
    super.key,
  });

  final Appointment appointment;
  final bool isUpcoming;
  final VoidCallback onTap;
  final provider_model.Provider? provider;
  final Location? location;
  final Service? service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        '${DateFormat('EEE, MMM d').format(appointment.startTime)} • '
        '${DateFormat('h:mm a').format(appointment.startTime)}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service != null) Text(service!.name),
          if (provider != null) Text(provider!.fullName),
          if (location != null)
            Text(
              location!.name ?? location!.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      trailing: StatusChip(status: appointment.status),
      onTap: onTap,
    );
  }
}

class RecurringBadge extends StatelessWidget {
  const RecurringBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.repeat, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          'Recurring series',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case AppointmentStatus.confirmed:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        label = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case AppointmentStatus.pending:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        label = 'Pending';
        icon = Icons.schedule_outlined;
        break;
      case AppointmentStatus.cancelled:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case AppointmentStatus.completed:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      case AppointmentStatus.noShow:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        label = 'No Show';
        icon = Icons.event_busy_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
