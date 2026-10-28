import { beforeEach, describe, expect, it } from 'vitest';
import { __test__ as emailTest } from './email';

describe('email functions helpers', () => {
  beforeEach(() => {
    process.env.ENABLE_EMAIL_INTEGRATION = 'true';
  });

  it('validates oauth state and rejects mismatches', () => {
    const payload = {
      userId: 'user-1',
      businessId: 'biz-1',
      nonce: 'nonce-123',
      issuedAt: Date.now(),
    };
    const encoded = Buffer.from(JSON.stringify(payload), 'utf8').toString('base64');
    const decoded = emailTest.decodeState(encoded);

    expect(() => emailTest.validateOAuthState(decoded, 'biz-1', 'user-1')).not.toThrow();
    expect(() => emailTest.validateOAuthState(decoded, 'biz-2', 'user-1')).toThrow();
    expect(() => emailTest.validateOAuthState(decoded, 'biz-1', 'user-2')).toThrow();
  });

  it('encrypts and decrypts tokens safely', () => {
    const encrypted = emailTest.encryptToken('super-secret-token');
    expect(encrypted).not.toContain('super-secret-token');
    expect(emailTest.decryptToken(encrypted)).toBe('super-secret-token');
  });

  it('sanitizes errors and strips emails and token-like strings', () => {
    const raw = 'Account john@example.com failed with token abcdefghijklmnopqrstuvwxyz123456';
    const sanitized = emailTest.sanitizeError(raw);

    expect(sanitized).not.toContain('john@example.com');
    expect(sanitized).not.toContain('abcdefghijklmnopqrstuvwxyz123456');
  });

  it('accepts only http and https redirect URLs', () => {
    expect(emailTest.safeRedirect('https://example.com/path?x=1')).toBe('https://example.com/path?x=1');
    expect(emailTest.safeRedirect('http://localhost:5173/callback')).toBe('http://localhost:5173/callback');
    expect(emailTest.safeRedirect('javascript:alert(1)')).toBeNull();
    expect(emailTest.safeRedirect('data:text/plain,hello')).toBeNull();
  });

  it('stores tracked URLs without query strings', () => {
    expect(emailTest.sanitizeTrackedUrl('https://example.com/path?q=secret#hash')).toBe(
      'https://example.com/path'
    );
  });

  it('parses and updates folder cursors without dropping state', () => {
    const cursor = emailTest.updateSyncCursor(undefined, 'inbox', 'cursor-1');
    const second = emailTest.updateSyncCursor(cursor, 'sent', 'cursor-2');
    expect(emailTest.parseSyncCursor(second)).toEqual({
      inbox: 'cursor-1',
      sent: 'cursor-2',
    });
  });

  it('hashes IP addresses and builds deterministic ids', () => {
    expect(emailTest.hashIp('127.0.0.1')).toMatch(/^[a-f0-9]{64}$/);
    expect(emailTest.buildAccountId('user', 'gmail', 'user@example.com')).toHaveLength(32);
    expect(emailTest.buildThreadId('acct', 'thread')).toHaveLength(32);
    expect(emailTest.buildSyncedMessageId('acct', 'provider-message')).toHaveLength(32);
  });

  it('enforces in-memory rate limits', () => {
    const first = emailTest.checkRateLimit('email:test', 1, 60_000);
    const second = emailTest.checkRateLimit('email:test', 1, 60_000);

    expect(first.allowed).toBe(true);
    expect(second.allowed).toBe(false);
    expect(second.retryAfterMs).toBeGreaterThan(0);
  });
});
