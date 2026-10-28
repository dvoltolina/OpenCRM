import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'session_note.freezed.dart';
part 'session_note.g.dart';

/// Visibility/access level for session notes
enum SessionNoteVisibility {
  providerOnly, // Only the provider who created it
  businessOnly, // All providers in the business
  shared, // Shared with client (rare)
}

/// Type of session note for different clinical contexts
enum SessionNoteType {
  soap, // Subjective, Objective, Assessment, Plan
  progressNote, // General progress note
  treatmentPlan, // Treatment plan documentation
  procedureLog, // Dental/medical procedure log
  adjustmentNote, // Chiropractic adjustment
  intakeAssessment, // Initial assessment
  dischargeNote, // End of treatment
  psychNote, // Psychotherapy note (extra protected)
  custom, // Custom note type
}

/// Extension for SessionNoteType display and templates
extension SessionNoteTypeExtensions on SessionNoteType {
  /// Label alias for displayName
  String get label => displayName;

  String get displayName {
    switch (this) {
      case SessionNoteType.soap:
        return 'SOAP Note';
      case SessionNoteType.progressNote:
        return 'Progress Note';
      case SessionNoteType.treatmentPlan:
        return 'Treatment Plan';
      case SessionNoteType.procedureLog:
        return 'Procedure Log';
      case SessionNoteType.adjustmentNote:
        return 'Adjustment Note';
      case SessionNoteType.intakeAssessment:
        return 'Intake Assessment';
      case SessionNoteType.dischargeNote:
        return 'Discharge Note';
      case SessionNoteType.psychNote:
        return 'Psychotherapy Note';
      case SessionNoteType.custom:
        return 'Custom Note';
    }
  }

  String get icon {
    switch (this) {
      case SessionNoteType.soap:
        return '📋';
      case SessionNoteType.progressNote:
        return '📈';
      case SessionNoteType.treatmentPlan:
        return '🎯';
      case SessionNoteType.procedureLog:
        return '🔬';
      case SessionNoteType.adjustmentNote:
        return '💆';
      case SessionNoteType.intakeAssessment:
        return '📝';
      case SessionNoteType.dischargeNote:
        return '✅';
      case SessionNoteType.psychNote:
        return '🔒';
      case SessionNoteType.custom:
        return '📄';
    }
  }

  /// Get template structure for this note type
  String get template {
    switch (this) {
      case SessionNoteType.soap:
        return '''Subjective:


Objective:


Assessment:


Plan:

''';
      case SessionNoteType.progressNote:
        return '''Progress Summary:


Observations:


Goals Progress:


Next Steps:

''';
      case SessionNoteType.treatmentPlan:
        return '''Diagnosis/Chief Complaint:


Treatment Goals:


Interventions:


Timeline:


Expected Outcomes:

''';
      case SessionNoteType.procedureLog:
        return '''Procedure Performed:


Indications:


Technique:


Materials Used:


Complications:


Post-Procedure Instructions:

''';
      case SessionNoteType.adjustmentNote:
        return '''Chief Complaint:


Areas Treated:


Technique Used:


Patient Response:


Follow-up Plan:

''';
      case SessionNoteType.intakeAssessment:
        return '''Presenting Problem:


History:


Assessment:


Diagnosis/Impressions:


Recommended Treatment:

''';
      case SessionNoteType.dischargeNote:
        return '''Reason for Discharge:


Treatment Summary:


Outcomes Achieved:


Recommendations:


Follow-up Care:

''';
      case SessionNoteType.psychNote:
        return '''Session Focus:


Interventions Used:


Client Response:


Progress Toward Goals:


Plan for Next Session:

''';
      case SessionNoteType.custom:
        return '';
    }
  }
}

/// Audit entry for session note access/modifications
@freezed
abstract class SessionNoteAudit with _$SessionNoteAudit {
  const factory SessionNoteAudit({
    required String id,
    required String action, // 'created', 'viewed', 'edited', 'deleted'
    required String userId,
    required String userFullName,
    @TimestampConverter() required DateTime timestamp,
    String? ipAddress,
    String? userAgent,
    String? changesSummary,
  }) = _SessionNoteAudit;

  factory SessionNoteAudit.fromJson(Map<String, dynamic> json) =>
      _$SessionNoteAuditFromJson(json);
}

/// HIPAA-compliant session note for clinical documentation
///
/// Note content is encrypted at rest using AES-256 encryption.
/// Access is strictly limited to providers with appropriate permissions.
/// All access and modifications are logged for audit compliance.
@freezed
abstract class SessionNote with _$SessionNote {
  const factory SessionNote({
    required String id,
    required String businessId,
    required String appointmentId,
    required String clientId,
    required String providerId,
    required SessionNoteType noteType,

    /// Visibility/access level for this note
    @Default(SessionNoteVisibility.providerOnly) SessionNoteVisibility visibility,

    /// Encrypted note content (encrypted with business encryption key)
    required String encryptedContent,
    
    /// Plain text title/summary (NOT encrypted, for listing)
    String? title,
    
    /// Tags for categorization (NOT encrypted)
    @Default([]) List<String> tags,
    
    /// Whether this note is locked for editing
    @Default(false) bool isLocked,
    
    /// Creation timestamp
    @TimestampConverter() required DateTime createdAt,
    
    /// Last modification timestamp
    @NullableTimestampConverter() DateTime? updatedAt,
    
    /// Created by user ID
    required String createdBy,
    
    /// Created by user full name (cached for display)
    required String createdByName,
    
    /// Last edited by user ID
    String? lastEditedBy,
    
    /// Last edited by user full name
    String? lastEditedByName,
    
    /// Audit trail (access and modification log)
    @Default([]) List<SessionNoteAudit> auditLog,
    
    /// Retention policy: never delete even if appointment is deleted
    @Default(true) bool retainIndefinitely,
    
    /// For psychotherapy notes: extra protected, different disclosure rules
    @Default(false) bool isPsychotherapyNote,
  }) = _SessionNote;

  factory SessionNote.fromJson(Map<String, dynamic> json) =>
      _$SessionNoteFromJson(json);
}

/// Extension methods for SessionNote
extension SessionNoteExtensions on SessionNote {
  /// Alias for noteType for backwards compatibility
  SessionNoteType get type => noteType;

  /// Placeholder for decrypted content (should be populated after decryption)
  /// In real usage, this would be set after decrypting encryptedContent
  String? get decryptedContent => null; // Must be decrypted separately

  /// Check if note was recently modified
  bool get isRecentlyModified {
    if (updatedAt == null) return false;
    final now = DateTime.now();
    return now.difference(updatedAt!).inDays < 7;
  }

  /// Get display timestamp (updated or created)
  DateTime get displayTimestamp => updatedAt ?? createdAt;

  /// Get display author (last edited or created by)
  String get displayAuthor => lastEditedByName ?? createdByName;

  /// Count audit entries by action type
  int countAuditAction(String action) {
    return auditLog.where((entry) => entry.action == action).length;
  }

  /// Get last viewed timestamp
  DateTime? get lastViewedAt {
    final viewEntries = auditLog.where((entry) => entry.action == 'viewed');
    if (viewEntries.isEmpty) return null;
    return viewEntries.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Add audit entry
  SessionNote withAuditEntry(SessionNoteAudit entry) {
    return copyWith(
      auditLog: [...auditLog, entry],
    );
  }
}
