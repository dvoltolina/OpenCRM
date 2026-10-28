import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/group_attendee.dart';
import '../models/payment.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

class GroupAttendeesRepository {
  GroupAttendeesRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  Stream<List<GroupAttendee>> watchAttendees({
    required SecurityContext context,
    required String appointmentId,
  }) {
    _ensureCanView(context);
    final stream = _attendeesRef(context.businessId, appointmentId)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupAttendee.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return _withAuditLogOnFirstEmission(
      stream: stream,
      context: context,
      appointmentId: appointmentId,
    );
  }

  Future<void> upsertAttendee({
    required SecurityContext context,
    required String appointmentId,
    required GroupAttendee attendee,
  }) async {
    DemoGuardService.assertReadOnly('save group attendee');
    _ensureCanEdit(context, attendee.clientId);
    await _attendeesRef(
      context.businessId,
      appointmentId,
    ).doc(attendee.id).set(attendee.toMap(), SetOptions(merge: true));
  }

  Future<void> updateStatuses({
    required SecurityContext context,
    required String appointmentId,
    required String attendeeId,
    GroupAttendeeStatus? status,
    PaymentStatus? paymentStatus,
    PaymentStatus? refundStatus,
  }) async {
    if (status == null && paymentStatus == null && refundStatus == null) {
      return;
    }
    DemoGuardService.assertReadOnly('update group attendee');
    _ensureCanEdit(context, null);
    final update = <String, Object?>{};
    if (status != null) update['status'] = status.name;
    if (paymentStatus != null) update['paymentStatus'] = paymentStatus.name;
    if (refundStatus != null) update['refundStatus'] = refundStatus.name;
    await _attendeesRef(
      context.businessId,
      appointmentId,
    ).doc(attendeeId).update(update);
  }

  Future<void> removeAttendee({
    required SecurityContext context,
    required String appointmentId,
    required String attendeeId,
  }) async {
    DemoGuardService.assertReadOnly('remove group attendee');
    _ensureCanEdit(context, null);
    await _attendeesRef(context.businessId, appointmentId).doc(attendeeId).set({
      'status': GroupAttendeeStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<GroupAttendee?> getAttendee({
    required SecurityContext context,
    required String appointmentId,
    required String attendeeId,
  }) async {
    _ensureCanView(context);
    final doc = await _attendeesRef(
      context.businessId,
      appointmentId,
    ).doc(attendeeId).get();
    if (!doc.exists) return null;
    final attendee = GroupAttendee.fromMap(doc.id, doc.data()!);

    // HIPAA: Log PHI single-entity read
    unawaited(
      _auditLogRepository.logEvent(
        AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiRead,
          entityType: 'GroupAttendee',
          entityId: attendeeId,
          metadata: {'source': 'getAttendee', 'appointmentId': appointmentId},
        ),
      ),
    );

    return attendee;
  }

  CollectionReference<Map<String, dynamic>> _attendeesRef(
    String businessId,
    String appointmentId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments')
        .doc(appointmentId)
        .collection('attendees');
  }

  void _ensureCanView(SecurityContext context) {
    if (_isStaff(context)) {
      return;
    }
    if (context.clientId != null) return;
    throw SecurityException('Not authorized to view attendees');
  }

  void _ensureCanEdit(SecurityContext context, String? clientId) {
    if (_isStaff(context)) {
      return;
    }
    if (clientId != null && context.clientId == clientId) return;
    throw SecurityException('Not authorized to modify attendees');
  }

  bool _isStaff(SecurityContext context) {
    return context.role.canManageAllAppointments ||
        context.role.canManageClients ||
        context.providerId != null;
  }

  /// Log once per stream subscription to avoid per-document audit noise.
  Stream<List<GroupAttendee>> _withAuditLogOnFirstEmission({
    required Stream<List<GroupAttendee>> stream,
    required SecurityContext context,
    required String appointmentId,
  }) {
    var hasLogged = false;
    return stream.map((data) {
      if (!hasLogged) {
        hasLogged = true;
        unawaited(
          _auditLogRepository.logEvent(
            AuditLogEntry(
              businessId: context.businessId,
              userId: context.userId,
              actionType: AuditActionType.phiReadList,
              entityType: 'GroupAttendee',
              entityId: appointmentId,
              metadata: {
                'source': 'watchAttendees',
                'mode': 'list',
                'count': data.length,
              },
            ),
          ),
        );
      }
      return data;
    });
  }
}
