import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../core/utils/safe_error_handler.dart';
import '../../../data/models/session_note.dart';
import '../../../data/models/audit_log.dart';

/// Quick Notes page for providers - create and view provider-only encrypted notes.
///
/// HIPAA Compliance:
/// - Notes are encrypted at rest using AES-256 (SessionNotesRepository)
/// - Visibility set to providerOnly (only the creating provider can see)
/// - phiRead/phiWrite audit logged by SessionNotesRepository
/// - Encryption keys managed via EncryptionKeyManager (Cloud KMS)
///
/// Features:
/// - List provider's quick notes (newest first)
/// - Create new notes with optional client/appointment link
/// - Edit existing notes (if not locked)
/// - View note details with decrypted content
///
/// Under 600 lines by extracting note editor to helper widget.
class QuickNotesPage extends ConsumerStatefulWidget {
  const QuickNotesPage({super.key});

  @override
  ConsumerState<QuickNotesPage> createState() => _QuickNotesPageState();
}

class _QuickNotesPageState extends ConsumerState<QuickNotesPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContext = ref.watch(currentSecurityContextProvider);

    if (securityContext == null || securityContext.providerId == null) {
      return const Scaffold(
        body: Center(child: Text('Provider authentication required')),
      );
    }

    final notesAsync = ref.watch(_providerNotesProvider(securityContext.providerId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Notes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        onPressed: () => _showNoteEditor(context, null),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  VSpace.md,
                  Text(
                    'No notes yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  VSpace.xs,
                  Text(
                    'Create a quick note to get started',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppSpacing.pagePadding,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(
                note: note,
                onTap: () => _showNoteEditor(context, note),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              VSpace.md,
              Text('Error loading notes', style: theme.textTheme.titleMedium),
              VSpace.xs,
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteEditor(BuildContext context, SessionNote? note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _NoteEditorPage(note: note),
      ),
    );

    if (result == true && mounted) {
      // Refresh list
      ref.invalidate(_providerNotesProvider);
    }
  }
}

/// Provider to fetch provider's quick notes.
/// Filters notes by providerId and orders by creation date descending.
final _providerNotesProvider = StreamProvider.family<List<SessionNote>, String>((ref, providerId) {
  final securityContext = ref.watch(currentSecurityContextProvider);
  if (securityContext == null) return Stream.value([]);

  final notesRepo = ref.read(sessionNotesRepositoryProvider);

  // Query notes by providerId (Firestore query)
  // For simplicity, we'll use a custom stream that filters client notes
  // In production, add a compound index: providerId+createdAt(desc)
  return notesRepo.watchClientNotes(
    context: securityContext,
    clientId: providerId, // HACK: using clientId field to store providerId for quick notes
  );
});

/// Note card widget
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  final SessionNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title ?? 'Untitled Note',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isLocked)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
          VSpace.xxs,
          Text(
            dateFormat.format(note.displayTimestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (note.tags.isNotEmpty) ...[
            VSpace.xs,
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: note.tags.take(3).map((tag) => Chip(
                label: Text(tag),
                visualDensity: VisualDensity.compact,
                labelStyle: theme.textTheme.bodySmall,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Note editor page
class _NoteEditorPage extends ConsumerStatefulWidget {
  const _NoteEditorPage({this.note});

  final SessionNote? note;

  @override
  ConsumerState<_NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<_NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController();
    _tagsController = TextEditingController(
      text: widget.note?.tags.join(', ') ?? '',
    );

    if (widget.note != null) {
      _loadDecryptedContent();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadDecryptedContent() async {
    if (widget.note == null) return;

    setState(() => _isLoading = true);

    try {
      final securityContext = ref.read(currentSecurityContextProvider);
      if (securityContext == null) return;

      final encryptionService = await EncryptionKeyManager.getForBusiness(
        securityContext.businessId,
      );

      final decrypted = encryptionService.decrypt(widget.note!.encryptedContent);

      setState(() {
        _contentController.text = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(SafeErrorHandler.handle(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.note != null;
    final canEdit = !isEditing || !widget.note!.isLocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          if (canEdit)
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  VSpace.md,

                  // Content
                  TextField(
                    controller: _contentController,
                    enabled: canEdit,
                    maxLines: 15,
                    decoration: const InputDecoration(
                      labelText: 'Note Content',
                      border: OutlineInputBorder(),
                      hintText: 'Enter your note here...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  VSpace.md,

                  // Tags
                  TextField(
                    controller: _tagsController,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Tags (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., urgent, follow-up',
                    ),
                  ),

                  if (!canEdit) ...[
                    VSpace.md,
                    AppCard(
                      color: theme.colorScheme.errorContainer,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          HSpace.md,
                          Expanded(
                            child: Text(
                              'This note is locked and cannot be edited',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _handleSave() async {
    final securityContext = ref.read(currentSecurityContextProvider);
    if (securityContext == null || securityContext.providerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider authentication required')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notesRepo = ref.read(sessionNotesRepositoryProvider);
      final auditLogRepo = ref.read(auditLogRepositoryProvider);
      final encryptionService = await EncryptionKeyManager.getForBusiness(
        securityContext.businessId,
      );

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.note == null) {
        // Create new note
        // HACK: Store providerId in clientId field for quick notes
        // In production, add a dedicated quickNotes collection
        await notesRepo.createNote(
          context: securityContext,
          appointmentId: 'quick_note', // Placeholder
          clientId: securityContext.providerId!, // HACK: Store providerId here
          providerId: securityContext.providerId!,
          encryptionService: encryptionService,
          noteType: SessionNoteType.progressNote,
          content: _contentController.text,
          title: _titleController.text.trim(),
          tags: tags,
          visibility: SessionNoteVisibility.providerOnly,
        );

        // Audit log
        await auditLogRepo.logEvent(AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'SessionNote',
          entityId: 'quick_note',
          metadata: {'source': 'quickNotes', 'action': 'create'},
        ));
      } else {
        // Update existing note
        await notesRepo.updateNote(
          context: securityContext,
          encryptionService: encryptionService,
          noteId: widget.note!.id,
          content: _contentController.text,
          title: _titleController.text.trim(),
          tags: tags,
        );

        // Audit log
        await auditLogRepo.logEvent(AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.phiWrite,
          entityType: 'SessionNote',
          entityId: widget.note!.id,
          metadata: {'source': 'quickNotes', 'action': 'update'},
        ));
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SafeErrorHandler.handle(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
