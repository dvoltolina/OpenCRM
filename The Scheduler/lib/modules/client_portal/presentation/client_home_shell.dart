import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/theme_mode_service.dart';
import '../../../core/services/customer_auth_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import '../../auth/presentation/portal_selection_page.dart';
import '../../messaging/presentation/widgets/messaging_icons.dart';
import 'client_order_history_page.dart';
import 'client_shop_page.dart';
import 'customer_profile_page.dart';
import 'group_sessions_page.dart';
import 'my_appointments_page.dart';
import 'my_billing_page.dart';
import 'my_intake_forms_page.dart';
import 'widgets/client_home_page.dart';
import 'widgets/client_portal_experience.dart';

/// Navigation shell for authenticated clients.
///
/// Provides a complete navigation experience with:
/// - Bottom navigation on mobile
/// - Navigation rail on tablet/desktop
/// - Theme toggle
/// - Sign out functionality
class ClientHomeShell extends ConsumerStatefulWidget {
  const ClientHomeShell({
    required this.businessId,
    super.key,
  });

  final String businessId;

  @override
  ConsumerState<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends ConsumerState<ClientHomeShell> {
  int _currentIndex = 0;
  late CustomerAuthService _customerAuthService;
  Client? _client;
  SecurityContext? _securityContext;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customerAuthService = ref.read(customerAuthServiceProvider);
    _loadClientProfile();
  }

  Future<void> _loadClientProfile() async {
    try {
      final client = await _customerAuthService.getCurrentClientProfile(
        businessId: widget.businessId,
      );

      final securityContext = await _customerAuthService.getCustomerSecurityContext(
        businessId: widget.businessId,
      );

      setState(() {
        _client = client;
        _securityContext = securityContext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _customerAuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PortalSelectionPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_client == null || _securityContext == null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useBottomNav = width < 720;
        final extendRail = width >= 960;

        return Scaffold(
          appBar: _buildAppBar(useBottomNav),
          drawer: useBottomNav ? _buildDrawer() : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!useBottomNav) _buildRail(extended: extendRail),
                if (!useBottomNav) const VerticalDivider(width: 1),
                Expanded(child: _buildCurrentPage()),
              ],
            ),
          ),
          bottomNavigationBar: useBottomNav ? _buildBottomNav() : null,
        );
      },
    );
  }

  AppBar _buildAppBar(bool useBottomNav) {
    final config = ref.watch(appConfigProvider);
    final branding = config.branding;
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: useBottomNav,
      titleSpacing: 0,
      // Gradient background for app bar using sophisticated blue palette
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              branding.primaryColor,
              branding.accentColor,
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          if (!useBottomNav) VSpace.md,
          Icon(Icons.person_rounded, color: Colors.white),
          HSpace.xs,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Client Portal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  branding.productName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Notifications and Messages
        if (_securityContext != null)
          Theme(
            data: theme.copyWith(
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            child: MessagingIcons(
              userId: _securityContext!.userId,
              securityContext: _securityContext!,
            ),
          ),
        // Theme toggle
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeModeService.instance.themeMode,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);
            return IconButton(
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              color: Colors.white,
              onPressed: ThemeModeService.instance.toggleTheme,
            );
          },
        ),
        // Sign out button
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          color: Colors.white,
          onPressed: _handleSignOut,
        ),
        HSpace.xs,
      ],
    );
  }

  Widget _buildRail({required bool extended}) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      extended: extended,
      destinations: _buildNavDestinations()
          .map((dest) => NavigationRailDestination(
                icon: dest.icon,
                selectedIcon: dest.selectedIcon,
                label: Text(dest.label),
              ))
          .toList(),
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      trailing: extended
          ? Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildClientInfo(),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: _buildNavDestinations(),
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final config = ref.watch(appConfigProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: config.branding.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _client!.initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                VSpace.sm,
                Text(
                  _client!.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (_client!.email != null)
                  Text(
                    _client!.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          ..._buildDrawerItems(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.of(context).pop();
              _handleSignOut();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    final destinations = _buildNavDestinations();
    return [
      for (var i = 0; i < destinations.length; i++)
        ListTile(
          leading: destinations[i].icon,
          title: Text(destinations[i].label),
          selected: i == _currentIndex,
          onTap: () {
            setState(() => _currentIndex = i);
            Navigator.of(context).pop();
          },
        ),
    ];
  }

  List<NavigationDestination> _buildNavDestinations() {
    final config = ref.watch(appConfigProvider);
    final featureFlags = config.featureFlags;

    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Appointments',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle),
        label: 'Book',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups),
        label: 'Classes',
      ),
      if (featureFlags.enableRetailSales)
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Shop',
        ),
      if (featureFlags.enableRetailSales)
        const NavigationDestination(
          icon: Icon(Icons.receipt_outlined),
          selectedIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Forms',
      ),
      if (featureFlags.enablePayments)
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Billing',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  Widget _buildCurrentPage() {
    final config = ref.watch(appConfigProvider);
    final featureFlags = config.featureFlags;

    // Build list of pages matching navigation destinations
    final pages = <Widget>[
      ClientHomePage(
        client: _client!,
        securityContext: _securityContext!,
        onNavigate: (index) => setState(() => _currentIndex = index),
        config: config,
      ),
      MyAppointmentsPage(securityContext: _securityContext!),
      const ClientPortalExperience(), // Book appointment
      GroupSessionsPage(config: config), // Group sessions/classes
      if (featureFlags.enableRetailSales)
        ClientShopPage(securityContext: _securityContext!, config: config),
      if (featureFlags.enableRetailSales)
        ClientOrderHistoryPage(securityContext: _securityContext!, config: config),
      MyIntakeFormsPage(securityContext: _securityContext!),
      if (featureFlags.enablePayments)
        MyBillingPage(securityContext: _securityContext!),
      CustomerProfilePage(
        securityContext: _securityContext!,
        client: _client!,
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: pages[_currentIndex],
      ),
    );
  }

  Widget _buildClientInfo() {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          child: Text(_client!.initials),
        ),
        VSpace.xs,
        Text(
          _client!.firstName,
          style: theme.textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Client Portal')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              VSpace.md,
              Text(
                'Unable to Load Profile',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              VSpace.xs,
              Text(
                'Your profile could not be found. Please contact support or try logging in again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              VSpace.lg,
              FilledButton.icon(
                onPressed: () async {
                  await _customerAuthService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const PortalSelectionPage()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
