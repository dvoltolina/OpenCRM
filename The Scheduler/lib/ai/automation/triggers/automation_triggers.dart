/// Trigger evaluators for the automation engine.
///
/// Each trigger type evaluates specific AI predictions or signals
/// to determine if an automation rule should fire.
///
/// Agent AI-11: Risk Automation Engine
import 'package:flutter/foundation.dart';

import '../../models/noshow_prediction.dart';
import '../../models/sentiment_result.dart';
import '../../models/client_risk_score.dart';
import '../automation_rule.dart';

/// Base class for all trigger evaluators.
abstract class TriggerEvaluator {
  /// Evaluate whether the trigger should fire.
  TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  });

  /// Compare value against threshold using the specified comparison operator.
  @protected
  bool compareValue(double value, double threshold, String comparison) {
    return switch (comparison) {
      'gte' => value >= threshold,
      'gt' => value > threshold,
      'lte' => value <= threshold,
      'lt' => value < threshold,
      'eq' => value == threshold,
      _ => value >= threshold, // Default to gte
    };
  }
}

/// Evaluates no-show risk predictions.
///
/// Fires when appointment no-show probability exceeds threshold.
class NoShowRiskTrigger extends TriggerEvaluator {
  @override
  TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  }) {
    final prediction = context['prediction'] as NoshowPrediction?;

    // Missing prediction data
    if (prediction == null) {
      return TriggerEvaluationResult.skip(
        value: 0,
        threshold: config.threshold,
        reason: 'No prediction data available',
        context: context,
      );
    }

    // Prediction unavailable (AI service down)
    if (!prediction.isAvailable) {
      return TriggerEvaluationResult.skip(
        value: 0,
        threshold: config.threshold,
        reason: 'Prediction service unavailable',
        context: {'modelVersion': prediction.modelVersion},
      );
    }

    // Check confidence threshold
    if (prediction.confidence < config.minConfidence) {
      return TriggerEvaluationResult.skip(
        value: prediction.probability,
        threshold: config.threshold,
        reason:
            'Confidence ${(prediction.confidence * 100).toStringAsFixed(0)}% '
            'below minimum ${(config.minConfidence * 100).toStringAsFixed(0)}%',
        context: {
          'probability': prediction.probability,
          'confidence': prediction.confidence,
          'riskLevel': prediction.riskLevel.name,
        },
      );
    }

    // Compare probability against threshold
    final shouldFire =
        compareValue(prediction.probability, config.threshold, config.comparison);

    if (shouldFire) {
      return TriggerEvaluationResult.fire(
        value: prediction.probability,
        threshold: config.threshold,
        confidence: prediction.confidence,
        reason:
            'No-show probability ${(prediction.probability * 100).toStringAsFixed(0)}% '
            '${config.comparison} ${(config.threshold * 100).toStringAsFixed(0)}%',
        context: {
          'appointmentId': prediction.appointmentId,
          'riskLevel': prediction.riskLevel.name,
          'topFeatures':
              prediction.topFeatures.map((f) => f.featureName).toList(),
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: prediction.probability,
      threshold: config.threshold,
      reason:
          'No-show probability ${(prediction.probability * 100).toStringAsFixed(0)}% '
          'does not meet threshold ${(config.threshold * 100).toStringAsFixed(0)}%',
      context: {
        'appointmentId': prediction.appointmentId,
        'riskLevel': prediction.riskLevel.name,
      },
    );
  }
}

/// Evaluates sentiment analysis results.
///
/// Fires when sentiment score is below threshold (negative sentiment).
class SentimentTrigger extends TriggerEvaluator {
  @override
  TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  }) {
    final sentimentResult = context['sentimentResult'] as SentimentResult?;
    final clientRiskScore = context['clientRiskScore'] as ClientRiskScore?;

    // Check for specific risk indicators if configured
    if (config.indicatorTypes.isNotEmpty) {
      return _evaluateIndicators(config, context);
    }

    // Use sentiment result if available
    if (sentimentResult != null && sentimentResult.isValid) {
      return _evaluateSentimentResult(sentimentResult, config, context);
    }

    // Fall back to client risk score
    if (clientRiskScore != null && !clientRiskScore.isEmpty) {
      return _evaluateClientRiskScore(clientRiskScore, config, context);
    }

    return TriggerEvaluationResult.skip(
      value: 0,
      threshold: config.threshold,
      reason: 'No sentiment data available',
      context: context,
    );
  }

  TriggerEvaluationResult _evaluateSentimentResult(
    SentimentResult result,
    AutomationTriggerConfig config,
    Map<String, dynamic> context,
  ) {
    // Check confidence
    if (result.confidence < config.minConfidence) {
      return TriggerEvaluationResult.skip(
        value: result.sentimentScore,
        threshold: config.threshold,
        reason:
            'Confidence ${(result.confidence * 100).toStringAsFixed(0)}% '
            'below minimum ${(config.minConfidence * 100).toStringAsFixed(0)}%',
        context: {
          'sentimentScore': result.sentimentScore,
          'confidence': result.confidence,
        },
      );
    }

    // For negative sentiment, we use 'lte' comparison by default
    // Sentiment score: -1.0 (very negative) to 1.0 (very positive)
    final comparison = config.comparison == 'gte' ? 'lte' : config.comparison;
    final shouldFire =
        compareValue(result.sentimentScore, config.threshold, comparison);

    if (shouldFire) {
      return TriggerEvaluationResult.fire(
        value: result.sentimentScore,
        threshold: config.threshold,
        confidence: result.confidence,
        reason:
            'Sentiment score ${result.sentimentScore.toStringAsFixed(2)} '
            'is ${result.category.name}',
        context: {
          'clientId': result.clientId,
          'source': result.source.name,
          'category': result.category.name,
          'riskIndicatorCount': result.riskIndicators.length,
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: result.sentimentScore,
      threshold: config.threshold,
      reason:
          'Sentiment score ${result.sentimentScore.toStringAsFixed(2)} '
          'does not meet threshold ${config.threshold}',
      context: {
        'clientId': result.clientId,
        'category': result.category.name,
      },
    );
  }

  TriggerEvaluationResult _evaluateClientRiskScore(
    ClientRiskScore score,
    AutomationTriggerConfig config,
    Map<String, dynamic> context,
  ) {
    // Use satisfaction score (0-100), convert threshold if needed
    final threshold = config.threshold < 1 ? config.threshold * 100 : config.threshold;
    final shouldFire =
        compareValue(score.satisfactionScore.toDouble(), threshold, 'lte');

    if (shouldFire) {
      return TriggerEvaluationResult.fire(
        value: score.satisfactionScore.toDouble(),
        threshold: threshold,
        confidence: score.hasReliableData ? 0.8 : 0.5,
        reason: 'Satisfaction score ${score.satisfactionScore} is low',
        context: {
          'clientId': score.clientId,
          'satisfactionScore': score.satisfactionScore,
          'churnRiskScore': score.churnRiskScore,
          'textsAnalyzed': score.textsAnalyzed,
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: score.satisfactionScore.toDouble(),
      threshold: threshold,
      reason:
          'Satisfaction score ${score.satisfactionScore} '
          'above threshold $threshold',
      context: {
        'clientId': score.clientId,
      },
    );
  }

  TriggerEvaluationResult _evaluateIndicators(
    AutomationTriggerConfig config,
    Map<String, dynamic> context,
  ) {
    final sentimentResult = context['sentimentResult'] as SentimentResult?;
    final clientRiskScore = context['clientRiskScore'] as ClientRiskScore?;

    // Collect all risk indicators
    final indicators = <String>[];
    if (sentimentResult != null) {
      indicators.addAll(
        sentimentResult.riskIndicators.map((i) => i.category),
      );
    }
    if (clientRiskScore != null) {
      indicators.addAll(
        clientRiskScore.riskIndicators.map((i) => i.category),
      );
    }

    // Check if any configured indicator types are present
    final matchedIndicators = config.indicatorTypes
        .where((type) => indicators.contains(type))
        .toList();

    if (matchedIndicators.isNotEmpty) {
      return TriggerEvaluationResult.fire(
        value: matchedIndicators.length.toDouble(),
        threshold: 1,
        confidence: 0.9,
        reason: 'Risk indicators detected: ${matchedIndicators.join(", ")}',
        context: {
          'matchedIndicators': matchedIndicators,
          'allIndicators': indicators,
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: 0,
      threshold: 1,
      reason: 'No matching risk indicators found',
      context: {
        'configuredIndicators': config.indicatorTypes,
        'foundIndicators': indicators,
      },
    );
  }
}

/// Evaluates churn risk scores.
///
/// Fires when client churn risk score exceeds threshold.
class ChurnRiskTrigger extends TriggerEvaluator {
  @override
  TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  }) {
    final clientRiskScore = context['clientRiskScore'] as ClientRiskScore?;

    if (clientRiskScore == null) {
      return TriggerEvaluationResult.skip(
        value: 0,
        threshold: config.threshold,
        reason: 'No client risk score available',
        context: context,
      );
    }

    if (clientRiskScore.isEmpty) {
      return TriggerEvaluationResult.skip(
        value: 0,
        threshold: config.threshold,
        reason: 'Client risk score is empty (no data)',
        context: {'clientId': clientRiskScore.clientId},
      );
    }

    // Convert threshold if needed (0-1 to 0-100)
    final threshold = config.threshold < 1 ? config.threshold * 100 : config.threshold;

    // Confidence based on data reliability
    final confidence = clientRiskScore.hasReliableData ? 0.85 : 0.5;

    if (confidence < config.minConfidence) {
      return TriggerEvaluationResult.skip(
        value: clientRiskScore.churnRiskScore.toDouble(),
        threshold: threshold,
        reason:
            'Data reliability ${(confidence * 100).toStringAsFixed(0)}% '
            'below minimum ${(config.minConfidence * 100).toStringAsFixed(0)}%',
        context: {
          'clientId': clientRiskScore.clientId,
          'textsAnalyzed': clientRiskScore.textsAnalyzed,
        },
      );
    }

    final shouldFire = compareValue(
      clientRiskScore.churnRiskScore.toDouble(),
      threshold,
      config.comparison,
    );

    if (shouldFire) {
      return TriggerEvaluationResult.fire(
        value: clientRiskScore.churnRiskScore.toDouble(),
        threshold: threshold,
        confidence: confidence,
        reason:
            'Churn risk score ${clientRiskScore.churnRiskScore} '
            '${config.comparison} $threshold',
        context: {
          'clientId': clientRiskScore.clientId,
          'churnRiskScore': clientRiskScore.churnRiskScore,
          'churnTrend': clientRiskScore.churnTrend.name,
          'topRiskFactors': clientRiskScore.topRiskFactors,
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: clientRiskScore.churnRiskScore.toDouble(),
      threshold: threshold,
      reason:
          'Churn risk score ${clientRiskScore.churnRiskScore} '
          'does not meet threshold $threshold',
      context: {
        'clientId': clientRiskScore.clientId,
        'churnTrend': clientRiskScore.churnTrend.name,
      },
    );
  }
}

/// Evaluates VIP indicators.
///
/// Fires when VIP indicators are detected for a client.
class VipDetectedTrigger extends TriggerEvaluator {
  @override
  TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  }) {
    final clientRiskScore = context['clientRiskScore'] as ClientRiskScore?;
    final sentimentResult = context['sentimentResult'] as SentimentResult?;

    // Collect VIP indicators
    final vipIndicators = <String>[];
    int vipScore = 0;

    if (clientRiskScore != null) {
      vipIndicators.addAll(
        clientRiskScore.vipIndicators.map((i) => i.category),
      );
      vipScore = clientRiskScore.vipScore;
    }

    if (sentimentResult != null) {
      vipIndicators.addAll(
        sentimentResult.vipIndicators.map((i) => i.category),
      );
    }

    // Check for specific indicator types if configured
    if (config.indicatorTypes.isNotEmpty) {
      final matchedIndicators = config.indicatorTypes
          .where((type) => vipIndicators.contains(type))
          .toList();

      if (matchedIndicators.isNotEmpty) {
        return TriggerEvaluationResult.fire(
          value: matchedIndicators.length.toDouble(),
          threshold: 1,
          confidence: 0.9,
          reason: 'VIP indicators detected: ${matchedIndicators.join(", ")}',
          context: {
            'matchedIndicators': matchedIndicators,
            'vipScore': vipScore,
          },
        );
      }

      return TriggerEvaluationResult.skip(
        value: 0,
        threshold: 1,
        reason: 'No matching VIP indicators found',
        context: {
          'configuredIndicators': config.indicatorTypes,
          'foundIndicators': vipIndicators,
        },
      );
    }

    // Use VIP score threshold
    final threshold = config.threshold < 1 ? config.threshold * 100 : config.threshold;
    final shouldFire = compareValue(vipScore.toDouble(), threshold, config.comparison);

    if (shouldFire) {
      return TriggerEvaluationResult.fire(
        value: vipScore.toDouble(),
        threshold: threshold,
        confidence: clientRiskScore?.hasReliableData == true ? 0.85 : 0.6,
        reason: 'VIP score $vipScore meets threshold $threshold',
        context: {
          'vipScore': vipScore,
          'vipIndicators': vipIndicators,
          'topVipFactors': clientRiskScore?.topVipFactors ?? [],
        },
      );
    }

    return TriggerEvaluationResult.skip(
      value: vipScore.toDouble(),
      threshold: threshold,
      reason: 'VIP score $vipScore does not meet threshold $threshold',
      context: {
        'vipScore': vipScore,
        'vipIndicatorCount': vipIndicators.length,
      },
    );
  }
}

/// Factory for creating trigger evaluators.
class TriggerEvaluatorFactory {
  static final Map<AutomationTriggerType, TriggerEvaluator> _evaluators = {
    AutomationTriggerType.noShowRisk: NoShowRiskTrigger(),
    AutomationTriggerType.negativeSentiment: SentimentTrigger(),
    AutomationTriggerType.churnRisk: ChurnRiskTrigger(),
    AutomationTriggerType.vipDetected: VipDetectedTrigger(),
  };

  /// Get evaluator for a trigger type.
  static TriggerEvaluator getEvaluator(AutomationTriggerType type) {
    final evaluator = _evaluators[type];
    if (evaluator == null) {
      throw ArgumentError('Unknown trigger type: $type');
    }
    return evaluator;
  }

  /// Evaluate a trigger configuration with context.
  static TriggerEvaluationResult evaluate({
    required AutomationTriggerConfig config,
    required Map<String, dynamic> context,
  }) {
    final evaluator = getEvaluator(config.type);
    return evaluator.evaluate(config: config, context: context);
  }
}
