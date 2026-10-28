// StatusPill - Status badge component
// Created by Agent U0 (2025-11-28)
// Provides consistent status pill styling

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Status pill for displaying status badges
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  factory StatusPill.success({
    required String label,
    IconData? icon,
  }) {
    return StatusPill(
      label: label,
      color: Colors.white,
      backgroundColor: AppColors.success,
      icon: icon,
    );
  }

  factory StatusPill.warning({
    required String label,
    IconData? icon,
  }) {
    return StatusPill(
      label: label,
      color: Colors.white,
      backgroundColor: AppColors.warning,
      icon: icon,
    );
  }

  factory StatusPill.error({
    required String label,
    IconData? icon,
  }) {
    return StatusPill(
      label: label,
      color: Colors.white,
      backgroundColor: AppColors.error,
      icon: icon,
    );
  }

  factory StatusPill.info({
    required String label,
    IconData? icon,
  }) {
    return StatusPill(
      label: label,
      color: Colors.white,
      backgroundColor: AppColors.info,
      icon: icon,
    );
  }

  factory StatusPill.neutral({
    required String label,
    IconData? icon,
  }) {
    return StatusPill(
      label: label,
      color: null,
      backgroundColor: null,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onPrimary;
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.xs, color: effectiveColor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
