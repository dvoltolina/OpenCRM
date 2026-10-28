import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/components/components.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/session_note.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/appointments_repository.dart';
import '../../../../data/repositories/session_notes_repository.dart';

typedef ComposeSessionNoteCallback = Future<void> Function({
  required List<Appointment> appointments,
  required Appointment appointment,
});

typedef ShowAppointmentFilesCallback = void Function({
  required Appointment appointment,
});

/// Client appointments tab showing upcoming appointments
/// Updated by Agent U3 (2025-11-29) - Uses design tokens and AppCard
class ClientAppointmentsTab extends StatelessWidget {
  const ClientAppointmentsTab({
    super.key,
    required this.appointmentsRepository,
    required this.sessionNotesRepository,
    required this.securityContext,
    required this.client,
    required this.clientId,
    required this.sessionNotesEnabled,
    required this.onComposeSessionNote,
    required this.onShowAppointmentFiles,
  });

  final AppointmentsRepository appointmentsRepository;
  final SessionNotesRepository? sessionNotesRepository;
  final SecurityContext securityContext;
  final Client client;
  final String clientId;
  final bool sessionNotesEnabled;
  final ComposeSessionNoteCallback onComposeSessionNote;
  final ShowAppointmentFilesCallback onShowAppointmentFiles;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: appointmentsRepository.watchUpcoming(securityContext),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments =
            snapshot.data!.where((apt) => apt.clientId == clientId).toList();

        if (appointments.isEmpty) {
          return _EmptyAppointmentsState();
        }

        final notesStream = (sessionNotesEnabled && sessionNotesRepository != null)
            ? sessionNotesRepository!.watchClientNotes(
                context: securityContext,
                clientId: clientId,
              )
            : Stream<List<SessionNote>>.value(const []);

        return StreamBuilder<List<SessionNote>>(
          stream: notesStream,
          builder: (context, notesSnapshot) {
            final notedAppointments =
                notesSnapshot.data?.map((note) => note.appointmentId).toSet() ??
                    <String>{};

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: appointments.length,
              separatorBuilder: (context, index) => VSpace.sm,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final hasNote = notedAppointments.contains(appointment.id);
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        DateFormat('d').format(appointment.startTime),
                      ),
                    ),
                    title: Text(appointment.serviceType ?? 'Appointment'),
                    subtitle: Text(
                      DateFormat('MMM d, y - h:mm a').format(
                        appointment.startTime,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (sessionNotesEnabled)
                          _SessionNoteStatus(hasNote: hasNote),
                        IconButton(
                          icon: const Icon(Icons.note_add_outlined),
                          tooltip: sessionNotesEnabled
                              ? 'Add session note'
                              : 'Enable session notes to document visits',
                          onPressed: sessionNotesEnabled &&
                                  sessionNotesRepository != null
                              ? () => onComposeSessionNote(
                                    appointments: appointments,
                                    appointment: appointment,
                                  )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          tooltip: 'Appointment files',
                          onPressed: () =>
                              onShowAppointmentFiles(appointment: appointment),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyAppointmentsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: AppIconSize.xl,
              color: Theme.of(context).colorScheme.outline,
            ),
            VSpace.md,
            const Text('No appointments yet'),
            VSpace.lg,
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to booking page
              },
              icon: const Icon(Icons.add),
              label: const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionNoteStatus extends StatelessWidget {
  const _SessionNoteStatus({required this.hasNote});

  final bool hasNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (hasNote) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: Icon(
          Icons.verified,
          size: AppIconSize.sm,
          color: theme.colorScheme.secondary,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          'No note',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}


