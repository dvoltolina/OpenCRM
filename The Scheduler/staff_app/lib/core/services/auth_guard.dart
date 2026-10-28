import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../data/models/staff_user.dart';
import '../../modules/auth/presentation/staff_login_page.dart';

export '../../data/models/staff_user.dart';

/// Widget that guards child content, showing login when not authenticated.
///
/// Wraps authenticated content and redirects to login page when the user
/// is not signed in. Shows a loading indicator while checking auth state.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  /// The widget to show when authenticated.
  final Widget child;

  /// Custom loading widget while checking auth state.
  final Widget? loadingWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, verify staff role
          final staffUser = ref.watch(currentStaffUserProvider);
          return staffUser.when(
            data: (staff) {
              if (staff != null) {
                return child;
              }
              // User exists but doesn't have staff role
              return const _UnauthorizedPage();
            },
            loading: () => loadingWidget ?? const _LoadingScreen(),
            error: (_, __) => const StaffLoginPage(),
          );
        }
        return const StaffLoginPage();
      },
      loading: () => loadingWidget ?? const _LoadingScreen(),
      error: (_, __) => const StaffLoginPage(),
    );
  }
}

/// Provides route protection with redirect capabilities.
///
/// Use this class with navigation libraries like GoRouter to handle
/// authentication-based redirects.
class AuthRouteGuard {
  AuthRouteGuard(this._ref);

  final Ref _ref;

  /// Checks if the user is authenticated and has staff role.
  ///
  /// Returns true if user should have access, false otherwise.
  bool get isAuthenticated {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return false;

    final staffUser = _ref.read(currentStaffUserProvider);
    return staffUser.valueOrNull != null;
  }

  /// Gets the redirect path based on auth state.
  ///
  /// Returns '/login' if not authenticated, null if authenticated.
  String? getRedirectPath(String currentPath) {
    if (!isAuthenticated && currentPath != '/login') {
      return '/login';
    }
    if (isAuthenticated && currentPath == '/login') {
      return '/';
    }
    return null;
  }

  /// Checks current auth state.
  ///
  /// Use with GoRouter's refreshListenable for navigation updates.
  bool checkAuthState() {
    final authState = _ref.read(authStateProvider);
    return authState.valueOrNull != null;
  }
}

/// Provider for the auth route guard.
final authRouteGuardProvider = Provider<AuthRouteGuard>((ref) {
  return AuthRouteGuard(ref);
});

/// Page shown when user is authenticated but not authorized (not staff role).
class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account does not have staff access to this app. '
                  'Please contact your administrator if you believe this is an error.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Consumer(
                  builder: (context, ref, _) => FilledButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    onPressed: () async {
                      await ref.read(signOutProvider)();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading screen shown while checking auth state.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

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

/// Extension on WidgetRef to easily check auth status.
extension AuthRefExtension on WidgetRef {
  /// Whether the current user is authenticated.
  bool get isAuthenticated {
    final authState = watch(authStateProvider);
    return authState.valueOrNull != null;
  }

  /// Whether the current user has staff role.
  bool get isStaffUser {
    final staffUser = watch(currentStaffUserProvider);
    return staffUser.valueOrNull != null;
  }

  /// The current staff user or null.
  StaffUser? get staffUser {
    return watch(currentStaffUserProvider).valueOrNull;
  }

  /// Requires staff authentication, calling onUnauthorized if not.
  void requireStaffAuth({required VoidCallback onUnauthorized}) {
    if (!isStaffUser) {
      onUnauthorized();
    }
  }
}
