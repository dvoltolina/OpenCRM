// Audit Log Service
//
// Provides audit logging functionality with local persistence.
// Stores security-relevant events for HIPAA compliance.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Type of audit event.
enum AuditEventType {
  authentication,
  dataAccess,
  dataModification,
  security,
  sync,
  system,
}

/// Severity of audit event.
enum AuditSeverity {
  info,
  warning,
  error,
  critical,
}

/// An audit log entry.
class AuditLogEntry {
  AuditLogEntry({
    String? id,
    DateTime? timestamp,
    required this.type,
    required this.action,
    required this.severity,
    this.details,
    this.userId,
    this.deviceInfo,
    this.ipAddress,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  final String id;
  final DateTime timestamp;
  final AuditEventType type;
  final String action;
  final AuditSeverity severity;
  final String? details;
  final String? userId;
  final String? deviceInfo;
  final String? ipAddress;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
        'action': action,
        'severity': severity.index,
        'details': details,
        'userId': userId,
        'deviceInfo': deviceInfo,
        'ipAddress': ipAddress,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) => AuditLogEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: AuditEventType.values[json['type'] as int],
        action: json['action'] as String,
        severity: AuditSeverity.values[json['severity'] as int],
        details: json['details'] as String?,
        userId: json['userId'] as String?,
        deviceInfo: json['deviceInfo'] as String?,
        ipAddress: json['ipAddress'] as String?,
      );
}

/// Service for managing audit logs.
class AuditLogService {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  static const String _storageKey = 'audit_logs';
  static const int _maxLogEntries = 1000;

  final _logsController = StreamController<List<AuditLogEntry>>.broadcast();
  List<AuditLogEntry> _logs = [];
  bool _initialized = false;
  String? _currentUserId;
  String? _currentDeviceInfo;

  /// Stream of audit logs.
  Stream<List<AuditLogEntry>> get logsStream => _logsController.stream;

  /// Get all logs.
  List<AuditLogEntry> get logs => List.unmodifiable(_logs);

  /// Whether service is initialized.
  bool get isInitialized => _initialized;

  /// Initialize the service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_storageKey) ?? [];

      _logs = logsJson.map((json) {
        try {
          final map = _parseJson(json);
          return AuditLogEntry.fromJson(map);
        } catch (e) {
          debugPrint('AuditLogService: Failed to parse log entry: $e');
          return null;
        }
      }).whereType<AuditLogEntry>().toList();

      // Sort by timestamp descending
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _initialized = true;
      _logsController.add(_logs);
      debugPrint('AuditLogService: Initialized with ${_logs.length} logs');
    } catch (e) {
      debugPrint('AuditLogService: Failed to initialize: $e');
      _initialized = true;
    }
  }

  /// Set user context for logging.
  void setUserContext({String? userId, String? deviceInfo}) {
    _currentUserId = userId;
    _currentDeviceInfo = deviceInfo;
  }

  /// Clear user context on logout.
  void clearUserContext() {
    _currentUserId = null;
  }

  /// Log an audit event.
  Future<void> log({
    required AuditEventType type,
    required String action,
    AuditSeverity severity = AuditSeverity.info,
    String? details,
    String? userId,
    String? deviceInfo,
  }) async {
    final entry = AuditLogEntry(
      type: type,
      action: action,
      severity: severity,
      details: details,
      userId: userId ?? _currentUserId,
      deviceInfo: deviceInfo ?? _currentDeviceInfo,
    );

    _logs.insert(0, entry);

    // Trim if too many logs
    while (_logs.length > _maxLogEntries) {
      _logs.removeLast();
    }

    await _persist();
    _logsController.add(_logs);

    debugPrint('AuditLog: [${severity.name}] ${type.name}: $action');
  }

  /// Log authentication events.
  Future<void> logAuthentication(String action, {
    AuditSeverity severity = AuditSeverity.info,
    String? details,
  }) async {
    await log(
      type: AuditEventType.authentication,
      action: action,
      severity: severity,
      details: details,
    );
  }

  /// Log data access events.
  Future<void> logDataAccess(String action, {
    String? details,
  }) async {
    await log(
      type: AuditEventType.dataAccess,
      action: action,
      severity: AuditSeverity.info,
      details: details,
    );
  }

  /// Log data modification events.
  Future<void> logDataModification(String action, {
    String? details,
  }) async {
    await log(
      type: AuditEventType.dataModification,
      action: action,
      severity: AuditSeverity.info,
      details: details,
    );
  }

  /// Log security events.
  Future<void> logSecurity(String action, {
    AuditSeverity severity = AuditSeverity.warning,
    String? details,
  }) async {
    await log(
      type: AuditEventType.security,
      action: action,
      severity: severity,
      details: details,
    );
  }

  /// Log sync events.
  Future<void> logSync(String action, {
    AuditSeverity severity = AuditSeverity.info,
    String? details,
  }) async {
    await log(
      type: AuditEventType.sync,
      action: action,
      severity: severity,
      details: details,
    );
  }

  /// Log system events.
  Future<void> logSystem(String action, {
    AuditSeverity severity = AuditSeverity.info,
    String? details,
  }) async {
    await log(
      type: AuditEventType.system,
      action: action,
      severity: severity,
      details: details,
    );
  }

  /// Get logs filtered by criteria.
  List<AuditLogEntry> getFilteredLogs({
    AuditEventType? type,
    AuditSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    var filtered = _logs.where((log) {
      if (type != null && log.type != type) return false;
      if (severity != null && log.severity != severity) return false;
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  /// Clear all logs.
  Future<void> clearLogs() async {
    _logs.clear();
    await _persist();
    _logsController.add(_logs);
    debugPrint('AuditLogService: Logs cleared');
  }

  /// Export logs as JSON string.
  String exportLogsAsJson() {
    final jsonList = _logs.map((log) => log.toJson()).toList();
    return jsonList.toString();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => _encodeJson(log.toJson())).toList();
      await prefs.setStringList(_storageKey, logsJson);
    } catch (e) {
      debugPrint('AuditLogService: Failed to persist logs: $e');
    }
  }

  String _encodeJson(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in map.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":');
      final value = entry.value;
      if (value == null) {
        buffer.write('null');
      } else if (value is String) {
        buffer.write('"${value.replaceAll('"', r'\"')}"');
      } else if (value is num || value is bool) {
        buffer.write(value);
      } else {
        buffer.write('"$value"');
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  Map<String, dynamic> _parseJson(String json) {
    final map = <String, dynamic>{};
    // Simple JSON parsing for our specific format
    final content = json.substring(1, json.length - 1);
    final pairs = <String>[];

    var depth = 0;
    var start = 0;
    for (var i = 0; i < content.length; i++) {
      final c = content[i];
      if (c == '{' || c == '[') depth++;
      if (c == '}' || c == ']') depth--;
      if (c == ',' && depth == 0) {
        pairs.add(content.substring(start, i));
        start = i + 1;
      }
    }
    if (start < content.length) {
      pairs.add(content.substring(start));
    }

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex == -1) continue;

      var key = pair.substring(0, colonIndex).trim();
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }

      var value = pair.substring(colonIndex + 1).trim();
      if (value == 'null') {
        map[key] = null;
      } else if (value.startsWith('"') && value.endsWith('"')) {
        map[key] = value.substring(1, value.length - 1).replaceAll(r'\"', '"');
      } else if (value == 'true') {
        map[key] = true;
      } else if (value == 'false') {
        map[key] = false;
      } else {
        map[key] = int.tryParse(value) ?? double.tryParse(value) ?? value;
      }
    }

    return map;
  }

  /// Dispose resources.
  void dispose() {
    _logsController.close();
  }
}

/// Provider for audit log service.
final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return AuditLogService.instance;
});

/// Provider for audit logs stream.
final auditLogsStreamProvider = StreamProvider<List<AuditLogEntry>>((ref) {
  final service = ref.watch(auditLogServiceProvider);
  return service.logsStream;
});

/// Provider for filtered audit logs.
final filteredAuditLogsProvider = Provider.family<List<AuditLogEntry>, AuditLogFilter>((ref, filter) {
  final service = ref.watch(auditLogServiceProvider);
  return service.getFilteredLogs(
    type: filter.type,
    severity: filter.severity,
    startDate: filter.startDate,
    endDate: filter.endDate,
    limit: filter.limit,
  );
});

/// Filter parameters for audit logs.
class AuditLogFilter {
  const AuditLogFilter({
    this.type,
    this.severity,
    this.startDate,
    this.endDate,
    this.limit,
  });

  final AuditEventType? type;
  final AuditSeverity? severity;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
}
