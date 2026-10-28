import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// Callback when wipe is triggered.
typedef WipeCallback = Future<void> Function();

/// Status of the remote wipe service.
enum RemoteWipeStatus {
  /// Not initialized or not listening.
  inactive,

  /// Actively listening for wipe commands.
  listening,

  /// Wipe in progress.
  wiping,

  /// Wipe completed.
  completed,

  /// Error occurred.
  error,
}

/// Service for handling remote wipe commands from administrators.
///
/// Listens for wipe commands in Firestore and securely deletes all
/// local data when triggered. Used for device loss, employee termination,
/// or security incidents.
class RemoteWipeService {
  RemoteWipeService._();
  static final RemoteWipeService instance = RemoteWipeService._();

  final _secureStorage = SecureStorageService.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<DocumentSnapshot>? _wipeListener;
  String? _deviceId;
  String? _businessId;

  RemoteWipeStatus _status = RemoteWipeStatus.inactive;
  RemoteWipeStatus get status => _status;

  /// Callback invoked when wipe is triggered (for UI navigation).
  WipeCallback? onWipeTriggered;

  /// Callback invoked when wipe is complete.
  VoidCallback? onWipeComplete;

  /// Initializes the remote wipe service and starts listening.
  ///
  /// [businessId] is required to listen to the correct Firestore collection.
  Future<void> initialize(String businessId) async {
    _businessId = businessId;
    _deviceId = await _secureStorage.getOrCreateDeviceId();

    await _registerDevice();
    _startListening();
  }

  /// Stops listening for wipe commands.
  void dispose() {
    _wipeListener?.cancel();
    _wipeListener = null;
    _status = RemoteWipeStatus.inactive;
  }

  /// Registers this device in Firestore for remote wipe targeting.
  Future<void> _registerDevice() async {
    if (_businessId == null || _deviceId == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('devices')
          .doc(_deviceId)
          .set({
        'deviceId': _deviceId,
        'userId': user.uid,
        'userEmail': user.email,
        'platform': Platform.operatingSystem,
        'registeredAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'wipeRequested': false,
        'wipeCompletedAt': null,
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't fail - device registration is best-effort
    }
  }

  /// Updates the last active timestamp.
  Future<void> updateLastActive() async {
    if (_businessId == null || _deviceId == null) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('devices')
          .doc(_deviceId)
          .update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore errors for activity updates
    }
  }

  /// Starts listening for wipe commands.
  void _startListening() {
    if (_businessId == null || _deviceId == null) return;

    _status = RemoteWipeStatus.listening;

    _wipeListener = _firestore
        .collection('businesses')
        .doc(_businessId)
        .collection('devices')
        .doc(_deviceId)
        .snapshots()
        .listen(_handleDocumentChange, onError: _handleError);
  }

  void _handleDocumentChange(DocumentSnapshot snapshot) async {
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final wipeRequested = data['wipeRequested'] as bool? ?? false;
    if (wipeRequested) {
      await _executeWipe();
    }
  }

  void _handleError(dynamic error) {
    _status = RemoteWipeStatus.error;
  }

  /// Executes the wipe operation.
  Future<void> _executeWipe() async {
    _status = RemoteWipeStatus.wiping;

    // Notify UI to show wipe progress/message
    await onWipeTriggered?.call();

    try {
      // 1. Delete SQLite database file
      await _deleteDatabaseFile();

      // 2. Clear secure storage (auth tokens, encryption keys)
      await _secureStorage.clearAllSecureData();

      // 3. Clear shared preferences
      await _clearSharedPreferences();

      // 4. Confirm wipe completion to Firestore
      await _confirmWipeCompletion();

      // 5. Sign out from Firebase
      await _auth.signOut();

      _status = RemoteWipeStatus.completed;
      onWipeComplete?.call();
    } catch (e) {
      _status = RemoteWipeStatus.error;
      // Even if something fails, try to sign out
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<void> _deleteDatabaseFile() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/staff_app.sqlite');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Also delete any WAL or SHM files
      final walFile = File('${dbFolder.path}/staff_app.sqlite-wal');
      final shmFile = File('${dbFolder.path}/staff_app.sqlite-shm');

      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();
    } catch (e) {
      // Continue even if database deletion fails
    }
  }

  Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // Continue even if prefs clearing fails
    }
  }

  Future<void> _confirmWipeCompletion() async {
    if (_businessId == null || _deviceId == null) return;

    try {
      await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('devices')
          .doc(_deviceId)
          .update({
        'wipeCompletedAt': FieldValue.serverTimestamp(),
        'wipeRequested': false,
      });
    } catch (e) {
      // Confirmation is best-effort
    }
  }

  /// Manually triggers a local wipe (for self-service data clearing).
  Future<void> triggerLocalWipe() async {
    await _executeWipe();
  }

  /// Checks if a wipe was requested while the app was offline.
  Future<bool> checkPendingWipe() async {
    if (_businessId == null || _deviceId == null) return false;

    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('devices')
          .doc(_deviceId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['wipeRequested'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// Extension typedef for void callbacks.
typedef VoidCallback = void Function();
