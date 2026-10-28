import 'package:flutter/foundation.dart';
import '../../data/models/subscription.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/subscription_repository.dart';

/// Service for checking feature access based on subscription tier
///
/// This service provides methods to check if a feature is available
/// for the current subscription tier and enforces usage limits.
class FeatureGatingService {
  final SubscriptionRepository _subscriptionRepository;

  FeatureGatingService({
    required SubscriptionRepository subscriptionRepository,
  }) : _subscriptionRepository = subscriptionRepository;

  /// Check if a feature is available for the current subscription
  Future<bool> canAccessFeature(
    SecurityContext context,
    String featureName,
  ) async {
    final subscription = await _subscriptionRepository.getSubscription(context);
    
    // Default to free tier if no subscription
    final tier = subscription?.tier ?? SubscriptionTier.free;

    return _checkFeatureAccess(tier, featureName);
  }

  /// Check if feature is available based on tier
  bool _checkFeatureAccess(SubscriptionTier tier, String featureName) {
    switch (featureName) {
      case 'automated_reminders':
        return tier.hasAutomatedReminders;
      case 'sms_notifications':
        return tier.includedSmsPerMonth > 0;
      case 'payment_processing':
        return tier.hasPaymentProcessing;
      case 'custom_branding':
        return tier.hasCustomBranding;
      case 'hipaa_compliance':
        return tier.hasHipaaCompliance;
      case 'api_access':
        return tier.hasApiAccess;
      case 'client_portal':
        return tier.hasClientPortal;
      case 'advanced_reporting':
        return tier.hasAdvancedReporting;
      case 'two_way_calendar_sync':
        return tier.hasTwoWayCalendarSync;
      default:
        debugPrint('Unknown feature: $featureName');
        return false;
    }
  }

  /// Check if usage is within limits for the subscription tier
  Future<UsageLimitCheck> checkUsageLimits(
    SecurityContext context,
  ) async {
    final subscription = await _subscriptionRepository.getSubscription(context);
    final tier = subscription?.tier ?? SubscriptionTier.free;
    final usage = await _subscriptionRepository.getUsageStats(context);

    final warnings = <String>[];
    final exceeded = <String>[];

    // Check providers limit
    if (tier.maxProviders != -1) {
      final providerCount = usage['providers'] ?? 0;
      if (providerCount >= tier.maxProviders) {
        exceeded.add('Maximum providers (${tier.maxProviders}) reached');
      } else if (providerCount >= (tier.maxProviders * 0.8).floor()) {
        warnings.add(
            'Approaching provider limit ($providerCount/${tier.maxProviders})');
      }
    }

    // Check locations limit
    if (tier.maxLocations != -1) {
      final locationCount = usage['locations'] ?? 0;
      if (locationCount >= tier.maxLocations) {
        exceeded.add('Maximum locations (${tier.maxLocations}) reached');
      } else if (locationCount >= (tier.maxLocations * 0.8).floor()) {
        warnings.add(
            'Approaching location limit ($locationCount/${tier.maxLocations})');
      }
    }

    // Check appointments limit
    if (tier.maxAppointmentsPerMonth != -1) {
      final appointmentCount = usage['appointmentsThisMonth'] ?? 0;
      if (appointmentCount >= tier.maxAppointmentsPerMonth) {
        exceeded.add(
            'Monthly appointment limit (${tier.maxAppointmentsPerMonth}) reached');
      } else if (appointmentCount >=
          (tier.maxAppointmentsPerMonth * 0.8).floor()) {
        warnings.add(
            'Approaching monthly appointment limit ($appointmentCount/${tier.maxAppointmentsPerMonth})');
      }
    }

    // Check SMS limit
    if (tier.includedSmsPerMonth != -1 && tier.includedSmsPerMonth > 0) {
      final smsCount = usage['smsThisMonth'] ?? 0;
      if (smsCount >= tier.includedSmsPerMonth) {
        exceeded.add(
            'Monthly SMS limit (${tier.includedSmsPerMonth}) reached');
      } else if (smsCount >= (tier.includedSmsPerMonth * 0.8).floor()) {
        warnings.add(
            'Approaching monthly SMS limit ($smsCount/${tier.includedSmsPerMonth})');
      }
    }

    return UsageLimitCheck(
      tier: tier,
      usage: usage,
      warnings: warnings,
      exceeded: exceeded,
      canContinue: exceeded.isEmpty,
    );
  }

  /// Get upgrade recommendation based on current usage
  Future<UpgradeRecommendation?> getUpgradeRecommendation(
    SecurityContext context,
  ) async {
    final subscription = await _subscriptionRepository.getSubscription(context);
    final currentTier = subscription?.tier ?? SubscriptionTier.free;
    
    // Enterprise is the highest tier
    if (currentTier == SubscriptionTier.enterprise) {
      return null;
    }

    final limitCheck = await checkUsageLimits(context);

    // If any limits exceeded or multiple warnings, recommend upgrade
    if (limitCheck.exceeded.isNotEmpty || limitCheck.warnings.length >= 2) {
      final nextTier = _getNextTier(currentTier);
      if (nextTier == null) return null;

      return UpgradeRecommendation(
        currentTier: currentTier,
        recommendedTier: nextTier,
        reasons: [
          ...limitCheck.exceeded,
          if (limitCheck.warnings.length >= 2) 'Multiple usage limits approaching',
        ],
      );
    }

    return null;
  }

  /// Get the next subscription tier
  SubscriptionTier? _getNextTier(SubscriptionTier current) {
    switch (current) {
      case SubscriptionTier.free:
        return SubscriptionTier.starter;
      case SubscriptionTier.starter:
        return SubscriptionTier.professional;
      case SubscriptionTier.professional:
        return SubscriptionTier.enterprise;
      case SubscriptionTier.enterprise:
        return null;
    }
  }

  /// Check if action requires upgrade
  Future<bool> requiresUpgrade(
    SecurityContext context,
    String action,
  ) async {
    final subscription = await _subscriptionRepository.getSubscription(context);
    final tier = subscription?.tier ?? SubscriptionTier.free;

    switch (action) {
      case 'add_provider':
        final usage = await _subscriptionRepository.getUsageStats(context);
        final providerCount = usage['providers'] ?? 0;
        return tier.maxProviders != -1 && providerCount >= tier.maxProviders;

      case 'add_location':
        final usage = await _subscriptionRepository.getUsageStats(context);
        final locationCount = usage['locations'] ?? 0;
        return tier.maxLocations != -1 && locationCount >= tier.maxLocations;

      case 'create_appointment':
        final usage = await _subscriptionRepository.getUsageStats(context);
        final appointmentCount = usage['appointmentsThisMonth'] ?? 0;
        return tier.maxAppointmentsPerMonth != -1 &&
            appointmentCount >= tier.maxAppointmentsPerMonth;

      case 'send_sms':
        final usage = await _subscriptionRepository.getUsageStats(context);
        final smsCount = usage['smsThisMonth'] ?? 0;
        return tier.includedSmsPerMonth != -1 &&
            smsCount >= tier.includedSmsPerMonth;

      default:
        return false;
    }
  }
}

/// Result of usage limit check
class UsageLimitCheck {
  final SubscriptionTier tier;
  final Map<String, int> usage;
  final List<String> warnings;
  final List<String> exceeded;
  final bool canContinue;

  const UsageLimitCheck({
    required this.tier,
    required this.usage,
    required this.warnings,
    required this.exceeded,
    required this.canContinue,
  });
}

/// Upgrade recommendation
class UpgradeRecommendation {
  final SubscriptionTier currentTier;
  final SubscriptionTier recommendedTier;
  final List<String> reasons;

  const UpgradeRecommendation({
    required this.currentTier,
    required this.recommendedTier,
    required this.reasons,
  });
}

