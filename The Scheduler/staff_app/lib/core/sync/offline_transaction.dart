// Offline Queue Transaction Support
//
// Provides transactional guarantees for offline queue operations.
// Ensures atomicity and rollback capabilities for related operations.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Status of a transaction.
enum TransactionStatus {
  /// Transaction is being built/prepared.
  pending,

  /// Transaction is currently executing.
  executing,

  /// Transaction completed successfully.
  committed,

  /// Transaction was rolled back due to error.
  rolledBack,

  /// Transaction was cancelled before execution.
  cancelled,
}

/// A single operation within a transaction.
class TransactionOperation {
  const TransactionOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.execute,
    required this.rollback,
    this.data,
  });

  /// Unique identifier for this operation.
  final String id;

  /// Type of entity being operated on.
  final String entityType;

  /// ID of the entity.
  final String entityId;

  /// Type of operation (create, update, delete).
  final String operationType;

  /// Data associated with the operation.
  final Map<String, dynamic>? data;

  /// Execute the operation. Returns true on success.
  final Future<bool> Function() execute;

  /// Rollback the operation. Called if transaction fails.
  final Future<void> Function() rollback;
}

/// Result of a transaction execution.
class TransactionResult {
  const TransactionResult({
    required this.transactionId,
    required this.status,
    required this.operationsExecuted,
    required this.operationsRolledBack,
    this.error,
    this.failedOperationId,
  });

  /// ID of the transaction.
  final String transactionId;

  /// Final status.
  final TransactionStatus status;

  /// Number of operations successfully executed.
  final int operationsExecuted;

  /// Number of operations rolled back.
  final int operationsRolledBack;

  /// Error that caused failure, if any.
  final Object? error;

  /// ID of the operation that failed, if any.
  final String? failedOperationId;

  bool get success => status == TransactionStatus.committed;
}

/// An offline transaction that groups related operations.
class OfflineTransaction {
  OfflineTransaction({
    String? id,
    this.description,
  }) : id = id ?? _generateId();

  /// Unique identifier for this transaction.
  final String id;

  /// Human-readable description.
  final String? description;

  /// Operations in this transaction (in order).
  final List<TransactionOperation> _operations = [];

  /// Current status.
  TransactionStatus _status = TransactionStatus.pending;
  TransactionStatus get status => _status;

  /// IDs of successfully executed operations.
  final List<String> _executedOperationIds = [];

  /// Add an operation to the transaction.
  void addOperation(TransactionOperation operation) {
    if (_status != TransactionStatus.pending) {
      throw StateError('Cannot add operations to a transaction that is not pending');
    }
    _operations.add(operation);
  }

  /// Add a create operation.
  void addCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required Future<bool> Function() execute,
    required Future<void> Function() rollback,
  }) {
    addOperation(TransactionOperation(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operationType: 'create',
      data: data,
      execute: execute,
      rollback: rollback,
    ));
  }

  /// Add an update operation.
  void addUpdate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required Future<bool> Function() execute,
    required Future<void> Function() rollback,
  }) {
    addOperation(TransactionOperation(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operationType: 'update',
      data: data,
      execute: execute,
      rollback: rollback,
    ));
  }

  /// Add a delete operation.
  void addDelete({
    required String entityType,
    required String entityId,
    required Future<bool> Function() execute,
    required Future<void> Function() rollback,
  }) {
    addOperation(TransactionOperation(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operationType: 'delete',
      execute: execute,
      rollback: rollback,
    ));
  }

  /// Execute all operations in the transaction.
  ///
  /// If any operation fails, all previously executed operations
  /// will be rolled back.
  Future<TransactionResult> execute() async {
    if (_status != TransactionStatus.pending) {
      throw StateError('Transaction already executed or cancelled');
    }

    if (_operations.isEmpty) {
      _status = TransactionStatus.committed;
      return TransactionResult(
        transactionId: id,
        status: TransactionStatus.committed,
        operationsExecuted: 0,
        operationsRolledBack: 0,
      );
    }

    _status = TransactionStatus.executing;
    debugPrint('Transaction $id: Executing ${_operations.length} operations');

    try {
      // Execute each operation in order
      for (final operation in _operations) {
        debugPrint('Transaction $id: Executing ${operation.operationType} on ${operation.entityType}/${operation.entityId}');

        final success = await operation.execute();

        if (!success) {
          // Operation failed, rollback
          debugPrint('Transaction $id: Operation ${operation.id} failed');
          return await _rollback(
            failedOperationId: operation.id,
            error: Exception('Operation ${operation.id} returned false'),
          );
        }

        _executedOperationIds.add(operation.id);
      }

      // All operations succeeded
      _status = TransactionStatus.committed;
      debugPrint('Transaction $id: Committed successfully');

      return TransactionResult(
        transactionId: id,
        status: TransactionStatus.committed,
        operationsExecuted: _operations.length,
        operationsRolledBack: 0,
      );
    } catch (e) {
      debugPrint('Transaction $id: Error during execution: $e');
      return await _rollback(
        failedOperationId: _operations[_executedOperationIds.length].id,
        error: e,
      );
    }
  }

  /// Rollback executed operations in reverse order.
  Future<TransactionResult> _rollback({
    required String failedOperationId,
    required Object error,
  }) async {
    debugPrint('Transaction $id: Rolling back ${_executedOperationIds.length} operations');

    var rolledBackCount = 0;

    // Rollback in reverse order
    for (final opId in _executedOperationIds.reversed) {
      final operation = _operations.firstWhere((op) => op.id == opId);
      try {
        debugPrint('Transaction $id: Rolling back ${operation.operationType} on ${operation.entityType}/${operation.entityId}');
        await operation.rollback();
        rolledBackCount++;
      } catch (rollbackError) {
        debugPrint('Transaction $id: Rollback failed for ${operation.id}: $rollbackError');
        // Continue rolling back other operations even if one fails
      }
    }

    _status = TransactionStatus.rolledBack;

    return TransactionResult(
      transactionId: id,
      status: TransactionStatus.rolledBack,
      operationsExecuted: _executedOperationIds.length,
      operationsRolledBack: rolledBackCount,
      error: error,
      failedOperationId: failedOperationId,
    );
  }

  /// Cancel the transaction before execution.
  void cancel() {
    if (_status != TransactionStatus.pending) {
      throw StateError('Can only cancel pending transactions');
    }
    _status = TransactionStatus.cancelled;
    debugPrint('Transaction $id: Cancelled');
  }

  /// Get a summary of this transaction.
  String get summary {
    final ops = _operations.map((op) => '${op.operationType}(${op.entityType}/${op.entityId})').join(', ');
    return 'Transaction[$id]: $ops (status: $_status)';
  }

  static const _uuid = Uuid();
  static String _generateId() {
    return 'txn_${_uuid.v4()}';
  }
}

/// Manager for offline transactions.
class OfflineTransactionManager {
  OfflineTransactionManager._();
  static final OfflineTransactionManager instance = OfflineTransactionManager._();

  /// Active transactions by ID.
  final Map<String, OfflineTransaction> _transactions = {};

  /// Completed transaction results (limited history).
  final List<TransactionResult> _history = [];
  static const int _maxHistorySize = 100;

  /// Create a new transaction.
  OfflineTransaction createTransaction({String? description}) {
    final transaction = OfflineTransaction(description: description);
    _transactions[transaction.id] = transaction;
    return transaction;
  }

  /// Execute a transaction.
  Future<TransactionResult> executeTransaction(OfflineTransaction transaction) async {
    final result = await transaction.execute();

    // Move to history
    _transactions.remove(transaction.id);
    _addToHistory(result);

    return result;
  }

  /// Execute a simple transaction with a builder.
  Future<TransactionResult> runTransaction({
    String? description,
    required void Function(OfflineTransaction transaction) builder,
  }) async {
    final transaction = createTransaction(description: description);
    builder(transaction);
    return executeTransaction(transaction);
  }

  /// Cancel a pending transaction.
  void cancelTransaction(String transactionId) {
    final transaction = _transactions[transactionId];
    if (transaction != null) {
      transaction.cancel();
      _transactions.remove(transactionId);
    }
  }

  /// Get recent transaction history.
  List<TransactionResult> get history => List.unmodifiable(_history);

  /// Get pending transactions.
  List<OfflineTransaction> get pendingTransactions =>
      _transactions.values.where((t) => t.status == TransactionStatus.pending).toList();

  void _addToHistory(TransactionResult result) {
    _history.add(result);
    while (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// Clear history.
  void clearHistory() {
    _history.clear();
  }
}

/// Extension for running code in a transaction.
extension TransactionalExtension on Future<bool> Function() {
  /// Wrap this operation in a simple transaction.
  Future<TransactionResult> inTransaction({
    required Future<void> Function() rollback,
    String? entityType,
    String? entityId,
    String? description,
  }) async {
    final manager = OfflineTransactionManager.instance;
    return manager.runTransaction(
      description: description,
      builder: (txn) {
        txn.addOperation(TransactionOperation(
          id: 'op_1',
          entityType: entityType ?? 'unknown',
          entityId: entityId ?? 'unknown',
          operationType: 'execute',
          execute: this,
          rollback: rollback,
        ));
      },
    );
  }
}
