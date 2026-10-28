import 'package:freezed_annotation/freezed_annotation.dart';
// Export user_role.dart so that UserRolePermissions extension is available
// to any file that imports security_context.dart
export 'user_role.dart' show UserRole, UserRolePermissions;
import 'user_role.dart';

part 'security_context.freezed.dart';
part 'security_context.g.dart';

/// Security context containing authentication and authorization info.
/// Used to enforce multi-tenant isolation in repositories and queries.
@freezed
abstract class SecurityContext with _$SecurityContext {
  const factory SecurityContext({
    required String userId, // Firebase Auth UID
    required String businessId, // Current business context
    @Default(UserRole.client) UserRole role,
    @Default(<String>[]) List<String> roles,
    String? providerId, // Set if user is a staff member
    String? clientId, // Set if user is a client
    String? userFullName, // Optional cached user display name
    String? authToken, // Tenant-scoped JWT for AI/microservices
  }) = _SecurityContext;

  factory SecurityContext.fromJson(Map<String, dynamic> json) =>
      SecurityContext(
        userId: json['userId'] as String,
        businessId: json['businessId'] as String,
        role: parseUserRole(json['role'], fallback: UserRole.client),
        roles:
            (json['roles'] as List?)?.whereType<String>().toList() ?? const [],
        providerId: json['providerId'] as String?,
        clientId: json['clientId'] as String?,
        userFullName: json['userFullName'] as String?,
        authToken: json['authToken'] as String?,
      );

  const SecurityContext._();

  /// Create from UserProfile
  factory SecurityContext.fromUserProfile(UserProfile profile) {
    return SecurityContext(
      userId: profile.id,
      businessId: profile.businessId,
      role: profile.role,
      providerId: profile.providerId,
      clientId: profile.clientId,
      userFullName: profile.displayName,
    );
  }

  /// Verify access to business (multi-tenant isolation)
  void verifyBusinessAccess([String? targetBusinessId]) {
    final target = targetBusinessId ?? businessId;
    if (businessId != target) {
      throw SecurityException(
        'Access denied: User does not have access to business $target',
      );
    }
  }

  /// Verify client access
  void verifyClientAccess(String targetClientId, String targetBusinessId) {
    verifyBusinessAccess(targetBusinessId);
    if (!role.canManageClients && clientId != targetClientId) {
      throw SecurityException(
        'Access denied: User cannot access client $targetClientId',
      );
    }
  }

  /// Verify provider access
  void verifyProviderAccess(String targetProviderId, String targetBusinessId) {
    verifyBusinessAccess(targetBusinessId);
    if (!role.canManageProviders && providerId != targetProviderId) {
      throw SecurityException(
        'Access denied: User cannot access provider $targetProviderId',
      );
    }
  }

  /// Check if user can perform admin operations
  bool get isAdmin => role.canManageUsers;

  /// Check if user is owner
  bool get isOwner => role.canManageBusiness;

  /// Check if user can manage payments/refunds
  bool get canManagePayments => role.canManagePayments;

  /// Ensure caller can manage payment records
  void verifyPaymentAccess() {
    if (!canManagePayments) {
      throw SecurityException(
        'Access denied: User cannot manage payments for this business',
      );
    }
  }
}

/// Security exception thrown when access is denied
class SecurityException implements Exception {
  SecurityException(this.message);

  final String message;

  @override
  String toString() => 'SecurityException: $message';
}
