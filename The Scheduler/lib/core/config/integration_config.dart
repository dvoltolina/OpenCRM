
/// Supported outbound email providers.
enum EmailProviderType {
  mock,
  sendGrid,
  awsSes,
}

/// Supported outbound SMS providers.
enum SmsProviderType {
  mock,
  twilio,
  awsSns,
}

/// Supported calendar sync providers.
enum CalendarProviderType {
  google,
  microsoft,
}

/// Telehealth platforms that can be auto-attached to appointments.
enum TelehealthProviderType {
  none,
  zoom,
  googleMeet,
}

/// OAuth client configuration used for Google/Microsoft integrations.
class OAuthClientConfig {
  const OAuthClientConfig({
    required this.clientId,
    required this.redirectUri,
    required this.scopes,
    this.tenantId,
    this.additionalParams = const {},
  });

  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final String? tenantId;
  final Map<String, String> additionalParams;

  OAuthClientConfig copyWith({
    String? clientId,
    String? redirectUri,
    List<String>? scopes,
    String? tenantId,
    Map<String, String>? additionalParams,
  }) {
    return OAuthClientConfig(
      clientId: clientId ?? this.clientId,
      redirectUri: redirectUri ?? this.redirectUri,
      scopes: scopes ?? this.scopes,
      tenantId: tenantId ?? this.tenantId,
      additionalParams: additionalParams ?? this.additionalParams,
    );
  }
}

/// Configuration for SendGrid email delivery.
class SendGridConfig {
  const SendGridConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.sendgrid.com/v3',
  });

  final String apiKey;
  final String baseUrl;

  SendGridConfig copyWith({
    String? apiKey,
    String? baseUrl,
  }) {
    return SendGridConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

/// Configuration for AWS SES email delivery.
class AwsSesConfig {
  const AwsSesConfig({
    required this.region,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.sessionToken,
  });

  final String region;
  final String accessKeyId;
  final String secretAccessKey;
  final String? sessionToken;

  AwsSesConfig copyWith({
    String? region,
    String? accessKeyId,
    String? secretAccessKey,
    String? sessionToken,
  }) {
    return AwsSesConfig(
      region: region ?? this.region,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }
}

/// Configuration for Twilio SMS delivery.
class TwilioConfig {
  const TwilioConfig({
    required this.accountSid,
    required this.authToken,
    required this.fromPhone,
    this.messagingServiceSid,
    this.baseUrl = 'https://api.twilio.com/2010-04-01',
  });

  final String accountSid;
  final String authToken;
  final String fromPhone;
  final String? messagingServiceSid;
  final String baseUrl;

  TwilioConfig copyWith({
    String? accountSid,
    String? authToken,
    String? fromPhone,
    String? messagingServiceSid,
    String? baseUrl,
  }) {
    return TwilioConfig(
      accountSid: accountSid ?? this.accountSid,
      authToken: authToken ?? this.authToken,
      fromPhone: fromPhone ?? this.fromPhone,
      messagingServiceSid: messagingServiceSid ?? this.messagingServiceSid,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

/// Configuration for AWS SNS SMS delivery.
class AwsSnsConfig {
  const AwsSnsConfig({
    required this.region,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.sessionToken,
  });

  final String region;
  final String accessKeyId;
  final String secretAccessKey;
  final String? sessionToken;

  AwsSnsConfig copyWith({
    String? region,
    String? accessKeyId,
    String? secretAccessKey,
    String? sessionToken,
  }) {
    return AwsSnsConfig(
      region: region ?? this.region,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }
}

/// Configuration for Zoom telehealth integration.
class ZoomConfig {
  const ZoomConfig({
    required this.accountId,
    required this.clientId,
    required this.clientSecret,
    this.baseUrl = 'https://api.zoom.us/v2',
    this.tokenEndpoint = 'https://zoom.us/oauth/token',
  });

  final String accountId;
  final String clientId;
  final String clientSecret;
  final String baseUrl;
  final String tokenEndpoint;

  ZoomConfig copyWith({
    String? accountId,
    String? clientId,
    String? clientSecret,
    String? baseUrl,
    String? tokenEndpoint,
  }) {
    return ZoomConfig(
      accountId: accountId ?? this.accountId,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      baseUrl: baseUrl ?? this.baseUrl,
      tokenEndpoint: tokenEndpoint ?? this.tokenEndpoint,
    );
  }
}

/// High-level integration configuration referenced throughout the app.
class IntegrationConfig {
  const IntegrationConfig({
    required this.emailProvider,
    required this.smsProvider,
    required this.enableGoogleCalendarSync,
    required this.enableMicrosoftCalendarSync,
    required this.defaultCalendarSyncInterval,
    required this.googleOAuth,
    required this.microsoftOAuth,
    required this.sendGrid,
    required this.awsSes,
    required this.twilio,
    required this.awsSns,
    required this.zoom,
    required this.defaultTelehealthProvider,
    required this.integrationApiBaseUrl,
    required this.tokenEncryptionKey,
    this.allowProviderOverrides = true,
  }) : assert(tokenEncryptionKey.length >= 32,
            'tokenEncryptionKey must be at least 32 characters for AES-256');

  final EmailProviderType emailProvider;
  final SmsProviderType smsProvider;
  final bool enableGoogleCalendarSync;
  final bool enableMicrosoftCalendarSync;
  final Duration defaultCalendarSyncInterval;
  final bool allowProviderOverrides;
  final OAuthClientConfig googleOAuth;
  final OAuthClientConfig microsoftOAuth;
  final SendGridConfig sendGrid;
  final AwsSesConfig awsSes;
  final TwilioConfig twilio;
  final AwsSnsConfig awsSns;
  final ZoomConfig zoom;
  final TelehealthProviderType defaultTelehealthProvider;
  final Uri integrationApiBaseUrl;
  final String tokenEncryptionKey;

  /// Factory for default clinic configuration.
  ///
  /// SECURITY WARNING: This factory uses placeholder values for demonstration only.
  /// DO NOT use in production. Production apps must:
  /// 1. Load actual credentials from environment variables or secure storage
  /// 2. Use Cloud Functions for secure API key management
  /// 3. Never commit real API keys to version control
  ///
  /// Example production usage:
  /// ```dart
  /// final config = IntegrationConfig(
  ///   emailProvider: EmailProviderType.sendGrid,
  ///   sendGrid: SendGridConfig(
  ///     apiKey: Platform.environment['SENDGRID_API_KEY'] ?? '',
  ///   ),
  ///   twilio: TwilioConfig(
  ///     accountSid: Platform.environment['TWILIO_ACCOUNT_SID'] ?? '',
  ///     authToken: Platform.environment['TWILIO_AUTH_TOKEN'] ?? '',
  ///     fromPhone: Platform.environment['TWILIO_FROM_PHONE'] ?? '',
  ///   ),
  ///   tokenEncryptionKey: Platform.environment['TOKEN_ENCRYPTION_KEY'] ?? '',
  ///   ...
  /// );
  /// ```
  factory IntegrationConfig.defaultClinic() {
    // SECURITY: These are placeholders only - replace with environment variables
    // Must be at least 32 chars for AES-256 encryption
    const placeholderKey = ''; // Configure each enabled integration before use.

    return IntegrationConfig(
      emailProvider: EmailProviderType.sendGrid,
      smsProvider: SmsProviderType.twilio,
      enableGoogleCalendarSync: true,
      enableMicrosoftCalendarSync: true,
      defaultCalendarSyncInterval: const Duration(minutes: 15),
      googleOAuth: const OAuthClientConfig(
        clientId: placeholderKey, // Load from env: GOOGLE_OAUTH_CLIENT_ID
        redirectUri: 'com.scheduler.app:/oauth2redirect/google',
        scopes: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
          'openid',
          'email',
          'profile',
        ],
      ),
      microsoftOAuth: const OAuthClientConfig(
        clientId: placeholderKey, // Load from env: MICROSOFT_CLIENT_ID
        tenantId: 'common',
        redirectUri: 'msauth.com.scheduler.app://auth',
        scopes: [
          'offline_access',
          'Calendars.Read',
          'Calendars.ReadWrite',
          'User.Read',
        ],
      ),
      sendGrid: const SendGridConfig(
        apiKey: placeholderKey, // Load from env: SENDGRID_API_KEY
      ),
      awsSes: const AwsSesConfig(
        region: 'us-east-1',
        accessKeyId: placeholderKey, // Load from env: AWS_SES_ACCESS_KEY_ID
        secretAccessKey: placeholderKey, // Load from env: AWS_SES_SECRET_ACCESS_KEY
      ),
      twilio: const TwilioConfig(
        accountSid: placeholderKey, // Load from env: TWILIO_ACCOUNT_SID
        authToken: placeholderKey, // Load from env: TWILIO_AUTH_TOKEN
        fromPhone: '+15555551234', // Load from env: TWILIO_FROM_PHONE
      ),
      awsSns: const AwsSnsConfig(
        region: 'us-east-1',
        accessKeyId: placeholderKey, // Load from env: AWS_SNS_ACCESS_KEY_ID
        secretAccessKey: placeholderKey, // Load from env: AWS_SNS_SECRET_ACCESS_KEY
      ),
      zoom: const ZoomConfig(
        accountId: placeholderKey, // Load from env: ZOOM_ACCOUNT_ID
        clientId: placeholderKey, // Load from env: ZOOM_CLIENT_ID
        clientSecret: placeholderKey, // Load from env: ZOOM_CLIENT_SECRET
      ),
      defaultTelehealthProvider: TelehealthProviderType.zoom,
      integrationApiBaseUrl: Uri.parse(
        'https://us-central1-your-project.cloudfunctions.net', // Load from env
      ),
      tokenEncryptionKey: placeholderKey, // CRITICAL: Load from env: TOKEN_ENCRYPTION_KEY (min 32 chars)
    );
  }

  IntegrationConfig copyWith({
    EmailProviderType? emailProvider,
    SmsProviderType? smsProvider,
    bool? enableGoogleCalendarSync,
    bool? enableMicrosoftCalendarSync,
    Duration? defaultCalendarSyncInterval,
    bool? allowProviderOverrides,
    OAuthClientConfig? googleOAuth,
    OAuthClientConfig? microsoftOAuth,
    SendGridConfig? sendGrid,
    AwsSesConfig? awsSes,
    TwilioConfig? twilio,
    AwsSnsConfig? awsSns,
    ZoomConfig? zoom,
    TelehealthProviderType? defaultTelehealthProvider,
    Uri? integrationApiBaseUrl,
    String? tokenEncryptionKey,
  }) {
    return IntegrationConfig(
      emailProvider: emailProvider ?? this.emailProvider,
      smsProvider: smsProvider ?? this.smsProvider,
      enableGoogleCalendarSync:
          enableGoogleCalendarSync ?? this.enableGoogleCalendarSync,
      enableMicrosoftCalendarSync:
          enableMicrosoftCalendarSync ?? this.enableMicrosoftCalendarSync,
      defaultCalendarSyncInterval:
          defaultCalendarSyncInterval ?? this.defaultCalendarSyncInterval,
      allowProviderOverrides:
          allowProviderOverrides ?? this.allowProviderOverrides,
      googleOAuth: googleOAuth ?? this.googleOAuth,
      microsoftOAuth: microsoftOAuth ?? this.microsoftOAuth,
      sendGrid: sendGrid ?? this.sendGrid,
      awsSes: awsSes ?? this.awsSes,
      twilio: twilio ?? this.twilio,
      awsSns: awsSns ?? this.awsSns,
      zoom: zoom ?? this.zoom,
      defaultTelehealthProvider:
          defaultTelehealthProvider ?? this.defaultTelehealthProvider,
      integrationApiBaseUrl:
          integrationApiBaseUrl ?? this.integrationApiBaseUrl,
      tokenEncryptionKey: tokenEncryptionKey ?? this.tokenEncryptionKey,
    );
  }
}

