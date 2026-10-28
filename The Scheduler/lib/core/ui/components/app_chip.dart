// AppChip - Reusable chip components for filters and tags
// Created by Agent U0 (2025-11-28)
// Provides standardized chip styling

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Filter chip with selection state
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.showCheckmark = true,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null ? Icon(icon, size: AppIconSize.xs) : null,
      showCheckmark: showCheckmark,
    );
  }
}

/// Choice chip for single selection
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null && !selected
          ? Icon(icon, size: AppIconSize.xs)
          : null,
    );
  }
}

/// Input chip for dismissible items
class AppInputChip extends StatelessWidget {
  const AppInputChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onDeleted;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      onPressed: onPressed,
      avatar: icon != null ? Icon(icon, size: AppIconSize.xs) : null,
    );
  }
}

/// Chip group for multiple selections
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.chips,
    this.spacing = AppSpacing.xs,
    this.runSpacing = AppSpacing.xs,
  });

  final List<Widget> chips;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}
