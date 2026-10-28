import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_role.freezed.dart';
part 'user_role.g.dart';

/// Converter for Firestore Timestamp to DateTime.
/// Handles Timestamp, String (ISO8601), and int (milliseconds) formats.
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

/// User role enum for role-based access control (RBAC).
///
/// Hierarchy (highest → lowest):
/// - owner
/// - admin
/// - staff (legacy)
/// - client
/// - manager
/// - sales
/// - provider
/// - frontDesk
enum UserRole {
  owner,
  admin,
  staff,
  client,
  manager,
  sales,
  provider,
  frontDesk,
}

const Map<String, UserRole> _legacyUserRoleMap = {
  'assistant': UserRole.frontDesk,
  'sales_rep': UserRole.sales,
  'marketing': UserRole.sales,
  'user': UserRole.staff,
};

UserRole parseUserRole(dynamic value, {UserRole fallback = UserRole.staff}) {
  if (value is String) {
    final normalized = value.trim();
    for (final role in UserRole.values) {
      if (role.name == normalized) {
        return role;
      }
    }
    return _legacyUserRoleMap[normalized] ?? fallback;
  }
  return fallback;
}

/// Extension to check role permissions
extension UserRolePermissions on UserRole {
  /// Can manage business settings
  bool get canManageBusiness => this == UserRole.owner;

  /// Can manage all users
  bool get canManageUsers => this == UserRole.owner || this == UserRole.admin;

  /// Can manage all appointments
  bool get canManageAllAppointments =>
      this == UserRole.owner || this == UserRole.admin || this == UserRole.manager;

  /// Can manage providers and services
  bool get canManageProviders =>
      this == UserRole.owner || this == UserRole.admin || this == UserRole.manager;

  /// Can manage clients
  bool get canManageClients =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.staff ||
      this == UserRole.provider;

  /// Can manage payments, refunds, and billing settings
  bool get canManagePayments =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.staff ||
      this == UserRole.provider;

  /// Can view own appointments
  bool get canViewOwnAppointments => true;

  /// Can manage own schedule (for staff)
  bool get canManageOwnSchedule =>
      this == UserRole.owner ||
      this == UserRole.admin ||
      this == UserRole.manager ||
      this == UserRole.sales ||
      this == UserRole.provider ||
      this == UserRole.staff;
}

/// User profile linking Firebase Auth to business context with RBAC
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id, // Firebase Auth UID
    required String businessId,
    required UserRole role,
    String? providerId, // Set if user is a staff member
    String? clientId, // Set if user is a client
    String? email,
    String? displayName,
    @_TimestampConverter() required DateTime createdAt,
    @_NullableTimestampConverter() DateTime? lastLoginAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        role: parseUserRole(json['role']),
        providerId: json['providerId'] as String?,
        clientId: json['clientId'] as String?,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        createdAt: const _TimestampConverter().fromJson(json['createdAt']),
        lastLoginAt:
            const _NullableTimestampConverter().fromJson(json['lastLoginAt']),
      );

  const UserProfile._();

  /// Check if user has access to a specific business
  bool hasAccessToBusiness(String targetBusinessId) {
    return businessId == targetBusinessId;
  }

  /// Check if user can access a specific client's data
  bool canAccessClient(String targetClientId, String targetBusinessId) {
    if (!hasAccessToBusiness(targetBusinessId)) return false;
    if (role.canManageClients) return true;
    return clientId == targetClientId;
  }

  /// Check if user can access a specific provider's data
  bool canAccessProvider(String targetProviderId, String targetBusinessId) {
    if (!hasAccessToBusiness(targetBusinessId)) return false;
    if (role.canManageProviders) return true;
    return providerId == targetProviderId;
  }
}
