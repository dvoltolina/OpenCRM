import 'package:flutter/material.dart';

/// Availability (operating days) step for onboarding flow.
class OnboardingAvailabilityStep extends StatelessWidget {
  const OnboardingAvailabilityStep({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final Set<String> selectedDays;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Wrap(
      spacing: 8,
      children: days
          .map(
            (day) => FilterChip(
              label: Text(day),
              selected: selectedDays.contains(day),
              onSelected: (_) => onChanged(day),
            ),
          )
          .toList(),
    );
  }
}
