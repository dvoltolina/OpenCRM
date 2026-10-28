@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/models/demand_forecast.dart';

/// Tests for DemandForecastService and related models
///
/// Agent AI-21: Waitlist Intelligence & Demand Forecasting
void main() {
  group('DemandForecast', () {
    test('intervalWidth calculates correctly', () {
      final forecast = _createForecast(
        predictedCount: 20,
        lowerBound: 15,
        upperBound: 25,
      );

      expect(forecast.intervalWidth, 10);
    });

    test('relativeUncertainty calculates correctly', () {
      final forecast = _createForecast(
        predictedCount: 20,
        lowerBound: 15,
        upperBound: 25,
      );

      // (25 - 15) / 20 = 0.5
      expect(forecast.relativeUncertainty, 0.5);
    });

    test('relativeUncertainty handles zero prediction', () {
      final forecast = _createForecast(
        predictedCount: 0,
        lowerBound: 0,
        upperBound: 5,
      );

      expect(forecast.relativeUncertainty, 1.0);
    });

    test('predictedCountDisplay formats correctly', () {
      final forecast = _createForecast(predictedCount: 15.7);
      expect(forecast.predictedCountDisplay, '16');
    });

    test('intervalDisplay formats correctly', () {
      final forecast = _createForecast(
        lowerBound: 12.3,
        upperBound: 18.7,
      );

      expect(forecast.intervalDisplay, '12-19');
    });

    test('dayName returns correct value', () {
      final monday = _createForecast(dayOfWeek: 1);
      final friday = _createForecast(dayOfWeek: 5);
      final sunday = _createForecast(dayOfWeek: 7);

      expect(monday.dayName, 'Mon');
      expect(friday.dayName, 'Fri');
      expect(sunday.dayName, 'Sun');
    });

    test('isHighConfidence returns true for >= 0.7', () {
      final high = _createForecast(confidence: 0.8);
      final low = _createForecast(confidence: 0.6);

      expect(high.isHighConfidence, true);
      expect(low.isHighConfidence, false);
    });

    test('isLowConfidence returns true for < 0.5', () {
      final low = _createForecast(confidence: 0.4);
      final ok = _createForecast(confidence: 0.6);

      expect(low.isLowConfidence, true);
      expect(ok.isLowConfidence, false);
    });
  });

  group('DemandLevel', () {
    test('displayName returns correct values', () {
      expect(DemandLevel.veryLow.displayName, 'Very Low');
      expect(DemandLevel.low.displayName, 'Low');
      expect(DemandLevel.normal.displayName, 'Normal');
      expect(DemandLevel.high.displayName, 'High');
      expect(DemandLevel.veryHigh.displayName, 'Very High');
    });

    test('colorName returns correct values', () {
      expect(DemandLevel.veryLow.colorName, 'grey');
      expect(DemandLevel.low.colorName, 'blue');
      expect(DemandLevel.normal.colorName, 'green');
      expect(DemandLevel.high.colorName, 'orange');
      expect(DemandLevel.veryHigh.colorName, 'red');
    });
  });

  group('StaffingRecommendation', () {
    test('capacityGap calculates correctly', () {
      final understaffed = _createRecommendation(
        currentCapacity: 10,
        recommendedCapacity: 15,
      );
      final overstaffed = _createRecommendation(
        currentCapacity: 15,
        recommendedCapacity: 10,
      );

      expect(understaffed.capacityGap, 5);
      expect(overstaffed.capacityGap, -5);
    });

    test('isUrgent returns true for urgency >= 4', () {
      final urgent = _createRecommendation(urgency: 5);
      final notUrgent = _createRecommendation(urgency: 2);

      expect(urgent.isUrgent, true);
      expect(notUrgent.isUrgent, false);
    });

    test('capacityChangePercent calculates correctly', () {
      final rec = _createRecommendation(
        currentCapacity: 20,
        recommendedCapacity: 25,
      );

      // (25 - 20) / 20 * 100 = 25%
      expect(rec.capacityChangePercent, 25);
    });

    test('capacityChangePercent handles zero current', () {
      final rec = _createRecommendation(
        currentCapacity: 0,
        recommendedCapacity: 10,
      );

      expect(rec.capacityChangePercent, 0);
    });
  });

  group('StaffingAction', () {
    test('displayName returns correct values', () {
      expect(StaffingAction.addStaff.displayName, 'Add Staff');
      expect(StaffingAction.runPromotion.displayName, 'Run Promotion');
      expect(StaffingAction.optimal.displayName, 'Optimal');
      expect(StaffingAction.reduceStaff.displayName, 'Reduce Staff');
      expect(StaffingAction.reduceHours.displayName, 'Reduce Hours');
    });

    test('iconName returns correct values', () {
      expect(StaffingAction.addStaff.iconName, 'person_add');
      expect(StaffingAction.runPromotion.iconName, 'campaign');
      expect(StaffingAction.optimal.iconName, 'check_circle');
      expect(StaffingAction.reduceStaff.iconName, 'person_remove');
      expect(StaffingAction.reduceHours.iconName, 'schedule');
    });
  });

  group('DemandForecastResult', () {
    test('forecastDays returns correct count', () {
      final result = _createResult(forecastDays: 30);
      expect(result.forecastDays, 30);
    });

    test('hasUrgentNeeds returns correct value', () {
      final withUrgent = DemandForecastResult(
        businessId: 'biz_1',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        forecasts: [],
        staffingRecommendations: [],
        generatedAt: DateTime.now(),
        averageDemand: 15,
        urgentDays: [_createRecommendation(urgency: 5)],
      );

      final noUrgent = _createResult(forecastDays: 10);

      expect(withUrgent.hasUrgentNeeds, true);
      expect(noUrgent.hasUrgentNeeds, false);
    });

    test('totalPredicted sums all forecasts', () {
      final result = DemandForecastResult(
        businessId: 'biz_1',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3)),
        forecasts: [
          _createForecast(predictedCount: 10),
          _createForecast(predictedCount: 15),
          _createForecast(predictedCount: 20),
        ],
        staffingRecommendations: [],
        generatedAt: DateTime.now(),
        averageDemand: 15,
      );

      expect(result.totalPredicted, 45);
    });
  });

  group('DemandForecastRequest', () {
    test('default values are applied', () {
      final request = DemandForecastRequest(
        businessId: 'biz_1',
        startDate: DateTime.now(),
      );

      expect(request.forecastDays, 30);
      expect(request.includeStaffing, true);
      expect(request.includeHourly, false);
      expect(request.includeServiceBreakdown, false);
    });

    test('serialization works correctly', () {
      final request = DemandForecastRequest(
        businessId: 'biz_1',
        locationId: 'loc_1',
        serviceId: 'svc_1',
        startDate: DateTime(2024, 3, 15),
        forecastDays: 14,
        includeStaffing: false,
        currentCapacity: 20,
      );

      final json = request.toJson();
      final restored = DemandForecastRequest.fromJson(json);

      expect(restored.businessId, 'biz_1');
      expect(restored.locationId, 'loc_1');
      expect(restored.forecastDays, 14);
      expect(restored.includeStaffing, false);
      expect(restored.currentCapacity, 20);
    });
  });

  group('StaffingSuggestion', () {
    test('serialization works correctly', () {
      const suggestion = StaffingSuggestion(
        type: 'add_shift',
        description: 'Add extra morning shift',
        priority: 1,
        impact: 'Cover 5 additional appointments',
      );

      final json = suggestion.toJson();
      final restored = StaffingSuggestion.fromJson(json);

      expect(restored.type, 'add_shift');
      expect(restored.description, 'Add extra morning shift');
      expect(restored.priority, 1);
      expect(restored.impact, 'Cover 5 additional appointments');
    });
  });
}

/// Helper to create test forecasts
DemandForecast _createForecast({
  double predictedCount = 15,
  double lowerBound = 10,
  double upperBound = 20,
  DemandLevel demandLevel = DemandLevel.normal,
  double confidence = 0.7,
  int dayOfWeek = 1,
}) {
  return DemandForecast(
    date: DateTime.now(),
    predictedCount: predictedCount,
    lowerBound: lowerBound,
    upperBound: upperBound,
    demandLevel: demandLevel,
    confidence: confidence,
    dayOfWeek: dayOfWeek,
  );
}

/// Helper to create test recommendations
StaffingRecommendation _createRecommendation({
  int currentCapacity = 15,
  int recommendedCapacity = 20,
  StaffingAction action = StaffingAction.addStaff,
  int urgency = 3,
}) {
  return StaffingRecommendation(
    date: DateTime.now(),
    forecast: _createForecast(),
    currentCapacity: currentCapacity,
    recommendedCapacity: recommendedCapacity,
    action: action,
    urgency: urgency,
    reasoning: 'Test reasoning',
    confidence: 0.8,
  );
}

/// Helper to create test results
DemandForecastResult _createResult({
  int forecastDays = 30,
}) {
  return DemandForecastResult(
    businessId: 'biz_1',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(Duration(days: forecastDays)),
    forecasts: List.generate(forecastDays, (i) => _createForecast()),
    staffingRecommendations: [],
    generatedAt: DateTime.now(),
    averageDemand: 15,
  );
}
