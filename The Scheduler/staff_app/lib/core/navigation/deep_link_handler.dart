// Deep Link Handler for Staff App
//
// Handles navigation from push notifications and external deep links.
// Supports various routes like schedule, appointments, time clock, etc.

import 'package:flutter/material.dart';

/// Types of deep links supported by the app.
enum DeepLinkType {
  /// View schedule for a specific date.
  schedule,

  /// View a specific appointment.
  appointment,

  /// Open time clock to clock in/out.
  timeClock,

  /// View a specific time entry.
  timeEntry,

  /// View messages/notifications.
  messages,

  /// View settings.
  settings,

  /// View profile.
  profile,

  /// Unknown/invalid deep link.
  unknown,
}

/// Parsed deep link with route information.
class DeepLink {
  const DeepLink({
    required this.type,
    required this.path,
    this.params = const {},
    this.queryParams = const {},
  });

  /// Type of deep link.
  final DeepLinkType type;

  /// Full path of the link.
  final String path;

  /// Path parameters (e.g., appointmentId).
  final Map<String, String> params;

  /// Query parameters.
  final Map<String, String> queryParams;

  /// Parse a deep link URI.
  factory DeepLink.parse(Uri uri) {
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    if (pathSegments.isEmpty) {
      return DeepLink(
        type: DeepLinkType.unknown,
        path: uri.path,
        queryParams: queryParams,
      );
    }

    final firstSegment = pathSegments.first.toLowerCase();

    switch (firstSegment) {
      case 'schedule':
        return DeepLink(
          type: DeepLinkType.schedule,
          path: uri.path,
          params: {
            if (pathSegments.length > 1) 'date': pathSegments[1],
          },
          queryParams: queryParams,
        );

      case 'appointment':
      case 'appointments':
        return DeepLink(
          type: DeepLinkType.appointment,
          path: uri.path,
          params: {
            if (pathSegments.length > 1) 'appointmentId': pathSegments[1],
          },
          queryParams: queryParams,
        );

      case 'timeclock':
      case 'time-clock':
      case 'clock':
        return DeepLink(
          type: DeepLinkType.timeClock,
          path: uri.path,
          params: {
            if (pathSegments.length > 1) 'action': pathSegments[1],
          },
          queryParams: queryParams,
        );

      case 'timeentry':
      case 'time-entry':
        return DeepLink(
          type: DeepLinkType.timeEntry,
          path: uri.path,
          params: {
            if (pathSegments.length > 1) 'entryId': pathSegments[1],
          },
          queryParams: queryParams,
        );

      case 'messages':
      case 'notifications':
        return DeepLink(
          type: DeepLinkType.messages,
          path: uri.path,
          queryParams: queryParams,
        );

      case 'settings':
        return DeepLink(
          type: DeepLinkType.settings,
          path: uri.path,
          params: {
            if (pathSegments.length > 1) 'section': pathSegments[1],
          },
          queryParams: queryParams,
        );

      case 'profile':
        return DeepLink(
          type: DeepLinkType.profile,
          path: uri.path,
          queryParams: queryParams,
        );

      default:
        return DeepLink(
          type: DeepLinkType.unknown,
          path: uri.path,
          queryParams: queryParams,
        );
    }
  }

  /// Parse from notification payload.
  factory DeepLink.fromNotificationPayload(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'schedule_update':
        return DeepLink(
          type: DeepLinkType.schedule,
          path: '/schedule',
          params: {
            if (data['date'] != null) 'date': data['date'].toString(),
          },
        );

      case 'appointment_reminder':
      case 'appointment_update':
      case 'new_appointment':
        return DeepLink(
          type: DeepLinkType.appointment,
          path: '/appointment/${data['appointmentId'] ?? ''}',
          params: {
            if (data['appointmentId'] != null)
              'appointmentId': data['appointmentId'].toString(),
          },
        );

      case 'clock_reminder':
        return DeepLink(
          type: DeepLinkType.timeClock,
          path: '/timeclock',
          params: {
            if (data['action'] != null) 'action': data['action'].toString(),
          },
        );

      case 'timesheet_approved':
      case 'timesheet_rejected':
        return DeepLink(
          type: DeepLinkType.timeEntry,
          path: '/timeentry/${data['entryId'] ?? ''}',
          params: {
            if (data['entryId'] != null) 'entryId': data['entryId'].toString(),
          },
        );

      case 'message':
        return const DeepLink(
          type: DeepLinkType.messages,
          path: '/messages',
        );

      default:
        return const DeepLink(
          type: DeepLinkType.unknown,
          path: '/',
        );
    }
  }

  @override
  String toString() => 'DeepLink(type: $type, path: $path, params: $params)';
}

/// Service for handling deep link navigation.
class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  /// Pending deep link to process after app initialization.
  DeepLink? _pendingDeepLink;

  /// Whether the app is ready to handle navigation.
  bool _isReady = false;

  /// Callback for when navigation should occur.
  void Function(DeepLink link)? _onNavigate;

  /// Set the navigation callback.
  void setNavigationCallback(void Function(DeepLink link) callback) {
    _onNavigate = callback;

    // Process pending deep link if any
    if (_isReady && _pendingDeepLink != null) {
      callback(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  /// Mark the app as ready for navigation.
  void markReady() {
    _isReady = true;

    // Process pending deep link if any
    if (_pendingDeepLink != null && _onNavigate != null) {
      _onNavigate!(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  /// Handle a deep link URI.
  void handleUri(Uri uri) {
    final deepLink = DeepLink.parse(uri);
    _handleDeepLink(deepLink);
  }

  /// Handle a notification payload.
  void handleNotificationPayload(Map<String, dynamic> payload) {
    final deepLink = DeepLink.fromNotificationPayload(payload);
    _handleDeepLink(deepLink);
  }

  void _handleDeepLink(DeepLink deepLink) {
    if (deepLink.type == DeepLinkType.unknown) {
      debugPrint('DeepLinkHandler: Unknown deep link: ${deepLink.path}');
      return;
    }

    debugPrint('DeepLinkHandler: Processing ${deepLink.type}');

    if (_isReady && _onNavigate != null) {
      _onNavigate!(deepLink);
    } else {
      // Store for later processing
      _pendingDeepLink = deepLink;
      debugPrint('DeepLinkHandler: Stored pending deep link');
    }
  }

  /// Get the route name for a deep link type.
  static String getRouteName(DeepLinkType type) {
    switch (type) {
      case DeepLinkType.schedule:
        return '/schedule';
      case DeepLinkType.appointment:
        return '/appointment';
      case DeepLinkType.timeClock:
        return '/timeclock';
      case DeepLinkType.timeEntry:
        return '/timeentry';
      case DeepLinkType.messages:
        return '/messages';
      case DeepLinkType.settings:
        return '/settings';
      case DeepLinkType.profile:
        return '/profile';
      case DeepLinkType.unknown:
        return '/';
    }
  }

  /// Navigate to a deep link using Navigator.
  ///
  /// This is a generic implementation. In your app, you should
  /// customize this to work with your routing setup (Navigator 2.0,
  /// go_router, auto_route, etc.).
  static void navigateToDeepLink(
    BuildContext context,
    DeepLink link, {
    Widget Function(DeepLink)? routeBuilder,
  }) {
    if (link.type == DeepLinkType.unknown) {
      return;
    }

    final routeName = getRouteName(link.type);

    if (routeBuilder != null) {
      // Use custom route builder
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => routeBuilder(link),
          settings: RouteSettings(
            name: routeName,
            arguments: link.params,
          ),
        ),
      );
    } else {
      // Use named route navigation
      Navigator.of(context).pushNamed(
        routeName,
        arguments: link.params,
      );
    }
  }
}

/// Extension for easy deep link handling in widgets.
extension DeepLinkNavigation on BuildContext {
  /// Navigate to a deep link.
  void navigateToDeepLink(
    DeepLink link, {
    Widget Function(DeepLink)? routeBuilder,
  }) {
    DeepLinkHandler.navigateToDeepLink(this, link, routeBuilder: routeBuilder);
  }
}
