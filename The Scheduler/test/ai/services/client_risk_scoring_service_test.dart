@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/ai/services/client_risk_scoring_service.dart';
import 'package:the_scheduler/ai/repositories/client_risk_repository.dart';
import 'package:the_scheduler/ai/models/client_risk_score.dart';
import 'package:the_scheduler/ai/models/sentiment_result.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/models/risk_indicator.dart';

@GenerateMocks([ClientRiskRepository])
import 'client_risk_scoring_service_test.mocks.dart';

void main() {
  late ClientRiskScoringService service;
  late MockClientRiskRepository mockRiskRepo;
  late SecurityContext testContext;

  setUp(() {
    mockRiskRepo = MockClientRiskRepository();
    service = ClientRiskScoringService(riskRepo: mockRiskRepo);

    testContext = SecurityContext(
      userId: 'user_1',
      businessId: 'biz_001',
      roles: ['staff'],
    );

    // Default mock setup
    when(mockRiskRepo.getClientRiskScore(any, any))
        .thenAnswer((_) async => null);
    when(mockRiskRepo.saveClientRiskScore(any, any))
        .thenAnswer((_) async {});
  });

  group('ClientRiskScoringService', () {
    group('calculateScore', () {
      test('returns empty score for empty sentiment results', () {
        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: [],
        );

        expect(score.clientId, 'client_001');
        expect(score.businessId, 'biz_001');
        expect(score.textsAnalyzed, 0);
      });

      test('calculates positive sentiment as high satisfaction', () {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.8,
            confidence: 0.9,
          ),
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.7,
            confidence: 0.85,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        expect(score.satisfactionScore, greaterThan(70));
        expect(score.churnRiskScore, lessThan(30));
      });

      test('calculates negative sentiment as high churn risk', () {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: -0.7,
            confidence: 0.9,
          ),
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: -0.5,
            confidence: 0.85,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        expect(score.churnRiskScore, greaterThan(50));
        expect(score.satisfactionScore, lessThan(50));
      });

      test('includes risk indicators in score calculation', () {
        final riskIndicators = [
          RiskIndicator(
            id: 'ri_1',
            type: IndicatorType.negative,
            severity: IndicatorSeverity.high,
            category: 'churn_intent',
            description: 'Client mentioned leaving',
            confidence: 0.9,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ];

        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: -0.3,
            confidence: 0.85,
            riskIndicators: riskIndicators,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        // High severity indicator should boost churn risk significantly
        expect(score.churnRiskScore, greaterThan(40));
        expect(score.riskIndicators, contains(riskIndicators.first));
      });

      test('includes VIP indicators in score calculation', () {
        final vipIndicators = [
          RiskIndicator(
            id: 'vi_1',
            type: IndicatorType.positive,
            severity: IndicatorSeverity.medium,
            category: 'referral_intent',
            description: 'Client wants to refer friends',
            confidence: 0.9,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ];

        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.6,
            confidence: 0.85,
            vipIndicators: vipIndicators,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        // Referral intent should boost VIP score significantly (25 points)
        expect(score.vipScore, greaterThan(40));
        expect(score.vipIndicators, contains(vipIndicators.first));
      });

      test('considers noshow count in churn risk', () {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.0, // Neutral
            confidence: 0.8,
          ),
        ];

        final scoreWithNoshows = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
          recentNoshowCount: 3,
        );

        final scoreWithoutNoshows = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
          recentNoshowCount: 0,
        );

        // 3 noshows should add 24 points to churn risk (3 * 8)
        expect(
          scoreWithNoshows.churnRiskScore,
          greaterThan(scoreWithoutNoshows.churnRiskScore),
        );
      });

      test('considers days since last visit in churn risk', () {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.0,
            confidence: 0.8,
          ),
        ];

        final scoreRecent = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
          daysSinceLastVisit: 10,
        );

        final scoreInactive = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
          daysSinceLastVisit: 100, // >90 days adds 15 points
        );

        expect(
          scoreInactive.churnRiskScore,
          greaterThan(scoreRecent.churnRiskScore),
        );
      });

      test('calculates trend from previous score', () {
        final previousScore = ClientRiskScore(
          id: 'prev_score',
          clientId: 'client_001',
          businessId: 'biz_001',
          calculatedAt: DateTime.now().subtract(const Duration(days: 7)),
          churnRiskScore: 50,
          satisfactionScore: 50,
          vipScore: 30,
          overallHealthScore: 50,
          churnTrend: ScoreTrend.stable,
          satisfactionTrend: ScoreTrend.stable,
          vipTrend: ScoreTrend.stable,
          riskIndicators: [],
          vipIndicators: [],
          textsAnalyzed: 5,
          analysisStartDate: DateTime.now().subtract(const Duration(days: 30)),
          analysisEndDate: DateTime.now().subtract(const Duration(days: 7)),
          averageSentiment: 0.0,
          sentimentStdDev: 0.1,
          scoringVersion: '1.0.0',
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        // Create sentiment with much better scores
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.9,
            confidence: 0.95,
          ),
        ];

        final newScore = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
          previousScore: previousScore,
        );

        // Should detect improvement
        expect(newScore.satisfactionTrend, ScoreTrend.improving);
        // Churn should be declining (which is good - inverted)
        expect(newScore.churnTrend, ScoreTrend.improving);
      });

      test('generates recommended actions for high churn risk', () {
        final riskIndicators = [
          RiskIndicator(
            id: 'ri_1',
            type: IndicatorType.negative,
            severity: IndicatorSeverity.critical,
            category: 'churn_intent',
            description: 'Client said they are leaving',
            confidence: 0.95,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ];

        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: -0.8,
            confidence: 0.9,
            riskIndicators: riskIndicators,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        expect(score.recommendedActions, isNotEmpty);
        expect(
          score.recommendedActions.any((a) => a.actionId == 'urgent_outreach'),
          isTrue,
        );
      });

      test('generates recommended actions for VIP clients', () {
        final vipIndicators = [
          RiskIndicator(
            id: 'vi_1',
            type: IndicatorType.positive,
            severity: IndicatorSeverity.medium,
            category: 'referral_intent',
            description: 'Will tell friends',
            confidence: 0.9,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ];

        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.85,
            confidence: 0.9,
            vipIndicators: vipIndicators,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        expect(
          score.recommendedActions.any((a) => a.actionId == 'referral_program'),
          isTrue,
        );
      });

      test('weights newer results more heavily', () {
        final now = DateTime.now();
        final oldResult = _createSentimentResult(
          clientId: 'client_001',
          sentimentScore: -0.5, // Negative
          confidence: 0.9,
          analyzedAt: now.subtract(const Duration(days: 30)),
        );
        final newResult = _createSentimentResult(
          clientId: 'client_001',
          sentimentScore: 0.8, // Positive
          confidence: 0.9,
          analyzedAt: now,
        );

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: [newResult, oldResult],
        );

        // Newer positive result should dominate
        expect(score.satisfactionScore, greaterThan(60));
        expect(score.averageSentiment, greaterThan(0));
      });
    });

    group('calculateAndSaveScore', () {
      test('saves score to repository', () async {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.5,
            confidence: 0.85,
          ),
        ];

        final score = await service.calculateAndSaveScore(
          context: testContext,
          clientId: 'client_001',
          sentimentResults: sentimentResults,
        );

        verify(mockRiskRepo.saveClientRiskScore(testContext, any)).called(1);
        expect(score.clientId, 'client_001');
      });

      test('fetches previous score for trend calculation', () async {
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.5,
            confidence: 0.85,
          ),
        ];

        await service.calculateAndSaveScore(
          context: testContext,
          clientId: 'client_001',
          sentimentResults: sentimentResults,
        );

        verify(mockRiskRepo.getClientRiskScore(testContext, 'client_001'))
            .called(1);
      });
    });

    group('overall health score', () {
      test('combines churn, satisfaction, and VIP scores', () {
        // High satisfaction, low churn, moderate VIP
        final sentimentResults = [
          _createSentimentResult(
            clientId: 'client_001',
            sentimentScore: 0.7,
            confidence: 0.9,
          ),
        ];

        final score = service.calculateScore(
          clientId: 'client_001',
          businessId: 'biz_001',
          sentimentResults: sentimentResults,
        );

        // Health = (invertedChurn * 0.4) + (satisfaction * 0.4) + (vip * 0.2)
        expect(score.overallHealthScore, greaterThan(50));
        expect(score.overallHealthScore, lessThanOrEqualTo(100));
      });
    });
  });
}

/// Helper to create a SentimentResult for testing.
SentimentResult _createSentimentResult({
  required String clientId,
  required double sentimentScore,
  required double confidence,
  List<RiskIndicator> riskIndicators = const [],
  List<RiskIndicator> vipIndicators = const [],
  DateTime? analyzedAt,
}) {
  final now = analyzedAt ?? DateTime.now();
  return SentimentResult(
    id: 'sentiment_${now.millisecondsSinceEpoch}',
    businessId: 'biz_001',
    clientId: clientId,
    source: SentimentSource.smsReply,
    analyzedText: 'Test text',
    sentimentScore: sentimentScore,
    confidence: confidence,
    riskIndicators: riskIndicators,
    vipIndicators: vipIndicators,
    modelVersion: 'phi3:mini',
    analyzedAt: now,
    expiresAt: now.add(const Duration(days: 7)),
  );
}
