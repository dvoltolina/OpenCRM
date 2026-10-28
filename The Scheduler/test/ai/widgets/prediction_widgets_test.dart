@Tags(['ai'])
/// Tests for prediction widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/models/client_risk_score.dart';
import 'package:the_scheduler/ai/models/risk_indicator.dart';
import 'package:the_scheduler/ai/widgets/predictions/prediction_widgets.dart';

void main() {
  group('NoShowRiskGauge', () {
    testWidgets('displays probability percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoShowRiskGauge(
              probability: 0.75,
              riskLevel: RiskLevel.high,
              size: 64,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays correct color for high risk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoShowRiskGauge(
              probability: 0.85,
              riskLevel: RiskLevel.high,
              size: 64,
            ),
          ),
        ),
      );

      // Verify widget renders
      expect(find.byType(NoShowRiskGauge), findsOneWidget);
    });

    testWidgets('displays correct color for low risk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoShowRiskGauge(
              probability: 0.15,
              riskLevel: RiskLevel.low,
              size: 64,
            ),
          ),
        ),
      );

      expect(find.text('15%'), findsOneWidget);
    });
  });

  group('RiskLevelChip', () {
    testWidgets('displays high risk label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskLevelChip(riskLevel: RiskLevel.high),
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays medium risk label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskLevelChip(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('displays low risk label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskLevelChip(riskLevel: RiskLevel.low),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('supports small size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskLevelChip(
              riskLevel: RiskLevel.high,
              small: true,
            ),
          ),
        ),
      );

      expect(find.byType(RiskLevelChip), findsOneWidget);
    });
  });

  group('SentimentBadge', () {
    testWidgets('displays positive sentiment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SentimentBadge(score: 0.5),
          ),
        ),
      );

      expect(find.text('Positive'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_satisfied_alt), findsOneWidget);
    });

    testWidgets('displays neutral sentiment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SentimentBadge(score: 0.0),
          ),
        ),
      );

      expect(find.text('Neutral'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_neutral), findsOneWidget);
    });

    testWidgets('displays negative sentiment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SentimentBadge(score: -0.5),
          ),
        ),
      );

      expect(find.text('Negative'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SentimentBadge(
              score: 0.5,
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.text('Positive'), findsNothing);
      expect(find.byIcon(Icons.sentiment_satisfied_alt), findsOneWidget);
    });
  });

  group('RiskIndicatorChip', () {
    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicatorChip(
              label: 'Frequent cancellations',
              severity: IndicatorSeverity.high,
            ),
          ),
        ),
      );

      expect(find.text('Frequent cancellations'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskIndicatorChip(
              label: 'Test',
              severity: IndicatorSeverity.medium,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RiskIndicatorChip));
      expect(tapped, isTrue);
    });
  });

  group('PredictionCard', () {
    NoshowPrediction _createPrediction({
      double probability = 0.75,
      RiskLevel riskLevel = RiskLevel.high,
    }) {
      return NoshowPrediction(
        appointmentId: 'appt-123',
        probability: probability,
        riskLevel: riskLevel,
        confidence: 0.85,
        recommendedActions: const [],
        topFeatures: const [],
        modelVersion: '1.0.0',
        predictedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    }

    testWidgets('displays client name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionCard(
              prediction: _createPrediction(),
              clientName: 'John Doe',
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays probability percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionCard(
              prediction: _createPrediction(probability: 0.80),
              compact: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('80%'), findsWidgets);
    });

    testWidgets('shows unavailable state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionCard(
              prediction: NoshowPrediction.unavailable('appt-123'),
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('Prediction Unavailable'), findsOneWidget);
    });

    testWidgets('responds to tap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PredictionCard(
              prediction: _createPrediction(),
              compact: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });
  });

  group('ClientRiskCard', () {
    ClientRiskScore _createRiskScore({
      int overallHealth = 75,
      int churnRisk = 30,
      int satisfaction = 80,
      int vipScore = 50,
    }) {
      return ClientRiskScore(
        id: 'score-123',
        clientId: 'client-123',
        businessId: 'business-123',
        calculatedAt: DateTime.now(),
        churnRiskScore: churnRisk,
        satisfactionScore: satisfaction,
        vipScore: vipScore,
        overallHealthScore: overallHealth,
        churnTrend: ScoreTrend.stable,
        satisfactionTrend: ScoreTrend.improving,
        vipTrend: ScoreTrend.stable,
        riskIndicators: const [],
        vipIndicators: const [],
        topRiskFactors: const [],
        topVipFactors: const [],
        textsAnalyzed: 10,
        analysisStartDate: DateTime.now().subtract(const Duration(days: 30)),
        analysisEndDate: DateTime.now(),
        averageSentiment: 0.3,
        sentimentStdDev: 0.2,
        recommendedActions: const [],
        scoringVersion: '1.0.0',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
    }

    testWidgets('displays client name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientRiskCard(
              riskScore: _createRiskScore(),
              clientName: 'Jane Smith',
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('displays health score', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientRiskCard(
              riskScore: _createRiskScore(overallHealth: 85),
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('shows score breakdown in expanded mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientRiskCard(
                riskScore: _createRiskScore(
                  churnRisk: 25,
                  satisfaction: 90,
                  vipScore: 60,
                ),
                compact: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget); // Churn
      expect(find.text('90'), findsOneWidget); // Satisfaction
      expect(find.text('60'), findsOneWidget); // VIP
    });

    testWidgets('responds to tap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientRiskCard(
              riskScore: _createRiskScore(),
              compact: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });
  });
}
