@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/model_metrics_repository.dart';
import 'package:the_scheduler/data/repositories/prediction_outcomes_repository.dart';
import 'package:the_scheduler/ai/monitoring/retrain_trigger.dart';
import 'package:the_scheduler/ai/monitoring/drift_detector.dart';
import 'package:the_scheduler/ai/monitoring/model_performance_service.dart';
import 'package:the_scheduler/ai/models/model_performance_snapshot.dart';
import 'package:the_scheduler/data/models/user_role.dart';

@GenerateMocks([
  ModelPerformanceService,
  DriftDetector,
  PredictionOutcomesRepository,
  ModelMetricsRepository,
])
import 'retrain_trigger_test.mocks.dart';

void main() {
  late RetrainTrigger trigger;
  late MockModelPerformanceService mockPerformanceService;
  late MockDriftDetector mockDriftDetector;
  late MockPredictionOutcomesRepository mockOutcomesRepo;
  late MockModelMetricsRepository mockMetricsRepo;
  late SecurityContext testContext;

  setUp(() {
    mockPerformanceService = MockModelPerformanceService();
    mockDriftDetector = MockDriftDetector();
    mockOutcomesRepo = MockPredictionOutcomesRepository();
    mockMetricsRepo = MockModelMetricsRepository();

    trigger = RetrainTrigger(
      performanceService: mockPerformanceService,
      driftDetector: mockDriftDetector,
      outcomesRepository: mockOutcomesRepo,
      metricsRepository: mockMetricsRepo,
    );

    testContext = const SecurityContext(
      userId: 'test-user',
      businessId: 'test-business',
      role: UserRole.admin,
    );
  });

  group('RetrainTrigger', () {
    group('evaluateRetraining', () {
      test('returns no retrain when all metrics are healthy', () async {
        _setupHealthyMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
          lastRetrainDate: DateTime.now().subtract(const Duration(days: 10)),
        );

        expect(result.shouldRetrain, isFalse);
        expect(result.reasons, isEmpty);
      });

      test('returns lowAuc reason when AUC below threshold', () async {
        _setupLowAucMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.lowAuc));
      });

      test('returns highCalibrationError reason when calibration is poor', () async {
        _setupHighCalibrationMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.highCalibrationError));
      });

      test('returns driftDetected reason when drift found', () async {
        _setupDriftMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.driftDetected));
      });

      test('returns newDataAccumulated reason when enough new data', () async {
        _setupNewDataMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.newDataAccumulated));
      });

      test('returns scheduledInterval reason after 30 days', () async {
        _setupHealthyMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
          lastRetrainDate: DateTime.now().subtract(const Duration(days: 35)),
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.scheduledInterval));
      });

      test('handles errors gracefully', () async {
        when(mockMetricsRepo.getThresholds(any))
            .thenThrow(Exception('Database error'));

        final result = await trigger.evaluateRetraining(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isFalse);
        expect(result.error, isNotNull);
        expect(result.error, contains('Database error'));
      });
    });

    group('triggerIfNeeded', () {
      test('does not trigger when no retrain needed', () async {
        _setupHealthyMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.triggerIfNeeded(
          context: testContext,
          modelVersion: 'v1.0',
          lastRetrainDate: DateTime.now().subtract(const Duration(days: 10)),
        );

        expect(result.retrainRequested, isFalse);
      });

      test('triggers when force_retrain is true', () async {
        _setupHealthyMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.triggerIfNeeded(
          context: testContext,
          modelVersion: 'v1.0',
          forceRetrain: true,
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.manualTrigger));
        expect(result.retrainRequested, isTrue);
      });
    });

    group('manualTrigger', () {
      test('always triggers with manualTrigger reason', () async {
        _setupHealthyMocks(
          mockPerformanceService,
          mockDriftDetector,
          mockOutcomesRepo,
          mockMetricsRepo,
        );

        final result = await trigger.manualTrigger(
          context: testContext,
          modelVersion: 'v1.0',
        );

        expect(result.shouldRetrain, isTrue);
        expect(result.reasons, contains(RetrainReason.manualTrigger));
        expect(result.retrainRequested, isTrue);
      });
    });

    group('RetrainReason', () {
      test('displayName returns human-readable names', () {
        expect(RetrainReason.lowAuc.displayName, equals('Low AUC'));
        expect(RetrainReason.highCalibrationError.displayName,
            equals('High Calibration Error'));
        expect(RetrainReason.driftDetected.displayName, equals('Drift Detected'));
        expect(RetrainReason.newDataAccumulated.displayName,
            equals('New Data Available'));
        expect(RetrainReason.scheduledInterval.displayName,
            equals('Scheduled Interval'));
        expect(RetrainReason.manualTrigger.displayName, equals('Manual Trigger'));
      });

      test('description returns descriptive text', () {
        expect(RetrainReason.lowAuc.description, contains('AUC-ROC'));
        expect(RetrainReason.driftDetected.description, contains('drift'));
        expect(RetrainReason.manualTrigger.description, contains('Administrator'));
      });
    });

    group('RetrainTriggerResult', () {
      test('summaryText returns appropriate message when no retrain needed', () {
        final result = RetrainTriggerResult(
          shouldRetrain: false,
          reasons: [],
          newOutcomesCount: 50,
          evaluatedAt: DateTime.now(),
        );

        expect(result.summaryText, equals('No retraining needed'));
      });

      test('summaryText includes error when present', () {
        final result = RetrainTriggerResult(
          shouldRetrain: true,
          reasons: [],
          newOutcomesCount: 0,
          evaluatedAt: DateTime.now(),
          error: 'Test error',
        );

        expect(result.summaryText, contains('Test error'));
      });

      test('summaryText shows job ID when retrain requested', () {
        final result = RetrainTriggerResult(
          shouldRetrain: true,
          reasons: [RetrainReason.lowAuc],
          newOutcomesCount: 100,
          evaluatedAt: DateTime.now(),
          retrainRequested: true,
          retrainJobId: 'job-123',
        );

        expect(result.summaryText, contains('job-123'));
      });

      test('summaryText lists reasons when retrain recommended', () {
        final result = RetrainTriggerResult(
          shouldRetrain: true,
          reasons: [RetrainReason.lowAuc, RetrainReason.driftDetected],
          newOutcomesCount: 100,
          evaluatedAt: DateTime.now(),
        );

        expect(result.summaryText, contains('Low AUC'));
        expect(result.summaryText, contains('Drift Detected'));
      });
    });
  });
}

void _setupHealthyMocks(
  MockModelPerformanceService mockPerformanceService,
  MockDriftDetector mockDriftDetector,
  MockPredictionOutcomesRepository mockOutcomesRepo,
  MockModelMetricsRepository mockMetricsRepo,
) {
  when(mockMetricsRepo.getThresholds(any))
      .thenAnswer((_) async => const MonitoringThresholds());

  when(mockPerformanceService.calculateRollingMetrics(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => ModelPerformanceSnapshot(
        id: 'snapshot-1',
        businessId: 'test-business',
        modelVersion: 'v1.0',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        createdAt: DateTime.now(),
        sampleSize: 100,
        aucRoc: 0.85,
        precisionAt50: 0.80,
        recallAt50: 0.75,
        f1At50: 0.77,
        brierScore: 0.15,
        calibrationError: 0.05,
        status: PerformanceStatus.healthy,
      ));

  when(mockDriftDetector.detectDrift(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0.5,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: 100,
        analysisDate: DateTime.now(),
      ));

  when(mockOutcomesRepo.countEvaluableOutcomes(
    any,
    since: anyNamed('since'),
  )).thenAnswer((_) async => 500);
}

void _setupLowAucMocks(
  MockModelPerformanceService mockPerformanceService,
  MockDriftDetector mockDriftDetector,
  MockPredictionOutcomesRepository mockOutcomesRepo,
  MockModelMetricsRepository mockMetricsRepo,
) {
  when(mockMetricsRepo.getThresholds(any))
      .thenAnswer((_) async => const MonitoringThresholds(minAuc: 0.75));

  when(mockPerformanceService.calculateRollingMetrics(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => ModelPerformanceSnapshot(
        id: 'snapshot-1',
        businessId: 'test-business',
        modelVersion: 'v1.0',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        createdAt: DateTime.now(),
        sampleSize: 100,
        aucRoc: 0.65, // Below threshold
        precisionAt50: 0.60,
        recallAt50: 0.55,
        f1At50: 0.57,
        brierScore: 0.25,
        calibrationError: 0.08,
        status: PerformanceStatus.critical,
      ));

  when(mockDriftDetector.detectDrift(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0.5,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: 100,
        analysisDate: DateTime.now(),
      ));

  when(mockOutcomesRepo.countEvaluableOutcomes(
    any,
    since: anyNamed('since'),
  )).thenAnswer((_) async => 500);
}

void _setupHighCalibrationMocks(
  MockModelPerformanceService mockPerformanceService,
  MockDriftDetector mockDriftDetector,
  MockPredictionOutcomesRepository mockOutcomesRepo,
  MockModelMetricsRepository mockMetricsRepo,
) {
  when(mockMetricsRepo.getThresholds(any))
      .thenAnswer((_) async => const MonitoringThresholds(maxCalibrationError: 0.10));

  when(mockPerformanceService.calculateRollingMetrics(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => ModelPerformanceSnapshot(
        id: 'snapshot-1',
        businessId: 'test-business',
        modelVersion: 'v1.0',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        createdAt: DateTime.now(),
        sampleSize: 100,
        aucRoc: 0.80,
        precisionAt50: 0.75,
        recallAt50: 0.70,
        f1At50: 0.72,
        brierScore: 0.20,
        calibrationError: 0.15, // Above threshold
        status: PerformanceStatus.critical,
      ));

  when(mockDriftDetector.detectDrift(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0.5,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: 100,
        analysisDate: DateTime.now(),
      ));

  when(mockOutcomesRepo.countEvaluableOutcomes(
    any,
    since: anyNamed('since'),
  )).thenAnswer((_) async => 500);
}

void _setupDriftMocks(
  MockModelPerformanceService mockPerformanceService,
  MockDriftDetector mockDriftDetector,
  MockPredictionOutcomesRepository mockOutcomesRepo,
  MockModelMetricsRepository mockMetricsRepo,
) {
  when(mockMetricsRepo.getThresholds(any))
      .thenAnswer((_) async => const MonitoringThresholds(driftThreshold: 2.0));

  when(mockPerformanceService.calculateRollingMetrics(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => ModelPerformanceSnapshot(
        id: 'snapshot-1',
        businessId: 'test-business',
        modelVersion: 'v1.0',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        createdAt: DateTime.now(),
        sampleSize: 100,
        aucRoc: 0.80,
        precisionAt50: 0.75,
        recallAt50: 0.70,
        f1At50: 0.72,
        brierScore: 0.18,
        calibrationError: 0.07,
        status: PerformanceStatus.healthy,
      ));

  when(mockDriftDetector.detectDrift(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => DriftAnalysis(
        hasDrift: true,
        driftType: DriftType.dataDrift,
        overallScore: 3.5, // Above threshold
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: ['feature_a', 'feature_b'],
        sampleSize: 100,
        analysisDate: DateTime.now(),
      ));

  when(mockOutcomesRepo.countEvaluableOutcomes(
    any,
    since: anyNamed('since'),
  )).thenAnswer((_) async => 500);
}

void _setupNewDataMocks(
  MockModelPerformanceService mockPerformanceService,
  MockDriftDetector mockDriftDetector,
  MockPredictionOutcomesRepository mockOutcomesRepo,
  MockModelMetricsRepository mockMetricsRepo,
) {
  when(mockMetricsRepo.getThresholds(any))
      .thenAnswer((_) async => const MonitoringThresholds(minOutcomesForRetraining: 1000));

  when(mockPerformanceService.calculateRollingMetrics(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => ModelPerformanceSnapshot(
        id: 'snapshot-1',
        businessId: 'test-business',
        modelVersion: 'v1.0',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now(),
        createdAt: DateTime.now(),
        sampleSize: 100,
        aucRoc: 0.85,
        precisionAt50: 0.80,
        recallAt50: 0.75,
        f1At50: 0.77,
        brierScore: 0.15,
        calibrationError: 0.05,
        status: PerformanceStatus.healthy,
      ));

  when(mockDriftDetector.detectDrift(
    context: anyNamed('context'),
    modelVersion: anyNamed('modelVersion'),
  )).thenAnswer((_) async => DriftAnalysis(
        hasDrift: false,
        driftType: DriftType.none,
        overallScore: 0.5,
        dataDrift: null,
        conceptDrift: null,
        driftedFeatures: [],
        sampleSize: 100,
        analysisDate: DateTime.now(),
      ));

  when(mockOutcomesRepo.countEvaluableOutcomes(
    any,
    since: anyNamed('since'),
  )).thenAnswer((_) async => 1500); // Above threshold
}
