import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/integration_config.dart';

/// Result returned after completing an OAuth handshake.
class OAuthTokenBundle {
  const OAuthTokenBundle({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.idToken,
    this.accountEmail,
    this.accountName,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? idToken;
  final String? accountEmail;
  final String? accountName;

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;
}

/// Handles platform-aware OAuth flows for Google and Microsoft providers.
class OAuthService {
  OAuthService({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  Future<OAuthTokenBundle> authenticateGoogleCalendar(
    OAuthClientConfig config,
  ) async {
    if (kIsWeb) {
      final googleSignIn = GoogleSignIn(scopes: config.scopes);
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        throw Exception('Failed to obtain Google access token.');
      }

      return OAuthTokenBundle(
        accessToken: auth.accessToken!,
        refreshToken: account.serverAuthCode,
        expiresAt: DateTime.now().add(const Duration(minutes: 50)),
        idToken: auth.idToken,
        accountEmail: account.email,
        accountName: account.displayName,
      );
    }

    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        config.clientId,
        config.redirectUri,
        scopes: config.scopes,
        promptValues: ['consent'],
        additionalParameters: config.additionalParams,
      ),
    );

    if (result.accessToken == null) {
      throw Exception('Google OAuth failed to return an access token.');
    }

    return OAuthTokenBundle(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      expiresAt: result.accessTokenExpirationDateTime,
      idToken: result.idToken,
      accountEmail: result.tokenAdditionalParameters?['email'] as String?,
      accountName: result.tokenAdditionalParameters?['name'] as String?,
    );
  }

  Future<OAuthTokenBundle> authenticateMicrosoftCalendar(
    OAuthClientConfig config,
  ) async {
    // Microsoft Graph requires true OAuth2 authorization code flow with PKCE.
    if (kIsWeb) {
      throw UnsupportedError(
        'Microsoft Graph OAuth is not supported on Flutter Web yet. '
        'Use native platforms or connect via desktop browser.',
      );
    }

    final authority = config.tenantId == null
        ? 'https://login.microsoftonline.com/common'
        : 'https://login.microsoftonline.com/${config.tenantId}';

    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        config.clientId,
        config.redirectUri,
        scopes: config.scopes,
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: '$authority/oauth2/v2.0/authorize',
          tokenEndpoint: '$authority/oauth2/v2.0/token',
        ),
        additionalParameters: {
          ...config.additionalParams,
          'prompt': 'consent',
        },
      ),
    );

    if (result.accessToken == null) {
      throw Exception('Microsoft OAuth failed to return an access token.');
    }

    return OAuthTokenBundle(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      expiresAt: result.accessTokenExpirationDateTime,
      idToken: result.idToken,
      accountEmail: result.tokenAdditionalParameters?['preferred_username']
          as String?,
      accountName: result.tokenAdditionalParameters?['name'] as String?,
    );
  }

  /// Exchange a Zoom server-to-server OAuth token (account credentials flow).
  Future<OAuthTokenBundle> authenticateZoomServerToServer(
    ZoomConfig config,
  ) async {
    final basicAuth = base64Encode(utf8.encode('${config.clientId}:${config.clientSecret}'));
    final httpClient = HttpClient();
    try {
      final request = await httpClient.postUrl(Uri.parse(config.tokenEndpoint));
      request.headers
        ..set('Authorization', 'Basic $basicAuth')
        ..set('Content-Type', 'application/x-www-form-urlencoded');
      request.write('grant_type=account_credentials&account_id=${config.accountId}');
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();

      if (response.statusCode != 200) {
        throw Exception('Zoom token exchange failed (${response.statusCode}): $body');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final accessToken = json['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('Zoom response missing access_token.');
      }

      final expiresInSeconds = json['expires_in'] as int? ?? 3600;
      return OAuthTokenBundle(
        accessToken: accessToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
      );
    } finally {
      httpClient.close();
    }
  }
}
