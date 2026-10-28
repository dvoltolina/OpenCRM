/**
 * Security Context Utilities
 * Helper functions for creating SecurityContext from AuthContext
 *
 * Agent CRM-40 Implementation
 * HIPAA Compliance: Ensures all repository operations have proper context
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { CRMUser, Visibility } from '../types/models';

let defaultTeamIds: string[] = [];
let defaultManagedTeamIds: string[] = [];
const DEFAULT_VISIBILITY: Visibility = 'team';

export function setDefaultTeamIds(teamIds: string[]): void {
  defaultTeamIds = sanitizeTeamIds(teamIds);
}

export function getDefaultTeamIds(): string[] {
  return defaultTeamIds;
}

export function setDefaultManagedTeamIds(teamIds: string[]): void {
  defaultManagedTeamIds = sanitizeTeamIds(teamIds);
}

export function getDefaultManagedTeamIds(): string[] {
  return defaultManagedTeamIds;
}

/**
 * Normalize and de-duplicate team IDs.
 */
export function sanitizeTeamIds(teamIds?: string[] | null): string[] {
  if (!Array.isArray(teamIds)) return [];
  const sanitized = teamIds
    .map((id) => id?.trim())
    .filter((id): id is string => Boolean(id));
  return Array.from(new Set(sanitized));
}

/**
 * Resolve team memberships for a user, falling back to defaults when none are set.
 */
export function getUserTeamIds(crmUser?: CRMUser | null, fallback?: string[]): string[] {
  const resolved = sanitizeTeamIds(crmUser?.teamIds);
  const fallbackTeams = sanitizeTeamIds(fallback ?? defaultTeamIds);
  return resolved.length ? resolved : fallbackTeams;
}

/**
 * Resolve managed team memberships for manager hierarchy.
 */
export function getUserManagedTeamIds(crmUser?: CRMUser | null, fallback?: string[]): string[] {
  const resolved = sanitizeTeamIds(crmUser?.managedTeamIds);
  const fallbackTeams = sanitizeTeamIds(fallback ?? defaultManagedTeamIds);
  return resolved.length ? resolved : fallbackTeams;
}

export interface HierarchyScope {
  teamIds: string[];
  managedTeamIds: string[];
  allTeamIds: string[];
  isManager: boolean;
  isOrgPrivileged: boolean;
  managerId?: string;
}

/**
  * Resolve hierarchy scope (teams + role privilege) from CRM user.
  */
export function getHierarchyScope(crmUser?: CRMUser | null): HierarchyScope {
  const teamIds = getUserTeamIds(crmUser);
  const managedTeamIds = getUserManagedTeamIds(crmUser);
  const allTeamIds = resolveTeamIds([...teamIds, ...managedTeamIds]);
  const role = (crmUser?.role || '').toLowerCase();

  return {
    teamIds,
    managedTeamIds,
    allTeamIds,
    isManager: role === 'manager',
    isOrgPrivileged: role === 'owner' || role === 'admin',
    managerId: crmUser?.managerId,
  };
}

/**
 * Resolve team memberships with optional override/fallback arrays.
 */
export function resolveTeamIds(
  explicitTeamIds?: string[],
  fallbackTeamIds: string[] = defaultTeamIds
): string[] {
  const explicit = sanitizeTeamIds(explicitTeamIds);
  if (explicit.length) return explicit;
  return sanitizeTeamIds(fallbackTeamIds);
}

/**
 * Create a SecurityContext from CRMUser
 *
 * @param crmUser - Authenticated CRM user from AuthContext
 * @returns SecurityContext for repository operations
 * @throws Error if user is not authenticated or missing required fields
 */
export function createSecurityContext(crmUser: CRMUser | null): SecurityContext {
  if (!crmUser) {
    throw new Error('User not authenticated');
  }

  if (!crmUser.businessId) {
    throw new Error('User missing businessId - multi-tenant isolation required');
  }

  if (!crmUser.id) {
    throw new Error('User missing id');
  }

  setDefaultTeamIds(crmUser.teamIds || []);
  setDefaultManagedTeamIds(crmUser.managedTeamIds || []);

  const teamIds = getUserTeamIds(crmUser);
  const managedTeamIds = getUserManagedTeamIds(crmUser);
  const requiresHipaaCompliance = crmUser.requiresHipaaCompliance === true;
  const auditLoggingEnabled =
    requiresHipaaCompliance || crmUser.auditLoggingEnabled === true;

  return {
    businessId: crmUser.businessId,
    userId: crmUser.id,
    userName: crmUser.displayName || crmUser.email || 'Unknown User',
    userRole: crmUser.role || 'staff',
    teamIds,
    managedTeamIds,
    managerId: crmUser.managerId,
    requiresHipaaCompliance,
    auditLoggingEnabled,
  };
}

/**
 * Create a SecurityContext from discrete parameters (for tests and hooks that only have primitives)
 */
export function createSecurityContextFromParams(
  businessId: string,
  userId: string,
  userName: string,
  userRole: string,
  teamIds: string[] = [],
  managedTeamIds: string[] = [],
  managerId?: string,
  options?: {
    requiresHipaaCompliance?: boolean;
    auditLoggingEnabled?: boolean;
  }
): SecurityContext {
  const resolvedTeams = resolveTeamIds(teamIds, defaultTeamIds);
  const resolvedManagedTeams = resolveTeamIds(managedTeamIds, defaultManagedTeamIds);
  setDefaultTeamIds(resolvedTeams);
  setDefaultManagedTeamIds(resolvedManagedTeams);
  const requiresHipaaCompliance = options?.requiresHipaaCompliance === true;
  const auditLoggingEnabled =
    requiresHipaaCompliance || options?.auditLoggingEnabled === true;
  return {
    businessId,
    userId,
    userName,
    userRole,
    teamIds: resolvedTeams,
    managedTeamIds: resolvedManagedTeams,
    managerId,
    requiresHipaaCompliance,
    auditLoggingEnabled,
  };
}

/**
 * Build hierarchy scope from a populated SecurityContext (UI/services convenience).
 */
export function getHierarchyScopeFromContext(context: SecurityContext): HierarchyScope {
  const teamIds = sanitizeTeamIds(context.teamIds);
  const managedTeamIds = sanitizeTeamIds(context.managedTeamIds);
  const allTeamIds = resolveTeamIds([...teamIds, ...managedTeamIds]);
  const role = (context.userRole || '').toLowerCase();

  return {
    teamIds,
    managedTeamIds,
    allTeamIds,
    isManager: role === 'manager',
    isOrgPrivileged: role === 'owner' || role === 'admin',
    managerId: context.managerId,
  };
}

export interface ShareableQueryScope {
  ownerId: string;
  teamIds: string[];
  managedTeamIds: string[];
  allTeamIds: string[];
  visibilityValues: Visibility[];
}

export interface AccessibleTeamScope {
  ownerId: string;
  teamIds: string[];
  managedTeamIds: string[];
  allTeamIds: string[];
  isManager: boolean;
  isOrgPrivileged: boolean;
}

export interface ShareableAccessSummary {
  visibility: Visibility;
  isOwner: boolean;
  hasOrgPrivilege: boolean;
  hasManagerAccess: boolean;
  hasTeamAccess: boolean;
  canRead: boolean;
  canWrite: boolean;
  canEdit: boolean; // Alias for canWrite - convenience for UI components
  canDelete: boolean;
  effectiveTeams: string[];
}

/**
 * Helper for building shareable Firestore queries (owner/team/org visibility).
 * Does not execute queries; callers still need to apply OR logic per Firestore constraints.
 */
export function getShareableQueryScope(context: SecurityContext): ShareableQueryScope {
  const hierarchyScope = getHierarchyScopeFromContext(context);

  return {
    ownerId: context.userId,
    teamIds: hierarchyScope.teamIds,
    managedTeamIds: hierarchyScope.managedTeamIds,
    allTeamIds: hierarchyScope.allTeamIds,
    visibilityValues: ['org', DEFAULT_VISIBILITY],
  };
}

/**
 * Resolve accessible teams (direct + managed) for a user, including manager/org flags.
 * Useful for query builders and UI guards that need hierarchy awareness.
 */
export function getAccessibleTeamScope(context: SecurityContext): AccessibleTeamScope {
  const teamIds = sanitizeTeamIds(context.teamIds);
  const managedTeamIds = sanitizeTeamIds(context.managedTeamIds);
  const allTeamIds = resolveTeamIds([...teamIds, ...managedTeamIds]);
  const role = (context.userRole || '').toLowerCase();

  return {
    ownerId: context.userId,
    teamIds,
    managedTeamIds,
    allTeamIds,
    isManager: role === 'manager',
    isOrgPrivileged: role === 'owner' || role === 'admin',
  };
}

/**
 * Validate that a SecurityContext is complete
 * Used to ensure no partial context is passed to repositories
 *
 * @param context - SecurityContext to validate
 * @returns true if valid, throws error otherwise
 */
export function validateSecurityContext(context: SecurityContext): boolean {
  const required: Array<keyof SecurityContext> = [
    'businessId',
    'userId',
    'userName',
    'userRole',
  ];

  const missing = required.filter(field => {
    const value = context[field];
    if (Array.isArray(value)) {
      return value.length === 0;
    }
    if (typeof value === 'string') {
      return !value.trim();
    }
    return !value;
  });

  if (missing.length > 0) {
    throw new Error(
      `SecurityContext missing required fields: ${missing.join(', ')}`
    );
  }

  return true;
}

/**
 * Check if user has one of the specified roles
 *
 * @param context - SecurityContext with user role
 * @param allowedRoles - Array of allowed role names
 * @returns true if user has one of the allowed roles
 */
export function hasRole(
  context: SecurityContext,
  allowedRoles: string[]
): boolean {
  return allowedRoles.includes(context.userRole);
}

/**
 * Check if user is admin or owner
 *
 * @param context - SecurityContext with user role
 * @returns true if user is admin or owner
 */
export function isAdminOrOwner(context: SecurityContext): boolean {
  return hasRole(context, ['admin', 'owner']);
}

/**
 * Check if user can modify a resource
 * Resource can be modified if:
 * - User is admin/owner, OR
 * - User created the resource, OR
 * - User is assigned to the resource
 *
 * @param context - SecurityContext with user info
 * @param resource - Resource with optional createdById and assigneeId
 * @returns true if user can modify the resource
 */
export function canModifyResource(
  context: SecurityContext,
  resource: { createdById?: string; assigneeId?: string }
): boolean {
  // Admins and owners can modify anything
  if (isAdminOrOwner(context)) {
    return true;
  }

  // Resource creator can modify
  if (resource.createdById === context.userId) {
    return true;
  }

  // Assigned user can modify
  if (resource.assigneeId === context.userId) {
    return true;
  }

  return false;
}

type ShareableLike = {
  ownerId?: string;
  teamIds?: string[];
  visibility?: Visibility;
};

function normalizeVisibility(value?: Visibility): Visibility {
  if (value === 'private' || value === 'team' || value === 'org') {
    return value;
  }
  return DEFAULT_VISIBILITY;
}

function getAllTeamsForUser(context: SecurityContext): string[] {
  return sanitizeTeamIds([...(context.teamIds || []), ...(context.managedTeamIds || [])]);
}

function hasOrgPrivilege(context: SecurityContext): boolean {
  const role = (context.userRole || '').toLowerCase();
  return role === 'owner' || role === 'admin';
}

/**
 * UI-friendly helper to determine read access for shareable entities.
 * Mirrors repository-layer logic (owner/admin > owner > team > org visibility).
 */
export function canReadShareableEntity(
  context: SecurityContext,
  entity: ShareableLike | null
): boolean {
  if (!entity) return false;
  const normalizedVisibility = normalizeVisibility(entity.visibility);
  const orgPrivileged = hasOrgPrivilege(context);
  const userTeams = getAllTeamsForUser(context);
  const entityTeams = sanitizeTeamIds(entity.teamIds);
  const hasTeamAccess = userTeams.some((team) => entityTeams.includes(team));

  if (orgPrivileged) return true;
  if (entity.ownerId && entity.ownerId === context.userId) return true;
  if (hasTeamAccess) return true;
  return normalizedVisibility === 'org';
}

/**
 * UI-friendly helper to determine write access for shareable entities.
 * Mirrors repository-layer logic (owner/admin > owner > team).
 */
export function canWriteShareableEntity(
  context: SecurityContext,
  entity: ShareableLike | null
): boolean {
  if (!entity) return false;
  const orgPrivileged = hasOrgPrivilege(context);
  const userTeams = getAllTeamsForUser(context);
  const entityTeams = sanitizeTeamIds(entity.teamIds);
  const hasTeamAccess = userTeams.some((team) => entityTeams.includes(team));

  if (orgPrivileged) return true;
  if (entity.ownerId && entity.ownerId === context.userId) return true;
  return hasTeamAccess;
}

/**
 * Admin/owner-only delete guard for UI parity with repository rules.
 */
export function canDeleteShareableEntity(
  context: SecurityContext,
  entity: ShareableLike | null
): boolean {
  if (!entity) return false;
  return hasOrgPrivilege(context);
}

/**
 * Return consolidated sharing metadata for UI guards.
 * Mirrors repository-layer logic so components can toggle edit/delete affordances.
 */
export function getShareableAccessSummary(
  context: SecurityContext,
  entity: ShareableLike | null
): ShareableAccessSummary {
  const normalizedVisibility = normalizeVisibility(entity?.visibility);
  const orgPrivileged = hasOrgPrivilege(context);
  const effectiveTeams = getAllTeamsForUser(context);
  const entityTeams = sanitizeTeamIds(entity?.teamIds);
  const hasTeamAccess = effectiveTeams.some((team) => entityTeams.includes(team));
  const isOwner = Boolean(entity?.ownerId && entity?.ownerId === context.userId);
  const hasManagerAccess = (context.userRole || '').toLowerCase() === 'manager' && hasTeamAccess;

  const canWrite = canWriteShareableEntity(context, entity);
  return {
    visibility: normalizedVisibility,
    isOwner,
    hasOrgPrivilege: orgPrivileged,
    hasManagerAccess,
    hasTeamAccess,
    canRead: canReadShareableEntity(context, entity),
    canWrite,
    canEdit: canWrite, // Alias for UI convenience
    canDelete: canDeleteShareableEntity(context, entity),
    effectiveTeams,
  };
}
