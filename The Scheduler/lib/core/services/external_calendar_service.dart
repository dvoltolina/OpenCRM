import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/demo_config.dart';
import '../../data/models/appointment.dart';
import '../../data/models/integration_models.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/integration_repository.dart';
import '../config/app_config.dart';
import '../config/integration_config.dart';
import 'demo_guard_service.dart';
import 'integration_token_cipher.dart';
import 'oauth_service.dart';

/// High-level service that orchestrates OAuth connections and calendar sync.
class ExternalCalendarService {
  ExternalCalendarService({
    required IntegrationRepository integrationRepository,
    required IntegrationTokenCipher tokenCipher,
    required OAuthService oauthService,
    required IntegrationConfig integrationConfig,
    required this.bookingPolicies,
  })  : _integrationRepository = integrationRepository,
        _tokenCipher = tokenCipher,
        _oauthService = oauthService,
        _integrationConfig = integrationConfig;

  final IntegrationRepository _integrationRepository;
  final IntegrationTokenCipher _tokenCipher;
  final OAuthService _oauthService;
  final IntegrationConfig _integrationConfig;
  final BookingPolicies bookingPolicies;

  /// Initiates Google OAuth and persists encrypted credentials.
  Future<IntegrationAccount> connectGoogleCalendar(
    SecurityContext context,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('connect Google Calendar');
    }
    final tokens =
        await _oauthService.authenticateGoogleCalendar(_integrationConfig.googleOAuth);
    final integrationId = 'google_${context.userId}';

    final account = IntegrationAccount(
      id: integrationId,
      businessId: context.businessId,
      provider: IntegrationProvider.googleCalendar,
      status: IntegrationStatus.connected,
      scopes: _integrationConfig.googleOAuth.scopes,
      connectedAt: DateTime.now(),
      displayName: tokens.accountName,
      email: tokens.accountEmail,
      calendarSettings: CalendarSyncSettings(
        providerType: CalendarProviderType.google,
        twoWaySync: true,
        syncIntervalMinutes:
            _integrationConfig.defaultCalendarSyncInterval.inMinutes,
      ),
    );

    await _integrationRepository.upsertIntegration(
      context: context,
      account: account,
    );

    await _integrationRepository.saveEncryptedToken(
      context: context,
      token: EncryptedOAuthToken(
        integrationId: integrationId,
        encryptedAccessToken: _tokenCipher.encrypt(tokens.accessToken),
        encryptedRefreshToken: tokens.refreshToken == null
            ? null
            : _tokenCipher.encrypt(tokens.refreshToken!),
        expiresAt: tokens.expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    return account;
  }

  /// Initiates Microsoft OAuth (Graph) and persists encrypted credentials.
  Future<IntegrationAccount> connectMicrosoftCalendar(
    SecurityContext context,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('connect Outlook Calendar');
    }
    final tokens = await _oauthService
        .authenticateMicrosoftCalendar(_integrationConfig.microsoftOAuth);
    final integrationId = 'microsoft_${context.userId}';

    final account = IntegrationAccount(
      id: integrationId,
      businessId: context.businessId,
      provider: IntegrationProvider.outlookCalendar,
      status: IntegrationStatus.connected,
      scopes: _integrationConfig.microsoftOAuth.scopes,
      connectedAt: DateTime.now(),
      displayName: tokens.accountName,
      email: tokens.accountEmail,
      calendarSettings: CalendarSyncSettings(
        providerType: CalendarProviderType.microsoft,
        twoWaySync: true,
        syncIntervalMinutes:
            _integrationConfig.defaultCalendarSyncInterval.inMinutes,
      ),
    );

    await _integrationRepository.upsertIntegration(
      context: context,
      account: account,
    );

    await _integrationRepository.saveEncryptedToken(
      context: context,
      token: EncryptedOAuthToken(
        integrationId: integrationId,
        encryptedAccessToken: _tokenCipher.encrypt(tokens.accessToken),
        encryptedRefreshToken: tokens.refreshToken == null
            ? null
            : _tokenCipher.encrypt(tokens.refreshToken!),
        expiresAt: tokens.expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    return account;
  }

  Future<void> disconnectIntegration({
    required SecurityContext context,
    required IntegrationProvider provider,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('disconnect calendar integration');
    }
    final account = await _integrationRepository.getIntegration(
      context: context,
      provider: provider,
    );
    if (account == null) return;
    await _integrationRepository.deleteIntegration(
      context: context,
      integrationId: account.id,
    );
  }

  /// Push a single appointment into the connected calendar.
  Future<CalendarSyncResult> pushAppointmentToCalendar({
    required SecurityContext context,
    required IntegrationProvider provider,
    required Appointment appointment,
    required String providerName,
    required String clientName,
    required String clientEmail,
    required String locationDisplay,
    bool includeTelehealthLink = false,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('sync appointment to calendar');
    }
    final account = await _integrationRepository.getIntegration(
      context: context,
      provider: provider,
    );
    if (account == null) {
      return const CalendarSyncResult(
        success: false,
        syncedAppointments: 0,
        errorMessage: 'No integration connected for selected provider.',
      );
    }

    final token = await _integrationRepository.getEncryptedToken(
      context: context,
      integrationId: account.id,
    );

    if (token == null) {
      return const CalendarSyncResult(
        success: false,
        syncedAppointments: 0,
        errorMessage: 'Missing OAuth token. Please reconnect the integration.',
      );
    }

    if (token.expiresAt.isBefore(DateTime.now())) {
      return const CalendarSyncResult(
        success: false,
        syncedAppointments: 0,
        errorMessage: 'OAuth token expired. Please reconnect the integration.',
      );
    }

    switch (provider) {
      case IntegrationProvider.googleCalendar:
        return _pushToGoogle(
          context: context,
          account: account,
          token: token,
          appointment: appointment,
          providerName: providerName,
          clientName: clientName,
          clientEmail: clientEmail,
          locationDisplay: locationDisplay,
          includeMeet: includeTelehealthLink,
        );
      case IntegrationProvider.outlookCalendar:
        return _pushToMicrosoft(
          context: context,
          account: account,
          token: token,
          appointment: appointment,
          providerName: providerName,
          clientName: clientName,
          clientEmail: clientEmail,
          locationDisplay: locationDisplay,
          includeTeams: includeTelehealthLink,
        );
      default:
        return const CalendarSyncResult(
          success: false,
          syncedAppointments: 0,
          errorMessage: 'Unsupported calendar provider.',
        );
    }
  }

  Future<List<CalendarConflict>> detectConflicts({
    required SecurityContext context,
    required IntegrationProvider provider,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (DemoConfig.isDemoMode) {
      return const [];
    }
    final account = await _integrationRepository.getIntegration(
      context: context,
      provider: provider,
    );
    if (account == null ||
        account.calendarSettings == null ||
        !account.calendarSettings!.includePersonalConflicts) {
      return const [];
    }

    final token = await _integrationRepository.getEncryptedToken(
      context: context,
      integrationId: account.id,
    );
    if (token == null || token.expiresAt.isBefore(DateTime.now())) {
      return const [];
    }

    switch (provider) {
      case IntegrationProvider.googleCalendar:
        return _fetchGoogleConflicts(account, token, rangeStart, rangeEnd);
      case IntegrationProvider.outlookCalendar:
        return _fetchMicrosoftConflicts(account, token, rangeStart, rangeEnd);
      default:
        return const [];
    }
  }

  Future<CalendarSyncResult> _pushToGoogle({
    required SecurityContext context,
    required IntegrationAccount account,
    required EncryptedOAuthToken token,
    required Appointment appointment,
    required String providerName,
    required String clientName,
    required String clientEmail,
    required String locationDisplay,
    required bool includeMeet,
  }) async {
    final accessToken = _tokenCipher.decrypt(token.encryptedAccessToken);
    final payload = <String, dynamic>{
      'summary': '${appointment.serviceId} with $clientName',
      'description': appointment.notes ?? '',
      'location': locationDisplay,
      'start': {
        'dateTime': appointment.startTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': appointment.endTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'attendees': [
        {
          'email': clientEmail,
          'displayName': clientName,
        },
      ],
      'reminders': {
        'useDefault': true,
      },
    };

    var queryParams = 'sendUpdates=all';

    if (includeMeet) {
      payload['conferenceData'] = {
        'createRequest': {
          'requestId': appointment.id,
          'conferenceSolutionKey': {'type': 'hangoutsMeet'},
        },
      };
      queryParams += '&conferenceDataVersion=1';
    }

    final response = await http.post(
      Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events?$queryParams',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _integrationRepository.logSyncEvent(
        context: context,
        integrationId: account.id,
        result: const CalendarSyncResult(success: true, syncedAppointments: 1),
      );
      return const CalendarSyncResult(success: true, syncedAppointments: 1);
    }

    return CalendarSyncResult(
      success: false,
      syncedAppointments: 0,
      errorMessage: 'Google Calendar API error: ${response.body}',
    );
  }

  Future<CalendarSyncResult> _pushToMicrosoft({
    required SecurityContext context,
    required IntegrationAccount account,
    required EncryptedOAuthToken token,
    required Appointment appointment,
    required String providerName,
    required String clientName,
    required String clientEmail,
    required String locationDisplay,
    required bool includeTeams,
  }) async {
    final accessToken = _tokenCipher.decrypt(token.encryptedAccessToken);

    final payload = <String, dynamic>{
      'subject': '${appointment.serviceId} with $clientName',
      'body': {
        'contentType': 'HTML',
        'content': appointment.notes ?? '',
      },
      'start': {
        'dateTime': appointment.startTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': appointment.endTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'location': {'displayName': locationDisplay},
      'attendees': [
        {
          'emailAddress': {
            'address': clientEmail,
            'name': clientName,
          },
          'type': 'required',
        },
      ],
      'isOnlineMeeting': includeTeams,
      if (includeTeams) 'onlineMeetingProvider': 'teamsForBusiness',
    };

    final response = await http.post(
      Uri.parse('https://graph.microsoft.com/v1.0/me/events'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _integrationRepository.logSyncEvent(
        context: context,
        integrationId: account.id,
        result: const CalendarSyncResult(success: true, syncedAppointments: 1),
      );
      return const CalendarSyncResult(success: true, syncedAppointments: 1);
    }

    return CalendarSyncResult(
      success: false,
      syncedAppointments: 0,
      errorMessage: 'Microsoft Graph API error: ${response.body}',
    );
  }

  Future<List<CalendarConflict>> _fetchGoogleConflicts(
    IntegrationAccount account,
    EncryptedOAuthToken token,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final accessToken = _tokenCipher.decrypt(token.encryptedAccessToken);
    final response = await http.get(
      Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events'
        '?timeMin=${rangeStart.toUtc().toIso8601String()}'
        '&timeMax=${rangeEnd.toUtc().toIso8601String()}'
        '&singleEvents=true',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final start = map['start'] as Map<String, dynamic>? ?? const {};
      final end = map['end'] as Map<String, dynamic>? ?? const {};
      return CalendarConflict(
        title: map['summary'] as String? ?? 'Busy',
        startTime: DateTime.parse(
          (start['dateTime'] ?? start['date']) as String,
        ),
        endTime: DateTime.parse(
          (end['dateTime'] ?? end['date']) as String,
        ),
        providerName: account.displayName ?? 'Google Calendar',
        externalCalendar: IntegrationProvider.googleCalendar,
      );
    }).toList();
  }

  Future<List<CalendarConflict>> _fetchMicrosoftConflicts(
    IntegrationAccount account,
    EncryptedOAuthToken token,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final accessToken = _tokenCipher.decrypt(token.encryptedAccessToken);
    final response = await http.get(
      Uri.parse(
        'https://graph.microsoft.com/v1.0/me/calendarview'
        '?startDateTime=${rangeStart.toUtc().toIso8601String()}'
        '&endDateTime=${rangeEnd.toUtc().toIso8601String()}',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['value'] as List<dynamic>? ?? const [];
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      final start = map['start'] as Map<String, dynamic>? ?? const {};
      final end = map['end'] as Map<String, dynamic>? ?? const {};
      return CalendarConflict(
        title: map['subject'] as String? ?? 'Busy',
        startTime: DateTime.parse(start['dateTime'] as String),
        endTime: DateTime.parse(end['dateTime'] as String),
        providerName: account.displayName ?? 'Outlook Calendar',
        externalCalendar: IntegrationProvider.outlookCalendar,
      );
    }).toList();
  }
}
