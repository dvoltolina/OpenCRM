/**
 * API Types
 * Type definitions for the REST API layer
 *
 * Task 5: Cloud Functions - API Layer
 *
 * HIPAA Compliance:
 * - Request types include businessId for tenant isolation
 * - API keys are validated before any data access
 * - No PHI in error messages or logs
 */

import type { Request, Response, NextFunction } from 'express';

// ============================================
// API Scopes
// ============================================

export type ApiScope =
  | 'leads:read'
  | 'leads:write'
  | 'deals:read'
  | 'deals:write'
  | 'contacts:read'
  | 'contacts:write'
  | 'tasks:read'
  | 'tasks:write'
  | 'activities:read'
  | 'sequences:read'
  | 'sequences:write'
  | 'webhooks:manage';

// ============================================
// API Key Types
// ============================================

export interface ApiKeyData {
  id: string;
  businessId: string;
  name: string;
  scopes: ApiScope[];
  rateLimit: number;
  rateLimitWindow: number;
  isActive: boolean;
  expiresAt?: Date;
}

// ============================================
// Extended Request
// ============================================

/**
 * Extended Express Request with API authentication data
 */
export interface AuthenticatedRequest extends Request {
  /** Business ID from validated API key */
  businessId: string;
  /** Validated API key data */
  apiKey: ApiKeyData;
  /** Request metadata for logging */
  requestId: string;
}

// ============================================
// Middleware Types
// ============================================

export type AsyncHandler = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => Promise<void>;

export type ScopeMiddleware = (
  scope: ApiScope
) => (req: Request, res: Response, next: NextFunction) => void;

// ============================================
// Response Types
// ============================================

export interface ApiSuccessResponse<T> {
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
  };
}

export interface ApiPaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    hasMore: boolean;
  };
  meta: {
    requestId: string;
    timestamp: string;
  };
}

export interface ApiErrorResponse {
  error: {
    code: string;
    message: string;
    details?: Record<string, string>;
  };
  meta: {
    requestId: string;
    timestamp: string;
  };
}

// ============================================
// Query Parameters
// ============================================

export interface PaginationParams {
  page?: number;
  limit?: number;
  sort?: string;
  order?: 'asc' | 'desc';
}

export interface LeadQueryParams extends PaginationParams {
  status?: string;
  source?: string;
  assigneeId?: string;
  tags?: string;
  search?: string;
  createdAfter?: string;
  createdBefore?: string;
}

export interface DealQueryParams extends PaginationParams {
  pipelineId?: string;
  stageId?: string;
  status?: string;
  assigneeId?: string;
  clientId?: string;
  companyId?: string;
  minValue?: number;
  maxValue?: number;
  closeDateAfter?: string;
  closeDateBefore?: string;
}

export interface ContactQueryParams extends PaginationParams {
  lifecycle?: string;
  companyId?: string;
  tags?: string;
  search?: string;
  hasDeals?: string;
}

export interface TaskQueryParams extends PaginationParams {
  type?: string;
  isCompleted?: string;
  assigneeId?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  dueAfter?: string;
  dueBefore?: string;
  overdue?: string;
}

export interface ActivityQueryParams extends PaginationParams {
  type?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  createdById?: string;
  createdAfter?: string;
  createdBefore?: string;
}

// ============================================
// Request Body Types
// ============================================

export interface CreateLeadBody {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyName?: string;
  title?: string;
  source?: string;
  assigneeId?: string;
  tags?: string[];
  notes?: string;
  customFields?: Record<string, unknown>;
}

export interface UpdateLeadBody {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  companyName?: string;
  title?: string;
  status?: string;
  source?: string;
  assigneeId?: string;
  tags?: string[];
  notes?: string;
  customFields?: Record<string, unknown>;
}

export interface ConvertLeadBody {
  createDeal?: boolean;
  dealTitle?: string;
  dealValueCents?: number;
  pipelineId?: string;
  stageId?: string;
}

export interface CreateDealBody {
  title: string;
  pipelineId: string;
  stageId: string;
  valueCents?: number;
  currency?: string;
  expectedCloseDate?: string;
  clientId?: string;
  companyId?: string;
  assigneeId?: string;
  tags?: string[];
  notes?: string;
  customFields?: Record<string, unknown>;
}

export interface UpdateDealBody {
  title?: string;
  valueCents?: number;
  currency?: string;
  probability?: number;
  expectedCloseDate?: string;
  clientId?: string;
  companyId?: string;
  assigneeId?: string;
  tags?: string[];
  notes?: string;
  customFields?: Record<string, unknown>;
}

export interface MoveDealStageBody {
  stageId: string;
}

export interface DealOutcomeBody {
  wonReason?: string;
  lostReason?: string;
}

export interface CreateContactBody {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyId?: string;
  title?: string;
  lifecycle?: string;
  tags?: string[];
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
}

export interface UpdateContactBody {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  companyId?: string;
  title?: string;
  lifecycle?: string;
  tags?: string[];
  crmNotes?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
}

export interface CreateTaskBody {
  type: string;
  title: string;
  description?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
  assigneeId?: string;
  dueDate?: string;
  reminderAt?: string;
}

export interface UpdateTaskBody {
  title?: string;
  description?: string;
  dueDate?: string;
  reminderAt?: string;
  assigneeId?: string;
}

export interface CompleteTaskBody {
  completionNotes?: string;
}

export interface CreateActivityBody {
  type: string;
  title: string;
  description?: string;
  dealId?: string;
  clientId?: string;
  leadId?: string;
  companyId?: string;
}

export interface EnrollSequenceBody {
  entityType: 'lead' | 'contact' | 'deal';
  entityId: string;
  startAt?: string;
}

export interface CreateWebhookBody {
  name: string;
  url: string;
  events: string[];
  customHeaders?: Record<string, string>;
  retryEnabled?: boolean;
  maxRetries?: number;
}

export interface UpdateWebhookBody {
  name?: string;
  url?: string;
  events?: string[];
  isActive?: boolean;
  customHeaders?: Record<string, string>;
  retryEnabled?: boolean;
  maxRetries?: number;
}

// ============================================
// Validation Helpers
// ============================================

export const VALID_LEAD_STATUSES = ['new', 'contacted', 'qualified', 'unqualified', 'converted'];
export const VALID_LEAD_SOURCES = ['website', 'referral', 'coldCall', 'social', 'event', 'scheduler', 'other'];
export const VALID_DEAL_STATUSES = ['open', 'won', 'lost'];
export const VALID_CLIENT_LIFECYCLES = ['lead', 'prospect', 'active', 'inactive', 'churned'];
export const VALID_ACTIVITY_TYPES = ['call', 'email', 'meeting', 'note', 'task'];

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'https:';
  } catch {
    return false;
  }
}
