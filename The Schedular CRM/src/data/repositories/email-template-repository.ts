/**
 * Email Template Repository
 * Manages email templates in Firestore
 *
 * HIPAA Compliance:
 * - Templates MUST NOT contain PHI placeholders
 * - Audit logging for all template operations
 * - Tenant isolation via businessId
 *
 * Storage Path: businesses/{businessId}/email_templates/{templateId}
 */

import { BaseRepository } from './base-repository';
import type {
  SecurityContext,
  RepositoryResult,
  PaginatedResult,
  QueryOptions,
} from './repository-types';
import type { EmailTemplate, EmailTemplateType } from '../../types/email';
import type { EmailTemplate as IntegrationEmailTemplate } from '../../types/email-integration';
import {
  successResult,
  failedResult,
  ValidationError,
  AuthorizationError,
} from '../errors/repository-errors';

type EmailTemplateRecord = EmailTemplate & Partial<IntegrationEmailTemplate>;

// ============================================
// Repository Implementation
// ============================================

export class EmailTemplateRepository extends BaseRepository<EmailTemplateRecord> {
  constructor() {
    super({
      collectionName: 'email_templates',
      softDelete: true,
    });
  }

  /**
   * Validate template data
   * Ensures NO PHI placeholders in content
   */
  private ensureManageAccess(context: SecurityContext): void {
    const allowed = ['owner', 'admin', 'manager'];
    if (!allowed.includes(context.userRole)) {
      throw new AuthorizationError('Only owners/admins/managers can manage message templates');
    }
  }

  private validateTemplate(
    data: Partial<EmailTemplateRecord>
  ): { isValid: boolean; errors: Array<{ field: string; message: string }> } {
    const errors: Array<{ field: string; message: string }> = [];

    // Check for PHI placeholders in subject
    if (data.subject) {
      const phiPatterns = [
        /\{\{.*name.*\}\}/i,
        /\{\{.*phone.*\}\}/i,
        /\{\{.*email.*\}\}/i,
        /\{\{.*address.*\}\}/i,
        /\{\{.*ssn.*\}\}/i,
        /\{\{.*dob.*\}\}/i,
        /\{\{.*appointment.*time.*\}\}/i,
        /\{\{.*provider.*\}\}/i,
        /\{\{.*diagnosis.*\}\}/i,
        /\{\{.*treatment.*\}\}/i,
      ];

      for (const pattern of phiPatterns) {
        if (pattern.test(data.subject)) {
          errors.push({ field: 'subject', message: 'Subject contains potential PHI placeholder' });
          break;
        }
      }
    }

    // Check for PHI in body
    const bodyContent = [
      data.textBody,
      data.htmlBody,
      data.bodyText,
      data.bodyHtml,
    ]
      .filter(Boolean)
      .join('');

    if (bodyContent) {
      const phiPatterns = [
        /\{\{.*client.*name.*\}\}/i,
        /\{\{.*patient.*name.*\}\}/i,
        /\{\{.*first.*name.*\}\}/i,
        /\{\{.*last.*name.*\}\}/i,
        /\{\{.*ssn.*\}\}/i,
        /\{\{.*dob.*\}\}/i,
        /\{\{.*diagnosis.*\}\}/i,
        /\{\{.*treatment.*\}\}/i,
        /\{\{.*appointment.*time.*\}\}/i,
        /\{\{.*appointment.*date.*\}\}/i,
        /\{\{.*provider.*name.*\}\}/i,
      ];

      for (const pattern of phiPatterns) {
        if (pattern.test(bodyContent)) {
          errors.push({ field: 'body', message: 'Body contains potential PHI placeholder - use secure portal links instead' });
          break;
        }
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  private normalizeCreateData(
    context: SecurityContext,
    data: Omit<EmailTemplateRecord, 'id' | 'createdAt' | 'updatedAt'>
  ): Omit<EmailTemplateRecord, 'id' | 'createdAt' | 'updatedAt'> {
    const bodyHtml = data.bodyHtml ?? data.htmlBody ?? '';
    const bodyText = data.bodyText ?? data.textBody ?? '';

    return {
      ...data,
      businessId: data.businessId || context.businessId,
      bodyHtml,
      htmlBody: bodyHtml,
      bodyText,
      textBody: bodyText,
      availableMergeFields: data.availableMergeFields || [],
      usageCount: data.usageCount ?? 0,
      isActive: data.isActive ?? true,
    };
  }

  private normalizeUpdateData(
    context: SecurityContext,
    data: Partial<Omit<EmailTemplateRecord, 'id' | 'createdAt'>>
  ): Partial<Omit<EmailTemplateRecord, 'id' | 'createdAt'>> {
    const normalized: Partial<Omit<EmailTemplateRecord, 'id' | 'createdAt'>> = {
      ...data,
    };

    if (data.bodyHtml !== undefined || data.htmlBody !== undefined) {
      const bodyHtml = data.bodyHtml ?? data.htmlBody ?? '';
      normalized.bodyHtml = bodyHtml;
      normalized.htmlBody = bodyHtml;
    }

    if (data.bodyText !== undefined || data.textBody !== undefined) {
      const bodyText = data.bodyText ?? data.textBody ?? '';
      normalized.bodyText = bodyText;
      normalized.textBody = bodyText;
    }

    if (!normalized.businessId && data.businessId !== undefined) {
      normalized.businessId = data.businessId || context.businessId;
    }

    return normalized;
  }

  /**
   * Create a new email template
   */
  async create(
    context: SecurityContext,
    data: Omit<EmailTemplateRecord, 'id' | 'createdAt' | 'updatedAt'>,
    customId?: string
  ): Promise<RepositoryResult<EmailTemplateRecord>> {
    this.ensureManageAccess(context);

    const normalized = this.normalizeCreateData(context, data);

    // Validate for PHI
    const validation = this.validateTemplate(normalized);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Add creator info
    const templateData = {
      ...normalized,
      createdById: context.userId,
    };

    return super.create(context, templateData, customId);
  }

  /**
   * Update an email template
   */
  async update(
    context: SecurityContext,
    id: string,
    data: Partial<Omit<EmailTemplateRecord, 'id' | 'createdAt'>>
  ): Promise<RepositoryResult<EmailTemplateRecord>> {
    this.ensureManageAccess(context);

    const normalized = this.normalizeUpdateData(context, data);

    // Validate for PHI
    const validation = this.validateTemplate(normalized);
    if (!validation.isValid) {
      return failedResult(ValidationError.fromErrors(validation.errors));
    }

    // Add updater info
    const updateData = {
      ...normalized,
      updatedById: context.userId,
    };

    return super.update(context, id, updateData);
  }

  /**
   * Get templates by type
   */
  async getByType(
    context: SecurityContext,
    type: EmailTemplateType
  ): Promise<RepositoryResult<PaginatedResult<EmailTemplateRecord>>> {
    const options: QueryOptions = {
      where: [
        { field: 'type', operator: '==', value: type },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get templates by category
   */
  async getByCategory(
    context: SecurityContext,
    category: 'transactional' | 'marketing' | 'system' | 'outreach' | 'followup' | 'nurture'
  ): Promise<RepositoryResult<PaginatedResult<EmailTemplateRecord>>> {
    const options: QueryOptions = {
      where: [
        { field: 'category', operator: '==', value: category },
        { field: 'isActive', operator: '==', value: true },
      ],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get active templates
   */
  async getActiveTemplates(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<EmailTemplateRecord>>> {
    const options: QueryOptions = {
      where: [{ field: 'isActive', operator: '==', value: true }],
      orderBy: { field: 'name', direction: 'asc' },
    };

    return this.getAll(context, options);
  }

  /**
   * Get default template for a type
   */
  async getDefaultTemplate(
    context: SecurityContext,
    type: EmailTemplateType
  ): Promise<RepositoryResult<EmailTemplateRecord | null>> {
    const result = await this.getByType(context, type);

    if (!result.success) {
      return { success: false, data: null, error: result.error };
    }

    // Return first active template of this type
    const template = result.data.data[0] || null;
    return successResult(template);
  }

  /**
   * Deactivate a template (soft disable)
   */
  async deactivate(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<EmailTemplateRecord>> {
    this.ensureManageAccess(context);
    return this.update(context, id, { isActive: false });
  }

  /**
   * Activate a template
   */
  async activate(
    context: SecurityContext,
    id: string
  ): Promise<RepositoryResult<EmailTemplateRecord>> {
    this.ensureManageAccess(context);
    return this.update(context, id, { isActive: true });
  }

  /**
   * Active templates for pickers.
   */
  async getActive(
    context: SecurityContext
  ): Promise<RepositoryResult<PaginatedResult<EmailTemplateRecord>>> {
    return this.getActiveTemplates(context);
  }

  /**
   * Increment usage counter when a template is sent.
   */
  async incrementUsage(
    context: SecurityContext,
    templateId: string
  ): Promise<RepositoryResult<EmailTemplateRecord>> {
    const templateResult = await this.getById(context, templateId);
    if (!templateResult.success || !templateResult.data) {
      return templateResult;
    }

    const current = templateResult.data.usageCount || 0;
    return this.update(context, templateId, { usageCount: current + 1 });
  }
}

// ============================================
// Singleton Instance
// ============================================

let emailTemplateRepositoryInstance: EmailTemplateRepository | null = null;

export function getEmailTemplateRepository(): EmailTemplateRepository {
  if (!emailTemplateRepositoryInstance) {
    emailTemplateRepositoryInstance = new EmailTemplateRepository();
  }
  return emailTemplateRepositoryInstance;
}
