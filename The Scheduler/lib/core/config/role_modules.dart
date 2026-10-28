import 'module_config.dart';
import '../../data/models/user_role.dart';

/// Enumerated modules aligned to existing ModuleConfig IDs.
enum AppModule {
  dashboard('dashboard'),
  calendar('calendar'),
  clients('clients'),
  providers('providers'),
  services('services'),
  locations('locations'),
  timesheets('timesheets'),
  reports('reports'),
  settings('settings'),
  booking('booking'),
  groupSessions('group-sessions'),
  waitlist('waitlist'),
  communications('communications'),
  providerMode('provider-mode'),
  salesVisits('sales-visits'),
  clientPortal('client-portal'),
  quickSale('quick-sale'),
  products('products'),
  posHistory('pos-history');

  const AppModule(this.id);
  final String id;
}

/// Role-based module selection.
class RoleModules {
  static List<AppModule> getModulesForRole(UserRole role) {
    return switch (role) {
      UserRole.owner || UserRole.admin => _adminModules,
      UserRole.manager => _managerModules,
      UserRole.sales => _salesModules,
      UserRole.provider || UserRole.staff => _providerModules,
      UserRole.frontDesk => _frontDeskModules,
      UserRole.client => _clientModules,
    };
  }

  static List<ModuleConfig> filterModuleConfigs(
    List<ModuleConfig> modules,
    List<AppModule> allowed,
  ) {
    if (allowed.isEmpty) return const <ModuleConfig>[];
    final allowedIds = allowed.map((m) => m.id).toSet();
    return modules.where((m) => allowedIds.contains(m.id)).toList();
  }

  static const _adminModules = [
    AppModule.dashboard,
    AppModule.calendar,
    AppModule.clients,
    AppModule.providers,
    AppModule.services,
    AppModule.locations,
    AppModule.timesheets,
    AppModule.reports,
    AppModule.communications,
    AppModule.booking,
    AppModule.groupSessions,
    AppModule.waitlist,
    AppModule.settings,
  ];

  static const _managerModules = [
    AppModule.dashboard,
    AppModule.calendar,
    AppModule.clients,
    AppModule.providers,
    AppModule.timesheets,
    AppModule.reports,
    AppModule.booking,
    AppModule.waitlist,
  ];

  static const _salesModules = [
    AppModule.salesVisits,
    AppModule.clients,
    AppModule.calendar,
    AppModule.communications,
  ];

  static const _providerModules = [AppModule.providerMode];

  static const _frontDeskModules = [
    AppModule.booking,
    AppModule.clients,
    AppModule.calendar,
  ];

  static const _clientModules = [AppModule.clientPortal];
}
