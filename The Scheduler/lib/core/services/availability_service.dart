import 'dart:async';

import '../config/app_config.dart' show BookingPolicies;
import '../../data/models/security_context.dart';
import '../../data/repositories/availability_repository.dart';
import '../../data/repositories/appointments_repository.dart';
import 'time_slot_service.dart';

/// Describes an availability search window and desired parameters.
class AvailabilityQuery {
  const AvailabilityQuery({
    required this.start,
    required this.end,
    this.providerId,
    this.locationId,
    this.serviceDuration,
  });

  final DateTime start;
  final DateTime end;
  final String? providerId;
  final String? locationId;
  final Duration? serviceDuration;
}

/// Represents a concrete bookable slot that can be surfaced to users.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.providerId,
    required this.locationId,
    required this.start,
    required this.end,
    this.isBlocked = false,
  });

  final String providerId;
  final String locationId;
  final DateTime start;
  final DateTime end;
  final bool isBlocked;

  Duration get duration => end.difference(start);

  bool get isPast => end.isBefore(DateTime.now());
}

/// Contract for generating and streaming provider availability.
abstract class AvailabilityService {
  Stream<List<AvailabilitySlot>> watchSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  });

  Future<List<AvailabilitySlot>> generateSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  });

  Future<bool> isSlotBookable({
    required SecurityContext context,
    required AvailabilitySlot slot,
  });
}

class FirestoreAvailabilityService implements AvailabilityService {
  FirestoreAvailabilityService({
    required AvailabilityRepository availabilityRepository,
    required AppointmentsRepository appointmentsRepository,
    required BookingPolicies bookingPolicies,
  })  : _availabilityRepository = availabilityRepository,
        _appointmentsRepository = appointmentsRepository,
        _bookingPolicies = bookingPolicies,
        _timeSlotService = TimeSlotService(
          availabilityRepository: availabilityRepository,
          appointmentsRepository: appointmentsRepository,
          bookingPolicies: bookingPolicies,
        );

  final AvailabilityRepository _availabilityRepository;
  final AppointmentsRepository _appointmentsRepository;
  final BookingPolicies _bookingPolicies;
  final TimeSlotService _timeSlotService;

  @override
  Stream<List<AvailabilitySlot>> watchSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) {
    final providerId = _requireProvider(query.providerId);
    final locationId = _requireLocation(query.locationId);

    final controller = StreamController<List<AvailabilitySlot>>.broadcast();
    final subscriptions = <StreamSubscription>[];

    Future<void> emit() async {
      final slots = await generateSlots(context: context, query: query);
      if (!controller.isClosed) {
        controller.add(slots);
      }
    }

    subscriptions.add(
      _availabilityRepository
          .watchWeeklySchedules(
            context,
            providerId,
            locationId: locationId,
          )
          .listen((_) => emit()),
    );

    subscriptions.add(
      _availabilityRepository
          .watchAvailability(
            context,
            providerId,
            query.start,
            query.end,
            locationId: locationId,
          )
          .listen((_) => emit()),
    );

    subscriptions.add(
      _appointmentsRepository
          .watchAppointmentsInRange(
            context: context,
            start: query.start,
            end: query.end,
            providerId: providerId,
            locationId: locationId,
          )
          .listen((_) => emit()),
    );

    emit();

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<List<AvailabilitySlot>> generateSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) async {
    final providerId = _requireProvider(query.providerId);
    final locationId = _requireLocation(query.locationId);
    final duration = query.serviceDuration ?? _bookingPolicies.defaultSlotLength;
    final slots = <AvailabilitySlot>[];

    DateTime cursor = DateTime(query.start.year, query.start.month, query.start.day);
    final DateTime endDate = DateTime(query.end.year, query.end.month, query.end.day);

    while (!cursor.isAfter(endDate)) {
      final daySlots = await _timeSlotService.generateSlots(
        context: context,
        providerId: providerId,
        locationId: locationId,
        date: cursor,
        serviceDuration: duration,
      );

      slots.addAll(
        daySlots.map(
          (slot) => AvailabilitySlot(
            providerId: slot.providerId,
            locationId: slot.locationId,
            start: slot.startTime,
            end: slot.endTime,
            isBlocked: !slot.isAvailable,
          ),
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return slots
        .where(
          (slot) =>
              !slot.end.isBefore(query.start) && !slot.start.isAfter(query.end),
        )
        .toList();
  }

  @override
  Future<bool> isSlotBookable({
    required SecurityContext context,
    required AvailabilitySlot slot,
  }) async {
    return _timeSlotService.isSlotAvailable(
      context: context,
      providerId: slot.providerId,
      locationId: slot.locationId,
      startTime: slot.start,
      endTime: slot.end,
    );
  }

  String _requireProvider(String? providerId) {
    if (providerId == null) {
      throw ArgumentError('Availability queries require a providerId');
    }
    return providerId;
  }

  String _requireLocation(String? locationId) {
    if (locationId == null) {
      throw ArgumentError('Availability queries require a locationId');
    }
    return locationId;
  }
}

/// Lightweight mock implementation kept for tests.
class MockAvailabilityService implements AvailabilityService {
  MockAvailabilityService({this.refreshInterval = const Duration(minutes: 10)});

  final Duration refreshInterval;

  @override
  Stream<List<AvailabilitySlot>> watchSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) async* {
    while (true) {
      yield await generateSlots(context: context, query: query);
      await Future.delayed(refreshInterval);
    }
  }

  @override
  Future<List<AvailabilitySlot>> generateSlots({
    required SecurityContext context,
    required AvailabilityQuery query,
  }) async {
    final slots = <AvailabilitySlot>[];
    final duration = query.serviceDuration ?? const Duration(minutes: 60);
    final slotLength = duration;
    DateTime dayCursor = DateTime(
      query.start.year,
      query.start.month,
      query.start.day,
    );

    while (!dayCursor.isAfter(query.end)) {
      final dayStart = DateTime(
        dayCursor.year,
        dayCursor.month,
        dayCursor.day,
        8,
      );
      final dayEnd = DateTime(
        dayCursor.year,
        dayCursor.month,
        dayCursor.day,
        18,
      );
      DateTime cursor = dayStart;

      while (cursor.add(slotLength).isBefore(dayEnd)) {
        final slot = AvailabilitySlot(
          providerId: query.providerId ?? 'provider-default',
          locationId: query.locationId ?? 'location-default',
          start: cursor,
          end: cursor.add(slotLength),
          isBlocked: cursor.isBefore(DateTime.now()),
        );

        final withinRange =
            !slot.start.isBefore(query.start) && !slot.end.isAfter(query.end);

        if (withinRange && !slot.isPast) {
          slots.add(slot);
        }

        cursor = cursor.add(slotLength);
      }

      dayCursor = dayCursor.add(const Duration(days: 1));
      if (dayStart.isAfter(query.end)) break;
    }

    return slots;
  }

  @override
  Future<bool> isSlotBookable({
    required SecurityContext context,
    required AvailabilitySlot slot,
  }) async {
    return !slot.isBlocked && !slot.isPast;
  }
}
