// AppButton - Standardized button components
// Created by Agent U0 (2025-11-28)
// Provides consistent button styling across the app

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Primary filled button with consistent styling
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (isLoading) {
      button = FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: AppIconSize.sm,
          height: AppIconSize.sm,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(label),
      );
    } else if (icon != null) {
      button = FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppIconSize.sm),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// Secondary outlined button
class AppButtonOutlined extends StatelessWidget {
  const AppButtonOutlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (isLoading) {
      button = OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: AppIconSize.sm,
          height: AppIconSize.sm,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(label),
      );
    } else if (icon != null) {
      button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppIconSize.sm),
        label: Text(label),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// Text button for tertiary actions
class AppButtonText extends StatelessWidget {
  const AppButtonText({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppIconSize.sm),
        label: Text(label),
      );
    }

    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
