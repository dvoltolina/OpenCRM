import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_request.freezed.dart';
part 'join_request.g.dart';

/// Status of a join request in its lifecycle.
enum JoinRequestStatus {
  /// Request is pending admin/owner review
  pending,

  /// Request has been approved by admin/owner
  approved,

  /// Request has been denied by admin/owner
  denied,
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

/// Represents a join request for staff onboarding.
///
/// Join requests are created when a user attempts to join a business
/// and approval is required (when feature flag is enabled).
/// Stored in Firestore at: `businesses/{businessId}/join_requests/{requestId}`
@freezed
abstract class JoinRequest with _$JoinRequest {
  const factory JoinRequest({
    required String id,
    required String businessId,

    /// User ID of the person requesting to join
    required String requestorUserId,

    /// Email address of the requestor
    required String requestorEmail,

    /// Display name of the requestor
    required String requestorDisplayName,

    /// Role the requestor is asking for
    required String role,

    /// Current status of the request
    required JoinRequestStatus status,

    /// Device/client metadata (no PHI, for audit purposes)
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,

    /// When the request was created
    @_TimestampConverter() required DateTime createdAt,

    /// When the request was reviewed (optional)
    @_NullableTimestampConverter() DateTime? reviewedAt,

    /// User ID of the admin/owner who reviewed the request (optional)
    String? reviewedBy,

    /// Notes from the reviewer about approval/denial (optional)
    String? reviewNotes,
  }) = _JoinRequest;

  factory JoinRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestFromJson(json);

  const JoinRequest._();

  /// Create a JoinRequest from Firestore document
  factory JoinRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return JoinRequest.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convert JoinRequest to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  /// Check if the request is still pending
  bool get isPending => status == JoinRequestStatus.pending;

  /// Check if the request has been approved
  bool get isApproved => status == JoinRequestStatus.approved;
}
