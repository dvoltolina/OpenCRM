import '../../../core/config/external_portal_config.dart';

/// Helper class for opening CRM links in the external browser.
class CrmWebLinks {
  static Uri? dashboard(String businessId) =>
      ExternalPortalConfig.crmUri('/dashboard');

  static Uri? leads(String businessId) => ExternalPortalConfig.crmUri('/leads');

  static Uri? deals(String businessId) => ExternalPortalConfig.crmUri('/deals');

  static Uri? activities(String businessId) =>
      ExternalPortalConfig.crmUri('/activities');

  static Future<bool> open(Uri? uri) async {
    if (uri == null) {
      return false;
    }
    return ExternalPortalConfig.openExternal(uri);
  }

  static Future<bool> openDashboard(String businessId) async {
    return open(dashboard(businessId));
  }

  static Future<bool> openLeads(String businessId) async {
    return open(leads(businessId));
  }

  static Future<bool> openDeals(String businessId) async {
    return open(deals(businessId));
  }

  static Future<bool> openActivities(String businessId) async {
    return open(activities(businessId));
  }
}
