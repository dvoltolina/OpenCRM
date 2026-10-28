import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/core/config/module_config.dart';
import 'package:the_scheduler/core/config/role_modules.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/data/models/user_role.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Role module alignment', () {
    test('provider and staff only expose provider mode in HomeShell', () {
      expect(
        RoleModules.getModulesForRole(UserRole.provider),
        equals(const [AppModule.providerMode]),
      );
      expect(
        RoleModules.getModulesForRole(UserRole.staff),
        equals(const [AppModule.providerMode]),
      );
    });

    test(
      'availableModuleConfigsProvider fails closed when no allowed module exists',
      () async {
        final config = TestData.createTestConfig().copyWith(
          modules: [
            ModuleConfig(
              id: 'dashboard',
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              description: 'Test dashboard',
              builder: (_) => const SizedBox.shrink(),
            ),
          ],
        );

        final providerProfile = UserProfile(
          id: 'provider-user',
          businessId: TestData.businessId,
          role: UserRole.provider,
          providerId: 'provider-1',
          createdAt: TestData.testDate,
        );

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(providerProfile),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(currentUserProfileProvider.future);

        expect(container.read(availableModuleConfigsProvider), isEmpty);
      },
    );
  });
}
