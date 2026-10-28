import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/models/group_attendee.dart';
import '../../../../data/models/payment.dart';
import '../../../../data/models/security_context.dart';

class ClientGroupSessionCard extends StatelessWidget {
  const ClientGroupSessionCard({
    required this.session,
    required this.securityContext,
    required this.serviceName,
    required this.providerName,
    required this.locationName,
    required this.servicePriceCents,
    required this.loadAttendee,
    required this.onCopyIcs,
    this.remainingSeats,
    this.capacity,
    this.registrationDeadline,
    this.isFull = false,
    this.deadlinePassed = false,
    this.busy = false,
    this.joined = false,
    this.onJoin,
    this.onCancel,
    this.materialsSection,
    super.key,
  });

  final Appointment session;
  final SecurityContext securityContext;
  final String serviceName;
  final String providerName;
  final String locationName;
  final int servicePriceCents;
  final int? remainingSeats;
  final int? capacity;
  final DateTime? registrationDeadline;
  final bool isFull;
  final bool deadlinePassed;
  final bool busy;
  final bool joined;
  final Future<GroupAttendee?> Function() loadAttendee;
  final VoidCallback onCopyIcs;
  final VoidCallback? onJoin;
  final VoidCallback? onCancel;
  final Widget? materialsSection;

  @override
  Widget build(BuildContext context) {
    final seatsTaken = capacity != null && remainingSeats != null
        ? (capacity! - remainingSeats!.clamp(0, capacity!))
        : session.attendeeIds.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(session.startTime),
            ),
            Text('Provider: $providerName'),
            Text('Location: $locationName'),
            const SizedBox(height: 8),
            if (capacity != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: capacity == 0 ? 0 : seatsTaken / capacity!,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seats left: ${remainingSeats ?? 0} / $capacity',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Text(
                'Capacity: Flexible',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (registrationDeadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Register by ${DateFormat.yMMMd().add_jm().format(registrationDeadline!)}',
                  style: TextStyle(
                    color: deadlinePassed
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            if (joined && onCancel != null) ...[
              _buildAttendeeStatusSection(context),
              if (materialsSection != null) materialsSection!,
            ],
            if (session.notes != null && session.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(session.notes!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          serviceName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Copy calendar invite',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: onCopyIcs,
            ),
            FilledButton(
              onPressed: isFull || busy || joined ? null : onJoin,
              child: Text(
                isFull
                    ? 'Unavailable'
                    : joined
                        ? 'Joined'
                        : 'Join',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendeeStatusSection(BuildContext context) {
    return FutureBuilder<GroupAttendee?>(
      future: loadAttendee(),
      builder: (context, snapshot) {
        final attendee = snapshot.data;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re registered!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (attendee != null && servicePriceCents > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPaymentStatusChip(
                        attendee.paymentStatus,
                        theme,
                      ),
                      if (attendee.refundStatus != PaymentStatus.none &&
                          attendee.refundStatus != attendee.paymentStatus) ...[
                        const SizedBox(width: 8),
                        _buildRefundStatusChip(attendee.refundStatus, theme),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel spot'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status, ThemeData theme) {
    Color chipColor;
    IconData icon;
    String label;

    switch (status) {
      case PaymentStatus.completed:
        chipColor = Colors.green;
        icon = Icons.paid;
        label = 'Paid';
      case PaymentStatus.pending:
        chipColor = Colors.orange;
        icon = Icons.hourglass_empty;
        label = 'Payment pending';
      case PaymentStatus.failed:
        chipColor = Colors.red;
        icon = Icons.error_outline;
        label = 'Payment failed';
      case PaymentStatus.refunded:
        chipColor = Colors.blue;
        icon = Icons.replay;
        label = 'Refunded';
      case PaymentStatus.partiallyRefunded:
        chipColor = Colors.blue.shade300;
        icon = Icons.replay;
        label = 'Partially refunded';
      case PaymentStatus.none:
        chipColor = Colors.grey;
        icon = Icons.money_off;
        label = 'No payment';
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: chipColor),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRefundStatusChip(PaymentStatus status, ThemeData theme) {
    if (status == PaymentStatus.none) return const SizedBox.shrink();

    Color chipColor;
    String label;

    switch (status) {
      case PaymentStatus.refunded:
        chipColor = Colors.blue;
        label = 'Full refund issued';
      case PaymentStatus.partiallyRefunded:
        chipColor = Colors.blue.shade300;
        label = 'Partial refund issued';
      case PaymentStatus.pending:
        chipColor = Colors.orange;
        label = 'Refund pending';
      default:
        return const SizedBox.shrink();
    }

    return Chip(
      avatar: Icon(Icons.replay, size: 16, color: chipColor),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: chipColor),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
