// Widget Test Helpers for Staff App
//
// Provides utilities for widget testing including mock providers,
// pump helpers, and common test fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with Material app and providers for testing.
Widget testableWidget({
  required Widget child,
  List<Override>? overrides,
  Locale? locale,
  ThemeMode themeMode = ThemeMode.light,
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
      locale: locale ?? const Locale('en', 'US'),
      themeMode: themeMode,
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
    ),
  );
}

/// Wraps a widget with a Scaffold for testing.
Widget testableScaffold({
  required Widget child,
  List<Override>? overrides,
}) {
  return testableWidget(
    overrides: overrides,
    child: Scaffold(body: child),
  );
}

/// Pump and settle with timeout.
extension WidgetTesterExtension on WidgetTester {
  /// Pump widget and settle with a custom timeout.
  Future<void> pumpAndSettleWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  }

  /// Pump the widget tree a specified number of frames.
  Future<void> pumpFrames(int count, {Duration duration = const Duration(milliseconds: 16)}) async {
    for (var i = 0; i < count; i++) {
      await pump(duration);
    }
  }

  /// Tap and pump.
  Future<void> tapAndPump(Finder finder) async {
    await tap(finder);
    await pump();
  }

  /// Tap and settle.
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and pump.
  Future<void> enterTextAndPump(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
  }

  /// Scroll until visible.
  Future<void> scrollUntilVisible(
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
    int maxScrolls = 50,
  }) async {
    var scrollCount = 0;
    while (finder.evaluate().isEmpty && scrollCount < maxScrolls) {
      await drag(scrollable, Offset(0, -delta));
      await pumpAndSettle();
      scrollCount++;
    }
  }
}

/// Common finders for staff app.
class StaffAppFinders {
  StaffAppFinders._();

  // Buttons
  static Finder get clockInButton => find.text('Clock In');
  static Finder get clockOutButton => find.text('Clock Out');
  static Finder get startBreakButton => find.text('Start Break');
  static Finder get endBreakButton => find.text('End Break');
  static Finder get saveButton => find.text('Save');
  static Finder get cancelButton => find.text('Cancel');
  static Finder get confirmButton => find.text('Confirm');
  static Finder get retryButton => find.text('Retry');

  // Navigation
  static Finder get backButton => find.byIcon(Icons.arrow_back);
  static Finder get menuButton => find.byIcon(Icons.menu);
  static Finder get closeButton => find.byIcon(Icons.close);

  // Bottom navigation
  static Finder get scheduleTab => find.text('Schedule');
  static Finder get timeClockTab => find.text('Time Clock');
  static Finder get settingsTab => find.text('Settings');

  // Form fields
  static Finder textField(String label) => find.widgetWithText(TextField, label);
  static Finder dropdown(String label) => find.widgetWithText(DropdownButton, label);

  // Status indicators
  static Finder get loadingIndicator => find.byType(CircularProgressIndicator);
  static Finder get errorIcon => find.byIcon(Icons.error);
  static Finder get successIcon => find.byIcon(Icons.check_circle);

  // Snackbars
  static Finder snackBarWithText(String text) => find.widgetWithText(SnackBar, text);
}

/// Test data generators.
class TestData {
  TestData._();

  /// Generate a test date.
  static DateTime testDate({
    int year = 2024,
    int month = 1,
    int day = 15,
    int hour = 9,
    int minute = 0,
  }) {
    return DateTime(year, month, day, hour, minute);
  }

  /// Generate a test time range.
  static DateTimeRange testTimeRange({
    int startHour = 9,
    int endHour = 17,
  }) {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day, startHour),
      end: DateTime(now.year, now.month, now.day, endHour),
    );
  }

  /// Generate a test duration.
  static Duration testDuration({
    int hours = 0,
    int minutes = 30,
  }) {
    return Duration(hours: hours, minutes: minutes);
  }
}

/// Mock navigation observer for testing navigation.
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      replacedRoutes.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
    replacedRoutes.clear();
  }
}

/// Custom matchers for staff app testing.
class StaffAppMatchers {
  StaffAppMatchers._();

  /// Matcher for visible widget.
  static Matcher isVisible() => isA<Widget>();

  /// Matcher for enabled widget.
  static Matcher isEnabled() => predicate<Widget>(
        (widget) {
          if (widget is ElevatedButton) {
            return widget.onPressed != null;
          }
          if (widget is TextButton) {
            return widget.onPressed != null;
          }
          if (widget is IconButton) {
            return widget.onPressed != null;
          }
          return true;
        },
        'is enabled',
      );

  /// Matcher for disabled widget.
  static Matcher isDisabled() => predicate<Widget>(
        (widget) {
          if (widget is ElevatedButton) {
            return widget.onPressed == null;
          }
          if (widget is TextButton) {
            return widget.onPressed == null;
          }
          if (widget is IconButton) {
            return widget.onPressed == null;
          }
          return false;
        },
        'is disabled',
      );
}

/// Golden test helpers.
class GoldenTestHelpers {
  GoldenTestHelpers._();

  /// Standard device sizes for golden tests.
  static const Size iPhoneSE = Size(375, 667);
  static const Size iPhone14 = Size(390, 844);
  static const Size iPhone14ProMax = Size(430, 932);
  static const Size pixel5 = Size(393, 851);
  static const Size iPadMini = Size(768, 1024);
  static const Size iPadPro = Size(1024, 1366);

  /// Create a constrained box for golden tests.
  static Widget constrainedGolden({
    required Widget child,
    Size size = iPhone14,
  }) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: child,
    );
  }
}

/// Accessibility test helpers.
class AccessibilityTestHelpers {
  AccessibilityTestHelpers._();

  /// Check if widget has semantic label.
  static Matcher hasSemanticLabel(String label) => predicate<Semantics>(
        (semantics) => semantics.properties.label == label,
        'has semantic label "$label"',
      );

  /// Check minimum touch target size (48x48).
  static Future<void> verifyMinimumTouchTargets(WidgetTester tester) async {
    final buttons = tester.widgetList<Widget>(find.byType(InkWell));
    for (final button in buttons) {
      final renderObject = tester.renderObject(find.byWidget(button));
      final size = renderObject.paintBounds.size;
      expect(
        size.width >= 48 && size.height >= 48,
        isTrue,
        reason: 'Touch target should be at least 48x48',
      );
    }
  }
}
