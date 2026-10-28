import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/services/availability_service.dart';
import 'package:the_scheduler/core/services/recurrence_service.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';
import 'package:the_scheduler/data/repositories/availability_repository.dart';
import 'package:the_scheduler/data/repositories/group_attendees_repository.dart';

void main() {
  group('FirestoreAvailabilityService', () {
    late TestAvailabilityRepository availabilityRepository;
    late TestAppointmentsRepository appointmentsRepository;
    late FirestoreAvailabilityService service;
    final securityContext = SecurityContext(
      userId: 'user-1',
      businessId: 'biz-1',
      role: UserRole.owner,
    );

    setUp(() {
      availabilityRepository = TestAvailabilityRepository();
      appointmentsRepository = TestAppointmentsRepository();
      service = FirestoreAvailabilityService(
        availabilityRepository: availabilityRepository,
        appointmentsRepository: appointmentsRepository,
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(hours: 1),
          bufferBetweenAppointments: Duration(minutes: 0),
          cancellationWindow: Duration(hours: 24),
        ),
      );
    });

    test('marks slots as blocked when location is busy', () async {
      // Use a future Monday to avoid past-time blocking
      final now = DateTime.now();
      final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      final futureMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
      final targetDate = DateTime(futureMonday.year, futureMonday.month, futureMonday.day);

      availabilityRepository.weeklySchedule = WeeklySchedule(
        id: 'schedule-1',
        providerId: 'provider-1',
        locationId: 'location-1',
        dayOfWeek: DayOfWeek.monday,
        timeBlocks: [TimeBlock.fromStrings('09:00', '11:00')],
        isActive: true,
        createdAt: DateTime.now(),
      );

      appointmentsRepository.locationAppointments.add(
        Appointment(
          id: 'appt-1',
          businessId: 'business-1',
          clientId: 'client-X',
          providerId: 'provider-2',
          serviceId: 'service',
          locationId: 'location-1',
          startTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 9),
          endTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 59),
          date: targetDate,
          status: AppointmentStatus.confirmed,
          notes: null,
          createdAt: DateTime.now(),
        ),
      );

      final slots = await service.generateSlots(
        context: securityContext,
        query: AvailabilityQuery(
          start: DateTime(targetDate.year, targetDate.month, targetDate.day, 9),
          end: DateTime(targetDate.year, targetDate.month, targetDate.day, 11),
          providerId: 'provider-1',
          locationId: 'location-1',
          serviceDuration: const Duration(hours: 1),
        ),
      );

      final slotAtNine = slots.firstWhere(
        (slot) => slot.start.hour == 9 && slot.start.minute == 0,
      );
      final slotAtTen = slots.firstWhere(
        (slot) => slot.start.hour == 10 && slot.start.minute == 0,
      );

      expect(slotAtNine.isBlocked, isTrue);
      expect(slotAtTen.isBlocked, isFalse);
    });
  });
}

class TestAvailabilityRepository implements AvailabilityRepository {
  WeeklySchedule? weeklySchedule;

  @override
  Stream<List<WeeklySchedule>> watchWeeklySchedules(
    SecurityContext context,
    String providerId, {
    String? locationId,
  }) =>
      Stream.value(weeklySchedule == null ? [] : [weeklySchedule!]);

  @override
  Stream<List<Availability>> watchAvailability(
    SecurityContext context,
    String providerId,
    DateTime startDate,
    DateTime endDate, {
    String? locationId,
  }) =>
      const Stream.empty();

  @override
  Future<WeeklySchedule?> getWeeklySchedule(
    SecurityContext context,
    String providerId,
    DayOfWeek dayOfWeek, {
    String? locationId,
  }) async =>
      weeklySchedule;

  @override
  Future<List<Availability>> getAvailabilityForDate(
    SecurityContext context,
    String providerId,
    DateTime date, {
    String? locationId,
  }) async =>
      const [];

  @override
  Future<void> upsertWeeklySchedule(
    SecurityContext context,
    WeeklySchedule schedule,
  ) async => weeklySchedule = schedule;

  @override
  Future<void> upsertAvailability(
    SecurityContext context,
    Availability availability,
  ) async {}

  @override
  Future<void> deleteWeeklySchedule(
    SecurityContext context,
    String scheduleId,
  ) async {}

  @override
  Future<void> deleteAvailability(
    SecurityContext context,
    String availabilityId,
  ) async {}

  @override
  Future<void> batchCreateWeeklySchedules(
    SecurityContext context,
    List<WeeklySchedule> schedules,
  ) async {}
}

class TestAppointmentsRepository extends AppointmentsRepository {
  factory TestAppointmentsRepository() {
    final firestore = FakeFirebaseFirestore();
    final auditLogRepository = AuditLogRepository(firestore: firestore);
    return TestAppointmentsRepository._(firestore, auditLogRepository);
  }

  TestAppointmentsRepository._(
    FakeFirebaseFirestore firestore,
    AuditLogRepository auditLogRepository,
  ) : super(
          firestore: firestore,
          recurrenceService: RecurrenceService(firestore: firestore),
          groupAttendeesRepository: GroupAttendeesRepository(
            firestore: firestore,
            auditLogRepository: auditLogRepository,
          ),
          auditLogRepository: auditLogRepository,
        );

  final List<Appointment> locationAppointments = [];

  @override
  Future<List<Appointment>> loadAppointmentsInRange({
    required SecurityContext context,
    required DateTime start,
    required DateTime end,
    String? providerId,
    String? clientId,
    String? locationId,
  }) async => List.unmodifiable(locationAppointments);

  @override
  Future<List<Appointment>> getAppointmentsForDate({
    required SecurityContext context,
    required String providerId,
    required DateTime date,
  }) async => const [];
}
