import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../data/models/appointment.dart';
import '../../data/models/payment.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/payment_repository.dart';
import '../config/app_config.dart' show BookingPolicies;

/// Service for processing refunds based on cancellation timing and business policies
///
/// Handles:
/// - Refund calculation based on cancellation timing
/// - Stripe refund API calls via Cloud Function
/// - Payment record updates
/// - Refund status tracking
class RefundService {
  RefundService({
    required this.bookingPolicies,
    required this.paymentRepository,
    this.refundCloudFunctionUrl,
  });

  final BookingPolicies bookingPolicies;
  final PaymentRepository paymentRepository;
  final String? refundCloudFunctionUrl;

  static const _uuid = Uuid();

  /// Calculate refund eligibility and amount based on cancellation timing
  ///
  /// Returns:
  /// - null if no refund applicable
  /// - RefundCalculation with amount and reason
  RefundCalculation? calculateRefundAmount({
    required Appointment appointment,
    required DateTime cancellationTime,
    required int paymentAmountCents,
  }) {
    if (!appointment.refundEligible) {
      return null;
    }

    // If no cancellation window defined, no refund
    final cancellationWindow = bookingPolicies.cancellationWindow;

    // Calculate time until appointment
    final timeUntilAppointment =
        appointment.startTime.difference(cancellationTime);

    // If cancelling after appointment started, no refund
    if (timeUntilAppointment.isNegative) {
      return RefundCalculation(
        refundAmountCents: 0,
        refundPercentage: 0,
        reason: 'Cancellation after appointment time - no refund',
        isFullRefund: false,
      );
    }

    // If cancelling within cancellation window, apply penalty
    if (timeUntilAppointment < cancellationWindow) {
      // Late cancellation: 50% refund
      final refundAmountCents = (paymentAmountCents * 0.5).round();
      return RefundCalculation(
        refundAmountCents: refundAmountCents,
        refundPercentage: 50,
        reason:
            'Late cancellation (within ${cancellationWindow.inHours}h window) - 50% refund',
        isFullRefund: false,
      );
    }

    // Cancelling outside window: full refund
    return RefundCalculation(
      refundAmountCents: paymentAmountCents,
      refundPercentage: 100,
      reason: 'Cancellation outside window - full refund',
      isFullRefund: true,
    );
  }

  /// Process a refund for a cancelled appointment
  ///
  /// Steps:
  /// 1. Calculate refund amount based on timing
  /// 2. Call Stripe API to process refund
  /// 3. Create refund payment record
  /// 4. Update source payment with refund status
  ///
  /// Returns the refund Payment record or null if no refund
  Future<Payment?> processRefund({
    required SecurityContext context,
    required Appointment appointment,
    required Payment sourcePayment,
    required String cancellationReason,
  }) async {
    // Calculate refund
    final calculation = calculateRefundAmount(
      appointment: appointment,
      cancellationTime: DateTime.now(),
      paymentAmountCents: sourcePayment.amountCents,
    );

    if (calculation == null || calculation.refundAmountCents == 0) {
      return null;
    }

    // Call Stripe to process refund
    String? stripeRefundId;
    if (refundCloudFunctionUrl != null &&
        sourcePayment.stripePaymentIntentId != null) {
      try {
        stripeRefundId = await _callStripeRefund(
          paymentIntentId: sourcePayment.stripePaymentIntentId!,
          amountCents: calculation.refundAmountCents,
          reason: cancellationReason,
        );
      } catch (e) {
        // Log error but continue - record refund anyway for manual processing
        developer.log(
          'Stripe refund failed',
          name: 'RefundService',
        );
      }
    }

    // Create refund payment record
    final refundPayment = Payment(
      id: _uuid.v4(),
      businessId: context.businessId,
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      amountCents: calculation.refundAmountCents,
      currency: sourcePayment.currency,
      status:
          stripeRefundId != null ? PaymentStatus.completed : PaymentStatus.pending,
      type: PaymentType.refund,
      stripeRefundId: stripeRefundId,
      parentPaymentId: sourcePayment.id,
      reason: calculation.reason,
      notes: cancellationReason,
      createdAt: DateTime.now(),
      completedAt: stripeRefundId != null ? DateTime.now() : null,
      refundedAt: stripeRefundId != null ? DateTime.now() : null,
    );

    // Save refund record and update source payment
    await paymentRepository.recordRefund(
      context: context,
      sourcePayment: sourcePayment,
      refundPayment: refundPayment,
    );

    return refundPayment;
  }

  /// Call Stripe Cloud Function to process refund
  Future<String> _callStripeRefund({
    required String paymentIntentId,
    required int amountCents,
    required String reason,
  }) async {
    if (refundCloudFunctionUrl == null) {
      throw Exception('Refund Cloud Function URL not configured');
    }

    _ensureHttps(refundCloudFunctionUrl!);

    final response = await http.post(
      Uri.parse(refundCloudFunctionUrl!),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentIntentId': paymentIntentId,
        'amount': amountCents,
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Stripe refund failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['refundId'] as String;
  }

  void _ensureHttps(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme.toLowerCase() != 'https') {
      throw ArgumentError('RefundService requires HTTPS endpoints');
    }
  }
}

/// Refund calculation result
class RefundCalculation {
  RefundCalculation({
    required this.refundAmountCents,
    required this.refundPercentage,
    required this.reason,
    required this.isFullRefund,
  });

  final int refundAmountCents;
  final int refundPercentage;
  final String reason;
  final bool isFullRefund;

  double get refundAmountDollars => refundAmountCents / 100.0;
}
