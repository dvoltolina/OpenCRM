import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/services/file_storage_service.dart';
import 'package:the_scheduler/data/models/file_attachment.dart';
import 'package:the_scheduler/data/models/security_context.dart';

void main() {
  group('FileStorageService upload validation', () {
    late FileStorageService service;
    late SecurityContext adminContext;
    String? capturedPath;
    SettableMetadata? capturedMetadata;

    setUp(() {
      adminContext = SecurityContext(
        userId: 'user-1',
        businessId: 'biz-1',
        role: UserRole.admin,
        userFullName: 'Admin User',
      );
      capturedPath = null;
      capturedMetadata = null;
      service = FileStorageService(
        uploadHandler: (
          path,
          bytes,
          metadata,
          onProgress,
        ) async {
          capturedPath = path;
          capturedMetadata = metadata;
          onProgress?.call(1.0);
          return 'https://mock.storage/object';
        },
      );
    });

    test('rejects files larger than the allowed 10MB limit', () async {
      final oversized = PlatformFile(
        name: 'too-big.pdf',
        size: 10 * 1024 * 1024 + 1,
        bytes: Uint8List(1),
      );

      expect(
        () => service.uploadClientFile(
          context: adminContext,
          file: oversized,
          clientId: 'client-1',
        ),
        throwsA(
          predicate<Exception>(
            (ex) => ex.toString().contains('File too large'),
          ),
        ),
      );
    });

    test('rejects unsupported file extensions', () async {
      final unsupported = PlatformFile(
        name: 'script.exe',
        size: 1024,
        bytes: Uint8List(1),
      );

      expect(
        () => service.uploadClientFile(
          context: adminContext,
          file: unsupported,
          clientId: 'client-1',
        ),
        throwsA(
          predicate<Exception>(
            (ex) => ex.toString().contains('Unsupported file type'),
          ),
        ),
      );
    });

    test('uploads allowed file and stores metadata', () async {
      final file = PlatformFile(
        name: 'intake.pdf',
        size: 2048,
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      final attachment = await service.uploadClientFile(
        context: adminContext,
        file: file,
        clientId: 'client-42',
        appointmentId: 'appt-9',
        category: FileCategory.intake,
        accessLevel: FileAccessLevel.clientOnly,
        isSensitive: true,
        extraMetadata: const {'foo': 'bar'},
      );

      expect(attachment.name, 'intake.pdf');
      expect(attachment.downloadUrl, 'https://mock.storage/object');
      expect(attachment.category, FileCategory.intake);
      expect(attachment.accessLevel, FileAccessLevel.clientOnly);
      expect(attachment.appointmentId, 'appt-9');
      expect(capturedPath, contains('client-42/files'));
      expect(capturedMetadata?.contentType, 'application/pdf');
      expect(capturedMetadata?.customMetadata?['accessLevel'], 'clientOnly');
      expect(capturedMetadata?.customMetadata?['category'], 'intake');
      expect(capturedMetadata?.customMetadata?['foo'], 'bar');
    });
  });
}

