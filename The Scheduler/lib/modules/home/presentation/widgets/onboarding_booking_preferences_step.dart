// ignore_for_file: deprecated_member_use
// RadioListTile still requires groupValue/onChanged until Flutter provides
// a stable RadioGroup.of pattern. Will update when alternative is available.
import 'package:flutter/material.dart';

import '../../../../data/models/self_booking_access.dart';

/// Booking preferences step for onboarding flow.
class OnboardingBookingPreferencesStep extends StatelessWidget {
  const OnboardingBookingPreferencesStep({
    super.key,
    required this.selfBookingAccess,
    required this.requireDeposit,
    required this.onPreferenceChanged,
  });

  final SelfBookingAccess selfBookingAccess;
  final bool requireDeposit;
  final void Function(SelfBookingAccess access, bool requireDeposit)
      onPreferenceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client self-booking',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...SelfBookingAccess.values.map(
          (option) => RadioListTile<SelfBookingAccess>(
            title: Text(option.displayName),
            subtitle: Text(_subtitleFor(option)),
            value: option,
            groupValue: selfBookingAccess,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              if (value != null) {
                onPreferenceChanged(value, requireDeposit);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Require deposit for online bookings'),
          subtitle: const Text('Protect against no-shows'),
          value: requireDeposit,
          contentPadding: EdgeInsets.zero,
          onChanged: selfBookingAccess.isEnabled
              ? (value) => onPreferenceChanged(selfBookingAccess, value)
              : null,
        ),
      ],
    );
  }

  String _subtitleFor(SelfBookingAccess option) {
    switch (option) {
      case SelfBookingAccess.disabled:
        return 'Staff must create all appointments';
      case SelfBookingAccess.existingOnly:
        return 'Only clients with accounts can book';
      case SelfBookingAccess.allCustomers:
        return 'Anyone can book via your portal';
    }
  }
}
