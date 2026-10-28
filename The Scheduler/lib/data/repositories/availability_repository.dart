import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import '../../core/config/demo_config.dart';
import '../../core/services/demo_guard_service.dart';

/// Repository for managing provider availability and weekly schedules.
/// Enforces multi-tenant isolation and RBAC permissions.
abstract class AvailabilityRepository {
  /// Watch weekly schedules for a provider
  Stream<List<WeeklySchedule>> watchWeeklySchedules(
    SecurityContext context,
    String providerId, {
    String? locationId,
  });

  /// Watch one-time availability blocks for a provider in a date range
  Stream<List<Availability>> watchAvailability(
    SecurityContext context,
    String providerId,
    DateTime startDate,
    DateTime endDate, {
    String? locationId,
  });

  /// Get weekly schedule for a specific day
  Future<WeeklySchedule?> getWeeklySchedule(
    SecurityContext context,
    String providerId,
    DayOfWeek dayOfWeek, {
    String? locationId,
  });

  /// Get all availability blocks for a provider on a specific date
  Future<List<Availability>> getAvailabilityForDate(
    SecurityContext context,
    String providerId,
    DateTime date, {
    String? locationId,
  });

  /// Create or update weekly schedule
  Future<void> upsertWeeklySchedule(
    SecurityContext context,
    WeeklySchedule schedule,
  );

  /// Create or update one-time availability block
  Future<void> upsertAvailability(
    SecurityContext context,
    Availability availability,
  );

  /// Delete weekly schedule
  Future<void> deleteWeeklySchedule(SecurityContext context, String scheduleId);

  /// Delete availability block
  Future<void> deleteAvailability(
    SecurityContext context,
    String availabilityId,
  );

  /// Batch create multiple weekly schedules (useful for onboarding)
  Future<void> batchCreateWeeklySchedules(
    SecurityContext context,
    List<WeeklySchedule> schedules,
  );
}

/// Firestore implementation of AvailabilityRepository
class FirestoreAvailabilityRepository implements AvailabilityRepository {
  final FirebaseFirestore _firestore;

  FirestoreAvailabilityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<WeeklySchedule> _weeklySchedulesCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('weekly_schedules')
        .withConverter<WeeklySchedule>(
          fromFirestore: (snapshot, _) =>
              WeeklySchedule.fromJson(snapshot.data()!),
          toFirestore: (schedule, _) => schedule.toJson(),
        );
  }

  CollectionReference<Availability> _availabilityCollection(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('availability')
        .withConverter<Availability>(
          fromFirestore: (snapshot, _) =>
              Availability.fromJson(snapshot.data()!),
          toFirestore: (availability, _) => availability.toJson(),
        );
  }

  @override
  Stream<List<WeeklySchedule>> watchWeeklySchedules(
    SecurityContext context,
    String providerId, {
    String? locationId,
  }) {
    context.verifyBusinessAccess();

    Query<WeeklySchedule> query = _weeklySchedulesCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('isActive', isEqualTo: true);

    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  @override
  Stream<List<Availability>> watchAvailability(
    SecurityContext context,
    String providerId,
    DateTime startDate,
    DateTime endDate, {
    String? locationId,
  }) {
    context.verifyBusinessAccess();

    Query<Availability> query = _availabilityCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('startTime', isGreaterThanOrEqualTo: startDate)
        .where('startTime', isLessThanOrEqualTo: endDate);

    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  @override
  Future<WeeklySchedule?> getWeeklySchedule(
    SecurityContext context,
    String providerId,
    DayOfWeek dayOfWeek, {
    String? locationId,
  }) async {
    context.verifyBusinessAccess();

    Query<WeeklySchedule> query = _weeklySchedulesCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('dayOfWeek', isEqualTo: dayOfWeek.name)
        .where('isActive', isEqualTo: true);

    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    final snapshot = await query.limit(1).get();

    return snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
  }

  @override
  Future<List<Availability>> getAvailabilityForDate(
    SecurityContext context,
    String providerId,
    DateTime date, {
    String? locationId,
  }) async {
    context.verifyBusinessAccess();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    Query<Availability> query = _availabilityCollection(context.businessId)
        .where('providerId', isEqualTo: providerId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThanOrEqualTo: endOfDay);

    if (locationId != null) {
      query = query.where('locationId', isEqualTo: locationId);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> upsertWeeklySchedule(
    SecurityContext context,
    WeeklySchedule schedule,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save weekly schedule');
    }
    context.verifyBusinessAccess();

    // Only admin/staff can manage schedules
    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions to manage schedules');
    }

    // Staff can only manage their own schedule
    if (context.role == UserRole.staff &&
        context.providerId != schedule.providerId) {
      throw SecurityException('Staff can only manage their own schedule');
    }

    final doc = _weeklySchedulesCollection(context.businessId).doc(schedule.id);
    await doc.set(schedule.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> upsertAvailability(
    SecurityContext context,
    Availability availability,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('save availability');
    }
    context.verifyBusinessAccess();

    // Only admin/staff can manage availability
    if (!context.role.canManageOwnSchedule) {
      throw SecurityException(
        'Insufficient permissions to manage availability',
      );
    }

    // Staff can only manage their own availability
    if (context.role == UserRole.staff &&
        context.providerId != availability.providerId) {
      throw SecurityException('Staff can only manage their own availability');
    }

    final doc = _availabilityCollection(
      context.businessId,
    ).doc(availability.id);
    await doc.set(availability.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteWeeklySchedule(
    SecurityContext context,
    String scheduleId,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete weekly schedule');
    }
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions to delete schedules');
    }

    // Get the schedule to verify ownership for staff
    final doc = await _weeklySchedulesCollection(
      context.businessId,
    ).doc(scheduleId).get();

    if (!doc.exists) {
      return; // Already deleted or doesn't exist
    }

    final schedule = doc.data()!;

    // Staff can only delete their own schedule
    if (context.role == UserRole.staff &&
        context.providerId != schedule.providerId) {
      throw SecurityException('Staff can only delete their own schedule');
    }

    await doc.reference.delete();
  }

  @override
  Future<void> deleteAvailability(
    SecurityContext context,
    String availabilityId,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('delete availability');
    }
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException(
        'Insufficient permissions to delete availability',
      );
    }

    // Get the availability to verify ownership for staff
    final doc = await _availabilityCollection(
      context.businessId,
    ).doc(availabilityId).get();

    if (!doc.exists) {
      return; // Already deleted or doesn't exist
    }

    final availability = doc.data()!;

    // Staff can only delete their own availability
    if (context.role == UserRole.staff &&
        context.providerId != availability.providerId) {
      throw SecurityException('Staff can only delete their own availability');
    }

    await doc.reference.delete();
  }

  @override
  Future<void> batchCreateWeeklySchedules(
    SecurityContext context,
    List<WeeklySchedule> schedules,
  ) async {
    if (DemoConfig.isDemoMode) {
      DemoGuardService.blockWrite('create weekly schedules');
    }
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException(
        'Insufficient permissions to create weekly schedules',
      );
    }

    // Staff can only create their own schedules
    if (context.role == UserRole.staff) {
      for (final schedule in schedules) {
        if (context.providerId != schedule.providerId) {
          throw SecurityException('Staff can only create their own schedules');
        }
      }
    }

    final batch = _firestore.batch();
    final collection = _weeklySchedulesCollection(context.businessId);

    for (final schedule in schedules) {
      final doc = collection.doc(schedule.id);
      batch.set(doc, schedule);
    }

    await batch.commit();
  }
}

/// Mock implementation for testing
class MockAvailabilityRepository implements AvailabilityRepository {
  final Map<String, List<WeeklySchedule>> _weeklySchedules = {};
  final Map<String, List<Availability>> _availability = {};

  @override
  Stream<List<WeeklySchedule>> watchWeeklySchedules(
    SecurityContext context,
    String providerId, {
    String? locationId,
  }) {
    context.verifyBusinessAccess();

    final key = '${context.businessId}:$providerId:${locationId ?? 'all'}';
    return Stream.value(_weeklySchedules[key] ?? []);
  }

  @override
  Stream<List<Availability>> watchAvailability(
    SecurityContext context,
    String providerId,
    DateTime startDate,
    DateTime endDate, {
    String? locationId,
  }) {
    context.verifyBusinessAccess();

    final key = '${context.businessId}:$providerId:${locationId ?? 'all'}';
    final all = _availability[key] ?? [];
    final filtered = all.where((a) {
      return a.startTime.isAfter(startDate) && a.startTime.isBefore(endDate);
    }).toList();

    return Stream.value(filtered);
  }

  @override
  Future<WeeklySchedule?> getWeeklySchedule(
    SecurityContext context,
    String providerId,
    DayOfWeek dayOfWeek, {
    String? locationId,
  }) async {
    context.verifyBusinessAccess();

    final key = '${context.businessId}:$providerId:${locationId ?? 'all'}';
    final schedules = _weeklySchedules[key] ?? [];

    return schedules.firstWhere(
      (s) => s.dayOfWeek == dayOfWeek && s.isActive,
      orElse: () => throw StateError('No schedule found'),
    );
  }

  @override
  Future<List<Availability>> getAvailabilityForDate(
    SecurityContext context,
    String providerId,
    DateTime date, {
    String? locationId,
  }) async {
    context.verifyBusinessAccess();

    final key = '${context.businessId}:$providerId:${locationId ?? 'all'}';
    final all = _availability[key] ?? [];

    return all.where((a) => a.isOnDate(date)).toList();
  }

  @override
  Future<void> upsertWeeklySchedule(
    SecurityContext context,
    WeeklySchedule schedule,
  ) async {
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions');
    }

    final key =
        '${context.businessId}:${schedule.providerId}:${schedule.locationId}';
    final schedules = _weeklySchedules[key] ?? [];

    final index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }

    _weeklySchedules[key] = schedules;
  }

  @override
  Future<void> upsertAvailability(
    SecurityContext context,
    Availability availability,
  ) async {
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions');
    }

    final key =
        '${context.businessId}:${availability.providerId}:${availability.locationId}';
    final all = _availability[key] ?? [];

    final index = all.indexWhere((a) => a.id == availability.id);
    if (index >= 0) {
      all[index] = availability;
    } else {
      all.add(availability);
    }

    _availability[key] = all;
  }

  @override
  Future<void> deleteWeeklySchedule(
    SecurityContext context,
    String scheduleId,
  ) async {
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions');
    }

    _weeklySchedules.forEach((key, schedules) {
      schedules.removeWhere((s) => s.id == scheduleId);
    });
  }

  @override
  Future<void> deleteAvailability(
    SecurityContext context,
    String availabilityId,
  ) async {
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions');
    }

    _availability.forEach((key, all) {
      all.removeWhere((a) => a.id == availabilityId);
    });
  }

  @override
  Future<void> batchCreateWeeklySchedules(
    SecurityContext context,
    List<WeeklySchedule> schedules,
  ) async {
    context.verifyBusinessAccess();

    if (!context.role.canManageOwnSchedule) {
      throw SecurityException('Insufficient permissions');
    }

    for (final schedule in schedules) {
      await upsertWeeklySchedule(context, schedule);
    }
  }
}
