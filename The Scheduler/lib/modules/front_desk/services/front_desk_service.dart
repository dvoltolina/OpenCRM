import 'package:uuid/uuid.dart';

import '../../../data/models/appointment.dart';
import '../../../data/models/audit_log.dart';
import '../../../data/models/security_context.dart';
import '../../../data/models/waitlist_entry.dart';
import '../../../data/repositories/appointments_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/repositories/waitlist_repository.dart';

/// Service for front desk operations including check-in and waitlist management.
///
/// HIPAA Compliance:
/// - All operations audit log PHI access
/// - No PHI in error messages or logs
/// - All operations require SecurityContext with proper permissions
class FrontDeskService {
  FrontDeskService({
    required AppointmentsRepository appointmentsRepository,
    required WaitlistRepository waitlistRepository,
    AuditLogRepository? auditLogRepository,
  })  : _appointmentsRepository = appointmentsRepository,
        _waitlistRepository = waitlistRepository,
        _auditLogRepository =
            auditLogRepository ?? AuditLogRepository();

  final AppointmentsRepository _appointmentsRepository;
  final WaitlistRepository _waitlistRepository;
  final AuditLogRepository _auditLogRepository;
  final _uuid = const Uuid();

  /// Check in a client for their appointment.
  ///
  /// Updates appointment status to confirmed if pending, or marks as arrived.
  /// Logs audit event for PHI access.
  Future<void> checkInClient(
    SecurityContext context,
    String appointmentId,
  ) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to check in clients',
      );
    }

    final appointment = await _appointmentsRepository.getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw Exception('Appointment not found');
    }

    // Update appointment status
    await _appointmentsRepository.upsertAppointment(
      context: context,
      appointment: appointment.copyWith(
        status: AppointmentStatus.confirmed,
      ),
    );

    // Audit log check-in action (no PHI in log)
    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {
        'action': 'check_in',
        'source': 'front_desk',
      },
    ));
  }

  /// Mark client as arrived (waiting for service).
  ///
  /// Used when client arrives but provider is not ready yet.
  Future<void> markArrived(
    SecurityContext context,
    String appointmentId,
  ) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to update appointments',
      );
    }

    final appointment = await _appointmentsRepository.getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw Exception('Appointment not found');
    }

    await _appointmentsRepository.upsertAppointment(
      context: context,
      appointment: appointment.copyWith(
        status: AppointmentStatus.confirmed,
      ),
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {
        'action': 'mark_arrived',
        'source': 'front_desk',
      },
    ));
  }

  /// Mark appointment as no-show.
  ///
  /// Used when client doesn't arrive for their appointment.
  Future<void> markNoShow(
    SecurityContext context,
    String appointmentId,
  ) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to update appointments',
      );
    }

    final appointment = await _appointmentsRepository.getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw Exception('Appointment not found');
    }

    await _appointmentsRepository.upsertAppointment(
      context: context,
      appointment: appointment.copyWith(
        status: AppointmentStatus.noShow,
      ),
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {
        'action': 'mark_no_show',
        'source': 'front_desk',
      },
    ));
  }

  /// Add client to waitlist.
  ///
  /// Returns the waitlist entry ID.
  Future<String> addToWaitlist(
    SecurityContext context, {
    required String clientId,
    required String clientName,
    required String serviceId,
    required String serviceName,
    String? preferredProviderId,
    String? clientEmail,
    String? clientPhone,
    DateTime? earliestDate,
    DateTime? latestDate,
  }) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to manage waitlist',
      );
    }

    final now = DateTime.now();
    final entryId = _uuid.v4();

    final entry = WaitlistEntry(
      id: entryId,
      businessId: context.businessId,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      serviceId: serviceId,
      serviceName: serviceName,
      providerId: preferredProviderId,
      earliestDate: earliestDate ?? now,
      latestDate: latestDate ?? now.add(const Duration(days: 30)),
      priorityScore: 1.0,
      notificationPreference: NotificationPreference.email,
      status: WaitlistStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _waitlistRepository.upsertEntry(
      context: context,
      entry: entry,
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'WaitlistEntry',
      entityId: entryId,
      metadata: {
        'action': 'add_to_waitlist',
        'source': 'front_desk',
      },
    ));

    return entryId;
  }

  /// Seat client from waitlist by creating an appointment.
  ///
  /// Removes from waitlist and creates appointment, returns appointment ID.
  Future<String> seatFromWaitlist(
    SecurityContext context,
    String waitlistEntryId,
    String providerId,
    DateTime startTime,
    int durationMinutes,
  ) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to manage waitlist',
      );
    }

    final entries = await _waitlistRepository.loadEntries(
      context: context,
      businessId: context.businessId,
    );

    final entry = entries.firstWhere(
      (e) => e.id == waitlistEntryId,
      orElse: () => throw Exception('Waitlist entry not found'),
    );

    // Create appointment
    final appointmentId = _uuid.v4();
    final appointment = Appointment(
      id: appointmentId,
      businessId: context.businessId,
      clientId: entry.clientId ?? '',
      providerId: providerId,
      serviceId: entry.serviceId,
      serviceType: entry.serviceName,
      locationId: entry.locationId ?? '',
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: durationMinutes)),
      date: startTime,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
    );

    await _appointmentsRepository.upsertAppointment(
      context: context,
      appointment: appointment,
    );

    // Update waitlist entry status
    await _waitlistRepository.updateStatus(
      businessId: context.businessId,
      entryId: waitlistEntryId,
      status: WaitlistStatus.converted,
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {
        'action': 'seat_from_waitlist',
        'source': 'front_desk',
        'waitlistEntryId': waitlistEntryId,
      },
    ));

    return appointmentId;
  }

  /// Create walk-in appointment (immediate booking).
  ///
  /// Returns the appointment ID.
  Future<String> createWalkInAppointment(
    SecurityContext context, {
    required String clientId,
    required String serviceId,
    required String providerId,
    required String locationId,
    required DateTime startTime,
    required int durationMinutes,
    String? serviceType,
  }) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to create appointments',
      );
    }

    final appointmentId = _uuid.v4();
    final appointment = Appointment(
      id: appointmentId,
      businessId: context.businessId,
      clientId: clientId,
      providerId: providerId,
      serviceId: serviceId,
      serviceType: serviceType,
      locationId: locationId,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: durationMinutes)),
      date: startTime,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
    );

    await _appointmentsRepository.upsertAppointment(
      context: context,
      appointment: appointment,
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {
        'action': 'create_walk_in',
        'source': 'front_desk',
      },
    ));

    return appointmentId;
  }

  /// Remove entry from waitlist.
  Future<void> removeFromWaitlist(
    SecurityContext context,
    String waitlistEntryId,
  ) async {
    if (!context.role.canManageClients) {
      throw SecurityException(
        'Insufficient permissions to manage waitlist',
      );
    }

    final entries = await _waitlistRepository.loadEntries(
      context: context,
      businessId: context.businessId,
    );

    final entry = entries.firstWhere(
      (e) => e.id == waitlistEntryId,
      orElse: () => throw Exception('Waitlist entry not found'),
    );

    await _waitlistRepository.deleteEntry(
      context: context,
      entry: entry,
    );

    await _auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiWrite,
      entityType: 'WaitlistEntry',
      entityId: waitlistEntryId,
      metadata: {
        'action': 'remove_from_waitlist',
        'source': 'front_desk',
      },
    ));
  }
}
