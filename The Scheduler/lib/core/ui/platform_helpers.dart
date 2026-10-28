// Platform-specific helpers and adaptive widgets
// Agent 8: Mobile & UI Polish
// Provides platform-aware UI components

import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

/// Platform detection utilities
class PlatformInfo {
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  static bool get isMobile => isIOS || isAndroid;

  /// Should use Cupertino widgets
  static bool get useCupertino => isIOS || isMacOS;

  /// Should use Material widgets
  static bool get useMaterial => !useCupertino;

  /// Get platform name for display
  static String get platformName {
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isWeb) return 'Web';
    return 'Unknown';
  }
}

/// Adaptive button that uses native style per platform
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
    this.isDefaultAction = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isDestructive;
  final bool isDefaultAction;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.useCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        color: isDefaultAction
            ? CupertinoColors.activeBlue
            : isDestructive
                ? CupertinoColors.destructiveRed
                : null,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Theme.of(context).colorScheme.error
            : isDefaultAction
                ? Theme.of(context).colorScheme.primary
                : null,
      ),
      child: child,
    );
  }
}

/// Adaptive switch
class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.useCupertino) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }

    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Adaptive loading indicator
class AdaptiveLoadingIndicator extends StatelessWidget {
  const AdaptiveLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.useCupertino) {
      return const CupertinoActivityIndicator();
    }

    return const CircularProgressIndicator();
  }
}

/// Adaptive text field
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.useCupertino) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }
}

/// Show adaptive dialog
Future<T?> showAdaptiveDialogHelper<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AlertDialogAction<T>> actions,
}) {
  return showAlertDialog<T>(
    context: context,
    title: title,
    message: message,
    actions: actions,
  );
}

/// Show adaptive confirmation dialog
Future<bool> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String okLabel = 'OK',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showOkCancelAlertDialog(
    context: context,
    title: title,
    message: message,
    okLabel: okLabel,
    cancelLabel: cancelLabel,
    isDestructiveAction: isDestructive,
  );

  return result == OkCancelResult.ok;
}

/// Show adaptive text input dialog
Future<String?> showAdaptiveTextInputDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? placeholder,
  String? initialText,
  String okLabel = 'OK',
  String cancelLabel = 'Cancel',
  TextInputType? keyboardType,
}) {
  return showTextInputDialog(
    context: context,
    title: title,
    message: message,
    textFields: [
      DialogTextField(
        hintText: placeholder,
        initialText: initialText,
        keyboardType: keyboardType,
      ),
    ],
    okLabel: okLabel,
    cancelLabel: cancelLabel,
  ).then((result) => result?.first);
}

/// Keyboard shortcut helper for desktop
class KeyboardShortcutHelper {
  /// Map of shortcuts to actions
  static final Map<LogicalKeySet, VoidCallback> _shortcuts = {};

  /// Register a shortcut
  static void register(LogicalKeySet keys, VoidCallback action) {
    _shortcuts[keys] = action;
  }

  /// Unregister a shortcut
  static void unregister(LogicalKeySet keys) {
    _shortcuts.remove(keys);
  }

  /// Clear all shortcuts
  static void clear() {
    _shortcuts.clear();
  }

  /// Get all registered shortcuts
  static Map<LogicalKeySet, VoidCallback> get shortcuts => _shortcuts;
}

/// Widget that handles keyboard shortcuts
class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    super.key,
    required this.shortcuts,
    required this.child,
  });

  final Map<LogicalKeySet, VoidCallback> shortcuts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformInfo.isDesktop) {
      return child;
    }

    return Shortcuts(
      shortcuts: shortcuts.map(
        (key, value) => MapEntry(key, _VoidCallbackIntent(value)),
      ),
      child: Actions(
        actions: {
          _VoidCallbackIntent: _VoidCallbackAction(),
        },
        child: child,
      ),
    );
  }
}

/// Intent for void callbacks
class _VoidCallbackIntent extends Intent {
  const _VoidCallbackIntent(this.callback);

  final VoidCallback callback;
}

/// Action for void callbacks
class _VoidCallbackAction extends Action<_VoidCallbackIntent> {
  @override
  Object? invoke(_VoidCallbackIntent intent) {
    intent.callback();
    return null;
  }
}

/// Touch target size constants
class TouchTargets {
  /// Minimum touch target size (48x48 per Material Design)
  static const double minimum = 48.0;

  /// Comfortable touch target size
  static const double comfortable = 56.0;

  /// Large touch target for primary actions
  static const double large = 64.0;

  /// Ensure widget meets minimum touch target
  static Widget ensure({required Widget child, double size = minimum}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      child: child,
    );
  }
}

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static String currentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return 'mobile';
    if (width < desktop) return 'tablet';
    return 'desktop';
  }
}

