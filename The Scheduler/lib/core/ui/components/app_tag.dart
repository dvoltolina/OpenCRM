import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum AppTagVariant { neutral, primary, success, warning, error }

/// Pill-style tag/chip for statuses and filters.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.neutral,
    this.icon,
    this.onTap,
  });

  final String label;
  final AppTagVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(Theme.of(context).colorScheme);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSize.xs, color: colors.foreground),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
      ],
    );

    final tag = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );

    if (onTap == null) return tag;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: tag,
    );
  }

  _TagColors _resolveColors(ColorScheme scheme) {
    switch (variant) {
      case AppTagVariant.primary:
        return _TagColors(
          background: scheme.primary.withValues(alpha: 0.12),
          border: scheme.primary.withValues(alpha: 0.4),
          foreground: scheme.primary,
        );
      case AppTagVariant.success:
        return _TagColors(
          background: AppColors.success.withValues(alpha: 0.12),
          border: AppColors.success.withValues(alpha: 0.4),
          foreground: AppColors.success,
        );
      case AppTagVariant.warning:
        return _TagColors(
          background: AppColors.warning.withValues(alpha: 0.14),
          border: AppColors.warning.withValues(alpha: 0.45),
          foreground: AppColors.warning,
        );
      case AppTagVariant.error:
        return _TagColors(
          background: AppColors.error.withValues(alpha: 0.12),
          border: AppColors.error.withValues(alpha: 0.4),
          foreground: AppColors.error,
        );
      case AppTagVariant.neutral:
        return _TagColors(
          background: scheme.surfaceContainerLow,
          border: scheme.outline,
          foreground: scheme.onSurfaceVariant,
        );
    }
  }
}

class _TagColors {
  const _TagColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
