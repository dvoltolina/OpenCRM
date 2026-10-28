import 'dart:developer' as developer;

import 'package:intl/intl.dart';

import '../../data/models/analytics_metrics.dart';
import '../../data/models/appointment.dart';
import '../../data/models/client.dart';
import '../../data/models/payment.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'crashlytics_service.dart';

/// Service for computing analytics metrics from repository data
class AnalyticsService {
  const AnalyticsService({
    required AppointmentsRepository appointmentsRepository,
    required ClientsRepository clientsRepository,
    required PaymentRepository paymentRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _appointmentsRepository = appointmentsRepository,
       _clientsRepository = clientsRepository,
       _paymentRepository = paymentRepository,
       _subscriptionRepository = subscriptionRepository;

  final AppointmentsRepository _appointmentsRepository;
  final ClientsRepository _clientsRepository;
  final PaymentRepository _paymentRepository;
  final SubscriptionRepository _subscriptionRepository;

  /// Compute comprehensive analytics metrics for a given date range
  Future<AnalyticsMetrics> computeMetrics({
    required SecurityContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Fetch all appointments in date range
    final appointments = await _appointmentsRepository.loadAppointmentsInRange(
      context: context,
      start: startDate,
      end: endDate,
    );
    final appointmentsById = {
      for (final appt in appointments) appt.id: appt,
    };

    // Fetch all clients
    final clients = await _clientsRepository.getClients(context);

    // Fetch subscription data (kept for future feature gating)
    await _subscriptionRepository.getSubscription(context);

    // Fetch payments linked to the appointments for revenue metrics
    final payments = await _getPaymentsForAppointments(
      context,
      appointments,
      startDate,
      endDate,
    );

    // Compute appointment metrics
    final appointmentMetrics = _computeAppointmentMetrics(appointments);

    // Compute revenue metrics
    final revenueMetrics = _computeRevenueMetrics(payments);

    // Compute client metrics
    final clientMetrics = _computeClientMetrics(
      clients,
      appointments,
      startDate,
      endDate,
    );

    // Compute provider metrics
    final providerMetrics =
        _computeProviderMetrics(appointments, payments, appointmentsById);

    // Compute service metrics
    final serviceMetrics =
        _computeServiceMetrics(appointments, payments, appointmentsById);

    // Compute time-based metrics
    final timeMetrics = _computeTimeMetrics(appointments);

    // Compute performance metrics
    final performanceMetrics = _computePerformanceMetrics(appointments);

    // Compute group session metrics
    final groupSessionMetrics = _computeGroupSessionMetrics(appointments);

    return AnalyticsMetrics(
      businessId: context.businessId,
      startDate: startDate,
      endDate: endDate,
      totalAppointments: appointmentMetrics['totalAppointments'] as int,
      confirmedAppointments: appointmentMetrics['confirmedAppointments'] as int,
      canceledAppointments: appointmentMetrics['canceledAppointments'] as int,
      completedAppointments: appointmentMetrics['completedAppointments'] as int,
      pendingAppointments: appointmentMetrics['pendingAppointments'] as int,
      noShowAppointments: appointmentMetrics['noShowAppointments'] as int,
      totalRevenueCents: revenueMetrics['totalRevenueCents'] as int,
      paidRevenueCents: revenueMetrics['paidRevenueCents'] as int,
      pendingRevenueCents: revenueMetrics['pendingRevenueCents'] as int,
      refundedRevenueCents: revenueMetrics['refundedRevenueCents'] as int,
      totalClients: clientMetrics['totalClients'] as int,
      newClients: clientMetrics['newClients'] as int,
      returningClients: clientMetrics['returningClients'] as int,
      activeClients: clientMetrics['activeClients'] as int,
      inactiveClients: clientMetrics['inactiveClients'] as int,
      appointmentsByProvider: Map<String, int>.from(
        providerMetrics['appointmentsByProvider'] as Map,
      ),
      revenueByProvider: Map<String, int>.from(
        providerMetrics['revenueByProvider'] as Map,
      ),
      appointmentsByService: Map<String, int>.from(
        serviceMetrics['appointmentsByService'] as Map,
      ),
      revenueByService: Map<String, int>.from(
        serviceMetrics['revenueByService'] as Map,
      ),
      appointmentsByDayOfWeek: Map<String, int>.from(
        timeMetrics['appointmentsByDayOfWeek'] as Map,
      ),
      appointmentsByHourOfDay: Map<int, int>.from(
        timeMetrics['appointmentsByHourOfDay'] as Map,
      ),
      appointmentsByDate: Map<String, int>.from(
        timeMetrics['appointmentsByDate'] as Map,
      ),
      averageBookingLeadDays:
          performanceMetrics['averageBookingLeadDays'] as double,
      cancellationRate: performanceMetrics['cancellationRate'] as double,
      noShowRate: performanceMetrics['noShowRate'] as double,
      utilizationRate: performanceMetrics['utilizationRate'] as double,
      totalGroupSessions: groupSessionMetrics['totalGroupSessions'] as int,
      totalGroupSessionAttendees:
          groupSessionMetrics['totalGroupSessionAttendees'] as int,
      totalGroupSessionCapacity:
          groupSessionMetrics['totalGroupSessionCapacity'] as int,
      groupSessionUtilizationRate:
          groupSessionMetrics['groupSessionUtilizationRate'] as double,
      groupSessionsByService: Map<String, int>.from(
        groupSessionMetrics['groupSessionsByService'] as Map,
      ),
      attendeesByGroupSession: Map<String, int>.from(
        groupSessionMetrics['attendeesByGroupSession'] as Map,
      ),
    );
  }

  Map<String, dynamic> _computeAppointmentMetrics(
    List<Appointment> appointments,
  ) {
    var totalAppointments = 0;
    var confirmedAppointments = 0;
    var canceledAppointments = 0;
    var completedAppointments = 0;
    var pendingAppointments = 0;
    var noShowAppointments = 0;

    for (final appointment in appointments) {
      final seats = _seatCount(appointment);
      totalAppointments += seats;
      switch (appointment.status) {
        case AppointmentStatus.confirmed:
          confirmedAppointments += seats;
          break;
        case AppointmentStatus.cancelled:
          canceledAppointments += seats;
          break;
        case AppointmentStatus.completed:
          completedAppointments += seats;
          break;
        case AppointmentStatus.pending:
          pendingAppointments += seats;
          break;
        case AppointmentStatus.noShow:
          noShowAppointments += seats;
          break;
      }
    }

    return {
      'totalAppointments': totalAppointments,
      'confirmedAppointments': confirmedAppointments,
      'canceledAppointments': canceledAppointments,
      'completedAppointments': completedAppointments,
      'pendingAppointments': pendingAppointments,
      'noShowAppointments': noShowAppointments,
    };
  }

  Map<String, dynamic> _computeRevenueMetrics(List<Payment> payments) {
    var totalRevenue = 0;
    var paidRevenue = 0;
    var pendingRevenue = 0;
    var refundedRevenue = 0;

    for (final payment in payments) {
      // Handle explicit refund records first
      if (payment.type == PaymentType.refund) {
        totalRevenue -= payment.amountCents;
        refundedRevenue += payment.amountCents;
        continue;
      }

      switch (payment.status) {
        case PaymentStatus.completed:
          totalRevenue += payment.amountCents;
          paidRevenue += payment.amountCents;
          break;
        case PaymentStatus.pending:
          totalRevenue += payment.amountCents;
          pendingRevenue += payment.amountCents;
          break;
        case PaymentStatus.refunded:
          final refundAmount = payment.refundAmountCents ?? payment.amountCents;
          totalRevenue -= refundAmount;
          refundedRevenue += refundAmount;
          break;
        case PaymentStatus.partiallyRefunded:
          final refundAmount = payment.refundAmountCents ?? 0;
          totalRevenue += payment.amountCents - refundAmount;
          paidRevenue += payment.amountCents;
          refundedRevenue += refundAmount;
          break;
        case PaymentStatus.none:
        case PaymentStatus.failed:
          break;
      }
    }

    return {
      'totalRevenueCents': totalRevenue,
      'paidRevenueCents': paidRevenue,
      'pendingRevenueCents': pendingRevenue,
      'refundedRevenueCents': refundedRevenue,
    };
  }

  Map<String, dynamic> _computeClientMetrics(
    List<Client> clients,
    List<Appointment> appointments,
    DateTime startDate,
    DateTime endDate,
  ) {
    final newClients = clients.where((c) {
      return c.createdAt.isAfter(startDate) && c.createdAt.isBefore(endDate);
    }).length;

    final activeClients = clients
        .where((c) => c.lifecycle == ClientLifecycle.active)
        .length;

    final inactiveClients = clients
        .where((c) => c.lifecycle == ClientLifecycle.inactive)
        .length;

    // Clients with more than one appointment in the range
    final clientAppointmentCounts = <String, int>{};
    for (final appt in appointments) {
      for (final participantId in _participantIds(appt)) {
        clientAppointmentCounts[participantId] =
            (clientAppointmentCounts[participantId] ?? 0) + 1;
      }
    }
    final returningClients = clientAppointmentCounts.values
        .where((count) => count > 1)
        .length;

    return {
      'totalClients': clients.length,
      'newClients': newClients,
      'returningClients': returningClients,
      'activeClients': activeClients,
      'inactiveClients': inactiveClients,
    };
  }

  Map<String, dynamic> _computeProviderMetrics(
    List<Appointment> appointments,
    List<Payment> payments,
    Map<String, Appointment> appointmentsById,
  ) {
    final appointmentsByProvider = <String, int>{};
    final revenueByProvider = <String, int>{};

    for (final appt in appointments) {
      final seatCount = _seatCount(appt);
      appointmentsByProvider[appt.providerId] =
          (appointmentsByProvider[appt.providerId] ?? 0) + seatCount;
    }

    // Map payments to providers via appointments
    for (final payment in payments) {
      final appt = appointmentsById[payment.appointmentId];
      if (appt == null) {
        _logDataIntegrityIssue(
          message: 'Orphaned payment missing appointment (provider mapping)',
          payment: payment,
        );
        continue;
      }
      final amount = _netPaymentAmount(payment);
      if (amount == 0) continue;
      revenueByProvider[appt.providerId] =
          (revenueByProvider[appt.providerId] ?? 0) + amount;
    }

    return {
      'appointmentsByProvider': appointmentsByProvider,
      'revenueByProvider': revenueByProvider,
    };
  }

  Map<String, dynamic> _computeServiceMetrics(
    List<Appointment> appointments,
    List<Payment> payments,
    Map<String, Appointment> appointmentsById,
  ) {
    final appointmentsByService = <String, int>{};
    final revenueByService = <String, int>{};

    for (final appt in appointments) {
      final seatCount = _seatCount(appt);
      appointmentsByService[appt.serviceId] =
          (appointmentsByService[appt.serviceId] ?? 0) + seatCount;
    }

    for (final payment in payments) {
      final appt = appointmentsById[payment.appointmentId];
      if (appt == null) {
        _logDataIntegrityIssue(
          message: 'Orphaned payment missing appointment (service mapping)',
          payment: payment,
        );
        continue;
      }
      final amount = _netPaymentAmount(payment);
      if (amount == 0) continue;
      revenueByService[appt.serviceId] =
          (revenueByService[appt.serviceId] ?? 0) + amount;
    }

    return {
      'appointmentsByService': appointmentsByService,
      'revenueByService': revenueByService,
    };
  }

  Map<String, dynamic> _computeTimeMetrics(List<Appointment> appointments) {
    final appointmentsByDayOfWeek = <String, int>{};
    final appointmentsByHourOfDay = <int, int>{};
    final appointmentsByDate = <String, int>{};

    final dateFormat = DateFormat('yyyy-MM-dd');
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (final appt in appointments) {
      final seatCount = _seatCount(appt);

      // Day of week
      final dayName = dayNames[appt.startTime.weekday - 1];
      appointmentsByDayOfWeek[dayName] =
          (appointmentsByDayOfWeek[dayName] ?? 0) + seatCount;

      // Hour of day
      final hour = appt.startTime.hour;
      appointmentsByHourOfDay[hour] =
          (appointmentsByHourOfDay[hour] ?? 0) + seatCount;

      // Date
      final dateStr = dateFormat.format(appt.startTime);
      appointmentsByDate[dateStr] =
          (appointmentsByDate[dateStr] ?? 0) + seatCount;
    }

    return {
      'appointmentsByDayOfWeek': appointmentsByDayOfWeek,
      'appointmentsByHourOfDay': appointmentsByHourOfDay,
      'appointmentsByDate': appointmentsByDate,
    };
  }

  Map<String, dynamic> _computePerformanceMetrics(
    List<Appointment> appointments,
  ) {
    var leadTimeSum = 0.0;
    var totalWeighted = 0;
    var canceledCount = 0;
    var noShowCount = 0;
    var completedCount = 0;

    for (final appointment in appointments) {
      final seats = _seatCount(appointment);
      totalWeighted += seats;
      leadTimeSum += appointment.startTime
              .difference(appointment.createdAt)
              .inDays
              .toDouble() *
          seats;

      switch (appointment.status) {
        case AppointmentStatus.cancelled:
          canceledCount += seats;
          break;
        case AppointmentStatus.noShow:
          noShowCount += seats;
          break;
        case AppointmentStatus.completed:
          completedCount += seats;
          break;
        case AppointmentStatus.confirmed:
        case AppointmentStatus.pending:
          break;
      }
    }

    final averageLeadDays =
        totalWeighted == 0 ? 0.0 : leadTimeSum / totalWeighted;
    final totalRelevant = completedCount + noShowCount + canceledCount;
    final cancellationRate =
        totalWeighted == 0 ? 0.0 : canceledCount / totalWeighted;
    final noShowRate = totalWeighted == 0 ? 0.0 : noShowCount / totalWeighted;
    final utilizationRate =
        totalRelevant == 0 ? 0.0 : completedCount / totalRelevant;

    return {
      'averageBookingLeadDays': averageLeadDays,
      'cancellationRate': cancellationRate,
      'noShowRate': noShowRate,
      'utilizationRate': utilizationRate,
    };
  }

  Map<String, dynamic> _computeGroupSessionMetrics(
    List<Appointment> appointments,
  ) {
    final groupSessions = appointments.where((a) => a.isGroupSession).toList();
    final totalGroupSessions = groupSessions.length;

    var totalAttendees = 0;
    var totalCapacity = 0;
    final groupSessionsByService = <String, int>{};
    final attendeesByGroupSession = <String, int>{};

    for (final session in groupSessions) {
      final attendeeCount = session.attendeeIds.length;
      totalAttendees += attendeeCount;
      totalCapacity += session.capacity ?? 0;

      // Track sessions by service
      groupSessionsByService[session.serviceId] =
          (groupSessionsByService[session.serviceId] ?? 0) + 1;

      // Track attendees by session (use service name as key for display)
      attendeesByGroupSession[session.id] = attendeeCount;
    }

    final utilizationRate = totalCapacity > 0
        ? totalAttendees / totalCapacity
        : 0.0;

    return {
      'totalGroupSessions': totalGroupSessions,
      'totalGroupSessionAttendees': totalAttendees,
      'totalGroupSessionCapacity': totalCapacity,
      'groupSessionUtilizationRate': utilizationRate,
      'groupSessionsByService': groupSessionsByService,
      'attendeesByGroupSession': attendeesByGroupSession,
    };
  }

  Future<List<Payment>> _getPaymentsForAppointments(
    SecurityContext context,
    List<Appointment> appointments,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (appointments.isEmpty) return [];
    final appointmentIds = appointments.map((a) => a.id).toList();

    final payments = await _paymentRepository.getPaymentsByAppointmentIds(
      context: context,
      appointmentIds: appointmentIds,
    );

    // Keep date filtering as a safeguard for unexpected out-of-range records.
    return payments
        .where(
          (payment) =>
              !payment.createdAt.isBefore(startDate) &&
              !payment.createdAt.isAfter(endDate),
        )
        .toList();
  }

  /// Stream of today's metrics
  Stream<AnalyticsMetrics> watchTodayMetrics(SecurityContext context) async* {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    await for (final _ in Stream.periodic(const Duration(minutes: 5))) {
      yield await computeMetrics(
        context: context,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    }
  }

  int _seatCount(Appointment appointment) {
    return _participantIds(appointment).length;
  }

  Iterable<String> _participantIds(Appointment appointment) {
    final participants = <String>{appointment.clientId};
    if (appointment.isGroupSession) {
      participants.addAll(appointment.attendeeIds);
    }
    return participants;
  }

  int _netPaymentAmount(Payment payment) {
    if (payment.type == PaymentType.refund) {
      return -payment.amountCents;
    }

    switch (payment.status) {
      case PaymentStatus.completed:
        return payment.amountCents;
      case PaymentStatus.pending:
        return payment.amountCents;
      case PaymentStatus.refunded:
        return -(payment.refundAmountCents ?? payment.amountCents);
      case PaymentStatus.partiallyRefunded:
        return payment.amountCents - (payment.refundAmountCents ?? 0);
      case PaymentStatus.none:
      case PaymentStatus.failed:
        return 0;
    }
  }

  void _logDataIntegrityIssue({
    required String message,
    Payment? payment,
  }) {
    developer.log(
      message,
      name: 'AnalyticsService',
      error: payment?.id,
    );

    if (CrashlyticsService.isAvailable) {
      CrashlyticsService.instance.recordError(
        message,
        StackTrace.current,
        reason: 'analytics_data_integrity',
        information: [
          if (payment != null) 'paymentId=${payment.id}',
          if (payment != null) 'appointmentId=${payment.appointmentId}',
        ],
        fatal: false,
      );
    }
  }
}
