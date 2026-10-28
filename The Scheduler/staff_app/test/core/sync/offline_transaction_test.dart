import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/sync/offline_transaction.dart';

void main() {
  group('TransactionStatus', () {
    test('has all expected values', () {
      expect(TransactionStatus.values, [
        TransactionStatus.pending,
        TransactionStatus.executing,
        TransactionStatus.committed,
        TransactionStatus.rolledBack,
        TransactionStatus.cancelled,
      ]);
    });
  });

  group('TransactionOperation', () {
    test('creates operation with all parameters', () {
      final operation = TransactionOperation(
        id: 'op1',
        entityType: 'user',
        entityId: 'user123',
        operationType: 'create',
        data: {'name': 'Test'},
        execute: () async => true,
        rollback: () async {},
      );

      expect(operation.id, 'op1');
      expect(operation.entityType, 'user');
      expect(operation.entityId, 'user123');
      expect(operation.operationType, 'create');
      expect(operation.data, {'name': 'Test'});
    });
  });

  group('TransactionResult', () {
    test('success returns true when committed', () {
      const result = TransactionResult(
        transactionId: 'txn1',
        status: TransactionStatus.committed,
        operationsExecuted: 3,
        operationsRolledBack: 0,
      );

      expect(result.success, true);
    });

    test('success returns false when rolled back', () {
      const result = TransactionResult(
        transactionId: 'txn1',
        status: TransactionStatus.rolledBack,
        operationsExecuted: 2,
        operationsRolledBack: 2,
        error: 'Test error',
        failedOperationId: 'op3',
      );

      expect(result.success, false);
    });
  });

  group('OfflineTransaction', () {
    test('creates transaction with unique ID', () {
      final txn1 = OfflineTransaction();
      final txn2 = OfflineTransaction();

      expect(txn1.id, isNotEmpty);
      expect(txn1.id, isNot(txn2.id));
      expect(txn1.id, startsWith('txn_'));
    });

    test('creates transaction with custom ID', () {
      final txn = OfflineTransaction(id: 'custom_id');
      expect(txn.id, 'custom_id');
    });

    test('initial status is pending', () {
      final txn = OfflineTransaction();
      expect(txn.status, TransactionStatus.pending);
    });

    test('addCreate adds create operation', () {
      final txn = OfflineTransaction();

      txn.addCreate(
        entityType: 'user',
        entityId: 'u1',
        data: {'name': 'Test'},
        execute: () async => true,
        rollback: () async {},
      );

      expect(txn.summary, contains('create'));
      expect(txn.summary, contains('user'));
    });

    test('addUpdate adds update operation', () {
      final txn = OfflineTransaction();

      txn.addUpdate(
        entityType: 'user',
        entityId: 'u1',
        data: {'name': 'Updated'},
        execute: () async => true,
        rollback: () async {},
      );

      expect(txn.summary, contains('update'));
    });

    test('addDelete adds delete operation', () {
      final txn = OfflineTransaction();

      txn.addDelete(
        entityType: 'user',
        entityId: 'u1',
        execute: () async => true,
        rollback: () async {},
      );

      expect(txn.summary, contains('delete'));
    });

    test('cannot add operations after execution starts', () async {
      final txn = OfflineTransaction();
      txn.addCreate(
        entityType: 'test',
        entityId: 't1',
        data: {},
        execute: () async => true,
        rollback: () async {},
      );

      await txn.execute();

      expect(
        () => txn.addCreate(
          entityType: 'test',
          entityId: 't2',
          data: {},
          execute: () async => true,
          rollback: () async {},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('execute commits on success', () async {
      final executed = <String>[];
      final txn = OfflineTransaction();

      txn.addCreate(
        entityType: 'item',
        entityId: 'i1',
        data: {},
        execute: () async {
          executed.add('create');
          return true;
        },
        rollback: () async {},
      );

      txn.addUpdate(
        entityType: 'item',
        entityId: 'i1',
        data: {'updated': true},
        execute: () async {
          executed.add('update');
          return true;
        },
        rollback: () async {},
      );

      final result = await txn.execute();

      expect(result.status, TransactionStatus.committed);
      expect(result.operationsExecuted, 2);
      expect(result.operationsRolledBack, 0);
      expect(executed, ['create', 'update']);
    });

    test('execute rolls back on failure', () async {
      final executed = <String>[];
      final rolledBack = <String>[];
      final txn = OfflineTransaction();

      txn.addCreate(
        entityType: 'item',
        entityId: 'i1',
        data: {},
        execute: () async {
          executed.add('create');
          return true;
        },
        rollback: () async {
          rolledBack.add('create');
        },
      );

      txn.addUpdate(
        entityType: 'item',
        entityId: 'i1',
        data: {},
        execute: () async {
          executed.add('update');
          return false; // Fail
        },
        rollback: () async {
          rolledBack.add('update');
        },
      );

      final result = await txn.execute();

      expect(result.status, TransactionStatus.rolledBack);
      expect(result.operationsExecuted, 1);
      expect(result.operationsRolledBack, 1);
      expect(executed, ['create', 'update']);
      expect(rolledBack, ['create']);
    });

    test('empty transaction commits immediately', () async {
      final txn = OfflineTransaction();
      final result = await txn.execute();

      expect(result.status, TransactionStatus.committed);
      expect(result.operationsExecuted, 0);
    });

    test('cancel changes status to cancelled', () {
      final txn = OfflineTransaction();
      txn.cancel();

      expect(txn.status, TransactionStatus.cancelled);
    });

    test('cannot cancel non-pending transaction', () async {
      final txn = OfflineTransaction();
      await txn.execute();

      expect(() => txn.cancel(), throwsA(isA<StateError>()));
    });

    test('cannot execute already executed transaction', () async {
      final txn = OfflineTransaction();
      await txn.execute();

      expect(() => txn.execute(), throwsA(isA<StateError>()));
    });
  });

  group('OfflineTransactionManager', () {
    late OfflineTransactionManager manager;

    setUp(() {
      manager = OfflineTransactionManager.instance;
      manager.clearHistory();
    });

    test('singleton instance is consistent', () {
      final instance1 = OfflineTransactionManager.instance;
      final instance2 = OfflineTransactionManager.instance;
      expect(identical(instance1, instance2), true);
    });

    test('createTransaction creates new transaction', () {
      final txn = manager.createTransaction(description: 'Test');
      expect(txn, isNotNull);
      expect(txn.status, TransactionStatus.pending);
    });

    test('executeTransaction adds result to history', () async {
      final txn = manager.createTransaction();
      await manager.executeTransaction(txn);

      expect(manager.history.length, 1);
      expect(manager.history.first.status, TransactionStatus.committed);
    });

    test('runTransaction executes with builder', () async {
      var executed = false;

      final result = await manager.runTransaction(
        description: 'Test',
        builder: (txn) {
          txn.addCreate(
            entityType: 'test',
            entityId: 't1',
            data: {},
            execute: () async {
              executed = true;
              return true;
            },
            rollback: () async {},
          );
        },
      );

      expect(result.success, true);
      expect(executed, true);
    });

    test('cancelTransaction removes from pending', () {
      final txn = manager.createTransaction();
      final id = txn.id;

      manager.cancelTransaction(id);

      expect(txn.status, TransactionStatus.cancelled);
    });

    test('clearHistory empties history', () async {
      final txn = manager.createTransaction();
      await manager.executeTransaction(txn);

      manager.clearHistory();

      expect(manager.history, isEmpty);
    });
  });
}
