// Accessibility utilities and semantic helpers
// Agent 8: Mobile & UI Polish
// Ensures WCAG compliance and screen reader support

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities
class A11yHelpers {
  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.accessibleNavigation;
  }

  /// Check if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.disableAnimations;
  }

  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.highContrast;
  }

  /// Announce message to screen reader
  static void announce(
    BuildContext context,
    String message, {
    TextDirection? textDirection,
  }) {
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(
      view,
      message,
      textDirection ?? Directionality.of(context),
    );
  }

  /// Check color contrast ratio
  /// WCAG AA requires 4.5:1 for normal text, 3:1 for large text
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA
  static bool meetsWCAGAA(Color foreground, Color background,
      {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return ratio >= (isLargeText ? 3.0 : 4.5);
  }

  /// Check if contrast meets WCAG AAA
  static bool meetsWCAGAAA(Color foreground, Color background,
      {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return ratio >= (isLargeText ? 4.5 : 7.0);
  }

  /// Get relative luminance of a color
  static double _relativeLuminance(Color color) {
    final r = _luminanceComponent(color.r);
    final g = _luminanceComponent(color.g);
    final b = _luminanceComponent(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate luminance component
  static double _luminanceComponent(double value) {
    return value <= 0.03928
        ? value / 12.92
        : ((value + 0.055) / 1.055) * (value + 0.055) / 1.055;
  }
}

/// Semantic label builder helpers
class SemanticLabels {
  /// Button label
  static String button(String label, {String? hint}) {
    return hint != null ? '$label, $hint' : label;
  }

  /// Card label with content description
  static String card(String title, {String? subtitle, String? description}) {
    final parts = [title];
    if (subtitle != null) parts.add(subtitle);
    if (description != null) parts.add(description);
    return parts.join(', ');
  }

  /// Status chip label
  static String statusChip(String status, {String? description}) {
    final parts = ['Status: $status'];
    if (description != null) parts.add(description);
    return parts.join(', ');
  }

  /// Date label
  static String date(DateTime date, {bool includeTime = false}) {
    if (includeTime) {
      return 'Date: ${date.toLocal().toString()}';
    }
    return 'Date: ${date.toLocal().toString().split(' ')[0]}';
  }

  /// Count label
  static String count(int count, String singular, String plural) {
    return count == 1 ? '$count $singular' : '$count $plural';
  }

  /// Loading label
  static String loading([String? context]) {
    return context != null ? 'Loading $context' : 'Loading';
  }

  /// Error label
  static String error(String message) {
    return 'Error: $message';
  }

  /// Success label
  static String success(String message) {
    return 'Success: $message';
  }
}

/// Semantic wrapper widget for consistent accessibility
class SemanticWrapper extends StatelessWidget {
  const SemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.button = false,
    this.link = false,
    this.header = false,
    this.enabled = true,
    this.focusable = true,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool button;
  final bool link;
  final bool header;
  final bool enabled;
  final bool focusable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      link: link,
      header: header,
      enabled: enabled,
      focusable: focusable,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// Exclude from semantics helper
class ExcludeSemantics extends StatelessWidget {
  const ExcludeSemantics({
    super.key,
    required this.child,
    this.excluding = true,
  });

  final Widget child;
  final bool excluding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: excluding,
      child: child,
    );
  }
}

/// Merge semantics helper
class MergeSemantics extends StatelessWidget {
  const MergeSemantics({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: child,
    );
  }
}

/// Focus node helper
class FocusHelper {
  /// Request focus on a node
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Unfocus current node
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Move focus to next field
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous field
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }
}

/// Contrast checker widget for development
class ContrastChecker extends StatelessWidget {
  const ContrastChecker({
    super.key,
    required this.foreground,
    required this.background,
    required this.child,
    this.isLargeText = false,
  });

  final Color foreground;
  final Color background;
  final Widget child;
  final bool isLargeText;

  @override
  Widget build(BuildContext context) {
    final ratio = A11yHelpers.getContrastRatio(foreground, background);
    final meetsAA =
        A11yHelpers.meetsWCAGAA(foreground, background, isLargeText: isLargeText);

    // Only show warning in debug mode
    assert(() {
      if (!meetsAA) {
        debugPrint(
          'WARNING: Contrast ratio ${ratio.toStringAsFixed(2)}:1 does not meet WCAG AA standards',
        );
      }
      return true;
    }());

    return child;
  }
}

/// ARIA roles for web accessibility
enum AriaRole {
  button,
  link,
  navigation,
  main,
  article,
  banner,
  complementary,
  contentinfo,
  form,
  search,
  region,
  alert,
  status,
  dialog,
  menu,
  menuitem,
  tab,
  tabpanel,
  tree,
  treeitem,
}

/// Screen reader announcements
class ScreenReaderAnnouncements {
  /// Announce navigation
  static void announceNavigation(BuildContext context, String destination) {
    A11yHelpers.announce(context, 'Navigating to $destination');
  }

  /// Announce action
  static void announceAction(BuildContext context, String action) {
    A11yHelpers.announce(context, action);
  }

  /// Announce success
  static void announceSuccess(BuildContext context, String message) {
    A11yHelpers.announce(context, 'Success: $message');
  }

  /// Announce error
  static void announceError(BuildContext context, String message) {
    A11yHelpers.announce(context, 'Error: $message');
  }

  /// Announce loading
  static void announceLoading(BuildContext context, [String? item]) {
    final message = item != null ? 'Loading $item' : 'Loading';
    A11yHelpers.announce(context, message);
  }

  /// Announce loaded
  static void announceLoaded(BuildContext context, [String? item]) {
    final message = item != null ? '$item loaded' : 'Content loaded';
    A11yHelpers.announce(context, message);
  }
}
