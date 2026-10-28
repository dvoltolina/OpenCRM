import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/ui/components/components.dart';

class FeatureTogglesCard extends StatelessWidget {
  const FeatureTogglesCard({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Features', padding: EdgeInsets.zero),
        VSpace.xs,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: config.featureFlags.enableClientPortal,
                onChanged: (_) {},
                title: const Text('Client self-service portal'),
                subtitle: const Text('Allow clients to book and manage appointments'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: config.featureFlags.enablePayments,
                onChanged: (_) {},
                title: const Text('Collect deposits and payments'),
                subtitle: const Text('Accept payments via Stripe'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: config.featureFlags.enableAutomatedReminders,
                onChanged: (_) {},
                title: const Text('Send automated reminders'),
                subtitle: const Text('Email and SMS appointment reminders'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: config.featureFlags.enableMultiLocation,
                onChanged: (_) {},
                title: const Text('Manage multiple locations'),
                subtitle: const Text('Support for multiple office locations'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: config.featureFlags.enableReporting,
                onChanged: (_) {},
                title: const Text('Advanced reporting'),
                subtitle: const Text('Detailed analytics and insights'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
