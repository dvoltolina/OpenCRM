import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

enum StaffStatus { active, pending, deactivated }

class StaffMember {
  const StaffMember({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.businessId,
    this.photoUrl,
    this.providerId,
    this.lastLoginAt,
    this.createdAt,
    this.permissions = const [],
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final StaffStatus status;
  final String businessId;
  final String? photoUrl;
  final String? providerId;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final List<String> permissions;

  bool get isActive => status == StaffStatus.active;
  bool get isPending => status == StaffStatus.pending;
  bool get isDeactivated => status == StaffStatus.deactivated;

  StaffMember copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    StaffStatus? status,
    String? businessId,
    String? photoUrl,
    String? providerId,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    List<String>? permissions,
  }) {
    return StaffMember(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      businessId: businessId ?? this.businessId,
      photoUrl: photoUrl ?? this.photoUrl,
      providerId: providerId ?? this.providerId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
    );
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: _roleFromString(json['role'] as String?),
      status: _statusFromString(json['status'] as String?),
      businessId: json['businessId'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      providerId: json['providerId'] as String?,
      lastLoginAt: _toDate(json['lastLoginAt']),
      createdAt: _toDate(json['createdAt']),
      permissions: (json['permissions'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }

  factory StaffMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StaffMember.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'businessId': businessId,
      'photoUrl': photoUrl,
      'providerId': providerId,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt,
      'permissions': permissions,
    };
  }

  static UserRole _roleFromString(String? value) {
    return parseUserRole(value);
  }

  static StaffStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return StaffStatus.pending;
      case 'deactivated':
        return StaffStatus.deactivated;
      case 'active':
      default:
        return StaffStatus.active;
    }
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      // assume milliseconds
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
