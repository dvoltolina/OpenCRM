import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/ui/components/components.dart';
import '../../../../core/utils/secure_error_handler.dart';
import '../../../../data/models/user_role.dart';

/// Admin-only card to toggle email/SMS delivery per tenant.
class CommunicationChannelsCard extends ConsumerStatefulWidget {
  const CommunicationChannelsCard({super.key});

  @override
  ConsumerState<CommunicationChannelsCard> createState() =>
      _CommunicationChannelsCardState();
}

class _CommunicationChannelsCardState
    extends ConsumerState<CommunicationChannelsCard> {
  bool? _emailEnabled;
  bool? _smsEnabled;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    _emailEnabled ??= config.communicationConfig.emailEnabled;
    _smsEnabled ??= config.communicationConfig.smsEnabled;
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const AppCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (error, stackTrace) => const AppCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text(SecureErrorHandler.loadingFailed),
        ),
      ),
      data: (securityContext) {
        if (securityContext == null ||
            (securityContext.role != UserRole.owner &&
                securityContext.role != UserRole.admin)) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Communication Channels',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              VSpace.sm,
              _ChannelToggleTile(
                title: 'Enable Email',
                subtitle: 'Send confirmations/reminders via email',
                value: _emailEnabled ?? false,
                onChanged: (value) => setState(() => _emailEnabled = value),
              ),
              _ChannelToggleTile(
                title: 'Enable SMS',
                subtitle: 'Send confirmations/reminders via SMS',
                value: _smsEnabled ?? false,
                onChanged: (value) => setState(() => _smsEnabled = value),
              ),
              const Divider(),
              _SaveButtons(
                isSaving: _isSaving,
                onSave: () => _saveConfig(config, context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveConfig(AppConfig config, BuildContext context) async {
    if (_emailEnabled == null || _smsEnabled == null) return;

    final repo = ref.read(communicationRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);
    try {
      final updatedConfig = config.communicationConfig.copyWith(
        emailEnabled: _emailEnabled,
        smsEnabled: _smsEnabled,
      );
      await repo.updateCommunicationConfig(updatedConfig);
      messenger.showSnackBar(
        const SnackBar(content: Text('Communication settings saved')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save communication settings')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ChannelToggleTile extends StatelessWidget {
  const _ChannelToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SaveButtons extends StatelessWidget {
  const _SaveButtons({
    required this.onSave,
    required this.isSaving,
  });

  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        FilledButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: const Icon(Icons.save),
          label: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
