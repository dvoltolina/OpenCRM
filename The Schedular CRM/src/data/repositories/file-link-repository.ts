/**
 * File Link Repository
 * Repository for managing secure file sharing links with expiring access
 *
 * HIPAA Compliance:
 * - All operations scoped by businessId (multi-tenant isolation)
 * - SecurityContext validation on all methods
 * - Audit logging for PHI access (file names may contain PHI)
 * - No PHI in error messages or logs
 *
 * Security Features:
 * - Expiring links with TTL
 * - Optional password protection
 * - Optional IP whitelisting
 * - Access count limits
 * - Revocable links
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  QueryOptions,
} from './repository-types';
import type { SecureFileLink } from '../../types/templates';
import { query, where, getDocs, limit } from 'firebase/firestore';
import { documentToEntity } from './firestore-utils';
import { failedResult, successResult } from '../errors/repository-errors';

/**
 * FileLinkRepository
 * Handles CRUD operations for secure file links
 */
export class FileLinkRepository extends BaseRepository<SecureFileLink> {
  constructor() {
    super({
      collectionName: 'file_links',
      softDelete: false, // Hard delete for security - expired links should be removed
    });
  }

  /**
   * Get a file link by its unique token
   * This is the primary lookup method for public link validation
   *
   * SECURITY: Token lookup doesn't require authentication but returns
   * limited data. Full validation happens in the service layer.
   *
   * @param context - Security context
   * @param token - Unique link token
   * @returns File link or null if not found
   */
  async getByToken(
    context: SecurityContext,
    token: string
  ): Promise<RepositoryResult<SecureFileLink | null>> {
    try {
      this.ensureSecurityContext(context);

      if (!token || token.trim().length === 0) {
        return failedResult(new Error('Token is required'));
      }

      const collectionRef = this.getCollectionRef(context);
      const q = query(collectionRef, where('token', '==', token), limit(1));

      const querySnapshot = await getDocs(q);

      if (querySnapshot.empty) {
        return successResult(null);
      }

      const link = documentToEntity<SecureFileLink>(querySnapshot.docs[0]);

      // Audit log - token lookup (log ID only, not file name due to PHI risk)
      await this.logAudit(context, 'read', link?.id || null, {
        operation: 'getByToken',
        found: !!link,
      });

      return successResult(link);
    } catch (error) {
      return failedResult(error, 'Failed to get link by token');
    }
  }

  /**
   * Get all links for a specific file
   *
   * @param context - Security context
   * @param fileId - File ID to get links for
   * @returns Array of file links
   */
  async getByFileId(
    context: SecurityContext,
    fileId: string
  ): Promise<RepositoryResult<SecureFileLink[]>> {
    try {
      this.ensureSecurityContext(context);

      if (!fileId || fileId.trim().length === 0) {
        return failedResult(new Error('File ID is required'));
      }

      const options: QueryOptions = {
        where: [{ field: 'fileId', operator: '==', value: fileId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log
      await this.logAudit(context, 'list', null, {
        operation: 'getByFileId',
        fileId, // Safe to log - file ID is not PHI
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get links for file');
    }
  }

  /**
   * Get all links for a specific client
   *
   * @param context - Security context
   * @param clientId - Client ID to get links for
   * @returns Array of file links
   */
  async getByClientId(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<SecureFileLink[]>> {
    try {
      this.ensureSecurityContext(context);

      if (!clientId || clientId.trim().length === 0) {
        return failedResult(new Error('Client ID is required'));
      }

      const options: QueryOptions = {
        where: [{ field: 'clientId', operator: '==', value: clientId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log (clientId only - not file names)
      await this.logAudit(context, 'list', null, {
        operation: 'getByClientId',
        clientId, // Safe to log - client ID is not PHI
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get links for client');
    }
  }

  /**
   * Get all active (non-revoked, non-expired) links
   *
   * @param context - Security context
   * @returns Array of active file links
   */
  async getActiveLinks(context: SecurityContext): Promise<RepositoryResult<SecureFileLink[]>> {
    try {
      this.ensureSecurityContext(context);

      const now = new Date();

      const options: QueryOptions = {
        where: [
          { field: 'isActive', operator: '==', value: true },
          { field: 'isRevoked', operator: '==', value: false },
          { field: 'expiresAt', operator: '>', value: now },
        ],
        orderBy: { field: 'expiresAt', direction: 'asc' },
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log
      await this.logAudit(context, 'list', null, {
        operation: 'getActiveLinks',
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get active links');
    }
  }

  /**
   * Get all expired links (for cleanup operations)
   *
   * @param context - Security context
   * @returns Array of expired file links
   */
  async getExpiredLinks(context: SecurityContext): Promise<RepositoryResult<SecureFileLink[]>> {
    try {
      this.ensureSecurityContext(context);

      const now = new Date();

      const options: QueryOptions = {
        where: [{ field: 'expiresAt', operator: '<', value: now }],
        orderBy: { field: 'expiresAt', direction: 'asc' },
      };

      const result = await this.getAll(context, options);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log
      await this.logAudit(context, 'list', null, {
        operation: 'getExpiredLinks',
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get expired links');
    }
  }

  /**
   * Override create to audit PHI access
   */
  async create(
    context: SecurityContext,
    data: Omit<SecureFileLink, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<SecureFileLink>> {
    // Call parent create
    const result = await super.create(context, data, customId);

    // Additional audit logging for file link creation
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, {
        operation: 'createFileLink',
        fileId: result.data.fileId, // Safe to log - ID not PHI
        expiresAt: result.data.expiresAt,
        requiresPassword: result.data.requiresPassword,
        hasIpRestrictions: (result.data.allowedIpAddresses?.length || 0) > 0,
      });
    }

    return result;
  }

  /**
   * Override delete to audit PHI access
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    // Get the link first for audit logging
    const existing = await this.getById(context, id);

    // Call parent delete
    const result = await super.delete(context, id);

    // Additional audit logging for file link deletion
    if (result.success && existing.success) {
      await this.logAudit(context, 'delete', id, {
        operation: 'deleteFileLink',
        fileId: existing.data.fileId, // Safe to log - ID not PHI
      });
    }

    return result;
  }
}

/**
 * Singleton instance
 */
let fileLinkRepositoryInstance: FileLinkRepository | null = null;

/**
 * Get the FileLinkRepository singleton instance
 */
export function getFileLinkRepository(): FileLinkRepository {
  if (!fileLinkRepositoryInstance) {
    fileLinkRepositoryInstance = new FileLinkRepository();
  }
  return fileLinkRepositoryInstance;
}
