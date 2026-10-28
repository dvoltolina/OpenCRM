import '../../data/models/payment.dart';
import '../../data/models/security_context.dart';
import '../../core/services/stripe_service.dart';
import 'booking_context_snapshot.dart';

/// Thrown when a payment gateway fails to collect a required deposit.
class BookingPaymentException implements Exception {
  BookingPaymentException(this.message);

  final String message;

  @override
  String toString() => 'BookingPaymentException: $message';
}

/// Abstraction for collecting deposits during the booking flow.
abstract class BookingPaymentGateway {
  Future<Payment> collectDeposit({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double amount,
    required String appointmentId,
    PaymentType paymentType = PaymentType.deposit,
  });

  /// Charge a reschedule fee for late appointment changes.
  Future<Payment> chargeRescheduleFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  });

  /// Charge a cancellation fee for late appointment cancellations.
  Future<Payment> chargeCancellationFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  });

  /// Calculate refund amount based on cancellation timing and policies.
  int calculateRefundAmount({
    required int originalAmountCents,
    required DateTime appointmentStartTime,
    required Duration cancellationWindow,
    DateTime? cancelledAt,
  });
}

/// Stripe implementation that relies on a Cloud Function to create payment
/// intents and the PaymentSheet UI to collect card details.
class StripeBookingPaymentGateway implements BookingPaymentGateway {
  StripeBookingPaymentGateway({
    required this.cloudFunctionUrl,
    this.currency = 'usd',
    StripeService? stripeService,
  }) : _stripeService = stripeService ?? StripeService.instance;

  final StripeService _stripeService;
  final String cloudFunctionUrl;
  final String currency;

  String? _destinationAccountId(BookingContextSnapshot snapshot) {
    final accountId = snapshot.provider.stripeAccountId;
    if (accountId == null || accountId.isEmpty) return null;
    return accountId;
  }

  int _computePlatformFee(int amountCents) {
    // 0.05% + $0.30 in cents
    final fee = (amountCents * 0.0005).floor() + 30;
    return fee;
  }

  @override
  Future<Payment> collectDeposit({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double amount,
    required String appointmentId,
    PaymentType paymentType = PaymentType.deposit,
  }) async {
    if (!_stripeService.isInitialized) {
      throw BookingPaymentException('Stripe is not initialized');
    }

    final amountCents = (amount * 100).round();
    final feeCents = _computePlatformFee(amountCents);

    final intentResponse = await _stripeService.createPaymentIntent(
      cloudFunctionUrl: cloudFunctionUrl,
      amountCents: amountCents,
      currency: currency,
      destinationAccountId: _destinationAccountId(snapshot),
      applicationFeeAmountCents: feeCents,
      metadata: {
        'appointmentId': appointmentId,
        'businessId': context.businessId,
        'clientId': snapshot.client.id,
        'providerId': snapshot.provider.id,
        'serviceId': snapshot.service.id,
        'paymentType': paymentType.name,
      },
    );

    final clientSecret = intentResponse['clientSecret'] as String?;
    final paymentIntentId = intentResponse['paymentIntentId'] as String?;

    if (clientSecret == null || paymentIntentId == null) {
      throw BookingPaymentException(
        'Payment intent response missing clientSecret/paymentIntentId',
      );
    }

    final success = await _stripeService.presentPaymentSheet(
      clientSecret: clientSecret,
    );

    if (!success) {
      throw BookingPaymentException('Payment sheet dismissed');
    }

    return Payment(
      id: paymentIntentId,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: snapshot.client.id,
      amountCents: amountCents,
      currency: currency.toUpperCase(),
      status: PaymentStatus.completed,
      type: paymentType,
      stripePaymentIntentId: paymentIntentId,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethodDescription: 'Stripe PaymentSheet',
    );
  }

  @override
  Future<Payment> chargeRescheduleFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  }) async {
    if (!_stripeService.isInitialized) {
      throw BookingPaymentException('Stripe is not initialized');
    }

    final amountCents = (feeAmount * 100).round();
    final feeCents = _computePlatformFee(amountCents);

    final metadata = {
      'appointmentId': appointmentId,
      'businessId': context.businessId,
      'clientId': snapshot.client.id,
      'providerId': snapshot.provider.id,
      'serviceId': snapshot.service.id,
      'paymentType': PaymentType.rescheduleFee.name,
      if (attendeeId != null) 'attendeeId': attendeeId,
    };

    final intentResponse = await _stripeService.createPaymentIntent(
      cloudFunctionUrl: cloudFunctionUrl,
      amountCents: amountCents,
      currency: currency,
      destinationAccountId: _destinationAccountId(snapshot),
      applicationFeeAmountCents: feeCents,
      metadata: metadata,
    );

    final clientSecret = intentResponse['clientSecret'] as String?;
    final paymentIntentId = intentResponse['paymentIntentId'] as String?;

    if (clientSecret == null || paymentIntentId == null) {
      throw BookingPaymentException(
        'Payment intent response missing clientSecret/paymentIntentId',
      );
    }

    final success = await _stripeService.presentPaymentSheet(
      clientSecret: clientSecret,
    );

    if (!success) {
      throw BookingPaymentException('Reschedule fee payment was cancelled');
    }

    return Payment(
      id: paymentIntentId,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: snapshot.client.id,
      amountCents: amountCents,
      currency: currency.toUpperCase(),
      status: PaymentStatus.completed,
      type: PaymentType.rescheduleFee,
      stripePaymentIntentId: paymentIntentId,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethodDescription: 'Stripe PaymentSheet',
      reason: 'Late reschedule fee',
      notes: attendeeId != null
          ? 'Group session attendee reschedule fee'
          : 'Appointment reschedule fee',
    );
  }

  @override
  Future<Payment> chargeCancellationFee({
    required BookingContextSnapshot snapshot,
    required SecurityContext context,
    required double feeAmount,
    required String appointmentId,
    String? attendeeId,
  }) async {
    if (!_stripeService.isInitialized) {
      throw BookingPaymentException('Stripe is not initialized');
    }

    final amountCents = (feeAmount * 100).round();
    final feeCents = _computePlatformFee(amountCents);

    final metadata = {
      'appointmentId': appointmentId,
      'businessId': context.businessId,
      'clientId': snapshot.client.id,
      'providerId': snapshot.provider.id,
      'serviceId': snapshot.service.id,
      'paymentType': PaymentType.cancellationFee.name,
      if (attendeeId != null) 'attendeeId': attendeeId,
    };

    final intentResponse = await _stripeService.createPaymentIntent(
      cloudFunctionUrl: cloudFunctionUrl,
      amountCents: amountCents,
      currency: currency,
      destinationAccountId: _destinationAccountId(snapshot),
      applicationFeeAmountCents: feeCents,
      metadata: metadata,
    );

    final clientSecret = intentResponse['clientSecret'] as String?;
    final paymentIntentId = intentResponse['paymentIntentId'] as String?;

    if (clientSecret == null || paymentIntentId == null) {
      throw BookingPaymentException(
        'Payment intent response missing clientSecret/paymentIntentId',
      );
    }

    final success = await _stripeService.presentPaymentSheet(
      clientSecret: clientSecret,
    );

    if (!success) {
      throw BookingPaymentException('Cancellation fee payment was cancelled');
    }

    return Payment(
      id: paymentIntentId,
      businessId: context.businessId,
      appointmentId: appointmentId,
      clientId: snapshot.client.id,
      amountCents: amountCents,
      currency: currency.toUpperCase(),
      status: PaymentStatus.completed,
      type: PaymentType.cancellationFee,
      stripePaymentIntentId: paymentIntentId,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethodDescription: 'Stripe PaymentSheet',
      reason: 'Late cancellation fee',
      notes: attendeeId != null
          ? 'Group session attendee cancellation fee'
          : 'Appointment cancellation fee',
    );
  }

  @override
  int calculateRefundAmount({
    required int originalAmountCents,
    required DateTime appointmentStartTime,
    required Duration cancellationWindow,
    DateTime? cancelledAt,
  }) {
    final cancellationTime = cancelledAt ?? DateTime.now();
    final timeUntilAppointment = appointmentStartTime.difference(cancellationTime);

    // If appointment already started or passed, no refund
    if (timeUntilAppointment.isNegative) {
      return 0;
    }

    // Calculate refund percentage based on timing:
    // - More than 48h before: 100% refund
    // - Between 24-48h before: 50% refund
    // - Less than 24h before: 0% refund

    final hoursUntil = timeUntilAppointment.inHours;

    if (hoursUntil > 48) {
      // Full refund
      return originalAmountCents;
    } else if (hoursUntil >= cancellationWindow.inHours) {
      // Partial refund (50%)
      return (originalAmountCents * 0.5).round();
    } else {
      // No refund (inside cancellation window)
      return 0;
    }
  }
}
