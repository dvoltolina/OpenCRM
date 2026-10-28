import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../config/demo_config.dart';
import '../config/module_config.dart';
import '../config/role_modules.dart';
import 'app_providers.dart';

/// Stream of the current user's profile (null when signed out).
/// Listens to auth state changes and fetches the profile via UserRepository.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  if (DemoConfig.isDemoMode) {
    yield DemoConfig.buildDemoUserProfile();
    return;
  }

  final authService = ref.watch(authStateServiceProvider);
  await for (final firebaseUser in authService.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
      continue;
    }

    try {
      final profile = await authService.getCurrentUserProfile();
      yield profile;
    } catch (_) {
      // Best-effort; return null on lookup failure.
      yield null;
    }
  }
});

/// Current user's role derived from the profile.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.valueOrNull?.role;
});

/// Check if the current user has a specific role.
final hasRoleProvider = Provider.family<bool, UserRole>((ref, role) {
  final currentRole = ref.watch(currentUserRoleProvider);
  return currentRole == role;
});

/// Convenience flag for admin/owner roles.
final isAdminOrOwnerProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.admin || role == UserRole.owner;
});

/// Permission check using role-based defaults.
///
/// Owner/Admin: all permissions.
/// Manager: limited to scheduling/timesheet approvals.
/// Others: conservative defaults (false unless explicitly allowed).
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return false;

  final role = profile.role;
  if (role == UserRole.owner || role == UserRole.admin) return true;

  // Minimal mapping for now; extend as granular permissions are added.
  switch (permission) {
    case 'timesheet:approve':
    case 'timesheet:view':
    case 'schedule:team':
      return role == UserRole.manager;
    case 'appointments:manage_own':
      return role == UserRole.staff || role == UserRole.provider;
    default:
      return false;
  }
});

/// Modules available to the current user, filtered by role.
final availableModulesProvider = Provider<List<AppModule>>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  if (role == null) return const [];
  return RoleModules.getModulesForRole(role);
});

/// ModuleConfig list filtered by the role's allowed modules.
final availableModuleConfigsProvider = Provider<List<ModuleConfig>>((ref) {
  final config = ref.watch(appConfigProvider);
  if (DemoConfig.isDemoMode) {
    return config.modules;
  }
  final role = ref.watch(currentUserRoleProvider);
  if (role == null) {
    return const <ModuleConfig>[];
  }

  return RoleModules.filterModuleConfigs(
    config.modules,
    RoleModules.getModulesForRole(role),
  );
});
