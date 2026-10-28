import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/services/integration_token_cipher.dart';
import 'package:the_scheduler/core/services/magic_link_service.dart';
import 'package:the_scheduler/data/models/magic_link_token.dart';
import 'package:the_scheduler/data/models/security_context.dart';

void main() {
  group('MagicLinkService', () {
    late FakeFirebaseFirestore firestore;
    late MagicLinkService service;
    final context = SecurityContext(
      userId: 'user-1',
      businessId: 'biz-1',
      role: UserRole.owner,
    );

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = MagicLinkService(
        firestore: firestore,
        tokenExpirationHours: 24,
        baseUrl: 'https://test.app',
      );
    });

    test('generates tokens, persists them, and builds link URL', () async {
      final token = await service.generateToken(
        context: context,
        appointmentId: 'appt-1',
        clientId: 'client-1',
        clientEmail: 'client@example.com',
      );

      final doc = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['businessId'], context.businessId);
      expect(doc.data()?['status'], 'active');
      expect(
        service.generateMagicLinkUrl(token: token),
        'https://test.app/appointment/${token.token}',
      );
    });

    test('respects custom expiration window when generating tokens', () async {
      final shortLivedService = MagicLinkService(
        firestore: firestore,
        tokenExpirationHours: 2,
        baseUrl: 'https://short.example',
      );

      final token = await shortLivedService.generateToken(
        context: context,
        appointmentId: 'appt-expiring',
        clientId: 'client-expiring',
        clientEmail: 'expire@example.com',
      );

      final stored = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .get();

      final storedExpiresAt = stored.data()!['expiresAt'];
      final expiresAt = storedExpiresAt is Timestamp
          ? storedExpiresAt.toDate()
          : DateTime.parse(storedExpiresAt as String);
      expect(
        token.expiresAt.difference(token.createdAt),
        const Duration(hours: 2),
      );
      expect(expiresAt.isAtSameMomentAs(token.expiresAt), isTrue);
    });

    test('validateToken marks expired tokens as expired and returns null',
        () async {
      final token = await service.generateToken(
        context: context,
        appointmentId: 'appt-2',
        clientId: 'client-2',
        clientEmail: 'client2@example.com',
      );

      await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .update({
        'expiresAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      });

      final result = await service.validateToken(
        tokenString: token.token,
        businessId: context.businessId,
      );

      expect(result, isNull);
      final stored = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .get();
      expect(stored.data()?['status'], 'expired');
    });

    test('validateToken records access count for valid tokens', () async {
      final token = await service.generateToken(
        context: context,
        appointmentId: 'appt-3',
        clientId: 'client-3',
        clientEmail: 'client3@example.com',
      );

      final validated = await service.validateToken(
        tokenString: token.token,
        businessId: context.businessId,
      );

      expect(validated, isNotNull);
      final stored = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .get();
      expect(stored.data()?['accessCount'], 1);
      expect(stored.data()?['hasBeenUsed'], isTrue);
      expect(stored.data()?['lastAccessedAt'], isNotNull);
    });

    test('validateToken does not leak tokens across businesses', () async {
      final token = await service.generateToken(
        context: context,
        appointmentId: 'appt-tenant-1',
        clientId: 'client-tenant-1',
        clientEmail: 'tenant1@example.com',
      );

      final wrongBusinessResult = await service.validateToken(
        tokenString: token.token,
        businessId: 'other-biz',
      );

      expect(wrongBusinessResult, isNull);
      final stored = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(token.id)
          .get();
      expect(stored.data()?['status'], 'active');
      expect(stored.data()?['hasBeenUsed'], isFalse);
    });

    test('cleanupExpiredTokens deletes tokens older than cutoff', () async {
      final expired = await service.generateToken(
        context: context,
        appointmentId: 'appt-4',
        clientId: 'client-4',
        clientEmail: 'client4@example.com',
      );
      final recent = await service.generateToken(
        context: context,
        appointmentId: 'appt-5',
        clientId: 'client-5',
        clientEmail: 'client5@example.com',
      );

      await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(expired.id)
          .update({
        'expiresAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 10))),
      });

      final removed = await service.cleanupExpiredTokens(
        businessId: context.businessId,
        daysOld: 7,
      );

      expect(removed, 1);
      final expiredDoc = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(expired.id)
          .get();
      final recentDoc = await firestore
          .collection('businesses')
          .doc(context.businessId)
          .collection('magic_link_tokens')
          .doc(recent.id)
          .get();

      expect(expiredDoc.exists, isFalse);
      expect(recentDoc.exists, isTrue);
    });

    test('revokeTokensForAppointment immediately invalidates access', () async {
      final sharedContext = context;
      final first = await service.generateToken(
        context: sharedContext,
        appointmentId: 'group-session',
        clientId: 'client-1',
        clientEmail: 'one@example.com',
      );
      final second = await service.generateToken(
        context: sharedContext,
        appointmentId: 'group-session',
        clientId: 'client-2',
        clientEmail: 'two@example.com',
      );
      await service.generateToken(
        context: sharedContext,
        appointmentId: 'other-session',
        clientId: 'client-3',
        clientEmail: 'three@example.com',
      );

      await service.revokeTokensForAppointment(
        businessId: sharedContext.businessId,
        appointmentId: 'group-session',
      );

      final firstResult = await service.validateToken(
        tokenString: first.token,
        businessId: sharedContext.businessId,
      );
      final secondResult = await service.validateToken(
        tokenString: second.token,
        businessId: sharedContext.businessId,
      );

      expect(firstResult, isNull);
      expect(secondResult, isNull);
      final stored = await service.getToken(
        businessId: sharedContext.businessId,
        tokenId: first.id,
      );
      expect(stored?.status, MagicLinkTokenStatus.revoked);
    });

    test('watchTokensForAppointment streams scoped token updates', () async {
      final streamContext = context;
      await service.generateToken(
        context: streamContext,
        appointmentId: 'appt-stream',
        clientId: 'client-a',
        clientEmail: 'a@example.com',
      );
      await service.generateToken(
        context: streamContext,
        appointmentId: 'appt-stream',
        clientId: 'client-b',
        clientEmail: 'b@example.com',
      );

      final snapshot = await service
          .watchTokensForAppointment(
            businessId: streamContext.businessId,
            appointmentId: 'appt-stream',
          )
          .firstWhere((tokens) => tokens.length == 2);

      expect(snapshot.map((t) => t.appointmentId).toSet(), {'appt-stream'});
      expect(snapshot.every((t) => t.status == MagicLinkTokenStatus.active), isTrue);
    });
  });

  group('IntegrationTokenCipher', () {
    test('round-trips plaintext through encrypt/decrypt', () {
      final key = base64.encode(List<int>.generate(32, (i) => i + 1));
      final cipher = IntegrationTokenCipher(key);

      const plaintext = 'oauth-token-123';
      final encrypted = cipher.encrypt(plaintext);
      final decrypted = cipher.decrypt(encrypted);

      expect(decrypted, plaintext);
    });

    test('throws FormatException when payload is malformed', () {
      final key = base64.encode(List<int>.generate(32, (i) => i + 1));
      final cipher = IntegrationTokenCipher(key);

      expect(() => cipher.decrypt('invalid-payload'), throwsFormatException);
    });

    test('pads shorter keys to 32 bytes and still decrypts correctly', () {
      final shortKey = base64.encode(utf8.encode('short-key'));
      final cipher = IntegrationTokenCipher(shortKey);

      const plaintext = 'token-value';
      final encrypted = cipher.encrypt(plaintext);

      expect(cipher.decrypt(encrypted), plaintext);
    });
  });
}
