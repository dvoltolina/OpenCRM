import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// A reusable gradient button with the "Ember glow" effect.
///
/// Features:
/// - Background gradient from primary (top-left) to accent (bottom-right)
/// - Rounded corners (12px radius)
/// - Subtle colored shadow creating an "ember glow" effect
/// - Disabled state with flat, translucent styling
/// - Loading state with centered spinner
///
/// Usage:
/// ```dart
/// GradientButton(
///   onPressed: () => doSomething(),
///   child: Text('Submit'),
/// )
/// ```
class GradientButton extends ConsumerWidget {
  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  /// The button's content (usually Text or Row with icon)
  final Widget child;

  /// Callback when button is pressed. Pass null to disable the button.
  final VoidCallback? onPressed;

  /// Shows a loading spinner instead of child when true
  final bool isLoading;

  /// Optional fixed width. Defaults to full width if not specified.
  final double? width;

  /// Optional fixed height. Defaults to 48.
  final double? height;

  /// Optional custom padding. Defaults to symmetric horizontal 24, vertical 14.
  final EdgeInsetsGeometry? padding;

  /// Optional custom border radius. Defaults to 12.
  final double? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    final isDisabled = onPressed == null || isLoading;
    final effectiveRadius = borderRadius ?? 12.0;
    final effectiveHeight = height ?? 48.0;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    // Modern gradient: primary navy to vibrant blue with warm coral glow
    final primaryColor = branding.primaryColor;
    final accentColor = branding.accentColor;
    final ctaColor = branding.effectiveCtaColor;

    // Disabled/loading styling - flat, translucent
    if (isDisabled) {
      return SizedBox(
        width: width,
        height: effectiveHeight,
        child: Material(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: InkWell(
            onTap: null,
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: Padding(
              padding: effectivePadding,
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: theme.textTheme.labelLarge!.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          fontWeight: FontWeight.w600,
                        ),
                        child: child,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    // Active state with modern gradient and warm glow
    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Modern gradient: navy to vibrant blue
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, accentColor],
          ),
          borderRadius: BorderRadius.circular(effectiveRadius),
          // Layered shadows for depth with warm accent glow
          boxShadow: [
            // Primary shadow
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // Accent glow
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Subtle warm coral accent (adds visual warmth)
            BoxShadow(
              color: ctaColor.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(effectiveRadius),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: effectivePadding,
              child: Center(
                child: DefaultTextStyle(
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A smaller variant of GradientButton for secondary actions or compact spaces.
class GradientButtonSmall extends ConsumerWidget {
  const GradientButtonSmall({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientButton(
      onPressed: onPressed,
      isLoading: isLoading,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 8,
      child: child,
    );
  }
}

/// A gradient pill/badge that uses the same primary-to-accent gradient.
/// Useful for "Feature Readiness" badges or status indicators.
class GradientPill extends ConsumerWidget {
  const GradientPill({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [branding.primaryColor, branding.accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: branding.primaryColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
