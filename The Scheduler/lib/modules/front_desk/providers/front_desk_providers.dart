import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../core/providers/providers.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/provider.dart' as model;
import '../../../data/models/waitlist_entry.dart';
import '../../../data/models/client.dart';
import '../../../data/models/service.dart';

/// Front desk providers for managing appointments, arrivals, and waitlist.
/// Optimized for stationary businesses with check-in workflows.

/// All appointments for today (all providers).
///
/// Used by front desk to see complete schedule across all providers.
final todayAllAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Stream.value([]);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return ref.watch(appointmentsRepositoryProvider).watchAppointmentsInRange(
        context: context,
        start: startOfDay,
        end: endOfDay,
      );
});

/// Appointments grouped by provider ID.
///
/// Used for displaying schedule in columns/sections by provider.
final appointmentsByProviderProvider =
    Provider<Map<String, List<Appointment>>>((ref) {
  final appointments = ref.watch(todayAllAppointmentsProvider).valueOrNull ?? [];
  return groupBy(appointments, (Appointment a) => a.providerId);
});

/// Expected arrivals for the next 60 minutes.
///
/// Shows clients who should arrive soon and need check-in.
/// Excludes already checked-in or completed appointments.
final expectedArrivalsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(todayAllAppointmentsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final cutoff = now.add(const Duration(minutes: 60));

  return appointments
      .where((a) =>
          a.startTime.isAfter(now.subtract(const Duration(minutes: 15))) &&
          a.startTime.isBefore(cutoff))
      .where((a) =>
          a.status != AppointmentStatus.completed &&
          a.status != AppointmentStatus.noShow)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
});

/// Current waitlist entries.
///
/// Shows clients waiting for service with active status.
final waitlistProvider = StreamProvider<List<WaitlistEntry>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Stream.value([]);

  return ref.watch(waitlistRepositoryProvider).watchEntries(
        context: context,
        status: WaitlistStatus.active,
      );
});

/// Providers working today.
///
/// Used for filtering schedule and assigning walk-ins.
final todayProvidersProvider = StreamProvider<List<model.Provider>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Stream.value([]);

  return ref.watch(providersRepositoryProvider).watchProviders(context);
});

/// All clients for search/lookup.
///
/// Used in check-in dialog for client lookup.
final allClientsProvider = StreamProvider<List<Client>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Stream.value([]);

  return ref.watch(clientsRepositoryProvider).watchClients(context);
});

/// All services for walk-in booking.
final allServicesProvider = StreamProvider<List<Service>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Stream.value([]);

  return ref.watch(servicesRepositoryProvider).watchServices(context);
});

/// Selected date for schedule view (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Selected provider filter (null = all providers).
final selectedProviderFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered appointments based on selected date and provider.
final filteredAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final allAppointments =
      ref.watch(todayAllAppointmentsProvider).valueOrNull ?? [];
  final selectedProvider = ref.watch(selectedProviderFilterProvider);

  if (selectedProvider == null) {
    return allAppointments;
  }

  return allAppointments
      .where((a) => a.providerId == selectedProvider)
      .toList();
});

/// Current time provider that updates every minute.
///
/// Used in app bar to show current time.
final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});
