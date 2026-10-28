/**
 * Token Encryption Service Tests
 * Verifies AES-256-GCM encryption for OAuth tokens
 *
 * Tests cover:
 * - Encrypt/decrypt round-trip
 * - Different token lengths
 * - Error handling
 * - Key rotation
 * - Tamper detection
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import crypto from 'crypto';
import {
  TokenEncryptionService,
  getTokenEncryptionService,
  resetTokenEncryptionService,
} from '../token-encryption-service';

// Generate a valid test encryption key
const TEST_KEY = crypto.randomBytes(32).toString('hex');

describe('TokenEncryptionService', () => {
  let service: TokenEncryptionService;
  const originalEnv = process.env;

  beforeEach(() => {
    // Reset singleton
    resetTokenEncryptionService();
    // Set test encryption key
    process.env = { ...originalEnv, TOKEN_ENCRYPTION_KEY: TEST_KEY };
    service = new TokenEncryptionService();
  });

  afterEach(() => {
    process.env = originalEnv;
    resetTokenEncryptionService();
    vi.restoreAllMocks();
  });

  describe('initialization', () => {
    it('initializes with valid environment key', async () => {
      await expect(service.initialize()).resolves.not.toThrow();
    });

    it('throws if TOKEN_ENCRYPTION_KEY is missing', async () => {
      delete process.env.TOKEN_ENCRYPTION_KEY;
      delete process.env.GOOGLE_CLOUD_KMS_KEY_NAME;
      const newService = new TokenEncryptionService();

      await expect(newService.initialize()).rejects.toThrow(
        'TOKEN_ENCRYPTION_KEY environment variable is required'
      );
    });

    it('throws if TOKEN_ENCRYPTION_KEY has invalid format', async () => {
      process.env.TOKEN_ENCRYPTION_KEY = 'not-valid-hex';
      const newService = new TokenEncryptionService();

      await expect(newService.initialize()).rejects.toThrow(
        'TOKEN_ENCRYPTION_KEY must be 64 hex characters'
      );
    });

    it('throws if TOKEN_ENCRYPTION_KEY is wrong length', async () => {
      process.env.TOKEN_ENCRYPTION_KEY = 'abcd1234'; // Too short
      const newService = new TokenEncryptionService();

      await expect(newService.initialize()).rejects.toThrow(
        'TOKEN_ENCRYPTION_KEY must be 64 hex characters'
      );
    });
  });

  describe('encrypt', () => {
    it('encrypts a token successfully', async () => {
      const token = 'oauth_access_token_12345';
      const encrypted = await service.encrypt(token);

      expect(encrypted).toBeDefined();
      expect(typeof encrypted).toBe('string');
      // Should be valid JSON
      const parsed = JSON.parse(encrypted);
      expect(parsed.algorithm).toBe('aes-256-gcm');
      expect(parsed.iv).toBeDefined();
      expect(parsed.authTag).toBeDefined();
      expect(parsed.ciphertext).toBeDefined();
      expect(parsed.keyVersion).toBe(1);
    });

    it('produces different ciphertext for same plaintext (random IV)', async () => {
      const token = 'same_token';
      const encrypted1 = await service.encrypt(token);
      const encrypted2 = await service.encrypt(token);

      expect(encrypted1).not.toBe(encrypted2);

      // But both decrypt to same value
      const decrypted1 = await service.decrypt(encrypted1);
      const decrypted2 = await service.decrypt(encrypted2);
      expect(decrypted1).toBe(decrypted2);
      expect(decrypted1).toBe(token);
    });

    it('throws on empty plaintext', async () => {
      await expect(service.encrypt('')).rejects.toThrow('Cannot encrypt empty value');
    });

    it('handles long tokens', async () => {
      const longToken = 'x'.repeat(10000);
      const encrypted = await service.encrypt(longToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(longToken);
    });

    it('handles special characters', async () => {
      const specialToken = 'token/with+special=chars&symbols!@#$%^&*()';
      const encrypted = await service.encrypt(specialToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(specialToken);
    });

    it('handles unicode characters', async () => {
      const unicodeToken = 'token_with_émojis_🔐_and_中文';
      const encrypted = await service.encrypt(unicodeToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(unicodeToken);
    });
  });

  describe('decrypt', () => {
    it('decrypts an encrypted token correctly', async () => {
      const original = 'my_secret_oauth_token';
      const encrypted = await service.encrypt(original);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(original);
    });

    it('throws on empty encrypted data', async () => {
      await expect(service.decrypt('')).rejects.toThrow('Cannot decrypt empty value');
    });

    it('throws on invalid JSON', async () => {
      await expect(service.decrypt('not-json')).rejects.toThrow(
        'Invalid encrypted token format'
      );
    });

    it('throws on invalid structure', async () => {
      const invalid = JSON.stringify({ foo: 'bar' });
      await expect(service.decrypt(invalid)).rejects.toThrow(
        'Invalid encrypted token structure'
      );
    });

    it('throws on wrong algorithm', async () => {
      const invalid = JSON.stringify({
        algorithm: 'aes-128-cbc', // Wrong algorithm
        iv: 'test',
        authTag: 'test',
        ciphertext: 'test',
        keyVersion: 1,
      });
      await expect(service.decrypt(invalid)).rejects.toThrow(
        'Invalid encrypted token structure'
      );
    });

    it('throws on tampered ciphertext', async () => {
      const encrypted = await service.encrypt('original_token');
      const parsed = JSON.parse(encrypted);

      // Tamper with ciphertext
      const tamperedCiphertext = Buffer.from(parsed.ciphertext, 'base64');
      tamperedCiphertext[0] = tamperedCiphertext[0] ^ 0xff;
      parsed.ciphertext = tamperedCiphertext.toString('base64');

      await expect(service.decrypt(JSON.stringify(parsed))).rejects.toThrow(
        'Decryption failed'
      );
    });

    it('throws on tampered auth tag', async () => {
      const encrypted = await service.encrypt('original_token');
      const parsed = JSON.parse(encrypted);

      // Tamper with auth tag
      const tamperedTag = Buffer.from(parsed.authTag, 'base64');
      tamperedTag[0] = tamperedTag[0] ^ 0xff;
      parsed.authTag = tamperedTag.toString('base64');

      await expect(service.decrypt(JSON.stringify(parsed))).rejects.toThrow(
        'Decryption failed'
      );
    });

    it('throws on tampered IV', async () => {
      const encrypted = await service.encrypt('original_token');
      const parsed = JSON.parse(encrypted);

      // Tamper with IV
      const tamperedIv = Buffer.from(parsed.iv, 'base64');
      tamperedIv[0] = tamperedIv[0] ^ 0xff;
      parsed.iv = tamperedIv.toString('base64');

      await expect(service.decrypt(JSON.stringify(parsed))).rejects.toThrow(
        'Decryption failed'
      );
    });

    it('throws on invalid IV length', async () => {
      const encrypted = await service.encrypt('original_token');
      const parsed = JSON.parse(encrypted);
      parsed.iv = Buffer.from('short').toString('base64');

      await expect(service.decrypt(JSON.stringify(parsed))).rejects.toThrow(
        'Invalid IV length'
      );
    });

    it('throws on invalid auth tag length', async () => {
      const encrypted = await service.encrypt('original_token');
      const parsed = JSON.parse(encrypted);
      parsed.authTag = Buffer.from('short').toString('base64');

      await expect(service.decrypt(JSON.stringify(parsed))).rejects.toThrow(
        'Invalid auth tag length'
      );
    });
  });

  describe('key rotation', () => {
    it('needsRotation returns false for current version', async () => {
      const encrypted = await service.encrypt('token');
      expect(service.needsRotation(encrypted)).toBe(false);
    });

    it('needsRotation returns false for invalid data', () => {
      expect(service.needsRotation('not-json')).toBe(false);
    });

    it('rotate re-encrypts with current key', async () => {
      const original = 'token_to_rotate';
      const encrypted = await service.encrypt(original);

      const rotated = await service.rotate(encrypted);

      // Should be different encrypted value
      expect(rotated).not.toBe(encrypted);

      // But decrypts to same value
      const decrypted = await service.decrypt(rotated);
      expect(decrypted).toBe(original);
    });
  });

  describe('singleton', () => {
    it('getTokenEncryptionService returns singleton', () => {
      const service1 = getTokenEncryptionService();
      const service2 = getTokenEncryptionService();

      expect(service1).toBe(service2);
    });

    it('resetTokenEncryptionService clears singleton', () => {
      const service1 = getTokenEncryptionService();
      resetTokenEncryptionService();
      const service2 = getTokenEncryptionService();

      expect(service1).not.toBe(service2);
    });
  });

  describe('real-world token scenarios', () => {
    it('encrypts typical OAuth access token', async () => {
      const accessToken =
        'ya29.a0AfH6SMBx...long_google_oauth_token...abcdef123456';
      const encrypted = await service.encrypt(accessToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(accessToken);
    });

    it('encrypts typical OAuth refresh token', async () => {
      const refreshToken = '1//0exampleRefreshToken_with-special.chars';
      const encrypted = await service.encrypt(refreshToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(refreshToken);
    });

    it('encrypts Slack bot token', async () => {
      const slackToken = ['xoxb', 'test-only', crypto.randomBytes(16).toString('hex')].join('-');
      const encrypted = await service.encrypt(slackToken);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(slackToken);
    });

    it('encrypts JWT token', async () => {
      const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
      const payload = Buffer.from(JSON.stringify({ sub: 'test-user' })).toString('base64url');
      const signature = crypto.createHmac('sha256', crypto.randomBytes(32))
        .update(`${header}.${payload}`).digest('base64url');
      const jwt = `${header}.${payload}.${signature}`;
      const encrypted = await service.encrypt(jwt);
      const decrypted = await service.decrypt(encrypted);

      expect(decrypted).toBe(jwt);
    });
  });

  describe('cross-key compatibility', () => {
    it('cannot decrypt with different key', async () => {
      const encrypted = await service.encrypt('secret_token');

      // Reset and use different key
      resetTokenEncryptionService();
      const newKey = crypto.randomBytes(32).toString('hex');
      process.env.TOKEN_ENCRYPTION_KEY = newKey;
      const newService = new TokenEncryptionService();

      await expect(newService.decrypt(encrypted)).rejects.toThrow(
        'Decryption failed'
      );
    });
  });
});
