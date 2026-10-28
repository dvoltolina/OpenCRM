import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_appointment.freezed.dart';
part 'local_appointment.g.dart';

/// Appointment model optimized for offline storage in the staff app.
///
/// This is a denormalized version of the main Appointment model that includes
/// client and service details inline, reducing the need for additional lookups
/// when working offline. Includes fields for offline sync queue management.
@freezed
class LocalAppointment with _$LocalAppointment {
  const LocalAppointment._();

  const factory LocalAppointment({
    // Required identifiers
    required String id,
    required String businessId,
    required String clientId,
    required String serviceId,
    required String locationId,

    // Denormalized client info (for offline display)
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,

    // Denormalized service/location info (for offline display)
    String? serviceName,
    String? locationName,
    int? serviceDurationMinutes,

    // Time fields
    required DateTime startTime,
    required DateTime endTime,

    // Appointment status
    required String status,

    // Notes
    /// Admin/booking notes (read-only for staff)
    String? notes,
    /// Staff-entered notes (editable)
    String? staffNotes,

    // Payment info
    @Default(false) bool requiresPayment,
    String? paymentStatus,

    // Offline sync fields
    /// When this record was last updated locally
    DateTime? localUpdatedAt,
    /// True if this record has pending changes to sync
    @Default(false) bool pendingSync,
    /// Action to perform on sync: 'update', 'check_in', 'complete', 'no_show'
    String? syncAction,

    // Check-in tracking
    /// When the client was checked in
    DateTime? checkedInAt,
    /// Staff member who checked in the client
    String? checkedInByStaffId,

    // Completion tracking
    /// When the appointment was completed
    DateTime? completedAt,
    /// Staff member who completed the appointment
    String? completedByStaffId,
  }) = _LocalAppointment;

  factory LocalAppointment.fromJson(Map<String, dynamic> json) =>
      _$LocalAppointmentFromJson(json);

  /// Whether the appointment is currently in progress (now is between start/end)
  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Whether the appointment is in the past
  bool get isPast => DateTime.now().isAfter(endTime);

  /// Whether the appointment is in the future
  bool get isFuture => DateTime.now().isBefore(startTime);

  /// Whether the client has been checked in
  bool get isCheckedIn => checkedInAt != null;

  /// Whether the appointment is completed
  bool get isCompleted => status == 'completed';

  /// Whether the appointment is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Construct from a main Appointment model (dynamic to avoid cross-package dependency).
  ///
  /// Safely maps known fields and falls back to sensible defaults.
  factory LocalAppointment.fromAppointment(dynamic appointment) {
    DateTime? asDate(dynamic value) => value is DateTime ? value : null;
    String? asString(dynamic value) {
      if (value == null) return null;
      if (value is Enum) return value.name;
      return value.toString();
    }

    final start = asDate(appointment.startTime) ?? DateTime.now();
    final end = asDate(appointment.endTime) ?? start.add(const Duration(minutes: 30));

    return LocalAppointment(
      id: asString(appointment.id) ?? '',
      businessId: asString(appointment.businessId) ?? '',
      clientId: asString(appointment.clientId) ?? '',
      serviceId: asString(appointment.serviceId) ?? '',
      locationId: asString(appointment.locationId) ?? '',
      clientName: asString(appointment.clientName),
      clientPhone: asString(appointment.clientPhone),
      clientEmail: asString(appointment.clientEmail),
      clientAddress: asString(appointment.clientAddress),
      serviceName: asString(appointment.serviceType) ?? asString(appointment.serviceName),
      locationName: asString(appointment.locationName),
      serviceDurationMinutes:
          appointment.serviceDurationMinutes is int ? appointment.serviceDurationMinutes as int : end.difference(start).inMinutes,
      startTime: start,
      endTime: end,
      status: asString(appointment.status) ?? 'pending',
      notes: asString(appointment.notes),
      staffNotes: asString(appointment.staffNotes),
      requiresPayment: appointment.requiresPayment is bool ? appointment.requiresPayment as bool : false,
      paymentStatus: asString(appointment.paymentStatus),
      localUpdatedAt: asDate(appointment.updatedAt),
      pendingSync: appointment.pendingSync is bool ? appointment.pendingSync as bool : false,
      syncAction: asString(appointment.syncAction),
      checkedInAt: asDate(appointment.checkedInAt),
      checkedInByStaffId: asString(appointment.checkedInByStaffId),
      completedAt: asDate(appointment.completedAt),
      completedByStaffId: asString(appointment.completedByStaffId),
    );
  }

  /// Whether the appointment is a no-show
  bool get isNoShow => status == 'noShow';

  /// Whether the appointment is actionable (can be checked in, completed, etc.)
  bool get isActionable =>
      !isCancelled && !isNoShow && !isCompleted && !isPast;

  /// Duration of the appointment in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Create a copy marked for sync with the specified action
  LocalAppointment markForSync(String action) => copyWith(
        pendingSync: true,
        syncAction: action,
        localUpdatedAt: DateTime.now(),
      );

  /// Create a copy with sync cleared (after successful sync)
  LocalAppointment clearSync() => copyWith(
        pendingSync: false,
        syncAction: null,
      );
}
