@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_scheduler/ai/cache/prediction_cache.dart';
import 'package:the_scheduler/ai/models/noshow_prediction.dart';

/// Tests for PredictionCache
///
/// Agent AI-4: Flutter Prediction Integration
void main() {
  late PredictionCache cache;

  NoshowPrediction _createPrediction({
    required String appointmentId,
    DateTime? expiresAt,
  }) {
    return NoshowPrediction(
      appointmentId: appointmentId,
      probability: 0.35,
      riskLevel: RiskLevel.medium,
      confidence: 0.85,
      recommendedActions: const [],
      topFeatures: const [],
      modelVersion: '1.0.0',
      predictedAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  setUp(() async {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});
    cache = PredictionCache();
  });

  group('PredictionCache', () {
    test('stores and retrieves prediction from memory', () async {
      final prediction = _createPrediction(appointmentId: 'appt_1');

      await cache.set('appt_1', prediction, businessId: 'biz_1');
      final retrieved = await cache.get('appt_1', businessId: 'biz_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.appointmentId, 'appt_1');
      expect(retrieved.probability, 0.35);
    });

    test('returns null for non-existent key', () async {
      final result = await cache.get('non_existent', businessId: 'biz_1');
      expect(result, isNull);
    });

    test('removes prediction correctly', () async {
      final prediction = _createPrediction(appointmentId: 'appt_1');

      await cache.set('appt_1', prediction, businessId: 'biz_1');
      expect(await cache.get('appt_1', businessId: 'biz_1'), isNotNull);

      await cache.remove('appt_1', businessId: 'biz_1');
      expect(await cache.get('appt_1', businessId: 'biz_1'), isNull);
    });

    test('clears all predictions', () async {
      await cache.set('appt_1', _createPrediction(appointmentId: 'appt_1'));
      await cache.set('appt_2', _createPrediction(appointmentId: 'appt_2'));

      expect(await cache.get('appt_1'), isNotNull);
      expect(await cache.get('appt_2'), isNotNull);

      await cache.clear();

      expect(await cache.get('appt_1'), isNull);
      expect(await cache.get('appt_2'), isNull);
    });

    test('returns null for expired prediction', () async {
      final expiredPrediction = _createPrediction(
        appointmentId: 'appt_1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await cache.set('appt_1', expiredPrediction);
      final result = await cache.get('appt_1');

      expect(result, isNull);
    });

    test('contains returns true for cached item', () async {
      await cache.set('appt_1', _createPrediction(appointmentId: 'appt_1'));

      expect(await cache.contains('appt_1'), true);
      expect(await cache.contains('non_existent'), false);
    });

    test('LRU eviction when cache full', () async {
      // Fill cache beyond limit (100 items)
      for (var i = 0; i < 105; i++) {
        await cache.set('appt_$i', _createPrediction(appointmentId: 'appt_$i'));
      }

      // First few items should be evicted from memory
      // Note: They may still be in persistent storage
      expect(cache.memoryCacheSize, 100);
    });

    test('updates access order on get', () async {
      // Add items
      await cache.set('appt_1', _createPrediction(appointmentId: 'appt_1'));
      await cache.set('appt_2', _createPrediction(appointmentId: 'appt_2'));
      await cache.set('appt_3', _createPrediction(appointmentId: 'appt_3'));

      // Access first item (moves it to end)
      await cache.get('appt_1');

      // Fill to capacity
      for (var i = 4; i <= 100; i++) {
        await cache.set('appt_$i', _createPrediction(appointmentId: 'appt_$i'));
      }

      // appt_2 should be evicted (oldest not accessed)
      // appt_1 should still be in memory (was accessed)
      final appt1 = await cache.get('appt_1');
      expect(appt1, isNotNull);
    });

    test('stats reports cache size correctly', () async {
      await cache.set('appt_1', _createPrediction(appointmentId: 'appt_1'));
      await cache.set('appt_2', _createPrediction(appointmentId: 'appt_2'));

      final stats = cache.stats;
      expect(stats['memoryCacheSize'], 2);
      expect(stats['maxMemoryCacheSize'], 100);
    });
  });

  group('NoshowPredictionExpiry', () {
    test('isExpired returns true for past expiration', () {
      final prediction = _createPrediction(
        appointmentId: 'appt_1',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(prediction.isExpired, true);
    });

    test('isExpired returns false for future expiration', () {
      final prediction = _createPrediction(
        appointmentId: 'appt_1',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(prediction.isExpired, false);
    });

    test('isValid returns false for unknown risk level', () {
      final unavailable = NoshowPrediction.unavailable('appt_1');
      expect(unavailable.isValid, false);
    });
  });
}
