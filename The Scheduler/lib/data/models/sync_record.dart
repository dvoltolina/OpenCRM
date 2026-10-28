import 'package:freezed_annotation/freezed_annotation.dart';

import '../converters/timestamp_converters.dart';

part 'sync_record.freezed.dart';
part 'sync_record.g.dart';

/// Type of local entity being synced.
enum SyncLocalType {
  @JsonValue('payment')
  payment,
  @JsonValue('client')
  client,
  @JsonValue('invoice')
  invoice,
  @JsonValue('appointment')
  appointment,
  @JsonValue('product')
  product,
  @JsonValue('service')
  service,
}

/// Extension for SyncLocalType display.
extension SyncLocalTypeExt on SyncLocalType {
  String get displayName {
    switch (this) {
      case SyncLocalType.payment:
        return 'Payment';
      case SyncLocalType.client:
        return 'Client';
      case SyncLocalType.invoice:
        return 'Invoice';
      case SyncLocalType.appointment:
        return 'Appointment';
      case SyncLocalType.product:
        return 'Product';
      case SyncLocalType.service:
        return 'Service';
    }
  }
}

/// Type of remote entity in accounting software.
enum SyncRemoteType {
  @JsonValue('invoice')
  invoice,
  @JsonValue('payment')
  payment,
  @JsonValue('customer')
  customer,
  @JsonValue('salesReceipt')
  salesReceipt,
  @JsonValue('item')
  item,
  @JsonValue('contact')
  contact, // Xero uses "Contact" for customers
}

/// Extension for SyncRemoteType display.
extension SyncRemoteTypeExt on SyncRemoteType {
  String get displayName {
    switch (this) {
      case SyncRemoteType.invoice:
        return 'Invoice';
      case SyncRemoteType.payment:
        return 'Payment';
      case SyncRemoteType.customer:
        return 'Customer';
      case SyncRemoteType.salesReceipt:
        return 'Sales Receipt';
      case SyncRemoteType.item:
        return 'Item';
      case SyncRemoteType.contact:
        return 'Contact';
    }
  }
}

/// Direction of sync operation.
enum SyncDirection {
  @JsonValue('toAccounting')
  toAccounting,
  @JsonValue('fromAccounting')
  fromAccounting,
}

/// Extension for SyncDirection display.
extension SyncDirectionExt on SyncDirection {
  String get displayName {
    switch (this) {
      case SyncDirection.toAccounting:
        return 'To Accounting';
      case SyncDirection.fromAccounting:
        return 'From Accounting';
    }
  }

  String get icon {
    switch (this) {
      case SyncDirection.toAccounting:
        return '→';
      case SyncDirection.fromAccounting:
        return '←';
    }
  }
}

/// Status of sync operation.
enum SyncStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('success')
  success,
  @JsonValue('failed')
  failed,
  @JsonValue('skipped')
  skipped,
}

/// Extension for SyncStatus display.
extension SyncStatusExt on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.success:
        return 'Success';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.skipped:
        return 'Skipped';
    }
  }

  bool get isSuccess => this == SyncStatus.success;
  bool get isFailed => this == SyncStatus.failed;
}

/// Records a sync operation between local and remote systems.
///
/// Used to:
/// - Avoid duplicate syncs by tracking what's already synced
/// - Link local records (payments, clients) to remote records (QuickBooks/Xero)
/// - Track sync history and errors for debugging
@freezed
abstract class SyncRecord with _$SyncRecord {
  const SyncRecord._();

  const factory SyncRecord({
    /// Unique identifier.
    required String id,

    /// Business this sync belongs to.
    required String businessId,

    /// The accounting connection this sync is for.
    required String connectionId,

    /// Local entity ID (payment ID, client ID, etc.).
    required String localId,

    /// Type of local entity.
    required SyncLocalType localType,

    /// Remote entity ID (QuickBooks/Xero ID).
    String? remoteId,

    /// Type of remote entity.
    required SyncRemoteType remoteType,

    /// When the sync was attempted.
    @TimestampConverter() required DateTime syncedAt,

    /// Direction of sync.
    required SyncDirection syncDirection,

    /// Status of the sync operation.
    @Default(SyncStatus.pending) SyncStatus status,

    /// Error message if sync failed.
    String? errorMessage,

    /// Number of retry attempts.
    @Default(0) int retryCount,

    /// Additional metadata (e.g., amounts, reference numbers).
    Map<String, dynamic>? metadata,

    /// Record creation timestamp.
    @NullableTimestampConverter() DateTime? createdAt,

    /// Last update timestamp.
    @NullableTimestampConverter() DateTime? updatedAt,
  }) = _SyncRecord;

  factory SyncRecord.fromJson(Map<String, dynamic> json) =>
      _$SyncRecordFromJson(json);

  /// Whether this sync was successful.
  bool get isSuccess => status == SyncStatus.success;

  /// Whether this sync failed.
  bool get isFailed => status == SyncStatus.failed;

  /// Whether this sync can be retried.
  bool get canRetry => isFailed && retryCount < 3;

  /// Display summary of the sync.
  String get displaySummary =>
      '${localType.displayName} ${syncDirection.icon} ${remoteType.displayName}';

  /// Time since sync, formatted.
  String get syncedAtDisplay {
    final diff = DateTime.now().difference(syncedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Filter options for querying sync records.
class SyncRecordFilter {
  const SyncRecordFilter({
    this.connectionId,
    this.localType,
    this.remoteType,
    this.status,
    this.syncDirection,
    this.startDate,
    this.endDate,
    this.limit,
  });

  final String? connectionId;
  final SyncLocalType? localType;
  final SyncRemoteType? remoteType;
  final SyncStatus? status;
  final SyncDirection? syncDirection;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
}
