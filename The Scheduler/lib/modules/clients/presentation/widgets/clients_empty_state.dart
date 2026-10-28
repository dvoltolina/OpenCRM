import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';

/// Enhanced empty state widget for the clients list with illustration.
/// Updated by Agent (2025-11-30) - Added illustration and improved messaging
class ClientsEmptyState extends ConsumerWidget {
  const ClientsEmptyState({
    super.key,
    required this.hasSearchTerm,
    required this.onAdd,
  });

  final bool hasSearchTerm;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appConfigProvider).branding;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(branding, theme),
            VSpace.xl,
            Text(
              hasSearchTerm ? 'No clients found' : 'No clients yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            VSpace.sm,
            Text(
              hasSearchTerm
                  ? 'Try adjusting your search or filters to find what you\'re looking for'
                  : 'Invite clients to get started and build your client list',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearchTerm) ...[
              VSpace.xl,
              // Primary CTA button
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Your First Client'),
                style: FilledButton.styleFrom(
                  backgroundColor: branding.effectiveCtaColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              VSpace.lg,
              // Secondary hint
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: branding.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: branding.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: AppIconSize.sm,
                      color: branding.primaryColor,
                    ),
                    HSpace.sm,
                    Flexible(
                      child: Text(
                        'Tip: You can also invite clients via email or share a booking link',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: branding.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasSearchTerm) ...[
              VSpace.lg,
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Client'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(AppBranding branding, ThemeData theme) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            branding.primaryColor.withValues(alpha: 0.1),
            branding.primaryColor.withValues(alpha: 0.02),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative circles
          Positioned(
            top: 30,
            right: 35,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: branding.accentColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: branding.effectiveCtaColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  branding.primaryColor.withValues(alpha: 0.15),
                  branding.accentColor.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                hasSearchTerm ? Icons.search_off : Icons.people_outline,
                size: AppIconSize.xl * 1.5,
                color: branding.primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Decorative person icons
          if (!hasSearchTerm) ...[
            Positioned(
              top: 45,
              left: 25,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline,
                  size: AppIconSize.sm,
                  color: branding.primaryColor,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 25,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add_outlined,
                  size: AppIconSize.sm,
                  color: branding.accentColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
