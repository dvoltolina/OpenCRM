import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../../../core/services/accounting_oauth_service.dart';
import '../../../../core/services/accounting_sync_service.dart';
import '../../../../data/models/accounting_connection.dart';
import '../../../../data/models/security_context.dart';

/// Panel for configuring accounting sync settings.
///
/// Provides:
/// - Toggles for what to sync (invoices, payments, clients)
/// - Dropdown selectors for account mappings
/// - Manual sync button
class SyncSettingsPanel extends ConsumerStatefulWidget {
  const SyncSettingsPanel({
    required this.connection,
    required this.onSettingsChanged,
    super.key,
  });

  final AccountingConnection connection;
  final VoidCallback onSettingsChanged;

  @override
  ConsumerState<SyncSettingsPanel> createState() => _SyncSettingsPanelState();
}

class _SyncSettingsPanelState extends ConsumerState<SyncSettingsPanel> {
  final AccountingOAuthService _oauthService = AccountingOAuthService();
  final AccountingSyncService _syncService = AccountingSyncService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isSaving = false;
  bool _isSyncing = false;
  bool _isLoadingAccounts = false;
  String? _errorMessage;

  // Sync settings
  late bool _syncInvoices;
  late bool _syncPayments;
  late bool _syncClients;

  // Account mappings
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _taxCodes = [];
  String? _selectedIncomeAccount;
  String? _selectedDepositAccount;
  String? _selectedTaxCode;

  @override
  void initState() {
    super.initState();
    _syncInvoices = widget.connection.syncInvoices;
    _syncPayments = widget.connection.syncPayments;
    _syncClients = widget.connection.syncClients;
    _selectedIncomeAccount = widget.connection.incomeAccountId;
    _selectedDepositAccount = widget.connection.depositAccountId;
    _selectedTaxCode = widget.connection.taxCodeId;
    _loadAccountOptions();
  }

  Future<SecurityContext> _getSecurityContext() async {
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

  Future<void> _loadAccountOptions() async {
    setState(() {
      _isLoadingAccounts = true;
    });

    try {
      final context = await _getSecurityContext();

      // Determine which function to call based on provider
      final isQuickBooks =
          widget.connection.provider == AccountingProvider.quickbooks;

      final accountsFunction = isQuickBooks
          ? _functions.httpsCallable('getQuickBooksAccounts')
          : _functions.httpsCallable('getXeroAccounts');

      final taxFunction = isQuickBooks
          ? _functions.httpsCallable('getQuickBooksTaxCodes')
          : _functions.httpsCallable('getXeroTaxRates');

      // Fetch accounts
      final accountsResult = await accountsFunction.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'connectionId': widget.connection.id,
        'realmId': widget.connection.providerCompanyId,
        'tenantId': widget.connection.providerCompanyId,
        'accountTypes': isQuickBooks
            ? ['Income', 'Bank']
            : ['REVENUE', 'BANK'],
      });

      if (accountsResult.data['success'] == true) {
        setState(() {
          _accounts =
              List<Map<String, dynamic>>.from(accountsResult.data['accounts']);
        });
      }

      // Fetch tax codes
      final taxResult = await taxFunction.call<Map<String, dynamic>>({
        'businessId': context.businessId,
        'connectionId': widget.connection.id,
        'realmId': widget.connection.providerCompanyId,
        'tenantId': widget.connection.providerCompanyId,
      });

      if (taxResult.data['success'] == true) {
        setState(() {
          _taxCodes = List<Map<String, dynamic>>.from(
            taxResult.data['taxCodes'] ?? taxResult.data['taxRates'] ?? [],
          );
        });
      }
    } catch (e) {
      // Don't show error - just proceed without dropdowns
      debugPrint('Failed to load account options: $e');
    } finally {
      setState(() {
        _isLoadingAccounts = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final context = await _getSecurityContext();

      await _oauthService.updateSyncSettings(
        context: context,
        connectionId: widget.connection.id,
        syncInvoices: _syncInvoices,
        syncPayments: _syncPayments,
        syncClients: _syncClients,
      );

      await _oauthService.updateAccountMappings(
        context: context,
        connectionId: widget.connection.id,
        incomeAccountId: _selectedIncomeAccount,
        incomeAccountName: _getAccountName(_selectedIncomeAccount),
        depositAccountId: _selectedDepositAccount,
        depositAccountName: _getAccountName(_selectedDepositAccount),
        taxCodeId: _selectedTaxCode,
        taxCodeName: _getTaxCodeName(_selectedTaxCode),
      );

      widget.onSettingsChanged();

      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save settings: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String? _getAccountName(String? accountId) {
    if (accountId == null) return null;
    final account = _accounts.firstWhere(
      (a) => a['id'] == accountId,
      orElse: () => {},
    );
    return account['name'] as String?;
  }

  String? _getTaxCodeName(String? taxCodeId) {
    if (taxCodeId == null) return null;
    final taxCode = _taxCodes.firstWhere(
      (t) => (t['id'] ?? t['taxType']) == taxCodeId,
      orElse: () => {},
    );
    return taxCode['name'] as String?;
  }

  Future<void> _syncNow() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      final securityContext = await _getSecurityContext();

      final result = await _syncService.syncToAccounting(
        context: securityContext,
      );

      widget.onSettingsChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync complete: ${result.successCount} succeeded, '
              '${result.failedCount} failed',
            ),
            backgroundColor:
                result.failedCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sync failed: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Sync Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 16),
            ],

            // Sync toggles
            Text(
              'What to sync',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _buildToggle(
              'Invoices & Payments',
              'Sync sales invoices and payments',
              _syncInvoices && _syncPayments,
              (value) => setState(() {
                _syncInvoices = value;
                _syncPayments = value;
              }),
            ),
            _buildToggle(
              'Customers',
              'Sync client records as customers',
              _syncClients,
              (value) => setState(() => _syncClients = value),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Account mappings
            Text(
              'Account Mappings',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (_isLoadingAccounts)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildDropdown(
                'Income Account',
                'Where revenue is recorded',
                _accounts.where((a) =>
                    a['type'] == 'Income' || a['type'] == 'REVENUE').toList(),
                _selectedIncomeAccount,
                (value) => setState(() => _selectedIncomeAccount = value),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                'Deposit Account',
                'Where payments are deposited',
                _accounts.where((a) =>
                    a['type'] == 'Bank' || a['type'] == 'BANK').toList(),
                _selectedDepositAccount,
                (value) => setState(() => _selectedDepositAccount = value),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                'Tax Code',
                'Default tax rate for invoices',
                _taxCodes,
                _selectedTaxCode,
                (value) => setState(() => _selectedTaxCode = value),
                isTaxCode: true,
              ),
            ],
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdown(
    String label,
    String hint,
    List<Map<String, dynamic>> items,
    String? selectedValue,
    ValueChanged<String?> onChanged, {
    bool isTaxCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        initialValue: selectedValue,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) {
            final id = isTaxCode
                ? (item['id'] ?? item['taxType']) as String
                : item['id'] as String;
            final name = item['name'] as String;
            return DropdownMenuItem(
              value: id,
              child: Text(name),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
