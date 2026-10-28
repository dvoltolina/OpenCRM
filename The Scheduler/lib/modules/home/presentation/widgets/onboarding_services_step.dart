import 'package:flutter/material.dart';

/// Services configuration step for onboarding flow.
class OnboardingServicesStep extends StatelessWidget {
  const OnboardingServicesStep({
    super.key,
    required this.services,
    required this.serviceInput,
    required this.onAddService,
    required this.onRemoveService,
  });

  final List<String> services;
  final TextEditingController serviceInput;
  final VoidCallback onAddService;
  final ValueChanged<String> onRemoveService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: serviceInput,
                decoration: const InputDecoration(
                  labelText: 'Service name',
                  hintText: '60-min consultation',
                ),
                onSubmitted: (_) => onAddService(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Add service',
              icon: const Icon(Icons.add),
              onPressed: onAddService,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          Text(
            'No custom services yet — default catalog will be used.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services
                .map(
                  (service) => Chip(
                    label: Text(service),
                    onDeleted: () => onRemoveService(service),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
