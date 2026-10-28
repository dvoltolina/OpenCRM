import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/provider.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/models/service.dart';
import '../../../../data/models/location.dart';
import '../../../../data/repositories/clients_repository.dart';
import '../../../../data/repositories/file_attachment_repository.dart';
import '../../../../data/repositories/appointments_repository.dart';
import 'appointment_detail_client_card.dart';
import 'appointment_detail_info_card.dart';
import 'appointment_detail_actions.dart';
import 'appointment_detail_files_section.dart';

/// Staff-facing appointment detail sheet with comprehensive information
/// and file management capabilities.
/// Updated by Agent U4 (2025-11-29) - Uses design tokens and StatusPill
class StaffAppointmentDetailSheet extends StatefulWidget {
  const StaffAppointmentDetailSheet({
    super.key,
    required this.securityContext,
    required this.appointment,
    required this.provider,
    this.service,
    this.location,
    this.fileAttachmentRepository,
    this.fileStorageService,
    this.clientsRepository,
    this.appointmentsRepository,
    this.onStatusChanged,
  });

  final SecurityContext securityContext;
  final Appointment appointment;
  final Provider provider;
  final Service? service;
  final Location? location;
  final FileAttachmentRepository? fileAttachmentRepository;
  final FileStorageService? fileStorageService;
  final ClientsRepository? clientsRepository;
  final AppointmentsRepository? appointmentsRepository;
  final VoidCallback? onStatusChanged;

  @override
  State<StaffAppointmentDetailSheet> createState() =>
      _StaffAppointmentDetailSheetState();
}

class _StaffAppointmentDetailSheetState
    extends State<StaffAppointmentDetailSheet> {
  late final FileAttachmentRepository _fileRepo;
  late final FileStorageService _storage;
  late final ClientsRepository _clientsRepo;
  late final AppointmentsRepository _appointmentsRepo;
  final _timeFormat = DateFormat.jm();

  Client? _client;
  bool _loadingClient = true;
  String? _clientError;

  @override
  void initState() {
    super.initState();
    _fileRepo = widget.fileAttachmentRepository ?? FileAttachmentRepository();
    _storage = widget.fileStorageService ?? FileStorageService();
    _clientsRepo = widget.clientsRepository ?? ClientsRepository();
    _appointmentsRepo =
        widget.appointmentsRepository ?? AppointmentsRepository();
    _loadClient();
  }

  Future<void> _loadClient() async {
    try {
      final client = await _clientsRepo.getClient(
        context: widget.securityContext,
        clientId: widget.appointment.clientId,
      );
      if (!mounted) return;
      setState(() {
        _client = client;
        _loadingClient = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clientError = 'Failed to load client: $e';
        _loadingClient = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = widget.appointment;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHandle(theme),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(theme, appointment),
                    ),
                    SliverToBoxAdapter(
                      child: AppointmentDetailClientCard(
                        client: _client,
                        isLoading: _loadingClient,
                        error: _clientError,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AppointmentDetailInfoCard(
                        appointment: appointment,
                        provider: widget.provider,
                        service: widget.service,
                        location: widget.location,
                      ),
                    ),
                    if (appointment.notes?.isNotEmpty ?? false)
                      SliverToBoxAdapter(
                        child: _buildNotesCard(theme, appointment),
                      ),
                    SliverToBoxAdapter(
                      child: AppointmentDetailActions(
                        appointment: appointment,
                        securityContext: widget.securityContext,
                        appointmentsRepository: _appointmentsRepo,
                        client: _client,
                        onStatusChanged: widget.onStatusChanged,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AppointmentDetailFilesSection(
                        appointment: appointment,
                        securityContext: widget.securityContext,
                        fileAttachmentRepository: _fileRepo,
                        fileStorageService: _storage,
                        client: _client,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: VSpace.lg,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Appointment appointment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.service?.name ??
                      appointment.serviceType ??
                      'Appointment',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(appointment.status),
            ],
          ),
          VSpace.xs,
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              HSpace.xs,
              Expanded(
                child: Text(
                  '${DateFormat('EEEE, MMMM d, y').format(appointment.startTime)} • '
                  '${_timeFormat.format(appointment.startTime)} - ${_timeFormat.format(appointment.endTime)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          if (appointment.isRecurring) ...[
            VSpace.xxs,
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: AppIconSize.xs,
                  color: theme.colorScheme.secondary,
                ),
                HSpace.xs,
                Text(
                  'Recurring appointment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, Appointment appointment) {
    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note,
                size: AppIconSize.sm,
                color: theme.colorScheme.primary,
              ),
              HSpace.xs,
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          VSpace.xs,
          Text(
            appointment.notes!,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return StatusPill.warning(label: 'Pending');
      case AppointmentStatus.confirmed:
        return StatusPill.success(label: 'Confirmed');
      case AppointmentStatus.cancelled:
        return StatusPill.error(label: 'Cancelled');
      case AppointmentStatus.completed:
        return StatusPill.info(label: 'Completed');
      case AppointmentStatus.noShow:
        return StatusPill.neutral(label: 'No Show');
    }
  }

}

