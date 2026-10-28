import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/audit_log.dart';
import 'package:the_scheduler/data/repositories/audit_log_repository.dart';

void main() {
  group('AuditLogRepository', () {
    late FakeFirebaseFirestore firestore;
    late AuditLogRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = AuditLogRepository(firestore: firestore);
    });

    test('strips client ip and sanitizes metadata', () async {
      final entry = AuditLogEntry(
        businessId: 'biz-1',
        userId: 'user-1',
        actionType: AuditActionType.phiRead,
        entityType: 'Client',
        entityId: 'client-123',
        ipAddress: '203.0.113.1',
        metadata: <String, dynamic>{
          'allowed': 'short',
          'longText': 'x' * 150,
          'nested': {'bad': true},
          'count': 5,
        },
      );

      await repository.logEvent(entry);

      final snapshot = await firestore
          .collection('businesses')
          .doc('biz-1')
          .collection('audit_logs')
          .get();

      expect(snapshot.docs, hasLength(1));
      final data = snapshot.docs.first.data();
      expect(data.containsKey('ipAddress'), isFalse);
      expect(data['metadata'], equals({'allowed': 'short', 'count': 5}));
      expect(data['timestamp'], isNotNull);
      expect(data['timestamp'], anyOf(isA<Timestamp>(), isA<DateTime>()));
    });

    test('skips writes when businessId missing', () async {
      final entry = AuditLogEntry(
        businessId: '',
        userId: 'user-1',
        actionType: AuditActionType.loginSuccess,
        entityType: 'Auth',
        entityId: 'signin',
      );

      await repository.logEvent(entry);

      final snapshot = await firestore
          .collection('businesses')
          .doc('')
          .collection('audit_logs')
          .get();

      expect(snapshot.docs, isEmpty);
    });
  });
}
