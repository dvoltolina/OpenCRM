/// Configuration for yield management and overbooking.
///
/// Business-specific settings that control overbooking behavior,
/// risk tolerance, and exclusion rules.
///
/// Agent AI-16: Yield Management & Overbooking Engine

/// Overbooking configuration for a business.
class OverbookingConfig {
  /// Whether overbooking feature is enabled for this business
  final bool isEnabled;

  /// Maximum overbooking percentage allowed (0.0 - 1.0)
  /// e.g., 0.2 means max 20% overbooking
  final double maxOverbookingPercentage;

  /// Confidence factor for conservative calculations (0.0 - 1.0)
  /// Lower = more conservative, higher = more aggressive
  /// Default: 0.8 (20% safety buffer)
  final double confidenceFactor;

  /// Minimum predicted no-show probability to consider overbooking
  /// Default: 0.3 (30% no-show probability)
  final double minNoshowProbabilityThreshold;

  /// Minimum number of bookings in slot before overbooking considered
  /// Default: 2 (need at least 2 bookings to have meaningful data)
  final int minBookingsForOverbooking;

  /// Maximum overbooks per slot regardless of calculation
  final int maxOverbooksPerSlot;

  /// Provider IDs that have opted out of overbooking
  final Set<String> optedOutProviderIds;

  /// Service IDs excluded from overbooking (e.g., complex procedures)
  final Set<String> excludedServiceIds;

  /// Client tags that exclude from overbooking (e.g., 'vip', 'new_client')
  final Set<String> excludedClientTags;

  /// Whether to exclude group sessions from overbooking (always recommended)
  final bool excludeGroupSessions;

  /// Minimum days before appointment for overbooking to be considered
  /// Prevents last-minute overbooking chaos
  final int minDaysBeforeAppointment;

  /// Revenue threshold below which overbooking isn't worth the risk (cents)
  final int minServiceValueCents;

  /// Double-booking penalty cost (cents) - used in yield calculations
  /// Represents cost of handling a double-book scenario
  final int doubleBookPenaltyCents;

  /// No-show cost per appointment (cents) - used in yield calculations
  /// Represents lost revenue from empty slot
  final int noshowCostCents;

  /// Hours of the day to exclude from overbooking (0-23)
  /// e.g., [8, 17] to exclude first and last hours
  final Set<int> excludedHours;

  /// Days of week to exclude (1=Monday, 7=Sunday)
  final Set<int> excludedDaysOfWeek;

  const OverbookingConfig({
    this.isEnabled = true,
    this.maxOverbookingPercentage = 0.2,
    this.confidenceFactor = 0.8,
    this.minNoshowProbabilityThreshold = 0.3,
    this.minBookingsForOverbooking = 2,
    this.maxOverbooksPerSlot = 2,
    this.optedOutProviderIds = const {},
    this.excludedServiceIds = const {},
    this.excludedClientTags = const {'vip', 'VIP', 'priority'},
    this.excludeGroupSessions = true,
    this.minDaysBeforeAppointment = 1,
    this.minServiceValueCents = 2500, // $25 minimum
    this.doubleBookPenaltyCents = 5000, // $50 penalty
    this.noshowCostCents = 0, // Full service price by default
    this.excludedHours = const {},
    this.excludedDaysOfWeek = const {},
  });

  /// Default conservative configuration
  factory OverbookingConfig.conservative() => const OverbookingConfig(
        maxOverbookingPercentage: 0.1,
        confidenceFactor: 0.7,
        minNoshowProbabilityThreshold: 0.4,
        maxOverbooksPerSlot: 1,
      );

  /// More aggressive configuration for businesses with high no-show rates
  factory OverbookingConfig.aggressive() => const OverbookingConfig(
        maxOverbookingPercentage: 0.3,
        confidenceFactor: 0.9,
        minNoshowProbabilityThreshold: 0.25,
        maxOverbooksPerSlot: 3,
      );

  /// Disabled configuration
  factory OverbookingConfig.disabled() => const OverbookingConfig(
        isEnabled: false,
      );

  /// Check if a provider has opted out
  bool isProviderOptedOut(String providerId) =>
      optedOutProviderIds.contains(providerId);

  /// Check if a service is excluded
  bool isServiceExcluded(String serviceId) =>
      excludedServiceIds.contains(serviceId);

  /// Check if a client has excluded tags
  bool hasExcludedTags(Set<String> clientTags) =>
      clientTags.any((tag) => excludedClientTags.contains(tag));

  /// Check if hour is excluded
  bool isHourExcluded(int hour) => excludedHours.contains(hour);

  /// Check if day is excluded
  bool isDayExcluded(int dayOfWeek) => excludedDaysOfWeek.contains(dayOfWeek);

  /// Copy with modifications
  OverbookingConfig copyWith({
    bool? isEnabled,
    double? maxOverbookingPercentage,
    double? confidenceFactor,
    double? minNoshowProbabilityThreshold,
    int? minBookingsForOverbooking,
    int? maxOverbooksPerSlot,
    Set<String>? optedOutProviderIds,
    Set<String>? excludedServiceIds,
    Set<String>? excludedClientTags,
    bool? excludeGroupSessions,
    int? minDaysBeforeAppointment,
    int? minServiceValueCents,
    int? doubleBookPenaltyCents,
    int? noshowCostCents,
    Set<int>? excludedHours,
    Set<int>? excludedDaysOfWeek,
  }) {
    return OverbookingConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      maxOverbookingPercentage:
          maxOverbookingPercentage ?? this.maxOverbookingPercentage,
      confidenceFactor: confidenceFactor ?? this.confidenceFactor,
      minNoshowProbabilityThreshold:
          minNoshowProbabilityThreshold ?? this.minNoshowProbabilityThreshold,
      minBookingsForOverbooking:
          minBookingsForOverbooking ?? this.minBookingsForOverbooking,
      maxOverbooksPerSlot: maxOverbooksPerSlot ?? this.maxOverbooksPerSlot,
      optedOutProviderIds: optedOutProviderIds ?? this.optedOutProviderIds,
      excludedServiceIds: excludedServiceIds ?? this.excludedServiceIds,
      excludedClientTags: excludedClientTags ?? this.excludedClientTags,
      excludeGroupSessions: excludeGroupSessions ?? this.excludeGroupSessions,
      minDaysBeforeAppointment:
          minDaysBeforeAppointment ?? this.minDaysBeforeAppointment,
      minServiceValueCents: minServiceValueCents ?? this.minServiceValueCents,
      doubleBookPenaltyCents:
          doubleBookPenaltyCents ?? this.doubleBookPenaltyCents,
      noshowCostCents: noshowCostCents ?? this.noshowCostCents,
      excludedHours: excludedHours ?? this.excludedHours,
      excludedDaysOfWeek: excludedDaysOfWeek ?? this.excludedDaysOfWeek,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'maxOverbookingPercentage': maxOverbookingPercentage,
        'confidenceFactor': confidenceFactor,
        'minNoshowProbabilityThreshold': minNoshowProbabilityThreshold,
        'minBookingsForOverbooking': minBookingsForOverbooking,
        'maxOverbooksPerSlot': maxOverbooksPerSlot,
        'optedOutProviderIds': optedOutProviderIds.toList(),
        'excludedServiceIds': excludedServiceIds.toList(),
        'excludedClientTags': excludedClientTags.toList(),
        'excludeGroupSessions': excludeGroupSessions,
        'minDaysBeforeAppointment': minDaysBeforeAppointment,
        'minServiceValueCents': minServiceValueCents,
        'doubleBookPenaltyCents': doubleBookPenaltyCents,
        'noshowCostCents': noshowCostCents,
        'excludedHours': excludedHours.toList(),
        'excludedDaysOfWeek': excludedDaysOfWeek.toList(),
      };

  /// Create from JSON
  factory OverbookingConfig.fromJson(Map<String, dynamic> json) {
    return OverbookingConfig(
      isEnabled: json['isEnabled'] as bool? ?? true,
      maxOverbookingPercentage:
          (json['maxOverbookingPercentage'] as num?)?.toDouble() ?? 0.2,
      confidenceFactor: (json['confidenceFactor'] as num?)?.toDouble() ?? 0.8,
      minNoshowProbabilityThreshold:
          (json['minNoshowProbabilityThreshold'] as num?)?.toDouble() ?? 0.3,
      minBookingsForOverbooking:
          json['minBookingsForOverbooking'] as int? ?? 2,
      maxOverbooksPerSlot: json['maxOverbooksPerSlot'] as int? ?? 2,
      optedOutProviderIds:
          (json['optedOutProviderIds'] as List?)?.cast<String>().toSet() ??
              const {},
      excludedServiceIds:
          (json['excludedServiceIds'] as List?)?.cast<String>().toSet() ??
              const {},
      excludedClientTags:
          (json['excludedClientTags'] as List?)?.cast<String>().toSet() ??
              const {'vip', 'VIP', 'priority'},
      excludeGroupSessions: json['excludeGroupSessions'] as bool? ?? true,
      minDaysBeforeAppointment: json['minDaysBeforeAppointment'] as int? ?? 1,
      minServiceValueCents: json['minServiceValueCents'] as int? ?? 2500,
      doubleBookPenaltyCents: json['doubleBookPenaltyCents'] as int? ?? 5000,
      noshowCostCents: json['noshowCostCents'] as int? ?? 0,
      excludedHours:
          (json['excludedHours'] as List?)?.cast<int>().toSet() ?? const {},
      excludedDaysOfWeek:
          (json['excludedDaysOfWeek'] as List?)?.cast<int>().toSet() ?? const {},
    );
  }
}
