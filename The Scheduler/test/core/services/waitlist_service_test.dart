import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/core/config/communication_config.dart';
import 'package:the_scheduler/core/services/availability_service.dart';
import 'package:the_scheduler/core/services/automation_service.dart';
import 'package:the_scheduler/core/services/email_service.dart';
import 'package:the_scheduler/core/services/sms_service.dart';
import 'package:the_scheduler/core/services/waitlist_service.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/models/waitlist_entry.dart';
import 'package:the_scheduler/data/repositories/communication_repository.dart';
import 'package:the_scheduler/data/repositories/waitlist_repository.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('WaitlistService', () {
    late InMemoryWaitlistRepository repository;
    late RecordingAutomationService automationService;
    late StubAvailabilityService availabilityService;
    late WaitlistService service;
    final adminContext = TestData.securityContext(role: UserRole.admin);

    setUp(() {
      repository = InMemoryWaitlistRepository();
      automationService = RecordingAutomationService();
      availabilityService = StubAvailabilityService();
      service = WaitlistService(
        waitlistRepository: repository,
        automationService: automationService,
        availabilityService: availabilityService,
        bookingPolicies: const BookingPolicies(
          defaultSlotLength: Duration(minutes: 30),
          bufferBetweenAppointments: Duration(minutes: 5),
          cancellationWindow: Duration(hours: 24),
          allowWaitlist: true,
        ),
        notificationHold: const Duration(minutes: 30),
      );
    });

    test('joinWaitlist stores VIP priority and defaults', () async {
      final entry = await service.joinWaitlist(
        context: adminContext,
        serviceId: 'svc-1',
        serviceName: 'Therapy',
        providerId: 'prov-1',
        providerName: 'Dr. Kim',
        earliestDate: DateTime.utc(2025, 12, 1),
        latestDate: DateTime.utc(2025, 12, 10),
        clientName: 'Alex',
        clientEmail: 'alex@test.com',
        notificationPreference: NotificationPreference.email,
        vip: true,
      );

      expect(repository.entries.length, 1);
      final saved = repository.entries.first;
      expect(saved.id, entry.id);
      expect(saved.status, WaitlistStatus.active);
      expect(saved.timeOfDayPreferences, [TimeOfDayPreference.anytime]);
      expect(
        saved.priorityScore,
        saved.createdAt.millisecondsSinceEpoch.toDouble() - 1000000,
      );
    });

    test('handleReleasedSlot blocks clients without permissions', () async {
      final clientContext = TestData.securityContext(
        role: UserRole.client,
        clientId: 'client-xyz',
      );

      repository.entries.add(waitlistEntry(
        id: 'entry-1',
        businessId: clientContext.businessId,
        status: WaitlistStatus.active,
        earliestDate: DateTime.utc(2025, 12, 1),
        latestDate: DateTime.utc(2025, 12, 2),
      ));

      final appointment = TestData.appointment(
        businessId: clientContext.businessId,
        providerId: 'provider-1',
        serviceId: 'service-1',
        startTime: DateTime.utc(2025, 12, 1, 9),
      );

      final notified = await service.handleReleasedSlot(
        actorContext: clientContext,
        appointment: appointment,
        slot: AvailabilitySlot(
          providerId: appointment.providerId,
          locationId: appointment.locationId,
          start: appointment.startTime,
          end: appointment.endTime,
        ),
      );

      expect(notified, isEmpty);
      expect(automationService.notifications, isEmpty);
      expect(repository.entries.first.status, WaitlistStatus.active);
    });

    test('handleReleasedSlot notifies top matches and updates status',
        () async {
      final slotStart = DateTime.utc(2025, 12, 3, 9);
      final appointment = TestData.appointment(
        businessId: adminContext.businessId,
        serviceId: 'service-1',
        providerId: 'provider-1',
        startTime: slotStart,
        endTime: slotStart.add(const Duration(hours: 1)),
      );

      // Lower priority (non-VIP)
      repository.entries.add(waitlistEntry(
        id: 'entry-regular',
        businessId: adminContext.businessId,
        serviceId: appointment.serviceId,
        providerId: appointment.providerId,
        clientName: 'Regular',
        earliestDate: DateTime.utc(2025, 12, 1),
        latestDate: DateTime.utc(2025, 12, 5),
        priorityScore: DateTime.now().millisecondsSinceEpoch.toDouble(),
        status: WaitlistStatus.active,
        timeOfDayPreferences: const [TimeOfDayPreference.morning],
      ));

      // Higher priority (VIP boost)
      repository.entries.add(waitlistEntry(
        id: 'entry-vip',
        businessId: adminContext.businessId,
        serviceId: appointment.serviceId,
        providerId: appointment.providerId,
        clientName: 'VIP',
        earliestDate: DateTime.utc(2025, 12, 1),
        latestDate: DateTime.utc(2025, 12, 5),
        priorityScore:
            DateTime.now().millisecondsSinceEpoch.toDouble() - 500000,
        status: WaitlistStatus.active,
        timeOfDayPreferences: const [TimeOfDayPreference.morning],
      ));

      final notified = await service.handleReleasedSlot(
        actorContext: adminContext,
        appointment: appointment,
        slot: AvailabilitySlot(
          providerId: appointment.providerId,
          locationId: appointment.locationId,
          start: slotStart,
          end: slotStart.add(const Duration(hours: 1)),
        ),
        maxNotifications: 2,
      );

      expect(notified.length, 2);
      expect(notified.first.clientName, 'VIP');
      expect(
        repository.entries
            .every((entry) => entry.status == WaitlistStatus.notified),
      isTrue,
      );
      expect(
        repository.entries.every(
          (entry) => entry.responseExpiresAt != null,
        ),
        isTrue,
      );
      expect(automationService.notifications.length, 2);
      expect(automationService.notifications.first.clientName, 'VIP');
    });

    test('handleReleasedSlot skips notifications when slot is no longer free',
        () async {
      availabilityService.bookable = false;
      repository.entries.add(waitlistEntry(
        id: 'entry-locked',
        businessId: adminContext.businessId,
        serviceId: 'service-locked',
        providerId: 'provider-locked',
        earliestDate: DateTime.utc(2025, 12, 1),
        latestDate: DateTime.utc(2025, 12, 5),
        status: WaitlistStatus.active,
      ));

      final appointment = TestData.appointment(
        businessId: adminContext.businessId,
        serviceId: 'service-locked',
        providerId: 'provider-locked',
      );

      final notified = await service.handleReleasedSlot(
        actorContext: adminContext,
        appointment: appointment,
        slot: AvailabilitySlot(
          providerId: appointment.providerId,
          locationId: appointment.locationId,
          start: appointment.startTime,
          end: appointment.endTime,
        ),
      );

      expect(notified, isEmpty);
      expect(automationService.notifications, isEmpty);
      expect(repository.entries.single.status, WaitlistStatus.active);
    });

    test('expireStaleEntries marks entries as expired', () async {
      final stale = waitlistEntry(
        id: 'stale',
        businessId: adminContext.businessId,
        earliestDate: DateTime.utc(2025, 10, 1),
        latestDate: DateTime.utc(2025, 10, 2),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        status: WaitlistStatus.active,
      );
      repository.entries.add(stale);

      await service.expireStaleEntries(
        context: adminContext,
        businessId: adminContext.businessId,
      );

      expect(repository.entries.first.status, WaitlistStatus.expired);
    });
  });
}

WaitlistEntry waitlistEntry({
  String id = 'entry',
  String businessId = TestData.businessId,
  String serviceId = 'service-1',
  String? providerId = 'provider-1',
  String clientName = 'Client',
  WaitlistStatus status = WaitlistStatus.active,
  DateTime? earliestDate,
  DateTime? latestDate,
  double? priorityScore,
  List<TimeOfDayPreference> timeOfDayPreferences =
      const [TimeOfDayPreference.anytime],
  DateTime? expiresAt,
}) {
  final start = earliestDate ?? TestData.testDate;
  return WaitlistEntry(
    id: id,
    businessId: businessId,
    clientName: clientName,
    serviceId: serviceId,
    providerId: providerId,
    preferredDaysOfWeek: const [],
    timeOfDayPreferences: timeOfDayPreferences,
    earliestDate: start,
    latestDate: latestDate ?? start.add(const Duration(days: 7)),
    priorityScore: priorityScore ?? start.millisecondsSinceEpoch.toDouble(),
    notificationPreference: NotificationPreference.email,
    status: status,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    expiresAt: expiresAt,
  );
}

class InMemoryWaitlistRepository extends WaitlistRepository {
  InMemoryWaitlistRepository() : super(firestore: FakeFirebaseFirestore());

  final List<WaitlistEntry> entries = [];

  @override
  Future<void> upsertEntry({
    required SecurityContext context,
    required WaitlistEntry entry,
  }) async {
    entries.removeWhere((existing) => existing.id == entry.id);
    entries.add(entry);
  }

  @override
  Future<List<WaitlistEntry>> loadEntries({
    SecurityContext? context,
    required String businessId,
    String? serviceId,
    String? providerId,
    WaitlistStatus status = WaitlistStatus.active,
    DateTime? notExpiredBefore,
  }) async {
    return entries.where((entry) {
      if (entry.businessId != businessId) return false;
      if (entry.status != status) return false;
      if (serviceId != null && entry.serviceId != serviceId) return false;
      if (providerId != null && entry.providerId != providerId) return false;
      if (notExpiredBefore != null &&
          entry.latestDate.isBefore(notExpiredBefore)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> updateStatus({
    required String businessId,
    required String entryId,
    required WaitlistStatus status,
    DateTime? lastNotifiedAt,
    DateTime? responseExpiresAt,
    DateTime? expiresAt,
  }) async {
    final index = entries.indexWhere(
      (entry) => entry.id == entryId && entry.businessId == businessId,
    );
    if (index == -1) return;

    entries[index] = entries[index].copyWith(
      status: status,
      lastNotifiedAt: lastNotifiedAt ?? entries[index].lastNotifiedAt,
      responseExpiresAt: responseExpiresAt ?? entries[index].responseExpiresAt,
      expiresAt: expiresAt ?? entries[index].expiresAt,
      updatedAt: DateTime.now(),
    );
  }
}

class RecordingAutomationService extends AutomationService {
  RecordingAutomationService()
      : super(
          emailService: MockEmailService(),
          smsService: MockSmsService(),
          communicationRepository: InMemoryCommunicationRepository(
            CommunicationConfig.defaultClinic(),
          ),
          communicationConfig: CommunicationConfig.defaultClinic(),
        );

  final List<WaitlistNotification> notifications = [];

  @override
  Future<void> notifyWaitlistSpot({
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String? clientPhone,
    required DateTime availableDate,
    required String availableTime,
    required String providerName,
    required String bookingLink,
    String? businessId,
    String? userId,
    Map<String, String>? additionalVariables,
  }) async {
    notifications.add(
      WaitlistNotification(
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        availableDate: availableDate,
        availableTime: availableTime,
        providerName: providerName,
        bookingLink: bookingLink,
      ),
    );
  }
}

class WaitlistNotification {
  WaitlistNotification({
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.availableDate,
    required this.availableTime,
    required this.providerName,
    required this.bookingLink,
  });

  final String clientId;
  final String clientName;
  final String clientEmail;
  final String? clientPhone;
  final DateTime availableDate;
  final String availableTime;
  final String providerName;
  final String bookingLink;
}

class StubAvailabilityService implements AvailabilityService {
  StubAvailabilityService({this.bookable = true});

  bool bookable;

  @override
  Future<List<AvailabilitySlot>> generateSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) async {
    return const [];
  }

  @override
  Future<bool> isSlotBookable({
    required SecurityContext context,
    required AvailabilitySlot slot,
  }) async {
    return bookable;
  }

  @override
  Stream<List<AvailabilitySlot>> watchSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) {
    return const Stream.empty();
  }
}
