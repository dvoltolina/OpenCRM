import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'magic_link_token.freezed.dart';
part 'magic_link_token.g.dart';

/// Magic link token for secure, login-free appointment access
///
/// Provides time-limited, secure access to appointment details without requiring
/// user authentication. Used for customer-facing booking confirmation and management.
@freezed
abstract class MagicLinkToken with _$MagicLinkToken {
  const factory MagicLinkToken({
    /// Unique token ID
    required String id,

    /// Business this token belongs to (multi-tenant isolation)
    required String businessId,

    /// Associated appointment ID
    required String appointmentId,

    /// Associated client ID
    required String clientId,

    /// Client email (for verification)
    required String clientEmail,

    /// Token string (random secure string)
    required String token,

    /// Token creation timestamp
    @TimestampConverter() required DateTime createdAt,

    /// Token expiration timestamp (typically 48 hours from creation)
    @TimestampConverter() required DateTime expiresAt,

    /// Whether the token has been used/accessed
    @Default(false) bool hasBeenUsed,

    /// Last accessed timestamp (null if never accessed)
    @NullableTimestampConverter() DateTime? lastAccessedAt,

    /// Number of times this token has been accessed
    @Default(0) int accessCount,

    /// Token status
    @Default(MagicLinkTokenStatus.active) MagicLinkTokenStatus status,
  }) = _MagicLinkToken;

  factory MagicLinkToken.fromJson(Map<String, dynamic> json) =>
      _$MagicLinkTokenFromJson(json);
}

/// Extension methods for MagicLinkToken
extension MagicLinkTokenX on MagicLinkToken {
  /// Check if token is still valid
  bool get isValid {
    if (status != MagicLinkTokenStatus.active) return false;
    return DateTime.now().isBefore(expiresAt);
  }

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get human-readable expiration time
  String get expirationDisplay {
    final now = DateTime.now();
    if (isExpired) return 'Expired';

    final diff = expiresAt.difference(now);
    if (diff.inHours > 24) {
      return 'Expires in ${diff.inDays} days';
    } else if (diff.inHours > 1) {
      return 'Expires in ${diff.inHours} hours';
    } else {
      return 'Expires in ${diff.inMinutes} minutes';
    }
  }
}

/// Magic link token status
enum MagicLinkTokenStatus {
  /// Token is active and can be used
  active,

  /// Token has been revoked (e.g., appointment cancelled)
  revoked,

  /// Token has expired
  expired,
}
