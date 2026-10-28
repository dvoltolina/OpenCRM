import '../../../core/config/external_portal_config.dart';

/// Helper class for opening admin web dashboard links.
///
/// The admin web dashboard is a separate React app that provides
/// full business management capabilities. The mobile app is for
/// on-the-go oversight, with links to web for complex operations.
class AdminWebLinks {
  /// Main dashboard URL for a business.
  static Uri dashboard(String businessId) =>
      ExternalPortalConfig.adminUri('/dashboard');

  /// Settings page URL.
  static Uri settings(String businessId) =>
      ExternalPortalConfig.adminUri('/settings');

  /// Team management URL (full staff CRUD).
  static Uri teamManagement(String businessId) =>
      ExternalPortalConfig.adminUri('/staff');

  /// Billing and subscription URL.
  static Uri billing(String businessId) =>
      ExternalPortalConfig.adminUri('/billing');

  /// Open a URL in external browser.
  ///
  /// Returns true if successful, false otherwise.
  static Future<bool> open(Uri uri) async {
    return ExternalPortalConfig.openExternal(uri);
  }

  /// Open dashboard for business.
  static Future<bool> openDashboard(String businessId) async {
    return open(dashboard(businessId));
  }

  /// Open settings for business.
  static Future<bool> openSettings(String businessId) async {
    return open(settings(businessId));
  }

  /// Open team management for business.
  static Future<bool> openTeamManagement(String businessId) async {
    return open(teamManagement(businessId));
  }

  /// Open billing for business.
  static Future<bool> openBilling(String businessId) async {
    return open(billing(businessId));
  }
}
