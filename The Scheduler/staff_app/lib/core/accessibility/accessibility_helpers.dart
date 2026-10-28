// Accessibility Helpers for Staff App
//
// Provides semantic labels, focus management, and accessibility
// utilities to ensure the app is usable with screen readers and
// other assistive technologies.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Semantic labels for common UI elements.
class SemanticLabels {
  SemanticLabels._();

  // Navigation
  static const String backButton = 'Go back';
  static const String closeButton = 'Close';
  static const String menuButton = 'Open menu';
  static const String searchButton = 'Search';
  static const String refreshButton = 'Refresh';

  // Time Clock
  static const String clockInButton = 'Clock in to start your shift';
  static const String clockOutButton = 'Clock out to end your shift';
  static const String startBreakButton = 'Start break';
  static const String endBreakButton = 'End break';

  // Schedule
  static const String previousDayButton = 'Go to previous day';
  static const String nextDayButton = 'Go to next day';
  static const String todayButton = 'Go to today';

  // Appointments
  static const String acceptAppointment = 'Accept this appointment';
  static const String declineAppointment = 'Decline this appointment';
  static const String viewAppointmentDetails = 'View appointment details';
}

/// Accessibility-enhanced button wrapper.
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.hint,
    this.isEnabled = true,
    this.isSelected = false,
    this.excludeSemantics = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? hint;
  final bool isEnabled;
  final bool isSelected;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      label: semanticLabel,
      hint: hint,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }
}

/// Accessibility-enhanced card for list items.
class AccessibleListTile extends StatelessWidget {
  const AccessibleListTile({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.hint,
    this.onTap,
    this.isSelected = false,
    this.isHeader = false,
  });

  final Widget child;
  final String semanticLabel;
  final String? hint;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      header: isHeader,
      label: semanticLabel,
      hint: hint,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Time display with accessibility support.
class AccessibleTimeDisplay extends StatelessWidget {
  const AccessibleTimeDisplay({
    super.key,
    required this.time,
    required this.label,
    this.style,
  });

  final DateTime time;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTimeForAccessibility(time);

    return Semantics(
      label: '$label: $formattedTime',
      child: ExcludeSemantics(
        child: Text(
          _formatTimeForDisplay(time),
          style: style,
        ),
      ),
    );
  }

  String _formatTimeForDisplay(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeForAccessibility(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute;

    if (minute == 0) {
      return '${hour == 0 ? 12 : hour} $period';
    } else if (minute == 30) {
      return '${hour == 0 ? 12 : hour} thirty $period';
    } else {
      return '${hour == 0 ? 12 : hour} ${_numberToWords(minute)} $period';
    }
  }

  String _numberToWords(int number) {
    const teens = [
      'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
      'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty',
    ];
    const ones = [
      '', 'one', 'two', 'three', 'four', 'five',
      'six', 'seven', 'eight', 'nine',
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    final tenPart = number ~/ 10;
    final onePart = number % 10;
    if (onePart == 0) return tens[tenPart];
    return '${tens[tenPart]} ${ones[onePart]}';
  }
}

/// Duration display with accessibility support.
class AccessibleDurationDisplay extends StatelessWidget {
  const AccessibleDurationDisplay({
    super.key,
    required this.duration,
    required this.label,
    this.style,
  });

  final Duration duration;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formattedDuration = _formatDurationForAccessibility(duration);

    return Semantics(
      label: '$label: $formattedDuration',
      child: ExcludeSemantics(
        child: Text(
          _formatDurationForDisplay(duration),
          style: style,
        ),
      ),
    );
  }

  String _formatDurationForDisplay(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDurationForAccessibility(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (parts.isEmpty) {
      return '0 minutes';
    }
    return parts.join(' and ');
  }
}

/// Status indicator with accessibility support.
class AccessibleStatusIndicator extends StatelessWidget {
  const AccessibleStatusIndicator({
    super.key,
    required this.status,
    required this.color,
    this.size = 12.0,
  });

  final String status;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $status',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Focus management utilities.
class FocusHelper {
  FocusHelper._();

  /// Move focus to the next focusable element.
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to the previous focusable element.
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Request focus on a specific node.
  static void requestFocus(FocusNode node) {
    node.requestFocus();
  }

  /// Unfocus the current element.
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Check if any element is focused.
  static bool hasFocus(BuildContext context) {
    return FocusScope.of(context).hasFocus;
  }
}

/// Announce a message to screen readers.
void announceToScreenReader(BuildContext context, String message) {
  // ignore: deprecated_member_use
  SemanticsService.announce(message, TextDirection.ltr);
}

/// Semantic group for related elements.
class SemanticGroup extends StatelessWidget {
  const SemanticGroup({
    super.key,
    required this.label,
    required this.children,
    this.hint,
  });

  final String label;
  final List<Widget> children;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: label,
        hint: hint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// High contrast mode detection.
extension AccessibilityExtension on BuildContext {
  /// Whether high contrast mode is enabled.
  bool get isHighContrastMode {
    return MediaQuery.of(this).highContrast;
  }

  /// Whether reduced motion is preferred.
  bool get prefersReducedMotion {
    return MediaQuery.of(this).disableAnimations;
  }

  /// Whether bold text is enabled.
  bool get isBoldTextEnabled {
    return MediaQuery.of(this).boldText;
  }

  /// Current text scale factor.
  double get textScaleFactor {
    return MediaQuery.textScalerOf(this).scale(1.0);
  }

  /// Whether screen reader is likely active.
  bool get isScreenReaderActive {
    return MediaQuery.of(this).accessibleNavigation;
  }
}

/// Accessibility-aware animation duration.
Duration getAccessibleAnimationDuration(
  BuildContext context, {
  Duration normalDuration = const Duration(milliseconds: 300),
}) {
  if (context.prefersReducedMotion) {
    return Duration.zero;
  }
  return normalDuration;
}

/// Minimum touch target size (48x48 per WCAG).
const double kMinTouchTargetSize = 48.0;

/// Ensure minimum touch target size.
class MinimumTouchTarget extends StatelessWidget {
  const MinimumTouchTarget({
    super.key,
    required this.child,
    this.minSize = kMinTouchTargetSize,
  });

  final Widget child;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Center(child: child),
    );
  }
}
