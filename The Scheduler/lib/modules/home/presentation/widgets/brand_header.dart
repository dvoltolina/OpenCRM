import 'package:flutter/material.dart';

import '../../../../core/config/app_branding.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.branding});

  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (branding.logoAsset != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              branding.logoAsset!,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                branding.productName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Text(
                branding.tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
