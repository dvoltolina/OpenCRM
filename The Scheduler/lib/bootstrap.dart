// import 'dart:io'; // AI MODULE DISABLED - was used for Platform.environment

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
// AI MODULE DISABLED FOR LAUNCH - Re-enable when AI services are ready
// import 'ai/providers/prediction_providers.dart' as prediction_providers;
// import 'ai/providers/sentiment_providers.dart' as sentiment_providers;
// import 'core/config/ai_config.dart';
import 'core/config/app_config.dart';
// import 'core/config/feature_flags.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/service_providers.dart';
import 'core/services/encryption_service.dart';
import 'core/services/firebase_initializer.dart';

Future<void> bootstrap({required AppConfig Function() loadConfig}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await const FirebaseInitializer().initialize();

  // Initialize SharedPreferences for offline queue (Agent FP4)
  final prefs = await SharedPreferences.getInstance();

  final config = loadConfig();
  // AI MODULE DISABLED FOR LAUNCH
  // final aiConfig = _loadAiConfigFromEnvironment(config.featureFlags);

  // Wrap app with ProviderScope and override appConfig provider
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs), // Agent FP4
        // AI MODULE DISABLED FOR LAUNCH
        // prediction_providers.aiConfigProvider.overrideWithValue(aiConfig),
        // sentiment_providers.aiConfigProvider.overrideWithValue(aiConfig),
      ],
      child: EncryptionLifecycleWrapper(
        child: SchedulerApp(config: config),
      ),
    ),
  );
}

// AI MODULE DISABLED FOR LAUNCH - Re-enable when AI services are ready
// AIConfig _loadAiConfigFromEnvironment(FeatureFlags featureFlags) {
//   // If AI features are off, return a disabled config so the app can boot
//   // without requiring AI environment variables.
//   if (!featureFlags.hasAnyAIEnabled) {
//     return AIConfig.disabled();
//   }
//
//   final baseUrl = Platform.environment['AI_BASE_URL'] ?? '';
//   final predictionUrl = Platform.environment['AI_PREDICTION_URL'];
//   final sentimentUrl = Platform.environment['AI_SENTIMENT_URL'];
//   final routeUrl = Platform.environment['AI_ROUTE_URL'];
//   final authToken = Platform.environment['AI_AUTH_TOKEN'];
//   final apiKey = Platform.environment['AI_API_KEY'];
//
//   if (baseUrl.isEmpty) {
//     throw StateError(
//       'AI_BASE_URL must be set before starting the app when AI features are enabled.',
//     );
//   }
//
//   if (!baseUrl.startsWith('https://')) {
//     throw StateError(
//       'AI_BASE_URL must use HTTPS when AI features are enabled.',
//     );
//   }
//
//   final hasAuthToken = authToken?.isNotEmpty == true;
//   final hasApiKey = apiKey?.isNotEmpty == true;
//
//   if (!hasAuthToken && !hasApiKey) {
//     throw StateError(
//       'AI auth is required when AI features are enabled (set AI_AUTH_TOKEN for tenant JWT or AI_API_KEY as a fallback).',
//     );
//   }
//
//   final config = AIConfig(
//     baseUrl: baseUrl,
//     apiKey: hasApiKey ? apiKey : null,
//     authToken: hasAuthToken ? authToken : null,
//   );
//
//   return config.copyWith(
//     predictionServiceUrl:
//         predictionUrl?.isNotEmpty == true ? predictionUrl : null,
//     sentimentServiceUrl:
//         sentimentUrl?.isNotEmpty == true ? sentimentUrl : null,
//     routeServiceUrl: routeUrl?.isNotEmpty == true ? routeUrl : null,
//     requireHttps: true,
//   );
// }

class EncryptionLifecycleWrapper extends StatefulWidget {
  const EncryptionLifecycleWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<EncryptionLifecycleWrapper> createState() =>
      _EncryptionLifecycleWrapperState();
}

class _EncryptionLifecycleWrapperState extends State<EncryptionLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EncryptionKeyManager.clearCache();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      EncryptionKeyManager.clearCache();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
