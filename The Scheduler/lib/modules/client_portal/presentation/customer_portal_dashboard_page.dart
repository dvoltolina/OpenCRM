import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/client.dart';
import '../../../data/models/security_context.dart';
import '../../../core/utils/secure_error_handler.dart';
import 'my_appointments_page.dart';
import 'my_billing_page.dart';
import 'my_intake_forms_page.dart';
import 'customer_profile_page.dart';

/// Customer Portal Dashboard Page - Main navigation hub for authenticated customers
///
/// Features:
/// - Bottom navigation bar with 4 main sections:
///   - Appointments: View upcoming/past appointments
///   - Billing: View payment history and receipts
///   - Forms: View intake form submissions and drafts
///   - Profile: Manage profile and preferences
/// - Quick actions for common tasks
/// - Greeting with customer name
///
/// Requires authenticated customer with SecurityContext and Client profile
class CustomerPortalDashboardPage extends ConsumerStatefulWidget {
  const CustomerPortalDashboardPage({
    required this.securityContext,
    super.key,
  });

  final SecurityContext securityContext;

  @override
  ConsumerState<CustomerPortalDashboardPage> createState() =>
      _CustomerPortalDashboardPageState();
}

class _CustomerPortalDashboardPageState
    extends ConsumerState<CustomerPortalDashboardPage> {
  int _currentIndex = 0;
  Client? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
  }

  Future<void> _loadClientProfile() async {
    final customerAuthService = ref.read(customerAuthServiceProvider);
    try {
      final client = await customerAuthService.getCurrentClientProfile(
        businessId: widget.securityContext.businessId,
      );

      setState(() {
        _client = client;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure Riverpod security context is loaded for downstream widgets.
    ref.watch(securityContextProvider);

    if (_isLoading) {
      return const AppPageScaffold(
        title: 'Customer Portal',
        showBackButton: false,
        showAppBar: false,
        addPagePadding: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_client == null) {
      return AppPageScaffold(
        title: 'Customer Portal',
        showBackButton: false,
        body: _buildErrorState(),
      );
    }

    final pages = [
      MyAppointmentsPage(securityContext: widget.securityContext),
      MyBillingPage(securityContext: widget.securityContext),
      MyIntakeFormsPage(securityContext: widget.securityContext),
      CustomerProfilePage(
        securityContext: widget.securityContext,
        client: _client!,
      ),
    ];

    return AppPageScaffold(
      title: 'Customer Portal',
      showBackButton: false,
      showAppBar: false,
      addPagePadding: false,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event),
                  label: 'Appointments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Billing',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Forms',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final customerAuthService = ref.read(customerAuthServiceProvider);
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Unable to Load Profile',
              subtitle: SecureErrorHandler.loadingFailed,
            ),
            VSpace.lg,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await customerAuthService.signOut();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
