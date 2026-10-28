import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/user_messages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/gift_card_template.dart';
import '../../../../data/models/security_context.dart';
import 'template_editor_dialog.dart';

/// Dialog for managing gift card templates.
///
/// Features:
/// - List existing templates
/// - Create new templates
/// - Edit existing templates
/// - Toggle active status
/// - Delete templates
class GiftCardTemplateDialog extends ConsumerStatefulWidget {
  const GiftCardTemplateDialog({super.key});

  @override
  ConsumerState<GiftCardTemplateDialog> createState() =>
      _GiftCardTemplateDialogState();
}

class _GiftCardTemplateDialogState extends ConsumerState<GiftCardTemplateDialog> {
  @override
  Widget build(BuildContext context) {
    final securityContextAsync = ref.watch(securityContextProvider);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: securityContextAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(UserMessages.loadError)),
          data: (securityContext) {
            if (securityContext == null) {
              return const Center(child: Text('Authentication required.'));
            }
            return _TemplateListView(securityContext: securityContext);
          },
        ),
      ),
    );
  }
}

class _TemplateListView extends ConsumerWidget {
  const _TemplateListView({required this.securityContext});

  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateRepo = ref.watch(giftCardTemplateRepositoryProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.add_photo_alternate_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gift Card Templates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Template List
        Expanded(
          child: StreamBuilder<List<GiftCardTemplate>>(
            stream: templateRepo.watchTemplates(securityContext, activeOnly: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final templates = snapshot.data ?? [];

              if (templates.isEmpty) {
                final theme = Theme.of(context);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No templates yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a template to customize gift card appearance',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _TemplateListTile(
                    template: template,
                    securityContext: securityContext,
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Footer
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Template'),
                onPressed: () => _showTemplateEditor(context, securityContext, null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTemplateEditor(
    BuildContext context,
    SecurityContext securityContext,
    GiftCardTemplate? template,
  ) {
    showDialog(
      context: context,
      builder: (context) => TemplateEditorDialog(
        securityContext: securityContext,
        template: template,
      ),
    );
  }
}

class _TemplateListTile extends ConsumerWidget {
  const _TemplateListTile({
    required this.template,
    required this.securityContext,
  });

  final GiftCardTemplate template;
  final SecurityContext securityContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bgColor = _parseColor(template.backgroundColor, context);
    final textColor = _parseColor(template.textColor, context);

    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: template.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  template.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Icon(
                    Icons.card_giftcard,
                    color: textColor,
                  ),
                ),
              )
            : Icon(
                Icons.card_giftcard,
                color: textColor,
              ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(template.name)),
          if (!template.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Inactive',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        _buildSubtitle(),
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(context, ref, value),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  template.isActive ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(template.isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _showTemplateEditor(context, ref),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (template.presetAmountsCents != null &&
        template.presetAmountsCents!.isNotEmpty) {
      final amounts = template.presetAmountsDollars
          .map((d) => '\$${d.toStringAsFixed(0)}')
          .join(', ');
      parts.add(amounts);
    } else {
      parts.add('Custom amounts');
    }

    if (template.validityDays != null) {
      parts.add('${template.validityDays} days');
    } else {
      parts.add('Never expires');
    }

    return parts.join(' • ');
  }

  Color _parseColor(String hex, BuildContext context) {
    try {
      final hexCode = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      final theme = Theme.of(context);
      return theme.colorScheme.outline;
    }
  }

  void _showTemplateEditor(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TemplateEditorDialog(
        securityContext: securityContext,
        template: template,
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final theme = Theme.of(context);
    final templateRepo = ref.read(giftCardTemplateRepositoryProvider);

    switch (action) {
      case 'edit':
        _showTemplateEditor(context, ref);
        break;
      case 'toggle':
        try {
          await templateRepo.updateTemplate(
            context: securityContext,
            templateId: template.id,
            updates: {'isActive': !template.isActive},
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                template.isActive
                    ? 'Template deactivated'
                    : 'Template activated',
              ),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(UserMessages.saveError)),
          );
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Template'),
            content: Text(
              'Are you sure you want to delete "${template.name}"? '
              'This cannot be undone.',
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            await templateRepo.deactivateTemplate(securityContext, template.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Template deleted')),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(UserMessages.saveError)),
            );
          }
        }
        break;
    }
  }
}
