import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/ui/state_widgets.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/models/session_note.dart';
import 'session_note_editor_dialog.dart';

/// Panel for viewing and managing session notes for a client
///
/// Provider-only access with encryption/decryption
/// Displays timeline of notes with rich text support
class SessionNotesPanel extends ConsumerStatefulWidget {
  const SessionNotesPanel({
    super.key,
    required this.clientId,
    this.appointmentId,
    this.client,
    this.securityContext,
    this.encryptionService,
  });

  final String clientId;
  final String? appointmentId;
  
  /// Optional client for editor dialog (will be fetched if not provided)
  final Client? client;
  
  /// Optional security context (will be fetched if not provided)
  final SecurityContext? securityContext;
  
  /// Optional encryption service (will be created if not provided)
  final EncryptionService? encryptionService;

  @override
  ConsumerState<SessionNotesPanel> createState() => _SessionNotesPanelState();
}

class _SessionNotesPanelState extends ConsumerState<SessionNotesPanel> {
  late final Future<EncryptionService> _encryptionFuture;
  SecurityContext? _context;
  Client? _client;
  SessionNoteType _filterType = SessionNoteType.progressNote;
  bool _showAllTypes = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    if (widget.securityContext != null) {
      _context = widget.securityContext;
      if (widget.encryptionService != null) {
        _encryptionFuture = Future.value(widget.encryptionService);
      } else {
        _encryptionFuture = EncryptionKeyManager.getForBusiness(_context!.businessId);
      }
      _client = widget.client;
      setState(() {});
      return;
    }
    
    final authService = ref.read(authStateServiceProvider);
    final context = await authService.getCurrentSecurityContext();
    setState(() {
      _context = context;
      _client = widget.client;
      if (_context != null) {
        _encryptionFuture = EncryptionKeyManager.getForBusiness(_context!.businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_context == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_context!.role.canManageClients) {
      return const Center(
        child: Text('Session notes are only accessible to providers'),
      );
    }

    return Column(
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Expanded(child: _buildNotesList()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Session Notes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'HIPAA-compliant encrypted notes',
            child: Icon(
              Icons.shield,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Spacer(),
          _buildFilterDropdown(),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showCreateNoteDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButton<String>(
      value: _showAllTypes ? 'all' : _filterType.name,
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All Types')),
        ...SessionNoteType.values.map((type) => DropdownMenuItem(
              value: type.name,
              child: Text(type.displayName),
            )),
      ],
      onChanged: (value) {
        setState(() {
          if (value == 'all') {
            _showAllTypes = true;
          } else {
            _showAllTypes = false;
            _filterType = SessionNoteType.values.firstWhere((t) => t.name == value);
          }
        });
      },
    );
  }

  Widget _buildNotesList() {
    return StreamBuilder<List<SessionNote>>(
      stream: widget.appointmentId != null
          ? ref.read(sessionNotesRepositoryProvider).watchAppointmentNotes(
              context: _context!,
              appointmentId: widget.appointmentId!,
            )
          : ref.read(sessionNotesRepositoryProvider).watchClientNotes(
              context: _context!,
              clientId: widget.clientId,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget(
            message: 'Loading session notes...',
          );
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            error: snapshot.error!,
            message: 'Unable to load session notes',
          );
        }

        var notes = snapshot.data ?? [];

        // Apply filter
        if (!_showAllTypes) {
          notes = notes.where((n) => n.noteType == _filterType).toList();
        }

        if (notes.isEmpty) {
          return _buildEmptyState(context);
        }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        separatorBuilder: (_, unused) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildNoteCard(context, notes[index]),
      );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.notes_outlined,
      title: 'No session notes yet',
      subtitle: _showAllTypes
          ? 'Create your first note to document this session'
          : 'No notes found for ${_filterType.displayName}',
      actionLabel: 'Create Note',
      onAction: () => _showCreateNoteDialog(context),
    );
  }

  Widget _buildNoteCard(BuildContext context, SessionNote note) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showNoteDetail(context, note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    note.noteType.icon,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title ?? note.noteType.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(note.displayTimestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (note.isLocked)
                    Chip(
                      label: const Text('Locked'),
                      avatar: const Icon(Icons.lock, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (note.isPsychotherapyNote)
                    Chip(
                      label: const Text('Psych Note'),
                      backgroundColor: theme.colorScheme.errorContainer,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: note.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'By ${note.displayAuthor}',
                style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteDetail(BuildContext context, SessionNote note) async {
    final encryptionService = await _encryptionFuture;
    final decryptedContent = encryptionService.decrypt(note.encryptedContent);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _NoteDetailDialog(
        note: note,
        decryptedContent: decryptedContent,
        onEdit: note.isLocked ? null : () => _showEditNoteDialog(context, note, decryptedContent),
      ),
    );
  }

  Future<void> _showCreateNoteDialog(BuildContext context) async {
    final encryptionService = await _encryptionFuture;
    if (!context.mounted) return;

    // Fetch appointments for the client
    final appointments = await ref.read(appointmentsRepositoryProvider).getClientAppointments(
      context: _context!,
      clientId: widget.clientId,
    );

    if (!context.mounted) return;

    // Create a minimal client if not provided
    final client = _client ?? Client(
      id: widget.clientId,
      firstName: 'Client',
      lastName: '',
      email: '',
      businessId: _context!.businessId,
      createdAt: DateTime.now(),
    );

    final result = await showDialog<SessionNoteEditorResult>(
      context: context,
      builder: (context) => SessionNoteEditorDialog(
        securityContext: _context!,
        repository: ref.read(sessionNotesRepositoryProvider),
        encryptionService: encryptionService,
        client: client,
        appointments: appointments,
        initialAppointmentId: widget.appointmentId,
      ),
    );

    if (!context.mounted || result == null) return;
    _handleEditorResult(context, result);
  }

  Future<void> _showEditNoteDialog(
    BuildContext context,
    SessionNote note,
    String currentContent,
  ) async {
    final encryptionService = await _encryptionFuture;
    if (!context.mounted) return;

    // Fetch appointments for the client
    final appointments = await ref.read(appointmentsRepositoryProvider).getClientAppointments(
      context: _context!,
      clientId: widget.clientId,
    );

    if (!context.mounted) return;

    // Create a minimal client if not provided
    final client = _client ?? Client(
      id: widget.clientId,
      firstName: 'Client',
      lastName: '',
      email: '',
      businessId: _context!.businessId,
      createdAt: DateTime.now(),
    );

    final result = await showDialog<SessionNoteEditorResult>(
      context: context,
      builder: (context) => SessionNoteEditorDialog(
        securityContext: _context!,
        repository: ref.read(sessionNotesRepositoryProvider),
        encryptionService: encryptionService,
        client: client,
        appointments: appointments,
        initialAppointmentId: note.appointmentId,
        initialNote: note,
      ),
    );

    if (!context.mounted || result == null) return;
    _handleEditorResult(context, result);
  }

  void _handleEditorResult(BuildContext context, SessionNoteEditorResult result) {
    final messenger = ScaffoldMessenger.of(context);
    switch (result.status) {
      case SessionNoteEditorStatus.saved:
        messenger.showSnackBar(
          const SnackBar(content: Text('Session note saved')),
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

/// Compact dialog for viewing note details with audit log
class _NoteDetailDialog extends StatelessWidget {
  const _NoteDetailDialog({
    required this.note,
    required this.decryptedContent,
    this.onEdit,
  });

  final SessionNote note;
  final String decryptedContent;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  decryptedContent,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (note.auditLog.isNotEmpty) _buildAuditSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            note.noteType.icon,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title ?? note.noteType.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'By ${note.displayAuthor} • ${DateFormat('MMM d, yyyy').format(note.displayTimestamp)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(context);
                onEdit!();
              },
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ExpansionTile(
            title: Text(
              'Audit Log (${note.auditLog.length} entries)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            children: note.auditLog.map((audit) {
              return ListTile(
                dense: true,
                leading: Icon(_getAuditIcon(audit.action)),
                title: Text('${audit.action} by ${audit.userFullName}'),
                subtitle: Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(audit.timestamp),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getAuditIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'viewed':
        return Icons.visibility;
      case 'edited':
        return Icons.edit;
      case 'locked':
        return Icons.lock;
      case 'deleted':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }
}
