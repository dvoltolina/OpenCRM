import 'package:flutter/material.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/config/module_config.dart';

class ModuleDetailPane extends StatelessWidget {
  const ModuleDetailPane({
    super.key,
    required this.module,
    required this.branding,
  });

  final ModuleConfig module;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(module.icon, color: branding.primaryColor),
          const SizedBox(height: 12),
          Text(
            module.label,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            module.description,
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            'Powered by ${branding.productName}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
