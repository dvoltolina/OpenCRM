import 'package:flutter/material.dart';

import 'app_branding.dart';
import 'demo_config.dart';
import 'app_modules.dart';
import 'communication_config.dart';
import 'feature_flags.dart';
import 'integration_config.dart';
import 'module_config.dart';
import 'payment_config.dart';

class AppConfig {
  const AppConfig({
    required this.branding,
    required this.featureFlags,
    required this.bookingPolicies,
    required this.modules,
    required this.serviceCatalog,
    required this.defaultTimeZone,
    required this.communicationConfig,
    required this.paymentConfig,
    required this.integrationConfig,
    this.cloudFunctionUrls = const {},
  });

  final AppBranding branding;
  final FeatureFlags featureFlags;
  final BookingPolicies bookingPolicies;
  final List<ModuleConfig> modules;
  final List<String> serviceCatalog;
  final String defaultTimeZone;
  final CommunicationConfig communicationConfig;
  final PaymentConfig paymentConfig;
  final IntegrationConfig integrationConfig;
  final Map<String, String> cloudFunctionUrls;

  AppConfig copyWith({
    AppBranding? branding,
    FeatureFlags? featureFlags,
    BookingPolicies? bookingPolicies,
    List<ModuleConfig>? modules,
    List<String>? serviceCatalog,
    String? defaultTimeZone,
    CommunicationConfig? communicationConfig,
    PaymentConfig? paymentConfig,
    IntegrationConfig? integrationConfig,
    Map<String, String>? cloudFunctionUrls,
  }) {
    return AppConfig(
      branding: branding ?? this.branding,
      featureFlags: featureFlags ?? this.featureFlags,
      bookingPolicies: bookingPolicies ?? this.bookingPolicies,
      modules: modules ?? this.modules,
      serviceCatalog: serviceCatalog ?? this.serviceCatalog,
      defaultTimeZone: defaultTimeZone ?? this.defaultTimeZone,
      communicationConfig: communicationConfig ?? this.communicationConfig,
      paymentConfig: paymentConfig ?? this.paymentConfig,
      integrationConfig: integrationConfig ?? this.integrationConfig,
      cloudFunctionUrls: cloudFunctionUrls ?? this.cloudFunctionUrls,
    );
  }

  /// Provides an opinionated preset that can be tweaked per client.
  factory AppConfig.defaultClinic() {
    final featureFlags = const FeatureFlags(
      enableClientPortal: true,
      enableAutomatedReminders: true,
      enablePayments: true,
      enableMultiLocation: true,
      enableReporting: true,
      enableWaitlist: true,
      enableSessionNotes: true,
      enablePOS: true,
      enableProviderMode: DemoConfig.isDemoMode,
    );

    return AppConfig(
      branding: AppBranding(
        productName: 'Scheduler HQ',
        tagline: 'Coordinate every visit with confidence.',
        // Modern Sophisticated Blue Theme
        // Rich saturated navy for depth and professionalism
        primaryColor: const Color(0xFF1A365D), // Rich Navy Blue
        // Vibrant blue for gradients and highlights
        accentColor: const Color(0xFF3B82F6), // Bright Modern Blue
        // Warm coral for CTAs and visual warmth
        ctaColor: const Color(0xFFF97316), // Warm Coral/Orange
        // Warm off-white background (not clinical white)
        backgroundColor: const Color(0xFFFAFAF9), // Warm Stone 50
        logoAsset: null,
        fontFamily: 'Inter',
      ),
      featureFlags: featureFlags,
      bookingPolicies: const BookingPolicies(
        defaultSlotLength: Duration(minutes: 60),
        bufferBetweenAppointments: Duration(minutes: 10),
        cancellationWindow: Duration(hours: 24),
        allowDeposits: true,
        depositAmount: 50,
        minimumBookingNotice: Duration(hours: 2),
        maximumAdvanceBooking: Duration(days: 90),
        allowWaitlist: true,
        requireManualApprovalInsideWindow: true,
        rescheduleFeeAmount: 25.0,
        cancellationFeeAmount: 50.0,
      ),
      modules: buildDefaultModules(featureFlags: featureFlags),
      serviceCatalog: const [
        'Initial Consultation',
        'Follow-up Visit',
        'Virtual Session',
        'Group Class',
      ],
      defaultTimeZone: 'America/New_York',
      communicationConfig: CommunicationConfig.defaultClinic(),
      paymentConfig: const PaymentConfig(
        paymentIntentFunctionUrl:
            'https://us-central1-your-project.cloudfunctions.net/createPaymentIntent',
        currency: 'usd',
      ),
      integrationConfig: IntegrationConfig.defaultClinic(),
      cloudFunctionUrls: const {
        'businessSearch':
            'https://us-central1-your-project.cloudfunctions.net/businessSearch',
        'sendGuestVerification':
            'https://us-central1-your-project.cloudfunctions.net/sendGuestVerification',
        'verifyGuestCode':
            'https://us-central1-your-project.cloudfunctions.net/verifyGuestCode',
        'resendGuestCode':
            'https://us-central1-your-project.cloudfunctions.net/resendGuestCode',
      },
    );
  }
}

class BookingPolicies {
  const BookingPolicies({
    required this.defaultSlotLength,
    required this.bufferBetweenAppointments,
    required this.cancellationWindow,
    this.allowDeposits = false,
    this.depositAmount,
    this.defaultDepositPercentage = 0.25,
    this.minimumBookingNotice,
    this.maximumAdvanceBooking,
    this.allowWaitlist = true,
    this.requireManualApprovalInsideWindow = false,
    this.rescheduleFeeAmount,
    this.cancellationFeeAmount,
  });

  final Duration defaultSlotLength;
  final Duration bufferBetweenAppointments;
  final Duration cancellationWindow;
  final bool allowDeposits;
  final double? depositAmount;
  final double defaultDepositPercentage;
  final Duration? minimumBookingNotice;
  final Duration? maximumAdvanceBooking;
  final bool allowWaitlist;
  final bool requireManualApprovalInsideWindow;
  final double? rescheduleFeeAmount;
  final double? cancellationFeeAmount;

  BookingPolicies copyWith({
    Duration? defaultSlotLength,
    Duration? bufferBetweenAppointments,
    Duration? cancellationWindow,
    bool? allowDeposits,
    double? depositAmount,
    double? defaultDepositPercentage,
    Duration? minimumBookingNotice,
    Duration? maximumAdvanceBooking,
    bool? allowWaitlist,
    bool? requireManualApprovalInsideWindow,
    double? rescheduleFeeAmount,
    double? cancellationFeeAmount,
  }) {
    return BookingPolicies(
      defaultSlotLength: defaultSlotLength ?? this.defaultSlotLength,
      bufferBetweenAppointments:
          bufferBetweenAppointments ?? this.bufferBetweenAppointments,
      cancellationWindow: cancellationWindow ?? this.cancellationWindow,
      allowDeposits: allowDeposits ?? this.allowDeposits,
      depositAmount: depositAmount ?? this.depositAmount,
      defaultDepositPercentage:
          defaultDepositPercentage ?? this.defaultDepositPercentage,
      minimumBookingNotice: minimumBookingNotice ?? this.minimumBookingNotice,
      maximumAdvanceBooking:
          maximumAdvanceBooking ?? this.maximumAdvanceBooking,
      allowWaitlist: allowWaitlist ?? this.allowWaitlist,
      requireManualApprovalInsideWindow:
          requireManualApprovalInsideWindow ??
          this.requireManualApprovalInsideWindow,
      rescheduleFeeAmount:
          rescheduleFeeAmount ?? this.rescheduleFeeAmount,
      cancellationFeeAmount:
          cancellationFeeAmount ?? this.cancellationFeeAmount,
    );
  }
}
