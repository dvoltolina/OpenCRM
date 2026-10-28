import 'package:flutter/material.dart';

/// Industry selection step for onboarding flow.
class OnboardingIndustryStep extends StatelessWidget {
  const OnboardingIndustryStep({
    super.key,
    required this.selectedIndustry,
    required this.onChanged,
  });

  final String selectedIndustry;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const industries = ['Therapy', 'Realtor', 'Dental', 'Chiropractor'];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: industries
          .map(
            (industry) => ChoiceChip(
              label: Text(industry),
              selected: selectedIndustry == industry,
              onSelected: (_) => onChanged(industry),
            ),
          )
          .toList(),
    );
  }
}
