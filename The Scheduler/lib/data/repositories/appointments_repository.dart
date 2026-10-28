import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';
import '../models/appointment.dart';
import '../models/audit_log.dart';
import '../models/group_attendee.dart';
import '../models/payment.dart';
import '../models/recurrence_pattern.dart';
import '../models/security_context.dart';
import '../../core/services/recurrence_service.dart';
import 'audit_log_repository.dart';
import 'group_attendees_repository.dart';

/// Repository for managing appointments with multi-tenant isolation and RBAC.
/// Clients can only view/manage their own appointments.
/// Staff can view/manage appointments for their assigned services.
/// Admins can view/manage all appointments in their business.
///
/// PHI Access Logging: All read operations are audit logged per HIPAA
/// requirements. Single-entity reads log `phiRead`; list/stream reads
/// log `phiReadList` once per logical action (not per document).
class AppointmentsRepository {
  AppointmentsRepository({
    FirebaseFirestore? firestore,
    RecurrenceService? recurrenceService,
    GroupAttendeesRepository? groupAttendeesRepository,
    AuditLogRepository? auditLogRepository,
  }) : this._internal(
          firestore: firestore ?? FirebaseFirestore.instance,
          recurrenceService: recurrenceService,
          groupAttendeesRepository: groupAttendeesRepository,
          auditLogRepository: auditLogRepository,
        );

  AppointmentsRepository._internal({
    required FirebaseFirestore firestore,
    RecurrenceService? recurrenceService,
    GroupAttendeesRepository? groupAttendeesRepository,
    AuditLogRepository? auditLogRepository,
  })  : _firestore = firestore,
        _auditLogRepository = auditLogRepository ??
            AuditLogRepository(firestore: firestore),
        _recurrenceService =
            recurrenceService ?? RecurrenceService(firestore: firestore),
        _groupAttendeesRepository = groupAttendeesRepository ??
            GroupAttendeesRepository(
              firestore: firestore,
              auditLogRepository:
                  auditLogRepository ?? AuditLogRepository(firestore: firestore),
            );

  final FirebaseFirestore _firestore;
  final RecurrenceService _recurrenceService;
  final GroupAttendeesRepository _groupAttendeesRepository;
  final AuditLogRepository _auditLogRepository;

  GroupAttendeesRepository get attendeesRepository => _groupAttendeesRepository;

  /// Watch upcoming appointments based on user role
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<Appointment>> watchUpcoming(SecurityContext context) {
    Query<Map<String, dynamic>> query =
        _businessAppointments(context.businessId)
            .where('startTime', isGreaterThan: Timestamp.now())
            .orderBy('startTime', descending: false)
            .limit(25);

    // Filter by role
    if (context.clientId != null && !context.role.canManageAllAppointments) {
      // Clients only see their own appointments
      query = query.where('clientId', isEqualTo: context.clientId);
    } else if (context.providerId != null &&
        !context.role.canManageAllAppointments) {
      // Staff only see their own appointments
      query = query.where('providerId', isEqualTo: context.providerId);
    }

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => _mapAppointmentDoc(
                      doc: doc, businessId: context.businessId),
                )
                .toList(),
          ),
      context: context,
      entityType: 'Appointment',
      metadata: {'source': 'watchUpcoming', 'mode': 'list'},
    );
  }

  /// Create or update an appointment
  Future<void> upsertAppointment({
    required SecurityContext context,
    required Appointment appointment,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save appointment');
    }
    // Clients can only create appointments for themselves
    if (context.clientId != null && context.clientId != appointment.clientId) {
      throw SecurityException('Clients can only book for themselves');
    }

    // Staff can only create appointments they're providing
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        context.providerId != appointment.providerId) {
      throw SecurityException(
        'Staff can only book appointments for themselves',
      );
    }

    await _businessAppointments(
      context.businessId,
    ).doc(appointment.id).set(appointment.toJson(), SetOptions(merge: true));
  }

  /// Get a single appointment
  ///
  /// Audit: Logs one `phiRead` event when appointment data is retrieved.
  Future<Appointment?> getAppointment({
    required SecurityContext context,
    required String appointmentId,
  }) async {
    final doc = await _businessAppointments(
      context.businessId,
    ).doc(appointmentId).get();

    if (!doc.exists) return null;

    final appointment = _mapAppointmentDoc(
      doc: doc,
      businessId: context.businessId,
    );
    final isGroupSession = appointment.isGroupSession;
    final canViewGroup = isGroupSession &&
        (appointment.publicVisibility ||
            (context.clientId != null &&
                appointment.attendeeIds.contains(context.clientId)));

    // Verify access
    if (!context.role.canManageAllAppointments) {
      if (context.clientId != null &&
          appointment.clientId != context.clientId &&
          !canViewGroup) {
        throw SecurityException('Cannot access other clients\' appointments');
      }
      if (context.providerId != null &&
          appointment.providerId != context.providerId) {
        throw SecurityException('Cannot access other providers\' appointments');
      }
    }

    // Log PHI read access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiRead,
      entityType: 'Appointment',
      entityId: appointmentId,
      metadata: {'source': 'getAppointment'},
    )));

    return appointment;
  }

  /// Cancel an appointment
  Future<void> cancelAppointment({
    required SecurityContext context,
    required String appointmentId,
    String? reason,
    String? cancellationCode,
    Map<String, dynamic>? additionalUpdates,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('cancel appointment');
    }
    final appointment = await getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw SecurityException('Appointment not found');
    }

    final update = <String, dynamic>{
      'status': AppointmentStatus.cancelled.name,
      if (reason != null) 'cancellationReason': reason,
      if (cancellationCode != null) 'cancellationCode': cancellationCode,
      'cancelledAt': FieldValue.serverTimestamp(),
    };

    if (additionalUpdates != null) {
      update.addAll(additionalUpdates);
    }

    await _businessAppointments(
      context.businessId,
    ).doc(appointmentId).update(update);
  }

  /// Default limit for appointment list queries to control Firebase costs.
  static const int defaultClientAppointmentsLimit = 50;

  /// Watch appointments for a specific client (customer portal)
  ///
  /// Returns stream of appointments for the given client,
  /// ordered by startTime descending (most recent first).
  /// Used by customer portal to show appointment history.
  ///
  /// [limit] controls max documents returned (default: 50).
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<Appointment>> watchClientAppointments({
    required SecurityContext context,
    required String clientId,
    int limit = defaultClientAppointmentsLimit,
  }) {
    // Verify client access
    if (!context.role.canManageAllAppointments) {
      context.verifyClientAccess(clientId, context.businessId);
    }

    return _withAuditLogOnFirstEmission(
      stream: _businessAppointments(context.businessId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => _mapAppointmentDoc(
                      doc: doc, businessId: context.businessId),
                )
                .toList(),
          ),
      context: context,
      entityType: 'Appointment',
      metadata: {
        'source': 'watchClientAppointments',
        'mode': 'list',
        'limit': limit,
      },
    );
  }

  /// Build a query for appointments in a date range with filters and RBAC.
  Query<Map<String, dynamic>> _buildAppointmentsQuery({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
    AppointmentStatus? status,
  }) {
    Query<Map<String, dynamic>> query =
        _businessAppointments(context.businessId)
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .orderBy('startTime');

    // Apply filters based on params and permissions
    if (providerId != null) {
      context.verifyProviderAccess(providerId, context.businessId);
      query = query.where('providerId', isEqualTo: providerId);
    } else if (context.providerId != null &&
        !context.role.canManageAllAppointments) {
      query = query.where('providerId', isEqualTo: context.providerId);
    }

    if (clientId != null) {
      context.verifyClientAccess(clientId, context.businessId);
      query = query.where('clientId', isEqualTo: clientId);
    } else if (context.clientId != null &&
        !context.role.canManageAllAppointments) {
      query = query.where('clientId', isEqualTo: context.clientId);
    }

    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query;
  }

  /// Watch appointments in a date range with optional filters.
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<Appointment>> watchAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) {
    final query = _buildAppointmentsQuery(
      context: context,
      start: start,
      end: end,
      providerId: providerId,
      clientId: clientId,
      locationId: locationId,
    );

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => _mapAppointmentDoc(
                      doc: doc, businessId: context.businessId),
                )
                .toList(),
          ),
      context: context,
      entityType: 'Appointment',
      metadata: {'source': 'watchAppointmentsInRange', 'mode': 'list'},
    );
  }

  /// Fetch appointments once for validation/conflict checks
  ///
  /// Audit: Logs one `phiReadList` event when appointments are retrieved.
  Future<List<Appointment>> loadAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) async {
    final query = _buildAppointmentsQuery(
      context: context,
      start: start,
      end: end,
      providerId: providerId,
      clientId: clientId,
      locationId: locationId,
    );

    final snapshot = await query.get();
    final appointments = snapshot.docs
        .map(
          (doc) => _mapAppointmentDoc(doc: doc, businessId: context.businessId),
        )
        .toList();

    // Log PHI read list access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Appointment',
      entityId: context.businessId, // High-level identifier for list reads
      metadata: {
        'source': 'loadAppointmentsInRange',
        'mode': 'list',
        'count': appointments.length,
      },
    )));

    return appointments;
  }

  /// Get appointments for a specific provider on a specific date
  Future<List<Appointment>> getAppointmentsForDate({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    return await loadAppointmentsInRange(
      context: context,
      start: startOfDay,
      end: endOfDay,
      providerId: providerId,
    );
  }

  /// Get all appointments for a specific client
  ///
  /// Returns appointments from the last year to 1 year in the future.
  /// Audit: Logs one `phiReadList` event when appointments are retrieved.
  Future<List<Appointment>> getClientAppointments({
    required SecurityContext context,
    required String clientId,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365));
    final end = now.add(const Duration(days: 365));

    return await loadAppointmentsInRange(
      context: context,
      start: start,
      end: end,
      clientId: clientId,
    );
  }

  /// Watch group sessions with optional filters.
  ///
  /// Audit: Logs one `phiReadList` event on first emission.
  Stream<List<Appointment>> watchGroupSessions({
    required SecurityContext context,
    DateTime? startingAfter,
    DateTime? endingBefore,
    String? serviceId,
    String? providerId,
    String? locationId,
    bool publicOnly = false,
  }) {
    Query<Map<String, dynamic>> query = _businessAppointments(
      context.businessId,
    )
        .where('isGroupSession', isEqualTo: true)
        .orderBy('startTime');

    final enforcePublic = publicOnly ||
        (!context.role.canManageAllAppointments &&
            !context.role.canManageClients &&
            context.clientId != null);

    if (enforcePublic) {
      query = query.where('publicVisibility', isEqualTo: true);
    }
    if (!context.role.canManageAllAppointments &&
        context.providerId != null &&
        !enforcePublic) {
      query = query.where('providerId', isEqualTo: context.providerId);
    }
    if (startingAfter != null) {
      query = query.where(
        'startTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startingAfter),
      );
    }
    if (endingBefore != null) {
      query = query.where(
        'startTime',
        isLessThanOrEqualTo: Timestamp.fromDate(endingBefore),
      );
    }
    if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }
    if (providerId != null) {
      if (context.providerId != null &&
          !context.role.canManageAllAppointments &&
          context.providerId != providerId) {
        throw SecurityException('Cannot view other providers');
      }
      query = query.where('providerId', isEqualTo: providerId);
    }
    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    return _withAuditLogOnFirstEmission(
      stream: query.snapshots().map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => _mapAppointmentDoc(
                      doc: doc, businessId: context.businessId),
                )
                .toList(),
          ),
      context: context,
      entityType: 'Appointment',
      metadata: {
        'source': 'watchGroupSessions',
        'mode': 'list',
        'isGroupSession': true,
        'publicOnly': publicOnly,
      },
    );
  }

  /// Watch public group sessions available for registration.
  Stream<List<Appointment>> watchPublicGroupSessions({
    required SecurityContext context,
    DateTime? startingAfter,
    DateTime? endingBefore,
    String? serviceId,
    String? providerId,
    String? locationId,
  }) {
    return watchGroupSessions(
      context: context,
      startingAfter: startingAfter,
      endingBefore: endingBefore,
      serviceId: serviceId,
      providerId: providerId,
      locationId: locationId,
      publicOnly: true,
    );
  }

  /// Convenience stream of attendee metadata for a group session.
  Stream<List<GroupAttendee>> watchGroupAttendees({
    required SecurityContext context,
    required String appointmentId,
  }) {
    return _groupAttendeesRepository.watchAttendees(
      context: context,
      appointmentId: appointmentId,
    );
  }

  Future<GroupAttendee?> getGroupAttendee({
    required SecurityContext context,
    required String appointmentId,
    required String attendeeId,
  }) {
    return _groupAttendeesRepository.getAttendee(
      context: context,
      appointmentId: appointmentId,
      attendeeId: attendeeId,
    );
  }

  /// Add an attendee to a group session, enforcing capacity and registration windows.
  Future<void> addAttendeeToGroupSession({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    GroupAttendee? attendee,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('join group session');
    }
    if (!context.role.canManageClients &&
        context.clientId != null &&
        context.clientId != clientId) {
      throw SecurityException('Cannot join on behalf of another client');
    }

    await _firestore.runTransaction((txn) async {
      final ref =
          _businessAppointments(context.businessId).doc(appointmentId);
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) {
        throw SecurityException('Session not found');
      }
      final appointment = _mapAppointmentDoc(
        doc: snapshot,
        businessId: context.businessId,
      );
      if (!appointment.isGroupSession) {
        throw SecurityException('Not a group session');
      }
      final currentAttendees =
          List<String>.from(snapshot.data()?['attendeeIds'] as List? ?? []);
      if (currentAttendees.contains(clientId)) {
        throw SecurityException('Already registered for this session');
      }
      if (appointment.capacity != null &&
          currentAttendees.length >= appointment.capacity!) {
        throw SecurityException('Session is full');
      }
      final registrationDeadline = appointment.registrationDeadline;
      if (registrationDeadline != null &&
          registrationDeadline.isBefore(DateTime.now())) {
        throw SecurityException('Registration is closed');
      }
      final attendeeRecord = attendee ??
          GroupAttendee(
            id: clientId,
            clientId: clientId,
            displayName: clientId,
          );
      txn.update(ref, {
        'attendeeIds': FieldValue.arrayUnion([clientId]),
      });
      txn.set(
        ref.collection('attendees').doc(attendeeRecord.id),
        attendeeRecord.toMap(),
        SetOptions(merge: true),
      );
    });
  }

  /// Remove an attendee from a group session.
  Future<void> removeAttendeeFromGroupSession({
    required SecurityContext context,
    required String appointmentId,
    required String clientId,
    String? attendeeId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('leave group session');
    }
    if (!context.role.canManageClients &&
        context.clientId != null &&
        context.clientId != clientId) {
      throw SecurityException('Cannot modify another client');
    }
    await _firestore.runTransaction((txn) async {
      final ref = _businessAppointments(context.businessId).doc(appointmentId);
      final snapshot = await txn.get(ref);
      if (!snapshot.exists) {
        throw SecurityException('Session not found');
      }
      txn.update(ref, {
        'attendeeIds': FieldValue.arrayRemove([clientId]),
      });
      txn.set(
        ref.collection('attendees').doc(attendeeId ?? clientId),
        {
          'status': GroupAttendeeStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> updateGroupAttendeeStatuses({
    required SecurityContext context,
    required String appointmentId,
    required String attendeeId,
    GroupAttendeeStatus? status,
    PaymentStatus? paymentStatus,
    PaymentStatus? refundStatus,
  }) {
    return _groupAttendeesRepository.updateStatuses(
      context: context,
      appointmentId: appointmentId,
      attendeeId: attendeeId,
      status: status,
      paymentStatus: paymentStatus,
      refundStatus: refundStatus,
    );
  }

  /// Create a recurring appointment series (parent + all instances).
  /// Returns the parent appointment ID.
  Future<String> createRecurringAppointment({
    required SecurityContext context,
    required Appointment parentAppointment,
    required RecurrencePattern pattern,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create recurring appointment');
    }
    // Verify permissions
    if (context.clientId != null && context.clientId != parentAppointment.clientId) {
      throw SecurityException('Clients can only book for themselves');
    }
    if (context.providerId != null &&
        !context.role.canManageAllAppointments &&
        context.providerId != parentAppointment.providerId) {
      throw SecurityException('Staff can only book appointments for themselves');
    }

    // Generate all instances
    final instances = _recurrenceService.generateRecurringInstances(
      parentAppointment: parentAppointment,
      pattern: pattern,
    );

    // Check for conflicts
    final conflicts = await _recurrenceService.checkRecurrenceConflicts(
      businessId: context.businessId,
      providerId: parentAppointment.providerId,
      proposedInstances: [parentAppointment, ...instances],
    );

    if (conflicts.isNotEmpty) {
      throw Exception('Scheduling conflict detected for ${conflicts.length} instances');
    }

    // Create parent and all instances in batch
    final batch = _firestore.batch();

    final parentRef = _businessAppointments(context.businessId).doc(parentAppointment.id);
    batch.set(parentRef, parentAppointment.toJson());

    for (final instance in instances) {
      final instanceRef = _businessAppointments(context.businessId).doc(instance.id);
      batch.set(instanceRef, instance.toJson());
    }

    await batch.commit();
    return parentAppointment.id;
  }

  /// Get all instances in a recurring series
  ///
  /// Audit: Logs one `phiReadList` event when recurring series is retrieved.
  Future<List<Appointment>> getRecurringSeries({
    required SecurityContext context,
    required String recurrenceId,
  }) async {
    final series = await _recurrenceService.getRecurringSeries(
      businessId: context.businessId,
      recurrenceId: recurrenceId,
    );

    // Log PHI read list access (non-blocking)
    unawaited(_auditLogRepository.logEvent(AuditLogEntry(
      businessId: context.businessId,
      userId: context.userId,
      actionType: AuditActionType.phiReadList,
      entityType: 'Appointment',
      entityId: recurrenceId, // Parent series ID as identifier
      metadata: {
        'source': 'getRecurringSeries',
        'mode': 'list',
        'recurrenceId': recurrenceId,
        'count': series.length,
      },
    )));

    return series;
  }

  /// Update a single instance in recurring series (marks as exception)
  Future<void> updateRecurringInstance({
    required SecurityContext context,
    required Appointment instance,
    required Appointment updatedInstance,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update recurring appointment');
    }
    // Verify permissions
    if (!context.role.canManageAllAppointments) {
      if (context.clientId != null && instance.clientId != context.clientId) {
        throw SecurityException('Cannot modify other clients\' appointments');
      }
      if (context.providerId != null && instance.providerId != context.providerId) {
        throw SecurityException('Cannot modify other providers\' appointments');
      }
    }

    await _recurrenceService.updateRecurringInstance(
      businessId: context.businessId,
      instance: instance,
      updatedInstance: updatedInstance,
    );
  }

  /// Delete a single instance from recurring series
  Future<void> deleteRecurringInstance({
    required SecurityContext context,
    required String appointmentId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete recurring appointment');
    }
    // Verify access first
    final appointment = await getAppointment(
      context: context,
      appointmentId: appointmentId,
    );

    if (appointment == null) {
      throw SecurityException('Appointment not found');
    }

    await _recurrenceService.deleteRecurringInstance(
      businessId: context.businessId,
      appointmentId: appointmentId,
    );
  }

  /// Delete entire recurring series
  Future<void> deleteRecurringSeries({
    required SecurityContext context,
    required String recurrenceId,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete recurring series');
    }
    // Verify access to parent
    final parent = await getAppointment(
      context: context,
      appointmentId: recurrenceId,
    );

    if (parent == null || !parent.isRecurrenceParent) {
      throw SecurityException('Invalid recurring series');
    }

    await _recurrenceService.deleteRecurringSeries(
      businessId: context.businessId,
      recurrenceId: recurrenceId,
    );
  }

  /// Update entire recurring series with new pattern
  Future<void> updateRecurringSeries({
    required SecurityContext context,
    required Appointment parentAppointment,
    required RecurrencePattern newPattern,
  }) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('update recurring series');
    }
    // Verify permissions
    if (!context.role.canManageAllAppointments) {
      if (context.providerId != null &&
          parentAppointment.providerId != context.providerId) {
        throw SecurityException('Cannot modify other providers\' appointments');
      }
    }

    if (!parentAppointment.isRecurrenceParent) {
      throw ArgumentError('Must be the parent appointment');
    }

    await _recurrenceService.updateRecurringSeries(
      businessId: context.businessId,
      parentAppointment: parentAppointment,
      newPattern: newPattern,
    );
  }

  CollectionReference<Map<String, dynamic>> _businessAppointments(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('appointments');
  }

  Appointment _mapAppointmentDoc({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String businessId,
  }) {
    final data = doc.data() ?? {};
    return Appointment.fromJson({
      'id': doc.id,
      'businessId': businessId,
      ...data,
    });
  }

  /// Wraps a stream to log one audit event on first emission.
  ///
  /// This is used for HIPAA-compliant logging of list/stream reads,
  /// logging once per logical action rather than per document.
  Stream<List<T>> _withAuditLogOnFirstEmission<T>({
    required Stream<List<T>> stream,
    required SecurityContext context,
    required String entityType,
    required Map<String, dynamic> metadata,
  }) {
    var hasLogged = false;
    return stream.map((data) {
      if (!hasLogged) {
        hasLogged = true;
        unawaited(_auditLogRepository.logEvent(AuditLogEntry(
          businessId: context.businessId,
          userId: context.userId,
          actionType: AuditActionType.phiReadList,
          entityType: entityType,
          entityId: context.businessId, // High-level identifier for list reads
          metadata: {...metadata, 'count': data.length},
        )));
      }
      return data;
    });
  }
}
