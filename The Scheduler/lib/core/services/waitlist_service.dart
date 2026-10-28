import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../data/models/appointment.dart';
import '../../data/models/security_context.dart';
import '../../data/models/waitlist_entry.dart';
import '../../data/repositories/waitlist_repository.dart';
import 'automation_service.dart';
import 'availability_service.dart';

/// Handles waitlist registration, matching, and notification workflows.
class WaitlistService {
  WaitlistService({
    required this.waitlistRepository,
    required this.automationService,
    required this.availabilityService,
    required BookingPolicies bookingPolicies,
    Duration? notificationHold,
    this.bookingLinkBuilder,
    this.handleReleasedSlotUrl,
    this.notifyWaitlistEntryUrl,
    http.Client? httpClient,
  })  : _bookingPolicies = bookingPolicies,
        responseWindow = notificationHold ?? const Duration(hours: 2),
        _httpClient = httpClient ?? http.Client();

  final WaitlistRepository waitlistRepository;
  final AutomationService automationService;
  final AvailabilityService availabilityService;
  final BookingPolicies _bookingPolicies;
  final Duration responseWindow;
  final String Function(WaitlistEntry entry, AvailabilitySlot slot)?
      bookingLinkBuilder;
  final String? handleReleasedSlotUrl;
  final String? notifyWaitlistEntryUrl;
  final http.Client _httpClient;

  static const _uuid = Uuid();

  /// Registers a new waitlist entry for the given business.
  Future<WaitlistEntry> joinWaitlist({
    required SecurityContext context,
    required String serviceId,
    required String serviceName,
    String? providerId,
    String? providerName,
    String? locationId,
    required DateTime earliestDate,
    required DateTime latestDate,
    List<int> preferredDays = const [],
    List<TimeOfDayPreference> timeOfDayPreferences = const [],
    required String clientName,
    String? clientId,
    String? clientEmail,
    String? clientPhone,
    NotificationPreference notificationPreference =
        NotificationPreference.email,
    String? notes,
    bool vip = false,
    double? manualPriorityBoost,
  }) async {
    final now = DateTime.now();
    final score = _computePriorityScore(now, vip, manualPriorityBoost);

    final entry = WaitlistEntry(
      id: _uuid.v4(),
      businessId: context.businessId,
      clientId: clientId ?? context.clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      serviceId: serviceId,
      serviceName: serviceName,
      providerId: providerId,
      providerName: providerName,
      locationId: locationId,
      preferredDaysOfWeek: preferredDays,
      timeOfDayPreferences: timeOfDayPreferences.isNotEmpty
          ? timeOfDayPreferences
          : const [TimeOfDayPreference.anytime],
      earliestDate: earliestDate,
      latestDate: latestDate,
      priorityScore: score,
      notificationPreference: notificationPreference,
      status: WaitlistStatus.active,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      expiresAt: _bookingPolicies.maximumAdvanceBooking != null
          ? now.add(_bookingPolicies.maximumAdvanceBooking!)
          : null,
    );

    await waitlistRepository.upsertEntry(context: context, entry: entry);
    return entry;
  }

  /// Runs matching logic when a slot is released (e.g., cancellation).
  ///
  /// Only staff/admin contexts are allowed to trigger notifications. When a
  /// client initiates a cancellation, the call is ignored to avoid exposing
  /// other waitlist entries; a server-side listener should re-run matching with
  /// elevated privileges.
  Future<List<WaitlistEntry>> handleReleasedSlot({
    SecurityContext? actorContext,
    required Appointment appointment,
    required AvailabilitySlot slot,
    int maxNotifications = 3,
  }) async {
    if (handleReleasedSlotUrl != null) {
      final succeeded = await _postHandleReleasedSlot(
        context: actorContext,
        appointment: appointment,
        slot: slot,
        maxNotifications: maxNotifications,
      );
      if (succeeded) {
        return const [];
      }
    }

    if (actorContext != null &&
        !actorContext.role.canManageClients &&
        !actorContext.role.canManageAllAppointments) {
      return [];
    }

    if (!_bookingPolicies.allowWaitlist) return [];

    if (actorContext != null) {
      final stillAvailable = await availabilityService.isSlotBookable(
        context: actorContext,
        slot: slot,
      );
      if (!stillAvailable) return [];
    }

    final entries = await waitlistRepository.loadEntries(
      context: actorContext,
      businessId: appointment.businessId,
      serviceId: appointment.serviceId,
      providerId: appointment.providerId,
      status: WaitlistStatus.active,
      notExpiredBefore: DateTime.now(),
    );

    final matches = entries
        .where(
          (entry) =>
              (entry.providerId == null ||
                  entry.providerId == appointment.providerId) &&
              entry.matchesSlot(slot.start),
        )
        .toList()
      ..sort((a, b) {
        final primary = a.priorityScore.compareTo(b.priorityScore);
        if (primary != 0) return primary;
        return a.createdAt.compareTo(b.createdAt);
      });

    final now = DateTime.now();
    final notified = <WaitlistEntry>[];
    final toNotify = matches.take(maxNotifications);

    for (final entry in toNotify) {
      final responseExpiresAt = now.add(responseWindow);
      final bookingLink = bookingLinkBuilder?.call(entry, slot) ??
          'https://example.com/book?waitlist=${entry.id}';

      await automationService.notifyWaitlistSpot(
        clientId: entry.clientId ?? entry.id,
        clientName: entry.clientName,
        clientEmail: entry.clientEmail ?? '',
        clientPhone: entry.clientPhone,
        availableDate: slot.start,
        availableTime:
            '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}',
        providerName: entry.providerName ?? 'Preferred provider',
        bookingLink: bookingLink,
      );

      await waitlistRepository.updateStatus(
        businessId: entry.businessId,
        entryId: entry.id,
        status: WaitlistStatus.notified,
        lastNotifiedAt: now,
        responseExpiresAt: responseExpiresAt,
      );

      notified.add(
        entry.copyWith(
          status: WaitlistStatus.notified,
          lastNotifiedAt: now,
          responseExpiresAt: responseExpiresAt,
        ),
      );
    }

    return notified;
  }

  /// Marks an entry as converted after the customer books the released slot.
  Future<void> markConverted(WaitlistEntry entry) async {
    await waitlistRepository.updateStatus(
      businessId: entry.businessId,
      entryId: entry.id,
      status: WaitlistStatus.converted,
      expiresAt: DateTime.now(),
    );
  }

  /// Expires entries that are past their requested window.
  Future<void> expireStaleEntries({
    SecurityContext? context,
    required String businessId,
  }) async {
    final now = DateTime.now();
    final activeEntries = await waitlistRepository.loadEntries(
      context: context,
      businessId: businessId,
      status: WaitlistStatus.active,
    );

    for (final entry in activeEntries) {
      if (entry.expiresAt != null && entry.expiresAt!.isBefore(now)) {
        await waitlistRepository.updateStatus(
          businessId: entry.businessId,
          entryId: entry.id,
          status: WaitlistStatus.expired,
          expiresAt: entry.expiresAt,
        );
      }
    }
  }

  Future<void> notifyEntry({
    required String businessId,
    required String entryId,
    required String message,
    required String channel,
    SecurityContext? actorContext,
    String? subject,
  }) async {
    if (notifyWaitlistEntryUrl == null) return;

    try {
      await _httpClient.post(
        Uri.parse(notifyWaitlistEntryUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': businessId,
          'entryId': entryId,
          'message': message,
          'channel': channel,
          'subject': subject,
          'userId': actorContext?.userId,
        }),
      );
    } catch (error) {
      // Surface to console but do not break flow for the caller
      // because this is a best-effort notification.
      developer.log(
        'Waitlist notify entry error',
        name: 'WaitlistService',
        error: error,
      );
    }
  }

  double _computePriorityScore(
    DateTime createdAt,
    bool vip,
    double? manualBoost,
  ) {
    // Lower score = higher priority. Older entries and VIPs bubble up first.
    var score = createdAt.millisecondsSinceEpoch.toDouble();
    if (vip) {
      score -= 1000000;
    }
    if (manualBoost != null) {
      score -= manualBoost;
    }
    return score;
  }

  Future<bool> _postHandleReleasedSlot({
    required SecurityContext? context,
    required Appointment appointment,
    required AvailabilitySlot slot,
    required int maxNotifications,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(handleReleasedSlotUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': appointment.businessId,
          'userId': context?.userId,
          'providerId': appointment.providerId,
          'serviceId': appointment.serviceId,
          'locationId': appointment.locationId,
          'startTime': slot.start.toIso8601String(),
          'endTime': slot.end.toIso8601String(),
          'maxNotifications': maxNotifications,
          'bookingLink': bookingLinkBuilder?.call(
            WaitlistEntry(
              id: '',
              businessId: appointment.businessId,
              clientName: '',
              serviceId: appointment.serviceId,
              earliestDate: slot.start,
              latestDate: slot.end,
              priorityScore: 0,
              notificationPreference: NotificationPreference.email,
              status: WaitlistStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            slot,
          ),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      developer.log(
        'Waitlist remote handleReleasedSlot error',
        name: 'WaitlistService',
        error: error,
      );
    }
    return false;
  }
}
