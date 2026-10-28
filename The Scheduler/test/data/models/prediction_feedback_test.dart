import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/prediction_feedback.dart';

void main() {
  group('FeedbackType', () {
    test('has correct display names', () {
      expect(FeedbackType.positive.displayName, equals('Helpful'));
      expect(FeedbackType.negative.displayName, equals('Not Helpful'));
      expect(FeedbackType.skipped.displayName, equals('Skipped'));
    });

    test('has correct emojis', () {
      expect(FeedbackType.positive.emoji, equals('👍'));
      expect(FeedbackType.negative.emoji, equals('👎'));
      expect(FeedbackType.skipped.emoji, equals('⏭️'));
    });

    test('has correct base weights', () {
      expect(FeedbackType.positive.baseWeight, equals(1.0));
      expect(FeedbackType.negative.baseWeight, equals(1.0));
      expect(FeedbackType.skipped.baseWeight, equals(0.0));
    });
  });

  group('NegativeFeedbackReason', () {
    test('has correct display names', () {
      expect(
        NegativeFeedbackReason.probabilityTooHigh.displayName,
        equals('Probability too high'),
      );
      expect(
        NegativeFeedbackReason.probabilityTooLow.displayName,
        equals('Probability too low'),
      );
      expect(
        NegativeFeedbackReason.wrongFactors.displayName,
        equals('Wrong risk factors shown'),
      );
      expect(
        NegativeFeedbackReason.doesntMatchBehavior.displayName,
        equals("Doesn't match client behavior"),
      );
      expect(
        NegativeFeedbackReason.inappropriateAction.displayName,
        equals('Suggested action not appropriate'),
      );
      expect(NegativeFeedbackReason.other.displayName, equals('Other'));
    });
  });

  group('FeedbackUserRole', () {
    test('has correct display names', () {
      expect(FeedbackUserRole.admin.displayName, equals('Admin'));
      expect(FeedbackUserRole.manager.displayName, equals('Manager'));
      expect(FeedbackUserRole.staff.displayName, equals('Staff'));
      expect(FeedbackUserRole.guest.displayName, equals('Guest'));
    });

    test('has correct role weights', () {
      expect(FeedbackUserRole.admin.roleWeight, equals(2.0));
      expect(FeedbackUserRole.manager.roleWeight, equals(1.5));
      expect(FeedbackUserRole.staff.roleWeight, equals(1.0));
      expect(FeedbackUserRole.guest.roleWeight, equals(0.5));
    });
  });

  group('PredictionFeedback', () {
    PredictionFeedback createFeedback({
      FeedbackType type = FeedbackType.positive,
      FeedbackUserRole role = FeedbackUserRole.staff,
      NegativeFeedbackReason? reason,
      double weight = 1.0,
    }) {
      return PredictionFeedback(
        id: 'feedback_123',
        businessId: 'biz_123',
        appointmentId: 'appt_123',
        clientId: 'client_123',
        userId: 'user_123',
        userRole: role,
        feedbackType: type,
        negativeReason: reason,
        modelVersion: 'v1.0',
        predictedProbability: 0.75,
        predictedRiskLevel: 'high',
        submittedAt: DateTime.now(),
        weight: weight,
      );
    }

    test('calculates weighted score for positive feedback', () {
      final feedback = createFeedback(
        type: FeedbackType.positive,
        weight: 2.0,
      );

      expect(feedback.weightedScore, equals(2.0));
    });

    test('calculates weighted score for negative feedback', () {
      final feedback = createFeedback(
        type: FeedbackType.negative,
        weight: 1.5,
      );

      expect(feedback.weightedScore, equals(-1.5));
    });

    test('calculates weighted score for skipped feedback', () {
      final feedback = createFeedback(
        type: FeedbackType.skipped,
        weight: 1.0,
      );

      expect(feedback.weightedScore, equals(0.0));
    });

    test('isActionable returns true for positive feedback', () {
      final feedback = createFeedback(type: FeedbackType.positive);
      expect(feedback.isActionable, isTrue);
    });

    test('isActionable returns true for negative feedback', () {
      final feedback = createFeedback(type: FeedbackType.negative);
      expect(feedback.isActionable, isTrue);
    });

    test('isActionable returns false for skipped feedback', () {
      final feedback = createFeedback(type: FeedbackType.skipped);
      expect(feedback.isActionable, isFalse);
    });

    test('indicatesModelProblem returns true for specific negative reasons', () {
      final feedback = createFeedback(
        type: FeedbackType.negative,
        reason: NegativeFeedbackReason.probabilityTooHigh,
      );

      expect(feedback.indicatesModelProblem, isTrue);
    });

    test('indicatesModelProblem returns false for "other" reason', () {
      final feedback = createFeedback(
        type: FeedbackType.negative,
        reason: NegativeFeedbackReason.other,
      );

      expect(feedback.indicatesModelProblem, isFalse);
    });

    test('indicatesModelProblem returns false for positive feedback', () {
      final feedback = createFeedback(type: FeedbackType.positive);
      expect(feedback.indicatesModelProblem, isFalse);
    });

    test('create factory calculates weight correctly for admin', () {
      final feedback = PredictionFeedback.create(
        id: 'feedback_123',
        businessId: 'biz_123',
        appointmentId: 'appt_123',
        clientId: 'client_123',
        userId: 'user_123',
        userRole: FeedbackUserRole.admin,
        feedbackType: FeedbackType.positive,
        modelVersion: 'v1.0',
        predictedProbability: 0.75,
        predictedRiskLevel: 'high',
      );

      expect(feedback.weight, equals(2.0)); // admin = 2.0, positive = 1.0
    });

    test('create factory calculates weight correctly for manager', () {
      final feedback = PredictionFeedback.create(
        id: 'feedback_123',
        businessId: 'biz_123',
        appointmentId: 'appt_123',
        clientId: 'client_123',
        userId: 'user_123',
        userRole: FeedbackUserRole.manager,
        feedbackType: FeedbackType.negative,
        modelVersion: 'v1.0',
        predictedProbability: 0.75,
        predictedRiskLevel: 'high',
      );

      expect(feedback.weight, equals(1.5)); // manager = 1.5, negative = 1.0
    });

    test('create factory calculates zero weight for skipped', () {
      final feedback = PredictionFeedback.create(
        id: 'feedback_123',
        businessId: 'biz_123',
        appointmentId: 'appt_123',
        clientId: 'client_123',
        userId: 'user_123',
        userRole: FeedbackUserRole.admin,
        feedbackType: FeedbackType.skipped,
        modelVersion: 'v1.0',
        predictedProbability: 0.75,
        predictedRiskLevel: 'high',
      );

      expect(feedback.weight, equals(0.0)); // skipped base = 0.0
    });
  });

  group('FeedbackSummary', () {
    FeedbackSummary createSummary({
      int positive = 70,
      int negative = 20,
      int skipped = 10,
      double weightedSum = 50,
      double totalWeight = 90,
    }) {
      return FeedbackSummary(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
        totalFeedback: positive + negative + skipped,
        positiveCount: positive,
        negativeCount: negative,
        skippedCount: skipped,
        weightedScoreSum: weightedSum,
        totalWeight: totalWeight,
      );
    }

    test('actionableFeedback excludes skipped', () {
      final summary = createSummary(positive: 70, negative: 20, skipped: 10);
      expect(summary.actionableFeedback, equals(90));
    });

    test('positiveRate calculates correctly', () {
      final summary = createSummary(positive: 70, negative: 30, skipped: 0);
      expect(summary.positiveRate, closeTo(0.7, 0.001));
    });

    test('negativeRate calculates correctly', () {
      final summary = createSummary(positive: 70, negative: 30, skipped: 0);
      expect(summary.negativeRate, closeTo(0.3, 0.001));
    });

    test('responseRate calculates correctly', () {
      final summary = createSummary(positive: 70, negative: 20, skipped: 10);
      expect(summary.responseRate, closeTo(0.9, 0.001));
    });

    test('averageWeightedScore calculates correctly', () {
      final summary = createSummary(weightedSum: 45, totalWeight: 90);
      expect(summary.averageWeightedScore, closeTo(0.5, 0.001));
    });

    test('scorePercentage converts to 0-100 scale', () {
      // averageWeightedScore of 0.5 should give 75%
      final summary = createSummary(weightedSum: 45, totalWeight: 90);
      expect(summary.scorePercentage, closeTo(75, 0.1));
    });

    test('netScore calculates correctly', () {
      // 70 positive - 30 negative = 40, / 100 * 100 = 40
      final summary = createSummary(positive: 70, negative: 30, skipped: 0);
      expect(summary.netScore, closeTo(40, 0.1));
    });

    test('handles zero actionable feedback', () {
      final summary = createSummary(positive: 0, negative: 0, skipped: 10);
      expect(summary.positiveRate, equals(0));
      expect(summary.negativeRate, equals(0));
      expect(summary.netScore, equals(0));
    });

    test('handles zero total weight', () {
      final summary = createSummary(totalWeight: 0);
      expect(summary.averageWeightedScore, equals(0));
    });

    test('empty factory creates zero summary', () {
      final summary = FeedbackSummary.empty(
        modelVersion: 'v1.0',
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 1, 31),
      );

      expect(summary.totalFeedback, equals(0));
      expect(summary.positiveCount, equals(0));
      expect(summary.negativeCount, equals(0));
      expect(summary.skippedCount, equals(0));
      expect(summary.positiveRate, equals(0));
    });
  });
}
