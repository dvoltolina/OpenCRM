import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_code.freezed.dart';
part 'join_code.g.dart';

/// Status of a join code in its lifecycle.
enum JoinCodeStatus {
  /// Code is active and can be used
  active,

  /// Code has been revoked by admin/owner
  revoked,

  /// Code has expired (past expiresAt date or max uses reached)
  expired,
}

/// Converter for Firestore Timestamp to DateTime.
class _TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const _TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  dynamic toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Converter for nullable Firestore Timestamp to DateTime.
class _NullableTimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const _NullableTimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return null;
  }

  @override
  dynamic toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object);
}

/// Represents a join code for staff onboarding.
///
/// Join codes allow staff to join a business using a shared code.
/// Codes are stored hashed (SHA-256) and never in plaintext.
/// Stored in Firestore at: `businesses/{businessId}/join_codes/{codeId}`
@freezed
abstract class JoinCode with _$JoinCode {
  const factory JoinCode({
    required String id,
    required String businessId,

    /// SHA-256 hash of the code (never plaintext)
    required String codeHash,

    /// User ID of the admin/owner who created this code
    required String createdBy,

    /// When the code was created
    @_TimestampConverter() required DateTime createdAt,

    /// When the code expires
    @_TimestampConverter() required DateTime expiresAt,

    /// Maximum number of times this code can be used
    required int maxUses,

    /// Current number of times this code has been used
    @Default(0) int uses,

    /// Role that will be assigned to users who join with this code
    required String role,

    /// Current status of the join code
    required JoinCodeStatus status,

    /// When the code was last used (optional)
    @_NullableTimestampConverter() DateTime? lastUsedAt,

    /// User ID of the last person who used this code (optional)
    String? lastUsedBy,

    /// Optional notes about this code (no PHI)
    String? notes,
  }) = _JoinCode;

  factory JoinCode.fromJson(Map<String, dynamic> json) =>
      _$JoinCodeFromJson(json);

  const JoinCode._();

  /// Create a JoinCode from Firestore document
  factory JoinCode.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return JoinCode.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convert JoinCode to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  /// Check if the code has expired based on date
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the code is usable (active, not expired, has remaining uses)
  bool get isUsable =>
      status == JoinCodeStatus.active && !isExpired && uses < maxUses;

  /// Calculate remaining uses for this code
  int get remainingUses => (maxUses - uses).clamp(0, maxUses);
}
