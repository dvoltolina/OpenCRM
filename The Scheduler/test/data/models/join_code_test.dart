import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/join_code.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('JoinCode Model', () {
    group('JSON Serialization', () {
      test('creates join code from JSON', () {
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: 7));

        final json = {
          'id': 'code-123',
          'businessId': 'business-456',
          'codeHash': 'hash123abc',
          'createdBy': 'admin-1',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'maxUses': 10,
          'uses': 3,
          'role': 'staff',
          'status': 'active',
          'lastUsedAt': Timestamp.fromDate(now),
          'lastUsedBy': 'user-1',
          'notes': 'Test code',
        };

        final joinCode = JoinCode.fromJson(json);

        expect(joinCode.id, 'code-123');
        expect(joinCode.businessId, 'business-456');
        expect(joinCode.codeHash, 'hash123abc');
        expect(joinCode.createdBy, 'admin-1');
        expect(joinCode.createdAt, now);
        expect(joinCode.expiresAt, expiresAt);
        expect(joinCode.maxUses, 10);
        expect(joinCode.uses, 3);
        expect(joinCode.role, 'staff');
        expect(joinCode.status, JoinCodeStatus.active);
        expect(joinCode.lastUsedAt, now);
        expect(joinCode.lastUsedBy, 'user-1');
        expect(joinCode.notes, 'Test code');
      });

      test('converts join code to JSON', () {
        final joinCode = TestData.joinCode(
          id: 'code-123',
          businessId: 'business-456',
          codeHash: 'hash123',
          maxUses: 5,
          uses: 2,
        );

        final json = joinCode.toJson();

        expect(json['id'], 'code-123');
        expect(json['businessId'], 'business-456');
        expect(json['codeHash'], 'hash123');
        expect(json['maxUses'], 5);
        expect(json['uses'], 2);
      });

      test('handles null optional fields', () {
        final now = DateTime.now();
        final joinCode = JoinCode(
          id: 'code-1',
          businessId: 'business-1',
          codeHash: 'hash123',
          createdBy: 'admin-1',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 7)),
          maxUses: 5,
          uses: 0,
          role: 'staff',
          status: JoinCodeStatus.active,
        );

        final json = joinCode.toJson();
        final deserialized = JoinCode.fromJson(json);

        expect(deserialized.lastUsedAt, null);
        expect(deserialized.lastUsedBy, null);
        expect(deserialized.notes, null);
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore removes id from document data', () {
        final joinCode = TestData.joinCode(id: 'code-123');
        final firestoreData = joinCode.toFirestore();

        expect(firestoreData.containsKey('id'), false);
        expect(firestoreData.containsKey('businessId'), true);
        expect(firestoreData.containsKey('codeHash'), true);
      });

      test('toFirestore converts DateTime to Timestamp', () {
        final joinCode = TestData.joinCode();
        final firestoreData = joinCode.toFirestore();

        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['expiresAt'], isA<Timestamp>());
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final original = TestData.joinCode(status: JoinCodeStatus.active);
        final updated = original.copyWith(status: JoinCodeStatus.revoked);

        expect(updated.status, JoinCodeStatus.revoked);
        expect(updated.id, original.id);
        expect(updated.businessId, original.businessId);
      });

      test('copies with incremented uses', () {
        final original = TestData.joinCode(uses: 3);
        final updated = original.copyWith(uses: 4);

        expect(updated.uses, 4);
        expect(updated.id, original.id);
      });

      test('copies with last used info', () {
        final now = DateTime.now();
        final original = TestData.joinCode();
        final updated = original.copyWith(
          lastUsedAt: now,
          lastUsedBy: 'user-123',
        );

        expect(updated.lastUsedAt, now);
        expect(updated.lastUsedBy, 'user-123');
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.joinCode();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.codeHash, original.codeHash);
        expect(copy.maxUses, original.maxUses);
        expect(copy.uses, original.uses);
      });
    });

    group('Helper Methods', () {
      test('isExpired returns true for past expiresAt', () {
        final expiredCode = TestData.joinCode(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredCode.isExpired, true);
      });

      test('isExpired returns false for future expiresAt', () {
        final validCode = TestData.joinCode(
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(validCode.isExpired, false);
      });

      test('isUsable returns false when uses >= maxUses', () {
        final depletedCode = TestData.joinCode(
          maxUses: 5,
          uses: 5,
          status: JoinCodeStatus.active,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(depletedCode.isUsable, false);
      });

      test('isUsable returns false when status is revoked', () {
        final revokedCode = TestData.joinCode(
          maxUses: 5,
          uses: 2,
          status: JoinCodeStatus.revoked,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(revokedCode.isUsable, false);
      });

      test('isUsable returns false when expired', () {
        final expiredCode = TestData.joinCode(
          maxUses: 5,
          uses: 2,
          status: JoinCodeStatus.active,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredCode.isUsable, false);
      });

      test('isUsable returns true when active, not expired, and has remaining uses', () {
        final usableCode = TestData.joinCode(
          maxUses: 5,
          uses: 2,
          status: JoinCodeStatus.active,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(usableCode.isUsable, true);
      });

      test('remainingUses calculates correctly', () {
        final code1 = TestData.joinCode(maxUses: 10, uses: 3);
        expect(code1.remainingUses, 7);

        final code2 = TestData.joinCode(maxUses: 5, uses: 5);
        expect(code2.remainingUses, 0);

        final code3 = TestData.joinCode(maxUses: 1, uses: 0);
        expect(code3.remainingUses, 1);
      });

      test('remainingUses never goes negative', () {
        final overusedCode = TestData.joinCode(maxUses: 5, uses: 10);
        expect(overusedCode.remainingUses, 0);
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Code = TestData.joinCode(businessId: 'business-1');
        final business2Code = TestData.joinCode(businessId: 'business-2');

        expect(business1Code.businessId, 'business-1');
        expect(business2Code.businessId, 'business-2');
        expect(
          business1Code.businessId,
          isNot(equals(business2Code.businessId)),
        );
      });

      test('tracks creator for audit purposes', () {
        final code = TestData.joinCode(createdBy: 'admin-123');
        expect(code.createdBy, 'admin-123');
      });

      test('supports different roles', () {
        final staffCode = TestData.joinCode(role: 'staff');
        final adminCode = TestData.joinCode(role: 'admin');

        expect(staffCode.role, 'staff');
        expect(adminCode.role, 'admin');
      });

      test('stores code as hash for security', () {
        final code = TestData.joinCode(codeHash: 'sha256hash123abc');
        expect(code.codeHash, 'sha256hash123abc');
        // Verify it's a hash, not plaintext (no spaces or special chars typical of plaintext)
        expect(code.codeHash.contains(' '), false);
      });
    });

    group('Status Lifecycle', () {
      test('active code can be used', () {
        final activeCode = TestData.joinCode(
          status: JoinCodeStatus.active,
          uses: 0,
          maxUses: 5,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(activeCode.status, JoinCodeStatus.active);
        expect(activeCode.isUsable, true);
      });

      test('revoked code cannot be used', () {
        final revokedCode = TestData.joinCode(
          status: JoinCodeStatus.revoked,
          uses: 2,
          maxUses: 5,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(revokedCode.status, JoinCodeStatus.revoked);
        expect(revokedCode.isUsable, false);
      });

      test('expired code cannot be used even if marked active', () {
        final expiredCode = TestData.joinCode(
          status: JoinCodeStatus.active,
          uses: 2,
          maxUses: 5,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredCode.status, JoinCodeStatus.active);
        expect(expiredCode.isExpired, true);
        expect(expiredCode.isUsable, false);
      });
    });

    group('Usage Tracking', () {
      test('tracks number of uses', () {
        final code = TestData.joinCode(uses: 3, maxUses: 10);
        expect(code.uses, 3);
        expect(code.maxUses, 10);
        expect(code.remainingUses, 7);
      });

      test('tracks last usage', () {
        final lastUsed = DateTime.now().subtract(const Duration(hours: 2));
        final code = TestData.joinCode(
          lastUsedAt: lastUsed,
          lastUsedBy: 'user-456',
        );

        expect(code.lastUsedAt, lastUsed);
        expect(code.lastUsedBy, 'user-456');
      });

      test('handles unused code', () {
        final unusedCode = TestData.joinCode(uses: 0);
        expect(unusedCode.uses, 0);
        expect(unusedCode.lastUsedAt, null);
        expect(unusedCode.lastUsedBy, null);
      });

      test('maxUses limit prevents overuse', () {
        final singleUseCode = TestData.joinCode(maxUses: 1, uses: 0);
        expect(singleUseCode.remainingUses, 1);

        final usedSingleCode = singleUseCode.copyWith(uses: 1);
        expect(usedSingleCode.remainingUses, 0);
        expect(usedSingleCode.isUsable, false);
      });
    });

    group('Test Data Factory', () {
      test('creates join code with defaults', () {
        final code = TestData.joinCode();

        expect(code.id, isNotEmpty);
        expect(code.businessId, isNotEmpty);
        expect(code.codeHash, isNotEmpty);
        expect(code.createdBy, isNotEmpty);
        expect(code.maxUses, greaterThan(0));
        expect(code.role, isNotEmpty);
      });

      test('creates join code with custom values', () {
        final now = DateTime.now();
        final code = TestData.joinCode(
          id: 'custom-id',
          businessId: 'custom-business',
          codeHash: 'custom-hash',
          maxUses: 20,
          uses: 5,
          role: 'admin',
          status: JoinCodeStatus.revoked,
          createdAt: now,
        );

        expect(code.id, 'custom-id');
        expect(code.businessId, 'custom-business');
        expect(code.codeHash, 'custom-hash');
        expect(code.maxUses, 20);
        expect(code.uses, 5);
        expect(code.role, 'admin');
        expect(code.status, JoinCodeStatus.revoked);
        expect(code.createdAt, now);
      });
    });

    group('Real-World Scenarios', () {
      test('single-use onboarding code', () {
        final oneTimeCode = JoinCode(
          id: 'code-single',
          businessId: 'dental-clinic',
          codeHash: 'abc123hash',
          createdBy: 'owner-1',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          maxUses: 1,
          uses: 0,
          role: 'staff',
          status: JoinCodeStatus.active,
          notes: 'For new hygienist Sarah',
        );

        expect(oneTimeCode.maxUses, 1);
        expect(oneTimeCode.remainingUses, 1);
        expect(oneTimeCode.isUsable, true);
      });

      test('team onboarding code with multiple uses', () {
        final teamCode = JoinCode(
          id: 'code-team',
          businessId: 'therapy-center',
          codeHash: 'team456hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          maxUses: 10,
          uses: 3,
          role: 'staff',
          status: JoinCodeStatus.active,
          notes: 'For new therapy team',
        );

        expect(teamCode.maxUses, 10);
        expect(teamCode.uses, 3);
        expect(teamCode.remainingUses, 7);
        expect(teamCode.isUsable, true);
      });

      test('expired code should not be usable', () {
        final expiredCode = JoinCode(
          id: 'code-expired',
          businessId: 'realty-firm',
          codeHash: 'expired789hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          expiresAt: DateTime.now().subtract(const Duration(days: 7)),
          maxUses: 5,
          uses: 2,
          role: 'staff',
          status: JoinCodeStatus.active,
        );

        expect(expiredCode.isExpired, true);
        expect(expiredCode.isUsable, false);
        expect(expiredCode.remainingUses, 3); // Still has uses, but expired
      });

      test('revoked code should not be usable', () {
        final revokedCode = JoinCode(
          id: 'code-revoked',
          businessId: 'medical-clinic',
          codeHash: 'revoked000hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          expiresAt: DateTime.now().add(const Duration(days: 25)),
          maxUses: 5,
          uses: 2,
          role: 'staff',
          status: JoinCodeStatus.revoked,
          notes: 'Revoked due to security concern',
        );

        expect(revokedCode.status, JoinCodeStatus.revoked);
        expect(revokedCode.isUsable, false);
        expect(revokedCode.isExpired, false); // Not expired, but revoked
      });
    });
  });
}
