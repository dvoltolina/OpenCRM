import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';

/// Premium branding showcase card with Modern Sophisticated Blue design
class BrandingCard extends ConsumerWidget {
  const BrandingCard({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final branding = ref.watch(appConfigProvider).branding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Branding', padding: EdgeInsets.zero),
        VSpace.xs,
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: branding.primaryColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppListTile(
                  leading: Icon(
                    Icons.business,
                    size: AppIconSize.sm,
                    color: branding.primaryColor,
                  ),
                  title: 'Product Name',
                  subtitle: config.branding.productName,
                  dense: true,
                  padding: EdgeInsets.zero,
                ),
                const SpacedDivider(spacing: AppSpacing.xs),
                AppListTile(
                  leading: Icon(
                    Icons.description,
                    size: AppIconSize.sm,
                    color: branding.accentColor,
                  ),
                  title: 'Tagline',
                  subtitle: config.branding.tagline,
                  dense: true,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
