/**
 * Thin client for CRM Cloud Functions:
 * - integrationSync
 * - importData / resumeImport
 * - exportData
 *
 * Assumes Functions are deployed with HTTPS and require Firebase ID token auth.
 * No PHI is sent; only IDs and metadata are forwarded.
 */

import { getAuth } from 'firebase/auth';
import type { SyncResult } from './integration-sync-service';
import type { ImportJobResult } from './import-export-service';
import type { ExportRequest, ExportResult } from './import-export-service';
import type {
  AutomationActionType,
  AutomationRelatedEntityType,
  AutomationReminderType,
  AutomationRunStatus,
  AutomationTriggerType,
} from '../types/automation';
import type { LeadStatus } from '../types/models';
import type { ExistingIdentifiers } from './csv-import-service';
import type { SignatureStatus } from '../types/documents';
import { getFunctionsBaseUrl, hasFunctionsBaseUrl } from './functions-base-url';

async function getIdToken(): Promise<string> {
  const auth = getAuth();
  const user = auth.currentUser;
  if (!user) {
    throw new Error('User not authenticated');
  }
  return user.getIdToken();
}

async function postJson<TResponse>(
  path: string,
  body: unknown,
  businessId?: string
): Promise<{ ok: boolean; status: number; data?: TResponse; error?: string; headers?: Headers }> {
  const baseUrl = getFunctionsBaseUrl();
  if (!baseUrl) {
    return {
      ok: false,
      status: 0,
      error: 'Functions base URL is not configured',
    };
  }

  const idToken = await getIdToken();
  const response = await fetch(`${baseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
      ...(businessId ? { 'X-Business-Id': businessId } : {}),
    },
    body: JSON.stringify(body),
  });

  const headers = response.headers;
  const isJson = headers.get('content-type')?.includes('application/json');
  const payload = isJson ? await response.json() : await response.text();

  if (!response.ok) {
    return {
      ok: false,
      status: response.status,
      error: typeof payload === 'string' ? payload : payload?.error || 'Request failed',
      headers,
    };
  }

  return {
      ok: true,
      status: response.status,
      data: payload as TResponse,
      headers,
  };
}

export interface IntegrationSyncRequest {
  integrationId: string;
  direction: 'pull' | 'push' | 'bidirectional';
  cursor?: string;
  allowConflicts?: boolean;
  businessId?: string;
}

export async function runIntegrationSync(
  request: IntegrationSyncRequest
): Promise<SyncResult> {
  const result = await postJson<SyncResult>('/integrationSync', request, request.businessId);
  if (!result.ok || !result.data) {
    return {
      success: false,
      created: 0,
      updated: 0,
      skipped: 0,
      conflicts: [],
      retried: 0,
      backoffMs: undefined,
      errors: [result.error || 'Failed to sync integration'],
    };
  }
  return result.data;
}

export interface ImportDataRequest {
  entityType: 'lead' | 'contact' | 'deal' | 'company' | 'client' | 'appointment' | 'multi';
  primaryEntityType?: 'lead' | 'contact' | 'deal' | 'company';
  rows: string[][];
  headers: string[];
  fieldMapping: Record<string, string>;
  sessionId?: string;
  businessId?: string;
  existingIdentifiers?: ExistingIdentifiers;
  duplicateHandling?: 'skip' | 'update' | 'create';
  skipFirstRow?: boolean;
  dryRun?: boolean;
}

export async function startImportJob(
  request: ImportDataRequest
): Promise<ImportJobResult> {
  const result = await postJson<ImportJobResult>('/importData', request, request.businessId);
  if (!result.ok || !result.data) {
    return {
      success: false,
      sessionId: request.sessionId || '',
      processedRows: 0,
      totalRows: request.rows.length,
      validationErrors: [],
      errors: [result.error || 'Import request failed'],
    };
  }
  return result.data;
}

export async function resumeImportJob(
  sessionId: string,
  resumeToken: string,
  businessId?: string
): Promise<ImportJobResult> {
  const result = await postJson<ImportJobResult>(
    '/resumeImport',
    { sessionId, resumeToken, businessId },
    businessId
  );
  if (!result.ok || !result.data) {
    return {
      success: false,
      sessionId,
      processedRows: 0,
      totalRows: 0,
      validationErrors: [],
      errors: [result.error || 'Resume request failed'],
    };
  }
  return result.data;
}

export interface ExportDataResponse extends ExportResult {
  exportId: string;
}

export async function runExport(
  request: ExportRequest
): Promise<ExportDataResponse> {
  const baseUrl = getFunctionsBaseUrl();
  if (!baseUrl) {
    return {
      success: false,
      content: '',
      contentType: request.format === 'pdf' ? 'application/pdf' : 'text/csv',
      exportId: '',
      errors: ['Functions base URL is not configured'],
    };
  }

  const idToken = await getIdToken();
  const businessId = (request as any).businessId as string | undefined;
  const response = await fetch(`${baseUrl}/exportData`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
      ...(businessId ? { 'X-Business-Id': businessId } : {}),
    },
    body: JSON.stringify(request),
  });

  const exportId = response.headers.get('X-Export-Id') || '';
  const contentType = response.headers.get('content-type') || 'text/plain';
  const content = await response.text();

  if (!response.ok) {
    return {
      success: false,
      content: '',
      contentType: contentType.includes('pdf') ? 'application/pdf' : 'text/csv',
      exportId,
      errors: [content || 'Export failed'],
    };
  }

  return {
    success: true,
    content,
    contentType: contentType.includes('pdf') ? 'application/pdf' : 'text/csv',
    exportId,
  };
}

// E-signature: persist signed documents via Functions (server downloads from provider)
export interface StoreSignedDocumentRequest {
  businessId: string;
  documentId: string;
  signatureRequestId: string;
  status: SignatureStatus;
  signedDocumentUrl?: string;
}

export async function storeSignedDocument(
  request: StoreSignedDocumentRequest
): Promise<{ success: boolean; error?: string }> {
  if (!hasFunctionsBaseUrl()) {
    return { success: false, error: 'Functions base URL is not configured' };
  }

  const result = await postJson<{ success: boolean; error?: string }>(
    '/storeSignedDocument',
    request,
    request.businessId
  );

  if (!result.ok || !result.data?.success) {
    return { success: false, error: result.error || 'Failed to persist signed document' };
  }

  return { success: true };
}

// Automation: Trigger → Action via Cloud Function/worker
// Sends only IDs/metadata; Cloud Function validates token + business scope and executes AutomationEngine server-side.

export interface AutomationFunctionRequest {
  triggerType: AutomationTriggerType;
  entityId: string;
  entityType: 'lead' | 'deal' | 'contact' | 'company' | 'activity';
  correlationId?: string;
  dryRun?: boolean;
  fromStatus?: LeadStatus;
  toStatus?: LeadStatus;
  fromStageId?: string;
  toStageId?: string;
  overdueDays?: number;
  reminderType?: AutomationReminderType;
  relatedEntityId?: string;
  relatedEntityType?: AutomationRelatedEntityType;
  businessId?: string;
}

export interface AutomationRunSummary {
  ruleId: string;
  status: AutomationRunStatus;
  reason?: string;
  actionType?: AutomationActionType;
  correlationId?: string;
}

export interface AutomationFunctionResponse {
  success: boolean;
  runs: AutomationRunSummary[];
  errors?: string[];
}

export async function triggerAutomationEvent(
  request: AutomationFunctionRequest
): Promise<AutomationFunctionResponse> {
  const result = await postJson<AutomationFunctionResponse>('/automationEvent', request, request.businessId);
  if (!result.ok || !result.data) {
    return {
      success: false,
      runs: [],
      errors: [result.error || 'Automation request failed'],
    };
  }

  return result.data;
}

// ---------------------------------------------------------------------------
// Route Optimization via Google Routes API (Cloud Function proxy)
// ---------------------------------------------------------------------------

export interface RouteOptimizationRequest {
  businessId: string;
  routeId?: string;
  startLatitude: number;
  startLongitude: number;
  stops: Array<{
    contactId: string;
    latitude: number;
    longitude: number;
  }>;
}

export interface RouteOptimizationResponse {
  success: boolean;
  optimizedOrder: Array<{
    contactId: string;
    order: number;
    distanceToNextMeters: number | null;
    durationToNextSeconds: number | null;
  }>;
  totalDistanceKm: number;
  totalDurationMinutes: number;
  source: string;
}

export async function optimizeRouteViaGoogle(
  request: RouteOptimizationRequest
): Promise<RouteOptimizationResponse | null> {
  const result = await postJson<RouteOptimizationResponse>(
    '/optimizeRouteGoogle',
    request,
    request.businessId
  );
  if (!result.ok || !result.data) {
    return null;
  }
  return result.data;
}
