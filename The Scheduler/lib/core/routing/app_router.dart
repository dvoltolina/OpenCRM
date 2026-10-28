import 'package:flutter/material.dart';

import '../../modules/home/presentation/home_shell.dart';
import '../../modules/auth/presentation/invite_link_handler_page.dart';
import '../../modules/auth/presentation/widgets/auth_gate.dart';
import '../config/demo_config.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = settings.name ?? '';
    final inviteMatch = _parseInviteRoute(route);

    if (inviteMatch != null) {
      return MaterialPageRoute(
        builder: (_) => InviteLinkHandlerPage(
          inviteId: inviteMatch.inviteId,
          token: inviteMatch.token,
        ),
      );
    }

    if (DemoConfig.isDemoMode) {
      return MaterialPageRoute(builder: (_) => const HomeShell());
    }

    return MaterialPageRoute(builder: (_) => const AuthGate());
  }

  static _InviteRouteMatch? _parseInviteRoute(String route) {
    // Expected: /invite/{id}?token={token}
    if (!route.startsWith('/invite/')) return null;
    final uri = Uri.parse(route);
    final segments = uri.pathSegments;
    if (segments.length < 2) return null;
    final inviteId = segments[1];
    final token = uri.queryParameters['token'];
    if (inviteId.isEmpty || token == null || token.isEmpty) return null;
    return _InviteRouteMatch(inviteId: inviteId, token: token);
  }
}

class _InviteRouteMatch {
  _InviteRouteMatch({required this.inviteId, required this.token});
  final String inviteId;
  final String token;
}
