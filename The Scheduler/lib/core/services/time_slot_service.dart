import 'package:the_scheduler/core/config/app_config.dart';
import 'package:the_scheduler/data/models/appointment.dart';
import 'package:the_scheduler/data/models/availability.dart';
import 'package:the_scheduler/data/models/provider.dart';
import 'package:the_scheduler/data/models/security_context.dart';
import 'package:the_scheduler/data/repositories/appointments_repository.dart';
import 'package:the_scheduler/data/repositories/availability_repository.dart';

/// Represents a bookable time slot
class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final String providerId;
  final String locationId;
  final bool isAvailable;
  final String? unavailableReason;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.providerId,
    required this.locationId,
    this.isAvailable = true,
    this.unavailableReason,
  });

  Duration get duration => endTime.difference(startTime);

  @override
  String toString() {
    return 'TimeSlot(${startTime.toString()} - ${endTime.toString()}, '
        'provider: $providerId, available: $isAvailable)';
  }
}

/// Service for generating available booking slots based on:
/// - Provider availability (weekly schedules and one-time blocks)
/// - Service duration
/// - Buffer times (from BookingPolicies)
/// - Existing appointments
/// - Multi-provider conflicts for shared resources
class TimeSlotService {
  final AvailabilityRepository availabilityRepository;
  final AppointmentsRepository appointmentsRepository;
  final BookingPolicies bookingPolicies;

  TimeSlotService({
    required this.availabilityRepository,
    required this.appointmentsRepository,
    required this.bookingPolicies,
  });

  /// Generate available time slots for a provider on a specific date
  Future<List<TimeSlot>> generateSlots({
    required SecurityContext context,
    required String providerId,
    required String locationId,
    required DateTime date,
    required Duration serviceDuration,
  }) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final dayOfWeek = DayOfWeek.fromDateTime(targetDate);
    final weeklySchedule = await availabilityRepository.getWeeklySchedule(
      context,
      providerId,
      dayOfWeek,
      locationId: locationId,
    );

    final oneTimeBlocks = await availabilityRepository.getAvailabilityForDate(
      context,
      providerId,
      targetDate,
      locationId: locationId,
    );

    final providerAppointments = await appointmentsRepository
        .getAppointmentsForDate(
          context: context,
          providerId: providerId,
          date: targetDate,
        );

    final locationAppointments = await appointmentsRepository
        .loadAppointmentsInRange(
          context: context,
          start: startOfDay,
          end: endOfDay,
          locationId: locationId,
        );

    List<TimeSlot> slots = [];

    if (weeklySchedule != null) {
      for (final timeBlock in weeklySchedule.timeBlocks) {
        final blockStart = timeBlock.toStartDateTime(targetDate);
        final blockEnd = timeBlock.toEndDateTime(targetDate);

        slots.addAll(
          _generateSlotsInRange(
            startTime: blockStart,
            endTime: blockEnd,
            slotDuration: serviceDuration,
            buffer: bookingPolicies.bufferBetweenAppointments,
            providerId: providerId,
            locationId: locationId,
          ),
        );
      }
    }

    for (final block in oneTimeBlocks) {
      if (block.type == AvailabilityType.available) {
        slots.addAll(
          _generateSlotsInRange(
            startTime: block.startTime,
            endTime: block.endTime,
            slotDuration: serviceDuration,
            buffer: bookingPolicies.bufferBetweenAppointments,
            providerId: providerId,
            locationId: locationId,
          ),
        );
      } else if (block.type == AvailabilityType.blocked) {
        slots = slots.where((slot) {
          return !_overlaps(
            slot.startTime,
            slot.endTime,
            block.startTime,
            block.endTime,
          );
        }).toList();
      }
    }

    slots = _markAppointmentConflicts(
      slots: slots,
      providerAppointments: providerAppointments,
      locationAppointments: locationAppointments,
      providerId: providerId,
    );

    slots = _applyBookingPolicies(slots, targetDate);
    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  /// Generate slots for multiple providers (useful for showing availability across team)
  Future<Map<String, List<TimeSlot>>> generateSlotsForProviders({
    required SecurityContext context,
    required List<Provider> providers,
    required String locationId,
    required DateTime date,
    required Duration serviceDuration,
  }) async {
    final result = <String, List<TimeSlot>>{};

    for (final provider in providers) {
      final slots = await generateSlots(
        context: context,
        providerId: provider.id,
        locationId: locationId,
        date: date,
        serviceDuration: serviceDuration,
      );
      result[provider.id] = slots;
    }

    return result;
  }

  /// Find the next available slot for a provider starting from a given date
  Future<TimeSlot?> findNextAvailableSlot({
    required SecurityContext context,
    required String providerId,
    required String locationId,
    required DateTime startDate,
    required Duration serviceDuration,
    int maxDaysToSearch = 30,
  }) async {
    for (int dayOffset = 0; dayOffset < maxDaysToSearch; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      final slots = await generateSlots(
        context: context,
        providerId: providerId,
        locationId: locationId,
        date: date,
        serviceDuration: serviceDuration,
      );

      final availableSlot = slots.firstWhere(
        (slot) => slot.isAvailable,
        orElse: () => TimeSlot(
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          providerId: providerId,
          locationId: locationId,
          isAvailable: false,
        ),
      );

      if (availableSlot.isAvailable) {
        return availableSlot;
      }
    }

    return null; // No available slots found
  }

  /// Check if a specific time slot is available
  Future<bool> isSlotAvailable({
    required SecurityContext context,
    required String providerId,
    required String locationId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final date = DateTime(startTime.year, startTime.month, startTime.day);
    final serviceDuration = endTime.difference(startTime);

    final slots = await generateSlots(
      context: context,
      providerId: providerId,
      locationId: locationId,
      date: date,
      serviceDuration: serviceDuration,
    );

    return slots.any(
      (slot) =>
          slot.isAvailable &&
          slot.startTime == startTime &&
          slot.endTime == endTime,
    );
  }

  // Private helper methods

  List<TimeSlot> _generateSlotsInRange({
    required DateTime startTime,
    required DateTime endTime,
    required Duration slotDuration,
    required Duration buffer,
    required String providerId,
    required String locationId,
  }) {
    final slots = <TimeSlot>[];
    DateTime currentStart = startTime;

    while (currentStart.add(slotDuration).isBefore(endTime) ||
        currentStart.add(slotDuration).isAtSameMomentAs(endTime)) {
      final slotEnd = currentStart.add(slotDuration);

      slots.add(
        TimeSlot(
          startTime: currentStart,
          endTime: slotEnd,
          providerId: providerId,
          locationId: locationId,
          isAvailable: true,
        ),
      );

      // Move to next slot (including buffer)
      currentStart = slotEnd.add(buffer);
    }

    return slots;
  }

  List<TimeSlot> _markAppointmentConflicts({
    required List<TimeSlot> slots,
    required List<Appointment> providerAppointments,
    required List<Appointment> locationAppointments,
    required String providerId,
  }) {
    return slots.map((slot) {
      final providerBusy = providerAppointments.any((appointment) {
        if (!_isBlockingStatus(appointment.status)) return false;
        return _overlaps(
          slot.startTime,
          slot.endTime,
          appointment.startTime,
          appointment.endTime,
        );
      });

      final locationBusy = locationAppointments.any((appointment) {
        if (!_isBlockingStatus(appointment.status)) return false;
        if (appointment.providerId == providerId) {
          return false;
        }
        return _overlaps(
          slot.startTime,
          slot.endTime,
          appointment.startTime,
          appointment.endTime,
        );
      });

      if (providerBusy) {
        return _blockedSlot(slot, 'Provider busy');
      }
      if (locationBusy) {
        return _blockedSlot(slot, 'Location in use');
      }
      return slot;
    }).toList();
  }

  TimeSlot _blockedSlot(TimeSlot slot, String reason) {
    return TimeSlot(
      startTime: slot.startTime,
      endTime: slot.endTime,
      providerId: slot.providerId,
      locationId: slot.locationId,
      isAvailable: false,
      unavailableReason: reason,
    );
  }

  bool _isBlockingStatus(AppointmentStatus status) {
    return status == AppointmentStatus.confirmed ||
        status == AppointmentStatus.pending;
  }

  bool _overlaps(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  List<TimeSlot> _applyBookingPolicies(List<TimeSlot> slots, DateTime date) {
    final now = DateTime.now();
    final minimumNotice = bookingPolicies.minimumBookingNotice;
    final maximumAdvance = bookingPolicies.maximumAdvanceBooking;

    return slots.map((slot) {
      // Check minimum notice period
      if (minimumNotice != null) {
        final minimumStartTime = now.add(minimumNotice);
        if (slot.startTime.isBefore(minimumStartTime)) {
          return TimeSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            providerId: slot.providerId,
            locationId: slot.locationId,
            isAvailable: false,
            unavailableReason: 'Minimum notice required',
          );
        }
      }

      // Check maximum advance booking
      if (maximumAdvance != null) {
        final maximumDate = now.add(maximumAdvance);
        if (slot.startTime.isAfter(maximumDate)) {
          return TimeSlot(
            startTime: slot.startTime,
            endTime: slot.endTime,
            providerId: slot.providerId,
            locationId: slot.locationId,
            isAvailable: false,
            unavailableReason: 'Too far in advance',
          );
        }
      }

      // Don't allow booking in the past
      if (slot.endTime.isBefore(now)) {
        return TimeSlot(
          startTime: slot.startTime,
          endTime: slot.endTime,
          providerId: slot.providerId,
          locationId: slot.locationId,
          isAvailable: false,
          unavailableReason: 'Past time',
        );
      }

      return slot;
    }).toList();
  }
}
