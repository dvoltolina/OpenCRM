import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/client_note.dart';
import '../../providers/sales_providers.dart';

class QuickAddNoteDialog extends ConsumerStatefulWidget {
  const QuickAddNoteDialog({super.key, this.initialClientId});

  final String? initialClientId;

  @override
  ConsumerState<QuickAddNoteDialog> createState() => _QuickAddNoteDialogState();
}

class _QuickAddNoteDialogState extends ConsumerState<QuickAddNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  NoteType _noteType = NoteType.call;
  String? _selectedClientId;
  bool _isSubmitting = false;
  bool _isLoadingClients = true;
  List<Client> _clients = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.initialClientId;
    _loadClients();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final context = ref.read(securityContextProvider).valueOrNull;
    if (context == null) {
      setState(() => _isLoadingClients = false);
      return;
    }

    try {
      final clients = await ref
          .read(clientsRepositoryProvider)
          .getClients(context, limit: 50, allowSalesRead: true);
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });
    } catch (_) {
      setState(() {
        _clients = const [];
        _isLoadingClients = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _filteredClients();

    return AlertDialog(
      title: const Text('Add Note'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingClients)
              const LinearProgressIndicator(minHeight: 2)
            else
              _ClientSelector(
                clients: filteredClients,
                selectedClientId: _selectedClientId,
                onSelected: (value) =>
                    setState(() => _selectedClientId = value),
                searchController: _clientSearchController,
                onSearchChanged: () => setState(() {}),
              ),
            VSpace.md,
            DropdownButtonFormField<NoteType>(
              initialValue: _noteType,
              decoration: const InputDecoration(labelText: 'Type'),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _noteType = value);
                }
              },
              items: NoteType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_labelForType(type)),
                    ),
                  )
                  .toList(),
            ),
            VSpace.md,
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note *',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              VSpace.sm,
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : () => _save(context),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Note'),
        ),
      ],
    );
  }

  List<Client> _filteredClients() {
    final query = _clientSearchController.text.trim().toLowerCase();
    final results = query.isEmpty
        ? List<Client>.from(_clients)
        : _clients.where((client) {
            return client.fullName.toLowerCase().contains(query) ||
                (client.email?.toLowerCase().contains(query) ?? false) ||
                (client.phone?.contains(query) ?? false);
          }).toList();

    if (_selectedClientId != null &&
        results.every((client) => client.id != _selectedClientId)) {
      try {
        final selected = _clients.firstWhere(
          (client) => client.id == _selectedClientId,
        );
        results.insert(0, selected);
      } catch (_) {
        // Ignore if selected client not found.
      }
    }

    return results;
  }

  Future<void> _save(BuildContext context) async {
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext == null) {
      setState(() => _error = 'Sign in required.');
      return;
    }

    if (_selectedClientId == null) {
      setState(() => _error = 'Select a client.');
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      setState(() => _error = 'Note cannot be empty.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      await ref
          .read(salesNotesRepositoryProvider)
          .addNote(
            securityContext,
            clientId: _selectedClientId!,
            content: _noteController.text.trim(),
            type: _noteType,
          );
      if (mounted) navigator.pop();
    } catch (_) {
      setState(() => _error = 'Unable to save note. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _labelForType(NoteType type) {
    switch (type) {
      case NoteType.call:
        return 'Call';
      case NoteType.meeting:
        return 'Meeting';
      case NoteType.email:
        return 'Email';
      case NoteType.followUp:
        return 'Follow-up';
      case NoteType.other:
        return 'Other';
    }
  }
}

class _ClientSelector extends StatelessWidget {
  const _ClientSelector({
    required this.clients,
    required this.selectedClientId,
    required this.onSelected,
    required this.searchController,
    required this.onSearchChanged,
  });

  final List<Client> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onSelected;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Client *',
            hintText: 'Search clients...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => onSearchChanged(),
        ),
        VSpace.sm,
        DropdownButtonFormField<String>(
          initialValue: selectedClientId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Select client'),
          items: clients
              .map(
                (client) => DropdownMenuItem(
                  value: client.id,
                  child: Text(client.fullName),
                ),
              )
              .toList(),
          onChanged: onSelected,
        ),
      ],
    );
  }
}
