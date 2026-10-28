import 'package:flutter/material.dart';

/// Notifications configuration step for onboarding flow.
class OnboardingNotificationsStep extends StatelessWidget {
  const OnboardingNotificationsStep({
    super.key,
    required this.emailReminders,
    required this.smsReminders,
    required this.reminderLeadTime,
    required this.onChanged,
  });

  final bool emailReminders;
  final bool smsReminders;
  final Duration reminderLeadTime;
  final void Function(bool email, bool sms, Duration lead) onChanged;

  @override
  Widget build(BuildContext context) {
    final hourOptions = [1, 3, 6, 12, 24, 48];

    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Email reminders'),
          value: emailReminders,
          onChanged: (value) => onChanged(
            value ?? false,
            smsReminders,
            reminderLeadTime,
          ),
        ),
        CheckboxListTile(
          title: const Text('SMS reminders'),
          subtitle: const Text('Requires Twilio or SNS integration'),
          value: smsReminders,
          onChanged: (value) => onChanged(
            emailReminders,
            value ?? false,
            reminderLeadTime,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Send reminders'),
            DropdownButton<int>(
              value: reminderLeadTime.inHours,
              items: hourOptions
                  .map(
                    (hours) => DropdownMenuItem<int>(
                      value: hours,
                      child: Text('$hours hr before'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(
                  emailReminders,
                  smsReminders,
                  Duration(hours: value),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
