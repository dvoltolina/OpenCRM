/// Risk and VIP indicator models for sentiment analysis.
///
/// Represents individual risk or VIP signals detected from text analysis,
/// including severity levels, confidence scores, and suggested actions.
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
import 'package:freezed_annotation/freezed_annotation.dart';
import 'sentiment_source.dart';

part 'risk_indicator.freezed.dart';
part 'risk_indicator.g.dart';

/// Type of indicator detected in sentiment analysis.
enum IndicatorType {
  /// Negative indicator suggesting churn risk
  negative,

  /// Positive indicator suggesting VIP/loyalty
  positive,

  /// Negative indicator suggesting churn risk
  risk,

  /// Positive indicator suggesting VIP/loyalty
  vip,

  /// Neutral observation
  neutral,
}

/// Severity level of the indicator.
enum IndicatorSeverity {
  /// Critical - requires immediate attention
  critical,

  /// High - should be addressed soon
  high,

  /// Medium - monitor and consider action
  medium,

  /// Low - informational
  low,
}

/// A single risk or VIP indicator detected from text analysis.
@freezed
abstract class RiskIndicator with _$RiskIndicator {
  const factory RiskIndicator({
    /// Unique identifier
    required String id,

    /// Type of indicator (risk, vip, neutral)
    required IndicatorType type,

    /// Severity level
    required IndicatorSeverity severity,

    /// Category of the indicator
    required String category,

    /// Human-readable description
    required String description,

    /// Confidence score from AI (0.0-1.0)
    required double confidence,

    /// Source that triggered this indicator
    required SentimentSource source,

    /// Reference to source document ID
    String? sourceDocumentId,

    /// Snippet of text that triggered this indicator
    String? triggerText,

    /// When this indicator was detected
    required DateTime detectedAt,

    /// Suggested action to take
    String? suggestedAction,

    /// Whether this indicator has been acknowledged by staff
    @Default(false) bool acknowledged,

    /// Staff member who acknowledged (if any)
    String? acknowledgedBy,

    /// When acknowledged
    DateTime? acknowledgedAt,
  }) = _RiskIndicator;

  factory RiskIndicator.fromJson(Map<String, dynamic> json) =>
      _$RiskIndicatorFromJson(json);
}

/// Extension for RiskIndicator helper methods.
extension RiskIndicatorHelpers on RiskIndicator {
  /// Whether this is a risk indicator
  bool get isRisk => type == IndicatorType.risk;

  /// Whether this is a VIP indicator
  bool get isVip => type == IndicatorType.vip;

  /// Whether this requires attention (critical or high severity risk)
  bool get requiresAttention =>
      type == IndicatorType.risk &&
      (severity == IndicatorSeverity.critical ||
          severity == IndicatorSeverity.high);

  /// Color hex for UI display based on type and severity
  String get colorHex {
    if (type == IndicatorType.vip) {
      return '#8B5CF6'; // Purple for VIP
    }
    return switch (severity) {
      IndicatorSeverity.critical => '#DC2626',
      IndicatorSeverity.high => '#EF4444',
      IndicatorSeverity.medium => '#F59E0B',
      IndicatorSeverity.low => '#6B7280',
    };
  }
}

/// Common risk indicator categories.
class RiskCategories {
  RiskCategories._();

  static const frustration = 'frustration';
  static const dissatisfaction = 'dissatisfaction';
  static const priceComplaint = 'price_complaint';
  static const serviceComplaint = 'service_complaint';
  static const schedulingIssue = 'scheduling_issue';
  static const communicationIssue = 'communication_issue';
  static const healthConcern = 'health_concern';
  static const lifeChange = 'life_change';
  static const competitorMention = 'competitor_mention';
  static const churnIntent = 'churn_intent';

  static const allCategories = [
    frustration,
    dissatisfaction,
    priceComplaint,
    serviceComplaint,
    schedulingIssue,
    communicationIssue,
    healthConcern,
    lifeChange,
    competitorMention,
    churnIntent,
  ];

  /// Display name for a risk category
  static String displayName(String category) => switch (category) {
        frustration => 'Frustration',
        dissatisfaction => 'Dissatisfaction',
        priceComplaint => 'Price Complaint',
        serviceComplaint => 'Service Complaint',
        schedulingIssue => 'Scheduling Issue',
        communicationIssue => 'Communication Issue',
        healthConcern => 'Health Concern',
        lifeChange => 'Life Change',
        competitorMention => 'Competitor Mention',
        churnIntent => 'Churn Intent',
        _ => category,
      };
}

/// Common VIP indicator categories.
class VipCategories {
  VipCategories._();

  static const loyalty = 'loyalty';
  static const referralIntent = 'referral_intent';
  static const positiveReview = 'positive_review';
  static const gratitude = 'gratitude';
  static const engagement = 'engagement';
  static const repeatBooking = 'repeat_booking';
  static const premiumInterest = 'premium_interest';
  static const advocateSignal = 'advocate_signal';

  static const allCategories = [
    loyalty,
    referralIntent,
    positiveReview,
    gratitude,
    engagement,
    repeatBooking,
    premiumInterest,
    advocateSignal,
  ];

  /// Display name for a VIP category
  static String displayName(String category) => switch (category) {
        loyalty => 'Loyalty',
        referralIntent => 'Referral Intent',
        positiveReview => 'Positive Review',
        gratitude => 'Gratitude',
        engagement => 'Engagement',
        repeatBooking => 'Repeat Booking',
        premiumInterest => 'Premium Interest',
        advocateSignal => 'Advocate Signal',
        _ => category,
      };
}
