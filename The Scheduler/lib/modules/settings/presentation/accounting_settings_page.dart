import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/accounting_oauth_service.dart';
import '../../../core/ui/components/components.dart';
import '../../../data/models/accounting_connection.dart';
import '../../../data/models/security_context.dart';
import 'widgets/accounting_connection_card.dart';
import 'widgets/sync_history_panel.dart';
import 'widgets/sync_settings_panel.dart';

/// Page for managing accounting software integrations (QuickBooks, Xero).
///
/// Allows admins to:
/// - Connect to QuickBooks Online or Xero
/// - Configure sync settings and account mappings
/// - View sync history and retry failed syncs
/// - Disconnect from accounting software
class AccountingSettingsPage extends ConsumerStatefulWidget {
  const AccountingSettingsPage({super.key});

  @override
  ConsumerState<AccountingSettingsPage> createState() =>
      _AccountingSettingsPageState();
}

class _AccountingSettingsPageState
    extends ConsumerState<AccountingSettingsPage> {
  final AccountingOAuthService _oauthService = AccountingOAuthService();

  bool _isLoading = false;
  bool _isConnecting = false;
  AccountingConnection? _connection;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  Future<void> _loadConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final context = await _getSecurityContext();
      final connection = await _oauthService.getActiveConnection(
        context: context,
      );
      setState(() {
        _connection = connection;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load connection: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<SecurityContext> _getSecurityContext() async {
    final securityContext = ref.read(securityContextProvider).valueOrNull;
    if (securityContext != null) return securityContext;

    final authService = ref.read(authStateServiceProvider);
    final profile = await authService.getCurrentUserProfile();
    if (profile == null) {
      throw Exception('User not authenticated');
    }
    return SecurityContext(
      userId: profile.id,
      businessId: profile.businessId,
      role: profile.role,
    );
  }

  // OAuth client IDs - these should be configured in your environment
  // For production, store in Firebase Remote Config or environment variables
  static const String _quickbooksClientId =
      String.fromEnvironment('QUICKBOOKS_CLIENT_ID', defaultValue: '');
  static const String _xeroClientId =
      String.fromEnvironment('XERO_CLIENT_ID', defaultValue: '');
  static const String _oauthRedirectBase =
      String.fromEnvironment('OAUTH_REDIRECT_BASE', defaultValue: 'https://yourdomain.com');

  Future<void> _connectProvider(AccountingProvider provider) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final securityContext = await _getSecurityContext();

      // Get client ID from environment
      final clientId = provider == AccountingProvider.quickbooks
          ? _quickbooksClientId
          : _xeroClientId;

      if (clientId.isEmpty) {
        throw Exception(
          '${provider.displayName} is not configured. '
          'Please contact your administrator.',
        );
      }

      // Get redirect URI
      final redirectUri = '$_oauthRedirectBase/oauth/callback/${provider.name}';

      // Generate authorization URL
      final authUrl = _oauthService.getAuthorizationUrl(
        provider: provider,
        businessId: securityContext.businessId,
        redirectUri: redirectUri,
        clientId: clientId,
      );

      // Open in browser
      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open authorization URL');
      }

      // Show dialog to wait for callback
      if (mounted) {
        await _showWaitingDialog(provider);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _showWaitingDialog(AccountingProvider provider) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Connecting to ${provider.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            VSpace.md,
            const Text(
              'Complete the authorization in your browser.\n'
              'This dialog will close automatically when done.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadConnection();
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Accounting'),
        content: const Text(
          'Are you sure you want to disconnect from your accounting software?\n\n'
          'This will not delete any data that has already been synced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true || _connection == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final context = await _getSecurityContext();
      await _oauthService.disconnect(
        context: context,
        connection: _connection!,
      );
      setState(() {
        _connection = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Disconnected successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to disconnect: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityContextAsync = ref.watch(securityContextProvider);

    return securityContextAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading session: $error')),
      data: (_) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ScrollablePageScaffold(
          title: 'Accounting',
          showBackButton: false,
          showAppBar: false,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                VSpace.lg,
              ],
              if (_connection == null)
                _buildDisconnectedState(theme)
              else
                _buildConnectedState(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            HSpace.sm,
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        AppCard(
          child: Column(
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              VSpace.lg,
              Text(
                'Connect Your Accounting Software',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              VSpace.xs,
              Text(
                'Automatically sync your payments and customers to '
                'QuickBooks Online or Xero.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        VSpace.xl,

        // Provider buttons
        _buildProviderButton(
          provider: AccountingProvider.quickbooks,
          icon: Icons.calculate, // Placeholder - use actual logo asset
          color: const Color(0xFF2CA01C), // QuickBooks green
        ),
        VSpace.md,
        _buildProviderButton(
          provider: AccountingProvider.xero,
          icon: Icons.auto_graph, // Placeholder - use actual logo asset
          color: const Color(0xFF13B5EA), // Xero blue
        ),
        VSpace.xl,

        // Info section
        CardSection(
          title: 'What gets synced',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(Icons.people, 'Customers'),
              VSpace.xs,
              _buildInfoItem(Icons.receipt, 'Invoices'),
              VSpace.xs,
              _buildInfoItem(Icons.payment, 'Payments'),
              VSpace.md,
              Text(
                'Your data is synced securely using OAuth 2.0. '
                'We never store your accounting password.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderButton({
    required AccountingProvider provider,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isConnecting ? null : () => _connectProvider(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        icon: _isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text('Connect to ${provider.displayName}'),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.sm, color: Theme.of(context).colorScheme.primary),
          HSpace.sm,
          Text(text),
        ],
      ),
    );
  }

  Widget _buildConnectedState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connection card
        AccountingConnectionCard(
          connection: _connection!,
          onDisconnect: _disconnect,
          onReconnect: () => _connectProvider(_connection!.provider),
        ),
        VSpace.lg,

        // Sync settings
        SyncSettingsPanel(
          connection: _connection!,
          onSettingsChanged: _loadConnection,
        ),
        VSpace.lg,

        // Sync history
        SyncHistoryPanel(
          connection: _connection!,
          onRetryComplete: _loadConnection,
        ),
      ],
    );
  }
}
