import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/home/presentation/home_shell.dart';
import '../../data/models/user_role.dart';
import '../../modules/auth/presentation/login_page.dart';
import '../../modules/client_portal/presentation/client_home_shell.dart';
import '../../modules/front_desk/presentation/front_desk_home_shell.dart';
import '../../modules/manager/presentation/manager_home_shell.dart';
import '../../modules/provider_mode/presentation/provider_mode_page.dart';
import '../../modules/sales/presentation/sales_home_shell.dart';
import '../../modules/admin/presentation/admin_home_shell.dart';
import '../config/demo_config.dart';
import '../providers/role_providers.dart';

/// Routes authenticated users to the correct shell based on their role.
class RoleRouter extends ConsumerWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DemoConfig.isDemoMode) {
      return const HomeShell();
    }

    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) =>
          const Scaffold(body: Center(child: Text('Unable to load profile'))),
      data: (profile) {
        if (profile == null) {
          // Not authenticated; show entry point.
          return const LoginPage();
        }

        switch (profile.role) {
          case UserRole.owner:
          case UserRole.admin:
            return const AdminHomeShell();
          case UserRole.manager:
            return const ManagerHomeShell();
          case UserRole.sales:
            return const SalesHomeShell();
          case UserRole.provider:
          case UserRole.staff:
            return const ProviderModePage();
          case UserRole.frontDesk:
            return const FrontDeskHomeShell();
          case UserRole.client:
            return ClientHomeShell(businessId: profile.businessId);
        }
      },
    );
  }
}
