/**
 * Report Definition Repository
 * Manages report definitions with RBAC and Firestore persistence.
 *
 * HIPAA Compliance:
 * - Report definitions contain no PHI (configuration only)
 * - All operations require SecurityContext for businessId scoping
 * - Audit log report access with IDs only
 * - System reports are seeded and cannot be deleted
 */

import { getDocs, doc, writeBatch } from 'firebase/firestore';
import type { QuerySnapshot, DocumentData } from 'firebase/firestore';

import { ShareableRepository, filterAuthorizedEntities, isOrgPrivileged } from './access-control';
import {
  SYSTEM_REPORTS,
  createReportDefinitionFromSystem,
} from '../system-reports';
import type {
  SecurityContext,
  RepositoryResult,
  Validator,
  ValidationResult,
} from './repository-types';
import {
  InvalidArgumentError,
  AuthorizationError,
  failedResult,
  successResult,
} from '../errors/repository-errors';
import { buildQuery, generateId, prepareForCreate } from './firestore-utils';
import type {
  ReportDefinition,
  ReportType,
  ChartType,
  ReportDataSource,
} from '../../types/reporting';

// ============================================
// Validation
// ============================================

const VALID_REPORT_TYPES: ReportType[] = [
  'leads',
  'deals',
  'activities',
  'sequences',
  'pipeline',
  'revenue',
  'conversion',
  'team',
];

const VALID_CHART_TYPES: ChartType[] = [
  'bar',
  'line',
  'pie',
  'funnel',
  'table',
  'metric',
  'heatmap',
];

const VALID_DATA_SOURCES: ReportDataSource[] = [
  'leads',
  'deals',
  'activities',
  'sequence_enrollments',
  'email_messages',
];

const reportValidator: Validator<ReportDefinition> = (
  data: Partial<ReportDefinition>
): ValidationResult => {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (data.name !== undefined && !data.name?.trim()) {
    errors.push({
      field: 'name',
      message: 'Report name is required',
      code: 'REQUIRED',
    });
  }

  if (data.name && data.name.length > 100) {
    errors.push({
      field: 'name',
      message: 'Report name must be 100 characters or less',
      code: 'MAX_LENGTH',
    });
  }

  if (data.reportType !== undefined && !VALID_REPORT_TYPES.includes(data.reportType)) {
    errors.push({
      field: 'reportType',
      message: `Invalid report type. Must be one of: ${VALID_REPORT_TYPES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.chartType !== undefined && !VALID_CHART_TYPES.includes(data.chartType)) {
    errors.push({
      field: 'chartType',
      message: `Invalid chart type. Must be one of: ${VALID_CHART_TYPES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.dataSource !== undefined && !VALID_DATA_SOURCES.includes(data.dataSource)) {
    errors.push({
      field: 'dataSource',
      message: `Invalid data source. Must be one of: ${VALID_DATA_SOURCES.join(', ')}`,
      code: 'INVALID_VALUE',
    });
  }

  if (data.dimensions !== undefined && !Array.isArray(data.dimensions)) {
    errors.push({
      field: 'dimensions',
      message: 'Dimensions must be an array',
      code: 'INVALID_TYPE',
    });
  }

  if (data.metrics !== undefined && !Array.isArray(data.metrics)) {
    errors.push({
      field: 'metrics',
      message: 'Metrics must be an array',
      code: 'INVALID_TYPE',
    });
  }

  if (
    data.dimensions !== undefined &&
    data.metrics !== undefined &&
    (!data.dimensions?.length && !data.metrics?.length)
  ) {
    errors.push({
      field: 'dimensions',
      message: 'At least one dimension or metric is required',
      code: 'REQUIRED',
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

// ============================================
// Report Repository
// ============================================

/**
 * Report Definition Repository
 * Handles CRUD operations for report definitions with RBAC
 */
export class ReportRepository extends ShareableRepository<ReportDefinition> {
  protected entityName = 'report';
  protected sensitiveFields: Array<keyof ReportDefinition> = [];

  constructor() {
    super({ collectionName: 'report_definitions' });
    this.setValidator(reportValidator);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get all reports accessible to the user
   */
  async getAccessible(
    context: SecurityContext,
    options?: { type?: ReportType; includeSystem?: boolean }
  ): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      const result = await this.getAll(context, {
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      if (!result.success) {
        return failedResult(result.error, 'Failed to get accessible reports');
      }

      let reports = result.data.data;

      // Filter by type if specified
      if (options?.type) {
        reports = reports.filter((report) => report.reportType === options.type);
      }

      // Filter system reports if not requested
      if (options?.includeSystem === false) {
        reports = reports.filter((report) => !report.isSystemReport);
      }

      await this.logAudit(context, 'list', null, {
        action: 'getAccessible',
        count: reports.length,
        typeFilter: options?.type,
        includeSystem: options?.includeSystem,
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error, 'Failed to get accessible reports');
    }
  }

  /**
   * Get all system reports for the business
   */
  async getSystemReports(context: SecurityContext): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'isSystemReport', operator: '==', value: true }],
        orderBy: { field: 'name', direction: 'asc' },
      });

      const snapshot = await getDocs(q);
      const reports = this.snapshotToReports(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getSystemReports',
        count: reports.length,
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error, 'Failed to get system reports');
    }
  }

  /**
   * Get public reports (visible to all in the business)
   */
  async getPublic(context: SecurityContext): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'isPublic', operator: '==', value: true }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const reports = this.snapshotToReports(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getPublic',
        count: reports.length,
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error, 'Failed to get public reports');
    }
  }

  /**
   * Get reports owned by the current user
   */
  async getMyReports(context: SecurityContext): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'ownerId', operator: '==', value: context.userId }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const reports = this.snapshotToReports(snapshot);

      await this.logAudit(context, 'list', null, {
        action: 'getMyReports',
        count: reports.length,
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error, 'Failed to get user reports');
    }
  }

  /**
   * Get reports by type
   */
  async getByType(
    context: SecurityContext,
    reportType: ReportType
  ): Promise<RepositoryResult<ReportDefinition[]>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [{ field: 'reportType', operator: '==', value: reportType }],
        orderBy: { field: 'createdAt', direction: 'desc' },
      });

      const snapshot = await getDocs(q);
      const reports = this.filterAccessibleReports(context, this.snapshotToReports(snapshot));

      await this.logAudit(context, 'list', null, {
        action: 'getByType',
        reportType,
        count: reports.length,
      });

      return successResult(reports);
    } catch (error) {
      return failedResult(error, 'Failed to get reports by type');
    }
  }

  /**
   * Check if a system report with given name exists
   */
  async systemReportExists(
    context: SecurityContext,
    name: string
  ): Promise<RepositoryResult<boolean>> {
    try {
      const collectionRef = this.getCollectionRef(context);
      const q = buildQuery(collectionRef, {
        where: [
          { field: 'isSystemReport', operator: '==', value: true },
          { field: 'name', operator: '==', value: name },
        ],
        limit: 1,
      });

      const snapshot = await getDocs(q);
      return successResult(!snapshot.empty);
    } catch (error) {
      return failedResult(error, 'Failed to check system report existence');
    }
  }

  // ============================================
  // System Report Seeding
  // ============================================

  /**
   * Seed system reports for a business.
   * Creates all predefined system reports that don't already exist.
   * Should be called when a business is created or on first reporting access.
   *
   * HIPAA: System reports contain configuration only, no PHI.
   * Audit logged as batch creation.
   */
  async seedSystemReports(
    context: SecurityContext
  ): Promise<RepositoryResult<{ seeded: number; existing: number; skipped: string[] }>> {
    try {
      this.ensureSecurityContext(context);

      // Only admins/owners can seed system reports
      if (!isOrgPrivileged(context)) {
        return failedResult(
          new AuthorizationError('Only admins can seed system reports', 'seedSystemReports', context.userRole)
        );
      }

      // Get existing system reports for this business
      const existingResult = await this.getSystemReports(context);
      if (!existingResult.success) {
        return failedResult(existingResult.error, 'Failed to check existing system reports');
      }

      const existingNames = new Set(existingResult.data.map((r) => r.name));
      const seededReports: string[] = [];
      const skippedReports: string[] = [];
      const batch = writeBatch(this.db);
      const collectionPath = this.getCollectionPath(context);

      for (const systemReport of SYSTEM_REPORTS) {
        if (existingNames.has(systemReport.name)) {
          skippedReports.push(systemReport.name);
          continue;
        }

        const id = generateId();
        const reportData = createReportDefinitionFromSystem(
          systemReport,
          context.businessId,
          context.userId,
          context.userName
        );

        const preparedData = prepareForCreate({
          ...reportData,
          businessId: context.businessId,
        });

        const docRef = doc(this.db, collectionPath, id);
        batch.set(docRef, preparedData);
        seededReports.push(systemReport.name);
      }

      // Commit batch if there are reports to seed
      if (seededReports.length > 0) {
        await batch.commit();
      }

      await this.logAudit(context, 'batch', null, {
        action: 'seedSystemReports',
        seeded: seededReports.length,
        existing: skippedReports.length,
        seededReports,
      });

      return successResult({
        seeded: seededReports.length,
        existing: skippedReports.length,
        skipped: skippedReports,
      });
    } catch (error) {
      return failedResult(error, 'Failed to seed system reports');
    }
  }

  /**
   * Check if system reports have been seeded for the business.
   * Returns true if at least half of the system reports exist.
   */
  async areSystemReportsSeeded(context: SecurityContext): Promise<RepositoryResult<boolean>> {
    try {
      this.ensureSecurityContext(context);

      const existingResult = await this.getSystemReports(context);
      if (!existingResult.success) {
        return failedResult(existingResult.error, 'Failed to check system reports');
      }

      const threshold = Math.floor(SYSTEM_REPORTS.length / 2);
      return successResult(existingResult.data.length >= threshold);
    } catch (error) {
      return failedResult(error, 'Failed to check if system reports are seeded');
    }
  }

  /**
   * Reseed a specific system report by name.
   * Updates existing report or creates if missing.
   *
   * HIPAA: Admin-only operation, audit logged.
   */
  async reseedSystemReport(
    context: SecurityContext,
    reportName: string
  ): Promise<RepositoryResult<ReportDefinition>> {
    try {
      this.ensureSecurityContext(context);

      if (!isOrgPrivileged(context)) {
        return failedResult(
          new AuthorizationError('Only admins can reseed system reports', 'reseedSystemReport', context.userRole)
        );
      }

      // Find the system report template
      const systemReport = SYSTEM_REPORTS.find((r) => r.name === reportName);
      if (!systemReport) {
        return failedResult(
          new InvalidArgumentError(`System report not found: ${reportName}`, 'reportName')
        );
      }

      // Check if it already exists
      const existsResult = await this.systemReportExists(context, reportName);
      if (!existsResult.success) {
        return failedResult(existsResult.error, 'Failed to check report existence');
      }

      if (existsResult.data) {
        // Find and update existing report
        const existingReports = await this.getSystemReports(context);
        if (!existingReports.success) {
          return failedResult(existingReports.error, 'Failed to get existing reports');
        }

        const existing = existingReports.data.find((r) => r.name === reportName);
        if (existing) {
          const reportData = createReportDefinitionFromSystem(
            systemReport,
            context.businessId,
            existing.ownerId,
            existing.ownerName
          );

          const updateResult = await super.update(context, existing.id, reportData);
          if (updateResult.success) {
            await this.logAudit(context, 'update', existing.id, {
              action: 'reseedSystemReport',
              reportName,
            });
          }
          return updateResult;
        }
      }

      // Create new report
      const reportData = createReportDefinitionFromSystem(
        systemReport,
        context.businessId,
        context.userId,
        context.userName
      );

      const createResult = await this.create(context, {
        ...reportData,
        businessId: context.businessId,
      } as Omit<ReportDefinition, 'id' | 'createdAt' | 'updatedAt'>);

      if (createResult.success) {
        await this.logAudit(context, 'create', createResult.data.id, {
          action: 'reseedSystemReport',
          reportName,
        });
      }

      return createResult;
    } catch (error) {
      return failedResult(error, 'Failed to reseed system report');
    }
  }

  // ============================================
  // Override Methods for System Report Protection
  // ============================================

  /**
   * Override delete to prevent system report deletion
   */
  async delete(context: SecurityContext, id: string): Promise<RepositoryResult<void>> {
    try {
      // Get the report first
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return { success: false, data: null, error: existing.error };
      }

      // Check if it's a system report
      if (existing.data.isSystemReport) {
        return failedResult(
          new AuthorizationError('System reports cannot be deleted', 'delete', context.userRole)
        );
      }

      return super.delete(context, id);
    } catch (error) {
      return failedResult(error, 'Failed to delete report');
    }
  }

  /**
   * Override update to protect system report flags
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<ReportDefinition>
  ): Promise<RepositoryResult<ReportDefinition>> {
    try {
      // Get the report first
      const existing = await this.getById(context, id);
      if (!existing.success) {
        return existing;
      }

      // Prevent changing isSystemReport flag
      if (data.isSystemReport !== undefined && data.isSystemReport !== existing.data.isSystemReport) {
        return failedResult(
          new InvalidArgumentError('Cannot change isSystemReport flag', 'isSystemReport')
        );
      }

      // Only admins can modify system reports
      if (existing.data.isSystemReport && !isOrgPrivileged(context)) {
        return failedResult(
          new AuthorizationError(
            'Only admins can modify system reports',
            'update',
            context.userRole
          )
        );
      }

      return super.update(context, id, data);
    } catch (error) {
      return failedResult(error, 'Failed to update report');
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  private filterAccessibleReports(
    context: SecurityContext,
    reports: ReportDefinition[]
  ): ReportDefinition[] {
    return filterAuthorizedEntities(context, reports, this.sensitiveFields);
  }

  /**
   * Convert Firestore snapshot to ReportDefinition array
   */
  private snapshotToReports(snapshot: QuerySnapshot<DocumentData>): ReportDefinition[] {
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        businessId: data.businessId as string,
        name: data.name as string,
        description: data.description as string | undefined,
        reportType: data.reportType as ReportType,
        chartType: data.chartType as ChartType,
        dataSource: data.dataSource as ReportDataSource,
        dimensions: data.dimensions || [],
        metrics: data.metrics || [],
        filters: data.filters || [],
        defaultDateRange: data.defaultDateRange || 'this_month',
        dateField: data.dateField || 'createdAt',
        sortBy: data.sortBy as string | undefined,
        sortOrder: data.sortOrder as 'asc' | 'desc' | undefined,
        limit: data.limit as number | undefined,
        isSystemReport: data.isSystemReport as boolean || false,
        isPublic: data.isPublic as boolean || false,
        ownerId: data.ownerId as string,
        ownerName: data.ownerName as string | undefined,
        sharedWithUserIds: data.sharedWithUserIds as string[] | undefined,
        sharedWithTeamIds: data.sharedWithTeamIds as string[] | undefined,
        teamIds: data.teamIds as string[] || [],
        visibility: data.visibility || 'team',
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      };
    });
  }
}

// ============================================
// Export singleton instance
// ============================================

let reportRepository: ReportRepository | null = null;

export function getReportRepository(): ReportRepository {
  if (!reportRepository) {
    reportRepository = new ReportRepository();
  }
  return reportRepository;
}
