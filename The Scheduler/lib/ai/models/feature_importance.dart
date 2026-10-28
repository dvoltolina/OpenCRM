import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_importance.freezed.dart';
part 'feature_importance.g.dart';

/// Information about which feature contributed to the prediction.
///
/// This model is used to explain predictions to staff, showing which
/// factors increased or decreased the no-show risk for a given appointment.
@freezed
abstract class FeatureImportance with _$FeatureImportance {
  const factory FeatureImportance({
    /// Technical name of the feature (e.g., 'clientHistoricalNoshowRate')
    required String featureName,

    /// Human-readable name for display (e.g., 'Past No-Show Rate')
    required String featureDisplayName,

    /// Importance score (0.0-1.0, relative to other features)
    required double importance,

    /// Actual value of this feature for this prediction
    required double featureValue,

    /// Direction of impact on risk: 'increases_risk' or 'decreases_risk'
    required String impact,

    /// Human-readable explanation of this feature's contribution
    String? explanation,
  }) = _FeatureImportance;

  factory FeatureImportance.fromJson(Map<String, dynamic> json) =>
      _$FeatureImportanceFromJson(json);

  const FeatureImportance._();

  /// Whether this feature increases risk
  bool get increasesRisk => impact == 'increases_risk';

  /// Whether this feature decreases risk
  bool get decreasesRisk => impact == 'decreases_risk';

  /// Importance as percentage (0-100)
  int get importancePercent => (importance * 100).round();
}

/// Feature display names mapping for UI.
///
/// Maps technical feature names to human-readable display names
/// for showing in the prediction explanation UI.
const Map<String, String> featureDisplayNames = {
  'clientHistoricalNoshowRate': 'Past No-Show Rate',
  'clientHistoricalCancelRate': 'Past Cancellation Rate',
  'clientTotalAppointments': 'Appointment History',
  'clientDaysSinceLastVisit': 'Days Since Last Visit',
  'clientLifetimeValueCents': 'Lifetime Value',
  'clientLifecycleStage': 'Client Status',
  'clientHasPaymentMethod': 'Payment Method on File',
  'bookingLeadDays': 'Days Until Appointment',
  'dayOfWeek': 'Day of Week',
  'hourOfDay': 'Time of Day',
  'isRecurring': 'Recurring Appointment',
  'isGroupSession': 'Group Session',
  'serviceDurationMinutes': 'Service Duration',
  'servicePriceCents': 'Service Price',
  'requiresPayment': 'Payment Required',
  'paymentCollected': 'Payment Collected',
  'hasIntakeForm': 'Intake Form Completed',
  'providerHistoricalNoshowRate': 'Provider\'s No-Show Rate',
  'providerTotalAppointments': 'Provider Experience',
  'slotHistoricalNoshowRate': 'Time Slot Risk',
  'isFirstAppointmentOfDay': 'First Appointment',
  'isLastAppointmentOfDay': 'Last Appointment',
};

/// Helper to get display name for a feature.
String getFeatureDisplayName(String featureName) {
  return featureDisplayNames[featureName] ?? featureName;
}

/// Create a FeatureImportance with automatic display name lookup.
FeatureImportance createFeatureImportance({
  required String featureName,
  required double importance,
  required double featureValue,
  required String impact,
  String? explanation,
}) {
  return FeatureImportance(
    featureName: featureName,
    featureDisplayName: getFeatureDisplayName(featureName),
    importance: importance,
    featureValue: featureValue,
    impact: impact,
    explanation: explanation,
  );
}
