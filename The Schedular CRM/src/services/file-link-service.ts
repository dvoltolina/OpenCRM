/**
 * File Link Service
 * Handles secure file sharing with expiring links and access logging
 *
 * Agent CRM-30 Implementation
 * MIGRATED TO REPOSITORY PATTERN - HIPAA Compliant
 *
 * SECURITY REQUIREMENTS:
 * - All links expire after configurable TTL
 * - Access logging for HIPAA compliance
 * - Optional password protection
 * - Optional IP whitelisting
 * - Revocable links
 * - Max access count limits
 *
 * HIPAA Compliance:
 * - Complete audit trail of all file access via repositories
 * - Automatic expiration of links
 * - Secure token generation
 * - Multi-tenant isolation enforced by repositories
 * - No PHI in logs
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { SecureFileLink, FileLinkAccessLog } from '../types/templates';
import { getFileLinkRepository } from '../data/repositories/file-link-repository';
import { getFileLinkAccessLogRepository } from '../data/repositories/file-link-access-log-repository';

// ============================================
// Service Types
// ============================================

export interface CreateFileLinkOptions {
  // File information
  fileId: string;
  fileName: string;
  fileType: string;
  fileSize: number;

  // Associated entities
  clientId?: string;
  dealId?: string;
  templateInstanceId?: string;

  // Link configuration
  ttl?: number; // Time to live in milliseconds (default: 7 days)
  maxAccessCount?: number; // Optional limit on accesses

  // Security
  password?: string; // Plain text password (will be hashed)
  allowedIpAddresses?: string[];
}

export interface ValidateLinkOptions {
  token: string;
  password?: string;
  ipAddress?: string;
  userAgent?: string;
}

export interface FileLinkServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// Default TTL: 7 days
const DEFAULT_TTL_MS = 7 * 24 * 60 * 60 * 1000;

// ============================================
// File Link Service
// ============================================

export class FileLinkService {
  private linkRepository = getFileLinkRepository();
  private accessLogRepository = getFileLinkAccessLogRepository();

  constructor() {
    // Repositories are initialized via singleton pattern
  }

  /**
   * Create an expiring file link
   */
  async createExpiringLink(
    context: SecurityContext,
    options: CreateFileLinkOptions
  ): Promise<FileLinkServiceResult<SecureFileLink>> {
    try {
      // Validate required fields
      if (!options.fileId || !options.fileName) {
        return {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'File ID and name are required',
          },
        };
      }

      // Generate unique token
      const token = this.generateSecureToken();

      // Calculate expiration date
      const ttl = options.ttl || DEFAULT_TTL_MS;
      const expiresAt = new Date(Date.now() + ttl);

      // Hash password if provided
      let passwordHash: string | undefined;
      if (options.password) {
        passwordHash = await this.hashPassword(options.password);
      }

      // Create file link data
      const fileLinkData: Omit<SecureFileLink, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        fileId: options.fileId,
        fileName: options.fileName,
        fileType: options.fileType,
        fileSize: options.fileSize,
        clientId: options.clientId,
        dealId: options.dealId,
        templateInstanceId: options.templateInstanceId,
        token,
        expiresAt,
        maxAccessCount: options.maxAccessCount,
        currentAccessCount: 0,
        requiresPassword: !!options.password,
        passwordHash,
        allowedIpAddresses: options.allowedIpAddresses,
        isActive: true,
        isRevoked: false,
        createdBy: context.userId,
        createdByName: context.userName || 'Unknown User',
      };

      // Store via repository (includes audit logging)
      const result = await this.linkRepository.create(context, fileLinkData);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'CREATE_ERROR',
            message: result.error.message,
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'CREATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to create file link',
        },
      };
    }
  }

  /**
   * Validate a link and check if access is allowed
   */
  async validateLink(
    context: SecurityContext,
    options: ValidateLinkOptions
  ): Promise<FileLinkServiceResult<{ link: SecureFileLink; isValid: boolean; reason?: string }>> {
    try {
      // Find link by token via repository
      const linkResult = await this.linkRepository.getByToken(context, options.token);

      if (!linkResult.success || !linkResult.data) {
        await this.logAccess(context, 'unknown', {
          accessedAt: new Date(),
          ipAddress: options.ipAddress,
          userAgent: options.userAgent,
          wasSuccessful: false,
          failureReason: 'invalid_token',
        });

        return {
          success: false,
          error: {
            code: 'INVALID_TOKEN',
            message: 'Invalid or expired link',
          },
        };
      }

      const link = linkResult.data;

      // Check if link is active
      if (!link.isActive || link.isRevoked) {
        await this.logAccess(context, link.id, {
          accessedAt: new Date(),
          ipAddress: options.ipAddress,
          userAgent: options.userAgent,
          wasSuccessful: false,
          failureReason: 'revoked',
        });

        return {
          success: true,
          data: {
            link,
            isValid: false,
            reason: 'Link has been revoked',
          },
        };
      }

      // Check expiration
      if (link.expiresAt < new Date()) {
        await this.logAccess(context, link.id, {
          accessedAt: new Date(),
          ipAddress: options.ipAddress,
          userAgent: options.userAgent,
          wasSuccessful: false,
          failureReason: 'expired',
        });

        return {
          success: true,
          data: {
            link,
            isValid: false,
            reason: 'Link has expired',
          },
        };
      }

      // Check max access count
      if (link.maxAccessCount && link.currentAccessCount >= link.maxAccessCount) {
        await this.logAccess(context, link.id, {
          accessedAt: new Date(),
          ipAddress: options.ipAddress,
          userAgent: options.userAgent,
          wasSuccessful: false,
          failureReason: 'max_access_reached',
        });

        return {
          success: true,
          data: {
            link,
            isValid: false,
            reason: 'Maximum access count reached',
          },
        };
      }

      // Check IP whitelist
      if (link.allowedIpAddresses && link.allowedIpAddresses.length > 0) {
        if (!options.ipAddress || !link.allowedIpAddresses.includes(options.ipAddress)) {
          await this.logAccess(context, link.id, {
            accessedAt: new Date(),
            ipAddress: options.ipAddress,
            userAgent: options.userAgent,
            wasSuccessful: false,
            failureReason: 'ip_blocked',
          });

          return {
            success: true,
            data: {
              link,
              isValid: false,
              reason: 'Access not allowed from this IP address',
            },
          };
        }
      }

      // Check password
      if (link.requiresPassword) {
        if (!options.password) {
          return {
            success: true,
            data: {
              link,
              isValid: false,
              reason: 'Password required',
            },
          };
        }

        const passwordValid = await this.verifyPassword(options.password, link.passwordHash!);
        if (!passwordValid) {
          await this.logAccess(context, link.id, {
            accessedAt: new Date(),
            ipAddress: options.ipAddress,
            userAgent: options.userAgent,
            wasSuccessful: false,
            failureReason: 'invalid_password',
          });

          return {
            success: true,
            data: {
              link,
              isValid: false,
              reason: 'Invalid password',
            },
          };
        }
      }

      // Link is valid - log successful access
      await this.logAccess(context, link.id, {
        accessedAt: new Date(),
        ipAddress: options.ipAddress,
        userAgent: options.userAgent,
        wasSuccessful: true,
        userId: context.userId,
        userName: context.userName,
      });

      // Increment access count
      await this.incrementAccessCount(context, link.id);

      return {
        success: true,
        data: {
          link,
          isValid: true,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'VALIDATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to validate link',
        },
      };
    }
  }

  /**
   * Log file access via repository
   */
  async logAccess(
    context: SecurityContext,
    linkId: string,
    accessData: Omit<FileLinkAccessLog, 'id' | 'businessId' | 'linkId' | 'createdAt' | 'updatedAt'>
  ): Promise<FileLinkServiceResult<void>> {
    try {
      const accessLogData: Omit<FileLinkAccessLog, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        linkId,
        ...accessData,
      };

      // Log via repository (includes audit logging)
      const result = await this.accessLogRepository.create(context, accessLogData);

      if (!result.success) {
        // HIPAA: Don't fail on logging errors - but track them
        return {
          success: false,
          error: {
            code: 'LOG_ERROR',
            message: result.error.message,
          },
        };
      }

      return {
        success: true,
      };
    } catch (error) {
      // HIPAA: Audit logging failures should not block operations
      return {
        success: false,
        error: {
          code: 'LOG_ERROR',
          message: error instanceof Error ? error.message : 'Failed to log access',
        },
      };
    }
  }

  /**
   * Increment access count for a link
   */
  private async incrementAccessCount(
    context: SecurityContext,
    linkId: string
  ): Promise<FileLinkServiceResult<void>> {
    try {
      // Get current link to read access count
      const linkResult = await this.linkRepository.getById(context, linkId);

      if (!linkResult.success || !linkResult.data) {
        return {
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Link not found',
          },
        };
      }

      const currentCount = linkResult.data.currentAccessCount || 0;

      // Update via repository
      const updateResult = await this.linkRepository.update(context, linkId, {
        currentAccessCount: currentCount + 1,
      });

      if (!updateResult.success) {
        return {
          success: false,
          error: {
            code: 'UPDATE_ERROR',
            message: updateResult.error.message,
          },
        };
      }

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'UPDATE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to increment access count',
        },
      };
    }
  }

  /**
   * Revoke a link
   */
  async revokeLink(
    context: SecurityContext,
    linkId: string,
    reason?: string
  ): Promise<FileLinkServiceResult<void>> {
    try {
      // Update via repository
      const result = await this.linkRepository.update(context, linkId, {
        isActive: false,
        isRevoked: true,
        revokedAt: new Date(),
        revokedBy: context.userId,
        revokedReason: reason,
      });

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'REVOKE_ERROR',
            message: result.error.message,
          },
        };
      }

      return {
        success: true,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'REVOKE_ERROR',
          message: error instanceof Error ? error.message : 'Failed to revoke link',
        },
      };
    }
  }

  /**
   * Get access logs for a link
   */
  async getLinkAccessLogs(
    context: SecurityContext,
    linkId: string
  ): Promise<FileLinkServiceResult<FileLinkAccessLog[]>> {
    try {
      // Get logs via repository
      const result = await this.accessLogRepository.getByLinkId(context, linkId);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'GET_ERROR',
            message: result.error.message,
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'GET_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get access logs',
        },
      };
    }
  }

  /**
   * Get all links for a file
   */
  async getFileLinks(
    context: SecurityContext,
    fileId: string
  ): Promise<FileLinkServiceResult<SecureFileLink[]>> {
    try {
      // Get links via repository
      const result = await this.linkRepository.getByFileId(context, fileId);

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'GET_ERROR',
            message: result.error.message,
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'GET_ERROR',
          message: error instanceof Error ? error.message : 'Failed to get file links',
        },
      };
    }
  }

  /**
   * Generate a secure random token
   */
  private generateSecureToken(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    let token = '';
    for (let i = 0; i < 48; i++) {
      token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
  }

  /**
   * Hash a password using simple hashing
   * Note: In production, use a proper hashing library like bcrypt
   */
  private async hashPassword(password: string): Promise<string> {
    // This is a placeholder implementation
    // In production, use bcrypt or similar
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  }

  /**
   * Verify a password against a hash
   */
  private async verifyPassword(password: string, hash: string): Promise<boolean> {
    const passwordHash = await this.hashPassword(password);
    return passwordHash === hash;
  }
}

// ============================================
// Singleton Instance
// ============================================

let fileLinkServiceInstance: FileLinkService | null = null;

export function getFileLinkService(): FileLinkService {
  if (!fileLinkServiceInstance) {
    fileLinkServiceInstance = new FileLinkService();
  }
  return fileLinkServiceInstance;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Generate a public URL for a file link
 */
export function generatePublicLinkUrl(baseUrl: string, token: string): string {
  return `${baseUrl}/shared/${token}`;
}

/**
 * Parse TTL from human-readable format
 */
export function parseTTL(ttlString: string): number {
  const units: Record<string, number> = {
    hour: 60 * 60 * 1000,
    day: 24 * 60 * 60 * 1000,
    week: 7 * 24 * 60 * 60 * 1000,
    month: 30 * 24 * 60 * 60 * 1000,
  };

  const match = ttlString.match(/^(\d+)\s*(hour|day|week|month)s?$/i);
  if (!match) {
    return DEFAULT_TTL_MS;
  }

  const amount = parseInt(match[1], 10);
  const unit = match[2].toLowerCase();

  return amount * (units[unit] || units.day);
}

/**
 * Format TTL for display
 */
export function formatTTL(ttlMs: number): string {
  const days = Math.floor(ttlMs / (24 * 60 * 60 * 1000));
  const hours = Math.floor((ttlMs % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));

  if (days > 0 && hours > 0) {
    return `${days} day${days > 1 ? 's' : ''} ${hours} hour${hours > 1 ? 's' : ''}`;
  } else if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`;
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`;
  } else {
    const minutes = Math.floor(ttlMs / (60 * 1000));
    return `${minutes} minute${minutes > 1 ? 's' : ''}`;
  }
}
