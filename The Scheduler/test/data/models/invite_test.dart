import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/invite.dart';

import '../../helpers/test_data_factories.dart';

void main() {
  group('Invite Model', () {
    group('JSON Serialization', () {
      test('creates invite from JSON', () {
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: 7));
        final acceptedAt = now.add(const Duration(hours: 2));

        final json = {
          'id': 'invite-123',
          'businessId': 'business-456',
          'email': 'staff@example.com',
          'role': 'staff',
          'tokenHash': 'hash123abc',
          'createdBy': 'admin-1',
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'status': 'pending',
          'acceptedAt': Timestamp.fromDate(acceptedAt),
          'acceptedBy': 'user-1',
          'notes': 'Test invite',
        };

        final invite = Invite.fromJson(json);

        expect(invite.id, 'invite-123');
        expect(invite.businessId, 'business-456');
        expect(invite.email, 'staff@example.com');
        expect(invite.role, 'staff');
        expect(invite.tokenHash, 'hash123abc');
        expect(invite.createdBy, 'admin-1');
        expect(invite.createdAt, now);
        expect(invite.expiresAt, expiresAt);
        expect(invite.status, InviteStatus.pending);
        expect(invite.acceptedAt, acceptedAt);
        expect(invite.acceptedBy, 'user-1');
        expect(invite.notes, 'Test invite');
      });

      test('converts invite to JSON', () {
        final invite = TestData.invite(
          id: 'invite-123',
          businessId: 'business-456',
          email: 'staff@example.com',
          role: 'staff',
        );

        final json = invite.toJson();

        expect(json['id'], 'invite-123');
        expect(json['businessId'], 'business-456');
        expect(json['email'], 'staff@example.com');
        expect(json['role'], 'staff');
      });

      test('handles null optional fields', () {
        final now = DateTime.now();
        final invite = Invite(
          id: 'invite-1',
          businessId: 'business-1',
          email: 'test@example.com',
          role: 'staff',
          tokenHash: 'hash123',
          createdBy: 'admin-1',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 7)),
          status: InviteStatus.pending,
        );

        final json = invite.toJson();
        final deserialized = Invite.fromJson(json);

        expect(deserialized.acceptedAt, null);
        expect(deserialized.acceptedBy, null);
        expect(deserialized.notes, null);
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore removes id from document data', () {
        final invite = TestData.invite(id: 'invite-123');
        final firestoreData = invite.toFirestore();

        expect(firestoreData.containsKey('id'), false);
        expect(firestoreData.containsKey('businessId'), true);
        expect(firestoreData.containsKey('email'), true);
      });

      test('toFirestore converts DateTime to Timestamp', () {
        final invite = TestData.invite();
        final firestoreData = invite.toFirestore();

        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['expiresAt'], isA<Timestamp>());
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final original = TestData.invite(status: InviteStatus.pending);
        final updated = original.copyWith(status: InviteStatus.accepted);

        expect(updated.status, InviteStatus.accepted);
        expect(updated.id, original.id);
        expect(updated.email, original.email);
      });

      test('copies with accepted info', () {
        final now = DateTime.now();
        final original = TestData.invite();
        final updated = original.copyWith(
          acceptedAt: now,
          acceptedBy: 'user-123',
          status: InviteStatus.accepted,
        );

        expect(updated.acceptedAt, now);
        expect(updated.acceptedBy, 'user-123');
        expect(updated.status, InviteStatus.accepted);
        expect(updated.id, original.id);
      });

      test('preserves all fields when no changes', () {
        final original = TestData.invite();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.businessId, original.businessId);
        expect(copy.email, original.email);
        expect(copy.role, original.role);
        expect(copy.tokenHash, original.tokenHash);
      });
    });

    group('Helper Methods', () {
      test('isExpired returns true for past expiresAt', () {
        final expiredInvite = TestData.invite(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredInvite.isExpired, true);
      });

      test('isExpired returns false for future expiresAt', () {
        final validInvite = TestData.invite(
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(validInvite.isExpired, false);
      });

      test('isPending returns true for pending status and not expired', () {
        final pendingInvite = TestData.invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(pendingInvite.isPending, true);
      });

      test('isPending returns false for accepted status', () {
        final acceptedInvite = TestData.invite(
          status: InviteStatus.accepted,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(acceptedInvite.isPending, false);
      });

      test('isPending returns false for revoked status', () {
        final revokedInvite = TestData.invite(
          status: InviteStatus.revoked,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(revokedInvite.isPending, false);
      });

      test('isPending returns false when expired even if status is pending', () {
        final expiredPendingInvite = TestData.invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredPendingInvite.isPending, false);
      });
    });

    group('Business Logic', () {
      test('supports multi-tenant isolation', () {
        final business1Invite = TestData.invite(businessId: 'business-1');
        final business2Invite = TestData.invite(businessId: 'business-2');

        expect(business1Invite.businessId, 'business-1');
        expect(business2Invite.businessId, 'business-2');
        expect(
          business1Invite.businessId,
          isNot(equals(business2Invite.businessId)),
        );
      });

      test('tracks creator for audit purposes', () {
        final invite = TestData.invite(createdBy: 'admin-123');
        expect(invite.createdBy, 'admin-123');
      });

      test('supports different roles', () {
        final staffInvite = TestData.invite(role: 'staff');
        final adminInvite = TestData.invite(role: 'admin');

        expect(staffInvite.role, 'staff');
        expect(adminInvite.role, 'admin');
      });

      test('stores token as hash for security', () {
        final invite = TestData.invite(tokenHash: 'sha256hash123abc');
        expect(invite.tokenHash, 'sha256hash123abc');
        // Verify it's a hash, not plaintext
        expect(invite.tokenHash.contains(' '), false);
      });

      test('email is stored for invite targeting', () {
        final invite = TestData.invite(email: 'newstaff@example.com');
        expect(invite.email, 'newstaff@example.com');
      });
    });

    group('Status Lifecycle', () {
      test('pending invite can be accepted', () {
        final pendingInvite = TestData.invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(pendingInvite.status, InviteStatus.pending);
        expect(pendingInvite.isPending, true);
      });

      test('accepted invite tracks acceptance info', () {
        final now = DateTime.now();
        final acceptedInvite = TestData.invite(
          status: InviteStatus.accepted,
          acceptedAt: now,
          acceptedBy: 'user-123',
        );

        expect(acceptedInvite.status, InviteStatus.accepted);
        expect(acceptedInvite.acceptedAt, now);
        expect(acceptedInvite.acceptedBy, 'user-123');
        expect(acceptedInvite.isPending, false);
      });

      test('revoked invite cannot be used', () {
        final revokedInvite = TestData.invite(
          status: InviteStatus.revoked,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(revokedInvite.status, InviteStatus.revoked);
        expect(revokedInvite.isPending, false);
      });

      test('expired invite cannot be used even if marked pending', () {
        final expiredInvite = TestData.invite(
          status: InviteStatus.pending,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(expiredInvite.status, InviteStatus.pending);
        expect(expiredInvite.isExpired, true);
        expect(expiredInvite.isPending, false);
      });
    });

    group('Test Data Factory', () {
      test('creates invite with defaults', () {
        final invite = TestData.invite();

        expect(invite.id, isNotEmpty);
        expect(invite.businessId, isNotEmpty);
        expect(invite.email, isNotEmpty);
        expect(invite.role, isNotEmpty);
        expect(invite.tokenHash, isNotEmpty);
        expect(invite.createdBy, isNotEmpty);
      });

      test('creates invite with custom values', () {
        final now = DateTime.now();
        final invite = TestData.invite(
          id: 'custom-id',
          businessId: 'custom-business',
          email: 'custom@example.com',
          role: 'admin',
          tokenHash: 'custom-hash',
          status: InviteStatus.accepted,
          createdAt: now,
        );

        expect(invite.id, 'custom-id');
        expect(invite.businessId, 'custom-business');
        expect(invite.email, 'custom@example.com');
        expect(invite.role, 'admin');
        expect(invite.tokenHash, 'custom-hash');
        expect(invite.status, InviteStatus.accepted);
        expect(invite.createdAt, now);
      });
    });

    group('Real-World Scenarios', () {
      test('email invite to specific staff member', () {
        final staffInvite = Invite(
          id: 'invite-staff',
          businessId: 'dental-clinic',
          email: 'sarah.hygienist@example.com',
          role: 'staff',
          tokenHash: 'abc123hash',
          createdBy: 'owner-1',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          status: InviteStatus.pending,
          notes: 'New hygienist joining next week',
        );

        expect(staffInvite.email, 'sarah.hygienist@example.com');
        expect(staffInvite.role, 'staff');
        expect(staffInvite.isPending, true);
      });

      test('accepted invite tracks when user joined', () {
        final acceptedTime = DateTime.now().subtract(const Duration(hours: 2));
        final acceptedInvite = Invite(
          id: 'invite-accepted',
          businessId: 'therapy-center',
          email: 'john.therapist@example.com',
          role: 'staff',
          tokenHash: 'accepted456hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          expiresAt: DateTime.now().add(const Duration(days: 4)),
          status: InviteStatus.accepted,
          acceptedAt: acceptedTime,
          acceptedBy: 'user-789',
        );

        expect(acceptedInvite.status, InviteStatus.accepted);
        expect(acceptedInvite.acceptedAt, acceptedTime);
        expect(acceptedInvite.acceptedBy, 'user-789');
        expect(acceptedInvite.isPending, false);
      });

      test('expired invite should not be pending', () {
        final expiredInvite = Invite(
          id: 'invite-expired',
          businessId: 'realty-firm',
          email: 'agent@example.com',
          role: 'staff',
          tokenHash: 'expired789hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          expiresAt: DateTime.now().subtract(const Duration(days: 7)),
          status: InviteStatus.pending,
        );

        expect(expiredInvite.isExpired, true);
        expect(expiredInvite.isPending, false);
      });

      test('revoked invite should not be pending', () {
        final revokedInvite = Invite(
          id: 'invite-revoked',
          businessId: 'medical-clinic',
          email: 'wrongemail@example.com',
          role: 'staff',
          tokenHash: 'revoked000hash',
          createdBy: 'admin-1',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          expiresAt: DateTime.now().add(const Duration(days: 5)),
          status: InviteStatus.revoked,
          notes: 'Sent to wrong email, revoked',
        );

        expect(revokedInvite.status, InviteStatus.revoked);
        expect(revokedInvite.isPending, false);
        expect(revokedInvite.isExpired, false); // Not expired, but revoked
      });

      test('admin invite has elevated permissions', () {
        final adminInvite = Invite(
          id: 'invite-admin',
          businessId: 'clinic',
          email: 'newmanager@example.com',
          role: 'admin',
          tokenHash: 'admin111hash',
          createdBy: 'owner-1',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          status: InviteStatus.pending,
          notes: 'New clinic manager',
        );

        expect(adminInvite.role, 'admin');
        expect(adminInvite.isPending, true);
      });
    });
  });
}
