import 'package:flutter/material.dart';

import '../../../../core/ui/accessibility_helpers.dart';
import '../../../../core/ui/animations.dart';
import '../../../../core/ui/platform_helpers.dart';
import '../../../../core/ui/responsive_helpers.dart';
import '../../../../data/repositories/clients_repository.dart';
import 'clients_import_export.dart';

/// Header widget for the clients page
class ClientsHeader extends StatelessWidget {
  final ClientsRepository clientsRepository;
  final dynamic authService;

  const ClientsHeader({
    super.key,
    required this.clientsRepository,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: responsivePadding(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemanticWrapper(
                  header: true,
                  label: 'Clients page heading',
                  child: Text(
                    'Clients',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).fadeIn(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage client relationships and information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ).fadeIn(delay: 100.ms),
              ],
            ),
          ),
          TouchTargets.ensure(
            child: SemanticWrapper(
              label: 'Export clients to CSV',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Export clients',
                onPressed: () => ClientsImportExport.showExportDialog(
                  context: context,
                  clientsRepository: clientsRepository,
                  authService: authService,
                ),
              ),
            ),
          ),
          TouchTargets.ensure(
            child: SemanticWrapper(
              label: 'Import clients from CSV',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.file_upload),
                tooltip: 'Import clients',
                onPressed: () => ClientsImportExport.showImportDialog(
                  context: context,
                  clientsRepository: clientsRepository,
                  authService: authService,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
