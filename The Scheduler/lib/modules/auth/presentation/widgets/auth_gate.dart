import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/demo_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/routing/role_router.dart';
import '../portal_selection_page.dart';
import 'auth_guard.dart';

/// Launch-time route guard that restores authenticated sessions.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DemoConfig.isDemoMode) {
      return const RoleRouter();
    }

    final authService = ref.watch(authStateServiceProvider);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const PortalSelectionPage();
        }

        return const AuthGuard(child: RoleRouter());
      },
    );
  }
}
