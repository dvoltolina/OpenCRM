import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/demo_config.dart';
import '../../data/models/appointment.dart';
import '../../data/models/integration_models.dart';
import '../../data/models/security_context.dart';
import '../config/integration_config.dart';
import 'demo_guard_service.dart';
import 'external_calendar_service.dart';
import 'oauth_service.dart';

class TelehealthMeeting {
  const TelehealthMeeting({
    required this.provider,
    required this.url,
    this.passcode,
  });

  final TelehealthProviderType provider;
  final String url;
  final String? passcode;
}

/// Generates telehealth meeting links for appointments (Zoom or Google Meet).
class TelehealthService {
  TelehealthService({
    required IntegrationConfig integrationConfig,
    required OAuthService oauthService,
    required ExternalCalendarService calendarService,
  })  : _config = integrationConfig,
        _oauthService = oauthService,
        _calendarService = calendarService;

  final IntegrationConfig _config;
  final OAuthService _oauthService;
  final ExternalCalendarService _calendarService;

  Future<TelehealthMeeting?> maybeCreateMeeting({
    required SecurityContext context,
    required Appointment appointment,
    required String providerName,
    required String clientName,
    required String clientEmail,
    required String locationDisplay,
    TelehealthProviderType? overrideProvider,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create telehealth meeting');
    }
    final platform = overrideProvider ?? _config.defaultTelehealthProvider;
    if (platform == TelehealthProviderType.none) {
      return null;
    }

    if (platform == TelehealthProviderType.zoom) {
      return _createZoomMeeting(appointment, providerName, clientName);
    }

    if (platform == TelehealthProviderType.googleMeet) {
      final result = await _calendarService.pushAppointmentToCalendar(
        context: context,
        provider: IntegrationProvider.googleCalendar,
        appointment: appointment,
        providerName: providerName,
        clientName: clientName,
        clientEmail: clientEmail,
        locationDisplay: locationDisplay,
        includeTelehealthLink: true,
      );

      if (result.success) {
        return const TelehealthMeeting(
          provider: TelehealthProviderType.googleMeet,
          url: 'Generated via Calendar event (see event details).',
        );
      }

      throw Exception(result.errorMessage ??
          'Unable to create Google Meet link. Ensure Google Calendar is connected.');
    }

    return null;
  }

  Future<TelehealthMeeting> _createZoomMeeting(
    Appointment appointment,
    String providerName,
    String clientName,
  ) async {
    final tokens = await _oauthService.authenticateZoomServerToServer(
      _config.zoom,
    );

    final payload = {
      'topic': '${appointment.serviceId} with $clientName',
      'type': 2,
      'start_time': appointment.startTime.toUtc().toIso8601String(),
      'duration': appointment.endTime
          .difference(appointment.startTime)
          .inMinutes,
      'timezone': 'UTC',
      'settings': {
        'waiting_room': true,
        'join_before_host': false,
        'participant_video': true,
        'host_video': true,
      },
    };

    final response = await http.post(
      Uri.parse('${_config.zoom.baseUrl}/users/me/meetings'),
      headers: {
        'Authorization': 'Bearer ${tokens.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return TelehealthMeeting(
        provider: TelehealthProviderType.zoom,
        url: decoded['join_url'] as String,
        passcode: decoded['password'] as String?,
      );
    }

    throw Exception('Zoom API error: ${response.body}');
  }
}
