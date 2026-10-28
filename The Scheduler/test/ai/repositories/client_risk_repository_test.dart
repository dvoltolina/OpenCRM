@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:the_scheduler/ai/repositories/client_risk_repository.dart';
import 'package:the_scheduler/ai/models/client_risk_score.dart';
import 'package:the_scheduler/ai/models/sentiment_result.dart';
import 'package:the_scheduler/ai/models/sentiment_source.dart';
import 'package:the_scheduler/ai/models/risk_indicator.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/core/services/encryption_service.dart';

/// Tests for ClientRiskRepository
///
/// Agent AI-5: Sentiment Analysis Data Models & Repository
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ClientRiskRepository repository;
  late SecurityContext context;
  late EncryptionService encryptionService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    encryptionService = MockEncryptionService()..initialize();
    repository = ClientRiskRepository(
      firestore: fakeFirestore,
      encryptionService: encryptionService,
    );
    context = const SecurityContext(
      businessId: 'test_business',
      userId: 'test_user',
      role: UserRole.admin,
    );
  });

  group('ClientRiskRepository - Risk Scores', () {
    test('saves and retrieves client risk score', () async {
      final score = ClientRiskScore(
        id: 'score_1',
        clientId: 'client_123',
        businessId: 'test_business',
        calculatedAt: DateTime.now(),
        churnRiskScore: 45,
        satisfactionScore: 72,
        vipScore: 30,
        overallHealthScore: 65,
        churnTrend: ScoreTrend.stable,
        satisfactionTrend: ScoreTrend.improving,
        vipTrend: ScoreTrend.stable,
        riskIndicators: const [],
        vipIndicators: const [],
        topRiskFactors: const ['Late cancellations'],
        topVipFactors: const [],
        textsAnalyzed: 5,
        analysisStartDate: DateTime.now().subtract(const Duration(days: 30)),
        analysisEndDate: DateTime.now(),
        averageSentiment: 0.2,
        sentimentStdDev: 0.15,
        recommendedActions: const [],
        scoringVersion: '1.0.0',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await repository.saveClientRiskScore(context, score);

      final retrieved =
          await repository.getClientRiskScore(context, 'client_123');

      expect(retrieved, isNotNull);
      expect(retrieved!.clientId, 'client_123');
      expect(retrieved.churnRiskScore, 45);
      expect(retrieved.satisfactionScore, 72);
    });

    test('returns null for non-existent client', () async {
      final result =
          await repository.getClientRiskScore(context, 'nonexistent');
      expect(result, isNull);
    });

    test('updates existing score and archives to history', () async {
      final initialScore = ClientRiskScore.empty(
        clientId: 'client_123',
        businessId: 'test_business',
      ).copyWith(churnRiskScore: 30);

      await repository.saveClientRiskScore(context, initialScore);

      // Update with new score
      final updatedScore = initialScore.copyWith(
        churnRiskScore: 50,
        calculatedAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await repository.saveClientRiskScore(context, updatedScore);

      // Current score should be updated
      final current =
          await repository.getClientRiskScore(context, 'client_123');
      expect(current!.churnRiskScore, 50);

      // History should contain old score
      final history =
          await repository.getClientRiskScoreHistory(context, 'client_123');
      expect(history.length, 1);
      expect(history.first.churnRiskScore, 30);
    });

    test('gets high risk clients', () async {
      // Create some test scores with varying churn risk
      for (var i = 0; i < 5; i++) {
        final score = ClientRiskScore.empty(
          clientId: 'client_$i',
          businessId: 'test_business',
        ).copyWith(
          id: 'score_$i',
          churnRiskScore: 50 + i * 10, // 50, 60, 70, 80, 90
        );

        await repository.saveClientRiskScore(context, score);
      }

      final highRisk =
          await repository.getHighRiskClients(context, minChurnScore: 70);

      expect(highRisk.length, 3); // Scores 70, 80, 90
      for (final score in highRisk) {
        expect(score.churnRiskScore, greaterThanOrEqualTo(70));
      }
    });

    test('gets VIP clients', () async {
      for (var i = 0; i < 5; i++) {
        final score = ClientRiskScore.empty(
          clientId: 'client_$i',
          businessId: 'test_business',
        ).copyWith(
          id: 'score_$i',
          vipScore: 50 + i * 10, // 50, 60, 70, 80, 90
        );

        await repository.saveClientRiskScore(context, score);
      }

      final vips = await repository.getVipClients(context, minVipScore: 70);

      expect(vips.length, 3); // Scores 70, 80, 90
      for (final score in vips) {
        expect(score.vipScore, greaterThanOrEqualTo(70));
      }
    });

    test('batch retrieves multiple client scores', () async {
      for (var i = 0; i < 5; i++) {
        final score = ClientRiskScore.empty(
          clientId: 'client_$i',
          businessId: 'test_business',
        );
        await repository.saveClientRiskScore(context, score);
      }

      final scores = await repository.getClientRiskScoresBatch(
        context,
        ['client_0', 'client_2', 'client_4'],
      );

      expect(scores.length, 3);
      expect(scores.containsKey('client_0'), true);
      expect(scores.containsKey('client_2'), true);
      expect(scores.containsKey('client_4'), true);
    });

    test('deletes client risk score and history', () async {
      final score = ClientRiskScore.empty(
        clientId: 'client_123',
        businessId: 'test_business',
      );

      await repository.saveClientRiskScore(context, score);

      // Update to create history
      await repository.saveClientRiskScore(
        context,
        score.copyWith(churnRiskScore: 50),
      );

      // Verify score exists
      expect(
        await repository.getClientRiskScore(context, 'client_123'),
        isNotNull,
      );

      // Delete
      await repository.deleteClientRiskScore(context, 'client_123');

      // Verify deleted
      expect(
        await repository.getClientRiskScore(context, 'client_123'),
        isNull,
      );

      // Verify history deleted
      final history =
          await repository.getClientRiskScoreHistory(context, 'client_123');
      expect(history, isEmpty);
    });

    test('multi-tenant isolation - cannot access cross-business scores',
        () async {
      // Save score for business A
      final scoreA = ClientRiskScore.empty(
        clientId: 'client_123',
        businessId: 'business_A',
      );

      final contextA = const SecurityContext(
        businessId: 'business_A',
        userId: 'user_A',
        role: UserRole.admin,
      );

      await ClientRiskRepository(firestore: fakeFirestore)
          .saveClientRiskScore(contextA, scoreA);

      // Try to access from business B
      final contextB = const SecurityContext(
        businessId: 'business_B',
        userId: 'user_B',
        role: UserRole.admin,
      );

      final result = await ClientRiskRepository(firestore: fakeFirestore)
          .getClientRiskScore(contextB, 'client_123');

      expect(result, isNull); // Cannot see business A's data
    });
  });

  group('ClientRiskRepository - Sentiment Results', () {
    test('saves and retrieves sentiment results', () async {
      final result = SentimentResult(
        id: 'result_1',
        businessId: 'test_business',
        clientId: 'client_123',
        source: SentimentSource.smsReply,
        sourceDocumentId: 'msg_456',
        analyzedText: 'Thanks for the appointment!',
        sentimentScore: 0.8,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        summary: 'Positive feedback',
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await repository.saveSentimentResult(context, result);

      final results = await repository.getClientSentimentResults(
        context,
        'client_123',
      );

      expect(results.length, 1);
      expect(results.first.sentimentScore, 0.8);
      expect(results.first.source, SentimentSource.smsReply);
    });

    test('batch saves sentiment results', () async {
      final results = List.generate(
        5,
        (i) => SentimentResult(
          id: 'result_$i',
          businessId: 'test_business',
          clientId: 'client_123',
          source: SentimentSource.smsReply,
          analyzedText: 'Test message $i',
          sentimentScore: 0.5,
          confidence: 0.8,
          riskIndicators: const [],
          vipIndicators: const [],
          modelVersion: '1.0.0',
          analyzedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      await repository.saveSentimentResultsBatch(context, results);

      final retrieved = await repository.getClientSentimentResults(
        context,
        'client_123',
      );

      expect(retrieved.length, 5);
    });

    test('gets sentiment result by source document', () async {
      final result = SentimentResult(
        id: 'result_1',
        businessId: 'test_business',
        clientId: 'client_123',
        source: SentimentSource.cancellationReason,
        sourceDocumentId: 'appt_789',
        analyzedText: 'Cannot make it due to work',
        sentimentScore: -0.2,
        confidence: 0.85,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await repository.saveSentimentResult(context, result);

      final retrieved = await repository.getSentimentResultBySource(
        context,
        'appt_789',
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.sourceDocumentId, 'appt_789');
    });

    test('gets analyzed source document IDs', () async {
      for (var i = 0; i < 3; i++) {
        await repository.saveSentimentResult(
          context,
          SentimentResult(
            id: 'result_$i',
            businessId: 'test_business',
            clientId: 'client_123',
            source: SentimentSource.smsReply,
            sourceDocumentId: 'msg_$i',
            analyzedText: 'Test $i',
            sentimentScore: 0.5,
            confidence: 0.8,
            riskIndicators: const [],
            vipIndicators: const [],
            modelVersion: '1.0.0',
            analyzedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        );
      }

      final analyzedIds = await repository.getAnalyzedSourceDocumentIds(
        context,
        'client_123',
      );

      expect(analyzedIds.length, 3);
      expect(analyzedIds.contains('msg_0'), true);
      expect(analyzedIds.contains('msg_1'), true);
      expect(analyzedIds.contains('msg_2'), true);
    });

    test('deletes expired sentiment results', () async {
      // Create expired result
      await repository.saveSentimentResult(
        context,
        SentimentResult(
          id: 'expired_result',
          businessId: 'test_business',
          clientId: 'client_123',
          source: SentimentSource.smsReply,
          analyzedText: 'Old message',
          sentimentScore: 0.5,
          confidence: 0.8,
          riskIndicators: const [],
          vipIndicators: const [],
          modelVersion: '1.0.0',
          analyzedAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );

      // Create non-expired result
      await repository.saveSentimentResult(
        context,
        SentimentResult(
          id: 'fresh_result',
          businessId: 'test_business',
          clientId: 'client_123',
          source: SentimentSource.smsReply,
          analyzedText: 'Recent message',
          sentimentScore: 0.5,
          confidence: 0.8,
          riskIndicators: const [],
          vipIndicators: const [],
          modelVersion: '1.0.0',
          analyzedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      final deletedCount = await repository.deleteExpiredSentimentResults(
        context,
      );

      expect(deletedCount, 1);

      final remaining = await repository.getClientSentimentResults(
        context,
        'client_123',
      );

      expect(remaining.length, 1);
      expect(remaining.first.id, 'fresh_result');
    });
  });

  group('ClientRiskScore Model', () {
    test('empty factory creates default score', () {
      final empty = ClientRiskScore.empty(
        clientId: 'client_123',
        businessId: 'business_456',
      );

      expect(empty.clientId, 'client_123');
      expect(empty.businessId, 'business_456');
      expect(empty.churnRiskScore, 0);
      expect(empty.satisfactionScore, 50);
      expect(empty.isEmpty, true);
    });

    test('riskLevel classification works correctly', () {
      final lowRisk = ClientRiskScore.empty(
        clientId: 'c1',
        businessId: 'b1',
      ).copyWith(churnRiskScore: 30);

      final mediumRisk = ClientRiskScore.empty(
        clientId: 'c2',
        businessId: 'b1',
      ).copyWith(churnRiskScore: 50);

      final highRisk = ClientRiskScore.empty(
        clientId: 'c3',
        businessId: 'b1',
      ).copyWith(churnRiskScore: 75);

      expect(lowRisk.riskLevel, ClientRiskLevel.low);
      expect(mediumRisk.riskLevel, ClientRiskLevel.medium);
      expect(highRisk.riskLevel, ClientRiskLevel.high);
    });

    test('needsAttention flag works correctly', () {
      final normalScore = ClientRiskScore.empty(
        clientId: 'c1',
        businessId: 'b1',
      ).copyWith(churnRiskScore: 50);

      final highRiskScore = ClientRiskScore.empty(
        clientId: 'c2',
        businessId: 'b1',
      ).copyWith(churnRiskScore: 75);

      final criticalIndicatorScore = ClientRiskScore.empty(
        clientId: 'c3',
        businessId: 'b1',
      ).copyWith(
        churnRiskScore: 30,
        riskIndicators: [
          RiskIndicator(
            id: 'ind_1',
            type: IndicatorType.risk,
            severity: IndicatorSeverity.critical,
            category: RiskCategories.churnIntent,
            description: 'Client mentioned leaving',
            confidence: 0.9,
            source: SentimentSource.smsReply,
            detectedAt: DateTime.now(),
          ),
        ],
      );

      expect(normalScore.needsAttention, false);
      expect(highRiskScore.needsAttention, true);
      expect(criticalIndicatorScore.needsAttention, true);
    });

    test('isPotentialVip flag works correctly', () {
      final normalScore = ClientRiskScore.empty(
        clientId: 'c1',
        businessId: 'b1',
      ).copyWith(vipScore: 50);

      final vipScore = ClientRiskScore.empty(
        clientId: 'c2',
        businessId: 'b1',
      ).copyWith(vipScore: 80);

      expect(normalScore.isPotentialVip, false);
      expect(vipScore.isPotentialVip, true);
    });
  });

  group('SentimentResult Model', () {
    test('category classification works correctly', () {
      final positive = SentimentResult(
        id: 'r1',
        businessId: 'b1',
        clientId: 'c1',
        source: SentimentSource.smsReply,
        analyzedText: 'Great!',
        sentimentScore: 0.5,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      final neutral = SentimentResult(
        id: 'r2',
        businessId: 'b1',
        clientId: 'c1',
        source: SentimentSource.smsReply,
        analyzedText: 'Ok',
        sentimentScore: 0.0,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      final negative = SentimentResult(
        id: 'r3',
        businessId: 'b1',
        clientId: 'c1',
        source: SentimentSource.smsReply,
        analyzedText: 'Bad',
        sentimentScore: -0.5,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(positive.category, SentimentCategory.positive);
      expect(neutral.category, SentimentCategory.neutral);
      expect(negative.category, SentimentCategory.negative);
    });

    test('weightedScore applies source weight', () {
      final smsResult = SentimentResult(
        id: 'r1',
        businessId: 'b1',
        clientId: 'c1',
        source: SentimentSource.smsReply, // weight 0.9
        analyzedText: 'Text',
        sentimentScore: 0.8,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      final feedbackResult = SentimentResult(
        id: 'r2',
        businessId: 'b1',
        clientId: 'c1',
        source: SentimentSource.feedbackText, // weight 1.0
        analyzedText: 'Text',
        sentimentScore: 0.8,
        confidence: 0.9,
        riskIndicators: const [],
        vipIndicators: const [],
        modelVersion: '1.0.0',
        analyzedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(smsResult.weightedScore, closeTo(0.72, 0.01)); // 0.8 * 0.9
      expect(feedbackResult.weightedScore, closeTo(0.8, 0.01)); // 0.8 * 1.0
    });
  });
}
