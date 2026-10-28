import 'package:flutter/material.dart';

/// Business profile step for onboarding flow.
class OnboardingBusinessProfileStep extends StatelessWidget {
  const OnboardingBusinessProfileStep({
    super.key,
    required this.businessName,
    required this.tagline,
    required this.location,
  });

  final TextEditingController businessName;
  final TextEditingController tagline;
  final TextEditingController location;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: businessName,
          decoration: const InputDecoration(
            labelText: 'Business name',
            hintText: 'Bright Smiles Dental',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: tagline,
          decoration: const InputDecoration(
            labelText: 'Tagline',
            hintText: 'Coordinate every visit with confidence.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: location,
          decoration: const InputDecoration(
            labelText: 'Primary location',
            hintText: '123 Main Street',
          ),
        ),
      ],
    );
  }
}
