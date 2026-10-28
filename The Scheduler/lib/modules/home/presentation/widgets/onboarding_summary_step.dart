import 'package:flutter/material.dart';

import '../../../../data/models/self_booking_access.dart';

/// Summary step for onboarding flow showing all configured values.
class OnboardingSummaryStep extends StatelessWidget {
  const OnboardingSummaryStep({
    super.key,
    required this.industry,
    required this.businessName,
    required this.tagline,
    required this.location,
    required this.selectedDays,
    required this.services,
    required this.selfBookingAccess,
    required this.requireDeposit,
    required this.emailReminders,
    required this.smsReminders,
    required this.reminderLeadTime,
  });

  final String industry;
  final String businessName;
  final String tagline;
  final String location;
  final List<String> selectedDays;
  final List<String> services;
  final SelfBookingAccess selfBookingAccess;
  final bool requireDeposit;
  final bool emailReminders;
  final bool smsReminders;
  final Duration reminderLeadTime;

  @override
  Widget build(BuildContext context) {
    final summaryItems = [
      ('Industry', industry),
      ('Business', businessName),
      ('Tagline', tagline),
      ('Location', location.isEmpty ? 'Not set' : location),
      ('Operating days', selectedDays.isEmpty ? 'Not set' : selectedDays.join(', ')),
      (
        'Services',
        services.isEmpty ? 'Using defaults' : services.join(', '),
      ),
      (
        'Self-booking',
        selfBookingAccess.displayName,
      ),
      (
        'Deposits',
        requireDeposit ? 'Required' : 'Optional',
      ),
      (
        'Reminders',
        [
          if (emailReminders) 'Email',
          if (smsReminders) 'SMS',
        ].isEmpty
            ? 'Disabled'
            : [
                if (emailReminders) 'Email',
                if (smsReminders) 'SMS',
              ].join(' & '),
      ),
      (
        'Lead time',
        '${reminderLeadTime.inHours}h before appointment',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      item.$1,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
