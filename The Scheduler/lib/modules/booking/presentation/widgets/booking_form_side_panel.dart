import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/booking_rules_engine.dart';

class BookingFormSidePanel extends StatelessWidget {
  const BookingFormSidePanel({
    required this.policies,
    required this.validation,
    required this.onRefreshPolicies,
    super.key,
  });

  final BookingPolicies policies;
  final BookingValidationResult? validation;
  final VoidCallback onRefreshPolicies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PolicyCard(policies: policies),
        const SizedBox(height: 16),
        if (validation != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest validation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    validation!.isValid
                        ? 'Ready to book'
                        : '${validation!.conflicts.length} conflict(s)',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: onRefreshPolicies,
                    child: const Text('Re-run validation'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recent requests',
                  ),
                  SizedBox(height: 12),
                  _RequestTile(
                    name: 'Alex Johnson',
                    subtitle: 'Initial Consultation • 9:30 AM',
                  ),
                  Divider(),
                  _RequestTile(
                    name: 'Priya Patel',
                    subtitle: 'Follow-up Visit • 11:00 AM',
                  ),
                  Divider(),
                  _RequestTile(
                    name: 'Farrah Lewis',
                    subtitle: 'Virtual Session • 2:00 PM',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.policies});

  final BookingPolicies policies;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking policies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PolicyChip(
                  label: 'Slot length',
                  value: '${policies.defaultSlotLength.inMinutes} mins',
                ),
                _PolicyChip(
                  label: 'Buffer',
                  value: '${policies.bufferBetweenAppointments.inMinutes} mins',
                ),
                _PolicyChip(
                  label: 'Cancellation window',
                  value: '${policies.cancellationWindow.inHours} hrs',
                ),
                _PolicyChip(
                  label: 'Min. notice',
                  value: '${policies.minimumBookingNotice?.inHours ?? 0} hrs',
                ),
                _PolicyChip(
                  label: 'Max advance',
                  value: '${policies.maximumAdvanceBooking?.inDays ?? 0} days',
                ),
                _PolicyChip(
                  label: 'Deposits',
                  value: policies.allowDeposits
                      ? '\$${policies.depositAmount?.toStringAsFixed(0) ?? '50'}'
                      : 'Disabled',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyChip extends StatelessWidget {
  const _PolicyChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(subtitle),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new),
        onPressed: () {},
      ),
    );
  }
}
