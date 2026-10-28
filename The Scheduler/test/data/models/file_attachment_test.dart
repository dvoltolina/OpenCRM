import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/file_attachment.dart';
import 'package:the_scheduler/data/models/security_context.dart';

void main() {
  group('FileAttachment security', () {
    test('verifyFileAccess enforces business isolation', () {
      final context = SecurityContext(
        userId: 'user-1',
        businessId: 'biz-a',
        role: UserRole.admin,
      );

      expect(
        () => verifyFileAccess(context, 'biz-b'),
        throwsA(isA<SecurityException>()),
      );
    });

    test('fromJson defaults unknown access/category to safest values', () {
      final attachment = FileAttachment.fromJson({
        'id': 'file-1',
        'businessId': 'biz-a',
        'name': 'document.xyz',
        'contentType': 'application/octet-stream',
        'sizeBytes': 1024,
        'storagePath': 'businesses/biz-a/clients/client-1/files/file-1',
        'uploadedAt': DateTime.now().toIso8601String(),
        'uploaderId': 'user-1',
        'accessLevel': 'super-public',
        'category': 'unknown',
      });

      expect(attachment.accessLevel, FileAccessLevel.clientOnly);
      expect(attachment.category, FileCategory.general);
      expect(attachment.isSensitive, isFalse);
    });

    test('verifyFileAccess allows same-business staff access', () {
      final context = SecurityContext(
        userId: 'staff-1',
        businessId: 'biz-a',
        role: UserRole.staff,
      );

      expect(
        () => verifyFileAccess(context, 'biz-a'),
        returnsNormally,
      );
    });

    test('copyWith updates access level and sensitivity flags', () {
      final attachment = FileAttachment(
        id: 'file-1',
        businessId: 'biz-a',
        name: 'chart.pdf',
        contentType: 'application/pdf',
        sizeBytes: 1024,
        storagePath: 'path/file-1',
        uploadedAt: DateTime.now(),
        uploaderId: 'user-1',
      );

      final secured = attachment.copyWith(
        accessLevel: FileAccessLevel.staffOnly,
        isSensitive: true,
        metadata: {'requiresBAA': true},
      );

      expect(secured.accessLevel, FileAccessLevel.staffOnly);
      expect(secured.isSensitive, isTrue);
      expect(secured.metadata['requiresBAA'], isTrue);
    });
  });
}
