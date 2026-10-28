import { describe, expect, it } from 'vitest';

import { getPasswordStrength, getStrengthLabel, validatePassword } from './passwordPolicy';

describe('passwordPolicy', () => {
  it('validates all required rules', () => {
    expect(validatePassword('Short1!')).toContain('At least 12 characters');
    expect(validatePassword('alllowercasepassword!1')).toContain('At least 1 uppercase letter');
    expect(validatePassword('ALLUPPERCASEPASSWORD!1')).toContain('At least 1 lowercase letter');
    expect(validatePassword('NoNumberHere!!')).toContain('At least 1 number');
    expect(validatePassword('NoSpecial1234')).toContain('At least 1 special character');
  });

  it('returns no errors for a compliant password', () => {
    const errors = validatePassword('StrongPassword1!');
    expect(errors).toHaveLength(0);
  });

  it('computes strength buckets', () => {
    const emptyScore = getPasswordStrength('');
    expect(emptyScore).toBe(0);

    const weakScore = getPasswordStrength('Weakpass12');
    expect(getStrengthLabel(weakScore)).toBe('Weak');

    const goodScore = getPasswordStrength('GoodPassword12!');
    expect(getStrengthLabel(goodScore)).toBe('Good');

    const strongScore = getPasswordStrength('VeryStrongPassword123!');
    expect(getStrengthLabel(strongScore)).toBe('Strong');
  });
});
