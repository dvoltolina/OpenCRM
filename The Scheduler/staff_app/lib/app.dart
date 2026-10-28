import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'core/providers/auth_providers.dart';
import 'core/providers/sync_providers.dart';
import 'modules/auth/presentation/staff_login_page.dart';
import 'core/services/auth_guard.dart';
import 'core/theme/staff_theme.dart';

/// Root widget for the Staff App.
///
/// Sets up Material theming, routing, and handles authentication state
/// to determine the initial screen (login vs schedule).
/// Verifies staff role after Firebase Auth authentication.
class StaffApp extends ConsumerWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Staff App',
      debugShowCheckedModeBanner: false,
      theme: staffLightTheme(),
      darkTheme: staffDarkTheme(),
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (_) => const AuthGuard(
          child: _SyncGate(child: AppShell()),
        ),
        loading: () => const _SplashScreen(),
        error: (_, __) => const StaffLoginPage(),
      ),
    );
  }
}

/// Ensures sync engine is initialized before rendering authenticated content.
class _SyncGate extends ConsumerWidget {
  const _SyncGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffUser = ref.watch(currentStaffUserProvider).valueOrNull;
    if (staffUser == null) {
      return const StaffLoginPage();
    }

    final syncInit = ref.watch(syncEngineInitializedProvider);
    return syncInit.when(
      data: (_) => child,
      loading: () => const _SplashScreen(),
      error: (_, __) => const StaffLoginPage(),
    );
  }
}

/// Splash screen shown while checking authentication or sync state.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
