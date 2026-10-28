/**
 * Import/Export Service
 * Server-side style validation with RBAC, audit logging, resumable imports,
 * and sanitized export generation (CSV/PDF placeholders).
 *
 * HIPAA Compliance:
 * - Never return row data or PHI in errors; audit only IDs/counts
 * - All exports include watermarks with user, business, and timestamp
 * - Comprehensive audit logging for all export operations
 * - 6-year audit retention per 45 CFR 164.530(j)
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import type { ValidationError, ExistingIdentifiers } from './csv-import-service';
import { validateAllRows } from './csv-import-service';
import { getRateLimitService, RateLimitService } from './RateLimitService';
import { getAuditLogService, AuditLogService } from './AuditLogService';
import { getImportSessionStore } from '../data/repositories/import-session-repository';
import { isAllowedToImport } from './import-security';

const IMPORT_SESSION_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const AUDIT_TIMEOUT_MS = 1_000; // avoid blocking flows if audit persistence is slow

export interface ImportJobConfig {
  entityType: 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment';
  rows: string[][];
  headers: string[];
  fieldMapping: Record<string, string>;
  sessionId?: string;
  existingIdentifiers?: ExistingIdentifiers;
}

export interface ImportJobResult {
  success: boolean;
  sessionId: string;
  processedRows: number;
  totalRows: number;
  validationErrors: ValidationError[];
  resumeToken?: string;
  backoffMs?: number;
  errors?: string[];
  multiEntitySummary?: {
    companiesCreated?: number;
    companiesUpdated?: number;
    companiesSkipped?: number;
    contactsCreated?: number;
    contactsUpdated?: number;
    contactsSkipped?: number;
    leadsCreated?: number;
    leadsUpdated?: number;
    leadsSkipped?: number;
    dealsCreated?: number;
    dealsUpdated?: number;
    dealsSkipped?: number;
    companies?: { created?: number; updated?: number; skipped?: number };
    contacts?: { created?: number; updated?: number; skipped?: number };
    leads?: { created?: number; updated?: number; skipped?: number };
    deals?: { created?: number; updated?: number; skipped?: number };
  };
}

export interface ResumeRequest {
  sessionId: string;
  resumeToken: string;
}

export interface ExportRequest {
  entity: 'lead' | 'contact' | 'deal' | 'company' | 'activity' | 'client' | 'appointment';
  format: 'csv' | 'pdf';
  filters?: Record<string, string | number | boolean>;
  businessId?: string;
}

export interface ExportResult {
  success: boolean;
  content: string;
  contentType: 'text/csv' | 'application/pdf';
  exportId: string;
  backoffMs?: number;
  errors?: string[];
}

export interface ImportSessionState {
  businessId: string;
  createdBy: string;
  createdByRole: string;
  entityType: ImportJobConfig['entityType'];
  startedAt: Date;
  expiresAt: Date;
  processedRows: number;
  totalRows: number;
  errors: ValidationError[];
  resumeToken: string;
  status: 'pending' | 'paused' | 'failed' | 'complete';
}

export interface ImportSessionStore {
  load: (businessId: string, sessionId: string) => Promise<ImportSessionState | null>;
  save: (businessId: string, sessionId: string, state: ImportSessionState) => Promise<void>;
  delete: (businessId: string, sessionId: string) => Promise<void>;
}

export class ImportExportService {
  private rateLimit: RateLimitService;
  private audit: AuditLogService;
  private sessions: Map<string, ImportSessionState>;
  private sessionStore?: ImportSessionStore;

  constructor(
    rateLimitService?: RateLimitService,
    auditService?: AuditLogService,
    sessionStore?: ImportSessionStore
  ) {
    this.rateLimit = rateLimitService || getRateLimitService();
    this.audit = auditService || getAuditLogService();
    this.sessions = new Map();
    this.sessionStore = sessionStore ?? createDefaultSessionStore() ?? getImportSessionStore();
  }

  /**
   * Start an import with server-side validation and resumable token.
   */
  async startImport(
    context: SecurityContext,
    config: ImportJobConfig
  ): Promise<ImportJobResult> {
    const rbac = this.enforceImportRBAC(context);
    if (!rbac.allowed) {
      return {
        success: false,
        sessionId: config.sessionId ?? '',
        processedRows: 0,
        totalRows: config.rows.length,
        validationErrors: [],
        errors: [rbac.reason ?? 'Access denied'],
      };
    }

    const limit = await this.rateLimit.checkLimit('import', context.userId, context.businessId);
    if (!limit.allowed) {
      return {
        success: false,
        sessionId: config.sessionId ?? '',
        processedRows: 0,
        totalRows: config.rows.length,
        validationErrors: [],
        backoffMs: Math.max(0, limit.resetAt.getTime() - Date.now()),
        errors: [limit.message || 'Import rate limit exceeded'],
        resumeToken: undefined,
      };
    }

    const identifierSet = this.sanitizeIdentifiers(config.existingIdentifiers);

    const validationErrors = validateAllRows(
      config.rows,
      config.headers,
      config.entityType,
      config.fieldMapping,
      identifierSet
    ).map(this.sanitizeValidationError);

    const now = new Date();
    const sessionId = config.sessionId || `import_${Date.now()}`;
    const resumeToken = `${sessionId}_${Date.now()}`;

    const sessionState: ImportSessionState = {
      businessId: context.businessId,
      createdBy: context.userId,
      createdByRole: context.userRole,
      entityType: config.entityType,
      startedAt: now,
      expiresAt: new Date(now.getTime() + IMPORT_SESSION_TTL_MS),
      processedRows: validationErrors.length ? 0 : config.rows.length,
      totalRows: config.rows.length,
      errors: validationErrors,
      resumeToken,
      status: validationErrors.length ? 'paused' : 'complete',
    };

    this.sessions.set(this.getSessionKey(context.businessId, sessionId), sessionState);
    await this.persistSession(context.businessId, sessionId, sessionState);
    await this.rateLimit.recordAction('import', context.userId, context.businessId);

    await this.safeAuditLog(context, {
      action: 'import',
      entityType: 'importJob',
      entityId: sessionId,
      entityName: config.entityType,
      metadata: {
        totalRows: config.rows.length,
        validationErrors: validationErrors.length,
        status: sessionState.status,
        existingIdentifierCounts: {
          emails: identifierSet?.emails?.length || 0,
          phones: identifierSet?.phones?.length || 0,
        },
      },
    });

    return {
      success: sessionState.errors.length === 0,
      sessionId,
      processedRows: sessionState.processedRows,
      totalRows: sessionState.totalRows,
      validationErrors,
      resumeToken,
      errors: sessionState.errors.length ? ['Validation required before import'] : undefined,
    };
  }

  /**
   * Resume a paused import after fixing validation issues.
   */
  async resumeImport(
    context: SecurityContext,
    request: ResumeRequest
  ): Promise<ImportJobResult> {
    const rbac = this.enforceImportRBAC(context);
    if (!rbac.allowed) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: 0,
        totalRows: 0,
        validationErrors: [],
        errors: [rbac.reason ?? 'Access denied'],
      };
    }

    const session = await this.loadSession(context.businessId, request.sessionId);
    if (!session || session.resumeToken !== request.resumeToken) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: 0,
        totalRows: 0,
        validationErrors: [],
        errors: ['Invalid resume token'],
      };
    }

    if (session.businessId !== context.businessId) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: 0,
        totalRows: 0,
        validationErrors: [],
        errors: ['Import session does not belong to this business'],
      };
    }

    if (this.isSessionExpired(session)) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: 0,
        totalRows: session.totalRows,
        validationErrors: [],
        errors: ['Import session expired; please restart import'],
      };
    }

    if (session.status !== 'paused') {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: session.processedRows,
        totalRows: session.totalRows,
        validationErrors: session.errors,
        errors: ['Import session is not resumable'],
      };
    }

    if (session.errors.length > 0) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: session.processedRows,
        totalRows: session.totalRows,
        validationErrors: session.errors,
        errors: ['Validation errors must be resolved before resuming'],
      };
    }

    const limit = await this.rateLimit.checkLimit('import', context.userId, context.businessId);
    if (!limit.allowed) {
      return {
        success: false,
        sessionId: request.sessionId,
        processedRows: session.processedRows,
        totalRows: session.totalRows,
        validationErrors: session.errors,
        backoffMs: Math.max(0, limit.resetAt.getTime() - Date.now()),
        errors: [limit.message || 'Import rate limit exceeded'],
      };
    }

    session.status = 'complete';
    session.processedRows = session.totalRows;
    this.sessions.set(this.getSessionKey(context.businessId, request.sessionId), session);
    await this.persistSession(context.businessId, request.sessionId, session);
    if (this.sessionStore) {
      await this.sessionStore.delete(context.businessId, request.sessionId);
    }
    await this.rateLimit.recordAction('import', context.userId, context.businessId);

    await this.safeAuditLog(context, {
      action: 'import',
      entityType: 'importJob',
      entityId: request.sessionId,
      entityName: 'import-resume',
      metadata: {
        processedRows: session.processedRows,
        totalRows: session.totalRows,
      },
    });

    return {
      success: true,
      sessionId: request.sessionId,
      processedRows: session.processedRows,
      totalRows: session.totalRows,
      validationErrors: [],
    };
  }

  /**
   * Export data with RBAC + audit + rate limits.
   *
   * HIPAA Compliance:
   * - All exports include watermarks with user identification
   * - Comprehensive audit logging includes export metadata
   * - Exports are tracked for compliance monitoring
   */
  async exportData(
    context: SecurityContext,
    request: ExportRequest
  ): Promise<ExportResult> {
    const rbac = this.enforceExportRBAC(context);
    if (!rbac.allowed) {
      return {
        success: false,
        content: '',
        contentType: request.format === 'csv' ? 'text/csv' : 'application/pdf',
        exportId: '',
        errors: [rbac.reason ?? 'Access denied'],
      };
    }

    const limit = await this.rateLimit.checkLimit('export', context.userId, context.businessId);
    if (!limit.allowed) {
      return {
        success: false,
        content: '',
        contentType: request.format === 'csv' ? 'text/csv' : 'application/pdf',
        exportId: '',
        backoffMs: Math.max(0, limit.resetAt.getTime() - Date.now()),
        errors: [limit.message || 'Export rate limit exceeded'],
      };
    }

    const exportId = `export_${Date.now()}`;
    const exportTimestamp = new Date().toISOString();
    const sanitizedFilters = request.filters
      ? Object.keys(request.filters).reduce<Record<string, string | number | boolean>>(
          (acc, key) => {
            acc[key] = request.filters?.[key] ?? '';
            return acc;
          },
          {}
        )
      : undefined;

    // Generate watermark for HIPAA compliance tracking
    const watermark = this.generateExportWatermark(context, exportId, exportTimestamp);

    const content =
      request.format === 'csv'
        ? this.generateCsvPlaceholder(request.entity, sanitizedFilters, watermark)
        : this.generatePdfPlaceholder(request.entity, sanitizedFilters, watermark);

    await this.rateLimit.recordAction('export', context.userId, context.businessId);

    // Enhanced audit logging for HIPAA compliance
    await this.safeAuditLog(context, {
      action: 'export',
      entityType: 'exportJob',
      entityId: exportId,
      entityName: request.entity,
      metadata: {
        format: request.format,
        filters: sanitizedFilters,
        delivery: 'download',
        exportTimestamp,
        watermarkId: exportId,
        // HIPAA: Track export for compliance monitoring
        hipaaTracking: {
          exportedBy: context.userId,
          exportedByName: context.userName,
          businessId: context.businessId,
          entityType: request.entity,
          timestamp: exportTimestamp,
        },
      },
    });

    return {
      success: true,
      content,
      contentType: request.format === 'csv' ? 'text/csv' : 'application/pdf',
      exportId,
    };
  }

  /**
   * Helper to expose session for diagnostics/testing.
   */
  getSession(businessId: string, sessionId: string): ImportSessionState | undefined {
    return this.sessions.get(this.getSessionKey(businessId, sessionId));
  }

  private enforceImportRBAC(context: SecurityContext): { allowed: boolean; reason?: string } {
    if (!isAllowedToImport(context.userRole)) {
      return {
        allowed: false,
        reason: 'Insufficient permissions for import',
      };
    }
    return { allowed: true };
  }

  private enforceExportRBAC(context: SecurityContext): { allowed: boolean; reason?: string } {
    const privilegedRoles = ['owner', 'admin', 'manager'];
    if (!privilegedRoles.includes(context.userRole)) {
      return {
        allowed: false,
        reason: 'Insufficient permissions for export',
      };
    }
    return { allowed: true };
  }

  private sanitizeValidationError(error: ValidationError): ValidationError {
    return {
      row: error.row,
      field: error.field,
      error: error.error,
    };
  }

  private sanitizeIdentifiers(
    identifiers?: ExistingIdentifiers
  ): ExistingIdentifiers | undefined {
    if (!identifiers) return undefined;

    const normalizeEmail = (email: string) => email.toLowerCase().trim();
    const normalizePhone = (phone: string) => phone.replace(/\D/g, '');

    const emails = Array.from(
      new Set((identifiers.emails || []).map(normalizeEmail).filter(Boolean))
    );
    const phones = Array.from(
      new Set((identifiers.phones || []).map(normalizePhone).filter(Boolean))
    );

    if (emails.length === 0 && phones.length === 0) {
      return undefined;
    }

    return { emails, phones };
  }

  private async safeAuditLog(
    context: SecurityContext,
    payload: Parameters<AuditLogService['logAction']>[1]
  ): Promise<void> {
    try {
      await Promise.race([
        this.audit.logAction(context, payload),
        new Promise((resolve) => setTimeout(resolve, AUDIT_TIMEOUT_MS)),
      ]);
    } catch {
      // Audit failures should not block import/export flows.
    }
  }

  private getSessionKey(businessId: string, sessionId: string): string {
    return `${businessId}:${sessionId}`;
  }

  private normalizeSessionState(
    businessId: string,
    _sessionId: string,
    state: Partial<ImportSessionState>
  ): ImportSessionState {
    const startedAt = state.startedAt ? new Date(state.startedAt) : new Date();
    const expiresAt =
      state.expiresAt instanceof Date
        ? state.expiresAt
        : state.expiresAt
          ? new Date(state.expiresAt)
          : new Date(startedAt.getTime() + IMPORT_SESSION_TTL_MS);

    return {
      businessId: state.businessId || businessId,
      createdBy: state.createdBy || 'unknown',
      createdByRole: state.createdByRole || 'unknown',
      entityType: state.entityType || 'lead',
      startedAt,
      expiresAt,
      processedRows: state.processedRows || 0,
      totalRows: state.totalRows || 0,
      errors: state.errors || [],
      resumeToken: state.resumeToken || '',
      status: state.status || 'paused',
    };
  }

  private isSessionExpired(session: ImportSessionState): boolean {
    return session.expiresAt.getTime() < Date.now();
  }

  /**
   * Generate HIPAA compliance watermark for exports
   * Includes user identification, business, timestamp for tracking
   */
  private generateExportWatermark(
    context: SecurityContext,
    exportId: string,
    timestamp: string
  ): string {
    // Create a traceable watermark that doesn't include PHI
    // but allows identification of who exported and when
    return [
      '=== HIPAA COMPLIANCE WATERMARK ===',
      `Export ID: ${exportId}`,
      `Exported By: ${context.userName || context.userId}`,
      `Business ID: ${context.businessId}`,
      `Timestamp: ${timestamp}`,
      `Role: ${context.userRole}`,
      'This export is logged and tracked for compliance.',
      '=================================='
    ].join('\n');
  }

  private generateCsvPlaceholder(
    entity: ExportRequest['entity'],
    filters?: Record<string, string | number | boolean>,
    watermark?: string
  ): string {
    const header = 'id,status,updatedAt';
    const rows = [
      `${entity}_1,exported,${new Date().toISOString()}`,
      `${entity}_2,exported,${new Date().toISOString()}`,
    ];
    const filterRow = filters ? `filters,${Object.keys(filters).length},sanitized` : '';

    // Add watermark as comment rows at the top of CSV (HIPAA compliance)
    const watermarkRows = watermark
      ? watermark.split('\n').map(line => `# ${line}`)
      : [];

    return [
      ...watermarkRows,
      '',
      header,
      ...(filterRow ? [filterRow] : []),
      ...rows
    ].join('\n');
  }

  private generatePdfPlaceholder(
    entity: ExportRequest['entity'],
    filters?: Record<string, string | number | boolean>,
    watermark?: string
  ): string {
    const appliedFilters = filters ? JSON.stringify(filters) : '{}';
    const watermarkSection = watermark ? `\n\n${watermark}` : '';
    return `PDF Export for ${entity} — filters: ${appliedFilters} — generated at ${new Date().toISOString()}${watermarkSection}`;
  }

  private async persistSession(
    businessId: string,
    sessionId: string,
    state: ImportSessionState
  ): Promise<void> {
    if (!this.sessionStore) {
      return;
    }
    try {
      await this.sessionStore.save(businessId, sessionId, state);
    } catch {
      // Persistence is best-effort; swallow to avoid impacting import flow.
    }
  }

  private async loadSession(
    businessId: string,
    sessionId: string
  ): Promise<ImportSessionState | undefined> {
    const cacheKey = this.getSessionKey(businessId, sessionId);
    const cached = this.sessions.get(cacheKey);
    if (cached) {
      return cached;
    }

    if (this.sessionStore) {
      try {
        const stored = await this.sessionStore.load(businessId, sessionId);
        if (stored) {
          const normalized = this.normalizeSessionState(businessId, sessionId, stored);
          this.sessions.set(cacheKey, normalized);
          return normalized;
        }
      } catch {
        return undefined;
      }
    }

    return undefined;
  }
}

let importExportService: ImportExportService | null = null;

export function getImportExportService(): ImportExportService {
  if (!importExportService) {
    importExportService = new ImportExportService(
      undefined,
      undefined,
      createDefaultSessionStore()
    );
  }
  return importExportService;
}

/**
 * Default session store backed by localStorage (IDs/counts only; no row data).
 * Falls back to in-memory only when storage is unavailable (SSR/Node).
 */
function createDefaultSessionStore(): ImportSessionStore | undefined {
  if (typeof localStorage === 'undefined') {
    return undefined;
  }

  const PREFIX = 'crm-import-session:';

  const safeParse = (value: string | null): ImportSessionState | null => {
    if (!value) return null;
    try {
      const parsed = JSON.parse(value) as Partial<ImportSessionState> & {
        startedAt?: string;
        expiresAt?: string;
      };
      if (!parsed.resumeToken || !parsed.businessId) {
        return null;
      }
      return {
        businessId: parsed.businessId,
        createdBy: parsed.createdBy || 'unknown',
        createdByRole: parsed.createdByRole || 'unknown',
        entityType: parsed.entityType || 'lead',
        startedAt: parsed.startedAt ? new Date(parsed.startedAt) : new Date(),
        expiresAt: parsed.expiresAt ? new Date(parsed.expiresAt) : new Date(Date.now() + IMPORT_SESSION_TTL_MS),
        processedRows: parsed.processedRows || 0,
        totalRows: parsed.totalRows || 0,
        errors: parsed.errors || [],
        resumeToken: parsed.resumeToken,
        status: parsed.status || 'paused',
      };
    } catch {
      return null;
    }
  };

  return {
    load: async (businessId: string, sessionId: string) => {
      try {
        return safeParse(localStorage.getItem(`${PREFIX}${businessId}:${sessionId}`));
      } catch {
        return null;
      }
    },
    save: async (businessId: string, sessionId: string, state: ImportSessionState) => {
      try {
        const payload = {
          ...state,
          startedAt: state.startedAt.toISOString(),
          expiresAt: state.expiresAt.toISOString(),
        };
        localStorage.setItem(`${PREFIX}${businessId}:${sessionId}`, JSON.stringify(payload));
      } catch {
        // Swallow storage failures to avoid blocking UI; data can be revalidated by backend.
      }
    },
    delete: async (businessId: string, sessionId: string) => {
      try {
        localStorage.removeItem(`${PREFIX}${businessId}:${sessionId}`);
      } catch {
        // Ignore
      }
    },
  };
}
