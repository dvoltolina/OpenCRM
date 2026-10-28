// AppPageScaffold - Unified page layout foundation
// Created by Agent P0 (2025-11-28)
// Provides consistent page structure for all app pages

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Standard page scaffold with consistent layout and spacing
///
/// Provides unified structure for all app pages with:
/// - Left-aligned AppBar title
/// - Standard page padding
/// - SafeArea wrapping
/// - Optional floating action button
///
/// Usage:
/// ```dart
/// AppPageScaffold(
///   title: 'Calendar',
///   actions: [
///     IconButton(icon: Icon(Icons.add), onPressed: _addNew),
///   ],
///   body: Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       // Page content
///     ],
///   ),
///   floatingActionButton: FloatingActionButton(
///     onPressed: _addNew,
///     child: Icon(Icons.add),
///   ),
/// )
/// ```
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showAppBar = true,
    this.backgroundColor,
    this.addPagePadding = true,
    this.sidebar,
    this.sidebarBreakpoint = 960,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool addPagePadding;
  final Widget? sidebar;
  final double sidebarBreakpoint;

  @override
  Widget build(BuildContext context) {
    final child = addPagePadding
        ? Padding(padding: AppSpacing.pagePadding, child: body)
        : body;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = sidebar != null && constraints.maxWidth >= sidebarBreakpoint;

        return Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text(title),
                  centerTitle: false, // LEFT-ALIGNED titles per design system
                  elevation: 0,
                  actions: actions,
                  automaticallyImplyLeading: showBackButton || !isWide && sidebar != null,
                )
              : null,
          drawer: !isWide && sidebar != null
              ? Drawer(
                  child: SafeArea(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: sidebar,
                    ),
                  ),
                )
              : null,
          backgroundColor: backgroundColor,
          body: SafeArea(
            top: !showAppBar,
            child: isWide && sidebar != null
                ? Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: sidebar!,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  )
                : child,
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}

/// Scrollable page scaffold for content that may overflow
///
/// Same as AppPageScaffold but wraps body in SingleChildScrollView
/// Use when page content may exceed screen height
class ScrollablePageScaffold extends StatelessWidget {
  const ScrollablePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showAppBar = true,
    this.backgroundColor,
    this.addPagePadding = true,
    this.sidebar,
    this.sidebarBreakpoint = 960,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showAppBar;
  final Color? backgroundColor;
  final bool addPagePadding;
  final Widget? sidebar;
  final double sidebarBreakpoint;

  @override
  Widget build(BuildContext context) {
    final scrollable = SingleChildScrollView(
      child: addPagePadding
          ? Padding(padding: AppSpacing.pagePadding, child: body)
          : body,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = sidebar != null && constraints.maxWidth >= sidebarBreakpoint;

        return Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text(title),
                  centerTitle: false,
                  elevation: 0,
                  actions: actions,
                  automaticallyImplyLeading: showBackButton || !isWide && sidebar != null,
                )
              : null,
          drawer: !isWide && sidebar != null
              ? Drawer(
                  child: SafeArea(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: sidebar,
                    ),
                  ),
                )
              : null,
          backgroundColor: backgroundColor,
          body: SafeArea(
            top: !showAppBar,
            child: isWide && sidebar != null
                ? Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: sidebar!,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: scrollable),
                    ],
                  )
                : scrollable,
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}

/// Page scaffold with tab bar
///
/// Provides AppBar with integrated TabBar for multi-tab pages
class TabbedPageScaffold extends StatelessWidget {
  const TabbedPageScaffold({
    super.key,
    required this.title,
    required this.tabs,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showAppBar = true,
    this.backgroundColor,
    this.sidebar,
    this.sidebarBreakpoint = 960,
  });

  final String title;
  final List<Widget> tabs;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showAppBar;
  final Color? backgroundColor;
  final Widget? sidebar;
  final double sidebarBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = sidebar != null && constraints.maxWidth >= sidebarBreakpoint;

        return Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text(title),
                  centerTitle: false, // LEFT-ALIGNED titles per design system
                  elevation: 0,
                  actions: actions,
                  automaticallyImplyLeading: showBackButton || !isWide && sidebar != null,
                  bottom: TabBar(tabs: tabs),
                )
              : null,
          drawer: !isWide && sidebar != null
              ? Drawer(
                  child: SafeArea(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: sidebar,
                    ),
                  ),
                )
              : null,
          backgroundColor: backgroundColor,
          body: SafeArea(
            top: !showAppBar,
            child: isWide && sidebar != null
                ? Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Padding(
                          padding: AppSpacing.pagePadding,
                          child: sidebar!,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  )
                : body,
          ),
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
