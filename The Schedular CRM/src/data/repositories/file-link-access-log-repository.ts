/**
 * File Link Access Log Repository
 * Repository for logging all file link access attempts for HIPAA compliance
 *
 * HIPAA Compliance:
 * - Complete audit trail of all file access (successful and failed)
 * - All operations scoped by businessId
 * - SecurityContext validation
 * - No PHI in logs (log IDs only, not file names)
 *
 * Access logs are append-only - no updates or deletes allowed
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  QueryOptions,
} from './repository-types';
import type { FileLinkAccessLog } from '../../types/templates';
import { failedResult, successResult } from '../errors/repository-errors';
import { InvalidArgumentError } from '../errors/repository-errors';

/**
 * FileLinkAccessLogRepository
 * Append-only repository for file link access logs
 */
export class FileLinkAccessLogRepository extends BaseRepository<FileLinkAccessLog> {
  constructor() {
    super({
      collectionName: 'file_link_access_logs',
      softDelete: false, // Access logs are never deleted
    });
  }

  /**
   * Get access logs for a specific link
   *
   * @param context - Security context
   * @param linkId - File link ID
   * @param options - Query options (limit, pagination)
   * @returns Array of access logs
   */
  async getByLinkId(
    context: SecurityContext,
    linkId: string,
    options?: QueryOptions
  ): Promise<RepositoryResult<FileLinkAccessLog[]>> {
    try {
      this.ensureSecurityContext(context);

      if (!linkId || linkId.trim().length === 0) {
        return failedResult(new InvalidArgumentError('Link ID is required'));
      }

      const queryOptions: QueryOptions = {
        where: [{ field: 'linkId', operator: '==', value: linkId }],
        orderBy: { field: 'accessedAt', direction: 'desc' },
        limit: options?.limit || 100, // Default limit to prevent large queries
        ...options,
      };

      const result = await this.getAll(context, queryOptions);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log - log viewing access logs
      await this.logAudit(context, 'list', null, {
        operation: 'getAccessLogsByLinkId',
        linkId, // Safe to log - ID not PHI
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get access logs for link');
    }
  }

  /**
   * Get recent access logs across all links (for monitoring)
   *
   * @param context - Security context
   * @param limitCount - Maximum number of logs to return
   * @returns Array of recent access logs
   */
  async getRecentLogs(
    context: SecurityContext,
    limitCount: number = 50
  ): Promise<RepositoryResult<FileLinkAccessLog[]>> {
    try {
      this.ensureSecurityContext(context);

      if (limitCount < 1 || limitCount > 500) {
        return failedResult(
          new InvalidArgumentError('Limit must be between 1 and 500')
        );
      }

      const queryOptions: QueryOptions = {
        orderBy: { field: 'accessedAt', direction: 'desc' },
        limit: limitCount,
      };

      const result = await this.getAll(context, queryOptions);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log
      await this.logAudit(context, 'list', null, {
        operation: 'getRecentAccessLogs',
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get recent access logs');
    }
  }

  /**
   * Get failed access attempts for security monitoring
   *
   * @param context - Security context
   * @param limitCount - Maximum number of logs to return
   * @returns Array of failed access attempts
   */
  async getFailedAttempts(
    context: SecurityContext,
    limitCount: number = 50
  ): Promise<RepositoryResult<FileLinkAccessLog[]>> {
    try {
      this.ensureSecurityContext(context);

      if (limitCount < 1 || limitCount > 500) {
        return failedResult(
          new InvalidArgumentError('Limit must be between 1 and 500')
        );
      }

      const queryOptions: QueryOptions = {
        where: [{ field: 'wasSuccessful', operator: '==', value: false }],
        orderBy: { field: 'accessedAt', direction: 'desc' },
        limit: limitCount,
      };

      const result = await this.getAll(context, queryOptions);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log - security monitoring
      await this.logAudit(context, 'list', null, {
        operation: 'getFailedAccessAttempts',
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get failed access attempts');
    }
  }

  /**
   * Get access logs by IP address (for security monitoring)
   *
   * @param context - Security context
   * @param ipAddress - IP address to search for
   * @param limitCount - Maximum number of logs to return
   * @returns Array of access logs from the IP
   */
  async getByIpAddress(
    context: SecurityContext,
    ipAddress: string,
    limitCount: number = 50
  ): Promise<RepositoryResult<FileLinkAccessLog[]>> {
    try {
      this.ensureSecurityContext(context);

      if (!ipAddress || ipAddress.trim().length === 0) {
        return failedResult(new InvalidArgumentError('IP address is required'));
      }

      if (limitCount < 1 || limitCount > 500) {
        return failedResult(
          new InvalidArgumentError('Limit must be between 1 and 500')
        );
      }

      const queryOptions: QueryOptions = {
        where: [{ field: 'ipAddress', operator: '==', value: ipAddress }],
        orderBy: { field: 'accessedAt', direction: 'desc' },
        limit: limitCount,
      };

      const result = await this.getAll(context, queryOptions);

      if (!result.success) {
        return failedResult(result.error);
      }

      // Audit log - security monitoring
      await this.logAudit(context, 'list', null, {
        operation: 'getAccessLogsByIpAddress',
        ipAddress, // Not PHI - network metadata
        count: result.data.data.length,
      });

      return successResult(result.data.data);
    } catch (error) {
      return failedResult(error, 'Failed to get access logs by IP address');
    }
  }

  /**
   * Override update to prevent modification of access logs
   * Access logs are immutable
   */
  async update(): Promise<RepositoryResult<FileLinkAccessLog>> {
    return failedResult(
      new InvalidArgumentError('Access logs cannot be modified')
    );
  }

  /**
   * Override delete to prevent deletion of access logs
   * Access logs must be retained for HIPAA compliance
   */
  async delete(): Promise<RepositoryResult<void>> {
    return failedResult(
      new InvalidArgumentError('Access logs cannot be deleted')
    );
  }

  /**
   * Override create to add additional audit logging
   */
  async create(
    context: SecurityContext,
    data: Omit<FileLinkAccessLog, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<FileLinkAccessLog>> {
    // Call parent create
    const result = await super.create(context, data, customId);

    // Additional audit logging for access log creation
    if (result.success) {
      await this.logAudit(context, 'create', result.data.id, {
        operation: 'logFileAccess',
        linkId: result.data.linkId, // Safe to log - ID not PHI
        wasSuccessful: result.data.wasSuccessful,
        failureReason: result.data.failureReason,
      });
    }

    return result;
  }
}

/**
 * Singleton instance
 */
let fileLinkAccessLogRepositoryInstance: FileLinkAccessLogRepository | null = null;

/**
 * Get the FileLinkAccessLogRepository singleton instance
 */
export function getFileLinkAccessLogRepository(): FileLinkAccessLogRepository {
  if (!fileLinkAccessLogRepositoryInstance) {
    fileLinkAccessLogRepositoryInstance = new FileLinkAccessLogRepository();
  }
  return fileLinkAccessLogRepositoryInstance;
}
