export const CANONICAL_USER_ROLES = [
  "owner",
  "admin",
  "manager",
  "staff",
  "sales",
  "provider",
  "frontDesk",
  "client",
] as const;

export type CanonicalUserRole = (typeof CANONICAL_USER_ROLES)[number];

export const LEGACY_ROLE_MAP = {
  assistant: "frontDesk",
  sales_rep: "sales",
  marketing: "sales",
  user: "staff",
} as const;

export type LegacyUserRole = keyof typeof LEGACY_ROLE_MAP;
export type UserRole = CanonicalUserRole | LegacyUserRole;

export const CRM_ALLOWED_ROLES = [
  "owner",
  "admin",
  "manager",
  "staff",
  "sales",
] as const satisfies readonly CanonicalUserRole[];

export const INTERNAL_BUSINESS_ROLES = [
  "owner",
  "admin",
  "manager",
  "staff",
  "sales",
  "provider",
  "frontDesk",
] as const satisfies readonly CanonicalUserRole[];

export const INVITABLE_USER_ROLES = [
  "admin",
  "manager",
  "staff",
  "sales",
  "provider",
  "frontDesk",
] as const satisfies readonly CanonicalUserRole[];

export type InvitableUserRole = (typeof INVITABLE_USER_ROLES)[number];

export function normalizeUserRole(role: unknown): CanonicalUserRole | undefined {
  if (typeof role !== "string") {
    return undefined;
  }

  const trimmed = role.trim();
  if (!trimmed) {
    return undefined;
  }

  if (CANONICAL_USER_ROLES.includes(trimmed as CanonicalUserRole)) {
    return trimmed as CanonicalUserRole;
  }

  return LEGACY_ROLE_MAP[trimmed as LegacyUserRole];
}

export function isAdminRole(role: unknown): boolean {
  const normalized = normalizeUserRole(role);
  return normalized === "owner" || normalized === "admin";
}

export function isCrmOperatorRole(role: unknown): boolean {
  const normalized = normalizeUserRole(role);
  return normalized !== undefined &&
    (CRM_ALLOWED_ROLES as readonly string[]).includes(normalized);
}

export function isInternalBusinessRole(role: unknown): boolean {
  const normalized = normalizeUserRole(role);
  return normalized !== undefined &&
    (INTERNAL_BUSINESS_ROLES as readonly string[]).includes(normalized);
}

export function isInvitableUserRole(role: unknown): role is InvitableUserRole {
  const normalized = normalizeUserRole(role);
  return normalized !== undefined &&
    (INVITABLE_USER_ROLES as readonly string[]).includes(normalized);
}

export function normalizeInvitableUserRole(role: unknown): InvitableUserRole | undefined {
  const normalized = normalizeUserRole(role);
  if (
    normalized !== undefined &&
    (INVITABLE_USER_ROLES as readonly string[]).includes(normalized)
  ) {
    return normalized as InvitableUserRole;
  }

  return undefined;
}

export function isProviderScopedRole(role: unknown): boolean {
  const normalized = normalizeUserRole(role);
  return normalized === "staff" || normalized === "provider";
}
