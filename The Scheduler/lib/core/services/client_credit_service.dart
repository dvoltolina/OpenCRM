import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/audit_log.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/audit_log_repository.dart';

/// Represents a client credit balance that can be applied to future bookings.
class ClientCredit {
  ClientCredit({
    required this.id,
    required this.businessId,
    required this.clientId,
    required this.amountCents,
    required this.currency,
    required this.createdAt,
    this.expiresAt,
    this.sourcePaymentId,
    this.sourceAppointmentId,
    this.reason,
    this.notes,
  });

  final String id;
  final String businessId;
  final String clientId;
  final int amountCents;
  final String currency;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? sourcePaymentId;
  final String? sourceAppointmentId;
  final String? reason;
  final String? notes;

  double get amountDollars => amountCents / 100.0;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'clientId': clientId,
      'amountCents': amountCents,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (sourcePaymentId != null) 'sourcePaymentId': sourcePaymentId,
      if (sourceAppointmentId != null)
        'sourceAppointmentId': sourceAppointmentId,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
    };
  }

  factory ClientCredit.fromMap(String id, Map<String, dynamic> data) {
    return ClientCredit(
      id: id,
      businessId: data['businessId'] as String,
      clientId: data['clientId'] as String,
      amountCents: data['amountCents'] as int,
      currency: data['currency'] as String? ?? 'USD',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      sourcePaymentId: data['sourcePaymentId'] as String?,
      sourceAppointmentId: data['sourceAppointmentId'] as String?,
      reason: data['reason'] as String?,
      notes: data['notes'] as String?,
    );
  }
}

/// Service for managing client credit balances as an alternative to refunds.
///
/// Credits can be issued instead of refunds and applied to future bookings.
/// This service handles:
/// - Issuing credits from refunds
/// - Tracking credit balances per client
/// - Applying credits to new bookings
/// - Handling credit expiration
///
/// All operations are HIPAA-compliant with audit logging for PHI access.
class ClientCreditService {
  ClientCreditService({
    FirebaseFirestore? firestore,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _creditsCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('clientCredits');
  }

  /// Issue a credit to a client (e.g., from a refund).
  Future<ClientCredit> issueCredit({
    required SecurityContext context,
    required String clientId,
    required int amountCents,
    required String currency,
    DateTime? expiresAt,
    String? sourcePaymentId,
    String? sourceAppointmentId,
    String? reason,
    String? notes,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final credit = ClientCredit(
      id: _uuid.v4(),
      businessId: context.businessId,
      clientId: clientId,
      amountCents: amountCents,
      currency: currency,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      sourcePaymentId: sourcePaymentId,
      sourceAppointmentId: sourceAppointmentId,
      reason: reason,
      notes: notes,
    );

    await _creditsCollection(context.businessId)
        .doc(credit.id)
        .set(credit.toMap());

    // HIPAA audit log for credit issuance
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'ClientCredit',
      entityId: credit.id,
      metadata: {
        'source': 'issueCredit',
        'clientId': clientId,
        'amountCents': amountCents,
        'currency': currency,
        'hasExpiration': expiresAt != null,
      },
    ));

    return credit;
  }

  /// Get total available credit balance for a client (non-expired).
  Future<int> getCreditBalance({
    required SecurityContext context,
    required String clientId,
    String? currency,
  }) async {
    context.verifyBusinessAccess();

    final query = _creditsCollection(context.businessId)
        .where('clientId', isEqualTo: clientId);

    final snapshot = await query.get();
    final now = DateTime.now();

    int totalCents = 0;
    for (final doc in snapshot.docs) {
      final credit = ClientCredit.fromMap(doc.id, doc.data());

      // Filter by currency if specified
      if (currency != null && credit.currency != currency) {
        continue;
      }

      // Skip expired credits
      if (credit.expiresAt != null && now.isAfter(credit.expiresAt!)) {
        continue;
      }

      totalCents += credit.amountCents;
    }

    // HIPAA audit log for balance read
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'ClientCredit',
      entityId: clientId,
      metadata: {
        'source': 'getCreditBalance',
        'clientId': clientId,
        'creditCount': snapshot.docs.length,
      },
    ));

    return totalCents;
  }

  /// Stream all credits for a client.
  Stream<List<ClientCredit>> watchClientCredits({
    required SecurityContext context,
    required String clientId,
    bool includeExpired = false,
  }) {
    context.verifyBusinessAccess();

    // HIPAA audit log for stream subscription (logged once at start)
    _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'ClientCredit',
      entityId: clientId,
      metadata: {
        'source': 'watchClientCredits',
        'clientId': clientId,
        'includeExpired': includeExpired,
      },
    ));

    final query = _creditsCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => ClientCredit.fromMap(doc.id, doc.data()))
          .where((credit) {
        if (includeExpired) return true;
        return credit.expiresAt == null || now.isBefore(credit.expiresAt!);
      }).toList();
    });
  }

  /// Fetch available credits for a client (non-expired).
  Future<List<ClientCredit>> getAvailableCredits({
    required SecurityContext context,
    required String clientId,
    String? currency,
  }) async {
    context.verifyBusinessAccess();

    final query = _creditsCollection(context.businessId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('expiresAt'); // Use oldest expiring first

    final snapshot = await query.get();
    final now = DateTime.now();

    final credits = snapshot.docs
        .map((doc) => ClientCredit.fromMap(doc.id, doc.data()))
        .where((credit) {
      // Filter by currency if specified
      if (currency != null && credit.currency != currency) {
        return false;
      }

      // Exclude expired
      return credit.expiresAt == null || now.isBefore(credit.expiresAt!);
    }).toList();

    // HIPAA audit log for credits read
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'ClientCredit',
      entityId: clientId,
      metadata: {
        'source': 'getAvailableCredits',
        'clientId': clientId,
        'creditCount': credits.length,
      },
    ));

    return credits;
  }

  /// Apply credits to a payment, consuming oldest expiring credits first.
  ///
  /// Returns the amount of credit applied in cents.
  Future<int> applyCreditsToPayment({
    required SecurityContext context,
    required String clientId,
    required int paymentAmountCents,
    required String currency,
    required String appointmentId,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final availableCredits = await getAvailableCredits(
      context: context,
      clientId: clientId,
      currency: currency,
    );

    if (availableCredits.isEmpty) {
      return 0;
    }

    int remainingToPay = paymentAmountCents;
    final batch = _firestore.batch();
    final creditsToConsume = <String>[];

    // Consume credits oldest expiring first
    for (final credit in availableCredits) {
      if (remainingToPay <= 0) break;

      if (credit.amountCents <= remainingToPay) {
        // Consume entire credit
        creditsToConsume.add(credit.id);
        batch.delete(_creditsCollection(context.businessId).doc(credit.id));
        remainingToPay -= credit.amountCents;
      } else {
        // Partial consumption - reduce credit amount
        final updatedAmount = credit.amountCents - remainingToPay;
        batch.update(
          _creditsCollection(context.businessId).doc(credit.id),
          {'amountCents': updatedAmount},
        );
        remainingToPay = 0;
      }
    }

    if (creditsToConsume.isNotEmpty || remainingToPay < paymentAmountCents) {
      await batch.commit();
    }

    final appliedAmount = paymentAmountCents - remainingToPay;

    // HIPAA audit log for credit application
    if (appliedAmount > 0) {
      await _auditLogRepository.logEvent(AuditLogEntry(
        businessId: context.businessId,
        userId: context.userId,
        actionType: AuditActionType.phiWrite,
        entityType: 'ClientCredit',
        entityId: appointmentId,
        metadata: {
          'source': 'applyCreditsToPayment',
          'clientId': clientId,
          'appliedAmountCents': appliedAmount,
          'creditsConsumed': creditsToConsume.length,
        },
      ));
    }

    return appliedAmount;
  }

  /// Delete an expired credit.
  Future<void> deleteExpiredCredit({
    required SecurityContext context,
    required String creditId,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    await _creditsCollection(context.businessId).doc(creditId).delete();

    // HIPAA audit log for credit deletion
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'ClientCredit',
      entityId: creditId,
      metadata: {
        'source': 'deleteExpiredCredit',
        'action': 'delete',
      },
    ));
  }

  /// Clean up all expired credits for a business (batch operation).
  Future<int> cleanupExpiredCredits({
    required SecurityContext context,
  }) async {
    context.verifyBusinessAccess();
    context.verifyPaymentAccess();

    final now = DateTime.now();
    final snapshot = await _creditsCollection(context.businessId)
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // HIPAA audit log for batch cleanup
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'ClientCredit',
      entityId: 'batch-cleanup',
      metadata: {
        'source': 'cleanupExpiredCredits',
        'action': 'batchDelete',
        'deletedCount': snapshot.docs.length,
      },
    ));

    return snapshot.docs.length;
  }
}
