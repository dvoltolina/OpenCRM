import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/external_portal_config.dart';
import 'package:the_scheduler/modules/admin/utils/web_links.dart';
import 'package:the_scheduler/modules/crm/utils/web_links.dart';

void main() {
  group('External portal links', () {
    test('uses the production admin portal URL by default', () {
      expect(
        ExternalPortalConfig.adminUri('/dashboard').toString(),
        'https://admin.example.com/dashboard',
      );
      expect(
        AdminWebLinks.teamManagement('business-1').toString(),
        'https://admin.example.com/staff',
      );
    });

    test('uses the production CRM portal URL by default', () {
      expect(ExternalPortalConfig.hasCrmPortal, isTrue);
      expect(
        ExternalPortalConfig.crmUri('/dashboard').toString(),
        'https://example.com/dashboard',
      );
      expect(
        CrmWebLinks.activities('business-1').toString(),
        'https://example.com/activities',
      );
    });
  });
}
