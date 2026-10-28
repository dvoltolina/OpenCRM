import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/intake_form.dart';
import '../../../../data/models/file_attachment.dart';
import '../../../../data/models/security_context.dart';

/// Client detail bottom sheet showing appointments history, intake forms, and files.
///
/// PHI reads are audit logged via repositories.
class ClientDetailSheet extends ConsumerStatefulWidget {
  const ClientDetailSheet({
    super.key,
    required this.client,
    required this.securityContext,
  });

  final Client client;
  final SecurityContext securityContext;

  @override
  ConsumerState<ClientDetailSheet> createState() => _ClientDetailSheetState();
}

class _ClientDetailSheetState extends ConsumerState<ClientDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ClientHeader(client: widget.client),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Appointments'),
                  Tab(text: 'Intake Forms'),
                  Tab(text: 'Files'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _AppointmentsTab(
                      clientId: widget.client.id,
                      securityContext: widget.securityContext,
                    ),
                    _IntakeFormsTab(
                      clientId: widget.client.id,
                      securityContext: widget.securityContext,
                    ),
                    _FilesTab(
                      clientId: widget.client.id,
                      securityContext: widget.securityContext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientHeader extends StatelessWidget {
  const _ClientHeader({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            client.initials,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          client.fullName,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        if (client.email != null)
          Text(
            client.email!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (client.phone != null)
          Text(
            client.phone!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Chip(
          label: Text(client.lifecycleDisplay),
          avatar: const Icon(Icons.info_outline, size: 16),
        ),
      ],
    );
  }
}

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab({
    required this.clientId,
    required this.securityContext,
  });

  final String clientId;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(appointmentsRepositoryProvider);

    return StreamBuilder<List<Appointment>>(
      stream: repo.watchClientAppointments(
        context: securityContext,
        clientId: clientId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_available,
            message: 'No appointments',
          );
        }

        // Sort by date descending (most recent first)
        final sortedAppointments = List<Appointment>.from(appointments)
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sortedAppointments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final appointment = sortedAppointments[index];
            return _AppointmentListItem(appointment: appointment);
          },
        );
      },
    );
  }
}

class _AppointmentListItem extends StatelessWidget {
  const _AppointmentListItem({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: appointment.status),
                const Spacer(),
                Text(
                  dateFormat.format(appointment.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${timeFormat.format(appointment.startTime)} - ${timeFormat.format(appointment.endTime)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (appointment.serviceType != null) ...[
              const SizedBox(height: 4),
              Text(
                appointment.serviceType!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = _getStatusLabel();

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No-Show';
    }
  }
}

class _IntakeFormsTab extends ConsumerWidget {
  const _IntakeFormsTab({
    required this.clientId,
    required this.securityContext,
  });

  final String clientId;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(intakeFormRepositoryProvider);

    return StreamBuilder<List<IntakeFormSubmission>>(
      stream: repo.watchClientSubmissions(
        context: securityContext,
        clientId: clientId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final submissions = snapshot.data ?? [];

        if (submissions.isEmpty) {
          return const _EmptyState(
            icon: Icons.description_outlined,
            message: 'No intake forms',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final submission = submissions[index];
            final dateFormat = DateFormat('MMM d, y');

            return Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(submission.templateName ?? 'Untitled Form'),
                subtitle: Text(
                  'Submitted: ${dateFormat.format(submission.submittedAt)}',
                ),
                trailing: Chip(
                  label: const Text('Completed'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({
    required this.clientId,
    required this.securityContext,
  });

  final String clientId;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(fileAttachmentRepositoryProvider);

    return StreamBuilder<List<FileAttachment>>(
      stream: repo.watchClientAttachments(
        context: securityContext,
        clientId: clientId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return const _EmptyState(
            icon: Icons.folder_open,
            message: 'No files',
          );
        }

        // Sort by upload date descending
        final sortedFiles = List<FileAttachment>.from(files)
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sortedFiles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final file = sortedFiles[index];
            final dateFormat = DateFormat('MMM d, y');
            final sizeKb = (file.sizeBytes / 1024).toStringAsFixed(1);

            return Card(
              child: ListTile(
                leading: Icon(_getFileIcon(file.contentType)),
                title: Text(file.name),
                subtitle: Text(
                  '$sizeKb KB • ${dateFormat.format(file.uploadedAt)}',
                ),
                trailing: file.isSensitive
                    ? const Icon(Icons.lock_outline, size: 20)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  IconData _getFileIcon(String contentType) {
    if (contentType.startsWith('image/')) return Icons.image;
    if (contentType.startsWith('video/')) return Icons.videocam;
    if (contentType.contains('pdf')) return Icons.picture_as_pdf;
    if (contentType.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
