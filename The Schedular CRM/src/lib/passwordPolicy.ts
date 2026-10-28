type PasswordRule = {
  id: 'length' | 'uppercase' | 'lowercase' | 'number' | 'special';
  label: string;
  test: (value: string) => boolean;
};

export const PASSWORD_RULES: PasswordRule[] = [
  {
    id: 'length',
    label: 'At least 12 characters',
    test: (value: string) => value.length >= 12,
  },
  {
    id: 'uppercase',
    label: 'At least 1 uppercase letter',
    test: (value: string) => /[A-Z]/.test(value),
  },
  {
    id: 'lowercase',
    label: 'At least 1 lowercase letter',
    test: (value: string) => /[a-z]/.test(value),
  },
  {
    id: 'number',
    label: 'At least 1 number',
    test: (value: string) => /[0-9]/.test(value),
  },
  {
    id: 'special',
    label: 'At least 1 special character',
    test: (value: string) => /[^A-Za-z0-9]/.test(value),
  },
];

export function validatePassword(password: string): string[] {
  return PASSWORD_RULES.filter((rule) => !rule.test(password)).map((rule) => rule.label);
}

export function getPasswordStrength(password: string): number {
  if (!password) return 0;
  const satisfied = PASSWORD_RULES.reduce((count, rule) => count + Number(rule.test(password)), 0);
  const extraLength = Math.min(Math.max(password.length - 12, 0), 8); // cap bonus
  const lengthBonus = extraLength / 8; // 0-1 range
  const baseScore = satisfied / PASSWORD_RULES.length;
  const score = Math.min(1, baseScore * 0.7 + lengthBonus * 0.3);
  return Number(score.toFixed(2));
}

export function getStrengthLabel(score: number): string {
  if (score >= 0.85) return 'Strong';
  if (score >= 0.55) return 'Good';
  if (score > 0) return 'Weak';
  return 'Empty';
}
