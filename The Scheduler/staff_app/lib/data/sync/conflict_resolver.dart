import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of conflict resolution.
enum ConflictWinner {
  /// Local version should be kept.
  local,

  /// Remote (server) version should be kept.
  remote,

  /// Merge both versions (for non-conflicting fields).
  merge,
}

/// Detailed result of a conflict resolution.
class ConflictResolution {
  const ConflictResolution({
    required this.winner,
    required this.reason,
    this.mergedData,
    this.conflictId,
    this.shouldLog = false,
  });

  /// Which version won the conflict.
  final ConflictWinner winner;

  /// Human-readable reason for the decision.
  final String reason;

  /// Merged data if winner is [ConflictWinner.merge].
  final Map<String, dynamic>? mergedData;

  /// Unique ID for this conflict (for audit trail).
  final String? conflictId;

  /// Whether this conflict should be logged for admin review.
  final bool shouldLog;

  /// Creates a resolution where local wins.
  factory ConflictResolution.localWins(String reason, {bool shouldLog = false}) {
    return ConflictResolution(
      winner: ConflictWinner.local,
      reason: reason,
      shouldLog: shouldLog,
    );
  }

  /// Creates a resolution where remote wins.
  factory ConflictResolution.remoteWins(String reason, {bool shouldLog = false}) {
    return ConflictResolution(
      winner: ConflictWinner.remote,
      reason: reason,
      shouldLog: shouldLog,
    );
  }

  /// Creates a resolution with merged data.
  factory ConflictResolution.merged(
    Map<String, dynamic> mergedData,
    String reason, {
    bool shouldLog = false,
  }) {
    return ConflictResolution(
      winner: ConflictWinner.merge,
      reason: reason,
      mergedData: mergedData,
      shouldLog: shouldLog,
    );
  }
}

/// Conflict audit record for admin review.
class ConflictAuditRecord {
  const ConflictAuditRecord({
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.resolution,
    required this.resolvedAt,
    required this.businessId,
    this.staffId,
  });

  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final ConflictResolution resolution;
  final DateTime resolvedAt;
  final String businessId;
  final String? staffId;

  Map<String, dynamic> toFirestore() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'localData': localData,
      'remoteData': remoteData,
      'winner': resolution.winner.name,
      'reason': resolution.reason,
      'resolvedAt': FieldValue.serverTimestamp(),
      'businessId': businessId,
      'staffId': staffId,
    };
  }
}

/// Service for resolving sync conflicts between local and remote data.
///
/// Implements conflict resolution strategies:
/// - Appointments: Server wins by default, unless local has newer changes
/// - Time Entries: Local always wins (staff's clock is authoritative)
/// - Clients: Server wins (admin manages client data)
class ConflictResolver {
  ConflictResolver({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Resolves conflict for appointment data.
  ///
  /// Strategy: Last write wins based on updatedAt timestamp.
  /// Server wins if timestamps are equal (tie-breaker).
  ConflictResolution resolveAppointmentConflict({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    final localUpdated = _parseTimestamp(local['updatedAt']);
    final remoteUpdated = _parseTimestamp(remote['updatedAt']);

    // If local has a newer timestamp, local wins
    if (localUpdated != null &&
        remoteUpdated != null &&
        localUpdated.isAfter(remoteUpdated)) {
      return ConflictResolution.localWins(
        'Local appointment has newer updatedAt timestamp',
        shouldLog: true,
      );
    }

    // Check for specific field conflicts that might need merge
    final localStatus = local['status'] as String?;
    final remoteStatus = remote['status'] as String?;

    // If local has check-in/complete but remote doesn't, preserve local action
    if (_isCompletionStatus(localStatus) && !_isCompletionStatus(remoteStatus)) {
      return ConflictResolution.localWins(
        'Local has completion status that remote lacks',
        shouldLog: true,
      );
    }

    // Server wins by default
    return ConflictResolution.remoteWins(
      'Server version is authoritative for appointments',
    );
  }

  /// Resolves conflict for time entry data.
  ///
  /// Strategy: Local ALWAYS wins - staff's clock is authoritative.
  /// This ensures staff's recorded work time is never overwritten by server.
  ConflictResolution resolveTimeEntryConflict({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    // Time entries: local always wins
    // Staff's recorded clock times are authoritative
    final localClockIn = _parseTimestamp(local['clockInTime']);
    final remoteClockIn = _parseTimestamp(remote['clockInTime']);

    // Check if this is a meaningful conflict (different clock times)
    if (localClockIn != null &&
        remoteClockIn != null &&
        localClockIn != remoteClockIn) {
      return ConflictResolution.localWins(
        'Time entry local version is authoritative (staff clock)',
        shouldLog: true, // Log significant time conflicts for admin review
      );
    }

    // Merge breaks data if both have different break entries
    final localBreaks = local['breaksJson'] as String?;
    final remoteBreaks = remote['breaksJson'] as String?;

    if (localBreaks != null && localBreaks != remoteBreaks) {
      return ConflictResolution.localWins(
        'Local break data preserved (staff authoritative)',
      );
    }

    return ConflictResolution.localWins(
      'Time entry defaults to local (staff authoritative)',
    );
  }

  /// Resolves conflict for client data.
  ///
  /// Strategy: Server wins - admin manages client data.
  ConflictResolution resolveClientConflict({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    // Client data: server wins
    // Admin/backend is authoritative for client records
    return ConflictResolution.remoteWins(
      'Client data managed by admin (server authoritative)',
    );
  }

  /// Logs a conflict resolution for admin audit trail.
  Future<void> logConflict(ConflictAuditRecord record) async {
    if (!record.resolution.shouldLog) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(record.businessId)
          .collection('syncConflicts')
          .add(record.toFirestore());
    } catch (e) {
      // Log errors silently - audit logging should not block sync
    }
  }

  /// Generic conflict resolution based on entity type.
  ConflictResolution resolveConflict({
    required String entityType,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    switch (entityType) {
      case 'appointment':
        return resolveAppointmentConflict(local: local, remote: remote);
      case 'time_entry':
        return resolveTimeEntryConflict(local: local, remote: remote);
      case 'client':
        return resolveClientConflict(local: local, remote: remote);
      default:
        // Default: server wins for unknown entity types
        return ConflictResolution.remoteWins(
          'Unknown entity type - defaulting to server',
        );
    }
  }

  // Helper methods

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  bool _isCompletionStatus(String? status) {
    return status == 'completed' ||
        status == 'checked_in' ||
        status == 'no_show';
  }
}
