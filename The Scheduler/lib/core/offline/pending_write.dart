/// Represents a write operation queued for offline processing.
///
/// Used to safely queue critical writes when offline:
/// - Appointment status changes (check-in, complete, no-show)
/// - Task updates (create, complete, edit)
/// - Quick notes (create, edit)
///
/// Each write has:
/// - Unique ID (deterministic for idempotency)
/// - Type (appointmentStatus, task, note)
/// - Payload (serialized data)
/// - Timestamps for tracking
/// - Retry count for backoff
class PendingWrite {
  PendingWrite({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.isProcessing = false,
    this.lastAttemptAt,
    this.lastError,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final bool isProcessing;
  final DateTime? lastAttemptAt;
  final String? lastError;

  /// Creates a copy with modified fields
  PendingWrite copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    bool? isProcessing,
    DateTime? lastAttemptAt,
    String? lastError,
  }) {
    return PendingWrite(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      isProcessing: isProcessing ?? this.isProcessing,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'isProcessing': isProcessing,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  /// Deserialize from JSON
  factory PendingWrite.fromJson(Map<String, dynamic> json) {
    return PendingWrite(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      isProcessing: json['isProcessing'] as bool? ?? false,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }

  @override
  String toString() {
    return 'PendingWrite(id: $id, type: $type, retryCount: $retryCount)';
  }
}

/// Types of pending writes
class PendingWriteType {
  static const String appointmentStatus = 'appointmentStatus';
  static const String taskCreate = 'taskCreate';
  static const String taskUpdate = 'taskUpdate';
  static const String taskDelete = 'taskDelete';
  static const String noteCreate = 'noteCreate';
  static const String noteUpdate = 'noteUpdate';
}
