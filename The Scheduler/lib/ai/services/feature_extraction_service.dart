import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/appointment.dart';
import '../../data/models/payment.dart';
import '../../data/models/security_context.dart';
import '../../data/models/service.dart';
import '../../data/repositories/appointments_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../data/repositories/clients_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/services_repository.dart';
import '../models/prediction_features.dart';

/// Service for extracting features from appointments and related data
/// for no-show prediction model input.
///
/// Features are extracted from multiple sources:
/// - Client history (past appointments, payments)
/// - Appointment details (timing, payment status)
/// - Provider statistics (historical no-show rates)
/// - Time slot patterns (day/hour patterns)
///
/// All operations respect multi-tenant isolation via [SecurityContext].
/// **HIPAA Compliance:** All PHI access is logged to AuditLogRepository.
class FeatureExtractionService {
  FeatureExtractionService({
    required AppointmentsRepository appointmentsRepository,
    required ClientsRepository clientsRepository,
    required ServicesRepository servicesRepository,
    required PaymentRepository paymentRepository,
    AuditLogRepository? auditLogRepository,
  })  : _appointmentsRepo = appointmentsRepository,
        _clientsRepo = clientsRepository,
        _servicesRepo = servicesRepository,
        _paymentRepo = paymentRepository,
        _auditLogRepository = auditLogRepository;

  final AppointmentsRepository _appointmentsRepo;
  final ClientsRepository _clientsRepo;
  final ServicesRepository _servicesRepo;
  final PaymentRepository _paymentRepo;
  final AuditLogRepository? _auditLogRepository;

  /// Cache for client statistics to avoid repeated queries
  /// Key: clientId, Value: cached stats with timestamp
  final Map<String, _CachedClientStats> _clientStatsCache = {};

  /// Cache for provider statistics
  final Map<String, _CachedProviderStats> _providerStatsCache = {};

  /// Cache for time slot statistics
  final Map<String, _CachedSlotStats> _slotStatsCache = {};

  /// Cache TTL in minutes
  static const int _cacheTtlMinutes = 5;

  /// Maximum days since last visit for new clients
  static const int _newClientDaysSinceVisit = 9999;

  /// Extract features for a single appointment
  ///
  /// **HIPAA:** Logs PHI access to audit trail.
  Future<PredictionFeatures> extractFeatures({
    required SecurityContext context,
    required Appointment appointment,
  }) async {
    // **CRITICAL: Log PHI access for HIPAA compliance**
    await _logFeatureExtraction(context, appointment.id, appointment.clientId);

    // Run all data fetches in parallel for efficiency
    final results = await Future.wait([
      _getClientStatistics(context, appointment.clientId),
      _getProviderStatistics(context, appointment.providerId),
      _servicesRepo.getService(
        context: context,
        serviceId: appointment.serviceId,
      ),
      _checkIntakeForm(context, appointment.clientId, appointment.id),
      _getSlotStatistics(
        context,
        appointment.startTime.weekday,
        appointment.startTime.hour,
      ),
      _getDayPosition(
        context,
        appointment.providerId,
        appointment.startTime,
        appointment.id,
      ),
    ]);

    final clientStats = results[0] as _ClientStatistics;
    final providerStats = results[1] as _ProviderStatistics;
    final service = results[2] as Service?;
    final hasIntakeForm = results[3] as bool;
    final slotStats = results[4] as _SlotStatistics;
    final dayPosition = results[5] as _DayPosition;

    // Calculate booking lead time (days between creation and start)
    final leadDays = appointment.startTime.difference(appointment.createdAt).inDays;
    final clampedLeadDays = leadDays.clamp(0, 365);

    // Check payment status
    final paymentCollected = appointment.paymentStatus == PaymentStatus.completed;

    return PredictionFeatures(
      // Metadata
      appointmentId: appointment.id,
      businessId: context.businessId,
      extractedAt: DateTime.now(),
      featureSchemaVersion: kFeatureSchemaVersion,

      // Client behavioral features
      clientHistoricalNoshowRate: clientStats.noshowRate,
      clientHistoricalCancelRate: clientStats.cancelRate,
      clientTotalAppointments: clientStats.totalAppointments,
      clientDaysSinceLastVisit: clientStats.daysSinceLastVisit,
      clientLifetimeValueCents: clientStats.lifetimeValueCents,
      clientLifecycleStage: clientStats.lifecycleStage,
      clientHasPaymentMethod: clientStats.hasPaymentMethod,

      // Appointment context features
      bookingLeadDays: clampedLeadDays,
      dayOfWeek: appointment.startTime.weekday,
      hourOfDay: appointment.startTime.hour,
      isRecurring: appointment.isRecurring,
      isGroupSession: appointment.isGroupSession,
      serviceDurationMinutes: service?.durationMinutes ?? 60,
      servicePriceCents: _convertPriceToCents(service?.price),
      requiresPayment: appointment.requiresPayment,
      paymentCollected: paymentCollected,
      hasIntakeForm: hasIntakeForm,

      // Provider features
      providerHistoricalNoshowRate: providerStats.noshowRate,
      providerTotalAppointments: providerStats.totalAppointments,

      // Time slot features
      slotHistoricalNoshowRate: slotStats.noshowRate,
      isFirstAppointmentOfDay: dayPosition.isFirst,
      isLastAppointmentOfDay: dayPosition.isLast,
    );
  }

  /// Extract features for multiple appointments (batch)
  /// Uses parallel processing with controlled concurrency
  Future<List<PredictionFeatures>> extractFeaturesBatch({
    required SecurityContext context,
    required List<Appointment> appointments,
  }) async {
    if (appointments.isEmpty) return [];

    // Process in batches of 10 to avoid overwhelming the database
    const batchSize = 10;
    final results = <PredictionFeatures>[];

    for (var i = 0; i < appointments.length; i += batchSize) {
      final batch = appointments.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((a) => extractFeatures(context: context, appointment: a)),
      );
      results.addAll(batchResults);
    }

    return results;
  }

  /// Clear all caches (useful for testing or when data changes significantly)
  void clearCaches() {
    _clientStatsCache.clear();
    _providerStatsCache.clear();
    _slotStatsCache.clear();
  }

  // ============ Private Methods ============

  /// Get client statistics with caching
  Future<_ClientStatistics> _getClientStatistics(
    SecurityContext context,
    String clientId,
  ) async {
    // Check cache
    final cached = _clientStatsCache[clientId];
    if (cached != null && !cached.isExpired) {
      return cached.stats;
    }

    // Fetch client details
    final client = await _clientsRepo.getClient(
      context: context,
      clientId: clientId,
    );

    // Fetch client's past appointments
    final appointments = await _appointmentsRepo.getClientAppointments(
      context: context,
      clientId: clientId,
    );

    // Filter to past appointments only (before now)
    final now = DateTime.now();
    final pastAppointments = appointments
        .where((a) => a.startTime.isBefore(now))
        .toList();

    // Calculate statistics
    final total = pastAppointments.length;
    final noshows = pastAppointments
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;
    final cancels = pastAppointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;

    // Get payment history for lifetime value
    final payments = await _paymentRepo.getClientPayments(
      context: context,
      clientId: clientId,
    );
    final lifetimeValue = payments
        .where((p) => p.status == PaymentStatus.completed)
        .fold<int>(0, (sum, p) => sum + p.amountCents);

    // Calculate days since last completed visit
    final lastVisit = _findLastCompletedVisit(pastAppointments);
    final daysSinceLastVisit = lastVisit != null
        ? now.difference(lastVisit).inDays
        : _newClientDaysSinceVisit;

    final stats = _ClientStatistics(
      noshowRate: total > 0 ? noshows / total : 0.0,
      cancelRate: total > 0 ? cancels / total : 0.0,
      totalAppointments: total,
      daysSinceLastVisit: daysSinceLastVisit,
      lifetimeValueCents: lifetimeValue,
      lifecycleStage: client?.lifecycle.name ?? 'newClient',
      hasPaymentMethod: client?.hasPaymentMethod ?? false,
    );

    // Cache the result
    _clientStatsCache[clientId] = _CachedClientStats(
      stats: stats,
      cachedAt: DateTime.now(),
    );

    return stats;
  }

  /// Get provider statistics with caching
  Future<_ProviderStatistics> _getProviderStatistics(
    SecurityContext context,
    String providerId,
  ) async {
    // Check cache
    final cached = _providerStatsCache[providerId];
    if (cached != null && !cached.isExpired) {
      return cached.stats;
    }

    // Fetch recent appointments and filter by provider
    // We look back 6 months for meaningful statistics
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    final appointments = await _appointmentsRepo.loadAppointmentsInRange(
      context: context,
      start: sixMonthsAgo,
      end: now,
    );

    // Filter to this provider's past appointments
    final providerAppointments = appointments
        .where((a) => a.providerId == providerId && a.startTime.isBefore(now))
        .toList();

    final total = providerAppointments.length;
    final noshows = providerAppointments
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;

    final stats = _ProviderStatistics(
      noshowRate: total > 0 ? noshows / total : 0.0,
      totalAppointments: total,
    );

    // Cache the result
    _providerStatsCache[providerId] = _CachedProviderStats(
      stats: stats,
      cachedAt: DateTime.now(),
    );

    return stats;
  }

  /// Get time slot statistics (day + hour combination)
  Future<_SlotStatistics> _getSlotStatistics(
    SecurityContext context,
    int dayOfWeek,
    int hourOfDay,
  ) async {
    final cacheKey = '$dayOfWeek-$hourOfDay';

    // Check cache
    final cached = _slotStatsCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.stats;
    }

    // For slot statistics, we fetch recent appointments and filter
    // We look back 6 months for meaningful statistics
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    final appointments = await _appointmentsRepo.loadAppointmentsInRange(
      context: context,
      start: sixMonthsAgo,
      end: now,
    );

    // Filter to appointments at the same day of week and hour
    final matchingSlots = appointments.where((a) =>
        a.startTime.isBefore(now) &&
        a.startTime.weekday == dayOfWeek &&
        a.startTime.hour == hourOfDay);

    final total = matchingSlots.length;
    final noshows = matchingSlots
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;

    final stats = _SlotStatistics(
      // Only use rate if we have enough data points (>5)
      noshowRate: total > 5 ? noshows / total : 0.0,
      totalAppointments: total,
    );

    // Cache the result
    _slotStatsCache[cacheKey] = _CachedSlotStats(
      stats: stats,
      cachedAt: DateTime.now(),
    );

    return stats;
  }

  /// Check if appointment is first or last of the provider's day
  Future<_DayPosition> _getDayPosition(
    SecurityContext context,
    String providerId,
    DateTime appointmentTime,
    String appointmentId,
  ) async {
    // Get all appointments for this provider on this day
    final dayStart = DateTime(
      appointmentTime.year,
      appointmentTime.month,
      appointmentTime.day,
    );

    final appointments = await _appointmentsRepo.getAppointmentsForDate(
      context: context,
      providerId: providerId,
      date: dayStart,
    );

    if (appointments.isEmpty) {
      return const _DayPosition(isFirst: true, isLast: true);
    }

    // Sort by start time
    appointments.sort((a, b) => a.startTime.compareTo(b.startTime));

    final isFirst = appointments.first.id == appointmentId;
    final isLast = appointments.last.id == appointmentId;

    return _DayPosition(isFirst: isFirst, isLast: isLast);
  }

  /// Check if client has submitted an intake form for this appointment
  /// Note: This is a simplified check. Full implementation would require
  /// querying intake form submissions by appointmentId.
  /// For now, returns false (conservative default) as intake form is a low-weight feature.
  Future<bool> _checkIntakeForm(
    SecurityContext context,
    String clientId,
    String appointmentId,
  ) async {
    // TODO: Implement proper intake form submission check by appointmentId
    // The current IntakeFormRepository doesn't support querying by appointmentId
    // For now, return false as this is a low-weight feature (Weight: Low in spec)
    // This will be enhanced when intake form submissions are linked to appointments
    return false;
  }

  /// Find the date of the last completed appointment
  DateTime? _findLastCompletedVisit(List<Appointment> appointments) {
    DateTime? latest;
    for (final apt in appointments) {
      if (apt.status == AppointmentStatus.completed) {
        if (latest == null || apt.startTime.isAfter(latest)) {
          latest = apt.startTime;
        }
      }
    }
    return latest;
  }

  /// Convert price (which may be in dollars) to cents
  int _convertPriceToCents(double? price) {
    if (price == null) return 0;
    // Assume price is in dollars, convert to cents
    return (price * 100).round();
  }

  /// Log feature extraction for HIPAA compliance.
  Future<void> _logFeatureExtraction(
    SecurityContext context,
    String appointmentId,
    String clientId,
  ) async {
    if (_auditLogRepository == null) return;

    try {
      await _auditLogRepository.log(
        context: context,
        action: 'ai_feature_extraction_read',
        entityType: 'client',
        entityId: clientId,
        details: {
          'appointment_id': appointmentId,
          'operation': 'feature_extraction',
        },
        source: 'FeatureExtractionService',
      );
    } catch (e) {
      // Don't fail feature extraction if audit logging fails
      debugPrint('FeatureExtractionService: Failed to log audit: $e');
    }
  }
}

// ============ Private Helper Classes ============

/// Internal class for cached client statistics
class _ClientStatistics {
  const _ClientStatistics({
    required this.noshowRate,
    required this.cancelRate,
    required this.totalAppointments,
    required this.daysSinceLastVisit,
    required this.lifetimeValueCents,
    required this.lifecycleStage,
    required this.hasPaymentMethod,
  });

  final double noshowRate;
  final double cancelRate;
  final int totalAppointments;
  final int daysSinceLastVisit;
  final int lifetimeValueCents;
  final String lifecycleStage;
  final bool hasPaymentMethod;
}

/// Cache wrapper for client statistics
class _CachedClientStats {
  _CachedClientStats({
    required this.stats,
    required this.cachedAt,
  });

  final _ClientStatistics stats;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inMinutes >
      FeatureExtractionService._cacheTtlMinutes;
}

/// Internal class for provider statistics
class _ProviderStatistics {
  const _ProviderStatistics({
    required this.noshowRate,
    required this.totalAppointments,
  });

  final double noshowRate;
  final int totalAppointments;
}

/// Cache wrapper for provider statistics
class _CachedProviderStats {
  _CachedProviderStats({
    required this.stats,
    required this.cachedAt,
  });

  final _ProviderStatistics stats;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inMinutes >
      FeatureExtractionService._cacheTtlMinutes;
}

/// Internal class for time slot statistics
class _SlotStatistics {
  const _SlotStatistics({
    required this.noshowRate,
    required this.totalAppointments,
  });

  final double noshowRate;
  final int totalAppointments;
}

/// Cache wrapper for slot statistics
class _CachedSlotStats {
  _CachedSlotStats({
    required this.stats,
    required this.cachedAt,
  });

  final _SlotStatistics stats;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inMinutes >
      FeatureExtractionService._cacheTtlMinutes;
}

/// Position of appointment in provider's day
class _DayPosition {
  const _DayPosition({
    required this.isFirst,
    required this.isLast,
  });

  final bool isFirst;
  final bool isLast;
}

