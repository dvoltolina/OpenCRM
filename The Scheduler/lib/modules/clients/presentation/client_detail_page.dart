import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/secure_error_handler.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/client.dart';
import '../../../data/models/intake_form.dart';
import '../../../data/models/security_context.dart';
import '../../../data/repositories/communication_repository.dart';
import '../../../data/repositories/session_notes_repository.dart';
import 'widgets/appointment_files_sheet.dart';
import 'widgets/client_appointments_tab.dart';
import 'widgets/client_communications_tab.dart';
import 'widgets/client_files_panel.dart';
import 'widgets/client_overview_tab.dart';
import 'widgets/client_intake_forms_tab.dart';
import 'widgets/edit_client_dialog.dart';
import 'widgets/intake_form_viewer.dart';
import 'widgets/session_note_editor_dialog.dart';
import 'widgets/session_notes_panel.dart';
import 'widgets/sliver_tab_bar_delegate.dart';

/// Client detail page showing comprehensive client information.
/// Under 600 lines by extracting complex widgets.
/// Polished by Agent P4 (2025-11-28) - Proper title and layout
class ClientDetailPage extends ConsumerStatefulWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends ConsumerState<ClientDetailPage>
    with SingleTickerProviderStateMixin {
  CommunicationRepository? _communicationRepository;
  SessionNotesRepository? _sessionNotesRepository;
  EncryptionService? _encryptionService;
  bool _sessionNotesEnabled = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = ref.read(appConfigProvider);
    _sessionNotesEnabled = config.featureFlags.enableSessionNotes;
    _encryptionService ??= EncryptionService(
      masterKey: config.integrationConfig.tokenEncryptionKey,
    );
    _sessionNotesRepository ??= ref.read(sessionNotesRepositoryProvider);
    final targetLength = _sessionNotesEnabled && _sessionNotesRepository != null
        ? 6
        : 5;
    _ensureTabControllerLength(targetLength);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final authService = ref.read(authStateServiceProvider);
    final clientsRepository = ref.read(clientsRepositoryProvider);

    return StreamBuilder(
      stream: authService.watchSecurityContext(),
      builder: (context, securitySnapshot) {
        if (!securitySnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final securityContext = securitySnapshot.data!;

        return FutureBuilder<Client?>(
          future: clientsRepository.getClient(
            context: securityContext,
            clientId: widget.clientId,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Text(SecureErrorHandler.loadingFailed),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final client = snapshot.data!;
            final showSessionNotes =
                _sessionNotesEnabled && _sessionNotesRepository != null;
            final tabConfigs = _buildTabConfigs(
              client: client,
              securityContext: securityContext,
              config: config,
              showSessionNotes: showSessionNotes,
            );
            _ensureTabControllerLength(tabConfigs.length);

            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  _buildAppBar(context, client),
                  _buildClientHeader(context, client),
                  _buildTabBar(tabConfigs),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: tabConfigs.map((tab) => tab.builder).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Client client) {
    return SliverAppBar(
      title: Text(client.fullName),
      centerTitle: false, // Left-aligned per design system
      pinned: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit client',
          onPressed: () => _showEditDialog(context, client),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onPressed: () => _showMoreOptions(context, client),
        ),
      ],
    );
  }

  Widget _buildClientHeader(BuildContext context, Client client) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.pagePadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(
                client.lifecycleColorValue,
              ).withValues(alpha: 0.2),
              child: Text(
                client.initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Color(client.lifecycleColorValue),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            VSpace.md,
            StatusPill(
              label: client.lifecycleDisplay,
              color: Color(client.lifecycleColorValue),
              backgroundColor: Color(client.lifecycleColorValue).withValues(alpha: 0.2),
            ),
            if (client.tags.isNotEmpty) ...[
              VSpace.sm,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: client.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: theme.textTheme.bodySmall),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(List<_ClientTabConfig> tabs) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Client client, SecurityContext securityContext) {
    return ClientOverviewTab(
      client: client,
      securityContext: securityContext,
      clientsRepository: ref.read(clientsRepositoryProvider),
    );
  }

  Widget _buildAppointmentsTab(SecurityContext securityContext, Client client) {
    return ClientAppointmentsTab(
      appointmentsRepository: ref.read(appointmentsRepositoryProvider),
      sessionNotesRepository: _sessionNotesRepository,
      securityContext: securityContext,
      client: client,
      clientId: widget.clientId,
      sessionNotesEnabled: _sessionNotesEnabled,
      onComposeSessionNote: ({
        required List<Appointment> appointments,
        required Appointment appointment,
      }) =>
          _composeSessionNote(
        securityContext: securityContext,
        client: client,
        appointments: appointments,
        appointment: appointment,
      ),
      onShowAppointmentFiles: ({
        required Appointment appointment,
      }) =>
          _showAppointmentFiles(
        securityContext: securityContext,
        client: client,
        appointment: appointment,
      ),
    );
  }

  void _showAppointmentFiles({
    required SecurityContext securityContext,
    required Client client,
    required Appointment appointment,
  }) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: AppointmentFilesSheet(
          securityContext: securityContext,
          appointment: appointment,
          client: client,
          repository: ref.read(fileAttachmentRepositoryProvider),
        ),
      ),
    );
  }

  Widget _buildIntakeFormsTab(SecurityContext securityContext) {
    return ClientIntakeFormsTab(
      intakeFormRepository: ref.read(intakeFormRepositoryProvider),
      securityContext: securityContext,
      clientId: widget.clientId,
      onViewSubmission: _viewIntakeForm,
    );
  }

  Future<void> _showEditDialog(BuildContext context, Client client) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditClientDialog(client: client),
    );

    if (!mounted) return;
    if (result == true) {
      setState(() {}); // Refresh
      messenger.showSnackBar(
        const SnackBar(content: Text('Client updated successfully')),
      );
    }
  }

  void _showMoreOptions(BuildContext context, Client client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Book Appointment'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to booking
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Send Intake Form'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Send intake form
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Client'),
              onTap: () => _confirmDelete(context, client),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Client client) async {
    Navigator.pop(context); // Close bottom sheet

    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client?'),
        content: Text(
          'Are you sure you want to delete ${client.fullName}? '
          'This action cannot be undone.',
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              HSpace.sm,
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      // TODO: Delete client
      navigator.pop(); // Go back to clients list
    }
  }

  void _viewIntakeForm(IntakeFormSubmission submission) {
    showDialog(
      context: context,
      builder: (context) => IntakeFormViewer(submission: submission),
    );
  }

  void _ensureTabControllerLength(int length) {
    if (_tabController.length == length) return;
    final previousIndex = _tabController.index.clamp(0, length - 1);
    _tabController.dispose();
    _tabController = TabController(length: length, vsync: this);
    _tabController.index = previousIndex;
  }

  List<_ClientTabConfig> _buildTabConfigs({
    required Client client,
    required SecurityContext securityContext,
    required AppConfig config,
    required bool showSessionNotes,
  }) {
    final tabs = <_ClientTabConfig>[
      _ClientTabConfig(
        label: 'Overview',
        builder: _buildOverviewTab(client, securityContext),
      ),
      _ClientTabConfig(
        label: 'Appointments',
        builder: _buildAppointmentsTab(securityContext, client),
      ),
      _ClientTabConfig(
        label: 'Forms',
        builder: _buildIntakeFormsTab(securityContext),
      ),
    ];

    if (showSessionNotes && _sessionNotesRepository != null) {
      tabs.add(
        _ClientTabConfig(
          label: 'Session Notes',
          builder: SessionNotesPanel(
            clientId: client.id,
          ),
        ),
      );
    }

    tabs.add(
      _ClientTabConfig(
        label: 'Files',
        builder: ClientFilesPanel(
          securityContext: securityContext,
          clientId: widget.clientId,
          fileAttachmentRepository: ref.read(fileAttachmentRepositoryProvider),
        ),
      ),
    );

    tabs.add(
      _ClientTabConfig(
        label: 'Communications',
        builder: () {
          _communicationRepository ??= InMemoryCommunicationRepository(
            config.communicationConfig,
          );
          return ClientCommunicationsTab(
            communicationRepository: _communicationRepository!,
            clientId: widget.clientId,
          );
        }(),
      ),
    );

    return tabs;
  }

  Future<void> _composeSessionNote({
    required SecurityContext securityContext,
    required Client client,
    required List<Appointment> appointments,
    Appointment? appointment,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_sessionNotesEnabled || _sessionNotesRepository == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session notes are disabled for this workspace.'),
        ),
      );
      return;
    }

    if (appointments.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No appointments available for session notes.'),
        ),
      );
      return;
    }

    final result = await showDialog<SessionNoteEditorResult>(
      context: context,
      builder: (context) => SessionNoteEditorDialog(
        securityContext: securityContext,
        repository: _sessionNotesRepository!,
        encryptionService: _encryptionService!,
        client: client,
        appointments: appointments,
        initialAppointmentId: appointment?.id,
      ),
    );

    if (result == null || !mounted) return;
    switch (result.status) {
      case SessionNoteEditorStatus.saved:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              appointment == null
                  ? 'Session note saved'
                  : 'Session note saved for ${DateFormat.MMMd().format(appointment.startTime)}',
            ),
          ),
        );
        break;
      case SessionNoteEditorStatus.deleted:
        messenger.showSnackBar(
          const SnackBar(content: Text('Session note deleted')),
        );
        break;
    }
  }
}

class _ClientTabConfig {
  const _ClientTabConfig({required this.label, required this.builder});

  final String label;
  final Widget builder;
}
