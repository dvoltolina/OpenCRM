import 'package:url_launcher/url_launcher.dart';

/// Centralized web portal URLs for companion apps.
///
/// These are environment-overridable so mobile builds can point at staging or
/// production web apps without scattering hard-coded URLs through feature code.
class ExternalPortalConfig {
  static const String adminBaseUrl = String.fromEnvironment(
    'ADMIN_PORTAL_BASE_URL',
    defaultValue: 'https://admin.example.com',
  );

  static const String crmBaseUrl = String.fromEnvironment(
    'CRM_PORTAL_BASE_URL',
    defaultValue: 'https://example.com',
  );

  static bool get hasCrmPortal => crmBaseUrl.trim().isNotEmpty;

  static Uri adminUri(String path) => _buildUri(adminBaseUrl, path);

  static Uri? crmUri(String path) =>
      hasCrmPortal ? _buildUri(crmBaseUrl, path) : null;

  static Future<bool> openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Uri _buildUri(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
