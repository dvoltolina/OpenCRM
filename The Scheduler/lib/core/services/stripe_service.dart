import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/demo_config.dart';
import 'demo_guard_service.dart';

/// Service for managing Stripe payment integration
///
/// This service handles initialization of the Stripe SDK and provides
/// methods for creating payment intents and managing subscriptions.
///
/// Environment variables required:
/// - STRIPE_PUBLISHABLE_KEY: Stripe publishable key for client-side
/// - STRIPE_SECRET_KEY: Stripe secret key for server-side (Cloud Functions only)
class StripeService {
  StripeService._();

  static final instance = StripeService._();

  bool _initialized = false;

  /// Initialize Stripe with publishable key
  ///
  /// This should be called early in app initialization, typically in main.dart
  /// after Firebase initialization.
  ///
  /// Example:
  /// ```dart
  /// await StripeService.instance.initialize(
  ///   publishableKey: 'pk_test_...',
  ///   merchantDisplayName: 'The Scheduler',
  /// );
  /// ```
  Future<void> initialize({
    required String publishableKey,
    String? merchantDisplayName,
  }) async {
    if (DemoConfig.isDemoMode) {
      debugPrint('Stripe disabled in demo mode');
      return;
    }
    if (_initialized) {
      assert(() {
        debugPrint('StripeService already initialized');
        return true;
      }());
      return;
    }

    try {
      Stripe.publishableKey = publishableKey;
      Stripe.merchantIdentifier = merchantDisplayName ?? 'The Scheduler';
      
      // Configure Stripe instance
      await Stripe.instance.applySettings();

      _initialized = true;
      assert(() {
        debugPrint('StripeService initialized successfully');
        return true;
      }());
    } catch (e) {
      debugPrint('Failed to initialize Stripe'); // avoid printing secrets/PII
      rethrow;
    }
  }

  /// Whether Stripe has been initialized
  bool get isInitialized => _initialized;

  /// Present payment sheet for client payments
  ///
  /// This is used when a client is booking an appointment and needs to pay
  /// a deposit or full amount.
  ///
  /// The [clientSecret] should be obtained from a Cloud Function that creates
  /// a Stripe Payment Intent server-side.
  ///
  /// Example usage:
  /// ```dart
  /// final clientSecret = await createPaymentIntent(amountCents: 5000);
  /// final success = await StripeService.instance.presentPaymentSheet(
  ///   clientSecret: clientSecret,
  /// );
  /// ```
  Future<bool> presentPaymentSheet({
    required String clientSecret,
    String? customerEphemeralKeySecret,
    String? customerId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('present payment sheet');
    }
    if (!_initialized) {
      throw StateError('StripeService not initialized');
    }

    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: Stripe.merchantIdentifier,
          customerEphemeralKeySecret: customerEphemeralKeySecret,
          customerId: customerId,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1), // Indigo 500
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6366F1),
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      assert(() {
        debugPrint('Payment completed successfully');
        return true;
      }());
      return true;
    } on StripeException catch (_) {
      debugPrint('Stripe error'); // avoid leaking error details
      return false;
    } catch (_) {
      debugPrint('Payment failed'); // avoid leaking details
      return false;
    }
  }

  /// Create a payment intent via Cloud Function
  ///
  /// This calls a Cloud Function that creates a Stripe Payment Intent
  /// server-side and returns the client secret.
  ///
  /// [cloudFunctionUrl] should point to your deployed Cloud Function endpoint.
  ///
  /// Example:
  /// ```dart
  /// final result = await StripeService.instance.createPaymentIntent(
  ///   cloudFunctionUrl: 'https://us-central1-project.cloudfunctions.net/createPaymentIntent',
  ///   amountCents: 5000,
  ///   currency: 'usd',
  ///   metadata: {'appointmentId': 'appt_123'},
  /// );
  /// ```
  Future<Map<String, dynamic>> createPaymentIntent({
    required String cloudFunctionUrl,
    required int amountCents,
    String currency = 'usd',
    String? customerId,
    Map<String, dynamic>? metadata,
    String? destinationAccountId,
    int? applicationFeeAmountCents,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create payment intent');
    }
    try {
      _ensureHttps(cloudFunctionUrl);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountCents,
          'currency': currency,
          if (customerId != null) 'customerId': customerId,
          if (metadata != null) 'metadata': metadata,
          if (destinationAccountId != null)
            'destinationAccountId': destinationAccountId,
          if (applicationFeeAmountCents != null)
            'applicationFeeAmount': applicationFeeAmountCents,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating payment intent');
      rethrow;
    }
  }

  /// Create a subscription via Cloud Function
  ///
  /// This calls a Cloud Function that creates a Stripe Subscription
  /// server-side and returns the subscription details.
  ///
  /// Example:
  /// ```dart
  /// final result = await StripeService.instance.createSubscription(
  ///   cloudFunctionUrl: 'https://us-central1-project.cloudfunctions.net/createSubscription',
  ///   customerId: 'cus_123',
  ///   priceId: 'price_starter_monthly',
  /// );
  /// ```
  Future<Map<String, dynamic>> createSubscription({
    required String cloudFunctionUrl,
    required String customerId,
    required String priceId,
    int? trialPeriodDays,
    Map<String, dynamic>? metadata,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create subscription');
    }
    try {
      _ensureHttps(cloudFunctionUrl);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'priceId': priceId,
          if (trialPeriodDays != null) 'trialPeriodDays': trialPeriodDays,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create subscription: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating subscription');
      rethrow;
    }
  }

  /// Cancel a subscription via Cloud Function
  ///
  /// Example:
  /// ```dart
  /// await StripeService.instance.cancelSubscription(
  ///   cloudFunctionUrl: 'https://us-central1-project.cloudfunctions.net/cancelSubscription',
  ///   subscriptionId: 'sub_123',
  ///   cancelAtPeriodEnd: true,
  /// );
  /// ```
  Future<void> cancelSubscription({
    required String cloudFunctionUrl,
    required String subscriptionId,
    bool cancelAtPeriodEnd = true,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('cancel subscription');
    }
    try {
      _ensureHttps(cloudFunctionUrl);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'cancelAtPeriodEnd': cancelAtPeriodEnd,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error canceling subscription');
      rethrow;
    }
  }

  /// Open Stripe Customer Portal for managing subscription
  ///
  /// This allows customers to update payment methods, view invoices,
  /// and manage their subscription directly through Stripe's hosted portal.
  ///
  /// Returns the portal URL which should be opened in a web view or browser.
  ///
  /// Example:
  /// ```dart
  /// final portalUrl = await StripeService.instance.getCustomerPortalUrl(
  ///   cloudFunctionUrl: 'https://us-central1-project.cloudfunctions.net/createPortalSession',
  ///   customerId: 'cus_123',
  /// );
  /// // Open portalUrl in web view
  /// ```
  Future<String> getCustomerPortalUrl({
    required String cloudFunctionUrl,
    required String customerId,
    String? returnUrl,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('open customer portal');
    }
    try {
      _ensureHttps(cloudFunctionUrl);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          if (returnUrl != null) 'returnUrl': returnUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create portal session: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    } catch (e) {
      debugPrint('Error getting customer portal URL');
      rethrow;
    }
  }

  /// Process a refund via Cloud Function
  ///
  /// Refunds a payment intent partially or fully.
  ///
  /// Example:
  /// ```dart
  /// final refund = await StripeService.instance.createRefund(
  ///   cloudFunctionUrl: 'https://us-central1-project.cloudfunctions.net/createRefund',
  ///   paymentIntentId: 'pi_123',
  ///   amountCents: 5000, // Optional: omit for full refund
  ///   reason: 'Appointment cancelled',
  /// );
  /// ```
  Future<Map<String, dynamic>> createRefund({
    required String cloudFunctionUrl,
    required String paymentIntentId,
    int? amountCents, // Null for full refund
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create refund');
    }
    try {
      _ensureHttps(cloudFunctionUrl);
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          if (amountCents != null) 'amount': amountCents,
          if (reason != null) 'reason': reason,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create refund: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating refund');
      rethrow;
    }
  }

  void _ensureHttps(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme.toLowerCase() != 'https') {
      throw ArgumentError('StripeService requires HTTPS endpoints');
    }
  }
}
