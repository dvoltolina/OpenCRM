import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'modification_request.freezed.dart';
part 'modification_request.g.dart';

/// Type of modification the client is requesting.
enum ModificationRequestType { reschedule, cancel }

/// Status of the modification workflow.
enum ModificationRequestStatus { pending, approved, rejected, autoApproved }

/// Firestore-backed model representing a reschedule/cancel request.
@freezed
abstract class ModificationRequest with _$ModificationRequest {
  const factory ModificationRequest({
    required String id,
    required String businessId,
    required String appointmentId,
    required String clientId,
    required String providerId,
    required ModificationRequestType type,
    @Default(ModificationRequestStatus.pending)
    ModificationRequestStatus status,
    @NullableTimestampConverter() DateTime? requestedStartTime,
    int? requestedDurationMinutes,
    String? reason,
    @Default(false) bool policyWindowBreached,
    @Default(false) bool feeRequired,
    double? feeAmount,
    @Default(false) bool feeCollected,
    String? requestedByName,
    String? requestedByEmail,
    @NullableTimestampConverter() DateTime? decisionAt,
    String? decidedBy,
    String? decisionNotes,
    @TimestampConverter() required DateTime createdAt,
    @NullableTimestampConverter() DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) = _ModificationRequest;

  factory ModificationRequest.fromJson(Map<String, dynamic> json) =>
      _$ModificationRequestFromJson(json);
}
