class PaymentConfig {
  const PaymentConfig({
    required this.paymentIntentFunctionUrl,
    this.currency = 'usd',
    this.giftCardPaymentFunctionUrl,
    this.giftCardBalanceFunctionUrl,
    this.giftCardResendEmailFunctionUrl,
    this.posPaymentFunctionUrl,
    this.refundFunctionUrl,
    this.defaultTaxRate = 0.0825,
  });

  /// HTTPS Cloud Function endpoint that creates Stripe Payment Intents.
  final String paymentIntentFunctionUrl;

  /// ISO currency code used for client payments.
  final String currency;

  /// HTTPS Cloud Function endpoint for creating gift card payment intents.
  final String? giftCardPaymentFunctionUrl;

  /// HTTPS Cloud Function endpoint for checking gift card balance.
  final String? giftCardBalanceFunctionUrl;

  /// Callable Cloud Function endpoint for resending gift card emails.
  final String? giftCardResendEmailFunctionUrl;

  /// HTTPS Cloud Function endpoint for POS payment intents.
  final String? posPaymentFunctionUrl;

  /// HTTPS Cloud Function endpoint for processing refunds.
  final String? refundFunctionUrl;

  /// Default tax rate for POS transactions (e.g., 0.0825 = 8.25%).
  /// Can be overridden per-business or per-transaction.
  final double defaultTaxRate;

  PaymentConfig copyWith({
    String? paymentIntentFunctionUrl,
    String? currency,
    String? giftCardPaymentFunctionUrl,
    String? giftCardBalanceFunctionUrl,
    String? giftCardResendEmailFunctionUrl,
    String? posPaymentFunctionUrl,
    String? refundFunctionUrl,
    double? defaultTaxRate,
  }) {
    return PaymentConfig(
      paymentIntentFunctionUrl:
          paymentIntentFunctionUrl ?? this.paymentIntentFunctionUrl,
      currency: currency ?? this.currency,
      giftCardPaymentFunctionUrl:
          giftCardPaymentFunctionUrl ?? this.giftCardPaymentFunctionUrl,
      giftCardBalanceFunctionUrl:
          giftCardBalanceFunctionUrl ?? this.giftCardBalanceFunctionUrl,
      giftCardResendEmailFunctionUrl:
          giftCardResendEmailFunctionUrl ?? this.giftCardResendEmailFunctionUrl,
      posPaymentFunctionUrl:
          posPaymentFunctionUrl ?? this.posPaymentFunctionUrl,
      refundFunctionUrl: refundFunctionUrl ?? this.refundFunctionUrl,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
    );
  }
}

