/**
 * Integration Sync Service
 * Handles email/calendar bidirectional sync with rate limits, credential validation,
 * conflict detection, retry/backoff, and audit logging.
 *
 * HIPAA: Only IDs/timestamps/hashes are processed. Do NOT log message bodies or PHI.
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService } from './AuditLogService';
import type {
  IntegrationCredential,
  SyncBatch,
  SyncConflict,
  SyncRecord,
  SyncResult,
} from '../types/integrations';
// Re-export result type for consumers that import from this service module
export type { SyncResult } from '../types/integrations';
import { withExponentialBackoff } from '../utils/backoff';
import { withTimeout } from '../lib/network';
import type { SyncStateStore } from '../data/repositories/integration-sync-state-repository';
import { getSyncStateStore } from '../data/repositories/integration-sync-state-repository';

export interface IntegrationSyncAdapter<T extends SyncRecord> {
  type: 'email' | 'calendar';
  credential: IntegrationCredential;
  fetchRemoteChanges: (cursor?: string) => Promise<SyncBatch<T>>;
  fetchLocalChanges: (cursor?: string) => Promise<SyncBatch<T>>;
  applyRemoteChanges: (records: T[]) => Promise<void>;
  pushLocalChanges?: (records: T[]) => Promise<{ created: number; updated: number; skipped?: number }>;
  acknowledgeSync?: (cursor?: string) => Promise<void>;
}

export interface SyncOptions {
  direction: 'pull' | 'push' | 'bidirectional';
  cursor?: string;
  allowConflicts?: boolean;
  maxConflicts?: number;
  timeoutMs?: number;
}

const MAX_CONFLICTS_DEFAULT = 25;
const DEFAULT_SYNC_TIMEOUT_MS = 15_000;

export class IntegrationSyncService {
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private syncStore: SyncStateStore;

  constructor(
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService,
    syncStore?: SyncStateStore
  ) {
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
    this.syncStore = syncStore || getSyncStateStore();
  }

  /**
   * Run a sync for email or calendar data.
   */
  async sync<T extends SyncRecord>(
    context: SecurityContext,
    adapter: IntegrationSyncAdapter<T>,
    options: SyncOptions
  ): Promise<SyncResult> {
    const errors: string[] = [];
    const integrationId = adapter.credential.integrationId || adapter.credential.provider;

    const credentialValidation = this.validateCredentials(context, adapter.credential);
    if (!credentialValidation.valid) {
      await this.audit.logAction(context, {
        action: 'integration',
        entityType: 'integration',
        entityId: adapter.type,
        entityName: adapter.type,
        metadata: {
          errors: credentialValidation.errors,
          direction: options.direction,
        },
      });

      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        conflicts: [],
        retried: 0,
        errors: credentialValidation.errors,
      };
    }

    const limit = await this.rateLimit.checkLimit('integration_sync', context.userId, context.businessId);
    if (!limit.allowed) {
      return {
        success: false,
        created: 0,
        updated: 0,
        skipped: 0,
        conflicts: [],
        retried: 0,
        backoffMs: limit.resetAt.getTime() - Date.now(),
        errors: [limit.message || 'Integration sync rate limit exceeded'],
      };
    }

    const conflicts: SyncConflict[] = [];
    let created = 0;
    let updated = 0;
    let skipped = 0;
    let retried = 0;
    const persisted = await this.syncStore.load(
      context.businessId,
      integrationId,
      adapter.credential.provider
    );

    let resumeCursor = options.cursor ?? persisted?.cursor;
    const timeoutMs = options.timeoutMs ?? DEFAULT_SYNC_TIMEOUT_MS;

    const backoffResult = await withExponentialBackoff({
      operation: async () => {
        const remote = await withTimeout(
          adapter.fetchRemoteChanges(resumeCursor),
          timeoutMs,
          'Remote sync timed out'
        );
        const local = await withTimeout(
          adapter.fetchLocalChanges(resumeCursor),
          timeoutMs,
          'Local sync fetch timed out'
        );

        const conflictList = this.detectConflicts(local.items, remote.items, options.maxConflicts);
        conflicts.push(...conflictList);

        const recordsToApply = options.allowConflicts
          ? remote.items
          : remote.items.filter(
              (item) => !conflictList.find((conflict) => conflict.itemId === item.id)
            );

        if (options.direction === 'pull' || options.direction === 'bidirectional') {
          await withTimeout(
            adapter.applyRemoteChanges(recordsToApply),
            timeoutMs,
            'Applying remote changes timed out'
          );
          created += recordsToApply.length;
          skipped += conflictList.length;
        }

        if (
          (options.direction === 'push' || options.direction === 'bidirectional') &&
          adapter.pushLocalChanges
        ) {
          const pushResult = await withTimeout(
            adapter.pushLocalChanges(local.items),
            timeoutMs,
            'Pushing local changes timed out'
          );
          created += pushResult.created;
          updated += pushResult.updated;
          skipped += pushResult.skipped || 0;
        }

        resumeCursor = remote.cursor;

        if (adapter.acknowledgeSync) {
          await withTimeout(
            adapter.acknowledgeSync(remote.cursor),
            timeoutMs,
            'Acknowledging sync timed out'
          );
        }

        await this.rateLimit.recordAction('integration_sync', context.userId, context.businessId);
      },
      onRetry: () => {
        retried += 1;
      },
      shouldRetry: (error) => error instanceof Error || typeof error === 'string',
    });

    if (backoffResult.error) {
      const message =
        backoffResult.error instanceof Error
          ? backoffResult.error.message
          : typeof backoffResult.error === 'string'
            ? backoffResult.error
            : 'Sync failed after retries';
      errors.push(message);
    }

    await this.syncStore.save(context.businessId, {
      integrationId,
      provider: adapter.credential.provider,
      cursor: resumeCursor,
      lastStatus: backoffResult.error ? 'failed' : 'success',
      lastSyncedAt: new Date(),
      backoffMs: backoffResult.backoffMs,
      retried,
    });

    await this.audit.logAction(context, {
      action: 'integration',
      entityType: 'integration',
      entityId: adapter.type,
      entityName: adapter.type,
      metadata: {
        created,
        updated,
        skipped,
        retried,
        conflicts: conflicts.length,
        resumeCursor,
        backoffMs: backoffResult.backoffMs,
        timeoutMs,
      },
    });

    return {
      success: !backoffResult.error,
      created,
      updated,
      skipped,
      conflicts,
      retried,
      backoffMs: backoffResult.backoffMs,
      resumeCursor,
      errors: errors.length ? errors : undefined,
    };
  }

  /**
   * Validate credentials are tenant-scoped and not expired.
   */
  validateCredentials(
    context: SecurityContext,
    credential: IntegrationCredential
  ): { valid: boolean; errors?: string[] } {
    const errors: string[] = [];
    const jwtClaims = this.decodeJwtClaims(credential.accessToken);

    if (credential.businessId !== context.businessId) {
      errors.push('Credential business mismatch');
    }

    if (credential.tenantScoped === false) {
      errors.push('Integration credential is not tenant scoped');
    }

    if (credential.staffId && credential.staffId !== context.userId) {
      errors.push('Integration credential not issued to this staff member');
    }

    if (!credential.accessToken) {
      errors.push('Missing access token');
    }

    const now = Date.now();
    if (credential.expiresAt && credential.expiresAt.getTime() < now) {
      errors.push('Integration token expired');
    }

    if (jwtClaims?.exp && jwtClaims.exp * 1000 < now) {
      errors.push('Integration token expired (exp claim)');
    }

    const tokenTenant = this.extractBusinessIdFromClaims(jwtClaims);
    if (tokenTenant && tokenTenant !== context.businessId) {
      errors.push('Integration token tenant mismatch');
    }

    if (
      jwtClaims &&
      !this.isAudienceValid(jwtClaims.aud || (jwtClaims as { audience?: unknown }).audience)
    ) {
      errors.push('Integration token audience mismatch');
    } else if (!jwtClaims && !this.validateJwtAudience(credential.accessToken, context.businessId)) {
      errors.push('Integration token audience mismatch');
    }

    return {
      valid: errors.length === 0,
      errors: errors.length ? errors : undefined,
    };
  }

  /**
   * Detect conflicts by comparing updated timestamps.
   */
  private detectConflicts<T extends SyncRecord>(
    local: T[],
    remote: T[],
    maxConflicts?: number
  ): SyncConflict[] {
    const conflicts: SyncConflict[] = [];
    const conflictCap = maxConflicts || MAX_CONFLICTS_DEFAULT;

    for (const remoteItem of remote) {
      if (conflicts.length >= conflictCap) {
        break;
      }

      const localItem = local.find((item) => item.id === remoteItem.id);
      if (!localItem) {
        continue;
      }

      const localHash = localItem.hash || localItem.remoteChecksum;
      const remoteHash = remoteItem.hash || remoteItem.remoteChecksum;

      if (
        localHash &&
        remoteHash &&
        localHash !== remoteHash &&
        localItem.updatedAt.getTime() === remoteItem.updatedAt.getTime()
      ) {
        conflicts.push({
          itemId: remoteItem.id,
          localUpdatedAt: localItem.updatedAt,
          remoteUpdatedAt: remoteItem.updatedAt,
          resolution: 'manual',
          reason: 'Checksum mismatch',
        });
        continue;
      }

      if (localItem.updatedAt.getTime() !== remoteItem.updatedAt.getTime()) {
        conflicts.push({
          itemId: remoteItem.id,
          localUpdatedAt: localItem.updatedAt,
          remoteUpdatedAt: remoteItem.updatedAt,
          resolution: localItem.updatedAt > remoteItem.updatedAt ? 'local' : 'remote',
          reason: 'Timestamp conflict',
        });
      }
    }

    return conflicts;
  }

  private decodeJwtClaims(token: string): Record<string, any> | null {
    if (!token || !token.includes('.')) {
      return null;
    }

    const parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const decode =
        typeof atob === 'function'
          ? atob
          : (value: string) => Buffer.from(value, 'base64').toString('utf-8');

      const payloadJson = decode(base64);
      return JSON.parse(payloadJson) as Record<string, any>;
    } catch {
      return null;
    }
  }

  private extractBusinessIdFromClaims(claims: Record<string, any> | null): string | undefined {
    if (!claims) return undefined;
    return (
      claims.businessId ||
      claims.bid ||
      claims.tenant ||
      claims.tid ||
      claims.organization ||
      undefined
    );
  }

  private isAudienceValid(audience: unknown): boolean {
    if (!audience) {
      return true;
    }

    if (Array.isArray(audience)) {
      return audience.includes('scheduler-crm');
    }

    if (typeof audience === 'string') {
      return audience === 'scheduler-crm';
    }

    return true;
  }

  /**
   * Validate JWT audience for tenant scoping.
   * Returns true for non-JWT tokens to avoid blocking legacy credentials.
   */
  private validateJwtAudience(token: string, businessId: string): boolean {
    if (!token || !token.includes('.')) {
      return true;
    }

    const parts = token.split('.');
    if (parts.length < 2) {
      return true;
    }

    try {
      const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const decode =
        typeof atob === 'function'
          ? atob
          : (value: string) => Buffer.from(value, 'base64').toString('utf-8');

      const payloadJson = decode(base64);
      const payload = JSON.parse(payloadJson);
      const audience = payload.aud || payload.audience;
      const tenant = payload.businessId || payload.bid || payload.tenant;

      if (tenant && tenant !== businessId) {
        return false;
      }

      if (audience && Array.isArray(audience) && !audience.includes('scheduler-crm')) {
        return false;
      }

      return true;
    } catch {
      return true; // Do not block if parsing fails; token may not be JWT
    }
  }
}

let integrationSyncService: IntegrationSyncService | null = null;

export function getIntegrationSyncService(): IntegrationSyncService {
  if (!integrationSyncService) {
    integrationSyncService = new IntegrationSyncService();
  }
  return integrationSyncService;
}
