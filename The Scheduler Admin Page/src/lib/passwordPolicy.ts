/**
 * Password Policy - HIPAA-compliant password requirements
 *
 * Requirements:
 * - Minimum 12 characters (HIPAA recommendation)
 * - At least one uppercase letter
 * - At least one lowercase letter
 * - At least one number
 * - At least one special character
 */

export interface PasswordRule {
  id: string;
  label: string;
  test: (password: string) => boolean;
}

/**
 * Password validation rules displayed to users
 */
export const PASSWORD_RULES: PasswordRule[] = [
  {
    id: 'length',
    label: 'At least 12 characters',
    test: (password: string) => password.length >= 12,
  },
  {
    id: 'uppercase',
    label: 'At least one uppercase letter (A-Z)',
    test: (password: string) => /[A-Z]/.test(password),
  },
  {
    id: 'lowercase',
    label: 'At least one lowercase letter (a-z)',
    test: (password: string) => /[a-z]/.test(password),
  },
  {
    id: 'number',
    label: 'At least one number (0-9)',
    test: (password: string) => /[0-9]/.test(password),
  },
  {
    id: 'special',
    label: 'At least one special character (!@#$%^&*)',
    test: (password: string) => /[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?`~]/.test(password),
  },
];

/**
 * Validate a password against all rules
 * @returns Array of error messages for failed rules (empty if valid)
 */
export function validatePassword(password: string): string[] {
  const errors: string[] = [];

  for (const rule of PASSWORD_RULES) {
    if (!rule.test(password)) {
      errors.push(rule.label);
    }
  }

  return errors;
}

/**
 * Calculate password strength as a value from 0 to 1
 * Based on rule compliance + length bonus + entropy estimation
 */
export function getPasswordStrength(password: string): number {
  if (!password) return 0;

  let score = 0;
  const maxScore = 100;

  // Rule compliance (60 points max)
  const passedRules = PASSWORD_RULES.filter(rule => rule.test(password)).length;
  score += (passedRules / PASSWORD_RULES.length) * 60;

  // Length bonus (20 points max)
  // 12 chars = 0, 16 chars = 10, 20+ chars = 20
  const lengthBonus = Math.min(20, Math.max(0, (password.length - 12) * 2.5));
  score += lengthBonus;

  // Character variety bonus (20 points max)
  const charTypes = [
    /[a-z]/.test(password),
    /[A-Z]/.test(password),
    /[0-9]/.test(password),
    /[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?`~]/.test(password),
  ].filter(Boolean).length;
  score += charTypes * 5;

  return Math.min(1, score / maxScore);
}

/**
 * Get a human-readable label for the password strength
 */
export function getStrengthLabel(strength: number): string {
  if (strength >= 0.85) return 'Strong';
  if (strength >= 0.7) return 'Good';
  if (strength >= 0.55) return 'Fair';
  if (strength >= 0.3) return 'Weak';
  return 'Very weak';
}

/**
 * Check if a password meets all requirements
 */
export function isPasswordValid(password: string): boolean {
  return validatePassword(password).length === 0;
}
