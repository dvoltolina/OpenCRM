/// Environment configuration for The Scheduler app
///
/// This file handles environment-specific settings using compile-time constants
/// passed via --dart-define flags during build.
///
/// Usage:
/// - Dev: flutter run --dart-define=ENV=dev
/// - Staging: flutter build web --dart-define=ENV=staging
/// - Production: flutter build apk --dart-define=ENV=prod
library;

enum Environment {
  dev,
  staging,
  prod;

  static Environment get current {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    return Environment.values.firstWhere(
      (e) => e.name == envString,
      orElse: () => Environment.dev,
    );
  }

  bool get isDev => this == Environment.dev;
  bool get isStaging => this == Environment.staging;
  bool get isProd => this == Environment.prod;
}

/// Environment-specific configuration values
class EnvironmentConfig {
  const EnvironmentConfig._({
    required this.environment,
    required this.firebaseProjectId,
    required this.apiBaseUrl,
    required this.cloudFunctionsUrl,
    required this.enableAnalytics,
    required this.enableCrashlytics,
    required this.enablePerformanceMonitoring,
    required this.logLevel,
  });

  final Environment environment;
  final String firebaseProjectId;
  final String apiBaseUrl;
  final String cloudFunctionsUrl;
  final bool enableAnalytics;
  final bool enableCrashlytics;
  final bool enablePerformanceMonitoring;
  final String logLevel;

  static EnvironmentConfig get current {
    final env = Environment.current;

    switch (env) {
      case Environment.dev:
        return const EnvironmentConfig._(
          environment: Environment.dev,
          firebaseProjectId: 'your-firebase-project-dev',
          apiBaseUrl: 'https://api-dev.example.com',
          cloudFunctionsUrl:
              'https://us-central1-your-firebase-project.cloudfunctions.net',
          enableAnalytics: false,
          enableCrashlytics: false,
          enablePerformanceMonitoring: false,
          logLevel: 'debug',
        );

      case Environment.staging:
        return const EnvironmentConfig._(
          environment: Environment.staging,
          firebaseProjectId: 'your-firebase-project-staging',
          apiBaseUrl: 'https://api-staging.example.com',
          cloudFunctionsUrl:
              'https://us-central1-your-firebase-project.cloudfunctions.net',
          enableAnalytics: true,
          enableCrashlytics: true,
          enablePerformanceMonitoring: true,
          logLevel: 'info',
        );

      case Environment.prod:
        return const EnvironmentConfig._(
          environment: Environment.prod,
          firebaseProjectId: 'your-firebase-project',
          apiBaseUrl: 'https://api.example.com',
          cloudFunctionsUrl:
              'https://example.com',
          enableAnalytics: true,
          enableCrashlytics: true,
          enablePerformanceMonitoring: true,
          logLevel: 'warning',
        );
    }
  }

  /// Override Firebase project ID from compile-time constant if provided
  static String get effectiveFirebaseProjectId {
    const override = String.fromEnvironment('FIREBASE_PROJECT');
    if (override.isNotEmpty) {
      return override;
    }
    return current.firebaseProjectId;
  }

  @override
  String toString() {
    return 'EnvironmentConfig('
        'environment: ${environment.name}, '
        'firebaseProjectId: $firebaseProjectId, '
        'apiBaseUrl: $apiBaseUrl, '
        'enableAnalytics: $enableAnalytics)';
  }
}
