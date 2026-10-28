import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/accounting_connection.dart';
import '../../data/models/security_context.dart';
import '../../data/repositories/accounting_connection_repository.dart';

/// Service for managing OAuth authentication with accounting providers.
///
/// Handles the OAuth 2.0 flow for QuickBooks Online and Xero:
/// 1. Generate authorization URL
/// 2. Exchange authorization code for tokens (via Cloud Function)
/// 3. Refresh expired tokens (via Cloud Function)
/// 4. Disconnect/revoke tokens
///
/// **Security Note:** OAuth client secrets are never stored or used client-side.
/// All token operations go through Cloud Functions to protect credentials.
class AccountingOAuthService {
  AccountingOAuthService({
    AccountingConnectionRepository? repository,
    FirebaseFunctions? functions,
  })  : _repository = repository ?? AccountingConnectionRepository(),
        _functions = functions ?? FirebaseFunctions.instance;

  final AccountingConnectionRepository _repository;
  final FirebaseFunctions _functions;

  // OAuth endpoints
  static const _quickbooksAuthUrl =
      'https://appcenter.intuit.com/connect/oauth2';
  static const _xeroAuthUrl =
      'https://login.xero.com/identity/connect/authorize';

  // Required scopes for each provider
  static const _quickbooksScopes = [
    'com.intuit.quickbooks.accounting',
    'openid',
    'profile',
    'email',
  ];

  static const _xeroScopes = [
    'openid',
    'profile',
    'email',
    'accounting.transactions',
    'accounting.contacts',
    'accounting.settings.read',
    'offline_access',
  ];

  /// Generate OAuth authorization URL for a provider.
  ///
  /// The URL should be opened in a browser/webview. After user authorization,
  /// the provider will redirect back to [redirectUri] with an authorization code.
  ///
  /// The [state] parameter encodes the business ID and timestamp for security.
  String getAuthorizationUrl({
    required AccountingProvider provider,
    required String businessId,
    required String redirectUri,
    required String clientId,
  }) {
    final state = _encodeState(businessId);

    switch (provider) {
      case AccountingProvider.quickbooks:
        return _buildQuickBooksAuthUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          state: state,
        );
      case AccountingProvider.xero:
        return _buildXeroAuthUrl(
          clientId: clientId,
          redirectUri: redirectUri,
          state: state,
        );
    }
  }

  String _buildQuickBooksAuthUrl({
    required String clientId,
    required String redirectUri,
    required String state,
  }) {
    final params = {
      'client_id': clientId,
      'response_type': 'code',
      'scope': _quickbooksScopes.join(' '),
      'redirect_uri': redirectUri,
      'state': state,
    };

    final uri = Uri.parse(_quickbooksAuthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  String _buildXeroAuthUrl({
    required String clientId,
    required String redirectUri,
    required String state,
  }) {
    final params = {
      'client_id': clientId,
      'response_type': 'code',
      'scope': _xeroScopes.join(' '),
      'redirect_uri': redirectUri,
      'state': state,
    };

    final uri = Uri.parse(_xeroAuthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Encode state parameter with business ID and timestamp.
  String _encodeState(String businessId) {
    final stateData = {
      'businessId': businessId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return base64Url.encode(utf8.encode(json.encode(stateData)));
  }

  /// Decode state parameter to extract business ID.
  String? decodeStateBusinessId(String state) {
    try {
      final decoded = utf8.decode(base64Url.decode(state));
      final data = json.decode(decoded) as Map<String, dynamic>;
      return data['businessId'] as String?;
    } catch (e) {
      debugPrint('Failed to decode state'); // avoid leaking details
      return null;
    }
  }

  /// Validate state parameter timestamp (must be within 10 minutes).
  bool isStateValid(String state) {
    try {
      final decoded = utf8.decode(base64Url.decode(state));
      final data = json.decode(decoded) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) return false;

      final stateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(stateTime);
      return age.inMinutes < 10;
    } catch (e) {
      return false;
    }
  }

  /// Exchange authorization code for access tokens.
  ///
  /// This calls a Cloud Function to perform the token exchange,
  /// keeping OAuth secrets secure on the server.
  ///
  /// Returns the created [AccountingConnection].
  Future<AccountingConnection> exchangeCodeForTokens({
    required SecurityContext context,
    required AccountingProvider provider,
    required String authorizationCode,
    required String redirectUri,
  }) async {
    context.verifyBusinessAccess();

    // Call Cloud Function to exchange code for tokens
    final callable = _functions.httpsCallable('exchangeAccountingOAuthCode');
    final result = await callable.call<Map<String, dynamic>>({
      'provider': provider.name,
      'code': authorizationCode,
      'redirectUri': redirectUri,
      'businessId': context.businessId,
    });

    final data = result.data;

    // Validate response
    if (data['error'] != null) {
      throw AccountingOAuthException(
        data['error'] as String,
        code: data['errorCode'] as String?,
      );
    }

    // Create connection record
    final connection = await _repository.createConnection(
      context: context,
      provider: provider,
      providerCompanyId: data['companyId'] as String,
      providerCompanyName: data['companyName'] as String?,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      tokenExpiresAt: DateTime.parse(data['expiresAt'] as String),
    );

    return connection;
  }

  /// Refresh an expired access token.
  ///
  /// Calls a Cloud Function to refresh the token using the refresh token.
  /// Updates the stored tokens on success.
  Future<AccountingConnection> refreshAccessToken({
    required SecurityContext context,
    required AccountingConnection connection,
  }) async {
    context.verifyBusinessAccess();

    // Skip if token is still valid
    if (!connection.isTokenExpiringSoon) {
      return connection;
    }

    // Call Cloud Function to refresh token
    final callable = _functions.httpsCallable('refreshAccountingOAuthToken');
    final result = await callable.call<Map<String, dynamic>>({
      'provider': connection.provider.name,
      'refreshToken': connection.refreshToken,
      'businessId': context.businessId,
    });

    final data = result.data;

    // Validate response
    if (data['error'] != null) {
      // Update connection status to expired
      await _repository.updateStatus(
        context: context,
        connectionId: connection.id,
        status: ConnectionStatus.expired,
        errorMessage: data['error'] as String,
      );

      throw AccountingOAuthException(
        data['error'] as String,
        code: data['errorCode'] as String?,
      );
    }

    // Update stored tokens
    final updated = await _repository.updateTokens(
      context: context,
      connectionId: connection.id,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String? ?? connection.refreshToken,
      tokenExpiresAt: DateTime.parse(data['expiresAt'] as String),
    );

    return updated;
  }

  /// Ensure connection has a valid access token.
  ///
  /// Refreshes the token if expired or expiring soon.
  Future<AccountingConnection> ensureValidToken({
    required SecurityContext context,
    required AccountingConnection connection,
  }) async {
    if (connection.isTokenExpiringSoon) {
      return refreshAccessToken(context: context, connection: connection);
    }
    return connection;
  }

  /// Disconnect from accounting provider.
  ///
  /// Revokes tokens via Cloud Function and updates connection status.
  Future<void> disconnect({
    required SecurityContext context,
    required AccountingConnection connection,
  }) async {
    context.verifyBusinessAccess();

    try {
      // Call Cloud Function to revoke tokens
      final callable = _functions.httpsCallable('revokeAccountingOAuthToken');
      await callable.call<Map<String, dynamic>>({
        'provider': connection.provider.name,
        'accessToken': connection.accessToken,
        'businessId': context.businessId,
      });
    } catch (_) {
      // Log but don't fail - we still want to clear local tokens
      debugPrint('Failed to revoke token');
    }

    // Update local connection status
    await _repository.disconnectConnection(
      context: context,
      connectionId: connection.id,
    );
  }

  /// Get the active connection for the current business.
  Future<AccountingConnection?> getActiveConnection({
    required SecurityContext context,
  }) async {
    return _repository.getActiveConnection(context: context);
  }

  /// Get connection for a specific provider.
  Future<AccountingConnection?> getConnectionByProvider({
    required SecurityContext context,
    required AccountingProvider provider,
  }) async {
    return _repository.getConnectionByProvider(
      context: context,
      provider: provider,
    );
  }

  /// Update connection sync settings.
  Future<AccountingConnection> updateSyncSettings({
    required SecurityContext context,
    required String connectionId,
    bool? syncInvoices,
    bool? syncPayments,
    bool? syncClients,
    bool? syncProducts,
  }) async {
    return _repository.updateConnection(
      context: context,
      connectionId: connectionId,
      syncInvoices: syncInvoices,
      syncPayments: syncPayments,
      syncClients: syncClients,
      syncProducts: syncProducts,
    );
  }

  /// Update account mappings.
  Future<AccountingConnection> updateAccountMappings({
    required SecurityContext context,
    required String connectionId,
    String? incomeAccountId,
    String? incomeAccountName,
    String? depositAccountId,
    String? depositAccountName,
    String? taxCodeId,
    String? taxCodeName,
  }) async {
    return _repository.updateConnection(
      context: context,
      connectionId: connectionId,
      incomeAccountId: incomeAccountId,
      incomeAccountName: incomeAccountName,
      depositAccountId: depositAccountId,
      depositAccountName: depositAccountName,
      taxCodeId: taxCodeId,
      taxCodeName: taxCodeName,
    );
  }
}

/// Exception thrown by AccountingOAuthService.
class AccountingOAuthException implements Exception {
  AccountingOAuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AccountingOAuthException: $message (code: $code)';
}

/// OAuth callback result from URL parsing.
class OAuthCallbackResult {
  const OAuthCallbackResult({
    required this.success,
    this.code,
    this.state,
    this.error,
    this.errorDescription,
  });

  final bool success;
  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  /// Parse OAuth callback URL parameters.
  factory OAuthCallbackResult.fromUri(Uri uri) {
    final params = uri.queryParameters;

    if (params.containsKey('error')) {
      return OAuthCallbackResult(
        success: false,
        error: params['error'],
        errorDescription: params['error_description'],
        state: params['state'],
      );
    }

    if (params.containsKey('code')) {
      return OAuthCallbackResult(
        success: true,
        code: params['code'],
        state: params['state'],
      );
    }

    return const OAuthCallbackResult(
      success: false,
      error: 'missing_code',
      errorDescription: 'Authorization code not found in callback URL',
    );
  }
}
