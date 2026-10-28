// Device Integrity Check (Jailbreak/Root Detection)
//
// Detects if the device has been jailbroken (iOS) or rooted (Android).
// Important for healthcare apps to ensure data security on compromised devices.
//
// NOTE: In production, use a dedicated package like:
// - flutter_jailbreak_detection
// - safe_device
// - freerasp

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Result of device integrity check.
enum DeviceIntegrityStatus {
  /// Device appears to be secure.
  secure,

  /// Device is jailbroken (iOS).
  jailbroken,

  /// Device is rooted (Android).
  rooted,

  /// Running on emulator/simulator.
  emulator,

  /// Debugger is attached.
  debuggerAttached,

  /// App has been tampered with.
  tampered,

  /// Unable to determine status.
  unknown,
}

/// Detailed result of integrity check.
class DeviceIntegrityResult {
  const DeviceIntegrityResult({
    required this.status,
    required this.isSecure,
    required this.checks,
    this.details,
  });

  /// Overall status.
  final DeviceIntegrityStatus status;

  /// Whether device is considered secure.
  final bool isSecure;

  /// Individual check results.
  final Map<String, bool> checks;

  /// Additional details.
  final String? details;

  @override
  String toString() => 'DeviceIntegrityResult(status: $status, secure: $isSecure)';
}

/// Service for checking device integrity.
class DeviceIntegrityService {
  DeviceIntegrityService._();
  static final DeviceIntegrityService instance = DeviceIntegrityService._();

  DeviceIntegrityResult? _cachedResult;
  DateTime? _lastCheck;

  /// How long to cache the result.
  static const _cacheDuration = Duration(minutes: 5);

  /// Check device integrity.
  Future<DeviceIntegrityResult> checkIntegrity({bool forceRefresh = false}) async {
    // Return cached result if valid
    if (!forceRefresh && _cachedResult != null && _lastCheck != null) {
      final elapsed = DateTime.now().difference(_lastCheck!);
      if (elapsed < _cacheDuration) {
        return _cachedResult!;
      }
    }

    final checks = <String, bool>{};
    var status = DeviceIntegrityStatus.secure;
    String? details;

    try {
      // Check for jailbreak/root
      if (Platform.isIOS) {
        final jailbroken = await _checkJailbreak();
        checks['jailbreak'] = !jailbroken;
        if (jailbroken) {
          status = DeviceIntegrityStatus.jailbroken;
          details = 'Device appears to be jailbroken';
        }
      } else if (Platform.isAndroid) {
        final rooted = await _checkRoot();
        checks['root'] = !rooted;
        if (rooted) {
          status = DeviceIntegrityStatus.rooted;
          details = 'Device appears to be rooted';
        }
      }

      // Check for emulator
      final isEmulator = await _checkEmulator();
      checks['emulator'] = !isEmulator;
      if (isEmulator && status == DeviceIntegrityStatus.secure) {
        status = DeviceIntegrityStatus.emulator;
        details = 'Running on emulator/simulator';
      }

      // Check for debugger
      final debuggerAttached = _checkDebugger();
      checks['debugger'] = !debuggerAttached;
      if (debuggerAttached && status == DeviceIntegrityStatus.secure && !kDebugMode) {
        status = DeviceIntegrityStatus.debuggerAttached;
        details = 'Debugger is attached';
      }

      // Check for app tampering (signature verification)
      final tampered = await _checkTampering();
      checks['tampering'] = !tampered;
      if (tampered && status == DeviceIntegrityStatus.secure) {
        status = DeviceIntegrityStatus.tampered;
        details = 'App integrity compromised';
      }
    } catch (e) {
      debugPrint('DeviceIntegrityService: Check failed: $e');
      status = DeviceIntegrityStatus.unknown;
      details = 'Unable to verify device integrity: $e';
    }

    final isSecure = status == DeviceIntegrityStatus.secure ||
        (status == DeviceIntegrityStatus.emulator && kDebugMode);

    final result = DeviceIntegrityResult(
      status: status,
      isSecure: isSecure,
      checks: checks,
      details: details,
    );

    _cachedResult = result;
    _lastCheck = DateTime.now();

    debugPrint('DeviceIntegrityService: $result');
    return result;
  }

  /// Quick check if device is secure (uses cache).
  Future<bool> isDeviceSecure() async {
    final result = await checkIntegrity();
    return result.isSecure;
  }

  /// Check for iOS jailbreak.
  Future<bool> _checkJailbreak() async {
    if (!Platform.isIOS) return false;

    // Check for common jailbreak indicators
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
      '/private/var/lib/cydia',
      '/private/var/tmp/cydia.log',
      '/Applications/Sileo.app',
      '/var/checkra1n.dmg',
      '/Applications/Zebra.app',
    ];

    for (final path in jailbreakPaths) {
      if (await _fileExists(path)) {
        debugPrint('DeviceIntegrityService: Jailbreak indicator found: $path');
        return true;
      }
    }

    // Check if we can write to system directories
    try {
      final file = File('/private/jailbreak_test.txt');
      await file.writeAsString('test');
      await file.delete();
      // If we could write, device is likely jailbroken
      return true;
    } catch (_) {
      // Expected to fail on non-jailbroken devices
    }

    // Check URL schemes
    // In production, use url_launcher to check for cydia://

    return false;
  }

  /// Check for Android root.
  Future<bool> _checkRoot() async {
    if (!Platform.isAndroid) return false;

    // Check for common root indicators
    final rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
      '/system/app/SuperSU.apk',
      '/system/app/Magisk.apk',
    ];

    for (final path in rootPaths) {
      if (await _fileExists(path)) {
        debugPrint('DeviceIntegrityService: Root indicator found: $path');
        return true;
      }
    }

    // Check for root management apps
    // In production, check if these packages are installed:
    // - com.topjohnwu.magisk
    // - com.koushikdutta.superuser
    // - com.noshufou.android.su
    // - com.thirdparty.superuser
    // - eu.chainfire.supersu
    // - com.yellowes.su

    // Try to execute su
    try {
      final result = await Process.run('su', ['-c', 'id']);
      if (result.exitCode == 0) {
        return true;
      }
    } catch (_) {
      // Expected to fail on non-rooted devices
    }

    return false;
  }

  /// Check if running on emulator using device_info_plus.
  Future<bool> _checkEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      try {
        final androidInfo = await deviceInfo.androidInfo;

        // Check isPhysicalDevice flag
        if (!androidInfo.isPhysicalDevice) {
          debugPrint('DeviceIntegrityService: Android emulator detected (isPhysicalDevice=false)');
          return true;
        }

        // Check for common emulator fingerprints
        final fingerprint = androidInfo.fingerprint.toLowerCase();
        final model = androidInfo.model.toLowerCase();
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();
        final product = androidInfo.product.toLowerCase();

        final emulatorIndicators = [
          fingerprint.contains('generic'),
          fingerprint.contains('unknown'),
          fingerprint.contains('sdk'),
          fingerprint.contains('emulator'),
          model.contains('sdk'),
          model.contains('emulator'),
          model.contains('android sdk'),
          manufacturer.contains('genymotion'),
          manufacturer.contains('unknown'),
          hardware.contains('goldfish'),
          hardware.contains('ranchu'),
          product.contains('sdk'),
          product.contains('emulator'),
        ];

        if (emulatorIndicators.any((indicator) => indicator)) {
          debugPrint('DeviceIntegrityService: Android emulator detected via device info');
          return true;
        }
      } catch (e) {
        debugPrint('DeviceIntegrityService: Failed to get Android info: $e');
      }
    } else if (Platform.isIOS) {
      try {
        final iosInfo = await deviceInfo.iosInfo;

        // Check isPhysicalDevice flag
        if (!iosInfo.isPhysicalDevice) {
          debugPrint('DeviceIntegrityService: iOS simulator detected (isPhysicalDevice=false)');
          return true;
        }

        // Check for simulator-specific model
        if (iosInfo.model.toLowerCase().contains('simulator')) {
          debugPrint('DeviceIntegrityService: iOS simulator detected via model');
          return true;
        }
      } catch (e) {
        debugPrint('DeviceIntegrityService: Failed to get iOS info: $e');
      }
    }

    return false;
  }

  /// Check if debugger is attached.
  bool _checkDebugger() {
    // kDebugMode is true when running in debug mode
    // In production, also check for JDWP on Android
    return kDebugMode;
  }

  /// Check for app tampering.
  Future<bool> _checkTampering() async {
    // In production, implement:
    // 1. Signature verification
    // 2. Code integrity checks
    // 3. Resource integrity checks

    // For now, return false (no tampering detected)
    return false;
  }

  /// Helper to check if file exists.
  Future<bool> _fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  /// Clear cached result.
  void clearCache() {
    _cachedResult = null;
    _lastCheck = null;
  }
}

/// Action to take when device is compromised.
enum CompromisedDeviceAction {
  /// Allow app to run with warning.
  warnAndContinue,

  /// Block sensitive features.
  restrictFeatures,

  /// Block app entirely.
  blockApp,
}

/// Configuration for device integrity policy.
class DeviceIntegrityPolicy {
  const DeviceIntegrityPolicy({
    this.jailbreakAction = CompromisedDeviceAction.blockApp,
    this.rootAction = CompromisedDeviceAction.blockApp,
    this.emulatorAction = CompromisedDeviceAction.warnAndContinue,
    this.debuggerAction = CompromisedDeviceAction.warnAndContinue,
    this.tamperAction = CompromisedDeviceAction.blockApp,
    this.allowInDebugMode = true,
  });

  final CompromisedDeviceAction jailbreakAction;
  final CompromisedDeviceAction rootAction;
  final CompromisedDeviceAction emulatorAction;
  final CompromisedDeviceAction debuggerAction;
  final CompromisedDeviceAction tamperAction;
  final bool allowInDebugMode;

  /// Default policy for production healthcare apps.
  static const production = DeviceIntegrityPolicy(
    jailbreakAction: CompromisedDeviceAction.blockApp,
    rootAction: CompromisedDeviceAction.blockApp,
    emulatorAction: CompromisedDeviceAction.blockApp,
    debuggerAction: CompromisedDeviceAction.blockApp,
    tamperAction: CompromisedDeviceAction.blockApp,
    allowInDebugMode: false,
  );

  /// Lenient policy for development.
  static const development = DeviceIntegrityPolicy(
    jailbreakAction: CompromisedDeviceAction.warnAndContinue,
    rootAction: CompromisedDeviceAction.warnAndContinue,
    emulatorAction: CompromisedDeviceAction.warnAndContinue,
    debuggerAction: CompromisedDeviceAction.warnAndContinue,
    tamperAction: CompromisedDeviceAction.warnAndContinue,
    allowInDebugMode: true,
  );

  /// Get action for a given status.
  CompromisedDeviceAction getActionForStatus(DeviceIntegrityStatus status) {
    switch (status) {
      case DeviceIntegrityStatus.jailbroken:
        return jailbreakAction;
      case DeviceIntegrityStatus.rooted:
        return rootAction;
      case DeviceIntegrityStatus.emulator:
        return emulatorAction;
      case DeviceIntegrityStatus.debuggerAttached:
        return debuggerAction;
      case DeviceIntegrityStatus.tampered:
        return tamperAction;
      case DeviceIntegrityStatus.secure:
      case DeviceIntegrityStatus.unknown:
        return CompromisedDeviceAction.warnAndContinue;
    }
  }
}
