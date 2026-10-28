import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment.dart';

/// Attendee metadata for group sessions/classes.
enum GroupAttendeeStatus { registered, attended, noShow, cancelled }

class GroupAttendee {
  GroupAttendee({
    required this.id,
    required this.clientId,
    required this.displayName,
    this.email,
    this.phone,
    this.status = GroupAttendeeStatus.registered,
    this.paymentStatus = PaymentStatus.none,
    this.refundStatus = PaymentStatus.none,
    this.paymentId,
    this.notes,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  final String id;
  final String clientId;
  final String displayName;
  final String? email;
  final String? phone;
  final GroupAttendeeStatus status;
  final PaymentStatus paymentStatus;
  final PaymentStatus refundStatus;
  final String? paymentId;
  final String? notes;
  final DateTime joinedAt;

  GroupAttendee copyWith({
    GroupAttendeeStatus? status,
    PaymentStatus? paymentStatus,
    PaymentStatus? refundStatus,
    String? paymentId,
    String? notes,
  }) {
    return GroupAttendee(
      id: id,
      clientId: clientId,
      displayName: displayName,
      email: email,
      phone: phone,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      refundStatus: refundStatus ?? this.refundStatus,
      paymentId: paymentId ?? this.paymentId,
      notes: notes ?? this.notes,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'refundStatus': refundStatus.name,
      'paymentId': paymentId,
      'notes': notes,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory GroupAttendee.fromMap(String id, Map<String, dynamic> data) {
    return GroupAttendee(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Guest',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      status: _statusFromString(data['status'] as String?),
      paymentStatus: _paymentFromString(data['paymentStatus'] as String?),
      refundStatus: _paymentFromString(data['refundStatus'] as String?),
      paymentId: data['paymentId'] as String?,
      notes: data['notes'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static GroupAttendeeStatus _statusFromString(String? raw) {
    return GroupAttendeeStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => GroupAttendeeStatus.registered,
    );
  }

  static PaymentStatus _paymentFromString(String? raw) {
    return PaymentStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => PaymentStatus.none,
    );
  }
}
