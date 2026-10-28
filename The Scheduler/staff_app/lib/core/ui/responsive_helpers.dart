// Responsive design helpers and pull-to-refresh
// Agent 8: Mobile & UI Polish
// Mobile-first responsive utilities

import 'package:flutter/material.dart';

/// Responsive value selector based on screen size
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 1200) return desktop ?? tablet ?? mobile;
  if (width >= 600) return tablet ?? mobile;
  return mobile;
}

/// Responsive padding
EdgeInsets responsivePadding(
  BuildContext context, {
  double mobile = 16.0,
  double? tablet,
  double? desktop,
}) {
  final value = responsiveValue(
    context,
    mobile: mobile,
    tablet: tablet ?? mobile * 1.5,
    desktop: desktop ?? mobile * 2,
  );
  return EdgeInsets.all(value);
}

/// Responsive grid columns
int responsiveColumns(
  BuildContext context, {
  int mobile = 1,
  int? tablet,
  int? desktop,
}) {
  return responsiveValue(
    context,
    mobile: mobile,
    tablet: tablet ?? mobile * 2,
    desktop: desktop ?? mobile * 3,
  );
}

/// Pull to refresh wrapper
class PullToRefreshWrapper extends StatelessWidget {
  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}

/// Scrollable wrapper that ensures pull-to-refresh works even with not enough content
class ScrollableRefreshWrapper extends StatelessWidget {
  const ScrollableRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: child,
        ),
      ),
    );
  }
}

/// One-handed reachability wrapper for mobile
class OneHandedWrapper extends StatelessWidget {
  const OneHandedWrapper({
    super.key,
    required this.child,
    this.showOnMobileOnly = true,
  });

  final Widget child;
  final bool showOnMobileOnly;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (showOnMobileOnly && !isMobile) {
      return child;
    }

    // Add bottom padding to make top content reachable with thumb
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: child),
          // Thumb zone helper (invisible)
          const SizedBox(height: 56),
        ],
      ),
    );
  }
}

/// Responsive layout builder
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        }

        if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        }

        return mobile;
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16.0,
    this.aspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double aspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final columns = responsiveColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: children.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row/column switcher
class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.breakpoint = 600.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isRow = width >= breakpoint;

    if (isRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// Responsive font size
double responsiveFontSize(
  BuildContext context, {
  required double mobile,
  double? tablet,
  double? desktop,
}) {
  return responsiveValue(
    context,
    mobile: mobile,
    tablet: tablet ?? mobile * 1.1,
    desktop: desktop ?? mobile * 1.2,
  );
}

/// Responsive icon size
double responsiveIconSize(
  BuildContext context, {
  double mobile = 24.0,
  double? tablet,
  double? desktop,
}) {
  return responsiveValue(
    context,
    mobile: mobile,
    tablet: tablet ?? mobile * 1.2,
    desktop: desktop ?? mobile * 1.4,
  );
}

/// Screen size utilities
class ScreenSize {
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static EdgeInsets safeArea(BuildContext context) =>
      MediaQuery.of(context).padding;

  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  static double topSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  /// Get keyboard height
  static double keyboardHeight(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;
}

/// Safe area wrapper with customization
class SafeAreaWrapper extends StatelessWidget {
  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );
  }
}

/// Keyboard dismisser
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: child,
    );
  }
}

/// Orientation builder
class OrientationAwareBuilder extends StatelessWidget {
  const OrientationAwareBuilder({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  final Widget portrait;
  final Widget landscape;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }
}

