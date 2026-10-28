/**
 * SMS Opt-Out Repository
 * Manages SMS opt-out records for TCPA compliance
 *
 * HIPAA/TCPA Compliance:
 * - Phone numbers normalized (digits only)
 * - Opt-out records maintained indefinitely
 * - Audit logging for all operations
 * - Tenant isolation via businessId
 *
 * Storage Path: businesses/{businessId}/sms_opt_outs/{optOutId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { SmsOptOut, OptOutStatus, OptOutSource } from '../../types/sms';
import { normalizePhone } from '../../types/sms';
import { successResult, failedResult, ValidationError } from '../errors/repository-errors';

// ============================================
// Repository Implementation
// ============================================

export class SmsOptOutRepository extends BaseRepository<SmsOptOut> {
  constructor() {
    super({
      collectionName: 'sms_opt_outs',
      softDelete: false, // Opt-out records must be maintained per TCPA
    });
  }

  /**
   * Check opt-out status for a phone number
   */
  async checkOptOut(
    context: SecurityContext,
    phone: string
  ): Promise<RepositoryResult<OptOutStatus>> {
    try {
      const normalized = normalizePhone(phone);
      if (!normalized || normalized.length < 10) {
        return failedResult(
          ValidationError.fromErrors([{ field: 'phone', message: 'Invalid phone number' }])
        );
      }

      const options: QueryOptions = {
        where: [{ field: 'phone', operator: '==', value: normalized }],
        limit: 1,
      };

      const result = await this.getAll(context, options);
      if (!result.success) {
        return { success: false, data: null, error: result.error };
      }

      const record = result.data.data[0];
      if (!record) {
        // No record means pending (not explicitly opted in or out)
        return successResult('pending' as OptOutStatus);
      }

      return successResult(record.status);
    } catch (error) {
      return failedResult(error, 'Failed to check opt-out status');
    }
  }

  /**
   * Get opt-out record by phone number
   */
  async getByPhone(
    context: SecurityContext,
    phone: string
  ): Promise<RepositoryResult<SmsOptOut | null>> {
    const normalized = normalizePhone(phone);

    const options: QueryOptions = {
      where: [{ field: 'phone', operator: '==', value: normalized }],
      limit: 1,
    };

    const result = await this.getAll(context, options);
    if (!result.success) {
      return { success: false, data: null, error: result.error };
    }

    const record = result.data.data[0] || null;
    return successResult(record);
  }

  /**
   * Record an opt-out (STOP request)
   */
  async optOut(
    context: SecurityContext,
    phone: string,
    source: OptOutSource
  ): Promise<RepositoryResult<SmsOptOut>> {
    try {
      const normalized = normalizePhone(phone);
      if (!normalized || normalized.length < 10) {
        return failedResult(
          ValidationError.fromErrors([{ field: 'phone', message: 'Invalid phone number' }])
        );
      }

      // Check if record already exists
      const existingResult = await this.getByPhone(context, normalized);

      if (existingResult.success && existingResult.data) {
        // Update existing record
        return super.update(context, existingResult.data.id, {
          status: 'opted_out',
          optedOutAt: new Date(),
          source,
        });
      }

      // Create new opt-out record
      const optOutData: Omit<SmsOptOut, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        phone: normalized,
        status: 'opted_out',
        optedOutAt: new Date(),
        source,
      };

      return super.create(context, optOutData);
    } catch (error) {
      return failedResult(error, 'Failed to record opt-out');
    }
  }

  /**
   * Record an opt-in (START request)
   */
  async optIn(context: SecurityContext, phone: string): Promise<RepositoryResult<SmsOptOut>> {
    try {
      const normalized = normalizePhone(phone);
      if (!normalized || normalized.length < 10) {
        return failedResult(
          ValidationError.fromErrors([{ field: 'phone', message: 'Invalid phone number' }])
        );
      }

      // Check if record exists
      const existingResult = await this.getByPhone(context, normalized);

      if (existingResult.success && existingResult.data) {
        // Update existing record
        return super.update(context, existingResult.data.id, {
          status: 'opted_in',
          optedInAt: new Date(),
        });
      }

      // Create new opt-in record
      const optInData: Omit<SmsOptOut, 'id' | 'createdAt' | 'updatedAt'> = {
        businessId: context.businessId,
        phone: normalized,
        status: 'opted_in',
        optedInAt: new Date(),
        source: 'api', // Default source for programmatic opt-ins
      };

      return super.create(context, optInData);
    } catch (error) {
      return failedResult(error, 'Failed to record opt-in');
    }
  }

  /**
   * Get all opted-out phone numbers
   */
  async getOptedOut(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<SmsOptOut>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: 'opted_out' }],
      orderBy: { field: 'optedOutAt', direction: 'desc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get opt-out records by status
   */
  async getByStatus(
    context: SecurityContext,
    status: OptOutStatus
  ): Promise<RepositoryResult<PaginatedResult<SmsOptOut>>> {
    const options: QueryOptions = {
      where: [{ field: 'status', operator: '==', value: status }],
      orderBy: { field: 'createdAt', direction: 'desc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Import opt-outs from a list (e.g., from external source)
   */
  async importOptOuts(
    context: SecurityContext,
    phones: string[]
  ): Promise<RepositoryResult<{ imported: number; skipped: number }>> {
    try {
      let imported = 0;
      let skipped = 0;

      for (const phone of phones) {
        const normalized = normalizePhone(phone);
        if (!normalized || normalized.length < 10) {
          skipped++;
          continue;
        }

        // Check if already exists
        const existingResult = await this.getByPhone(context, normalized);
        if (existingResult.success && existingResult.data?.status === 'opted_out') {
          skipped++;
          continue;
        }

        // Create or update
        const result = await this.optOut(context, normalized, 'import');
        if (result.success) {
          imported++;
        } else {
          skipped++;
        }
      }

      return successResult({ imported, skipped });
    } catch (error) {
      return failedResult(error, 'Failed to import opt-outs');
    }
  }

  /**
   * Check multiple phone numbers at once
   * Returns map of phone -> status
   */
  async checkMultiple(
    context: SecurityContext,
    phones: string[]
  ): Promise<RepositoryResult<Map<string, OptOutStatus>>> {
    try {
      const results = new Map<string, OptOutStatus>();

      // Normalize all phones
      const normalizedPhones = phones.map((p) => normalizePhone(p));

      // Get all opt-out records for this business
      const allRecordsResult = await this.getAll(context, {});
      if (!allRecordsResult.success) {
        return { success: false, data: null, error: allRecordsResult.error };
      }

      // Build lookup map
      const recordMap = new Map<string, SmsOptOut>();
      for (const record of allRecordsResult.data.data) {
        recordMap.set(record.phone, record);
      }

      // Check each phone
      for (let i = 0; i < normalizedPhones.length; i++) {
        const normalized = normalizedPhones[i];
        const originalPhone = phones[i];

        if (!normalized || normalized.length < 10) {
          results.set(originalPhone, 'pending');
          continue;
        }

        const record = recordMap.get(normalized);
        results.set(originalPhone, record?.status || 'pending');
      }

      return successResult(results);
    } catch (error) {
      return failedResult(error, 'Failed to check opt-out statuses');
    }
  }
}

// ============================================
// Singleton Instance
// ============================================

let smsOptOutRepositoryInstance: SmsOptOutRepository | null = null;

export function getSmsOptOutRepository(): SmsOptOutRepository {
  if (!smsOptOutRepositoryInstance) {
    smsOptOutRepositoryInstance = new SmsOptOutRepository();
  }
  return smsOptOutRepositoryInstance;
}
