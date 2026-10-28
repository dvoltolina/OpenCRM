/**
 * Teams Repository
 * Manages teams in Firestore for admin functionality
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for tenant isolation
 * - All CRUD operations are audit logged
 * - NO PHI in audit logs (IDs only)
 *
 * Storage Path: businesses/{businessId}/teams/{teamId}
 *
 * RBAC:
 * - Only owner/admin can create, update, delete teams
 * - All authenticated users can read teams
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
import { successResult, failedResult } from '../errors/repository-errors';
import { getFirebaseDb } from '../../lib/firebase';
import type { Team } from '../../types/models';

// ============================================
// Types
// ============================================

/**
 * Data for creating a team
 */
export type TeamCreateData = Omit<Team, 'id' | 'createdAt' | 'updatedAt' | 'createdById' | 'createdByName'>;

/**
 * Data for updating a team
 */
export type TeamUpdateData = Partial<Omit<Team, 'id' | 'createdAt' | 'createdById' | 'createdByName'>>;

// ============================================
// Repository Implementation
// ============================================

export class TeamsRepository extends BaseRepository<Team> {
  constructor() {
    super({
      collectionName: 'teams',
      softDelete: false, // Teams use isActive flag
    });
  }

  // ============================================
  // RBAC-Protected CRUD Overrides
  // ============================================

  /**
   * Create a new team
   * RBAC: Only owner/admin can create teams
   */
  async create(
    context: SecurityContext,
    data: TeamCreateData
  ): Promise<RepositoryResult<Team>> {
    // RBAC: Only owner/admin can create teams
    this.requireRole(context, ['owner', 'admin']);

    // Add creator info
    const teamData = {
      ...data,
      createdById: context.userId,
      createdByName: context.userName,
      isActive: data.isActive ?? true,
    };

    const result = await super.create(context, teamData as Omit<Team, 'id' | 'createdAt' | 'updatedAt'>);

    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, {
        action: 'team_created',
        teamName: data.name,
      });
    }

    return result;
  }

  /**
   * Update a team
   * RBAC: Only owner/admin can update teams
   */
  async update(
    context: SecurityContext,
    id: string,
    data: TeamUpdateData
  ): Promise<RepositoryResult<Team>> {
    // RBAC: Only owner/admin can update teams
    this.requireRole(context, ['owner', 'admin']);

    const result = await super.update(context, id, data);

    if (result.success) {
      await this.logAudit(context, 'update', id, {
        action: 'team_updated',
        updatedFields: Object.keys(data),
      });
    }

    return result;
  }

  /**
   * Delete a team (hard delete)
   * RBAC: Only owner/admin can delete teams
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    // RBAC: Only owner/admin can delete teams
    this.requireRole(context, ['owner', 'admin']);

    // Get team info for audit log before deletion
    const existingResult = await this.getById(context, id);
    const teamName = existingResult.success ? existingResult.data?.name : 'unknown';

    const result = await super.delete(context, id);

    if (result.success) {
      await this.logAudit(context, 'delete', id, {
        action: 'team_deleted',
        teamName,
      });
    }

    return result;
  }

  // ============================================
  // Custom Query Methods
  // ============================================

  /**
   * Get all active teams for a business
   */
  async getActiveTeams(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<Team>>> {
    const options: QueryOptions = {
      where: [{ field: 'isActive', operator: '==', value: true }],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get all teams (including inactive) for a business
   */
  async getAllTeams(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<Team>>> {
    const options: QueryOptions = {
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get teams managed by a specific user
   */
  async getTeamsByManager(
    context: SecurityContext,
    managerId: string
  ): Promise<RepositoryResult<PaginatedResult<Team>>> {
    const options: QueryOptions = {
      where: [
        { field: 'managerId', operator: '==', value: managerId },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Deactivate a team (soft delete)
   * RBAC: Only owner/admin can deactivate teams
   */
  async deactivate(
    context: SecurityContext,
    teamId: string
  ): Promise<RepositoryResult<Team>> {
    // RBAC: Only owner/admin can deactivate teams
    this.requireRole(context, ['owner', 'admin']);

    const result = await super.update(context, teamId, { isActive: false });

    if (result.success) {
      await this.logAudit(context, 'update', teamId, {
        action: 'team_deactivated',
      });
    }

    return result;
  }

  /**
   * Reactivate a team
   * RBAC: Only owner/admin can reactivate teams
   */
  async reactivate(
    context: SecurityContext,
    teamId: string
  ): Promise<RepositoryResult<Team>> {
    // RBAC: Only owner/admin can reactivate teams
    this.requireRole(context, ['owner', 'admin']);

    const result = await super.update(context, teamId, { isActive: true });

    if (result.success) {
      await this.logAudit(context, 'update', teamId, {
        action: 'team_reactivated',
      });
    }

    return result;
  }

  /**
   * Assign a manager to a team
   * RBAC: Only owner/admin can assign managers
   */
  async assignManager(
    context: SecurityContext,
    teamId: string,
    managerId: string,
    managerName: string
  ): Promise<RepositoryResult<Team>> {
    // RBAC: Only owner/admin can assign managers
    this.requireRole(context, ['owner', 'admin']);

    const result = await super.update(context, teamId, {
      managerId,
      managerName,
    });

    if (result.success) {
      await this.logAudit(context, 'update', teamId, {
        action: 'manager_assigned',
        newManagerId: managerId,
      });
    }

    return result;
  }

  /**
   * Subscribe to all teams (real-time updates)
   * Returns an unsubscribe function
   */
  subscribeToTeams(
    context: SecurityContext,
    onData: (teams: Team[]) => void,
    onError: (error: Error) => void,
    activeOnly: boolean = true
  ): Unsubscribe {
    this.ensureSecurityContext(context);

    const db = getFirebaseDb();
    if (!db) {
      onError(new Error('Database not initialized'));
      return () => {};
    }

    const collectionPath = `businesses/${context.businessId}/teams`;
    let q = query(
      collection(db, collectionPath),
      orderBy('name', 'asc')
    );

    if (activeOnly) {
      q = query(
        collection(db, collectionPath),
        where('isActive', '==', true),
        orderBy('name', 'asc')
      );
    }

    return onSnapshot(
      q,
      (snapshot) => {
        const teams: Team[] = snapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            id: doc.id,
            name: data.name || '',
            description: data.description,
            managerId: data.managerId,
            managerName: data.managerName,
            isActive: data.isActive ?? true,
            colorHex: data.colorHex,
            createdAt: data.createdAt?.toDate() || new Date(),
            updatedAt: data.updatedAt?.toDate(),
            createdById: data.createdById || '',
            createdByName: data.createdByName || '',
          };
        });
        onData(teams);
      },
      (error) => {
        onError(error);
      }
    );
  }

  /**
   * Count active teams
   */
  async countActive(context: SecurityContext): Promise<RepositoryResult<number>> {
    try {
      const result = await this.getActiveTeams(context);

      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      return successResult(result.data.data.length);
    } catch (error) {
      return failedResult(error, 'Failed to count teams');
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let teamsRepositoryInstance: TeamsRepository | null = null;

export function getTeamsRepository(): TeamsRepository {
  if (!teamsRepositoryInstance) {
    teamsRepositoryInstance = new TeamsRepository();
  }
  return teamsRepositoryInstance;
}
