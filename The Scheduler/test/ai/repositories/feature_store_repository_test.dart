@Tags(['ai'])
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/user_role.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';
import 'package:the_scheduler/ai/models/prediction_features.dart';
import 'package:the_scheduler/ai/repositories/feature_store_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FeatureStoreRepository repository;
  late SecurityContext testContext;
  late SecurityContext otherBusinessContext;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FeatureStoreRepository(firestore: fakeFirestore);

    testContext = SecurityContext(
      userId: 'test-user-id',
      businessId: 'test-business-id',
      role: UserRole.admin,
    );

    otherBusinessContext = SecurityContext(
      userId: 'other-user-id',
      businessId: 'other-business-id',
      role: UserRole.admin,
    );
  });

  PredictionFeatures createTestFeatures({
    String appointmentId = 'apt-1',
    String businessId = 'test-business-id',
    double noshowRate = 0.2,
  }) {
    return PredictionFeatures(
      appointmentId: appointmentId,
      businessId: businessId,
      extractedAt: DateTime.now(),
      featureSchemaVersion: kFeatureSchemaVersion,
      clientHistoricalNoshowRate: noshowRate,
      clientHistoricalCancelRate: 0.1,
      clientTotalAppointments: 10,
      clientDaysSinceLastVisit: 30,
      clientLifetimeValueCents: 50000,
      clientLifecycleStage: 'active',
      clientHasPaymentMethod: true,
      bookingLeadDays: 7,
      dayOfWeek: 1,
      hourOfDay: 10,
      isRecurring: false,
      isGroupSession: false,
      serviceDurationMinutes: 60,
      servicePriceCents: 10000,
      requiresPayment: true,
      paymentCollected: true,
      hasIntakeForm: false,
      providerHistoricalNoshowRate: 0.1,
      providerTotalAppointments: 100,
      slotHistoricalNoshowRate: 0.15,
      isFirstAppointmentOfDay: true,
      isLastAppointmentOfDay: false,
    );
  }

  NoshowPrediction createTestPrediction({
    String appointmentId = 'apt-1',
    double probability = 0.3,
  }) {
    return NoshowPrediction(
      appointmentId: appointmentId,
      probability: probability,
      riskLevel: probability >= 0.7
          ? RiskLevel.high
          : probability >= 0.4
              ? RiskLevel.medium
              : RiskLevel.low,
      confidence: 0.85,
      recommendedActions: const [
        RecommendedAction(
          actionId: 'action-1',
          title: 'Send reminder',
          description: 'Send an extra reminder to reduce no-show risk',
          priority: ActionPriority.high,
          automatable: true,
          estimatedImpact: 0.1,
        ),
      ],
      topFeatures: [
        const FeatureImportance(
          featureName: 'clientHistoricalNoshowRate',
          featureDisplayName: 'Past No-Show Rate',
          importance: 0.35,
          featureValue: 0.2,
          impact: 'increases_risk',
        ),
      ],
      modelVersion: '1.0.0',
      predictedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  group('FeatureStoreRepository', () {
    group('Store features', () {
      test('stores feature set successfully', () async {
        final features = createTestFeatures();

        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        expect(featureId, isNotEmpty);

        // Verify stored in Firestore
        final doc = await fakeFirestore
            .collection('businesses')
            .doc(testContext.businessId)
            .collection('featureStore')
            .doc(featureId)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['appointmentId'], equals('apt-1'));
      });

      test('stores features in bulk', () async {
        final features1 = createTestFeatures(appointmentId: 'apt-1');
        final features2 = createTestFeatures(appointmentId: 'apt-2');
        final features3 = createTestFeatures(appointmentId: 'apt-3');

        final ids = await repository.storeFeaturesBatch(
          context: testContext,
          featuresList: [features1, features2, features3],
        );

        expect(ids.length, equals(3));

        // Verify all stored
        for (final id in ids) {
          final doc = await fakeFirestore
              .collection('businesses')
              .doc(testContext.businessId)
              .collection('featureStore')
              .doc(id)
              .get();
          expect(doc.exists, isTrue);
        }
      });

      test('returns empty list for empty batch', () async {
        final ids = await repository.storeFeaturesBatch(
          context: testContext,
          featuresList: [],
        );

        expect(ids, isEmpty);
      });
    });

    group('Retrieve features', () {
      test('retrieves feature set by appointment ID', () async {
        final features = createTestFeatures(appointmentId: 'apt-lookup');

        await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        final record = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'apt-lookup',
        );

        expect(record, isNotNull);
        expect(record!.appointmentId, equals('apt-lookup'));
        expect(record.features.clientHistoricalNoshowRate, equals(0.2));
      });

      test('returns null for non-existent appointment', () async {
        final record = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'non-existent',
        );

        expect(record, isNull);
      });

      test('retrieves feature set by feature ID', () async {
        final features = createTestFeatures();

        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        final record = await repository.getFeaturesById(
          context: testContext,
          featureId: featureId,
        );

        expect(record, isNotNull);
        expect(record!.id, equals(featureId));
      });
    });

    group('Link prediction', () {
      test('links prediction to stored features', () async {
        final features = createTestFeatures();
        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        final prediction = createTestPrediction();

        await repository.linkPrediction(
          context: testContext,
          featureId: featureId,
          prediction: prediction,
        );

        final record = await repository.getFeaturesById(
          context: testContext,
          featureId: featureId,
        );

        expect(record!.prediction, isNotNull);
        expect(record.prediction!.probability, equals(0.3));
        expect(record.prediction!.riskLevel, equals(RiskLevel.low));
      });
    });

    group('Update outcome', () {
      test('updates actual outcome after appointment', () async {
        final features = createTestFeatures(appointmentId: 'apt-outcome');

        await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-outcome',
          outcome: AppointmentOutcome.show,
        );

        final record = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'apt-outcome',
        );

        expect(record!.actualOutcome, equals(AppointmentOutcome.show));
      });

      test('updates outcome to noshow', () async {
        final features = createTestFeatures(appointmentId: 'apt-noshow');

        await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-noshow',
          outcome: AppointmentOutcome.noshow,
        );

        final record = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'apt-noshow',
        );

        expect(record!.actualOutcome, equals(AppointmentOutcome.noshow));
      });

      test('updates outcome to cancelled', () async {
        final features = createTestFeatures(appointmentId: 'apt-cancel');

        await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-cancel',
          outcome: AppointmentOutcome.cancelled,
        );

        final record = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'apt-cancel',
        );

        expect(record!.actualOutcome, equals(AppointmentOutcome.cancelled));
      });

      test('does nothing for non-existent appointment', () async {
        // Should not throw
        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'non-existent',
          outcome: AppointmentOutcome.show,
        );
      });
    });

    group('Query by date range', () {
      test('queries features by date range', () async {
        final now = DateTime.now();
        final features1 = createTestFeatures(appointmentId: 'apt-1');
        final features2 = createTestFeatures(appointmentId: 'apt-2');

        await repository.storeFeatures(context: testContext, features: features1);
        await repository.storeFeatures(context: testContext, features: features2);

        final records = await repository.queryFeaturesByDateRange(
          context: testContext,
          startDate: now.subtract(const Duration(hours: 1)),
          endDate: now.add(const Duration(hours: 1)),
        );

        expect(records.length, equals(2));
      });

      test('respects limit parameter', () async {
        final features1 = createTestFeatures(appointmentId: 'apt-1');
        final features2 = createTestFeatures(appointmentId: 'apt-2');
        final features3 = createTestFeatures(appointmentId: 'apt-3');

        await repository.storeFeatures(context: testContext, features: features1);
        await repository.storeFeatures(context: testContext, features: features2);
        await repository.storeFeatures(context: testContext, features: features3);

        final records = await repository.queryFeaturesByDateRange(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(hours: 1)),
          endDate: DateTime.now().add(const Duration(hours: 1)),
          limit: 2,
        );

        expect(records.length, equals(2));
      });

      test('filters for outcomes only when requested', () async {
        final features1 = createTestFeatures(appointmentId: 'apt-with-outcome');
        final features2 = createTestFeatures(appointmentId: 'apt-no-outcome');

        await repository.storeFeatures(context: testContext, features: features1);
        await repository.storeFeatures(context: testContext, features: features2);

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-with-outcome',
          outcome: AppointmentOutcome.show,
        );

        final recordsWithOutcomes = await repository.queryFeaturesByDateRange(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(hours: 1)),
          endDate: DateTime.now().add(const Duration(hours: 1)),
          withOutcomesOnly: true,
        );

        expect(recordsWithOutcomes.length, equals(1));
        expect(recordsWithOutcomes.first.appointmentId, equals('apt-with-outcome'));
      });
    });

    group('Training data export', () {
      test('exports training data with outcomes', () async {
        final features = createTestFeatures(appointmentId: 'apt-train');
        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        final prediction = createTestPrediction(appointmentId: 'apt-train');
        await repository.linkPrediction(
          context: testContext,
          featureId: featureId,
          prediction: prediction,
        );

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-train',
          outcome: AppointmentOutcome.noshow,
        );

        final exportData = await repository.exportTrainingData(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(hours: 1)),
          endDate: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(exportData.length, equals(1));
        expect(exportData.first['isNoShow'], equals(1));
        expect(exportData.first['predictionProbability'], equals(0.3));
        expect(exportData.first['appointmentId'], equals('apt-train'));
      });
    });

    group('Multi-tenant isolation', () {
      test('cannot access features from other business', () async {
        final features = createTestFeatures(businessId: 'test-business-id');

        await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        // Try to access from other business context
        final record = await repository.getFeaturesByAppointmentId(
          context: otherBusinessContext,
          appointmentId: 'apt-1',
        );

        expect(record, isNull);
      });

      test('query returns only own business features', () async {
        final features1 = createTestFeatures(
          appointmentId: 'apt-business-1',
          businessId: 'test-business-id',
        );
        final features2 = createTestFeatures(
          appointmentId: 'apt-business-2',
          businessId: 'other-business-id',
        );

        await repository.storeFeatures(context: testContext, features: features1);
        await repository.storeFeatures(context: otherBusinessContext, features: features2);

        final records = await repository.queryFeaturesByDateRange(
          context: testContext,
          startDate: DateTime.now().subtract(const Duration(hours: 1)),
          endDate: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(records.length, equals(1));
        expect(records.first.appointmentId, equals('apt-business-1'));
      });
    });

    group('TTL cleanup', () {
      test('deletes old features', () async {
        // Store features with old timestamp
        final oldFeatureId = 'old-feature-id';
        await fakeFirestore
            .collection('businesses')
            .doc(testContext.businessId)
            .collection('featureStore')
            .doc(oldFeatureId)
            .set({
          'appointmentId': 'apt-old',
          'features': createTestFeatures().toJson(),
          'extractedAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 400)),
          ),
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 400)),
          ),
          'featureSchemaVersion': kFeatureSchemaVersion,
        });

        // Store recent features
        await repository.storeFeatures(
          context: testContext,
          features: createTestFeatures(appointmentId: 'apt-recent'),
        );

        final deletedCount = await repository.cleanupOldFeatures(
          context: testContext,
        );

        expect(deletedCount, equals(1));

        // Verify old one is deleted
        final oldDoc = await fakeFirestore
            .collection('businesses')
            .doc(testContext.businessId)
            .collection('featureStore')
            .doc(oldFeatureId)
            .get();
        expect(oldDoc.exists, isFalse);

        // Verify recent one still exists
        final recentRecord = await repository.getFeaturesByAppointmentId(
          context: testContext,
          appointmentId: 'apt-recent',
        );
        expect(recentRecord, isNotNull);
      });
    });

    group('Statistics', () {
      test('returns correct stats', () async {
        final features1 = createTestFeatures(appointmentId: 'apt-1');
        final features2 = createTestFeatures(appointmentId: 'apt-2');

        final featureId1 = await repository.storeFeatures(
          context: testContext,
          features: features1,
        );
        await repository.storeFeatures(context: testContext, features: features2);

        // Add prediction to first
        await repository.linkPrediction(
          context: testContext,
          featureId: featureId1,
          prediction: createTestPrediction(),
        );

        // Add outcome to first
        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-1',
          outcome: AppointmentOutcome.show,
        );

        final stats = await repository.getStats(context: testContext);

        expect(stats.totalRecords, equals(2));
        expect(stats.recordsWithOutcomes, equals(1));
        expect(stats.recordsWithPredictions, equals(1));
        expect(stats.lastExtractedAt, isNotNull);
      });
    });

    group('StoredFeatureRecord helpers', () {
      test('hasCompleteFeedbackLoop returns true when both present', () async {
        final features = createTestFeatures(appointmentId: 'apt-feedback');
        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        await repository.linkPrediction(
          context: testContext,
          featureId: featureId,
          prediction: createTestPrediction(),
        );

        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-feedback',
          outcome: AppointmentOutcome.show,
        );

        final record = await repository.getFeaturesById(
          context: testContext,
          featureId: featureId,
        );

        expect(record!.hasCompleteFeedbackLoop, isTrue);
      });

      test('predictionWasCorrect returns true for correct low risk prediction', () async {
        final features = createTestFeatures(appointmentId: 'apt-correct');
        final featureId = await repository.storeFeatures(
          context: testContext,
          features: features,
        );

        // Low risk prediction (probability 0.3)
        await repository.linkPrediction(
          context: testContext,
          featureId: featureId,
          prediction: createTestPrediction(probability: 0.3),
        );

        // Actual outcome: showed up
        await repository.updateActualOutcome(
          context: testContext,
          appointmentId: 'apt-correct',
          outcome: AppointmentOutcome.show,
        );

        final record = await repository.getFeaturesById(
          context: testContext,
          featureId: featureId,
        );

        expect(record!.predictionWasCorrect, isTrue);
      });
    });
  });
}
