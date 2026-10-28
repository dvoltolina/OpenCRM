import { describe, it, expect } from 'vitest';
import { __test__ as calendarTest } from './calendar';

describe('calendar functions state validation', () => {
  const validState = calendarTest.decodeState(
    Buffer.from(
      JSON.stringify({
        userId: 'user-1',
        businessId: 'biz-1',
        nonce: 'nonce-123',
        issuedAt: Date.now(),
      }),
      'utf-8'
    ).toString('base64')
  );

  it('validates matching state', () => {
    expect(() =>
      calendarTest.validateOAuthState(validState, 'biz-1', 'user-1')
    ).not.toThrow();
  });

  it('rejects mismatched user or business', () => {
    expect(() => calendarTest.validateOAuthState(validState, 'biz-2', 'user-1')).toThrow();
    expect(() => calendarTest.validateOAuthState(validState, 'biz-1', 'user-2')).toThrow();
  });

  it('rejects expired state', () => {
    const expiredState = { ...validState, issuedAt: Date.now() - 20 * 60 * 1000 };
    expect(() => calendarTest.validateOAuthState(expiredState, 'biz-1', 'user-1')).toThrow();
  });

  it('encrypts tokens deterministically in shape', () => {
    const token = 'secret-token';
    const encrypted = calendarTest.encryptToken(token);
    expect(typeof encrypted).toBe('string');
    expect(encrypted.length).toBeGreaterThan(token.length);
  });

  it('sanitizes errors to avoid leaking identifiers', () => {
    const raw = 'Unauthorized for john@example.com token super-secret-12345678901234567890';
    const sanitized = calendarTest.sanitizeError(raw);
    expect(sanitized).not.toContain('john@example.com');
    expect(sanitized.length).toBeLessThanOrEqual(300);
  });
});
