import { describe, expect, it } from 'vitest';

import { isBillingActive } from './BillingGuard';

describe('isBillingActive', () => {
  it('returns false for undefined or incomplete statuses', () => {
    expect(isBillingActive()).toBe(false);
    expect(isBillingActive('incomplete')).toBe(false);
    expect(isBillingActive('canceled')).toBe(false);
  });

  it('returns true for active-like statuses', () => {
    expect(isBillingActive('active')).toBe(true);
    expect(isBillingActive('trialing')).toBe(true);
    expect(isBillingActive('past_due')).toBe(true);
  });
});
