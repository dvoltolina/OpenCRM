/**
 * Web Form Repository
 * Firestore data access for web forms with CRUD and public endpoint support
 *
 * Agent Web Forms Implementation
 * Path: businesses/{businessId}/web_forms/{formId}
 *
 * HIPAA Compliance:
 * - All operations require SecurityContext for multi-tenant isolation
 * - Public form config endpoint returns sanitized data only
 * - No PHI in audit logs for form submissions
 */

import { getDocs, increment } from 'firebase/firestore';
import { ShareableRepository } from './access-control';
import type {
  SecurityContext,
  QueryOptions,
  RepositoryResult,
  PaginatedResult,
  ValidationResult,
  Validator,
} from './repository-types';
import {
  ValidationError,
  failedResult,
  successResult,
  NotFoundError,
} from '../errors/repository-errors';
import { buildQuery, prepareForUpdate } from './firestore-utils';
import type {
  WebForm,
  WebFormStatus,
  WebFormField,
  PublicWebFormConfig,
} from '../../types/web-forms';
import {
  toPublicFormConfig,
  DEFAULT_SPAM_PROTECTION as defaultSpamProtection,
  DEFAULT_STYLING as defaultStyling,
  DEFAULT_SETTINGS as defaultSettings,
  DEFAULT_STATS as defaultStats,
} from '../../types/web-forms';

// ============================================
// Validation
// ============================================

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const HEX_COLOR_REGEX = /^#[0-9A-Fa-f]{6}$/;
const URL_REGEX = /^https?:\/\/.+/;

/**
 * Validate web form data
 */
export function validateWebForm(data: Partial<WebForm>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Name validation
  if (data.name !== undefined) {
    if (!data.name?.trim()) {
      errors.push({
        field: 'name',
        message: 'Form name is required',
        code: 'REQUIRED',
      });
    } else if (data.name.length > 100) {
      errors.push({
        field: 'name',
        message: 'Form name must be less than 100 characters',
        code: 'TOO_LONG',
      });
    }
  }

  // Description validation
  if (data.description && data.description.length > 500) {
    errors.push({
      field: 'description',
      message: 'Description must be less than 500 characters',
      code: 'TOO_LONG',
    });
  }

  // Status validation
  if (data.status && !['active', 'inactive'].includes(data.status)) {
    errors.push({
      field: 'status',
      message: 'Status must be active or inactive',
      code: 'INVALID_FORMAT',
    });
  }

  // Fields validation
  if (data.fields) {
    const fieldErrors = validateFormFields(data.fields);
    errors.push(...fieldErrors);
  }

  // Settings validation
  if (data.settings) {
    if (data.settings.redirectUrl && !URL_REGEX.test(data.settings.redirectUrl)) {
      errors.push({
        field: 'settings.redirectUrl',
        message: 'Redirect URL must be a valid HTTP/HTTPS URL',
        code: 'INVALID_FORMAT',
      });
    }

    if (data.settings.notifyEmails) {
      for (let i = 0; i < data.settings.notifyEmails.length; i++) {
        const email = data.settings.notifyEmails[i];
        if (!EMAIL_REGEX.test(email)) {
          errors.push({
            field: `settings.notifyEmails[${i}]`,
            message: `Invalid email format: ${email}`,
            code: 'INVALID_FORMAT',
          });
        }
      }
    }
  }

  // Spam protection validation
  if (data.spamProtection) {
    if (
      data.spamProtection.rateLimit !== undefined &&
      (data.spamProtection.rateLimit < 1 || data.spamProtection.rateLimit > 100)
    ) {
      errors.push({
        field: 'spamProtection.rateLimit',
        message: 'Rate limit must be between 1 and 100',
        code: 'OUT_OF_RANGE',
      });
    }
  }

  // Styling validation
  if (data.styling) {
    if (data.styling.primaryColor && !HEX_COLOR_REGEX.test(data.styling.primaryColor)) {
      errors.push({
        field: 'styling.primaryColor',
        message: 'Primary color must be a valid hex color (e.g., #3B82F6)',
        code: 'INVALID_FORMAT',
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
}

/**
 * Validate form fields array
 */
function validateFormFields(
  fields: WebFormField[]
): Array<{ field: string; message: string; code: string }> {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  if (!Array.isArray(fields)) {
    errors.push({
      field: 'fields',
      message: 'Fields must be an array',
      code: 'INVALID_FORMAT',
    });
    return errors;
  }

  // Check for required email field
  const hasEmailField = fields.some((f) => f.mapToField === 'email');
  if (!hasEmailField) {
    errors.push({
      field: 'fields',
      message: 'Form must have at least one email field',
      code: 'REQUIRED',
    });
  }

  // Validate individual fields
  const fieldIds = new Set<string>();
  for (let i = 0; i < fields.length; i++) {
    const field = fields[i];

    // Check for duplicate IDs
    if (fieldIds.has(field.id)) {
      errors.push({
        field: `fields[${i}].id`,
        message: `Duplicate field ID: ${field.id}`,
        code: 'DUPLICATE',
      });
    }
    fieldIds.add(field.id);

    // Validate field properties
    if (!field.id?.trim()) {
      errors.push({
        field: `fields[${i}].id`,
        message: 'Field ID is required',
        code: 'REQUIRED',
      });
    }

    if (!field.label?.trim()) {
      errors.push({
        field: `fields[${i}].label`,
        message: 'Field label is required',
        code: 'REQUIRED',
      });
    }

    const validTypes = ['text', 'email', 'phone', 'textarea', 'select', 'checkbox', 'hidden'];
    if (!validTypes.includes(field.type)) {
      errors.push({
        field: `fields[${i}].type`,
        message: `Invalid field type: ${field.type}`,
        code: 'INVALID_FORMAT',
      });
    }

    // Select fields must have options
    if (field.type === 'select' && (!field.options || field.options.length === 0)) {
      errors.push({
        field: `fields[${i}].options`,
        message: 'Select fields must have at least one option',
        code: 'REQUIRED',
      });
    }

    // Validate mapToField
    const validMappings = [
      'firstName',
      'lastName',
      'email',
      'phone',
      'companyName',
      'title',
      'source',
      'notes',
    ];
    if (
      !validMappings.includes(field.mapToField) &&
      !field.mapToField.startsWith('customField_')
    ) {
      errors.push({
        field: `fields[${i}].mapToField`,
        message: `Invalid field mapping: ${field.mapToField}`,
        code: 'INVALID_FORMAT',
      });
    }
  }

  return errors;
}

/**
 * Validate required fields for form creation
 */
export function validateWebFormCreate(data: Partial<WebForm>): ValidationResult {
  const errors: Array<{ field: string; message: string; code: string }> = [];

  // Check required fields
  if (!data.name?.trim()) {
    errors.push({
      field: 'name',
      message: 'Form name is required',
      code: 'REQUIRED',
    });
  }

  if (!data.fields || data.fields.length === 0) {
    errors.push({
      field: 'fields',
      message: 'Form must have at least one field',
      code: 'REQUIRED',
    });
  }

  // Run general validation
  const generalValidation = validateWebForm(data);
  errors.push(...generalValidation.errors);

  return {
    isValid: errors.length === 0,
    errors,
  };
}

// ============================================
// Web Form Repository Class
// ============================================

/**
 * WebFormRepository
 * Provides CRUD operations for web forms
 */
export class WebFormRepository extends ShareableRepository<WebForm> {
  protected entityName = 'web_form';
  protected sensitiveFields: Array<keyof WebForm> = [];

  constructor() {
    super({
      collectionName: 'web_forms',
      softDelete: false,
    });
    this.setValidator(validateWebForm as Validator<WebForm>);
  }

  // ============================================
  // Create Override
  // ============================================

  /**
   * Create a new web form with required field validation and defaults
   */
  async create(
    context: SecurityContext,
    data: Omit<WebForm, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<WebForm>> {
    // Validate required fields for creation
    const validation = validateWebFormCreate(data);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Apply defaults
    const formData: Omit<WebForm, 'id' | 'createdAt' | 'updatedAt'> = {
      ...data,
      status: data.status || 'inactive',
      settings: {
        ...defaultSettings,
        ...(data.settings ?? {}),
      },
      spamProtection: {
        ...defaultSpamProtection,
        ...(data.spamProtection ?? {}),
      },
      styling: {
        ...defaultStyling,
        ...(data.styling ?? {}),
      },
      stats: {
        ...defaultStats,
        ...(data.stats ?? {}),
      },
    };

    return super.create(context, formData, customId);
  }

  // ============================================
  // Query Methods
  // ============================================

  /**
   * Get forms by status
   */
  async getByStatus(
    context: SecurityContext,
    status: WebFormStatus,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<WebForm>>> {
    return this.getAll(context, {
      ...options,
      where: [
        ...(options.where || []),
        { field: 'status', operator: '==', value: status },
      ],
    });
  }

  /**
   * Get active forms for a business
   * Used by embed script to find available forms
   */
  async getActiveByBusinessId(
    context: SecurityContext,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<WebForm>>> {
    return this.getByStatus(context, 'active', options);
  }

  /**
   * Get public form configuration (no auth required)
   * Returns sanitized form config for embedding
   *
   * SECURITY NOTE: This method bypasses normal auth checks
   * and returns only public-safe data. Must be called with
   * a system-level context from a Cloud Function.
   */
  async getPublicForm(
    businessId: string,
    formId: string
  ): Promise<RepositoryResult<PublicWebFormConfig>> {
    try {
      // Create a system context for this read
      const systemContext: SecurityContext = {
        businessId,
        userId: 'system',
        userName: 'System',
        userRole: 'system',
      };

      const collectionRef = this.getCollectionRef(systemContext);
      const snapshot = await getDocs(
        buildQuery(collectionRef, {
          where: [{ field: '__name__', operator: '==', value: formId }],
          limit: 1,
        })
      );

      if (snapshot.empty) {
        return failedResult(new NotFoundError('web_form', formId));
      }

      const doc = snapshot.docs[0];
      const data = doc.data();

      // Check if form is active
      if (data.status !== 'active') {
        return failedResult(new NotFoundError('web_form', formId));
      }

      // Convert to WebForm type and sanitize for public use
      const form = {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.() || new Date(),
        updatedAt: data.updatedAt?.toDate?.() || undefined,
      } as WebForm;

      const publicConfig = toPublicFormConfig(form);

      // Audit log with minimal info (no PHI)
      await this.logAudit(systemContext, 'read', formId, {
        public: true,
        action: 'getPublicForm',
      });

      return successResult(publicConfig);
    } catch (error) {
      return failedResult(error, 'Failed to get public form config');
    }
  }

  // ============================================
  // Stats Methods
  // ============================================

  /**
   * Increment submission count for a form
   * Called after successful form submission
   */
  async incrementSubmissionCount(
    context: SecurityContext,
    formId: string
  ): Promise<RepositoryResult<void>> {
    try {
      this.ensureSecurityContext(context);

      const docRef = this.getDocRef(context, formId);
      const now = new Date();
      const currentMonth = now.getMonth();
      const currentYear = now.getFullYear();

      // Get current form to check if we need to reset monthly counter
      const formResult = await this.getById(context, formId);
      if (!formResult.success) {
        return { success: false, data: null, error: formResult.error };
      }

      const form = formResult.data;
      const lastUpdate = form.updatedAt || form.createdAt;
      const lastMonth = lastUpdate.getMonth();
      const lastYear = lastUpdate.getFullYear();

      // Reset monthly counter if new month
      const resetMonthly = currentMonth !== lastMonth || currentYear !== lastYear;

      const updateData = prepareForUpdate({
        'stats.totalSubmissions': increment(1),
        'stats.submissionsThisMonth': resetMonthly ? 1 : increment(1),
      });

      const { updateDoc } = await import('firebase/firestore');
      await updateDoc(docRef, updateData);

      // Audit log (no PHI)
      await this.logAudit(context, 'update', formId, {
        action: 'incrementSubmissionCount',
      });

      return successResult(undefined);
    } catch (error) {
      return failedResult(error, 'Failed to increment submission count');
    }
  }

  // ============================================
  // Search Methods
  // ============================================

  /**
   * Search forms by name
   */
  async search(
    context: SecurityContext,
    query: string,
    options: QueryOptions = {}
  ): Promise<RepositoryResult<PaginatedResult<WebForm>>> {
    if (!query || query.trim().length === 0) {
      return this.getAll(context, options);
    }

    const normalizedQuery = query.toLowerCase().trim();

    // Get all forms and filter client-side
    const result = await this.getAll(context, {
      ...options,
      limit: undefined,
    });

    if (!result.success) {
      return result;
    }

    const filtered = result.data.data.filter((form) => {
      const name = form.name?.toLowerCase() || '';
      const description = form.description?.toLowerCase() || '';
      return name.includes(normalizedQuery) || description.includes(normalizedQuery);
    });

    const limitedResults = options.limit
      ? filtered.slice(0, options.limit)
      : filtered;

    return successResult({
      data: limitedResults,
      lastDoc: null,
      hasMore: options.limit ? filtered.length > options.limit : false,
    });
  }
}

// ============================================
// Singleton Export
// ============================================

let webFormRepositoryInstance: WebFormRepository | null = null;

export function getWebFormRepository(): WebFormRepository {
  if (!webFormRepositoryInstance) {
    webFormRepositoryInstance = new WebFormRepository();
  }
  return webFormRepositoryInstance;
}
