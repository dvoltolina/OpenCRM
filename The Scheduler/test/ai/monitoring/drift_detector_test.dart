@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/model_metrics_repository.dart';
import 'package:the_scheduler/data/repositories/prediction_outcomes_repository.dart';
import 'package:the_scheduler/ai/monitoring/drift_detector.dart';
import 'package:the_scheduler/ai/models/model_performance_snapshot.dart';
import 'package:the_scheduler/ai/models/prediction_outcome.dart';
import 'package:the_scheduler/data/models/user_role.dart';

@GenerateMocks([PredictionOutcomesRepository, ModelMetricsRepository])
import 'drift_detector_test.mocks.dart';

void main() {
  late DriftDetector detector;
  late MockPredictionOutcomesRepository mockOutcomesRepo;
  late MockModelMetricsRepository mockMetricsRepo;
  late SecurityContext testContext;

  setUp(() {
    mockOutcomesRepo = MockPredictionOutcomesRepository();
    mockMetricsRepo = MockModelMetricsRepository();

    detector = DriftDetector(
      outcomesRepository: mockOutcomesRepo,
      metricsRepository: mockMetricsRepo,
    );

    testContext = const SecurityContext(
      userId: 'test-user',
      businessId: 'test-business',
      role: UserRole.admin,
    );
  });

  group('DriftDetector', () {
    group('detectDrift', () {
      test('returns noBaseline when no baseline exists', () async {
        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await detector.detectDrift(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.hasBaseline, isFalse);
        expect(result.hasDrift, isFalse);
        expect(result.driftType, equals(DriftType.none));
      });

      test('returns insufficientData when too few outcomes', () async {
        final baseline = _createBaseline();

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => baseline);

        when(mockOutcomesRepo.getOutcomesForPeriod(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => []);

        final result = await detector.detectDrift(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.hasBaseline, isTrue);
        expect(result.hasSufficientData, isFalse);
        expect(result.hasDrift, isFalse);
      });

      test('detects no drift when distributions match', () async {
        final baseline = _createBaseline(
          predictionMean: 0.30,
          predictionStdDev: 0.15,
        );

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => baseline);

        // Generate outcomes matching baseline distribution
        final outcomes = _generateOutcomesMatchingBaseline(100);

        when(mockOutcomesRepo.getOutcomesForPeriod(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        final result = await detector.detectDrift(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.hasBaseline, isTrue);
        expect(result.hasSufficientData, isTrue);
        expect(result.hasDrift, isFalse);
        expect(result.driftType, equals(DriftType.none));
      });

      test('detects data drift when mean shifts significantly', () async {
        final baseline = _createBaseline(
          predictionMean: 0.30,
          predictionStdDev: 0.10,
        );

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => baseline);

        // Generate outcomes with shifted mean (0.70 instead of 0.30)
        final outcomes = _generateOutcomesWithShiftedMean(100, 0.70);

        when(mockOutcomesRepo.getOutcomesForPeriod(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        final result = await detector.detectDrift(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.hasDrift, isTrue);
        expect(
          result.driftType,
          anyOf(equals(DriftType.dataDrift), equals(DriftType.both)),
        );
        expect(result.overallScore, greaterThan(2.0));
      });

      test('detects concept drift when accuracy degrades', () async {
        final baseline = _createBaseline(
          calibrationError: 0.05,
          precision: 0.85,
        );

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => baseline);

        // Generate outcomes with poor calibration
        final outcomes = _generatePoorlyCalibrated(100);

        when(mockOutcomesRepo.getOutcomesForPeriod(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        final result = await detector.detectDrift(
          context: testContext,
          modelVersion: 'v1.0',
        );

        // Concept drift detected due to calibration degradation
        expect(result.hasDrift, isTrue);
      });
    });

    group('DriftAnalysis', () {
      test('summaryText shows correct message for no baseline', () {
        final analysis = DriftAnalysis.noBaseline();
        expect(analysis.summaryText, contains('No baseline'));
      });

      test('summaryText shows correct message for insufficient data', () {
        final analysis = DriftAnalysis.insufficientData(20);
        expect(analysis.summaryText, contains('Insufficient'));
        expect(analysis.summaryText, contains('20'));
      });

      test('summaryText shows drift type when drift detected', () {
        final analysis = DriftAnalysis(
          hasDrift: true,
          driftType: DriftType.dataDrift,
          overallScore: 3.5,
          dataDrift: null,
          conceptDrift: null,
          driftedFeatures: ['feature_a'],
          sampleSize: 100,
          analysisDate: DateTime.now(),
        );

        expect(analysis.summaryText, contains('Data Drift'));
        expect(analysis.summaryText, contains('3.5'));
      });
    });

    group('DriftType', () {
      test('displayName returns human-readable names', () {
        expect(DriftType.none.displayName, equals('No Drift'));
        expect(DriftType.dataDrift.displayName, equals('Data Drift'));
        expect(DriftType.conceptDrift.displayName, equals('Concept Drift'));
        expect(DriftType.both.displayName, equals('Data & Concept Drift'));
      });
    });
  });
}

ModelBaselineMetrics _createBaseline({
  double predictionMean = 0.30,
  double predictionStdDev = 0.20,
  double calibrationError = 0.05,
  double precision = 0.80,
}) {
  return ModelBaselineMetrics(
    modelVersion: 'v1.0',
    establishedAt: DateTime.now(),
    trainingSampleSize: 1000,
    aucRoc: 0.85,
    precision: precision,
    recall: 0.75,
    f1: 0.77,
    brierScore: 0.12,
    calibrationError: calibrationError,
    featureImportances: {
      'feature_a': 0.3,
      'feature_b': 0.2,
    },
    featureStats: {
      'predicted_probability': FeatureStats(
        featureName: 'predicted_probability',
        mean: predictionMean,
        stdDev: predictionStdDev,
        min: 0.0,
        max: 1.0,
        sampleCount: 1000,
      ),
    },
  );
}

List<PredictionOutcome> _generateOutcomesMatchingBaseline(int count) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 5 == 0;
    // Predictions around baseline mean (0.30) with some variance
    final probability = 0.30 + ((i % 20) - 10) / 100;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability.clamp(0.0, 1.0),
      predictedRiskLevel: 'low',
      modelVersion: 'v1.0',
      confidence: 0.85,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      topFeatures: ['feature_a', 'feature_b'],
    ));
  }

  return outcomes;
}

List<PredictionOutcome> _generateOutcomesWithShiftedMean(int count, double newMean) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 3 == 0; // Higher no-show rate
    // Predictions around shifted mean
    final probability = newMean + ((i % 20) - 10) / 100;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability.clamp(0.0, 1.0),
      predictedRiskLevel: 'high',
      modelVersion: 'v1.0',
      confidence: 0.75,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      topFeatures: ['feature_c', 'feature_d'], // Different features
    ));
  }

  return outcomes;
}

List<PredictionOutcome> _generatePoorlyCalibrated(int count) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 5 == 0;
    // Poorly calibrated: always predicts high but actual rate is low
    final probability = 0.80;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability,
      predictedRiskLevel: 'high',
      modelVersion: 'v1.0',
      confidence: 0.90,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      topFeatures: ['feature_a'],
    ));
  }

  return outcomes;
}
