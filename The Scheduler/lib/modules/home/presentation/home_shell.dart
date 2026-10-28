import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/config/module_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/onboarding_controller.dart';
import '../../../core/services/theme_mode_service.dart';
import '../../../core/ui/accessibility_helpers.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/ui/platform_helpers.dart';
import '../../../data/models/onboarding_state.dart';
import 'onboarding_flow.dart';
import 'widgets/subscription_gate.dart';
import 'widgets/bottom_nav_item.dart';
import 'widgets/drawer_item.dart';
import 'widgets/module_detail_pane.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _previousIndex = 0;
  final OnboardingController _onboardingController =
      OnboardingController.instance;
  String? _businessId;
  bool _initializedController = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Primary modules shown in bottom navigation
  static const List<String> _primaryModuleIds = [
    'dashboard',
    'calendar',
    'clients',
    'booking',
  ];

  void _onModuleSelected(int index) {
    if (_index == index) return;
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _navigateToSettings(List<ModuleConfig> m) {
    final i = m.indexWhere((x) => x.id == 'settings');
    if (i >= 0) _onModuleSelected(i);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedController) return;

    // Get businessId from security context (actual authenticated business)
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext != null) {
      _businessId = securityContext.businessId;
      _onboardingController.init(_businessId!);
      _initializedController = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final securityContext = ref.watch(securityContextProvider).valueOrNull;
    final filteredModules = ref.watch(availableModuleConfigsProvider);
    final modules = DemoConfig.isDemoMode ? config.modules : filteredModules;

    if (!_initializedController && securityContext != null) {
      _businessId = securityContext.businessId;
      _onboardingController.init(_businessId!);
      _initializedController = true;
    }

    if (modules.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No modules available for this role.')),
      );
    }

    final currentIndex = _index < modules.length ? _index : 0;
    final selectedModule = modules[currentIndex];

    final shell = KeyboardShortcuts(
      shortcuts: _buildKeyboardShortcuts(modules),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final useBottomNav = width < 720;
          final showDetailPane = width >= 1200;
          final extendRail = width >= 960;

          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: useBottomNav
                  ? IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      tooltip: 'Open menu',
                      onPressed: _openDrawer,
                    )
                  : null,
              titleSpacing: useBottomNav ? 0 : 16,
              title: Text(
                selectedModule.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              actions: [
                // Theme toggle
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeModeService.instance.themeMode,
                  builder: (context, themeMode, _) {
                    final isDark =
                        themeMode == ThemeMode.dark ||
                        (themeMode == ThemeMode.system &&
                            MediaQuery.platformBrightnessOf(context) ==
                                Brightness.dark);
                    return IconButton(
                      tooltip: isDark ? 'Light mode' : 'Dark mode',
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      onPressed: ThemeModeService.instance.toggleTheme,
                    );
                  },
                ),
                // Settings gear
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => _navigateToSettings(modules),
                ),
                // Onboarding (only show on desktop) - use GradientButton for premium feel
                if (!useBottomNav && !DemoConfig.isDemoMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ValueListenableBuilder<OnboardingState?>(
                      valueListenable: _onboardingController.state,
                      builder: (context, onboardingState, _) {
                        final isComplete = onboardingState?.isComplete ?? false;
                        return GradientButtonSmall(
                          onPressed: () => _launchOnboarding(context, config),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flag, size: 18),
                              const SizedBox(width: 6),
                              Text(isComplete ? 'Edit Setup' : 'Setup'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            drawer: useBottomNav
                ? _buildNavigationDrawer(context, modules, selectedModule.id)
                : null,
            bottomNavigationBar: useBottomNav
                ? _buildBottomNav(context, modules, currentIndex)
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!useBottomNav)
                    _buildRail(
                      context,
                      modules,
                      extended: extendRail,
                      currentIndex: currentIndex,
                    ),
                  if (!useBottomNav) const VerticalDivider(width: 1),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        // Slide from right if going forward, from left if going back
                        final isForward = currentIndex > _previousIndex;
                        final slideOffset = Tween<Offset>(
                          begin: Offset(isForward ? 0.05 : -0.05, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slideOffset,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(selectedModule.id),
                        child: selectedModule.builder(context),
                      ),
                    ),
                  ),
                  if (showDetailPane) ...[
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 280,
                      child: ModuleDetailPane(
                        module: selectedModule,
                        branding: config.branding,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    return SubscriptionGate(
      enabled: config.featureFlags.requirePaidSubscription,
      child: shell,
    );
  }

  /// Build keyboard shortcuts map for desktop navigation
  Map<LogicalKeySet, VoidCallback> _buildKeyboardShortcuts(
    List<ModuleConfig> modules,
  ) {
    if (!PlatformInfo.isDesktop) return {};

    final shortcuts = <LogicalKeySet, VoidCallback>{};

    // Cmd/Ctrl + 1-9 for module navigation
    for (var i = 0; i < modules.length && i < 9; i++) {
      final keySet = LogicalKeySet(
        PlatformInfo.isMacOS
            ? LogicalKeyboardKey.meta
            : LogicalKeyboardKey.control,
        LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i),
      );
      shortcuts[keySet] = () => _onModuleSelected(i);
    }

    // Cmd/Ctrl + N for new item (context-dependent)
    shortcuts[LogicalKeySet(
      PlatformInfo.isMacOS
          ? LogicalKeyboardKey.meta
          : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyN,
    )] = () {
      // Could be expanded to open context-specific new dialogs
      if (mounted) {
        ScreenReaderAnnouncements.announceAction(
          context,
          'New item shortcut (context dependent)',
        );
      }
    };

    // Cmd/Ctrl + K for search/command palette (future)
    shortcuts[LogicalKeySet(
      PlatformInfo.isMacOS
          ? LogicalKeyboardKey.meta
          : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyK,
    )] = () {
      if (mounted) {
        ScreenReaderAnnouncements.announceAction(
          context,
          'Search command palette (coming soon)',
        );
      }
    };

    return shortcuts;
  }

  Widget _buildRail(
    BuildContext context,
    List<ModuleConfig> modules, {
    required bool extended,
    required int currentIndex,
  }) {
    return Semantics(
      label: 'Main navigation',
      child: NavigationRail(
        selectedIndex: currentIndex,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        extended: extended,
        destinations: [
          for (final module in modules)
            NavigationRailDestination(
              icon: Icon(module.icon),
              label: Text(module.label),
            ),
        ],
        onDestinationSelected: _onModuleSelected,
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    List<ModuleConfig> modules,
    int currentIndex,
  ) {
    // Get primary modules that exist in the config
    final primaryModules = <ModuleConfig>[];
    for (final id in _primaryModuleIds) {
      final module = modules.where((m) => m.id == id).firstOrNull;
      if (module != null) {
        primaryModules.add(module);
      }
    }

    // Check if current selection is a primary module
    final isPrimarySelected =
        currentIndex < modules.length &&
        _primaryModuleIds.contains(modules[currentIndex].id);

    // Calculate selected index for bottom nav (-1 if not a primary module)
    int bottomNavIndex = -1;
    if (isPrimarySelected) {
      final currentModule = modules[currentIndex];
      bottomNavIndex = primaryModules.indexWhere(
        (m) => m.id == currentModule.id,
      );
    }

    final theme = Theme.of(context);
    final isMessagesSelected =
        currentIndex < modules.length &&
        modules[currentIndex].id == 'communications';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < primaryModules.length; i++)
                BottomNavItem(
                  icon: primaryModules[i].icon,
                  label: primaryModules[i].label,
                  isSelected: i == bottomNavIndex,
                  onTap: () {
                    final fullIndex = modules.indexWhere(
                      (m) => m.id == primaryModules[i].id,
                    );
                    if (fullIndex >= 0) {
                      _onModuleSelected(fullIndex);
                    }
                  },
                ),
              // Messages tab
              BottomNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                isSelected: isMessagesSelected,
                onTap: () {
                  // Navigate to messages/communications
                  final commIndex = modules.indexWhere(
                    (m) => m.id == 'communications',
                  );
                  if (commIndex >= 0) {
                    _onModuleSelected(commIndex);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDrawer(
    BuildContext context,
    List<ModuleConfig> modules,
    String selectedId,
  ) {
    final theme = Theme.of(context);
    final config = ref.read(appConfigProvider);
    final branding = config.branding;

    // Group modules by category (using actual module IDs from app_modules.dart)
    final coreModules = modules
        .where(
          (m) => ['dashboard', 'calendar', 'booking', 'clients'].contains(m.id),
        )
        .toList();
    final businessModules = modules
        .where(
          (m) => [
            'providers',
            'services',
            'locations',
            'waitlist',
            'group-sessions',
          ].contains(m.id),
        )
        .toList();
    final salesModules = modules
        .where((m) => ['products', 'quick-sale', 'pos-history'].contains(m.id))
        .toList();
    final adminModules = modules
        .where(
          (m) => [
            'timesheets',
            'reports',
            'settings',
            'communications',
          ].contains(m.id),
        )
        .toList();
    final portalModules = modules
        .where((m) => ['client-portal', 'provider-mode'].contains(m.id))
        .toList();
    final otherModules = modules
        .where(
          (m) => ![
            'dashboard',
            'calendar',
            'booking',
            'clients',
            'providers',
            'services',
            'locations',
            'waitlist',
            'group-sessions',
            'products',
            'quick-sale',
            'pos-history',
            'timesheets',
            'reports',
            'settings',
            'communications',
            'client-portal',
            'provider-mode',
          ].contains(m.id),
        )
        .toList();

    Widget buildSection(String title, List<ModuleConfig> sectionModules) {
      if (sectionModules.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...sectionModules.map(
            (module) => DrawerItem(
              icon: module.icon,
              label: module.label,
              isSelected: module.id == selectedId,
              onTap: () {
                final fullIndex = modules.indexWhere((m) => m.id == module.id);
                if (fullIndex >= 0) {
                  _onModuleSelected(fullIndex);
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      );
    }

    return Drawer(
      child: Column(
        children: [
          // Premium gradient header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [branding.primaryColor, branding.accentColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: branding.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branding.productName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                VSpace.xxs,
                Text(
                  branding.tagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable menu sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                buildSection('Core', coreModules),
                buildSection('Business', businessModules),
                buildSection('Sales & POS', salesModules),
                buildSection('Portals', portalModules),
                buildSection('Admin', adminModules),
                buildSection('Other', otherModules),
              ],
            ),
          ),
          // Settings quick access at bottom
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _navigateToSettings(modules);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 22),
                      label: const Text('Settings'),
                    ),
                  ),
                  ValueListenableBuilder<OnboardingState?>(
                    valueListenable: _onboardingController.state,
                    builder: (context, onboardingState, _) {
                      return TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _launchOnboarding(context, config);
                        },
                        icon: const Icon(Icons.flag_outlined, size: 22),
                        label: const Text('Setup'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchOnboarding(BuildContext context, AppConfig config) async {
    final sc = ref.read(securityContextProvider).valueOrNull;
    final bId = _businessId ?? sc?.businessId;
    if (bId == null || sc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load onboarding. Please try again.'),
        ),
      );
      return;
    }
    await showOnboardingFlow(
      context: context,
      ref: ref,
      config: config,
      businessId: bId,
      controller: _onboardingController,
      securityContext: sc,
    );
  }
}
