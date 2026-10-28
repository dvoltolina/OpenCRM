import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/auth_state_service.dart';
import '../../../../data/models/audit_log.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/security_context.dart';
import '../../../../data/repositories/audit_log_repository.dart';
import '../../../../data/repositories/clients_repository.dart';

/// Helper for CSV import/export flows so the main Clients page stays lean.
class ClientsImportExport {
  ClientsImportExport._();

  static const _uuid = Uuid();

  /// Show export dialog with CSV content ready to copy.
  static Future<void> showExportDialog({
    required BuildContext context,
    required ClientsRepository clientsRepository,
    required AuthStateService authService,
    AuditLogRepository? auditLogRepository,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => FutureBuilder<SecurityContext?>(
        future: authService.getCurrentSecurityContext(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final securityContext = snapshot.data;
          if (securityContext == null) {
            return AlertDialog(
              title: const Text('Export Clients'),
              content: const Text('Sign in to export client data.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          return FutureBuilder<List<Client>>(
            future: clientsRepository.getClients(securityContext),
            builder: (context, clientsSnapshot) {
              if (!clientsSnapshot.hasData) {
                return const AlertDialog(
                  content: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final clients = clientsSnapshot.data!;
              final csv = _buildCsv(clients);

              // Log the export for HIPAA compliance
              _logExport(
                securityContext: securityContext,
                clientCount: clients.length,
                auditLogRepository: auditLogRepository,
              );

              return AlertDialog(
                title: const Text('Export Clients'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Copy this CSV to import into another system.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(child: Text(csv)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csv));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV copied')),
                      );
                    },
                    child: const Text('Copy CSV'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Show import dialog that accepts CSV text and writes clients.
  static Future<void> showImportDialog({
    required BuildContext context,
    required ClientsRepository clientsRepository,
    required AuthStateService authService,
  }) async {
    const sample = 'firstName,lastName,email,phone,tags\n'
        'Jane,Doe,jane@example.com,555-111-2222,VIP|Member\n'
        'Alex,Kim,alex@example.com,,Realtor Lead';

    final controller = TextEditingController(text: sample);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Clients (CSV)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste CSV data with headers: firstName,lastName,email,phone,tags',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _importClientsFromCsv(
                context: context,
                csv: controller.text.trim(),
                clientsRepository: clientsRepository,
                authService: authService,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // ===== helpers =====

  static String _buildCsv(List<Client> clients) {
    final buffer = StringBuffer(
      'firstName,lastName,email,phone,tags,notes\n',
    );
    for (final client in clients) {
      final tags = client.tags.join('|');
      final row = [
        client.firstName,
        client.lastName,
        client.email ?? '',
        client.phone ?? '',
        tags,
        (client.notes ?? '').replaceAll('\n', ' '),
      ].map(_escapeCsv).join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  static Future<void> _importClientsFromCsv({
    required BuildContext context,
    required String csv,
    required ClientsRepository clientsRepository,
    required AuthStateService authService,
  }) async {
    final securityContext = await authService.getCurrentSecurityContext();
    if (securityContext == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to import clients')),
        );
      }
      return;
    }

    final lines = csv
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rows to import')),
        );
      }
      return;
    }

    var imported = 0;
    final now = DateTime.now();
    for (final line in lines.skip(1)) {
      final cells = line.split(',');
      if (cells.length < 2) continue;
      final firstName = cells[0].trim();
      final lastName = cells[1].trim().isEmpty ? 'Client' : cells[1].trim();
      final email = cells.length > 2 ? cells[2].trim() : null;
      final phone = cells.length > 3 ? cells[3].trim() : null;
      final tagsRaw = cells.length > 4 ? cells[4].trim() : '';
      final tags = tagsRaw.isEmpty
          ? <String>[]
          : tagsRaw.split(RegExp(r'[|;]')).map((t) => t.trim()).toList();

      final client = Client(
        id: _uuid.v4(),
        businessId: securityContext.businessId,
        firstName: firstName.isEmpty ? 'Client' : firstName,
        lastName: lastName,
        email: email?.isEmpty ?? true ? null : email,
        phone: phone?.isEmpty ?? true ? null : phone,
        tags: tags,
        createdAt: now,
      );

      try {
        await clientsRepository.upsertClient(
          context: securityContext,
          client: client,
        );
        imported++;
      } catch (_) {
        continue;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported clients')),
      );
    }
  }

  static String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    var escaped = value.replaceAll('"', '""');
    if (needsQuotes) {
      escaped = '"$escaped"';
    }
    return escaped;
  }

  /// Log client data export for HIPAA compliance
  static Future<void> _logExport({
    required SecurityContext securityContext,
    required int clientCount,
    AuditLogRepository? auditLogRepository,
  }) async {
    try {
      final auditRepo = auditLogRepository ?? AuditLogRepository();
      await auditRepo.logEvent(
        AuditLogEntry(
          businessId: securityContext.businessId,
          userId: securityContext.userId,
          actionType: AuditActionType.dataExport,
          entityType: 'Client',
          entityId: 'bulk_export',
          metadata: {
            'exportType': 'csv',
            'recordCount': clientCount,
            'source': 'clients_page',
          },
        ),
      );
    } catch (e) {
      // Best-effort logging: don't block the export if logging fails
    }
  }
}
