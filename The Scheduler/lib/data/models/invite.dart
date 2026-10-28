import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite.freezed.dart';
part 'invite.g.dart';

/// Status of an invite in its lifecycle.
enum InviteStatus {
  /// Invite is pending acceptance
  pending,

  /// Invite has been accepted
  accepted,

  /// Invite has been revoked by admin/owner
  revoked,

  /// Invite has expired (past expiresAt date)
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

/// Represents an email-specific invite for staff onboarding.
///
/// Invites are sent to a specific email address and can only be used once.
/// The invite token is stored hashed (SHA-256) and never in plaintext.
/// Stored in Firestore at: `businesses/{businessId}/invites/{inviteId}`
@freezed
abstract class Invite with _$Invite {
  const factory Invite({
    required String id,
    required String businessId,

    /// Email address this invite was sent to
    required String email,

    /// Role that will be assigned to the user who accepts this invite
    required String role,

    /// SHA-256 hash of the invite token (never plaintext)
    required String tokenHash,

    /// User ID of the admin/owner who created this invite
    required String createdBy,

    /// When the invite was created
    @_TimestampConverter() required DateTime createdAt,

    /// When the invite expires
    @_TimestampConverter() required DateTime expiresAt,

    /// Current status of the invite
    required InviteStatus status,

    /// When the invite was accepted (optional)
    @_NullableTimestampConverter() DateTime? acceptedAt,

    /// User ID of the person who accepted this invite (optional)
    String? acceptedBy,

    /// Optional notes about this invite (no PHI)
    String? notes,
  }) = _Invite;

  factory Invite.fromJson(Map<String, dynamic> json) =>
      _$InviteFromJson(json);

  const Invite._();

  /// Create an Invite from Firestore document
  factory Invite.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Invite.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convert Invite to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  /// Check if the invite has expired based on date
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the invite is still pending
  bool get isPending => status == InviteStatus.pending && !isExpired;
}
