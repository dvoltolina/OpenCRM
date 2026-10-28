/**
 * Repository Access Control Helpers
 * Centralizes ownership/team/visibility checks for shareable entities.
 */

import { AuthorizationError, failedResult, successResult } from '../errors/repository-errors';
import type {
  BaseEntity,
  PaginatedResult,
  QueryOptions,
  RepositoryResult,
  SecurityContext,
} from './repository-types';
import { getShareableQueryScope, resolveTeamIds, sanitizeTeamIds } from '../../lib/security-context';
import { BaseRepository } from './base-repository';
import {
  getDocs,
  limit,
  or,
  orderBy,
  query,
  startAfter,
  where,
  type QueryConstraint,
  type QueryFilterConstraint,
} from 'firebase/firestore';
import { documentsToEntities } from './firestore-utils';

export type VisibilityLevel = 'private' | 'team' | 'org';

export interface ShareableEntity {
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: VisibilityLevel;
  [key: string]: unknown;
}

export interface ShareableAccessMeta {
  visibility: VisibilityLevel;
  isOwner: boolean;
  hasOrgPrivilege: boolean;
  hasManagerAccess: boolean;
  hasTeamAccess: boolean;
  canRead: boolean;
  canWrite: boolean;
  canDelete: boolean;
  canChangeOwnership: boolean;
  effectiveTeams: string[];
}

const DEFAULT_VISIBILITY: VisibilityLevel = 'team';

const ORG_PRIVILEGED_ROLES: string[] = ['owner', 'admin'];
const MANAGER_ROLE = 'manager';
const PRIVILEGED_ROLES: string[] = [...ORG_PRIVILEGED_ROLES, MANAGER_ROLE];

/**
 * Normalize a visibility value, defaulting to team scope.
 */
export function normalizeVisibility(value?: VisibilityLevel): VisibilityLevel {
  if (value === 'private' || value === 'org' || value === 'team') {
    return value;
  }
  return DEFAULT_VISIBILITY;
}

/**
 * Combine user and managed team IDs, removing duplicates.
 */
export function getEffectiveTeams(context: SecurityContext): string[] {
  const primaryTeams = sanitizeTeamIds(context.teamIds);
  const managedTeams = sanitizeTeamIds(context.managedTeamIds);
  return resolveTeamIds([...primaryTeams, ...managedTeams]);
}

/**
 * Return the team scope (direct + managed) for downstream query construction.
 */
export function getTeamScope(context: SecurityContext): {
  teamIds: string[];
  managedTeamIds: string[];
  allTeamIds: string[];
} {
  const teamIds = sanitizeTeamIds(context.teamIds);
  const managedTeamIds = sanitizeTeamIds(context.managedTeamIds);
  return {
    teamIds,
    managedTeamIds,
    allTeamIds: resolveTeamIds([...teamIds, ...managedTeamIds]),
  };
}

/**
 * Surface consolidated access metadata for UI guards and query builders.
 */
export function getShareableAccessMeta(
  context: SecurityContext,
  entity: ShareableEntity | null
): ShareableAccessMeta {
  const visibility = normalizeVisibility(entity?.visibility);
  const effectiveTeams = getEffectiveTeams(context);
  const hasOrgPrivilege = isOrgPrivileged(context);
  const hasTeamAccessForEntity = entity ? hasTeamAccess(context, entity.teamIds) : false;
  const hasManagerAccess = entity ? hasManagerTeamAccess(context, entity.teamIds) : false;
  const isOwner = Boolean(entity && entity.ownerId === context.userId);

  const canRead = entity ? canReadShareable(context, entity) : false;
  const canWrite = entity ? canWriteShareable(context, entity) : false;
  const canDelete = entity ? canDeleteShareable(context, entity) : false;

  return {
    visibility,
    isOwner,
    hasOrgPrivilege,
    hasManagerAccess,
    hasTeamAccess: hasTeamAccessForEntity,
    canRead,
    canWrite,
    canDelete,
    canChangeOwnership: isOrgPrivileged(context),
    effectiveTeams,
  };
}

/**
 * Determine if a user is privileged (owner/admin/manager).
 */
export function isPrivileged(context: SecurityContext): boolean {
  const role = (context.userRole || '').toLowerCase();
  return PRIVILEGED_ROLES.includes(role);
}

/**
 * Determine if a user has org-level privileges (owner/admin).
 */
export function isOrgPrivileged(context: SecurityContext): boolean {
  const role = (context.userRole || '').toLowerCase();
  return ORG_PRIVILEGED_ROLES.includes(role);
}

/**
 * Determine if a user is a manager.
 */
export function isManager(context: SecurityContext): boolean {
  return (context.userRole || '').toLowerCase() === MANAGER_ROLE;
}

/**
 * Check if the user shares any team with the entity.
 */
export function hasTeamAccess(context: SecurityContext, entityTeams?: string[]): boolean {
  const userTeams = getEffectiveTeams(context);
  const targetTeams = sanitizeTeamIds(entityTeams);
  return userTeams.some((team) => targetTeams.includes(team));
}

/**
 * Check if a manager has access via managed team membership.
 */
export function hasManagerTeamAccess(context: SecurityContext, entityTeams?: string[]): boolean {
  return isManager(context) && hasTeamAccess(context, entityTeams);
}

/**
 * Determine if the user can read a shareable entity.
 */
export function canReadShareable(context: SecurityContext, entity: ShareableEntity | null): boolean {
  if (!entity) return false;
  const visibility = normalizeVisibility(entity.visibility);
  if (isOrgPrivileged(context)) return true;
  if (entity.ownerId && entity.ownerId === context.userId) return true;
  if (hasTeamAccess(context, entity.teamIds)) return true;
  return visibility === 'org';
}

/**
 * Determine if the user can write to a shareable entity.
 */
export function canWriteShareable(context: SecurityContext, entity: ShareableEntity | null): boolean {
  if (!entity) return false;
  if (isOrgPrivileged(context)) return true;
  if (entity.ownerId && entity.ownerId === context.userId) return true;
  return hasTeamAccess(context, entity.teamIds);
}

/**
 * Determine if the user can delete a shareable entity.
 * Mobile-aligned rule: only owner/admin can delete.
 */
export function canDeleteShareable(context: SecurityContext, entity: ShareableEntity | null): boolean {
  if (!entity) return false;
  return isOrgPrivileged(context);
}

/**
 * Apply default ownership/team/visibility to new entities.
 */
export function applyOwnershipDefaults<T extends ShareableEntity>(
  context: SecurityContext,
  data: T,
  defaultVisibility: VisibilityLevel = DEFAULT_VISIBILITY
): T {
  const scope = getTeamScope(context);
  const requestedTeams = sanitizeTeamIds(data.teamIds);
  const allowedTeams = isOrgPrivileged(context)
    ? requestedTeams
    : requestedTeams.filter((team) => scope.allTeamIds.includes(team));
  const combinedTeams = resolveTeamIds(allowedTeams, getEffectiveTeams(context));

  const ownerId = isOrgPrivileged(context) && data.ownerId ? data.ownerId : context.userId;
  const ownerName = isOrgPrivileged(context) && data.ownerName ? data.ownerName : context.userName;
  const visibility = (isOrgPrivileged(context) || hasManagerTeamAccess(context, combinedTeams))
    ? normalizeVisibility(data.visibility ?? defaultVisibility)
    : defaultVisibility;

  return {
    ...data,
    ownerId,
    ownerName,
    teamIds: combinedTeams,
    visibility,
  };
}

/**
 * Remove sensitive fields for non-privileged users who are not owners.
 */
export function sanitizeSensitiveFields<T extends Record<string, unknown> & ShareableEntity>(
  context: SecurityContext,
  entity: T,
  sensitiveFields: Array<keyof T>
): T {
  if (isOrgPrivileged(context) || entity.ownerId === context.userId || hasManagerTeamAccess(context, entity.teamIds)) {
    return entity;
  }

  const sanitized = { ...entity } as Record<string, unknown>;
  for (const field of sensitiveFields) {
    if (field in sanitized) {
      delete sanitized[field as string];
    }
  }

  return sanitized as T;
}

/**
 * Block read access with a consistent authorization error.
 */
export function enforceReadAccess(
  context: SecurityContext,
  entity: ShareableEntity,
  entityName: string
): void {
  if (!canReadShareable(context, entity)) {
    throw new AuthorizationError(`Not authorized to read ${entityName}`, 'read', context.userRole);
  }
}

/**
 * Block write access with a consistent authorization error.
 */
export function enforceWriteAccess(
  context: SecurityContext,
  entity: ShareableEntity,
  entityName: string
): void {
  if (!canWriteShareable(context, entity)) {
    throw new AuthorizationError(`Not authorized to modify ${entityName}`, 'write', context.userRole);
  }
}

/**
 * Block delete access with a consistent authorization error (admin/owner only).
 */
export function enforceDeleteAccess(
  context: SecurityContext,
  entity: ShareableEntity,
  entityName: string
): void {
  if (!canDeleteShareable(context, entity)) {
    throw new AuthorizationError(`Only admins or owners can delete ${entityName}`, 'delete', context.userRole);
  }
}

/**
 * Prevent non-privileged users from changing ownership/sharing fields.
 */
export function stripUnauthorizedOwnershipUpdates<T extends ShareableEntity>(
  context: SecurityContext,
  updates: Partial<T>,
  existing: T
): Partial<T> {
  const sanitized = { ...updates };
  const canChangeOwnership = isOrgPrivileged(context);
  const canChangeSharing = canChangeOwnership || hasManagerTeamAccess(context, existing.teamIds);

  if (!canChangeOwnership) {
    delete sanitized.ownerId;
    delete sanitized.ownerName;
  }

  if (!canChangeSharing) {
    delete sanitized.teamIds;
    delete sanitized.visibility;
  }

  return sanitized;
}

/**
 * Prevent non-privileged/non-owners from changing sensitive fields.
 */
export function stripUnauthorizedSensitiveUpdates<T extends ShareableEntity>(
  context: SecurityContext,
  updates: Partial<T>,
  existing: T,
  sensitiveFields: Array<keyof T>
): Partial<T> {
  if (isOrgPrivileged(context) || existing.ownerId === context.userId || hasManagerTeamAccess(context, existing.teamIds)) {
    return updates;
  }

  const sanitized = { ...updates };
  for (const field of sensitiveFields) {
    if (field in sanitized) {
      delete sanitized[field];
    }
  }
  return sanitized;
}

/**
 * Filter and sanitize a list of entities by access rules.
 */
export function filterAuthorizedEntities<T extends ShareableEntity>(
  context: SecurityContext,
  entities: T[],
  sensitiveFields: Array<keyof T>
): T[] {
  return entities
    .filter((entity) => canReadShareable(context, entity))
    .map((entity) => sanitizeSensitiveFields(context, entity, sensitiveFields));
}

/**
 * Base class for repositories that enforce ownership and team-based sharing.
 */
export abstract class ShareableRepository<T extends ShareableEntity & BaseEntity> extends BaseRepository<T> {
  protected abstract entityName: string;
  protected sensitiveFields: Array<keyof T> = [];
  protected defaultVisibility: VisibilityLevel = DEFAULT_VISIBILITY;

  /**
   * Build a Firestore constraint that scopes results to shareable entities
   * the caller is eligible to see (owner/team/org) without wide reads.
   */
  private buildShareableConstraint(context: SecurityContext): QueryConstraint | null {
    if (isOrgPrivileged(context)) {
      return null;
    }

    const scope = getShareableQueryScope(context);
    const filters: QueryFilterConstraint[] = [
      where('ownerId', '==', scope.ownerId),
    ];

    const teamScope = scope.allTeamIds.slice(0, 10);
    if (teamScope.length > 0) {
      filters.push(where('teamIds', 'array-contains-any', teamScope));
    }

    // Org-visible content is the only non-owner/team bucket non-privileged users can read.
    filters.push(where('visibility', '==', 'org'));

    if (filters.length === 1) {
      return filters[0] as unknown as QueryConstraint;
    }
    return or(...filters) as unknown as QueryConstraint;
  }

  async getById(context: SecurityContext, id: string): Promise<RepositoryResult<T>> {
    const result = await super.getById(context, id);
    if (!result.success) return result;

    try {
      enforceReadAccess(context, result.data, this.entityName);
    } catch (error) {
      return failedResult(error, `Not authorized to read ${this.entityName}`);
    }

    const sanitized = sanitizeSensitiveFields(context, result.data, this.sensitiveFields);
    return successResult(sanitized);
  }

  async getAll(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<T>>> {
    try {
      this.ensureSecurityContext(context);

      if (this.useLocalDemoData) {
        const page = this.getLocalDemoPage(context, options);
        return successResult({
          ...page,
          data: filterAuthorizedEntities(context, page.data, this.sensitiveFields),
        });
      }

      const collectionRef = this.getCollectionRef(context);
      const queryOptions = { ...options };

      // Apply soft delete filter if enabled
      const constraints: QueryConstraint[] = [];
      if (this.softDelete) {
        constraints.push(where('isDeleted', '!=', true));
      }

      // Scope by owner/team/org visibility for non-privileged callers
      const shareableConstraint = this.buildShareableConstraint(context);
      if (shareableConstraint) {
        constraints.push(shareableConstraint);
      }

      // Apply caller-provided where clauses
      if (queryOptions.where && queryOptions.where.length > 0) {
        for (const clause of queryOptions.where) {
          constraints.push(where(clause.field, clause.operator as any, clause.value));
        }
      }

      // Default ordering by createdAt if not specified
      if (!queryOptions.orderBy) {
        queryOptions.orderBy = { field: 'createdAt', direction: 'desc' };
      }

      constraints.push(orderBy(queryOptions.orderBy.field, queryOptions.orderBy.direction));

      if (queryOptions.orderByMultiple && queryOptions.orderByMultiple.length > 0) {
        for (const clause of queryOptions.orderByMultiple) {
          constraints.push(orderBy(clause.field, clause.direction));
        }
      }

      if (queryOptions.startAfter) {
        constraints.push(startAfter(queryOptions.startAfter));
      }

      if (queryOptions.limit && queryOptions.limit > 0) {
        constraints.push(limit(queryOptions.limit));
      }

      const q = query(collectionRef, ...constraints);
      const querySnapshot = await getDocs(q);
      const entities = documentsToEntities<T>(querySnapshot.docs);
      const lastDoc = querySnapshot.docs[querySnapshot.docs.length - 1] || null;
      const filtered = filterAuthorizedEntities(context, entities, this.sensitiveFields);
      const hasMore = Boolean(
        (options.limit && querySnapshot.docs.length >= options.limit) ||
          filtered.length < entities.length
      );

      await this.logAudit(context, 'list', null, {
        count: filtered.length,
        hasMore,
      });

      return successResult({
        data: filtered,
        lastDoc,
        hasMore,
      });
    } catch (error) {
      return failedResult(error, `Failed to list ${this.collectionName}`);
    }
  }

  async create(
    context: SecurityContext,
    data: Omit<T, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<T>> {
    const withOwnership = applyOwnershipDefaults(context, data as T, this.defaultVisibility);
    return super.create(context, withOwnership, customId);
  }

  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<T, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<T>> {
    const existingResult = await super.getById(context, id);
    if (!existingResult.success) return existingResult;

    try {
      enforceWriteAccess(context, existingResult.data, this.entityName);
    } catch (error) {
      return failedResult(error, `Not authorized to update ${this.entityName}`);
    }

    const sanitizedOwnership = stripUnauthorizedOwnershipUpdates(
      context,
      data as Partial<T>,
      existingResult.data
    );
    const sanitizedUpdates = stripUnauthorizedSensitiveUpdates(
      context,
      sanitizedOwnership,
      existingResult.data,
      this.sensitiveFields
    );

    const result = await super.update(context, id, sanitizedUpdates);
    if (!result.success) return result;

    try {
      enforceReadAccess(context, result.data, this.entityName);
    } catch (error) {
      return failedResult(error, `Not authorized to read ${this.entityName}`);
    }

    const sanitized = sanitizeSensitiveFields(context, result.data, this.sensitiveFields);
    return successResult(sanitized);
  }

  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    const existingResult = await super.getById(context, id);
    if (!existingResult.success) return existingResult;

    try {
      enforceDeleteAccess(context, existingResult.data, this.entityName);
    } catch (error) {
      return failedResult(error, `Not authorized to delete ${this.entityName}`);
    }

    return super.delete(context, id);
  }
}
