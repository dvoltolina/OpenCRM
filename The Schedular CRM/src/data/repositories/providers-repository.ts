/**
 * Providers Repository
 * Manages team members/providers in Firestore
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for tenant isolation
 * - Role changes are audit logged (security-critical)
 * - NO PHI in audit logs (IDs only)
 *
 * Storage Path: businesses/{businessId}/providers/{providerId}
 *
 * NOTE: Providers are shared with The Scheduler app.
 * This repository provides secure, audited access from the CRM.
 */

import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
  type Unsubscribe,
} from 'firebase/firestore';
import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import { successResult, failedResult, AuthorizationError } from '../errors/repository-errors';
import { getFirebaseDb } from '../../lib/firebase';
import { sanitizeTeamIds } from '../../lib/security-context';
import { normalizeUserRole } from '../../types/models';

// ============================================
// Types
// ============================================

/**
 * Provider/Team Member role
 */
export type ProviderRole =
  | 'owner'
  | 'admin'
  | 'manager'
  | 'staff'
  | 'sales'
  | 'provider'
  | 'frontDesk';

function normalizeProviderRole(value: unknown): ProviderRole {
  const normalized = normalizeUserRole(typeof value === 'string' ? value : null);
  if (
    normalized === 'owner' ||
    normalized === 'admin' ||
    normalized === 'manager' ||
    normalized === 'staff' ||
    normalized === 'sales' ||
    normalized === 'provider' ||
    normalized === 'frontDesk'
  ) {
    return normalized;
  }
  return 'staff';
}

/**
 * Provider entity (team member)
 */
export interface Provider {
  id: string;
  businessId: string;
  firstName: string;
  lastName: string;
  email: string;
  role: ProviderRole;
  isActive: boolean;
  avatarUrl?: string;
  phone?: string;
  teamIds?: string[];
  managedTeamIds?: string[];
  managerId?: string;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Data for creating a provider
 */
export type ProviderCreateData = Omit<Provider, 'id' | 'createdAt' | 'updatedAt'>;

/**
 * Data for updating a provider
 */
export type ProviderUpdateData = Partial<Omit<Provider, 'id' | 'businessId' | 'createdAt'>>;

// ============================================
// Repository Implementation
// ============================================

export class ProvidersRepository extends BaseRepository<Provider> {
  constructor() {
    super({
      collectionName: 'providers',
      softDelete: false, // Providers use isActive flag
    });
  }

  // ============================================
  // RBAC-Protected CRUD Overrides
  // ============================================

  /**
   * Create a new provider
   * RBAC: Only owner/admin can create providers
   * SECURITY: Prevents privilege escalation (only owner can create owner role)
   */
  async create(
    context: SecurityContext,
    data: Omit<Provider, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<Provider>> {
    // RBAC: Only owner/admin can create providers
    this.requireRole(context, ['owner', 'admin']);

    // Prevent privilege escalation: only owner can create provider with owner role
    if (data.role === 'owner' && context.userRole !== 'owner') {
      return failedResult(
        new AuthorizationError('Only owners can create providers with the owner role')
      );
    }

    return super.create(context, data, customId);
  }

  /**
   * Update a provider
   * RBAC: Only owner/admin can update providers
   * Note: For role changes, use updateRole() which has additional checks
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<Provider, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<Provider>> {
    // RBAC: Only owner/admin can update providers
    this.requireRole(context, ['owner', 'admin']);

    // Prevent privilege escalation via direct role update
    // Role changes should go through updateRole() for proper validation
    if (data.role && data.role === 'owner' && context.userRole !== 'owner') {
      return failedResult(
        new AuthorizationError('Only owners can assign the owner role')
      );
    }

    return super.update(context, id, data);
  }

  /**
   * Delete a provider (hard delete)
   * RBAC: Only owner can delete providers
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    // RBAC: Only owner can delete providers
    this.requireRole(context, ['owner']);

    // Prevent self-deletion of the last owner
    const existingResult = await this.getById(context, id);
    if (existingResult.success && existingResult.data?.role === 'owner') {
      const ownersResult = await this.getByRole(context, 'owner');
      if (ownersResult.success && ownersResult.data.data.length <= 1) {
        return failedResult(
          new AuthorizationError('Cannot delete the last owner of the business')
        );
      }
    }

    return super.delete(context, id);
  }

  /**
   * Get all active providers for a business
   */
  async getActiveProviders(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<Provider>>> {
    const options: QueryOptions = {
      where: [{ field: 'isActive', operator: '==', value: true }],
      orderBy: { field: 'firstName', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get provider by email
   */
  async getByEmail(
    context: SecurityContext,
    email: string
  ): Promise<RepositoryResult<Provider | null>> {
    try {
      this.ensureSecurityContext(context);

      const options: QueryOptions = {
        where: [{ field: 'email', operator: '==', value: email }],
        limit: 1,
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      const provider = result.data.data[0] || null;
      return successResult(provider);
    } catch (error) {
      return failedResult(error, 'Failed to get provider by email');
    }
  }

  /**
   * Update provider role with audit logging
   * SECURITY-CRITICAL: Role changes must be logged
   * RBAC: Role escalation prevention
   */
  async updateRole(
    context: SecurityContext,
    providerId: string,
    newRole: ProviderRole
  ): Promise<RepositoryResult<Provider>> {
    try {
      // RBAC: Only owner/admin can change roles
      this.requireRole(context, ['owner', 'admin']);

      // Get current provider to log the change
      const currentResult = await this.getById(context, providerId);
      if (!currentResult.success || !currentResult.data) {
        return failedResult(new Error('Provider not found'), 'Provider not found');
      }

      const currentProvider = currentResult.data;
      const oldRole = currentProvider.role;

      // Don't update if role is the same
      if (oldRole === newRole) {
        return successResult(currentProvider);
      }

      // Prevent privilege escalation: only owner can assign owner role
      if (newRole === 'owner' && context.userRole !== 'owner') {
        return failedResult(
          new AuthorizationError('Only owners can assign the owner role')
        );
      }

      // Prevent self-demotion of last owner
      if (providerId === context.userId && context.userRole === 'owner') {
        const ownersResult = await this.getByRole(context, 'owner');
        if (ownersResult.success && ownersResult.data.data.length <= 1 && newRole !== 'owner') {
          return failedResult(
            new AuthorizationError('Cannot demote the last owner of the business')
          );
        }
      }

      // Perform the update
      const updateResult = await this.update(context, providerId, { role: newRole });

      if (updateResult.success) {
        // Log the role change with enhanced audit info
        await this.logAudit(context, 'update', providerId, {
          action: 'role_change',
          oldRole: oldRole,
          newRole: newRole,
          // NO PHI: Don't log email or name
        });
      }

      return updateResult;
    } catch (error) {
      return failedResult(error, 'Failed to update provider role');
    }
  }

  /**
   * Deactivate a provider (soft delete)
   * RBAC: Only owner/admin can deactivate providers
   * SECURITY: Prevents deactivation of the last owner
   */
  async deactivate(
    context: SecurityContext,
    providerId: string
  ): Promise<RepositoryResult<Provider>> {
    // RBAC: Only owner/admin can deactivate providers
    this.requireRole(context, ['owner', 'admin']);

    // Prevent deactivation of the last owner
    const existingResult = await this.getById(context, providerId);
    if (existingResult.success && existingResult.data?.role === 'owner') {
      const ownersResult = await this.getByRole(context, 'owner');
      if (ownersResult.success && ownersResult.data.data.length <= 1) {
        return failedResult(
          new AuthorizationError('Cannot deactivate the last owner of the business')
        );
      }
    }

    // Note: update() is now RBAC-protected, but we already checked above
    const result = await super.update(context, providerId, { isActive: false });

    if (result.success) {
      await this.logAudit(context, 'delete', providerId, {
        action: 'deactivate',
      });
    }

    return result;
  }

  /**
   * Reactivate a provider
   * RBAC: Only owner/admin can reactivate providers
   */
  async reactivate(
    context: SecurityContext,
    providerId: string
  ): Promise<RepositoryResult<Provider>> {
    // RBAC: Only owner/admin can reactivate providers
    this.requireRole(context, ['owner', 'admin']);

    // Note: update() is now RBAC-protected, but we already checked above
    const result = await super.update(context, providerId, { isActive: true });

    if (result.success) {
      await this.logAudit(context, 'update', providerId, {
        action: 'reactivate',
      });
    }

    return result;
  }

  /**
   * Subscribe to active providers (real-time updates)
   * Returns an unsubscribe function
   */
  subscribeToActiveProviders(
    context: SecurityContext,
    onData: (providers: Provider[]) => void,
    onError: (error: Error) => void
  ): Unsubscribe {
    this.ensureSecurityContext(context);

    const db = getFirebaseDb();
    if (!db) {
      onError(new Error('Database not initialized'));
      return () => {};
    }

    const collectionPath = `businesses/${context.businessId}/providers`;
    const q = query(
      collection(db, collectionPath),
      where('isActive', '==', true),
      orderBy('firstName', 'asc')
    );

    return onSnapshot(
      q,
      (snapshot) => {
        const providers: Provider[] = snapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            businessId: context.businessId,
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            email: data.email || '',
            role: normalizeProviderRole(data.role),
            isActive: data.isActive ?? true,
            avatarUrl: data.avatarUrl,
            phone: data.phone,
            teamIds: sanitizeTeamIds(data.teamIds),
            managedTeamIds: sanitizeTeamIds(data.managedTeamIds),
            managerId: typeof data.managerId === 'string' ? data.managerId : undefined,
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate() || new Date(),
          };
        });
        onData(providers);
      },
      (error) => {
        onError(error);
      }
    );
  }

  /**
   * Get providers by role
   */
  async getByRole(
    context: SecurityContext,
    role: ProviderRole
  ): Promise<RepositoryResult<PaginatedResult<Provider>>> {
    const options: QueryOptions = {
      where: [
        { field: 'role', operator: '==', value: role },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'firstName', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get owners and admins (for permission checks)
   */
  async getAdmins(
    context: SecurityContext
  ): Promise<RepositoryResult<Provider[]>> {
    try {
      this.ensureSecurityContext(context);

      // Get owners
      const ownersResult = await this.getByRole(context, 'owner');
      // Get admins
      const adminsResult = await this.getByRole(context, 'admin');

      if (!ownersResult.success || !adminsResult.success) {
        return failedResult(
          ownersResult.error || adminsResult.error,
          'Failed to get admins'
        );
      }

      const admins = [...ownersResult.data.data, ...adminsResult.data.data];
      return successResult(admins);
    } catch (error) {
      return failedResult(error, 'Failed to get admins');
    }
  }

  /**
   * Count active providers
   */
  async countActive(context: SecurityContext): Promise<RepositoryResult<number>> {
    try {
      const result = await this.getActiveProviders(context);

      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      return successResult(result.data.data.length);
    } catch (error) {
      return failedResult(error, 'Failed to count providers');
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let providersRepositoryInstance: ProvidersRepository | null = null;

export function getProvidersRepository(): ProvidersRepository {
  if (!providersRepositoryInstance) {
    providersRepositoryInstance = new ProvidersRepository();
  }
  return providersRepositoryInstance;
}
