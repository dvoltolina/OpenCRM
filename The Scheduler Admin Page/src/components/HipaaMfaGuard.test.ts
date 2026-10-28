import { describe, expect, it } from 'vitest';

import { shouldRedirectToMfa } from './HipaaMfaGuard';

describe('shouldRedirectToMfa', () => {
  it('redirects to /mfa when required, no factors, and not already on MFA route', () => {
    expect(
      shouldRedirectToMfa({
        requiresMfa: true,
        enrolledFactors: 0,
        onMfaRoute: false,
      }),
    ).toBe('/mfa');
  });

  it('allows navigation when factors are enrolled', () => {
    expect(
      shouldRedirectToMfa({
        requiresMfa: true,
        enrolledFactors: 1,
        onMfaRoute: false,
      }),
    ).toBeNull();
  });

  it('does not redirect when MFA not required', () => {
    expect(
      shouldRedirectToMfa({
        requiresMfa: false,
        enrolledFactors: 0,
        onMfaRoute: false,
      }),
    ).toBeNull();
  });

  it('does not redirect if already on MFA route', () => {
    expect(
      shouldRedirectToMfa({
        requiresMfa: true,
        enrolledFactors: 0,
        onMfaRoute: true,
      }),
    ).toBeNull();
  });
});
