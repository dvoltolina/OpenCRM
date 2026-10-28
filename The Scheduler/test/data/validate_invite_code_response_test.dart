import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/repositories/workspace_repository.dart';

void main() {
  test('ValidateInviteCodeResponse maps HIPAA/MFA flags', () {
    final response = ValidateInviteCodeResponse.fromMap({
      'valid': true,
      'businessId': 'biz123',
      'businessName': 'Clinic',
      'requiresHipaaCompliance': true,
      'mfaEnabled': true,
    });

    expect(response.valid, isTrue);
    expect(response.businessId, 'biz123');
    expect(response.businessName, 'Clinic');
    expect(response.requiresHipaaCompliance, isTrue);
    expect(response.mfaEnabled, isTrue);
  });

  test('ValidateInviteCodeResponse defaults to false when flags missing', () {
    final response = ValidateInviteCodeResponse.fromMap({
      'valid': false,
    });

    expect(response.requiresHipaaCompliance, isFalse);
    expect(response.mfaEnabled, isFalse);
  });
}
