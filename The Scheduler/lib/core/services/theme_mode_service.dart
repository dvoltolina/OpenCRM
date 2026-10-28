import 'package:flutter/material.dart';

/// Service for managing theme mode (light/dark) across the application
/// Provides ValueNotifier for reactive theme changes
class ThemeModeService {
  ThemeModeService._();

  static final ThemeModeService instance = ThemeModeService._();

  /// Current theme mode notifier - defaults to light for clean white UI
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// Toggle between light and dark mode (ignores system)
  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }

  /// Check if currently using dark mode based on brightness
  bool isDarkMode(BuildContext context) {
    if (themeMode.value == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  /// Dispose the service (cleanup)
  void dispose() {
    themeMode.dispose();
  }
}
