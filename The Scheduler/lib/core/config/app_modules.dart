import 'package:flutter/material.dart';

import '../../modules/booking/presentation/booking_page.dart';
import '../../modules/calendar/presentation/calendar_page.dart';
import '../../modules/client_portal/presentation/client_portal_page.dart';
import '../../modules/clients/presentation/clients_page.dart';
import '../../modules/communications/presentation/communications_page.dart';
import '../../modules/locations/presentation/locations_page.dart';
import '../../modules/pos/presentation/products_page.dart';
import '../../modules/pos/presentation/quick_sale_page.dart';
import '../../modules/pos/presentation/transaction_history_page.dart';
import '../../modules/sales_visits/presentation/sales_visits_page.dart';
import '../../modules/provider_mode/presentation/provider_mode_page.dart';
import '../../modules/providers/presentation/providers_page.dart';
import '../../modules/staff/presentation/timesheets_page.dart';
import '../../modules/dashboard/presentation/dashboard_page.dart';
import '../../modules/booking/presentation/group_sessions_admin_page.dart';
import '../../modules/reports/presentation/reports_page.dart';
import '../../modules/services/presentation/services_page.dart';
import '../../modules/settings/presentation/settings_page.dart';
import '../../modules/waitlist/presentation/waitlist_page.dart';
import 'feature_flags.dart';
import 'module_config.dart';

List<ModuleConfig> buildDefaultModules({FeatureFlags? featureFlags}) {
  final modules = [
    ModuleConfig(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      description: 'KPIs & quick insights',
      builder: (_) => const DashboardPage(),
    ),
    // Legacy compatibility entry for HomeShell/demo flows. Authenticated
    // provider/staff users route directly to Provider Mode via RoleRouter.
    if (featureFlags?.enableProviderMode ?? false)
      ModuleConfig(
        id: 'provider-mode',
        label: 'Provider',
        icon: Icons.local_hospital_outlined,
        description: 'Staff schedule & tools',
        builder: (_) => const ProviderModePage(),
      ),
    ModuleConfig(
      id: 'booking',
      label: 'Booking',
      icon: Icons.event_available,
      description: 'Incoming requests & approvals',
      builder: (_) => const BookingPage(),
    ),
    ModuleConfig(
      id: 'group-sessions',
      label: 'Group Sessions',
      icon: Icons.groups_outlined,
      description: 'Manage classes and attendees',
      builder: (_) => const GroupSessionsAdminPage(),
    ),
    if (featureFlags?.enableWaitlist ?? false)
      ModuleConfig(
        id: 'waitlist',
        label: 'Waitlist',
        icon: Icons.hourglass_bottom_outlined,
        description: 'Hold requests and auto-fill openings',
        builder: (_) => const WaitlistPage(),
      ),
    ModuleConfig(
      id: 'clients',
      label: 'Clients',
      icon: Icons.people_alt_outlined,
      description: 'Client CRM light profile',
      builder: (_) => const ClientsPage(),
    ),
    if (featureFlags?.enableSalesVisits ?? false)
      ModuleConfig(
        id: 'sales-visits',
        label: 'Sales Visits',
        icon: Icons.route_outlined,
        description: 'Sales visits list with map handoff',
        builder: (_) => const SalesVisitsPage(),
      ),
    ModuleConfig(
      id: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_today,
      description: 'Internal availability controls',
      builder: (_) => const CalendarPage(),
    ),
    ModuleConfig(
      id: 'providers',
      label: 'Providers',
      icon: Icons.badge_outlined,
      description: 'Manage staff, specialties, and assignments',
      builder: (_) => const ProvidersPage(),
    ),
    if (featureFlags?.enableTimesheets ?? true)
      ModuleConfig(
        id: 'timesheets',
        label: 'Timesheets',
        icon: Icons.schedule_outlined,
        description: 'Review and approve staff time entries',
        builder: (_) => const TimesheetsPage(),
      ),
    ModuleConfig(
      id: 'services',
      label: 'Services',
      icon: Icons.design_services_outlined,
      description: 'Service catalog, durations, and pricing',
      builder: (_) => const ServicesPage(),
    ),
    ModuleConfig(
      id: 'locations',
      label: 'Locations',
      icon: Icons.location_city_outlined,
      description: 'Location details and resources',
      builder: (_) => const LocationsPage(),
    ),
    ModuleConfig(
      id: 'communications',
      label: 'Comms',
      icon: Icons.sms_outlined,
      description: 'Notifications & templates',
      builder: (_) => const CommunicationsPage(),
    ),
    ModuleConfig(
      id: 'reports',
      label: 'Reports',
      icon: Icons.insights_outlined,
      description: 'Utilization & KPIs',
      builder: (_) => const ReportsPage(),
    ),
    ModuleConfig(
      id: 'settings',
      label: 'Settings',
      icon: Icons.tune,
      description: 'Branding & feature toggles',
      builder: (_) => const SettingsPage(),
    ),
  ];

  // Add POS modules if enabled (Agent FC-J, FC-K)
  if (featureFlags?.enablePOS ?? false) {
    // Insert after Services module
    final servicesIndex = modules.indexWhere((m) => m.id == 'services');
    final insertIndex = servicesIndex >= 0
        ? servicesIndex + 1
        : modules.length - 1;

    // Quick Sale (POS register) - main selling interface
    modules.insert(
      insertIndex,
      ModuleConfig(
        id: 'quick-sale',
        label: 'Quick Sale',
        icon: Icons.point_of_sale,
        description: 'POS register for retail sales',
        builder: (_) => const QuickSalePage(),
      ),
    );

    // Products - product catalog and inventory management
    modules.insert(
      insertIndex + 1,
      ModuleConfig(
        id: 'products',
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        description: 'Retail product catalog & inventory',
        builder: (_) => const ProductsPage(),
      ),
    );

    // Transaction History - POS sales history (in settings submenu or standalone)
    modules.insert(
      insertIndex + 2,
      ModuleConfig(
        id: 'pos-history',
        label: 'Sales History',
        icon: Icons.receipt_long,
        description: 'View past POS transactions',
        builder: (_) => const TransactionHistoryPage(),
      ),
    );
  }

  if (featureFlags?.enableClientPortal ?? true) {
    modules.insert(
      2,
      ModuleConfig(
        id: 'client-portal',
        label: 'Client Portal',
        icon: Icons.public,
        description: 'Self-service booking preview',
        builder: (_) => const ClientPortalPage(),
      ),
    );
  }

  return modules;
}
