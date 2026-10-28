// SpacingHelpers - Convenient spacing widgets
// Created by Agent U0 (2025-11-28)
// Provides simple spacing utilities

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Vertical spacing widgets using design tokens
class VSpace {
  VSpace._();

  static const xxs = SizedBox(height: AppSpacing.xxs);
  static const xs = SizedBox(height: AppSpacing.xs);
  static const sm = SizedBox(height: AppSpacing.sm);
  static const md = SizedBox(height: AppSpacing.md);
  static const lg = SizedBox(height: AppSpacing.lg);
  static const xl = SizedBox(height: AppSpacing.xl);
  static const xxl = SizedBox(height: AppSpacing.xxl);
  static const xxxl = SizedBox(height: AppSpacing.xxxl);
}

/// Horizontal spacing widgets using design tokens
class HSpace {
  HSpace._();

  static const xxs = SizedBox(width: AppSpacing.xxs);
  static const xs = SizedBox(width: AppSpacing.xs);
  static const sm = SizedBox(width: AppSpacing.sm);
  static const md = SizedBox(width: AppSpacing.md);
  static const lg = SizedBox(width: AppSpacing.lg);
  static const xl = SizedBox(width: AppSpacing.xl);
  static const xxl = SizedBox(width: AppSpacing.xxl);
  static const xxxl = SizedBox(width: AppSpacing.xxxl);
}

/// Divider with consistent spacing
class SpacedDivider extends StatelessWidget {
  const SpacedDivider({
    super.key,
    this.spacing = AppSpacing.md,
  });

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: const Divider(),
    );
  }
}
