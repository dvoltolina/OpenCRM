/// Sentiment analysis result model.
///
/// Stores the result of analyzing a single piece of text for sentiment,
/// including the sentiment score, detected risk/VIP indicators, and metadata.
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
import 'package:freezed_annotation/freezed_annotation.dart';
import 'sentiment_source.dart';
import 'risk_indicator.dart';

part 'sentiment_result.freezed.dart';
part 'sentiment_result.g.dart';

/// Result of analyzing a single piece of text for sentiment.
@freezed
abstract class SentimentResult with _$SentimentResult {
  const factory SentimentResult({
    /// Unique identifier for this analysis
    required String id,

    /// Business ID (multi-tenant)
    required String businessId,

    /// Client ID this text belongs to
    required String clientId,

    /// Source of the analyzed text
    required SentimentSource source,

    /// Reference to source document
    String? sourceDocumentId,

    /// The text that was analyzed (truncated for storage)
    required String analyzedText,

    /// Overall sentiment score (-1.0 = very negative, 1.0 = very positive)
    required double sentimentScore,

    /// Confidence in the sentiment score (0.0-1.0)
    required double confidence,

    /// Detected risk indicators
    required List<RiskIndicator> riskIndicators,

    /// Detected VIP indicators
    required List<RiskIndicator> vipIndicators,

    /// AI-generated summary of the text sentiment
    String? summary,

    /// Suggested action based on analysis
    String? recommendedAction,

    /// Model version used for analysis
    required String modelVersion,

    /// When the analysis was performed
    required DateTime analyzedAt,

    /// When this result expires (for caching)
    required DateTime expiresAt,

    /// Processing time in milliseconds
    int? processingTimeMs,
  }) = _SentimentResult;

  factory SentimentResult.fromJson(Map<String, dynamic> json) =>
      _$SentimentResultFromJson(json);

  /// Create an unavailable/error result
  factory SentimentResult.unavailable({
    required String clientId,
    required String businessId,
    required SentimentSource source,
    String? sourceDocumentId,
  }) =>
      SentimentResult(
        id: 'unavailable_${DateTime.now().millisecondsSinceEpoch}',
        businessId: businessId,
        clientId: clientId,
        source: source,
        sourceDocumentId: sourceDocumentId,
        analyzedText: '',
        sentimentScore: 0.0,
        confidence: 0.0,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: 'unavailable',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now(),
      );
}

/// Sentiment category based on score.
enum SentimentCategory {
  /// Score >= 0.3
  positive,

  /// Score between -0.3 and 0.3
  neutral,

  /// Score <= -0.3
  negative,
}

extension SentimentResultHelpers on SentimentResult {
  /// Whether this result has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this result is valid (not unavailable)
  bool get isValid => modelVersion != 'unavailable' && confidence > 0;

  /// Sentiment category based on score
  SentimentCategory get category {
    if (sentimentScore >= 0.3) return SentimentCategory.positive;
    if (sentimentScore <= -0.3) return SentimentCategory.negative;
    return SentimentCategory.neutral;
  }

  /// Total number of indicators detected
  int get totalIndicators => riskIndicators.length + vipIndicators.length;

  /// Whether this result has critical risk indicators
  bool get hasCriticalRisk => riskIndicators.any(
        (i) => i.severity == IndicatorSeverity.critical,
      );

  /// Whether this result has high-severity risk indicators
  bool get hasHighRisk => riskIndicators.any(
        (i) =>
            i.severity == IndicatorSeverity.critical ||
            i.severity == IndicatorSeverity.high,
      );

  /// Weighted sentiment score (accounts for source weight)
  double get weightedScore => sentimentScore * source.weight;

  /// Color hex for UI display based on sentiment category
  String get sentimentColorHex => switch (category) {
        SentimentCategory.positive => '#22C55E',
        SentimentCategory.neutral => '#6B7280',
        SentimentCategory.negative => '#EF4444',
      };

  /// Sentiment label for UI display
  String get sentimentLabel => switch (category) {
        SentimentCategory.positive => 'Positive',
        SentimentCategory.neutral => 'Neutral',
        SentimentCategory.negative => 'Negative',
      };

  /// Sentiment percentage for UI display (0-100 scale, 50 = neutral)
  int get sentimentPercent => ((sentimentScore + 1) / 2 * 100).round();
}
