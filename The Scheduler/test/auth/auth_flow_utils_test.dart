import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/repositories/auth_repository.dart';
import 'package:the_scheduler/modules/auth/presentation/utils/auth_flow_utils.dart';

class _RecordingAuthRepository extends Fake implements AuthRepository {
  bool? lastFlag;

  @override
  Future<void> configurePersistence({required bool requiresHipaa}) async {
    lastFlag = requiresHipaa;
  }
}

class _ThrowingAuthRepository extends Fake implements AuthRepository {
  @override
  Future<void> configurePersistence({required bool requiresHipaa}) async {
    throw Exception('fail');
  }
}

void main() {
  group('applyBusinessPersistence', () {
    test('calls configurePersistence with HIPAA flag', () async {
      final repo = _RecordingAuthRepository();

      await applyBusinessPersistence(
        authRepository: repo,
        requiresHipaa: true,
      );

      expect(repo.lastFlag, isTrue);
    });

    test('swallows exceptions from configurePersistence', () async {
      final repo = _ThrowingAuthRepository();

      // Should not throw
      await applyBusinessPersistence(
        authRepository: repo,
        requiresHipaa: false,
      );
    });
  });

  group('shouldRouteToMfa', () {
    test('requires both mfaEnabled and admin role', () {
      expect(shouldRouteToMfa(mfaEnabled: true, isAdmin: true), isTrue);
      expect(shouldRouteToMfa(mfaEnabled: true, isAdmin: false), isFalse);
      expect(shouldRouteToMfa(mfaEnabled: false, isAdmin: true), isFalse);
      expect(shouldRouteToMfa(mfaEnabled: false, isAdmin: false), isFalse);
    });
  });
}
