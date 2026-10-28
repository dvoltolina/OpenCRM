@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/data/repositories/model_metrics_repository.dart';
import 'package:the_scheduler/data/repositories/prediction_outcomes_repository.dart';
import 'package:the_scheduler/ai/monitoring/model_performance_service.dart';
import 'package:the_scheduler/ai/models/model_performance_snapshot.dart';
import 'package:the_scheduler/ai/models/prediction_outcome.dart';

@GenerateMocks([PredictionOutcomesRepository, ModelMetricsRepository])
import 'model_performance_service_test.mocks.dart';

void main() {
  late ModelPerformanceService service;
  late MockPredictionOutcomesRepository mockOutcomesRepo;
  late MockModelMetricsRepository mockMetricsRepo;
  late SecurityContext testContext;

  setUp(() {
    mockOutcomesRepo = MockPredictionOutcomesRepository();
    mockMetricsRepo = MockModelMetricsRepository();

    service = ModelPerformanceService(
      outcomesRepository: mockOutcomesRepo,
      metricsRepository: mockMetricsRepo,
    );

    testContext = const SecurityContext(
      userId: 'test-user',
      businessId: 'test-business',
      role: UserRole.admin,
    );
  });

  group('ModelPerformanceService', () {
    group('calculateMetrics', () {
      test('returns null when no outcomes available', () async {
        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => []);

        final result = await service.calculateMetrics(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          modelVersion: 'v1.0',
        );

        expect(result, isNull);
      });

      test('calculates metrics with evaluable outcomes', () async {
        final outcomes = _generateTestOutcomes(100);

        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        when(mockMetricsRepo.getThresholds(any))
            .thenAnswer((_) async => const MonitoringThresholds());

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await service.calculateMetrics(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          modelVersion: 'v1.0',
        );

        expect(result, isNotNull);
        expect(result!.sampleSize, equals(100));
        expect(result.aucRoc, greaterThan(0.0));
        expect(result.aucRoc, lessThanOrEqualTo(1.0));
        expect(result.calibrationError, greaterThanOrEqualTo(0.0));
      });

      test('determines healthy status when metrics are good', () async {
        // Generate outcomes with good predictions
        final outcomes = _generateGoodPredictions(100);

        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        when(mockMetricsRepo.getThresholds(any))
            .thenAnswer((_) async => const MonitoringThresholds());

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await service.calculateMetrics(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          modelVersion: 'v1.0',
        );

        expect(result, isNotNull);
        expect(result!.status, equals(PerformanceStatus.healthy));
        expect(result.aucRoc, greaterThan(0.75));
      });

      test('determines critical status when AUC is low', () async {
        // Generate outcomes with random (poor) predictions
        final outcomes = _generateRandomPredictions(100);

        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        when(mockMetricsRepo.getThresholds(any))
            .thenAnswer((_) async => const MonitoringThresholds(minAuc: 0.75));

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await service.calculateMetrics(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          modelVersion: 'v1.0',
        );

        expect(result, isNotNull);
        // Random predictions should result in AUC around 0.5
        expect(result!.aucRoc, lessThan(0.75));
      });

      test('generates alerts when metrics below thresholds', () async {
        final outcomes = _generateRandomPredictions(100);

        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        when(mockMetricsRepo.getThresholds(any)).thenAnswer(
            (_) async => const MonitoringThresholds(minAuc: 0.90));

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await service.calculateMetrics(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          modelVersion: 'v1.0',
        );

        expect(result, isNotNull);
        expect(result!.alerts, isNotEmpty);
        expect(result.alerts.any((a) => a.contains('AUC')), isTrue);
      });
    });

    group('calculateRollingMetrics', () {
      test('uses correct date range', () async {
        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => []);

        await service.calculateRollingMetrics(
          context: testContext,
          days: 14,
          modelVersion: 'v1.0',
        );

        final captured = verify(mockOutcomesRepo.getEvaluableOutcomes(
          context: captureAnyNamed('context'),
          startDate: captureAnyNamed('startDate'),
          endDate: captureAnyNamed('endDate'),
          modelVersion: captureAnyNamed('modelVersion'),
        )).captured;

        final startDate = captured[1] as DateTime;
        final endDate = captured[2] as DateTime;

        final daysDiff = endDate.difference(startDate).inDays;
        expect(daysDiff, equals(14));
      });
    });

    group('compareWithBaseline', () {
      test('returns null when no baseline exists', () async {
        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => null);

        final result = await service.compareWithBaseline(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result, isNull);
      });

      test('calculates comparison when baseline exists', () async {
        final baseline = ModelBaselineMetrics(
          modelVersion: 'v1.0',
          establishedAt: DateTime.now(),
          trainingSampleSize: 1000,
          aucRoc: 0.85,
          precision: 0.80,
          recall: 0.75,
          f1: 0.77,
          brierScore: 0.12,
          calibrationError: 0.05,
          featureImportances: {},
          featureStats: {},
        );

        when(mockMetricsRepo.getBaseline(any, any))
            .thenAnswer((_) async => baseline);

        final outcomes = _generateGoodPredictions(100);

        when(mockOutcomesRepo.getEvaluableOutcomes(
          context: anyNamed('context'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          modelVersion: anyNamed('modelVersion'),
        )).thenAnswer((_) async => outcomes);

        when(mockMetricsRepo.getThresholds(any))
            .thenAnswer((_) async => const MonitoringThresholds());

        final result = await service.compareWithBaseline(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result, isNotNull);
        expect(result!.baseline, equals(baseline));
        expect(result.aucChange, isNotNull);
        expect(result.aucPercentChange, isNotNull);
      });
    });
  });
}

/// Generate test outcomes with varying predictions.
List<PredictionOutcome> _generateTestOutcomes(int count) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 5 == 0; // 20% no-show rate
    final probability = isNoShow ? 0.7 + (i % 10) / 50 : 0.2 + (i % 10) / 50;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability,
      predictedRiskLevel: probability > 0.5 ? 'high' : 'low',
      modelVersion: 'v1.0',
      confidence: 0.85,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      predictionCorrect: (probability > 0.5) == isNoShow,
    ));
  }

  return outcomes;
}

/// Generate outcomes with good predictions (high AUC).
List<PredictionOutcome> _generateGoodPredictions(int count) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 5 == 0;
    // Good predictions: high prob for no-shows, low for attended
    final probability = isNoShow ? 0.85 : 0.15;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability,
      predictedRiskLevel: probability > 0.5 ? 'high' : 'low',
      modelVersion: 'v1.0',
      confidence: 0.90,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      predictionCorrect: true,
    ));
  }

  return outcomes;
}

/// Generate outcomes with random predictions (low AUC).
List<PredictionOutcome> _generateRandomPredictions(int count) {
  final outcomes = <PredictionOutcome>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    final isNoShow = i % 5 == 0;
    // Random predictions: unrelated to actual outcome
    final probability = (i * 17 % 100) / 100.0;

    outcomes.add(PredictionOutcome(
      id: 'outcome_$i',
      businessId: 'test-business',
      appointmentId: 'apt_$i',
      clientId: 'client_$i',
      predictedProbability: probability,
      predictedRiskLevel: probability > 0.5 ? 'high' : 'low',
      modelVersion: 'v1.0',
      confidence: 0.50,
      predictedAt: now.subtract(Duration(days: i % 7)),
      appointmentTime: now.subtract(Duration(days: i % 7)),
      outcome: isNoShow ? AppointmentOutcome.noshow : AppointmentOutcome.attended,
      outcomeRecordedAt: now,
      predictionCorrect: (probability > 0.5) == isNoShow,
    ));
  }

  return outcomes;
}
