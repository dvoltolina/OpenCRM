/**
 * Duplicate Detection Service
 * Business logic for detecting and merging duplicate entities
 *
 * Agent CRM-27 Implementation
 * Dependencies: CRM-03 (leads), CRM-05 (clients)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { getLeadRepository } from '../data/repositories/lead-repository';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getCompanyRepository } from '../data/repositories/company-repository';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Lead, Client, Company } from '../types/models';
import { getAuditLogService, type AuditLogService } from './AuditLogService';

// ============================================
// Types
// ============================================

export type EntityType = 'lead' | 'client' | 'company';
export type MatchType = 'email' | 'phone' | 'name' | 'compound';

export interface DuplicateMatch<T = Lead | Client | Company> {
  /** The potential duplicate entity */
  entity: T;
  /** Match type(s) that triggered detection */
  matchTypes: MatchType[];
  /** Overall confidence score 0-100 */
  confidence: number;
  /** Details about what matched */
  matchDetails: {
    email?: boolean;
    phone?: boolean;
    name?: boolean;
    company?: boolean;
  };
}

export interface FindDuplicatesOptions {
  /** Entity type to search for duplicates */
  entityType: EntityType;
  /** Minimum confidence score to return (default: 60) */
  minConfidence?: number;
  /** Maximum number of results to return (default: 10) */
  limit?: number;
  /** Exclude this entity ID from results */
  excludeId?: string;
}

export interface MergeOptions {
  /** Entity type being merged */
  entityType: EntityType;
  /** The primary entity to keep */
  primaryId: string;
  /** The duplicate entity to merge and archive */
  secondaryId: string;
  /** Field-level merge preferences: primaryId's field value or secondaryId's field value */
  fieldPreferences?: Record<string, 'primary' | 'secondary'>;
  /** Whether to transfer related records (default: true) */
  transferRelatedRecords?: boolean;
}

export interface MergeResult {
  /** The merged entity */
  merged: Lead | Client | Company;
  /** Number of related records transferred */
  recordsTransferred: number;
  /** IDs of transferred deals */
  transferredDealIds: string[];
  /** IDs of transferred activities */
  transferredActivityIds: string[];
}

// ============================================
// Duplicate Detection Service
// ============================================

export class DuplicateDetectionService {
  private audit: AuditLogService;

  constructor(auditService?: AuditLogService) {
    this.audit = auditService || getAuditLogService();
  }

  /**
   * Find potential duplicates for a given entity
   */
  async findDuplicates<T extends Lead | Client | Company>(
    context: SecurityContext,
    entity: T,
    options: FindDuplicatesOptions
  ): Promise<DuplicateMatch<T>[]> {
    const { entityType, minConfidence = 60, limit = 10, excludeId } = options;

    const matches: DuplicateMatch<T>[] = [];

    // Get appropriate repository
    const repo =
      entityType === 'lead'
        ? getLeadRepository()
        : entityType === 'client'
        ? getContactRepository()
        : getCompanyRepository();

    // Search by email (exact match - highest confidence)
    if ('email' in entity && entity.email) {
      const emailResult = await repo.search(context, entity.email);
      if (emailResult.success) {
        const candidates = Array.isArray(emailResult.data) ? emailResult.data : (emailResult.data as any).data || [];
        for (const candidate of candidates) {
          if (excludeId && candidate.id === excludeId) continue;
          if (candidate.id === entity.id) continue;

          const candidateEmail = 'email' in candidate ? candidate.email : undefined;
          if (candidateEmail && candidateEmail.toLowerCase() === entity.email.toLowerCase()) {
            const score = this.calculateMatchScore(entity, candidate, entityType);
            if (score >= minConfidence) {
              matches.push({
                entity: candidate as T,
                matchTypes: ['email'],
                confidence: score,
                matchDetails: {
                  email: true,
                  phone: this.phoneMatches(entity, candidate),
                  name: this.nameMatches(entity, candidate, entityType),
                  company: this.companyMatches(entity, candidate),
                },
              });
            }
          }
        }
      }
    }

    // Search by phone (normalized match)
    if ('phone' in entity && entity.phone) {
      const normalizedPhone = this.normalizePhone(entity.phone);
      const phoneResult = await repo.search(context, normalizedPhone);
      if (phoneResult.success) {
        const candidates = Array.isArray(phoneResult.data) ? phoneResult.data : (phoneResult.data as any).data || [];
        for (const candidate of candidates) {
          if (excludeId && candidate.id === excludeId) continue;
          if (candidate.id === entity.id) continue;

          // Skip if already matched by email
          if (matches.some((m) => m.entity.id === candidate.id)) continue;

          const candidatePhone = 'phone' in candidate ? candidate.phone : undefined;
          if (candidatePhone && this.normalizePhone(candidatePhone) === normalizedPhone) {
            const score = this.calculateMatchScore(entity, candidate, entityType);
            if (score >= minConfidence) {
              matches.push({
                entity: candidate as T,
                matchTypes: ['phone'],
                confidence: score,
                matchDetails: {
                  email: this.emailMatches(entity, candidate),
                  phone: true,
                  name: this.nameMatches(entity, candidate, entityType),
                  company: this.companyMatches(entity, candidate),
                },
              });
            }
          }
        }
      }
    }

    // Search by name (fuzzy match)
    const searchName = this.getSearchName(entity, entityType);
    if (searchName) {
      const nameResult = await repo.search(context, searchName);
      if (nameResult.success) {
        const candidates = Array.isArray(nameResult.data) ? nameResult.data : (nameResult.data as any).data || [];
        for (const candidate of candidates) {
          if (excludeId && candidate.id === excludeId) continue;
          if (candidate.id === entity.id) continue;

          // Skip if already matched
          if (matches.some((m) => m.entity.id === candidate.id)) continue;

          if (this.nameMatches(entity, candidate, entityType)) {
            const score = this.calculateMatchScore(entity, candidate, entityType);
            if (score >= minConfidence) {
              matches.push({
                entity: candidate as T,
                matchTypes: ['name'],
                confidence: score,
                matchDetails: {
                  email: this.emailMatches(entity, candidate),
                  phone: this.phoneMatches(entity, candidate),
                  name: true,
                  company: this.companyMatches(entity, candidate),
                },
              });
            }
          }
        }
      }
    }

    // Sort by confidence (highest first) and limit results
    return matches.sort((a, b) => b.confidence - a.confidence).slice(0, limit);
  }

  /**
   * Calculate similarity score between two entities
   */
  calculateMatchScore(
    entityA: Lead | Client | Company,
    entityB: Lead | Client | Company,
    entityType: EntityType
  ): number {
    let score = 0;
    let factors = 0;

    // Email match (highest weight)
    const emailMatch = this.emailMatches(entityA, entityB);
    if (emailMatch !== undefined) {
      factors++;
      score += emailMatch ? 100 : 0;
    }

    // Phone match (high weight)
    const phoneMatch = this.phoneMatches(entityA, entityB);
    if (phoneMatch !== undefined) {
      factors++;
      score += phoneMatch ? 90 : 0;
    }

    // Name match (medium weight)
    const nameMatch = this.nameMatches(entityA, entityB, entityType);
    if (nameMatch !== undefined) {
      factors++;
      score += nameMatch ? 70 : 0;
    }

    // Company match (additional boost)
    const companyMatch = this.companyMatches(entityA, entityB);
    if (companyMatch !== undefined) {
      factors++;
      score += companyMatch ? 80 : 0;
    }

    // Calculate average score
    const avgScore = factors > 0 ? score / factors : 0;

    // Apply compound bonus if multiple factors match
    if (factors >= 2) {
      const matchingFactors = [emailMatch, phoneMatch, nameMatch, companyMatch].filter(
        (m) => m === true
      ).length;

      if (matchingFactors >= 2) {
        // Boost score by 10% for compound matches
        return Math.min(100, Math.round(avgScore * 1.1));
      }
    }

    return Math.round(avgScore);
  }

  /**
   * Merge two entities, keeping the primary and archiving the secondary
   */
  async merge(context: SecurityContext, options: MergeOptions): Promise<MergeResult> {
    const {
      entityType,
      primaryId,
      secondaryId,
      fieldPreferences = {},
      transferRelatedRecords = true,
    } = options;

    // Validate entities exist
    const repo =
      entityType === 'lead'
        ? getLeadRepository()
        : entityType === 'client'
        ? getContactRepository()
        : getCompanyRepository();

    const primaryResult = await repo.getById(context, primaryId);
    const secondaryResult = await repo.getById(context, secondaryId);

    if (!primaryResult.success) {
      throw new Error(`Primary entity not found: ${primaryResult.error.message}`);
    }
    if (!secondaryResult.success) {
      throw new Error(`Secondary entity not found: ${secondaryResult.error.message}`);
    }

    const primary = primaryResult.data;
    const secondary = secondaryResult.data;

    // Build merged entity with field preferences
    const merged = this.buildMergedEntity(primary, secondary, fieldPreferences);

    // Update primary entity
    const updateResult = await repo.update(context, primaryId, merged);
    if (!updateResult.success) {
      throw new Error(`Failed to update primary entity: ${updateResult.error.message}`);
    }

    const transferredDealIds: string[] = [];
    const transferredActivityIds: string[] = [];

    // Transfer related records if requested
    if (transferRelatedRecords) {
      // Transfer deals
      if (entityType === 'client') {
        const dealRepo = getDealRepository();
        const dealsResult = await dealRepo.getByClient(context, secondaryId);

        if (dealsResult.success) {
          for (const deal of dealsResult.data) {
            await dealRepo.update(context, deal.id, {
              clientId: primaryId,
              clientName:
                'firstName' in primary
                  ? `${primary.firstName} ${primary.lastName}`
                  : undefined,
            });
            transferredDealIds.push(deal.id);
          }
        }
      }

      // Transfer activities
      const activityRepo = getActivityRepository();
      const idField =
        entityType === 'lead'
          ? 'leadId'
          : entityType === 'client'
          ? 'clientId'
          : 'companyId';

      const activitiesResult =
        entityType === 'lead'
          ? await activityRepo.getByLead(context, secondaryId, { limit: undefined })
          : entityType === 'client'
          ? await activityRepo.getByClient(context, secondaryId, { limit: undefined })
          : await activityRepo.getByCompany(context, secondaryId, { limit: undefined });

      if (activitiesResult.success) {
        const linkedActivities = activitiesResult.data.data;

        for (const activity of linkedActivities) {
          await activityRepo.update(context, activity.id, {
            [idField]: primaryId,
          });
          transferredActivityIds.push(activity.id);
        }
      }
    }

    // Log merge activity
    const activityRepo = getActivityRepository();
    await activityRepo.create(context, {
      type: 'note',
      title: `${entityType.charAt(0).toUpperCase() + entityType.slice(1)} Merged`,
      description: `Merged duplicate ${entityType} (ID: ${secondaryId}) into this record. ${transferredDealIds.length} deals and ${transferredActivityIds.length} activities were transferred.`,
      ...(entityType === 'client' ? { clientId: primaryId } : {}),
      ...(entityType === 'lead' ? { leadId: primaryId } : {}),
      ...(entityType === 'company' ? { companyId: primaryId } : {}),
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    // Audit merge without PHI payload
    const auditEntityType: 'lead' | 'contact' | 'company' =
      entityType === 'client' ? 'contact' : entityType;
    try {
      await this.audit.logAction(context, {
        action: 'merge',
        entityType: auditEntityType,
        entityId: primaryId,
        metadata: {
          mergedFromId: secondaryId,
          transferredDealIds,
          transferredActivityIds,
        },
      });
    } catch {
      // Audit failures should not block the merge workflow
    }

    // Archive secondary entity (soft delete by updating tags)
    await repo.update(context, secondaryId, {
      tags: [
        ...((secondary.tags as string[]) || []),
        'MERGED',
        `MERGED_INTO:${primaryId}`,
      ],
    });

    return {
      merged: updateResult.data,
      recordsTransferred: transferredDealIds.length + transferredActivityIds.length,
      transferredDealIds,
      transferredActivityIds,
    };
  }

  // ============================================
  // Private Helper Methods
  // ============================================

  /**
   * Build merged entity from two entities with field preferences
   */
  private buildMergedEntity(
    primary: any,
    secondary: any,
    fieldPreferences: Record<string, 'primary' | 'secondary'>
  ): any {
    const merged = { ...primary };

    // Apply field preferences
    for (const [field, preference] of Object.entries(fieldPreferences)) {
      if (preference === 'secondary' && secondary[field] !== undefined) {
        merged[field] = secondary[field];
      }
    }

    // Merge tags (combine unique tags)
    if (primary.tags || secondary.tags) {
      const allTags = [...(primary.tags || []), ...(secondary.tags || [])];
      merged.tags = Array.from(new Set(allTags));
    }

    // Merge notes (combine if both present)
    if (primary.notes && secondary.notes && primary.notes !== secondary.notes) {
      merged.notes = `${primary.notes}\n\n--- Merged from duplicate record ---\n${secondary.notes}`;
    } else if (!primary.notes && secondary.notes) {
      merged.notes = secondary.notes;
    }

    // Similar logic for crmNotes if present
    if ('crmNotes' in primary || 'crmNotes' in secondary) {
      if (primary.crmNotes && secondary.crmNotes && primary.crmNotes !== secondary.crmNotes) {
        merged.crmNotes = `${primary.crmNotes}\n\n--- Merged from duplicate record ---\n${secondary.crmNotes}`;
      } else if (!primary.crmNotes && secondary.crmNotes) {
        merged.crmNotes = secondary.crmNotes;
      }
    }

    return merged;
  }

  /**
   * Check if emails match
   */
  private emailMatches(
    entityA: Lead | Client | Company,
    entityB: Lead | Client | Company
  ): boolean | undefined {
    const emailA = 'email' in entityA ? entityA.email : undefined;
    const emailB = 'email' in entityB ? entityB.email : undefined;

    if (!emailA || !emailB) return undefined;

    return emailA.toLowerCase() === emailB.toLowerCase();
  }

  /**
   * Check if phones match (normalized)
   */
  private phoneMatches(
    entityA: Lead | Client | Company,
    entityB: Lead | Client | Company
  ): boolean | undefined {
    const phoneA = 'phone' in entityA ? entityA.phone : undefined;
    const phoneB = 'phone' in entityB ? entityB.phone : undefined;

    if (!phoneA || !phoneB) return undefined;

    return this.normalizePhone(phoneA) === this.normalizePhone(phoneB);
  }

  /**
   * Check if names match
   */
  private nameMatches(
    entityA: Lead | Client | Company,
    entityB: Lead | Client | Company,
    entityType: EntityType
  ): boolean | undefined {
    const nameA = this.getSearchName(entityA, entityType);
    const nameB = this.getSearchName(entityB, entityType);

    if (!nameA || !nameB) return undefined;

    return nameA.toLowerCase() === nameB.toLowerCase();
  }

  private getCompanyNameValue(entity: Lead | Client | Company): string | undefined {
    if ('companyName' in entity && typeof (entity as Lead | Client).companyName === 'string') {
      return (entity as Lead | Client).companyName || undefined;
    }
    if ('name' in entity && typeof (entity as Company).name === 'string') {
      return (entity as Company).name || undefined;
    }
    return undefined;
  }

  /**
   * Check if company names match
   */
  private companyMatches(
    entityA: Lead | Client | Company,
    entityB: Lead | Client | Company
  ): boolean | undefined {
    const companyA = this.getCompanyNameValue(entityA);
    const companyB = this.getCompanyNameValue(entityB);

    if (!companyA || !companyB) return undefined;

    return companyA.toLowerCase() === companyB.toLowerCase();
  }

  /**
   * Get searchable name from entity
   */
  private getSearchName(
    entity: Lead | Client | Company,
    entityType: EntityType
  ): string | undefined {
    if (entityType === 'company') {
      return this.getCompanyNameValue(entity);
    }

    // For lead and client
    if ('firstName' in entity && 'lastName' in entity) {
      return `${entity.firstName} ${entity.lastName}`;
    }

    return undefined;
  }

  /**
   * Normalize phone number for comparison (remove all non-digits)
   */
  private normalizePhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}

// ============================================
// Singleton Export
// ============================================

let duplicateDetectionServiceInstance: DuplicateDetectionService | null = null;

export function getDuplicateDetectionService(): DuplicateDetectionService {
  if (!duplicateDetectionServiceInstance) {
    duplicateDetectionServiceInstance = new DuplicateDetectionService();
  }
  return duplicateDetectionServiceInstance;
}
