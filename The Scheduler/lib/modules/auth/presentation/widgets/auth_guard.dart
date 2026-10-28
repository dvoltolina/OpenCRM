import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/demo_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../join_workspace_selection_page.dart';

/// Auth Guard Wrapper
///
/// Verifies that the authenticated user has a businessId before allowing
/// access to protected routes (RoleRouter/HomeShell and scheduling UI).
///
/// If the user is authenticated but does not have a businessId, they are
/// redirected to the join/create workspace screen.
///
/// This enforces the workspace membership requirement:
/// - Users MUST belong to a business/workspace to access the main app
/// - New users must create a workspace or join via invite code
///
/// HIPAA Compliance:
/// - Enforces tenant isolation at the UI level
/// - Ensures all users have proper businessId before accessing PHI
class AuthGuard extends ConsumerWidget {
  const AuthGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DemoConfig.isDemoMode) {
      return child;
    }

    return FutureBuilder(
      future: _checkBusinessId(ref),
      builder: (context, snapshot) {
        // Show loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user has businessId
        final hasBusinessId = snapshot.data ?? false;

        if (!hasBusinessId) {
          // Redirect to join/create workspace screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const JoinWorkspaceSelectionPage(),
                ),
              );
            }
          });

          // Show loading while redirecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User has businessId - allow access
        return child;
      },
    );
  }

  Future<bool> _checkBusinessId(WidgetRef ref) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userProfile = await authRepo.getCurrentUserProfile();

      if (userProfile == null) {
        return false;
      }

      // Check if businessId exists and is not a temporary value
      final businessId = userProfile.businessId;
      if (businessId.isEmpty || businessId == 'pending') {
        return false;
      }

      return true;
    } catch (e) {
      // If there's an error fetching the profile, deny access
      return false;
    }
  }
}
