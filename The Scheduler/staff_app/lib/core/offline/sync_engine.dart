import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:flutter/foundation.dart';

import '../../data/local/staff_database.dart';
import '../../data/sync/sync_queue_processor.dart';
import '../config/staff_app_config.dart';

/// Callback type for sync status changes.
typedef SyncStatusCallback = void Function(SyncEngineStatus status);

/// Callback type for sync errors.
typedef SyncErrorCallback = void Function(String message, Object? error);

/// Status enum for sync engine state.
enum SyncEngineStatus {
  /// Engine not yet initialized
  uninitialized,

  /// Engine initialized and idle
  idle,

  /// Currently performing sync
  syncing,

  /// Sync encountered an error
  error,

  /// Device is offline
  offline,
}

/// Core offline sync engine for bidirectional data synchronization.
///
/// Handles:
/// - Initial full sync of appointments and client data
/// - Incremental sync for updates since last sync
/// - Periodic sync on configurable interval
/// - Queue processing when connectivity is restored
/// - Connectivity monitoring
///
/// ## Usage
/// ```dart
/// final syncEngine = SyncEngine(
///   db: database,
///   firestore: FirebaseFirestore.instance,
///   staffId: currentUser.providerId,
///   businessId: currentUser.businessId,
/// );
/// await syncEngine.initialize();
/// ```
class SyncEngine {
  SyncEngine({
    required StaffDatabase db,
    required FirebaseFirestore firestore,
    required String staffId,
    required String businessId,
  })  : _db = db,
        _firestore = firestore,
        _staffId = staffId,
        _businessId = businessId,
        _queueProcessor = SyncQueueProcessor(
          db: db,
          firestore: firestore,
          staffId: staffId,
          businessId: businessId,
        );

  static const int _firestorePageSize = 100;
  final StaffDatabase _db;
  final FirebaseFirestore _firestore;
  final String _staffId;
  final String _businessId;
  final SyncQueueProcessor _queueProcessor;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;
  DateTime? _lastSyncTime;

  SyncEngineStatus _status = SyncEngineStatus.uninitialized;
  SyncStatusCallback? onStatusChange;
  SyncErrorCallback? onError;

  /// Current sync engine status.
  SyncEngineStatus get status => _status;

  /// Whether the engine is currently syncing.
  bool get isSyncing => _isSyncing;

  /// Whether the engine has been initialized.
  bool get isInitialized => _isInitialized;

  /// Last successful sync timestamp.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Business ID this engine is configured for.
  String get businessId => _businessId;

  /// Staff ID this engine is configured for.
  String get staffId => _staffId;

  /// Initializes the sync engine and starts monitoring.
  ///
  /// Performs initial full sync and sets up:
  /// - Connectivity monitoring
  /// - Periodic sync timer
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SyncEngine: Already initialized');
      return;
    }

    debugPrint('SyncEngine: Initializing');

    try {
      // Check connectivity first
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (isOnline) {
        _updateStatus(SyncEngineStatus.syncing);
        await _performFullSync();
        _updateStatus(SyncEngineStatus.idle);
      } else {
        _updateStatus(SyncEngineStatus.offline);
        debugPrint('SyncEngine: Starting offline - will sync when connected');
      }

      // Monitor connectivity changes
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);

      // Start periodic sync timer
      _syncTimer = Timer.periodic(
        StaffAppConfig.syncInterval,
        (_) => _onSyncTimer(),
      );

      _isInitialized = true;
      debugPrint('SyncEngine: Initialization complete');
    } catch (e) {
      _updateStatus(SyncEngineStatus.error);
      _reportError('Initialization failed', e);
      debugPrint('SyncEngine: Initialization error');
      rethrow;
    }
  }

  /// Forces an immediate sync.
  ///
  /// Can be called to refresh data on demand (e.g., pull-to-refresh).
  Future<void> forceSync() async {
    if (!await _isOnline()) {
      debugPrint('SyncEngine: Cannot force sync - offline');
      return;
    }

    await _performIncrementalSync(includeQueue: true);
  }

  /// Performs a full sync of all data.
  ///
  /// Pulls appointments and clients from Firestore.
  Future<void> _performFullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint('SyncEngine: Starting full sync');
      _updateStatus(SyncEngineStatus.syncing);

      // Sync appointments for next N days (configurable)
      await _syncAppointments();

      // Process any pending local changes
      await _processSyncQueue();

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncEngineStatus.idle);
      debugPrint('SyncEngine: Full sync complete');
    } catch (e) {
      _updateStatus(SyncEngineStatus.error);
      _reportError('Full sync failed', e);
      debugPrint('SyncEngine: Full sync error');
    } finally {
      _isSyncing = false;
    }
  }

  /// Performs incremental sync (only changed records since last sync).
  Future<void> _performIncrementalSync({bool includeQueue = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint('SyncEngine: Starting incremental sync');
      _updateStatus(SyncEngineStatus.syncing);

      final since =
          _lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);

      await _syncAppointments(updatedSince: since);

      if (includeQueue) {
        await _processSyncQueue();
      }

      _lastSyncTime = DateTime.now();
      _updateStatus(SyncEngineStatus.idle);
      debugPrint('SyncEngine: Incremental sync complete');
    } catch (e) {
      _updateStatus(SyncEngineStatus.error);
      _reportError('Incremental sync failed', e);
      debugPrint('SyncEngine: Incremental sync error');
    } finally {
      _isSyncing = false;
    }
  }

  /// Syncs appointments from Firestore to local database.
  Future<void> _syncAppointments({DateTime? updatedSince}) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endDate = startOfToday
        .add(const Duration(days: StaffAppConfig.appointmentCacheDays));

    final appointmentsCollection = _firestore
        .collection('businesses')
        .doc(_businessId)
        .collection('appointments');

    final clientIds = <String>{};
    final appointmentCompanions = <AppointmentsTableCompanion>[];

    Query<Map<String, dynamic>> baseQuery = appointmentsCollection
        .where('providerId', isEqualTo: _staffId);

    if (updatedSince != null) {
      debugPrint(
          'SyncEngine: Incremental fetch for updates since $updatedSince');
      var query = baseQuery
          .where('updatedAt',
              isGreaterThan: Timestamp.fromDate(updatedSince))
          .orderBy('updatedAt')
          .limit(_firestorePageSize);

      DocumentSnapshot? lastDoc;
      do {
        final snapshot = await query.get();
        debugPrint(
            'SyncEngine: Incremental page fetched ${snapshot.docs.length} appointments');

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final clientId = data['clientId'] as String?;
          if (clientId != null) {
            clientIds.add(clientId);
          }
          appointmentCompanions.add(_appointmentFromFirestore(doc.id, data));
        }

        if (snapshot.docs.length < _firestorePageSize) break;
        lastDoc = snapshot.docs.last;
        query = query.startAfterDocument(lastDoc);
      } while (true);
    } else {
      debugPrint(
          'SyncEngine: Full fetch for appointments from $startOfToday to $endDate');

      var query = baseQuery
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('startTime', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('startTime')
          .limit(_firestorePageSize);

      DocumentSnapshot? lastDoc;
      do {
        final snapshot = await query.get();
        debugPrint(
            'SyncEngine: Full sync page fetched ${snapshot.docs.length} appointments');

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final clientId = data['clientId'] as String?;
          if (clientId != null) {
            clientIds.add(clientId);
          }

          appointmentCompanions.add(_appointmentFromFirestore(doc.id, data));
        }

        if (snapshot.docs.length < _firestorePageSize) break;
        lastDoc = snapshot.docs.last;
        query = query.startAfterDocument(lastDoc);
      } while (true);
    }

    if (appointmentCompanions.isNotEmpty) {
      await _db.appointmentsDao.upsertAppointments(appointmentCompanions);
      debugPrint(
          'SyncEngine: Upserted ${appointmentCompanions.length} appointments');
    }

    await _syncClients(clientIds.toList());
  }

  /// Syncs client data from Firestore for given client IDs.
  Future<void> _syncClients(List<String> clientIds) async {
    if (clientIds.isEmpty) return;

    debugPrint('SyncEngine: Fetching ${clientIds.length} clients');

    // Firestore limits 'in' queries to 30 items, batch if needed
    const batchSize = 30;
    final clientCompanions = <ClientsTableCompanion>[];

    for (var i = 0; i < clientIds.length; i += batchSize) {
      final batch = clientIds.skip(i).take(batchSize).toList();

      final clientsSnapshot = await _firestore
          .collection('businesses')
          .doc(_businessId)
          .collection('clients')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in clientsSnapshot.docs) {
        final data = doc.data();
        clientCompanions.add(_clientFromFirestore(doc.id, data));
      }
    }

    // Batch upsert clients
    if (clientCompanions.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.clientsTable, clientCompanions);
      });
      debugPrint('SyncEngine: Upserted ${clientCompanions.length} clients');
    }
  }

  /// Processes the sync queue (offline changes to be pushed).
  Future<void> _processSyncQueue() async {
    await _queueProcessor.processQueue();
  }

  /// Converts Firestore appointment document to table companion.
  AppointmentsTableCompanion _appointmentFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AppointmentsTableCompanion.insert(
      id: id,
      businessId: _businessId,
      staffId: Value(data['providerId'] as String? ?? _staffId),
      clientId: data['clientId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      locationId: data['locationId'] as String? ?? '',
      startTime: parseTimestamp(data['startTime']) ?? DateTime.now(),
      endTime: parseTimestamp(data['endTime']) ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      clientName: Value(data['clientName'] as String?),
      clientPhone: Value(data['clientPhone'] as String?),
      clientEmail: Value(data['clientEmail'] as String?),
      clientAddress: Value(data['clientAddress'] as String?),
      serviceName: Value(data['serviceName'] as String?),
      serviceDurationMinutes: Value(data['durationMinutes'] as int?),
      locationName: Value(data['locationName'] as String?),
      notes: Value(data['notes'] as String?),
      staffNotes: Value(data['staffNotes'] as String?),
      requiresPayment: Value(data['requiresPayment'] as bool? ?? false),
      paymentStatus: Value(data['paymentStatus'] as String?),
      checkedInAt: Value(parseTimestamp(data['checkedInAt'])),
      checkedInByStaffId: Value(data['checkedInByStaffId'] as String?),
      completedAt: Value(parseTimestamp(data['completedAt'])),
      completedByStaffId: Value(data['completedByStaffId'] as String?),
      lastSyncedAt: Value(DateTime.now()),
    );
  }

  /// Converts Firestore client document to table companion.
  ClientsTableCompanion _clientFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();

    return ClientsTableCompanion.insert(
      id: id,
      businessId: _businessId,
      name: name.isNotEmpty ? name : 'Unknown',
      email: Value(data['email'] as String?),
      phone: Value(data['phone'] as String?),
      address: Value(data['address'] as String?),
      notes: Value(data['notes'] as String?),
      lastSyncedAt: DateTime.now(),
    );
  }

  /// Handles connectivity changes.
  void _handleConnectivityChange(ConnectivityResult result) async {
    final isOnline = result != ConnectivityResult.none;

    debugPrint('SyncEngine: Connectivity changed - online: $isOnline');

    if (isOnline) {
      // Coming back online - process queue and sync
      if (_status == SyncEngineStatus.offline) {
        _updateStatus(SyncEngineStatus.syncing);
        await _processSyncQueue();
        await _performIncrementalSync();
      }
    } else {
      _updateStatus(SyncEngineStatus.offline);
    }
  }

  /// Called by periodic sync timer.
  void _onSyncTimer() async {
    if (!await _isOnline()) {
      debugPrint('SyncEngine: Timer sync skipped - offline');
      return;
    }

    if (_isSyncing) {
      debugPrint('SyncEngine: Timer sync skipped - already syncing');
      return;
    }

    await _performIncrementalSync(includeQueue: true);
  }

  /// Checks if device is currently online.
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Updates the sync status and notifies listeners.
  void _updateStatus(SyncEngineStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChange?.call(newStatus);
    }
  }

  /// Reports an error to the callback.
  void _reportError(String message, Object? error) {
    onError?.call(message, error);
  }

  /// Gets count of pending sync items.
  Future<int> getPendingSyncCount() async {
    return _db.syncQueueDao.getQueueCount();
  }

  /// Disposes of the sync engine, canceling subscriptions and timers.
  void dispose() {
    debugPrint('SyncEngine: Disposing');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _isInitialized = false;
    _updateStatus(SyncEngineStatus.uninitialized);
  }
}
