import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'guest_session.freezed.dart';
part 'guest_session.g.dart';

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

/// Guest session for users booking without creating an account.
///
/// Security Notes:
/// - verificationCodeHash is SHA-256 hash, never plaintext
/// - Sessions expire after 24 hours
/// - Max 3 verification attempts per session
///
/// HIPAA Notes:
/// - Guest contact info becomes PHI when linked to appointments
/// - Do not log this data to console or analytics
/// - Handle appropriately after booking completion
@freezed
abstract class GuestSession with _$GuestSession {
  const factory GuestSession({
    required String id,
    required String businessId,
    required String fullName,
    required String email,
    required String phone,
    required GuestVerificationMethod verificationMethod,
    required bool isVerified,
    @_TimestampConverter() required DateTime expiresAt,
    @_TimestampConverter() DateTime? verifiedAt,
    @_TimestampConverter() DateTime? createdAt,
  }) = _GuestSession;

  factory GuestSession.fromJson(Map<String, dynamic> json) =>
      _$GuestSessionFromJson(json);

  const GuestSession._();

  /// Check if session is still valid
  bool get isValid => isVerified && expiresAt.isAfter(DateTime.now());

  /// Check if session is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Method used for guest verification
enum GuestVerificationMethod {
  @JsonValue('sms')
  sms,
  @JsonValue('email')
  email,
}

/// Result of sending a verification code
@freezed
abstract class VerificationResult with _$VerificationResult {
  const factory VerificationResult({
    required String sessionId,
    @_TimestampConverter() required DateTime expiresAt,
    required int attemptsRemaining,
  }) = _VerificationResult;

  factory VerificationResult.fromJson(Map<String, dynamic> json) =>
      _$VerificationResultFromJson(json);
}
