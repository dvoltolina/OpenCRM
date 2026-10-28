import 'package:flutter/material.dart';
import 'package:the_scheduler/core/ui/components/components.dart';
import 'package:the_scheduler/core/utils/color_utils.dart';
import 'package:the_scheduler/data/models/provider.dart' as provider_model;

/// Premium provider filter chips with sophisticated styling
/// Updated by Agent S1 (2025-11-30) - Modern Sophisticated Blue design system
class CalendarProviderFilter extends StatelessWidget {
  const CalendarProviderFilter({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.primaryColor,
    required this.onSelectionChanged,
    required this.isDarkMode,
  });

  final List<provider_model.Provider> providers;
  final String? selectedProviderId;
  final Color primaryColor;
  final ValueChanged<String?> onSelectionChanged;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selectedProviderId == null,
            onTap: () => onSelectionChanged(null),
            theme: theme,
            isDarkMode: isDarkMode,
            primaryColor: primaryColor,
          ),
          HSpace.xs,
          ...providers.map(
            (provider) => Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: _FilterChip(
                label: provider.firstName,
                isSelected: selectedProviderId == provider.id,
                onTap: () => onSelectionChanged(
                  selectedProviderId == provider.id ? null : provider.id,
                ),
                theme: theme,
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
                color: hexToColor(provider.colorHex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDarkMode,
    required this.primaryColor,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDarkMode;
  final Color primaryColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected
            ? null
            : isDarkMode
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : isDarkMode
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : primaryColor.withValues(alpha: 0.15),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null && !isSelected) ...[
                  Container(
                    width: AppSpacing.xs + 2,
                    height: AppSpacing.xs + 2,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color!.withValues(alpha: 0.4),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
