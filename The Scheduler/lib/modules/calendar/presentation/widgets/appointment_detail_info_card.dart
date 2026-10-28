import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/location.dart';
import '../../../../data/models/payment.dart';

/// Appointment details card showing provider, location, duration, price, etc.
class AppointmentDetailInfoCard extends StatelessWidget {
  AppointmentDetailInfoCard({
    super.key,
    required this.appointment,
    required this.provider,
    this.service,
    this.location,
  }) : _dateFormat = DateFormat.yMMMd().add_jm();

  final Appointment appointment;
  final Provider provider;
  final Service? service;
  final Location? location;
  final DateFormat _dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              theme,
              Icons.person,
              'Provider',
              provider.fullName,
            ),
            if (location != null)
              _buildDetailRow(
                theme,
                Icons.location_on,
                'Location',
                location!.name ?? 'Unknown',
              ),
            if (service != null) ...[
              _buildDetailRow(
                theme,
                Icons.access_time,
                'Duration',
                '${service!.durationMinutes} minutes',
              ),
              if (service!.price > 0)
                _buildDetailRow(
                  theme,
                  Icons.attach_money,
                  'Price',
                  '\$${service!.price.toStringAsFixed(2)}',
                ),
            ],
            _buildDetailRow(
              theme,
              Icons.calendar_today,
              'Created',
              _dateFormat.format(appointment.createdAt),
            ),
            if (appointment.paymentStatus != PaymentStatus.none)
              _buildDetailRow(
                theme,
                Icons.payment,
                'Payment',
                _paymentStatusLabel(appointment.paymentStatus),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _paymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.none:
        return 'None';
    }
  }
}
