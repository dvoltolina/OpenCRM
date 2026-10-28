// AppCard - Consistent card styling component
// Created by Agent U0 (2025-11-28)
// Provides standardized card styling with consistent padding, radius, and elevation

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Standard card component with consistent styling
///
/// Usage:
/// ```dart
/// AppCard(
///   child: Text('Card content'),
/// )
///
/// AppCard.outlined(
///   child: Text('Outlined card'),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  }) : outlined = false;

  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.onTap,
  })  : outlined = true,
        elevation = null;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePadding = padding ?? AppSpacing.cardPadding;
    final effectiveRadius = borderRadius ?? AppRadius.card;

    Widget content = Container(
      padding: effectivePadding,
      decoration: outlined
          ? BoxDecoration(
              color: color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color: colorScheme.outline,
                width: 1,
              ),
            )
          : null,
      child: child,
    );

    if (outlined) {
      if (onTap != null) {
        content = InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: content,
        );
      }
      return Container(
        margin: margin,
        child: content,
      );
    }

    // Regular card with elevation
    return Card(
      margin: margin ?? EdgeInsets.zero,
      color: color,
      elevation: elevation ?? AppElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveRadius),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(effectiveRadius),
              child: Padding(
                padding: effectivePadding,
                child: child,
              ),
            )
          : Padding(
              padding: effectivePadding,
              child: child,
            ),
    );
  }
}

/// Compact card for smaller spaces
class CompactCard extends StatelessWidget {
  const CompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: color,
      onTap: onTap,
      child: child,
    );
  }
}
