// FormLayout - Form layout helpers
// Created by Agent P0 (2025-11-28)
// Provides standardized form layouts and button patterns

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'spacing_helpers.dart';

/// Form field group with consistent spacing
///
/// Wraps form fields with standard vertical spacing (VSpace.md)
/// Use to maintain consistent spacing between form fields
///
/// Usage:
/// ```dart
/// FormFieldGroup(
///   children: [
///     TextField(decoration: InputDecoration(labelText: 'Name')),
///     TextField(decoration: InputDecoration(labelText: 'Email')),
///     TextField(decoration: InputDecoration(labelText: 'Phone')),
///   ],
/// )
/// ```
class FormFieldGroup extends StatelessWidget {
  const FormFieldGroup({
    super.key,
    required this.children,
    this.spacing,
  });

  final List<Widget> children;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = spacing ?? AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) SizedBox(height: effectiveSpacing),
        ],
      ],
    );
  }
}

/// Form button row with cancel and submit buttons
///
/// Creates right-aligned button row with:
/// - Cancel button (TextButton) on left
/// - Submit button (FilledButton) on right
/// - Standard horizontal spacing
///
/// Usage:
/// ```dart
/// FormButtonRow(
///   onCancel: () => Navigator.pop(context),
///   onSubmit: _handleSubmit,
///   submitLabel: 'Save',
/// )
/// ```
class FormButtonRow extends StatelessWidget {
  const FormButtonRow({
    super.key,
    required this.onCancel,
    required this.onSubmit,
    this.cancelLabel = 'Cancel',
    this.submitLabel = 'Submit',
    this.isSubmitting = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          child: Text(cancelLabel),
        ),
        HSpace.sm,
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}

/// Full-width button wrapper
///
/// Creates button that spans full width of container
/// Use for primary actions in forms and dialogs
///
/// Usage:
/// ```dart
/// FullWidthButton(
///   onPressed: _handleLogin,
///   label: 'Log In',
/// )
/// ```
class FullWidthButton extends StatelessWidget {
  const FullWidthButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.buttonType = FullWidthButtonType.filled,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final FullWidthButtonType buttonType;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : (icon != null ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              HSpace.xs,
              Text(label),
            ],
          ) : Text(label));

    final button = switch (buttonType) {
      FullWidthButtonType.filled => FilledButton(
          onPressed: effectiveOnPressed,
          child: buttonChild,
        ),
      FullWidthButtonType.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: buttonChild,
        ),
      FullWidthButtonType.text => TextButton(
          onPressed: effectiveOnPressed,
          child: buttonChild,
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

/// Button type for FullWidthButton
enum FullWidthButtonType {
  filled,
  outlined,
  text,
}

/// Form section with title and optional description
///
/// Groups related form fields with a section header
///
/// Usage:
/// ```dart
/// FormSection(
///   title: 'Personal Information',
///   description: 'Enter your basic details',
///   child: FormFieldGroup(
///     children: [
///       TextField(decoration: InputDecoration(labelText: 'Name')),
///       TextField(decoration: InputDecoration(labelText: 'Email')),
///     ],
///   ),
/// )
/// ```
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        if (description != null) ...[
          VSpace.xxs,
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        VSpace.md,
        child,
      ],
    );
  }
}

/// Horizontal form field for compact layouts
///
/// Places label and field side-by-side
/// Useful for settings pages or compact forms
///
/// Usage:
/// ```dart
/// HorizontalFormField(
///   label: 'Email notifications',
///   field: Switch(
///     value: _emailEnabled,
///     onChanged: _handleEmailToggle,
///   ),
/// )
/// ```
class HorizontalFormField extends StatelessWidget {
  const HorizontalFormField({
    super.key,
    required this.label,
    required this.field,
    this.description,
    this.labelFlex = 2,
    this.fieldFlex = 3,
  });

  final String label;
  final Widget field;
  final String? description;
  final int labelFlex;
  final int fieldFlex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: labelFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
              if (description != null) ...[
                VSpace.xxs,
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        HSpace.md,
        Expanded(
          flex: fieldFlex,
          child: field,
        ),
      ],
    );
  }
}

/// Form container with card styling
///
/// Wraps form in a card with consistent padding
/// Use for standalone forms or form sections
class FormContainer extends StatelessWidget {
  const FormContainer({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );
  }
}
