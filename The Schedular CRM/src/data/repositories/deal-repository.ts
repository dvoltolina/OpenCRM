/**
 * Deal Repository
 * Manages sales deals/opportunities with pipeline stage management
 *
 * HIPAA Compliance: All operations require SecurityContext for businessId scoping
 */

import { getDocs, Timestamp } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities } from './access-control';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, isValidDocumentId } from './firestore-utils';
import type { Deal, DealStatus } from '../../types/models';

// ============================================
// Types
// ============================================

export interface DealsByStageResult {
  [stageId: string]: {
    count: number;
    totalValueCents: number;
  };
}

export interface WonValueResult {
  totalValueCents: number;
  dealCount: number;
}

// ============================================
// Validation
// ============================================

const dealValidator: Validator<Deal> = (data: Partial<Deal>): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Check required fields for creation
  if (data.title !== undefined && !data.title?.trim()) {
    errors.push({ field: 'title', message: 'Title is required', code: 'REQUIRED' });
  }

  if (data.valueCents !== undefined && data.valueCents < 0) {
    errors.push({
      field: 'valueCents',
      message: 'Value must be non-negative',
      code: 'INVALID_VALUE',
    });
  }

  if (data.probability !== undefined && (data.probability < 0 || data.probability > 100)) {
    errors.push({
      field: 'probability',
      message: 'Probability must be between 0 and 100',
      code: 'INVALID_VALUE',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Deal Repository
// ============================================

/**
 * Deal Repository
 * Handles CRUD operations for sales deals with pipeline stage management
 */
export class DealRepository extends ShareableRepository<Deal> {
  protected entityName = 'deal';
  protected sensitiveFields: Array<keyof Deal> = ['valueCents', 'wonLostReason', 'notes', 'customFields'];

  constructor() {
    super({ collectionName: 'deals' });
    this.setValidator(dealValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all deals for a pipeline
   */
  async getByPipeline(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [{ field: 'pipelineId', operator: '==', value: pipelineId }],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'pipelineId', operator: '==', value: pipelineId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByPipeline',
        pipelineId,
        count: deals.length,
      });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by pipeline');
    }
  }

  /**
   * Get deals in a specific stage
   */
  async getByStage(
    context: SecurityContext,
    pipelineId: string,
    stageId: string
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }
      if (!isValidDocumentId(stageId)) {
        return failedResult(new InvalidArgumentError('Invalid stage ID', 'stageId'));
      }

      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [
            { field: 'pipelineId', operator: '==', value: pipelineId },
            { field: 'stageId', operator: '==', value: stageId },
          ],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'pipelineId', operator: '==', value: pipelineId },
          { field: 'stageId', operator: '==', value: stageId },
        ],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByStage', pipelineId, stageId });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by stage');
    }
  }

  /**
   * Get deals by status (open, won, lost)
   */
  async getByStatus(
    context: SecurityContext,
    status: DealStatus
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [{ field: 'status', operator: '==', value: status }],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'status', operator: '==', value: status }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByStatus', status });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by status');
    }
  }

  /**
   * Get deals assigned to a user
   */
  async getByAssignee(
    context: SecurityContext,
    assigneeId: string
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!assigneeId) {
        return failedResult(new InvalidArgumentError('Assignee ID is required', 'assigneeId'));
      }

      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [{ field: 'assigneeId', operator: '==', value: assigneeId }],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'assigneeId', operator: '==', value: assigneeId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByAssignee', assigneeId });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by assignee');
    }
  }

  /**
   * Get deals for a client
   */
  async getByClient(
    context: SecurityContext,
    clientId: string
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!isValidDocumentId(clientId)) {
        return failedResult(new InvalidArgumentError('Invalid client ID', 'clientId'));
      }

      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [{ field: 'clientId', operator: '==', value: clientId }],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'clientId', operator: '==', value: clientId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByClient', clientId });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by client');
    }
  }

  /**
   * Get deals for a company
   */
  async getByCompany(
    context: SecurityContext,
    companyId: string
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (!isValidDocumentId(companyId)) {
        return failedResult(new InvalidArgumentError('Invalid company ID', 'companyId'));
      }

      if (this.useLocalDemoData) {
        const deals = this.filterAccessibleDeals(context, this.getLocalDemoPage(context, {
          where: [{ field: 'companyId', operator: '==', value: companyId }],
          orderBy: { field: 'createdAt', direction: 'desc' },
        }).data);
        return successResult(deals);
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'companyId', operator: '==', value: companyId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getByCompany', companyId });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get deals by company');
    }
  }

  /**
   * Get deals with expectedCloseDate within N days
   */
  async getUpcoming(
    context: SecurityContext,
    days: number
  ): Promise<RepositoryResult<Deal[]>> {
    try {
      if (days < 0) {
        return failedResult(new InvalidArgumentError('Days must be non-negative', 'days'));
      }

      const now = new Date();
      const futureDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'open' },
          { field: 'expectedCloseDate', operator: '<=', value: Timestamp.fromDate(futureDate) },
          { field: 'expectedCloseDate', operator: '>=', value: Timestamp.fromDate(now) },
        ],
        orderBy: { field: 'expectedCloseDate', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getUpcoming', days });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get upcoming deals');
    }
  }

  /**
   * Get open deals past their expectedCloseDate
   */
  async getOverdue(context: SecurityContext): Promise<RepositoryResult<Deal[]>> {
    try {
      const now = new Date();

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'open' },
          { field: 'expectedCloseDate', operator: '<', value: Timestamp.fromDate(now) },
        ],
        orderBy: { field: 'expectedCloseDate', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      await this.logAudit(context, 'list', null, { action: 'getOverdue' });

      return successResult(deals);
    } catch (error) {
      return failedResult(error, 'Failed to get overdue deals');
    }
  }

  // ============================================
  // Stage Management
  // ============================================

  /**
   * Move a deal to a new stage
   */
  async moveToStage(
    context: SecurityContext,
    dealId: string,
    stageId: string,
    probability?: number
  ): Promise<RepositoryResult<Deal>> {
    try {
      if (!isValidDocumentId(dealId)) {
        return failedResult(new InvalidArgumentError('Invalid deal ID', 'dealId'));
      }
      if (!isValidDocumentId(stageId)) {
        return failedResult(new InvalidArgumentError('Invalid stage ID', 'stageId'));
      }

      // Get current deal
      const existingResult = await this.getById(context, dealId);
      if (!existingResult.success) {
        return existingResult;
      }

      const deal = existingResult.data;

      // Cannot move closed deals
      if (deal.status !== 'open') {
        return failedResult(
          new InvalidArgumentError('Cannot move a closed deal. Reopen it first.', 'status')
        );
      }

      const updateData: Partial<Deal> = { stageId };
      if (probability !== undefined) {
        if (probability < 0 || probability > 100) {
          return failedResult(
            new InvalidArgumentError('Probability must be between 0 and 100', 'probability')
          );
        }
        updateData.probability = probability;
      }

      const result = await this.update(context, dealId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', dealId, {
          action: 'moveToStage',
          fromStageId: deal.stageId,
          toStageId: stageId,
          probability,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to move deal to stage');
    }
  }

  // ============================================
  // Win/Loss Management
  // ============================================

  /**
   * Mark a deal as won
   */
  async markWon(
    context: SecurityContext,
    dealId: string,
    reason?: string
  ): Promise<RepositoryResult<Deal>> {
    try {
      if (!isValidDocumentId(dealId)) {
        return failedResult(new InvalidArgumentError('Invalid deal ID', 'dealId'));
      }

      // Get current deal
      const existingResult = await this.getById(context, dealId);
      if (!existingResult.success) {
        return existingResult;
      }

      const deal = existingResult.data;

      // Can only mark open deals as won
      if (deal.status !== 'open') {
        return failedResult(
          new InvalidArgumentError('Can only mark open deals as won', 'status')
        );
      }

      const updateData: Partial<Deal> = {
        status: 'won',
        closedAt: new Date(),
        probability: 100,
      };

      if (reason) {
        updateData.wonLostReason = reason;
      }

      const result = await this.update(context, dealId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', dealId, { action: 'markWon', reason });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark deal as won');
    }
  }

  /**
   * Mark a deal as lost (reason required)
   */
  async markLost(
    context: SecurityContext,
    dealId: string,
    reason: string
  ): Promise<RepositoryResult<Deal>> {
    try {
      if (!isValidDocumentId(dealId)) {
        return failedResult(new InvalidArgumentError('Invalid deal ID', 'dealId'));
      }

      if (!reason?.trim()) {
        return failedResult(
          new InvalidArgumentError('Reason is required when marking a deal as lost', 'reason')
        );
      }

      // Get current deal
      const existingResult = await this.getById(context, dealId);
      if (!existingResult.success) {
        return existingResult;
      }

      const deal = existingResult.data;

      // Can only mark open deals as lost
      if (deal.status !== 'open') {
        return failedResult(
          new InvalidArgumentError('Can only mark open deals as lost', 'status')
        );
      }

      const updateData: Partial<Deal> = {
        status: 'lost',
        closedAt: new Date(),
        wonLostReason: reason,
        probability: 0,
      };

      const result = await this.update(context, dealId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', dealId, { action: 'markLost', reason });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to mark deal as lost');
    }
  }

  /**
   * Reopen a closed deal
   */
  async reopen(context: SecurityContext, dealId: string): Promise<RepositoryResult<Deal>> {
    try {
      if (!isValidDocumentId(dealId)) {
        return failedResult(new InvalidArgumentError('Invalid deal ID', 'dealId'));
      }

      // Get current deal
      const existingResult = await this.getById(context, dealId);
      if (!existingResult.success) {
        return existingResult;
      }

      const deal = existingResult.data;

      // Can only reopen closed deals
      if (deal.status === 'open') {
        return failedResult(new InvalidArgumentError('Deal is already open', 'status'));
      }

      const updateData: Partial<Deal> = {
        status: 'open',
        closedAt: undefined,
        wonLostReason: undefined,
      };

      const result = await this.update(context, dealId, updateData);

      if (result.success) {
        await this.logAudit(context, 'update', dealId, {
          action: 'reopen',
          previousStatus: deal.status,
        });
      }

      return result;
    } catch (error) {
      return failedResult(error, 'Failed to reopen deal');
    }
  }

  // ============================================
  // Aggregations
  // ============================================

  /**
   * Get total value and count by stage for a pipeline
   */
  async getTotalValueByStage(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<DealsByStageResult>> {
    try {
      if (!isValidDocumentId(pipelineId)) {
        return failedResult(new InvalidArgumentError('Invalid pipeline ID', 'pipelineId'));
      }

      const dealsResult = await this.getByPipeline(context, pipelineId);
      if (!dealsResult.success) {
        return { success: false, data: null, error: dealsResult.error };
      }

      // Only count open deals
      const openDeals = dealsResult.data.filter((deal) => deal.status === 'open');

      const result: DealsByStageResult = {};

      for (const deal of openDeals) {
        if (!result[deal.stageId]) {
          result[deal.stageId] = { count: 0, totalValueCents: 0 };
        }
        result[deal.stageId].count++;
        result[deal.stageId].totalValueCents += deal.valueCents;
      }

      await this.logAudit(context, 'list', null, { action: 'getTotalValueByStage', pipelineId });

      return successResult(result);
    } catch (error) {
      return failedResult(error, 'Failed to get total value by stage');
    }
  }

  /**
   * Get count of deals by stage for a pipeline
   */
  async getCountByStage(
    context: SecurityContext,
    pipelineId: string
  ): Promise<RepositoryResult<Record<string, number>>> {
    try {
      const valueResult = await this.getTotalValueByStage(context, pipelineId);
      if (!valueResult.success) {
        return { success: false, data: null, error: valueResult.error };
      }

      const counts: Record<string, number> = {};
      for (const [stageId, data] of Object.entries(valueResult.data)) {
        counts[stageId] = data.count;
      }

      return successResult(counts);
    } catch (error) {
      return failedResult(error, 'Failed to get count by stage');
    }
  }

  /**
   * Get total value of won deals in a date range
   */
  async getWonValueRange(
    context: SecurityContext,
    startDate: Date,
    endDate: Date
  ): Promise<RepositoryResult<WonValueResult>> {
    try {
      if (startDate > endDate) {
        return failedResult(
          new InvalidArgumentError('Start date must be before end date', 'startDate')
        );
      }

      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'status', operator: '==', value: 'won' },
          { field: 'closedAt', operator: '>=', value: Timestamp.fromDate(startDate) },
          { field: 'closedAt', operator: '<=', value: Timestamp.fromDate(endDate) },
        ],
      });

      const snapshot = await getDocs(q);
      const deals = this.filterAccessibleDeals(context, this.snapshotToDeals(snapshot));

      const totalValueCents = deals.reduce((sum, deal) => sum + deal.valueCents, 0);

      await this.logAudit(context, 'list', null, {
        action: 'getWonValueRange',
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
      });

      return successResult({
        totalValueCents,
        dealCount: deals.length,
      });
    } catch (error) {
      return failedResult(error, 'Failed to get won value in range');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleDeals(context: SecurityContext, deals: Deal[]): Deal[] {
    return filterAuthorizedEntities(context, deals, this.sensitiveFields);
  }

  /**
   * Convert Firestore snapshot to Deal array
   */
  private snapshotToDeals(snapshot: QuerySnapshot<DocumentData>): Deal[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        pipelineId: data.pipelineId as string,
        stageId: data.stageId as string,
        title: data.title as string,
        valueCents: data.valueCents as number,
        currency: data.currency as string,
        probability: data.probability as number,
        expectedCloseDate: data.expectedCloseDate?.toDate?.() || data.expectedCloseDate,
        status: data.status as DealStatus,
        wonLostReason: data.wonLostReason as string | undefined,
        closedAt: data.closedAt?.toDate?.() || data.closedAt,
        clientId: data.clientId as string | undefined,
        clientName: data.clientName as string | undefined,
        companyId: data.companyId as string | undefined,
        companyName: data.companyName as string | undefined,
        assigneeId: data.assigneeId as string | undefined,
        assigneeName: data.assigneeName as string | undefined,
        ownerId: data.ownerId as string | undefined,
        ownerName: data.ownerName as string | undefined,
        teamIds: (data.teamIds as string[]) || [],
        visibility: (data.visibility as Deal['visibility']) || undefined,
        tags: (data.tags as string[]) || [],
        notes: data.notes as string | undefined,
        customFields: data.customFields as Record<string, unknown> | undefined,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// Export singleton instance for convenience
let dealRepository: DealRepository | null = null;

export function getDealRepository(): DealRepository {
  if (!dealRepository) {
    dealRepository = new DealRepository();
  }
  return dealRepository;
}
