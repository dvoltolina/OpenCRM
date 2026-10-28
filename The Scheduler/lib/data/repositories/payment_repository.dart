import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/audit_log.dart';
import '../models/payment.dart';
import '../models/security_context.dart';
import 'audit_log_repository.dart';

/// Repository for managing payment and refund records per business.
///
/// All operations enforce multi-tenant isolation via [SecurityContext].
/// PHI read operations are logged via [AuditLogRepository] for HIPAA compliance.
class PaymentRepository {
  PaymentRepository({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  CollectionReference<Map<String, dynamic>> _paymentsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('payments');
  }

  /// Default limit for payment list queries to control Firebase costs.
  static const int defaultLimit = 50;

  /// Stream payments for the current business.
  ///
  /// - Admin/owner roles can optionally filter by [appointmentId] or [clientId].
  /// - Clients can only view their own payments.
  /// - [limit] controls max documents returned (default: 50).
  Stream<List<Payment>> watchPayments(
    SecurityContext context, {
    String? appointmentId,
    String? clientId,
    int limit = defaultLimit,
  }) {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _paymentsCollection(
      context.businessId,
    ).orderBy('createdAt', descending: true);

    if (!context.canManagePayments) {
      if (context.clientId == null) {
        throw SecurityException(
          'Access denied: user is not allowed to view payments',
        );
      }
      query = query.where('clientId', isEqualTo: context.clientId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    if (appointmentId != null) {
      query = query.where('appointmentId', isEqualTo: appointmentId);
    }

    query = query.limit(limit);

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Payment',
      entityId: clientId ?? appointmentId ?? 'all',
      metadata: {
        'source': 'watchPayments',
        'mode': 'stream',
        'limit': limit,
        if (clientId != null) 'filterClientId': clientId,
        if (appointmentId != null) 'filterAppointmentId': appointmentId,
      },
    ));

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => Payment.fromJson(
              _decodePaymentDoc(doc),
            ),
          )
          .toList(),
    );
  }

  /// Fetch payments once for reporting or validation.
  Future<List<Payment>> fetchPayments(
    SecurityContext context, {
    String? appointmentId,
    String? clientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    context.verifyBusinessAccess();

    Query<Map<String, dynamic>> query = _paymentsCollection(context.businessId);

    if (!context.canManagePayments) {
      if (context.clientId == null) {
        throw SecurityException(
          'Access denied: user is not allowed to view payments',
        );
      }
      query = query.where('clientId', isEqualTo: context.clientId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    if (appointmentId != null) {
      query = query.where('appointmentId', isEqualTo: appointmentId);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    final payments = snapshot.docs
        .map(
          (doc) => Payment.fromJson(
            _decodePaymentDoc(doc),
          ),
        )
        .toList();

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Payment',
      entityId: clientId ?? appointmentId ?? 'all',
      metadata: {
        'source': 'fetchPayments',
        'mode': 'fetch',
        'resultCount': payments.length,
        if (clientId != null) 'filterClientId': clientId,
        if (appointmentId != null) 'filterAppointmentId': appointmentId,
        if (startDate != null) 'hasDateFilter': true,
      },
    ));

    return payments;
  }

  /// Fetch payments for a list of appointment IDs (chunked for Firestore limits).
  Future<List<Payment>> fetchPaymentsForAppointments({
    required SecurityContext context,
    required List<String> appointmentIds,
  }) async {
    if (appointmentIds.isEmpty) return [];

    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final payments = <Payment>[];

    // Firestore whereIn supports up to 10 values; chunk the queries accordingly.
    for (var i = 0; i < appointmentIds.length; i += 10) {
      final chunk = appointmentIds.sublist(
        i,
        min(i + 10, appointmentIds.length),
      );

      final snapshot = await _paymentsCollection(context.businessId)
          .where('appointmentId', whereIn: chunk)
          .get();

      payments.addAll(
        snapshot.docs
            .map((doc) => Payment.fromJson(_decodePaymentDoc(doc))),
      );
    }

    // HIPAA: Log PHI list read (one event per logical action)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Payment',
      entityId: 'batch',
      metadata: {
        'source': 'fetchPaymentsForAppointments',
        'mode': 'batch',
        'appointmentCount': appointmentIds.length,
        'resultCount': payments.length,
      },
    ));

    return payments;
  }

  /// Convenience wrapper to mirror analytics needs.
  Future<List<Payment>> getPaymentsByAppointmentIds({
    required SecurityContext context,
    required List<String> appointmentIds,
  }) {
    return fetchPaymentsForAppointments(
      context: context,
      appointmentIds: appointmentIds,
    );
  }

  /// Convenience wrapper for client-specific streams (parity with legacy repo).
  Stream<List<Payment>> watchClientPayments({
    required SecurityContext context,
    required String clientId,
  }) =>
      watchPayments(context, clientId: clientId);

  /// Convenience wrapper for client-specific fetch (parity with legacy repo).
  Future<List<Payment>> getClientPayments({
    required SecurityContext context,
    required String clientId,
  }) =>
      fetchPayments(context, clientId: clientId);

  /// Convenience wrapper for single-payment lookup (parity with legacy repo).
  Future<Payment?> getPayment({
    required SecurityContext context,
    required String paymentId,
  }) =>
      getPaymentById(context, paymentId);

  /// Retrieve a single payment by ID.
  Future<Payment?> getPaymentById(
    SecurityContext context,
    String paymentId,
  ) async {
    context.verifyBusinessAccess();

    final doc = await _paymentsCollection(
      context.businessId,
    ).doc(paymentId).get();
    if (!doc.exists) return null;

    final payment = Payment.fromJson(_decodePaymentDoc(doc));

    if (!context.canManagePayments &&
        context.clientId != null &&
        payment.clientId != context.clientId) {
      throw SecurityException('Access denied: user cannot view this payment');
    }

    // HIPAA: Log PHI single-entity read
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'Payment',
      entityId: paymentId,
      metadata: {'source': 'getPaymentById'},
    ));

    return payment;
  }

  /// Insert or update a payment record.
  Future<void> upsertPayment({
    required SecurityContext context,
    required Payment payment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save payment');
    }
    context.verifyBusinessAccess(payment.businessId);
    final isOwnPayment =
        context.clientId != null && context.clientId == payment.clientId;
    if (!context.canManagePayments && !isOwnPayment) {
      throw SecurityException(
        'Access denied: user cannot create payments for other clients',
      );
    }

    await _paymentsCollection(
      payment.businessId,
    ).doc(payment.id).set(payment.toJson(), SetOptions(merge: true));
  }

  /// Update status metadata for an existing payment.
  Future<void> updatePaymentStatus({
    required SecurityContext context,
    required String paymentId,
    required PaymentStatus status,
    int? refundAmountCents,
    DateTime? refundedAt,
    String? stripePaymentIntentId,
    String? stripeRefundId,
    String? errorMessage,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update payment');
    }
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final update = <String, dynamic>{
      'status': status.name,
      if (refundAmountCents != null) 'refundAmountCents': refundAmountCents,
      if (refundedAt != null) 'refundedAt': refundedAt,
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
      if (stripeRefundId != null) 'stripeRefundId': stripeRefundId,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _paymentsCollection(context.businessId).doc(paymentId).update(update);
  }

  /// Record a refund transaction linked to the source payment.
  Future<void> recordRefund({
    required SecurityContext context,
    required Payment sourcePayment,
    required Payment refundPayment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('record refund');
    }
    context.verifyBusinessAccess(sourcePayment.businessId);
    final isOwnPayment =
        context.clientId != null && context.clientId == sourcePayment.clientId;
    if (!context.canManagePayments && !isOwnPayment) {
      throw SecurityException(
        'Access denied: user cannot record refunds for this payment',
      );
    }

    if (refundPayment.type != PaymentType.refund) {
      throw ArgumentError('refundPayment.type must be PaymentType.refund');
    }
    if (refundPayment.businessId != sourcePayment.businessId) {
      throw ArgumentError('Refund must belong to the same business as source');
    }
    if (refundPayment.appointmentId != sourcePayment.appointmentId) {
      throw ArgumentError('Refund must target the same appointment');
    }

    final paymentsRef = _paymentsCollection(sourcePayment.businessId);
    final batch = _firestore.batch();

    // Insert refund record
    batch.set(
      paymentsRef.doc(refundPayment.id),
      refundPayment.toJson(),
      SetOptions(merge: true),
    );

    final cumulativeRefund =
        (sourcePayment.refundAmountCents ?? 0) + refundPayment.amountCents;
    final isFullRefund = cumulativeRefund >= sourcePayment.amountCents;
    final newStatus = isFullRefund
        ? PaymentStatus.refunded
        : PaymentStatus.partiallyRefunded;

    batch.update(paymentsRef.doc(sourcePayment.id), {
      'refundAmountCents': cumulativeRefund,
      'status': newStatus.name,
      'refundedAt': refundPayment.refundedAt ?? FieldValue.serverTimestamp(),
      if (refundPayment.stripeRefundId != null)
        'stripeRefundId': refundPayment.stripeRefundId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Map<String, dynamic> _decodePaymentDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return {'id': doc.id};

    final normalized = Map<String, dynamic>.from(data);

    void normalizeField(String key) {
      final value = normalized[key];
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        normalized[key] = value.toIso8601String();
      }
    }

    normalizeField('createdAt');
    normalizeField('completedAt');
    normalizeField('refundedAt');

    return {'id': doc.id, ...normalized};
  }
}
