import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

/// Centralized audit log entry for HIPAA-grade tracking.
///
/// Metadata must never contain PHI or free-text user content. Use IDs, types,
/// and bounded descriptors only. `ipAddress` is populated only by server-side
/// writers (Cloud Functions); the Flutter client should leave it null.
@freezed
abstract class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    /// Optional document ID for round-tripping Firestore entries.
    String? id,

    /// Tenant isolation scope.
    required String businessId,

    /// Acting user.
    required String userId,

    /// Action category captured for compliance reporting.
    required AuditActionType actionType,

    /// Entity type (e.g., 'Client', 'Appointment').
    required String entityType,

    /// Entity identifier (use a high-level identifier for list reads).
    required String entityId,

    /// Server-assigned timestamp of the event.
    @NullableTimestampConverter() DateTime? timestamp,

    /// Server-captured IP address (never client-provided).
    String? ipAddress,

    /// Optional device descriptor (OS, app version, platform).
    Map<String, dynamic>? deviceInfo,

    /// Optional correlation ID to stitch related actions.
    String? correlationId,

    /// Additional structured context; never include PHI or free text.
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _AuditLogEntry;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditLogEntryFromJson(json);
}

/// Supported audit action categories for compliance reporting.
enum AuditActionType {
  loginSuccess,
  loginFailure,
  phiRead,
  phiReadList,
  phiWrite,
  dataExport,
  securityEvent,
}
