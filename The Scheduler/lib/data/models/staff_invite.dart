import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

enum StaffInviteStatus { pending, active, revoked, expired, exhausted }

class StaffInvite {
  const StaffInvite({
    required this.id,
    required this.businessId,
    this.email,
    this.name,
    required this.assignedRole,
    this.codeHash,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.status,
    required this.createdByUserId,
    this.permissions = const [],
  });

  final String id;
  final String businessId;
  final String? email;
  final String? name;
  final UserRole assignedRole;
  final String? codeHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final StaffInviteStatus status;
  final String createdByUserId;
  final List<String> permissions;

  int get remainingUses => (maxUses - usedCount).clamp(0, maxUses);
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StaffInvite.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StaffInvite.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  factory StaffInvite.fromJson(Map<String, dynamic> json) {
    return StaffInvite(
      id: json['id'] as String,
      businessId: json['businessId'] as String? ?? '',
      email: json['email'] as String?,
      name: json['name'] as String?,
      assignedRole: parseUserRole(
        json['assignedRole'] as String? ?? json['role'],
      ),
      codeHash: json['codeHash'] as String?,
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      expiresAt: _toDate(json['expiresAt']) ?? DateTime.now(),
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      status: _statusFromString(json['status'] as String?),
      createdByUserId: json['createdByUserId'] as String? ??
          json['createdBy'] as String? ??
          '',
      permissions: (json['permissions'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'email': email,
      'name': name,
      'assignedRole': assignedRole.name,
      'codeHash': codeHash,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'status': status.name,
      'createdByUserId': createdByUserId,
      'permissions': permissions,
    };
  }

  static StaffInviteStatus _statusFromString(String? value) {
    switch (value) {
      case 'pending':
        return StaffInviteStatus.pending;
      case 'revoked':
        return StaffInviteStatus.revoked;
      case 'expired':
        return StaffInviteStatus.expired;
      case 'exhausted':
        return StaffInviteStatus.exhausted;
      case 'active':
      default:
        return StaffInviteStatus.active;
    }
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
