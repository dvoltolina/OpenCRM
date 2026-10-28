import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment.dart';
import 'recurrence_pattern.dart';
import '../converters/timestamp_converters.dart';

part 'appointment.freezed.dart';
part 'appointment.g.dart';

/// Appointment status enum
enum AppointmentStatus { pending, confirmed, cancelled, completed, noShow }

/// Appointment entity representing a scheduled booking.
/// Multi-tenant: enforced via client.businessId, provider.businessId relationships.
@freezed
abstract class Appointment with _$Appointment {
  const factory Appointment({
    required String id,
    required String businessId,
    required String clientId,
    required String providerId,
    required String serviceId,
    String? serviceType, // Cached service name for display
    required String locationId,
    @TimestampConverter() required DateTime startTime,
    @TimestampConverter() required DateTime endTime,
    @TimestampConverter() required DateTime date,
    required AppointmentStatus status,
    String? notes,
    @TimestampConverter() required DateTime createdAt,
    @Default(false) bool requiresPayment,
    @Default(PaymentType.full) PaymentType paymentType,
    int? paymentAmountCents,
    @Default(PaymentStatus.none) PaymentStatus paymentStatus,
    String? paymentId,
    @Default(false) bool refundEligible,
    PaymentStatus? refundStatus,
    int? refundAmountCents,
    @NullableTimestampConverter() DateTime? refundRequestedAt,
    @NullableTimestampConverter() DateTime? refundProcessedAt,
    String? refundPaymentId,
    @Default(false) bool rescheduleFeeRequired,
    int? rescheduleFeeCents,
    @Default(PaymentStatus.none) PaymentStatus rescheduleFeeStatus,
    String? reschedulePaymentId,
    @Default(false) bool cancellationFeeRequired,
    int? cancellationFeeCents,
    @Default(PaymentStatus.none) PaymentStatus cancellationFeeStatus,
    String? cancellationPaymentId,
    String? cancellationReason,
    String? cancellationCode,
    @NullableTimestampConverter() DateTime? cancelledAt,
    // Recurrence fields
    /// Whether this is a recurring appointment
    @Default(false) bool isRecurring,
    /// ID linking all appointments in the same recurrence series
    String? recurrenceId,
    /// The recurrence pattern (only set on parent/first appointment in series)
    RecurrencePattern? recurrencePattern,
    /// Whether this instance is an exception (modified) from the series
    @Default(false) bool isRecurrenceException,
    /// Original date/time before modification (for exceptions)
    @NullableTimestampConverter() DateTime? originalStartTime,
    /// For group appointments/classes
    @Default(false) bool isGroupSession,
    int? capacity,
    @Default([]) List<String> attendeeIds,
    @Default(false) bool publicVisibility,
    @NullableTimestampConverter() DateTime? registrationDeadline,
  }) = _Appointment;

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
}

/// Extension methods for Appointment
extension AppointmentExtensions on Appointment {
  /// Checks if this is the parent appointment in a recurring series
  bool get isRecurrenceParent =>
      isRecurring && recurrencePattern != null && recurrenceId == id;

  /// Checks if this is a child instance in a recurring series
  bool get isRecurrenceInstance =>
      isRecurring && recurrencePattern == null && recurrenceId != null;

  /// Checks if appointment can be cancelled based on status
  bool get canBeCancelled =>
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed &&
      status != AppointmentStatus.noShow;

  /// Checks if appointment can be rescheduled
  bool get canBeRescheduled =>
      status != AppointmentStatus.cancelled &&
      status != AppointmentStatus.completed &&
      status != AppointmentStatus.noShow;

  /// Remaining seats for group session (null for 1:1).
  int? get remainingSeats => capacity == null
      ? null
      : ((capacity! - attendeeIds.length).clamp(0, capacity!));

  bool get isFull => remainingSeats != null && remainingSeats == 0;
}
