import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../providers/role_providers.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);

    if (role == null) {
      return fallback ?? const SizedBox.shrink();
    }

    if (allowedRoles.contains(role)) {
      return child;
    }

    return fallback ??
        const Center(
          child: Text('Not authorized'),
        );
  }
}
