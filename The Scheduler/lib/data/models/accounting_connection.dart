import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'accounting_connection.freezed.dart';
part 'accounting_connection.g.dart';

/// Supported accounting software providers.
enum AccountingProvider {
  @JsonValue('quickbooks')
  quickbooks,
  @JsonValue('xero')
  xero,
}

/// Extension for AccountingProvider display names.
extension AccountingProviderExt on AccountingProvider {
  String get displayName {
    switch (this) {
      case AccountingProvider.quickbooks:
        return 'QuickBooks Online';
      case AccountingProvider.xero:
        return 'Xero';
    }
  }

  String get iconAsset {
    switch (this) {
      case AccountingProvider.quickbooks:
        return 'assets/icons/quickbooks.png';
      case AccountingProvider.xero:
        return 'assets/icons/xero.png';
    }
  }
}

/// Status of the accounting connection.
enum ConnectionStatus {
  @JsonValue('active')
  active,
  @JsonValue('expired')
  expired,
  @JsonValue('error')
  error,
  @JsonValue('disconnected')
  disconnected,
}

/// Extension for ConnectionStatus display.
extension ConnectionStatusExt on ConnectionStatus {
  String get displayName {
    switch (this) {
      case ConnectionStatus.active:
        return 'Connected';
      case ConnectionStatus.expired:
        return 'Token Expired';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  bool get isHealthy => this == ConnectionStatus.active;
}

/// Represents a connection to an accounting software provider.
///
/// Stores OAuth tokens (encrypted), sync preferences, and account mappings.
/// Used to sync payments, invoices, and clients to QuickBooks or Xero.
@freezed
abstract class AccountingConnection with _$AccountingConnection {
  const AccountingConnection._();

  const factory AccountingConnection({
    /// Unique identifier.
    required String id,

    /// Business this connection belongs to.
    required String businessId,

    /// The accounting software provider.
    required AccountingProvider provider,

    /// Provider-specific company ID (QuickBooks Realm ID or Xero Tenant ID).
    required String providerCompanyId,

    /// Company name in the accounting software.
    String? providerCompanyName,

    /// OAuth access token (encrypted at rest).
    required String accessToken,

    /// OAuth refresh token (encrypted at rest).
    required String refreshToken,

    /// When the access token expires.
    @TimestampConverter() required DateTime tokenExpiresAt,

    /// Whether to sync invoices to accounting.
    @Default(true) bool syncInvoices,

    /// Whether to sync payments to accounting.
    @Default(true) bool syncPayments,

    /// Whether to sync clients/customers to accounting.
    @Default(true) bool syncClients,

    /// Whether to sync products/services to accounting.
    @Default(false) bool syncProducts,

    /// Mapped income account ID in accounting software.
    String? incomeAccountId,

    /// Mapped income account name for display.
    String? incomeAccountName,

    /// Mapped deposit/bank account ID.
    String? depositAccountId,

    /// Mapped deposit/bank account name for display.
    String? depositAccountName,

    /// Mapped tax code ID.
    String? taxCodeId,

    /// Mapped tax code name for display.
    String? taxCodeName,

    /// Current connection status.
    @Default(ConnectionStatus.active) ConnectionStatus status,

    /// Last successful sync timestamp.
    @NullableTimestampConverter() DateTime? lastSyncAt,

    /// Error message from last failed operation.
    String? lastSyncError,

    /// When the connection was established.
    @TimestampConverter() required DateTime connectedAt,

    /// User who set up the connection.
    String? connectedByUserId,

    // ============================================
    // HIPAA COMPLIANCE FIELDS
    // ============================================

    /// Whether HIPAA compliance mode is enabled.
    /// When true, client data will be de-identified before sync unless BAA is verified.
    /// Defaults to true for healthcare business safety.
    @Default(true) bool hipaaMode,

    /// Whether a Business Associate Agreement (BAA) has been verified.
    /// Only QuickBooks offers BAA - Xero does not.
    /// When false and hipaaMode is true, all synced data will be de-identified.
    @Default(false) bool baaVerified,

    /// When the BAA was verified by admin.
    @NullableTimestampConverter() DateTime? baaVerifiedAt,

    /// User ID of admin who verified the BAA.
    String? baaVerifiedByUserId,

    /// Record creation timestamp.
    @NullableTimestampConverter() DateTime? createdAt,

    /// Last update timestamp.
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _AccountingConnection;

  factory AccountingConnection.fromJson(Map<String, dynamic> json) =>
      _$AccountingConnectionFromJson(json);

  /// Whether the access token has expired.
  bool get isTokenExpired => tokenExpiresAt.isBefore(DateTime.now());

  /// Whether the token will expire soon (within 5 minutes).
  bool get isTokenExpiringSoon =>
      tokenExpiresAt.isBefore(DateTime.now().add(const Duration(minutes: 5)));

  /// Whether reauthentication is needed.
  bool get needsReauth =>
      status != ConnectionStatus.active || isTokenExpired;

  /// Whether the connection is healthy and ready for sync.
  bool get isHealthy =>
      status == ConnectionStatus.active && !isTokenExpired;

  /// Display name for the connection.
  String get displayName =>
      providerCompanyName ?? '${provider.displayName} Connection';

  /// Summary of what's being synced.
  String get syncSummary {
    final items = <String>[];
    if (syncInvoices) items.add('Invoices');
    if (syncPayments) items.add('Payments');
    if (syncClients) items.add('Clients');
    if (syncProducts) items.add('Products');
    return items.isEmpty ? 'Nothing' : items.join(', ');
  }

  /// Time since last sync, formatted.
  String? get lastSyncDisplay {
    if (lastSyncAt == null) return null;
    final diff = DateTime.now().difference(lastSyncAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ============================================
  // HIPAA COMPLIANCE HELPERS
  // ============================================

  /// Whether PHI (Protected Health Information) can be synced to this provider.
  /// Only true if:
  /// 1. BAA has been verified, AND
  /// 2. Provider is QuickBooks (Xero does NOT offer BAA)
  ///
  /// IMPORTANT: Xero does not currently offer Business Associate Agreements,
  /// so PHI should NEVER be synced to Xero regardless of baaVerified status.
  bool get canSyncPhi => baaVerified && provider == AccountingProvider.quickbooks;

  /// Whether data must be de-identified before syncing.
  /// True when HIPAA mode is enabled AND PHI cannot be synced.
  ///
  /// When true, the sync service should:
  /// - Use anonymized customer names: "Client-XXXXXXXX"
  /// - NOT sync emails, phones, or addresses
  /// - Use generic invoice descriptions: "Professional Services"
  /// - NOT include service/treatment names
  bool get requiresDeidentification => hipaaMode && !canSyncPhi;

  /// Warning message for HIPAA compliance status.
  String? get hipaaWarning {
    if (!hipaaMode) return null;
    if (provider == AccountingProvider.xero) {
      return 'Xero does not offer Business Associate Agreements (BAA). '
          'Client data will always be de-identified for HIPAA compliance.';
    }
    if (!baaVerified) {
      return 'BAA not verified. Client data will be de-identified. '
          'Verify your BAA to sync full client details.';
    }
    return null;
  }

  /// Whether the provider supports BAA.
  bool get providerSupportsBaa => provider == AccountingProvider.quickbooks;
}
