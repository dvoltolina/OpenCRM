import 'package:freezed_annotation/freezed_annotation.dart';

import 'feature_importance.dart';
export 'feature_importance.dart';

part 'noshow_prediction.freezed.dart';
part 'noshow_prediction.g.dart';

/// Risk level for no-show predictions
enum RiskLevel {
  /// High risk of no-show (probability >= highRiskThreshold)
  high,

  /// Medium risk of no-show (probability >= mediumRiskThreshold)
  medium,

  /// Low risk of no-show (probability < mediumRiskThreshold)
  low,

  /// Risk level could not be determined (e.g., AI unavailable)
  unknown,
}

/// Extension methods for RiskLevel
extension RiskLevelExtension on RiskLevel {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.unknown:
        return 'Unknown';
    }
  }

  /// Short label for badges
  String get shortLabel {
    switch (this) {
      case RiskLevel.high:
        return 'High';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.unknown:
        return '—';
    }
  }

  /// Color value for UI (as int for cross-platform compatibility)
  int get colorValue {
    switch (this) {
      case RiskLevel.high:
        return 0xFFF44336; // Red
      case RiskLevel.medium:
        return 0xFFFFC107; // Amber
      case RiskLevel.low:
        return 0xFF4CAF50; // Green
      case RiskLevel.unknown:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Icon name suggestion for UI
  String get iconName {
    switch (this) {
      case RiskLevel.high:
        return 'error';
      case RiskLevel.medium:
        return 'warning';
      case RiskLevel.low:
        return 'check_circle';
      case RiskLevel.unknown:
        return 'help_outline';
    }
  }

  /// Whether this is a concerning risk level
  bool get isConcerning => this == RiskLevel.high || this == RiskLevel.medium;
}

/// Priority level for recommended actions
enum ActionPriority {
  /// Critical - must take action immediately
  critical,

  /// High - should take action soon
  high,

  /// Medium - consider taking action
  medium,

  /// Low - optional improvement
  low,
}

/// Extension methods for ActionPriority
extension ActionPriorityExtension on ActionPriority {
  /// Display name for UI
  String get displayName {
    switch (this) {
      case ActionPriority.critical:
        return 'Critical';
      case ActionPriority.high:
        return 'High';
      case ActionPriority.medium:
        return 'Medium';
      case ActionPriority.low:
        return 'Low';
    }
  }

  /// Color value for UI
  int get colorValue {
    switch (this) {
      case ActionPriority.critical:
        return 0xFFD32F2F; // Dark Red
      case ActionPriority.high:
        return 0xFFF44336; // Red
      case ActionPriority.medium:
        return 0xFFFFC107; // Amber
      case ActionPriority.low:
        return 0xFF4CAF50; // Green
    }
  }

  /// Sort order (lower = more urgent)
  int get sortOrder {
    switch (this) {
      case ActionPriority.critical:
        return 0;
      case ActionPriority.high:
        return 1;
      case ActionPriority.medium:
        return 2;
      case ActionPriority.low:
        return 3;
    }
  }
}

/// A recommended action to reduce no-show risk
@freezed
abstract class RecommendedAction with _$RecommendedAction {
  const factory RecommendedAction({
    /// Unique identifier for this action type
    required String actionId,

    /// Human-readable title for the action
    required String title,

    /// Detailed description of what to do
    required String description,

    /// Priority level of this action
    required ActionPriority priority,

    /// Whether this action can be automated (e.g., send reminder)
    required bool automatable,

    /// Icon name for UI display (optional)
    String? iconName,

    /// Estimated impact on no-show probability reduction (0.0-1.0)
    double? estimatedImpact,
  }) = _RecommendedAction;

  factory RecommendedAction.fromJson(Map<String, dynamic> json) =>
      _$RecommendedActionFromJson(json);

  const RecommendedAction._();
}

/// Standard recommended actions for reducing no-show risk
class StandardActions {
  static const sendReminder = RecommendedAction(
    actionId: 'send_reminder',
    title: 'Send Reminder',
    description: 'Send an SMS or email reminder 24-48 hours before appointment',
    priority: ActionPriority.high,
    automatable: true,
    iconName: 'notifications',
    estimatedImpact: 0.15,
  );

  static const collectDeposit = RecommendedAction(
    actionId: 'collect_deposit',
    title: 'Collect Deposit',
    description: 'Request a deposit or pre-payment to increase commitment',
    priority: ActionPriority.high,
    automatable: false,
    iconName: 'payment',
    estimatedImpact: 0.25,
  );

  static const confirmAppointment = RecommendedAction(
    actionId: 'confirm_appointment',
    title: 'Request Confirmation',
    description: 'Ask client to confirm attendance via text or email',
    priority: ActionPriority.medium,
    automatable: true,
    iconName: 'check_circle',
    estimatedImpact: 0.10,
  );

  static const addToWaitlist = RecommendedAction(
    actionId: 'add_waitlist_backup',
    title: 'Prepare Waitlist',
    description: 'Have waitlist clients ready to fill this slot if cancelled',
    priority: ActionPriority.medium,
    automatable: false,
    iconName: 'list',
    estimatedImpact: 0.0, // Doesn't reduce no-show but mitigates impact
  );

  static const callClient = RecommendedAction(
    actionId: 'call_client',
    title: 'Call Client',
    description: 'Personal phone call to confirm and build rapport',
    priority: ActionPriority.high,
    automatable: false,
    iconName: 'phone',
    estimatedImpact: 0.20,
  );

  static const overbook = RecommendedAction(
    actionId: 'consider_overbooking',
    title: 'Consider Overbooking',
    description: 'Accept another booking in the same slot to account for expected no-show',
    priority: ActionPriority.low,
    automatable: false,
    iconName: 'event_repeat',
    estimatedImpact: 0.0, // Mitigates impact, not reduces no-show
  );

  /// Get all standard actions
  static List<RecommendedAction> get all => [
        sendReminder,
        collectDeposit,
        confirmAppointment,
        addToWaitlist,
        callClient,
        overbook,
      ];
}

/// No-show prediction result from the AI server
@freezed
abstract class NoshowPrediction with _$NoshowPrediction {
  const factory NoshowPrediction({
    /// Appointment ID this prediction is for
    required String appointmentId,

    /// Probability of no-show (0.0-1.0)
    /// 0.0 = definitely will show, 1.0 = definitely will no-show
    required double probability,

    /// Calculated risk level based on probability and thresholds
    required RiskLevel riskLevel,

    /// Model's confidence in this prediction (0.0-1.0)
    /// Lower confidence may indicate edge cases or unusual patterns
    required double confidence,

    /// Recommended actions to reduce no-show risk, ordered by priority
    required List<RecommendedAction> recommendedActions,

    /// Top features that contributed to this prediction, ordered by importance
    required List<FeatureImportance> topFeatures,

    /// Version of the model that made this prediction
    required String modelVersion,

    /// Timestamp when prediction was made
    required DateTime predictedAt,

    /// Timestamp when this prediction expires and should be refreshed
    required DateTime expiresAt,

    /// Request ID for tracing/debugging
    String? requestId,
  }) = _NoshowPrediction;

  factory NoshowPrediction.fromJson(Map<String, dynamic> json) =>
      _$NoshowPredictionFromJson(json);

  /// Create an unavailable prediction (when AI server is down)
  factory NoshowPrediction.unavailable(String appointmentId) => NoshowPrediction(
        appointmentId: appointmentId,
        probability: 0,
        riskLevel: RiskLevel.unknown,
        confidence: 0,
        recommendedActions: const [],
        topFeatures: const [],
        modelVersion: 'unavailable',
        predictedAt: DateTime.now(),
        expiresAt: DateTime.now(),
      );

  const NoshowPrediction._();

  /// Whether the prediction is still valid (not expired)
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Whether this is a meaningful prediction (not unavailable/error)
  bool get isAvailable =>
      modelVersion != 'unavailable' && riskLevel != RiskLevel.unknown;

  /// Probability as percentage (0-100)
  int get probabilityPercent => (probability * 100).round();

  /// Confidence as percentage (0-100)
  int get confidencePercent => (confidence * 100).round();

  /// Time remaining until expiration
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Get high-priority recommended actions only
  List<RecommendedAction> get urgentActions => recommendedActions
      .where((a) =>
          a.priority == ActionPriority.critical ||
          a.priority == ActionPriority.high)
      .toList();

  /// Get automatable actions only
  List<RecommendedAction> get automatableActions =>
      recommendedActions.where((a) => a.automatable).toList();

  /// Get risk-increasing features (explain why risk is high)
  List<FeatureImportance> get riskIncreasingFeatures =>
      topFeatures.where((f) => f.increasesRisk).toList();

  /// Get risk-decreasing features (explain what's good)
  List<FeatureImportance> get riskDecreasingFeatures =>
      topFeatures.where((f) => f.decreasesRisk).toList();
}
