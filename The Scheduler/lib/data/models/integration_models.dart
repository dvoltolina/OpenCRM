import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/integration_config.dart';

/// Generic provider identifiers used across repositories and services.
enum IntegrationProvider {
  googleCalendar,
  outlookCalendar,
  zoom,
  googleMeet,
  sendGrid,
  awsSes,
  twilio,
  awsSns,
}

/// Status of a connected integration.
enum IntegrationStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Metadata describing how often we sync and whether we push/pull events.
class CalendarSyncSettings {
  const CalendarSyncSettings({
    required this.providerType,
    this.twoWaySync = true,
    this.autoResolveConflicts = true,
    this.syncIntervalMinutes = 15,
    this.includePersonalConflicts = true,
  });

  final CalendarProviderType providerType;
  final bool twoWaySync;
  final bool autoResolveConflicts;
  final int syncIntervalMinutes;
  final bool includePersonalConflicts;

  factory CalendarSyncSettings.fromJson(Map<String, dynamic> json) {
    return CalendarSyncSettings(
      providerType: CalendarProviderType.values.byName(
        json['providerType'] as String? ?? CalendarProviderType.google.name,
      ),
      twoWaySync: json['twoWaySync'] as bool? ?? true,
      autoResolveConflicts: json['autoResolveConflicts'] as bool? ?? true,
      syncIntervalMinutes: json['syncIntervalMinutes'] as int? ?? 15,
      includePersonalConflicts:
          json['includePersonalConflicts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerType': providerType.name,
      'twoWaySync': twoWaySync,
      'autoResolveConflicts': autoResolveConflicts,
      'syncIntervalMinutes': syncIntervalMinutes,
      'includePersonalConflicts': includePersonalConflicts,
    };
  }
}

/// Telehealth preferences for a specific integration.
class TelehealthSettings {
  const TelehealthSettings({
    this.provider = TelehealthProviderType.none,
    this.autoAttachLinks = true,
    this.waitingRoomEnabled = false,
  });

  final TelehealthProviderType provider;
  final bool autoAttachLinks;
  final bool waitingRoomEnabled;

  factory TelehealthSettings.fromJson(Map<String, dynamic> json) {
    return TelehealthSettings(
      provider: TelehealthProviderType.values.byName(
        json['provider'] as String? ?? TelehealthProviderType.none.name,
      ),
      autoAttachLinks: json['autoAttachLinks'] as bool? ?? true,
      waitingRoomEnabled: json['waitingRoomEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'autoAttachLinks': autoAttachLinks,
      'waitingRoomEnabled': waitingRoomEnabled,
    };
  }
}

/// Representation of a connected integration account per business.
class IntegrationAccount {
  const IntegrationAccount({
    required this.id,
    required this.businessId,
    required this.provider,
    required this.status,
    required this.scopes,
    required this.connectedAt,
    this.displayName,
    this.email,
    this.lastSyncAt,
    this.errorMessage,
    this.calendarSettings,
    this.telehealthSettings,
  });

  final String id;
  final String businessId;
  final IntegrationProvider provider;
  final IntegrationStatus status;
  final List<String> scopes;
  final DateTime connectedAt;
  final String? displayName;
  final String? email;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final CalendarSyncSettings? calendarSettings;
  final TelehealthSettings? telehealthSettings;

  bool get isCalendarProvider =>
      provider == IntegrationProvider.googleCalendar ||
      provider == IntegrationProvider.outlookCalendar;

  bool get isTelehealthProvider =>
      provider == IntegrationProvider.zoom ||
      provider == IntegrationProvider.googleMeet;

  factory IntegrationAccount.fromJson(Map<String, dynamic> json) {
    return IntegrationAccount(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      provider: IntegrationProvider.values.byName(
        json['provider'] as String? ?? IntegrationProvider.googleCalendar.name,
      ),
      status: IntegrationStatus.values.byName(
        json['status'] as String? ?? IntegrationStatus.connected.name,
      ),
      scopes: List<String>.from(json['scopes'] as List? ?? const []),
      connectedAt: (json['connectedAt'] is Timestamp)
          ? (json['connectedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['connectedAt'] as String? ?? '') ??
              DateTime.now(),
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      lastSyncAt: _parseNullableTimestamp(json['lastSyncAt']),
      errorMessage: json['errorMessage'] as String?,
      calendarSettings: json['calendarSettings'] == null
          ? null
          : CalendarSyncSettings.fromJson(
              Map<String, dynamic>.from(
                json['calendarSettings'] as Map? ?? const {},
              ),
            ),
      telehealthSettings: json['telehealthSettings'] == null
          ? null
          : TelehealthSettings.fromJson(
              Map<String, dynamic>.from(
                json['telehealthSettings'] as Map? ?? const {},
              ),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'provider': provider.name,
      'status': status.name,
      'scopes': scopes,
      'connectedAt': Timestamp.fromDate(connectedAt),
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (lastSyncAt != null) 'lastSyncAt': Timestamp.fromDate(lastSyncAt!),
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (calendarSettings != null)
        'calendarSettings': calendarSettings!.toJson(),
      if (telehealthSettings != null)
        'telehealthSettings': telehealthSettings!.toJson(),
    };
  }

  IntegrationAccount copyWith({
    IntegrationStatus? status,
    List<String>? scopes,
    DateTime? lastSyncAt,
    String? errorMessage,
    CalendarSyncSettings? calendarSettings,
    TelehealthSettings? telehealthSettings,
    String? displayName,
    String? email,
  }) {
    return IntegrationAccount(
      id: id,
      businessId: businessId,
      provider: provider,
      status: status ?? this.status,
      scopes: scopes ?? this.scopes,
      connectedAt: connectedAt,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage ?? this.errorMessage,
      calendarSettings: calendarSettings ?? this.calendarSettings,
      telehealthSettings: telehealthSettings ?? this.telehealthSettings,
    );
  }

  static DateTime? _parseNullableTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Representation of encrypted OAuth tokens stored in Firestore.
class EncryptedOAuthToken {
  const EncryptedOAuthToken({
    required this.integrationId,
    required this.encryptedAccessToken,
    required this.encryptedRefreshToken,
    required this.expiresAt,
  });

  final String integrationId;
  final String encryptedAccessToken;
  final String? encryptedRefreshToken;
  final DateTime expiresAt;

  factory EncryptedOAuthToken.fromJson(Map<String, dynamic> json) {
    return EncryptedOAuthToken(
      integrationId: json['integrationId'] as String,
      encryptedAccessToken: json['accessToken'] as String,
      encryptedRefreshToken: json['refreshToken'] as String?,
      expiresAt: (json['expiresAt'] is Timestamp)
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'integrationId': integrationId,
      'accessToken': encryptedAccessToken,
      if (encryptedRefreshToken != null)
        'refreshToken': encryptedRefreshToken,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}

/// Result of a sync operation used for UI feedback.
class CalendarSyncResult {
  const CalendarSyncResult({
    required this.success,
    required this.syncedAppointments,
    this.conflicts = const [],
    this.errorMessage,
  });

  final bool success;
  final int syncedAppointments;
  final List<CalendarConflict> conflicts;
  final String? errorMessage;
}

/// Conflict representation that surfaces to booking UI.
class CalendarConflict {
  const CalendarConflict({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.providerName,
    this.externalCalendar,
  });

  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String providerName;
  final IntegrationProvider? externalCalendar;
}

