import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Subscription tiers matching pricing.md
enum SubscriptionTier {
  @JsonValue('free')
  free,
  @JsonValue('starter')
  starter,
  @JsonValue('professional')
  professional,
  @JsonValue('enterprise')
  enterprise,
}

/// Extension for subscription tier properties and limits
extension SubscriptionTierProperties on SubscriptionTier {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free (Solo)';
      case SubscriptionTier.starter:
        return 'Starter (Professional)';
      case SubscriptionTier.professional:
        return 'Professional (Practice)';
      case SubscriptionTier.enterprise:
        return 'Enterprise (Network)';
    }
  }

  /// Monthly price in USD cents (0 for free, null for custom pricing)
  int? get monthlyPriceCents {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.starter:
        return 2900; // $29.00
      case SubscriptionTier.professional:
        return 7900; // $79.00
      case SubscriptionTier.enterprise:
        return 29900; // $299.00
    }
  }

  /// Annual price in USD cents (0 for free, null for custom pricing)
  int? get annualPriceCents {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.starter:
        return 29000; // $290.00/year
      case SubscriptionTier.professional:
        return 79000; // $790.00/year
      case SubscriptionTier.enterprise:
        return 299000; // $2990.00/year
    }
  }

  /// Maximum providers allowed (-1 for unlimited)
  int get maxProviders {
    switch (this) {
      case SubscriptionTier.free:
        return 1;
      case SubscriptionTier.starter:
        return 3;
      case SubscriptionTier.professional:
        return 10;
      case SubscriptionTier.enterprise:
        return -1; // unlimited
    }
  }

  /// Maximum locations allowed (-1 for unlimited)
  int get maxLocations {
    switch (this) {
      case SubscriptionTier.free:
        return 1;
      case SubscriptionTier.starter:
        return 1;
      case SubscriptionTier.professional:
        return 3;
      case SubscriptionTier.enterprise:
        return -1; // unlimited
    }
  }

  /// Maximum appointments per month (-1 for unlimited)
  int get maxAppointmentsPerMonth {
    switch (this) {
      case SubscriptionTier.free:
        return 50;
      case SubscriptionTier.starter:
        return 200;
      case SubscriptionTier.professional:
        return -1; // unlimited
      case SubscriptionTier.enterprise:
        return -1; // unlimited
    }
  }

  /// Maximum clients (-1 for unlimited)
  int get maxClients {
    switch (this) {
      case SubscriptionTier.free:
        return 100;
      case SubscriptionTier.starter:
        return -1; // unlimited
      case SubscriptionTier.professional:
        return -1; // unlimited
      case SubscriptionTier.enterprise:
        return -1; // unlimited
    }
  }

  /// SMS notifications included per month (-1 for unlimited)
  int get includedSmsPerMonth {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.starter:
        return 100;
      case SubscriptionTier.professional:
        return 500;
      case SubscriptionTier.enterprise:
        return -1; // unlimited
    }
  }

  /// Whether this tier supports automated email reminders
  bool get hasAutomatedReminders {
    return this != SubscriptionTier.free;
  }

  /// Whether this tier supports payment processing
  bool get hasPaymentProcessing {
    return this == SubscriptionTier.professional ||
        this == SubscriptionTier.enterprise;
  }

  /// Whether this tier supports custom branding
  bool get hasCustomBranding {
    return this != SubscriptionTier.free;
  }

  /// Whether this tier supports HIPAA compliance
  bool get hasHipaaCompliance {
    return this == SubscriptionTier.professional ||
        this == SubscriptionTier.enterprise;
  }

  /// Whether this tier has API access
  bool get hasApiAccess {
    return this == SubscriptionTier.enterprise;
  }

  /// Whether this tier supports client self-service booking
  bool get hasClientPortal {
    return this != SubscriptionTier.free;
  }

  /// Whether this tier has advanced reporting
  bool get hasAdvancedReporting {
    return this == SubscriptionTier.professional ||
        this == SubscriptionTier.enterprise;
  }

  /// Whether this tier has two-way calendar sync
  bool get hasTwoWayCalendarSync {
    return this == SubscriptionTier.professional ||
        this == SubscriptionTier.enterprise;
  }
}

/// Subscription status
enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('trialing')
  trialing,
  @JsonValue('past_due')
  pastDue,
  @JsonValue('canceled')
  canceled,
  @JsonValue('incomplete')
  incomplete,
  @JsonValue('incomplete_expired')
  incompleteExpired,
  @JsonValue('unpaid')
  unpaid,
}

/// Business subscription information
@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    /// Unique subscription ID (Stripe subscription ID)
    required String id,

    /// Business ID this subscription belongs to
    required String businessId,

    /// Current subscription tier
    required SubscriptionTier tier,

    /// Current status
    required SubscriptionStatus status,

    /// Stripe customer ID
    required String stripeCustomerId,

    /// Stripe subscription ID (if applicable)
    String? stripeSubscriptionId,

    /// Stripe price ID being charged
    String? stripePriceId,

    /// Current period start (when billing cycle started)
    @TimestampConverter() required DateTime currentPeriodStart,

    /// Current period end (when billing cycle ends)
    @TimestampConverter() required DateTime currentPeriodEnd,

    /// Whether subscription will cancel at period end
    @Default(false) bool cancelAtPeriodEnd,

    /// Trial end date (if in trial)
    @NullableTimestampConverter() DateTime? trialEnd,

    /// Date subscription was created
    @TimestampConverter() required DateTime createdAt,

    /// Date subscription was last updated
    @TimestampConverter() required DateTime updatedAt,

    /// Date subscription was canceled (if applicable)
    @NullableTimestampConverter() DateTime? canceledAt,

    /// Additional add-ons purchased (e.g., extra SMS, providers)
    @Default({}) Map<String, dynamic> addOns,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  const Subscription._();

  /// Whether subscription is active or trialing
  bool get isActive => status == SubscriptionStatus.active || isTrialing;

  /// Whether subscription is in trial period
  bool get isTrialing => status == SubscriptionStatus.trialing;

  /// Whether subscription requires payment action
  bool get requiresPaymentAction =>
      status == SubscriptionStatus.incomplete ||
      status == SubscriptionStatus.pastDue;

  /// Whether subscription is canceled
  bool get isCanceled => status == SubscriptionStatus.canceled;

  /// Days remaining in trial (0 if not trialing)
  int get daysRemainingInTrial {
    if (trialEnd == null) return 0;
    final remaining = trialEnd!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Days until subscription renews
  int get daysUntilRenewal {
    return currentPeriodEnd.difference(DateTime.now()).inDays;
  }
}
