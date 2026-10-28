import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart' show BookingPolicies;
import '../../../../data/models/appointment.dart';
import '../../../../data/models/group_attendee.dart';
import '../../../../data/models/payment.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/group_attendees_repository.dart';
import '../../../../data/repositories/payment_repository.dart';

/// Result of a group session attendee cancellation with refund/fee details.
class AttendeeCancellationResult {
  AttendeeCancellationResult({
    required this.refundAmountCents,
    required this.cancellationFeeCents,
    required this.isLateCancel,
    this.refundPayment,
    this.feePayment,
    this.message,
  });

  /// Amount refunded to attendee (0 if no refund).
  final int refundAmountCents;

  /// Cancellation fee charged (0 if no fee).
  final int cancellationFeeCents;

  /// Whether the cancellation was inside the policy window.
  final bool isLateCancel;

  /// The refund Payment record (if created).
  final Payment? refundPayment;

  /// The cancellation fee Payment record (if created).
  final Payment? feePayment;

  /// Human-readable message about the outcome.
  final String? message;

  double get refundAmountDollars => refundAmountCents / 100.0;
  double get cancellationFeeDollars => cancellationFeeCents / 100.0;

  /// Net amount returned to attendee (refund - fee).
  int get netRefundCents => refundAmountCents - cancellationFeeCents;
}

/// Configuration for how cancellation refunds are calculated.
class GroupCancellationPolicy {
  const GroupCancellationPolicy({
    this.cancellationWindow = const Duration(hours: 24),
    this.lateRefundPercentage = 50,
    this.cancellationFeeAmount,
    this.allowLateCancellation = true,
  });

  /// Time before session start that defines "late" cancellation.
  final Duration cancellationWindow;

  /// Percentage of original payment refunded for late cancellations (0-100).
  final int lateRefundPercentage;

  /// Fixed cancellation fee amount in dollars (null = no fee).
  final double? cancellationFeeAmount;

  /// Whether late cancellations are allowed at all.
  final bool allowLateCancellation;

  /// Create from BookingPolicies for consistency with 1:1 appointments.
  factory GroupCancellationPolicy.fromBookingPolicies(BookingPolicies policies) {
    return GroupCancellationPolicy(
      cancellationWindow: policies.cancellationWindow,
      lateRefundPercentage: 50, // Default: 50% refund for late cancellations
      cancellationFeeAmount: policies.cancellationFeeAmount,
      allowLateCancellation: true,
    );
  }
}

/// Helper to keep attendee payment/refund updates in sync with ledger records.
///
/// This helper ensures that when staff mark group session attendees as paid or
/// refunded, the corresponding Payment records are created/updated in the ledger
/// for proper financial tracking and reconciliation.
///
/// Also handles policy-based cancellation fee logic for group sessions,
/// mirroring the cancellation/refund logic from RefundService for 1:1 appointments.
class GroupSessionBillingHelper {
  const GroupSessionBillingHelper({
    required this.paymentRepository,
    required this.attendeesRepository,
    this.currency = 'USD',
    this.cancellationPolicy = const GroupCancellationPolicy(),
  });

  final PaymentRepository paymentRepository;
  final GroupAttendeesRepository attendeesRepository;
  final String currency;
  final GroupCancellationPolicy cancellationPolicy;

  static const _uuid = Uuid();

  Future<void> markPaid({
    required SecurityContext actorContext,
    required Appointment appointment,
    required GroupAttendee attendee,
    required int amountCents,
  }) async {
    final payment = Payment(
      id: attendee.paymentId ?? _uuid.v4(),
      businessId: appointment.businessId,
      appointmentId: appointment.id,
      clientId: attendee.clientId,
      amountCents: amountCents,
      currency: currency,
      status: PaymentStatus.completed,
      type: PaymentType.full,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethodDescription: 'Marked paid by staff',
    );

    await paymentRepository.upsertPayment(
      context: actorContext,
      payment: payment,
    );

    await attendeesRepository.upsertAttendee(
      context: actorContext,
      appointmentId: appointment.id,
      attendee: attendee.copyWith(
        paymentStatus: PaymentStatus.completed,
        refundStatus: PaymentStatus.none,
        paymentId: payment.id,
      ),
    );
  }

  Future<void> markRefunded({
    required SecurityContext actorContext,
    required Appointment appointment,
    required GroupAttendee attendee,
    required int refundAmountCents,
  }) async {
    final resolvedAmount = refundAmountCents < 0 ? 0 : refundAmountCents;
    Payment? sourcePayment;
    if (attendee.paymentId != null) {
      sourcePayment = await paymentRepository.getPaymentById(
        actorContext,
        attendee.paymentId!,
      );
    }

    final refundPayment = Payment(
      id: _uuid.v4(),
      businessId: appointment.businessId,
      appointmentId: appointment.id,
      clientId: attendee.clientId,
      amountCents: resolvedAmount,
      currency: currency,
      status: PaymentStatus.refunded,
      type: PaymentType.refund,
      parentPaymentId: sourcePayment?.id,
      createdAt: DateTime.now(),
      refundedAt: DateTime.now(),
      notes: 'Refund recorded by staff',
    );

    if (sourcePayment != null) {
      await paymentRepository.recordRefund(
        context: actorContext,
        sourcePayment: sourcePayment,
        refundPayment: refundPayment,
      );
    } else {
      await paymentRepository.upsertPayment(
        context: actorContext,
        payment: refundPayment,
      );
    }

    await attendeesRepository.upsertAttendee(
      context: actorContext,
      appointmentId: appointment.id,
      attendee: attendee.copyWith(
        refundStatus: PaymentStatus.refunded,
        paymentStatus: PaymentStatus.refunded,
        paymentId: attendee.paymentId ?? sourcePayment?.id ?? refundPayment.id,
      ),
    );
  }

  /// Process an attendee cancellation with policy-based refund/fee calculation.
  ///
  /// This method handles the full cancellation workflow:
  /// 1. Determines if cancellation is "late" (inside policy window)
  /// 2. Calculates refund amount (full or partial based on timing)
  /// 3. Applies any cancellation fees if configured
  /// 4. Creates Payment records for refund and/or fee
  /// 5. Updates attendee payment status
  ///
  /// Returns [AttendeeCancellationResult] with details of the financial outcome.
  Future<AttendeeCancellationResult> processAttendeeCancellation({
    required SecurityContext actorContext,
    required Appointment appointment,
    required GroupAttendee attendee,
    required int originalPaymentCents,
    String? cancellationReason,
  }) async {
    final now = DateTime.now();
    final timeUntilSession = appointment.startTime.difference(now);
    final isLate = timeUntilSession < cancellationPolicy.cancellationWindow;

    // If session already started, no refund
    if (timeUntilSession.isNegative) {
      return AttendeeCancellationResult(
        refundAmountCents: 0,
        cancellationFeeCents: 0,
        isLateCancel: true,
        message: 'Session has already started - no refund available.',
      );
    }

    // If attendee never paid, just mark cancelled
    if (attendee.paymentStatus != PaymentStatus.completed ||
        originalPaymentCents <= 0) {
      await attendeesRepository.upsertAttendee(
        context: actorContext,
        appointmentId: appointment.id,
        attendee: attendee.copyWith(
          status: GroupAttendeeStatus.cancelled,
        ),
      );
      return AttendeeCancellationResult(
        refundAmountCents: 0,
        cancellationFeeCents: 0,
        isLateCancel: isLate,
        message: 'No payment to refund.',
      );
    }

    // Calculate refund amount based on timing
    int refundAmountCents;
    String message;

    if (isLate) {
      // Late cancellation: partial refund based on policy
      final percentage = cancellationPolicy.lateRefundPercentage;
      refundAmountCents = (originalPaymentCents * percentage / 100).round();
      message = 'Late cancellation (within ${_formatDuration(cancellationPolicy.cancellationWindow)}) '
          '- $percentage% refund applied.';
    } else {
      // On-time cancellation: full refund
      refundAmountCents = originalPaymentCents;
      message = 'Full refund issued for on-time cancellation.';
    }

    // Calculate any cancellation fee
    int cancellationFeeCents = 0;
    if (isLate && cancellationPolicy.cancellationFeeAmount != null) {
      cancellationFeeCents = (cancellationPolicy.cancellationFeeAmount! * 100).round();
      message += ' Cancellation fee of \$${cancellationPolicy.cancellationFeeAmount!.toStringAsFixed(2)} applied.';
    }

    // Load source payment if exists
    Payment? sourcePayment;
    if (attendee.paymentId != null) {
      sourcePayment = await paymentRepository.getPaymentById(
        actorContext,
        attendee.paymentId!,
      );
    }

    // Create refund payment record
    Payment? refundPayment;
    if (refundAmountCents > 0) {
      refundPayment = Payment(
        id: _uuid.v4(),
        businessId: appointment.businessId,
        appointmentId: appointment.id,
        clientId: attendee.clientId,
        amountCents: refundAmountCents,
        currency: currency,
        status: PaymentStatus.completed,
        type: PaymentType.refund,
        parentPaymentId: sourcePayment?.id,
        createdAt: now,
        refundedAt: now,
        completedAt: now,
        reason: isLate
            ? 'Late group session cancellation - ${cancellationPolicy.lateRefundPercentage}% refund'
            : 'Group session cancellation - full refund',
        notes: cancellationReason,
      );

      if (sourcePayment != null) {
        await paymentRepository.recordRefund(
          context: actorContext,
          sourcePayment: sourcePayment,
          refundPayment: refundPayment,
        );
      } else {
        await paymentRepository.upsertPayment(
          context: actorContext,
          payment: refundPayment,
        );
      }
    }

    // Create cancellation fee payment record
    Payment? feePayment;
    if (cancellationFeeCents > 0) {
      feePayment = Payment(
        id: _uuid.v4(),
        businessId: appointment.businessId,
        appointmentId: appointment.id,
        clientId: attendee.clientId,
        amountCents: cancellationFeeCents,
        currency: currency,
        status: PaymentStatus.pending, // Staff may need to collect this
        type: PaymentType.cancellationFee,
        createdAt: now,
        reason: 'Late group session cancellation fee',
        notes: cancellationReason,
      );

      await paymentRepository.upsertPayment(
        context: actorContext,
        payment: feePayment,
      );
    }

    // Determine final payment/refund status
    final newPaymentStatus = refundAmountCents >= originalPaymentCents
        ? PaymentStatus.refunded
        : PaymentStatus.partiallyRefunded;

    // Update attendee record
    await attendeesRepository.upsertAttendee(
      context: actorContext,
      appointmentId: appointment.id,
      attendee: attendee.copyWith(
        status: GroupAttendeeStatus.cancelled,
        paymentStatus: newPaymentStatus,
        refundStatus: newPaymentStatus,
      ),
    );

    return AttendeeCancellationResult(
      refundAmountCents: refundAmountCents,
      cancellationFeeCents: cancellationFeeCents,
      isLateCancel: isLate,
      refundPayment: refundPayment,
      feePayment: feePayment,
      message: message,
    );
  }

  /// Preview what the cancellation outcome would be without actually processing.
  ///
  /// Use this to show the user what refund/fee they would receive before confirming.
  AttendeeCancellationResult previewCancellation({
    required Appointment appointment,
    required GroupAttendee attendee,
    required int originalPaymentCents,
  }) {
    final now = DateTime.now();
    final timeUntilSession = appointment.startTime.difference(now);
    final isLate = timeUntilSession < cancellationPolicy.cancellationWindow;

    // Session already started
    if (timeUntilSession.isNegative) {
      return AttendeeCancellationResult(
        refundAmountCents: 0,
        cancellationFeeCents: 0,
        isLateCancel: true,
        message: 'Session has already started - no refund available.',
      );
    }

    // Never paid
    if (attendee.paymentStatus != PaymentStatus.completed ||
        originalPaymentCents <= 0) {
      return AttendeeCancellationResult(
        refundAmountCents: 0,
        cancellationFeeCents: 0,
        isLateCancel: isLate,
        message: 'No payment on file.',
      );
    }

    int refundAmountCents;
    String message;

    if (isLate) {
      final percentage = cancellationPolicy.lateRefundPercentage;
      refundAmountCents = (originalPaymentCents * percentage / 100).round();
      message = 'Late cancellation - $percentage% refund (\$${(refundAmountCents / 100).toStringAsFixed(2)})';
    } else {
      refundAmountCents = originalPaymentCents;
      message = 'Full refund (\$${(refundAmountCents / 100).toStringAsFixed(2)})';
    }

    int cancellationFeeCents = 0;
    if (isLate && cancellationPolicy.cancellationFeeAmount != null) {
      cancellationFeeCents = (cancellationPolicy.cancellationFeeAmount! * 100).round();
      message += ' + \$${cancellationPolicy.cancellationFeeAmount!.toStringAsFixed(2)} fee';
    }

    return AttendeeCancellationResult(
      refundAmountCents: refundAmountCents,
      cancellationFeeCents: cancellationFeeCents,
      isLateCancel: isLate,
      message: message,
    );
  }

  /// Fetch payment summary for a group session (all attendee payments).
  Future<GroupSessionPaymentSummary> getPaymentSummary({
    required SecurityContext context,
    required String appointmentId,
    required List<GroupAttendee> attendees,
  }) async {
    if (attendees.isEmpty) {
      return GroupSessionPaymentSummary.empty();
    }

    final payments = await paymentRepository.fetchPayments(
      context,
      appointmentId: appointmentId,
    );

    int totalCollected = 0;
    int totalRefunded = 0;
    int pendingFees = 0;
    int paidCount = 0;
    int refundedCount = 0;

    for (final payment in payments) {
      if (payment.type == PaymentType.refund) {
        totalRefunded += payment.amountCents;
        refundedCount++;
      } else if (payment.type == PaymentType.cancellationFee) {
        if (payment.status == PaymentStatus.pending) {
          pendingFees += payment.amountCents;
        } else if (payment.status == PaymentStatus.completed) {
          totalCollected += payment.amountCents;
        }
      } else if (payment.status == PaymentStatus.completed) {
        totalCollected += payment.amountCents;
        paidCount++;
      }
    }

    return GroupSessionPaymentSummary(
      totalCollectedCents: totalCollected,
      totalRefundedCents: totalRefunded,
      pendingFeesCents: pendingFees,
      paidAttendeesCount: paidCount,
      refundedAttendeesCount: refundedCount,
      totalAttendeesCount: attendees.length,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}

/// Summary of all payments for a group session.
class GroupSessionPaymentSummary {
  GroupSessionPaymentSummary({
    required this.totalCollectedCents,
    required this.totalRefundedCents,
    required this.pendingFeesCents,
    required this.paidAttendeesCount,
    required this.refundedAttendeesCount,
    required this.totalAttendeesCount,
  });

  factory GroupSessionPaymentSummary.empty() {
    return GroupSessionPaymentSummary(
      totalCollectedCents: 0,
      totalRefundedCents: 0,
      pendingFeesCents: 0,
      paidAttendeesCount: 0,
      refundedAttendeesCount: 0,
      totalAttendeesCount: 0,
    );
  }

  final int totalCollectedCents;
  final int totalRefundedCents;
  final int pendingFeesCents;
  final int paidAttendeesCount;
  final int refundedAttendeesCount;
  final int totalAttendeesCount;

  double get totalCollectedDollars => totalCollectedCents / 100.0;
  double get totalRefundedDollars => totalRefundedCents / 100.0;
  double get pendingFeesDollars => pendingFeesCents / 100.0;

  /// Net revenue (collected - refunded)
  int get netRevenueCents => totalCollectedCents - totalRefundedCents;
  double get netRevenueDollars => netRevenueCents / 100.0;
}
