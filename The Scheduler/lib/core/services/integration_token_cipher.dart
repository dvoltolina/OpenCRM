import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// Utility responsible for encrypting/decrypting OAuth tokens before they touch Firestore.
class IntegrationTokenCipher {
  IntegrationTokenCipher(String base64Key)
      : assert(base64Key.isNotEmpty, 'Encryption key cannot be empty'),
        _key = Key(_normalizeKey(base64Key));

  final Key _key;

  static Uint8List _normalizeKey(String base64Key) {
    final decoded = base64.decode(base64Key);
    if (decoded.length >= 32) {
      return Uint8List.fromList(decoded.sublist(0, 32));
    }
    // Pad with zeros if the provided key is short (developer mode only).
    final buffer = Uint8List(32);
    buffer.setRange(0, decoded.length, decoded);
    return buffer;
  }

  /// Encrypt plain text using AES-256 CBC and returns iv:ciphertext (both base64).
  String encrypt(String plaintext) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final ivBase64 = base64.encode(iv.bytes);
    return '$ivBase64:${encrypted.base64}';
  }

  /// Decrypt payloads generated via [encrypt].
  String decrypt(String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload format.');
    }

    final iv = IV(base64.decode(parts[0]));
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}

