import 'package:freezed_annotation/freezed_annotation.dart';

part 'prediction_features.freezed.dart';
part 'prediction_features.g.dart';

/// Current feature schema version for tracking model compatibility.
/// Increment when feature set changes (adding/removing/renaming features).
const int kFeatureSchemaVersion = 1;

/// Feature vector for no-show prediction model.
///
/// This model contains all extracted features sent to the prediction service.
/// Every field is documented with its data source and expected range.
///
/// Feature categories:
/// - Client behavioral: Historical patterns from past appointments
/// - Appointment context: Details about the current booking
/// - Provider features: Provider-specific patterns
/// - Time slot features: Patterns for specific days/times
///
/// All features are required to ensure consistent model input.
/// Missing data should be handled in [FeatureExtractionService] with defaults.
@freezed
abstract class PredictionFeatures with _$PredictionFeatures {
  const factory PredictionFeatures({
    // ============ Metadata ============
    /// Unique identifier of the appointment being predicted
    required String appointmentId,

    /// Business ID for multi-tenant isolation
    required String businessId,

    /// Timestamp when features were extracted
    required DateTime extractedAt,

    /// Schema version for compatibility tracking with ML model
    required int featureSchemaVersion,

    // ============ Client Behavioral Features ============
    /// Client's historical no-show rate (0.0-1.0)
    /// Source: Past appointments where status == noShow / total past appointments
    /// Range: 0.0 to 1.0
    /// Weight: Very High
    required double clientHistoricalNoshowRate,

    /// Client's historical cancellation rate (0.0-1.0)
    /// Source: Past appointments where status == cancelled / total past appointments
    /// Range: 0.0 to 1.0
    /// Weight: High
    required double clientHistoricalCancelRate,

    /// Total number of past appointments for this client
    /// Source: Count of all past appointments (before now)
    /// Range: 0 to infinity
    /// Weight: Medium (new clients have higher uncertainty)
    required int clientTotalAppointments,

    /// Days since client's last completed visit
    /// Source: DateTime.now - last completed appointment start time
    /// Range: 0 to infinity (9999 for first-time clients)
    /// Weight: Medium
    required int clientDaysSinceLastVisit,

    /// Client's total lifetime payment value in cents
    /// Source: Sum of completed payments for this client
    /// Range: 0 to infinity
    /// Weight: Medium (higher value = more invested)
    required int clientLifetimeValueCents,

    /// Client's current lifecycle stage
    /// Source: Client.lifecycle enum as string
    /// Values: 'newClient', 'active', 'inactive', 'churned'
    /// Weight: Low
    required String clientLifecycleStage,

    /// Whether client has a payment method on file
    /// Source: Client.hasPaymentMethod
    /// Weight: Medium (trust indicator)
    required bool clientHasPaymentMethod,

    // ============ Appointment Context Features ============
    /// Number of days between booking creation and appointment start
    /// Source: appointment.startTime - appointment.createdAt (in days)
    /// Range: 0 to 365 (capped)
    /// Weight: Very High (longer lead = higher no-show risk)
    required int bookingLeadDays,

    /// Day of week (1=Monday, 7=Sunday)
    /// Source: appointment.startTime.weekday
    /// Range: 1 to 7
    /// Weight: Medium
    required int dayOfWeek,

    /// Hour of day (24-hour format)
    /// Source: appointment.startTime.hour
    /// Range: 0 to 23
    /// Weight: Medium (early morning/late evening may have higher no-shows)
    required int hourOfDay,

    /// Whether this is a recurring appointment
    /// Source: Appointment.isRecurring
    /// Weight: Medium (recurring = more committed)
    required bool isRecurring,

    /// Whether this is a group session/class
    /// Source: Appointment.isGroupSession
    /// Weight: Low
    required bool isGroupSession,

    /// Service duration in minutes
    /// Source: Service.durationMinutes
    /// Range: 15 to 480
    /// Weight: Low
    required int serviceDurationMinutes,

    /// Service price in cents
    /// Source: Service.price (converted to cents)
    /// Range: 0 to infinity
    /// Weight: Low (higher price = more committed)
    required int servicePriceCents,

    /// Whether appointment requires payment
    /// Source: Appointment.requiresPayment
    /// Weight: High (payment required = lower no-show)
    required bool requiresPayment,

    /// Whether payment has been collected
    /// Source: Appointment.paymentStatus == completed
    /// Weight: Very High (collected = much lower no-show)
    required bool paymentCollected,

    /// Whether client submitted an intake form for this appointment
    /// Source: IntakeFormSubmission exists for client + appointment
    /// Weight: Low (engagement indicator)
    required bool hasIntakeForm,

    // ============ Provider Features ============
    /// Provider's historical no-show rate (0.0-1.0)
    /// Source: Past appointments for this provider where status == noShow
    /// Range: 0.0 to 1.0
    /// Weight: Medium (some providers may have higher no-show rates)
    required double providerHistoricalNoshowRate,

    /// Total appointments for this provider
    /// Source: Count of past appointments for this provider
    /// Range: 0 to infinity
    /// Weight: Low
    required int providerTotalAppointments,

    // ============ Time Slot Features ============
    /// Historical no-show rate for this day/hour combination (0.0-1.0)
    /// Source: Past appointments at same weekday + hour
    /// Range: 0.0 to 1.0
    /// Weight: Medium
    required double slotHistoricalNoshowRate,

    /// Whether this is the first appointment of the provider's day
    /// Source: Comparison with other appointments on same day
    /// Weight: Low (first appointments may have different patterns)
    required bool isFirstAppointmentOfDay,

    /// Whether this is the last appointment of the provider's day
    /// Source: Comparison with other appointments on same day
    /// Weight: Low
    required bool isLastAppointmentOfDay,
  }) = _PredictionFeatures;

  factory PredictionFeatures.fromJson(Map<String, dynamic> json) =>
      _$PredictionFeaturesFromJson(json);

  const PredictionFeatures._();

  /// Validate all features are within expected ranges.
  /// Returns list of validation errors (empty if valid).
  List<String> validate() {
    final errors = <String>[];

    // Rate validations (0.0 - 1.0)
    if (clientHistoricalNoshowRate < 0 || clientHistoricalNoshowRate > 1) {
      errors.add('clientHistoricalNoshowRate must be 0.0-1.0');
    }
    if (clientHistoricalCancelRate < 0 || clientHistoricalCancelRate > 1) {
      errors.add('clientHistoricalCancelRate must be 0.0-1.0');
    }
    if (providerHistoricalNoshowRate < 0 || providerHistoricalNoshowRate > 1) {
      errors.add('providerHistoricalNoshowRate must be 0.0-1.0');
    }
    if (slotHistoricalNoshowRate < 0 || slotHistoricalNoshowRate > 1) {
      errors.add('slotHistoricalNoshowRate must be 0.0-1.0');
    }

    // Count validations (non-negative)
    if (clientTotalAppointments < 0) {
      errors.add('clientTotalAppointments must be non-negative');
    }
    if (clientDaysSinceLastVisit < 0) {
      errors.add('clientDaysSinceLastVisit must be non-negative');
    }
    if (clientLifetimeValueCents < 0) {
      errors.add('clientLifetimeValueCents must be non-negative');
    }
    if (bookingLeadDays < 0) {
      errors.add('bookingLeadDays must be non-negative');
    }
    if (providerTotalAppointments < 0) {
      errors.add('providerTotalAppointments must be non-negative');
    }

    // Range validations
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      errors.add('dayOfWeek must be 1-7');
    }
    if (hourOfDay < 0 || hourOfDay > 23) {
      errors.add('hourOfDay must be 0-23');
    }
    if (serviceDurationMinutes < 0) {
      errors.add('serviceDurationMinutes must be non-negative');
    }
    if (servicePriceCents < 0) {
      errors.add('servicePriceCents must be non-negative');
    }

    // Lifecycle validation
    const validLifecycles = ['newClient', 'active', 'inactive', 'churned'];
    if (!validLifecycles.contains(clientLifecycleStage)) {
      errors.add('clientLifecycleStage must be one of: ${validLifecycles.join(', ')}');
    }

    return errors;
  }

  /// Check if features are valid
  bool get isValid => validate().isEmpty;

  /// Convert to flat feature vector for ML model input.
  /// Order MUST match the model's expected feature order.
  /// Used for direct model inference.
  List<double> toFeatureVector() {
    return [
      // Client behavioral (7 features)
      clientHistoricalNoshowRate,
      clientHistoricalCancelRate,
      clientTotalAppointments.toDouble(),
      clientDaysSinceLastVisit.toDouble(),
      clientLifetimeValueCents.toDouble(),
      _encodeLifecycleStage(clientLifecycleStage),
      clientHasPaymentMethod ? 1.0 : 0.0,

      // Appointment context (10 features)
      bookingLeadDays.toDouble(),
      dayOfWeek.toDouble(),
      hourOfDay.toDouble(),
      isRecurring ? 1.0 : 0.0,
      isGroupSession ? 1.0 : 0.0,
      serviceDurationMinutes.toDouble(),
      servicePriceCents.toDouble(),
      requiresPayment ? 1.0 : 0.0,
      paymentCollected ? 1.0 : 0.0,
      hasIntakeForm ? 1.0 : 0.0,

      // Provider features (2 features)
      providerHistoricalNoshowRate,
      providerTotalAppointments.toDouble(),

      // Time slot features (3 features)
      slotHistoricalNoshowRate,
      isFirstAppointmentOfDay ? 1.0 : 0.0,
      isLastAppointmentOfDay ? 1.0 : 0.0,
    ];
  }

  /// Get feature names in the same order as [toFeatureVector].
  /// Useful for debugging and feature importance analysis.
  static List<String> get featureNames => const [
        'clientHistoricalNoshowRate',
        'clientHistoricalCancelRate',
        'clientTotalAppointments',
        'clientDaysSinceLastVisit',
        'clientLifetimeValueCents',
        'clientLifecycleStage',
        'clientHasPaymentMethod',
        'bookingLeadDays',
        'dayOfWeek',
        'hourOfDay',
        'isRecurring',
        'isGroupSession',
        'serviceDurationMinutes',
        'servicePriceCents',
        'requiresPayment',
        'paymentCollected',
        'hasIntakeForm',
        'providerHistoricalNoshowRate',
        'providerTotalAppointments',
        'slotHistoricalNoshowRate',
        'isFirstAppointmentOfDay',
        'isLastAppointmentOfDay',
      ];

  /// Number of features in the vector
  static int get featureCount => featureNames.length;

  /// Encode lifecycle stage as numeric value for model
  double _encodeLifecycleStage(String stage) {
    switch (stage) {
      case 'newClient':
        return 0.0;
      case 'active':
        return 1.0;
      case 'inactive':
        return 2.0;
      case 'churned':
        return 3.0;
      default:
        return 0.0;
    }
  }
}
