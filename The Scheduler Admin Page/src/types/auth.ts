export const CANONICAL_USER_ROLES = [
  'owner',
  'admin',
  'manager',
  'staff',
  'sales',
  'provider',
  'frontDesk',
  'client',
] as const;

export type UserRole = (typeof CANONICAL_USER_ROLES)[number];

export const LEGACY_ROLE_MAP = {
  assistant: 'frontDesk',
  sales_rep: 'sales',
  marketing: 'sales',
  user: 'staff',
} as const satisfies Record<string, UserRole>;

export type LegacyUserRole = keyof typeof LEGACY_ROLE_MAP;
export type AnyUserRole = UserRole | LegacyUserRole;

export const INVITABLE_USER_ROLES = [
  'admin',
  'manager',
  'staff',
  'sales',
  'provider',
  'frontDesk',
] as const;

export type InvitableUserRole = (typeof INVITABLE_USER_ROLES)[number];

export const ROLE_PRIORITY: Record<UserRole, number> = {
  client: 0,
  frontDesk: 1,
  provider: 1,
  sales: 1,
  staff: 1,
  manager: 2,
  admin: 3,
  owner: 4,
};

export type RoleRequirement = UserRole | UserRole[];

export function normalizeUserRole(role: string | null | undefined): UserRole | undefined {
  if (!role) return undefined;
  const trimmed = role.trim();
  if (!trimmed) return undefined;
  if ((CANONICAL_USER_ROLES as readonly string[]).includes(trimmed)) {
    return trimmed as UserRole;
  }
  return LEGACY_ROLE_MAP[trimmed as LegacyUserRole];
}

export function toInvitableUserRole(
  role: string | null | undefined,
): InvitableUserRole | undefined {
  const normalized = normalizeUserRole(role);
  if (!normalized) return undefined;
  return (INVITABLE_USER_ROLES as readonly string[]).includes(normalized)
    ? (normalized as InvitableUserRole)
    : undefined;
}

export function hasRequiredRole(userRole: UserRole, required: RoleRequirement): boolean {
  const requiredRoles = Array.isArray(required) ? required : [required];
  return requiredRoles.some((role) => ROLE_PRIORITY[userRole] >= ROLE_PRIORITY[role]);
}

export type AppUser = {
  uid: string;
  email: string | null;
  displayName: string | null;
  role: UserRole;
  businessId: string;
  providerId?: string;
  clientId?: string;
  isSuperAdmin?: boolean; // From Firebase custom claim - grants cross-tenant ops access
};

import type { MultiFactorResolver } from 'firebase/auth';

export type PendingUser = {
  uid: string;
  email: string | null;
  displayName: string | null;
  emailVerified: boolean;
};

export type AuthState =
  | { status: 'loading' }
  | { status: 'signed_out' }
  | { status: 'signed_in'; user: AppUser }
  | { status: 'mfa_required'; step: 'enroll'; user: AppUser }
  | { status: 'mfa_required'; step: 'challenge'; resolver: MultiFactorResolver; email: string }
  | { status: 'pending_verification'; user: PendingUser }
  | { status: 'pending_profile'; user: PendingUser }
  | { status: 'error'; error: string };
