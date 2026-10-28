// Offline Sync Conflict Resolution for Staff App
//
// Handles conflicts when the same entity is modified both locally
// (while offline) and on the server. Critical for data integrity
// in healthcare applications.

import 'package:flutter/foundation.dart';

/// How to resolve a sync conflict.
enum ConflictResolution {
  /// Server version wins, discard local changes.
  serverWins,

  /// Client version wins, overwrite server.
  clientWins,

  /// Merge both versions (field-level).
  merge,

  /// Ask user to decide.
  askUser,

  /// Keep both versions (create duplicate).
  keepBoth,
}

/// Strategy for automatic conflict resolution.
enum ConflictStrategy {
  /// Always prefer server data (safe default).
  serverFirst,

  /// Always prefer client data.
  clientFirst,

  /// Use timestamps to determine winner.
  lastWriteWins,

  /// Merge non-conflicting fields, ask for conflicts.
  smartMerge,

  /// Always ask user.
  alwaysAsk,
}

/// Represents a sync conflict between local and server versions.
class SyncConflict {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.serverVersion,
    required this.clientVersion,
    required this.serverUpdatedAt,
    required this.clientUpdatedAt,
    this.conflictingFields = const [],
  });

  /// Type of entity (appointment, timeEntry, etc.)
  final String entityType;

  /// ID of the conflicting entity.
  final String entityId;

  /// Server version of the data.
  final Map<String, dynamic> serverVersion;

  /// Client (local) version of the data.
  final Map<String, dynamic> clientVersion;

  /// When server version was last updated.
  final DateTime serverUpdatedAt;

  /// When client version was last updated.
  final DateTime clientUpdatedAt;

  /// List of field names that have different values.
  final List<String> conflictingFields;

  /// Whether server version is newer.
  bool get isServerNewer => serverUpdatedAt.isAfter(clientUpdatedAt);

  /// Whether client version is newer.
  bool get isClientNewer => clientUpdatedAt.isAfter(serverUpdatedAt);

  /// Human-readable description of the conflict.
  String get description {
    final fieldCount = conflictingFields.length;
    final timeInfo = isServerNewer ? 'Server is newer' : 'Local is newer';
    return '$entityType conflict: $fieldCount field(s) differ. $timeInfo.';
  }

  /// Create conflict by comparing two versions.
  factory SyncConflict.detect({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> serverData,
    required Map<String, dynamic> clientData,
    required DateTime serverUpdatedAt,
    required DateTime clientUpdatedAt,
    List<String> fieldsToCompare = const [],
  }) {
    final conflictingFields = <String>[];

    // Compare specified fields or all fields
    final keysToCheck = fieldsToCompare.isNotEmpty
        ? fieldsToCompare
        : {...serverData.keys, ...clientData.keys}.toList();

    for (final key in keysToCheck) {
      // Skip metadata fields
      if (key == 'updatedAt' || key == 'createdAt' || key == 'syncedAt') {
        continue;
      }

      final serverValue = serverData[key];
      final clientValue = clientData[key];

      if (serverValue != clientValue) {
        conflictingFields.add(key);
      }
    }

    return SyncConflict(
      entityType: entityType,
      entityId: entityId,
      serverVersion: serverData,
      clientVersion: clientData,
      serverUpdatedAt: serverUpdatedAt,
      clientUpdatedAt: clientUpdatedAt,
      conflictingFields: conflictingFields,
    );
  }

  /// Check if there is actually a conflict.
  bool get hasConflict => conflictingFields.isNotEmpty;
}

/// Result of resolving a conflict.
class ConflictResolutionResult {
  const ConflictResolutionResult({
    required this.resolution,
    required this.resolvedData,
    this.userChoice,
  });

  /// How the conflict was resolved.
  final ConflictResolution resolution;

  /// The final merged/resolved data.
  final Map<String, dynamic> resolvedData;

  /// If user made a choice, which one.
  final String? userChoice;
}

/// Service for detecting and resolving sync conflicts.
class ConflictResolver {
  ConflictResolver({
    this.strategy = ConflictStrategy.lastWriteWins,
    this.onConflictDetected,
    this.onAskUser,
  });

  /// Default strategy for automatic resolution.
  final ConflictStrategy strategy;

  /// Callback when a conflict is detected.
  final void Function(SyncConflict conflict)? onConflictDetected;

  /// Callback to ask user for resolution (returns field -> chosen value).
  final Future<Map<String, dynamic>?> Function(SyncConflict conflict)? onAskUser;

  /// Resolve a conflict based on the configured strategy.
  Future<ConflictResolutionResult> resolve(SyncConflict conflict) async {
    onConflictDetected?.call(conflict);

    if (!conflict.hasConflict) {
      // No actual conflict, return server version
      return ConflictResolutionResult(
        resolution: ConflictResolution.serverWins,
        resolvedData: conflict.serverVersion,
      );
    }

    switch (strategy) {
      case ConflictStrategy.serverFirst:
        return _resolveServerWins(conflict);

      case ConflictStrategy.clientFirst:
        return _resolveClientWins(conflict);

      case ConflictStrategy.lastWriteWins:
        return _resolveLastWriteWins(conflict);

      case ConflictStrategy.smartMerge:
        return _resolveSmartMerge(conflict);

      case ConflictStrategy.alwaysAsk:
        return _resolveAskUser(conflict);
    }
  }

  ConflictResolutionResult _resolveServerWins(SyncConflict conflict) {
    debugPrint('Conflict resolved: Server wins for ${conflict.entityId}');
    return ConflictResolutionResult(
      resolution: ConflictResolution.serverWins,
      resolvedData: conflict.serverVersion,
    );
  }

  ConflictResolutionResult _resolveClientWins(SyncConflict conflict) {
    debugPrint('Conflict resolved: Client wins for ${conflict.entityId}');
    return ConflictResolutionResult(
      resolution: ConflictResolution.clientWins,
      resolvedData: conflict.clientVersion,
    );
  }

  ConflictResolutionResult _resolveLastWriteWins(SyncConflict conflict) {
    if (conflict.isServerNewer) {
      debugPrint('Conflict resolved: Last write wins (server) for ${conflict.entityId}');
      return ConflictResolutionResult(
        resolution: ConflictResolution.serverWins,
        resolvedData: conflict.serverVersion,
      );
    } else {
      debugPrint('Conflict resolved: Last write wins (client) for ${conflict.entityId}');
      return ConflictResolutionResult(
        resolution: ConflictResolution.clientWins,
        resolvedData: conflict.clientVersion,
      );
    }
  }

  Future<ConflictResolutionResult> _resolveSmartMerge(SyncConflict conflict) async {
    // Start with server data
    final merged = Map<String, dynamic>.from(conflict.serverVersion);

    // For each conflicting field, apply smart rules
    for (final field in conflict.conflictingFields) {
      final serverValue = conflict.serverVersion[field];
      final clientValue = conflict.clientVersion[field];

      // Smart merge rules:
      // 1. If client value is null, use server
      // 2. If server value is null, use client
      // 3. For arrays, merge unique values
      // 4. For timestamps, use later one
      // 5. Otherwise, prefer based on recency

      if (clientValue == null) {
        merged[field] = serverValue;
      } else if (serverValue == null) {
        merged[field] = clientValue;
      } else if (serverValue is List && clientValue is List) {
        // Merge lists, keep unique values
        merged[field] = {...serverValue, ...clientValue}.toList();
      } else if (_isTimestamp(serverValue) && _isTimestamp(clientValue)) {
        // Use later timestamp
        final serverTime = DateTime.parse(serverValue.toString());
        final clientTime = DateTime.parse(clientValue.toString());
        merged[field] = serverTime.isAfter(clientTime) ? serverValue : clientValue;
      } else {
        // Use based on overall recency
        merged[field] = conflict.isServerNewer ? serverValue : clientValue;
      }
    }

    debugPrint('Conflict resolved: Smart merge for ${conflict.entityId}');
    return ConflictResolutionResult(
      resolution: ConflictResolution.merge,
      resolvedData: merged,
    );
  }

  Future<ConflictResolutionResult> _resolveAskUser(SyncConflict conflict) async {
    if (onAskUser == null) {
      // Fallback to last write wins if no user callback
      return _resolveLastWriteWins(conflict);
    }

    final userChoice = await onAskUser!(conflict);

    if (userChoice == null) {
      // User cancelled, default to server
      return _resolveServerWins(conflict);
    }

    // Apply user's choices
    final merged = Map<String, dynamic>.from(conflict.serverVersion);
    merged.addAll(userChoice);

    debugPrint('Conflict resolved: User choice for ${conflict.entityId}');
    return ConflictResolutionResult(
      resolution: ConflictResolution.askUser,
      resolvedData: merged,
      userChoice: 'user_selected',
    );
  }

  bool _isTimestamp(dynamic value) {
    if (value is DateTime) return true;
    if (value is String) {
      try {
        DateTime.parse(value);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

/// Tracks unresolved conflicts for later review.
class ConflictLog {
  ConflictLog._();
  static final ConflictLog instance = ConflictLog._();

  final List<SyncConflict> _unresolvedConflicts = [];
  final List<ConflictResolutionResult> _resolvedConflicts = [];

  /// Add an unresolved conflict.
  void addUnresolved(SyncConflict conflict) {
    _unresolvedConflicts.add(conflict);
    debugPrint('Conflict logged: ${conflict.entityType} ${conflict.entityId}');
  }

  /// Mark a conflict as resolved.
  void markResolved(SyncConflict conflict, ConflictResolutionResult result) {
    _unresolvedConflicts.removeWhere(
      (c) => c.entityId == conflict.entityId && c.entityType == conflict.entityType,
    );
    _resolvedConflicts.add(result);
  }

  /// Get all unresolved conflicts.
  List<SyncConflict> get unresolvedConflicts => List.unmodifiable(_unresolvedConflicts);

  /// Get count of unresolved conflicts.
  int get unresolvedCount => _unresolvedConflicts.length;

  /// Clear all logs.
  void clear() {
    _unresolvedConflicts.clear();
    _resolvedConflicts.clear();
  }
}
