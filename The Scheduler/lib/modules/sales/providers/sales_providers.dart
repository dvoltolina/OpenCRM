import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../../../data/models/client_note.dart';
import '../data/sales_notes_repository.dart';

/// Repository provider for sales notes.
final salesNotesRepositoryProvider = Provider<SalesNotesRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auditLog = ref.watch(auditLogRepositoryProvider);
  return SalesNotesRepository(
    firestore: firestore,
    auditLogRepository: auditLog,
  );
});

/// Today's meetings for the current salesperson (provider-scoped).
final salesTodayMeetingsProvider = StreamProvider<List<Appointment>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || context.providerId == null) {
    return const Stream<List<Appointment>>.empty();
  }

  final repo = ref.watch(appointmentsRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

  return repo.watchAppointmentsInRange(
    context: context,
    start: start,
    end: end,
    providerId: context.providerId,
  );
});

/// Count of calls logged today (notes of type call created by the rep).
final salesTodayCallCountProvider = StreamProvider<int>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) {
    return Stream<int>.value(0);
  }

  return ref.watch(salesNotesRepositoryProvider).watchTodayNoteCount(
        context,
        type: NoteType.call,
      );
});

/// Recent clients based on the sales rep's notes.
final recentClientsProvider = FutureProvider<List<Client>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Future.value(const []);
  return ref.watch(salesNotesRepositoryProvider).getRecentClients(context);
});

/// Search input for sales clients.
final salesClientsSearchProvider = StateProvider<String>((ref) => '');

/// Stream of clients filtered by search (read-only for sales).
final filteredSalesClientsProvider = StreamProvider<List<Client>>((ref) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) {
    return const Stream<List<Client>>.empty();
  }

  final search = ref.watch(salesClientsSearchProvider);
  final clientsRepo = ref.watch(clientsRepositoryProvider);

  try {
    if (search.isEmpty) {
      return clientsRepo.watchClients(
        context,
        allowSalesRead: true,
      );
    }

    return clientsRepo.searchClients(
      context: context,
      query: search,
      allowSalesRead: true,
    );
  } catch (_) {
    return const Stream<List<Client>>.empty();
  }
});

/// Notes for a specific client (sales-facing).
final clientNotesProvider =
    StreamProvider.family<List<ClientNote>, String>((ref, clientId) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) {
    return const Stream<List<ClientNote>>.empty();
  }

  return ref.watch(salesNotesRepositoryProvider).watchClientNotes(
        context,
        clientId,
      );
});

/// Whether time clock is enabled for sales (mirrors timesheet flag).
final salesTimeClockEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.featureFlags.enableTimesheets;
});

/// Fetch a client by id (read-only for sales users).
final clientByIdProvider = FutureProvider.family<Client?, String>((ref, clientId) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null) return Future.value(null);

  return ref.watch(clientsRepositoryProvider).getClient(
        context: context,
        clientId: clientId,
        allowSalesRead: true,
      );
});

/// Upcoming appointments for the current sales rep filtered by client.
final clientUpcomingAppointmentsProvider =
    StreamProvider.family<List<Appointment>, String>((ref, clientId) {
  final context = ref.watch(securityContextProvider).valueOrNull;
  if (context == null || context.providerId == null) {
    return const Stream<List<Appointment>>.empty();
  }

  final repo = ref.watch(appointmentsRepositoryProvider);
  final now = DateTime.now();
  final end = now.add(const Duration(days: 30));

  return repo
      .watchAppointmentsInRange(
        context: context,
        start: now,
        end: end,
        providerId: context.providerId,
      )
      .map((appointments) =>
          appointments.where((a) => a.clientId == clientId).toList());
});
