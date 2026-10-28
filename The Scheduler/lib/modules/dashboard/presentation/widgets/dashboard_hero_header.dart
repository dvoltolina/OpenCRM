import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/ui/components/components.dart';

/// Hero header banner showing app tagline with dismiss capability.
/// Updated with Modern Sophisticated Blue design system - gradient and soft shadows.
class DashboardHeroHeader extends ConsumerStatefulWidget {
  const DashboardHeroHeader({required this.config, super.key});

  final AppConfig config;

  @override
  ConsumerState<DashboardHeroHeader> createState() => _DashboardHeroHeaderState();
}

class _DashboardHeroHeaderState extends ConsumerState<DashboardHeroHeader> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final branding = widget.config.branding;

    return Semantics(
      label: 'Dashboard hero header: ${branding.tagline}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          // Modern gradient: navy to vibrant blue
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [branding.primaryColor, branding.accentColor],
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          // Soft layered shadows with blue tint
          boxShadow: [
            BoxShadow(
              color: branding.primaryColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: branding.accentColor.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    branding.tagline,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  VSpace.xs,
                  Text(
                    'Your all-in-one scheduling and client management platform.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              tooltip: 'Dismiss',
              onPressed: () => setState(() => _dismissed = true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
