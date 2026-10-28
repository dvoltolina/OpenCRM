/**
 * Lead Conversion Service
 * Business logic for converting leads to contacts and deals
 *
 * Agent CRM-11 Implementation
 * Dependencies: Agent CRM-03 (leads), Agent CRM-04 (deals), Agent CRM-05 (contacts)
 *
 * HIPAA Compliance: All operations require SecurityContext for multi-tenant isolation
 */

import { getLeadRepository } from '../data/repositories/lead-repository';
import { getContactRepository } from '../data/repositories/contact-repository';
import { getDealRepository } from '../data/repositories/deal-repository';
import { getActivityRepository } from '../data/repositories/activity-repository';
import type { SecurityContext } from '../data/repositories/repository-types';
import type { Lead, Client, Deal } from '../types/models';

// ============================================
// Types
// ============================================

export interface ConversionOptions {
  /** ID of the lead to convert */
  leadId: string;
  /** Whether to create a deal during conversion */
  createDeal: boolean;
  /** Deal data if creating a deal */
  dealData?: {
    title: string;
    valueCents: number;
    pipelineId: string;
    stageId: string;
    expectedCloseDate?: Date;
    currency?: string;
    probability?: number;
  };
  /** If provided, link to existing client instead of creating new */
  existingClientId?: string;
  /** Override client data from lead */
  clientData?: Partial<Client>;
}

export interface ConversionResult {
  /** The converted lead */
  lead: Lead;
  /** The created or linked client */
  client: Client;
  /** The created deal (if requested) */
  deal?: Deal;
}

export interface DuplicateMatch {
  /** The potential duplicate client */
  client: Client;
  /** Match type (email, phone, name) */
  matchType: 'email' | 'phone' | 'name';
  /** Confidence score 0-100 */
  confidence: number;
}

export interface CanConvertResult {
  canConvert: boolean;
  reason?: string;
}

// ============================================
// Lead Conversion Service
// ============================================

export class LeadConversionService {
  /**
   * Check if a lead can be converted
   */
  async canConvert(
    context: SecurityContext,
    leadId: string
  ): Promise<CanConvertResult> {
    const leadRepo = getLeadRepository();

    const leadResult = await leadRepo.getById(context, leadId);
    if (!leadResult.success) {
      return {
        canConvert: false,
        reason: leadResult.error.message,
      };
    }

    const lead = leadResult.data;

    // Check if already converted
    if (lead.status === 'converted') {
      return {
        canConvert: false,
        reason: 'Lead has already been converted',
      };
    }

    // Check if lead has required fields for conversion
    if (!lead.email) {
      return {
        canConvert: false,
        reason: 'Lead must have an email address to convert',
      };
    }

    return { canConvert: true };
  }

  /**
   * Find potential duplicate clients for a lead
   */
  async suggestExistingClient(
    context: SecurityContext,
    lead: Lead
  ): Promise<DuplicateMatch[]> {
    const contactRepo = getContactRepository();
    const matches: DuplicateMatch[] = [];

    // Search by email (exact match - highest confidence)
    if (lead.email) {
      const emailResult = await contactRepo.search(context, lead.email);
      if (emailResult.success) {
        for (const client of emailResult.data) {
          if (client.email?.toLowerCase() === lead.email.toLowerCase()) {
            matches.push({
              client,
              matchType: 'email',
              confidence: 100,
            });
          }
        }
      }
    }

    // Search by phone (normalized match)
    if (lead.phone) {
      const normalizedPhone = this.normalizePhone(lead.phone);
      const phoneResult = await contactRepo.search(context, normalizedPhone);
      if (phoneResult.success) {
        for (const client of phoneResult.data) {
          if (client.phone && this.normalizePhone(client.phone) === normalizedPhone) {
            // Don't add if already matched by email
            if (!matches.some((m) => m.client.id === client.id)) {
              matches.push({
                client,
                matchType: 'phone',
                confidence: 90,
              });
            }
          }
        }
      }
    }

    // Search by name + company (fuzzy match)
    const fullName = `${lead.firstName} ${lead.lastName}`;
    const nameResult = await contactRepo.search(context, fullName);
    if (nameResult.success) {
      for (const client of nameResult.data) {
        const clientName = `${client.firstName} ${client.lastName}`.toLowerCase();
        const leadName = fullName.toLowerCase();

        // Check if names match and company matches (if both have company)
        if (clientName === leadName) {
          // Don't add if already matched
          if (!matches.some((m) => m.client.id === client.id)) {
            let confidence = 60;

            // Boost confidence if company matches
            if (lead.companyName && client.companyName) {
              if (client.companyName.toLowerCase() === lead.companyName.toLowerCase()) {
                confidence = 80;
              }
            }

            matches.push({
              client,
              matchType: 'name',
              confidence,
            });
          }
        }
      }
    }

    // Sort by confidence (highest first)
    return matches.sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * Convert a lead to a client and optionally create a deal
   */
  async convert(
    context: SecurityContext,
    options: ConversionOptions
  ): Promise<ConversionResult> {
    const leadRepo = getLeadRepository();
    const contactRepo = getContactRepository();
    const dealRepo = getDealRepository();
    const activityRepo = getActivityRepository();

    // Step 1: Validate lead can be converted
    const canConvertResult = await this.canConvert(context, options.leadId);
    if (!canConvertResult.canConvert) {
      throw new Error(canConvertResult.reason || 'Cannot convert lead');
    }

    // Step 2: Get lead data
    const leadResult = await leadRepo.getById(context, options.leadId);
    if (!leadResult.success) {
      throw new Error(leadResult.error.message);
    }
    const lead = leadResult.data;

    // Step 3: Create or link client
    let client: Client;

    if (options.existingClientId) {
      // Link to existing client
      const clientResult = await contactRepo.getById(context, options.existingClientId);
      if (!clientResult.success) {
        throw new Error(`Client not found: ${clientResult.error.message}`);
      }
      client = clientResult.data;

      // Optionally update client with lead data
      if (options.clientData) {
        const updateResult = await contactRepo.update(
          context,
          options.existingClientId,
          options.clientData
        );
        if (updateResult.success) {
          client = updateResult.data;
        }
      }
    } else {
      // Create new client from lead
      const clientData: Omit<Client, 'id' | 'createdAt' | 'updatedAt'> = {
        firstName: options.clientData?.firstName || lead.firstName,
        lastName: options.clientData?.lastName || lead.lastName,
        email: options.clientData?.email || lead.email,
        phone: options.clientData?.phone || lead.phone,
        companyName: options.clientData?.companyName || lead.companyName,
        title: options.clientData?.title || lead.title,
        lifecycle: 'prospect',
        leadSource: lead.source,
        tags: [...(lead.tags || []), ...(options.clientData?.tags || [])],
        crmNotes: lead.notes,
        ...options.clientData,
      };

      const createResult = await contactRepo.create(context, clientData);
      if (!createResult.success) {
        throw new Error(`Failed to create client: ${createResult.error.message}`);
      }
      client = createResult.data;
    }

    // Step 4: Optionally create deal
    let deal: Deal | undefined;

    if (options.createDeal && options.dealData) {
      const dealData: Omit<Deal, 'id' | 'createdAt' | 'updatedAt'> = {
        title: options.dealData.title,
        pipelineId: options.dealData.pipelineId,
        stageId: options.dealData.stageId,
        valueCents: options.dealData.valueCents,
        currency: options.dealData.currency || 'USD',
        probability: options.dealData.probability ?? 25,
        expectedCloseDate: options.dealData.expectedCloseDate,
        status: 'open',
        clientId: client.id,
        clientName: `${client.firstName} ${client.lastName}`,
        companyName: client.companyName,
        assigneeId: lead.assigneeId,
        assigneeName: lead.assigneeName,
        tags: lead.tags || [],
      };

      const dealResult = await dealRepo.create(context, dealData);
      if (!dealResult.success) {
        // Rollback: delete the created client if we created one
        if (!options.existingClientId) {
          await contactRepo.delete(context, client.id);
        }
        throw new Error(`Failed to create deal: ${dealResult.error.message}`);
      }
      deal = dealResult.data;
    }

    // Step 5: Mark lead as converted
    const convertResult = await leadRepo.markConverted(
      context,
      options.leadId,
      client.id,
      deal?.id
    );
    if (!convertResult.success) {
      // Rollback: delete created entities
      if (deal) {
        await dealRepo.delete(context, deal.id);
      }
      if (!options.existingClientId) {
        await contactRepo.delete(context, client.id);
      }
      throw new Error(`Failed to mark lead as converted: ${convertResult.error.message}`);
    }

    // Step 6: Log conversion activity
    await activityRepo.create(context, {
      type: 'note',
      title: 'Lead Converted',
      description: `Lead "${lead.firstName} ${lead.lastName}" was converted to a contact${deal ? ` and deal "${deal.title}"` : ''}.`,
      clientId: client.id,
      dealId: deal?.id,
      isCompleted: true,
      completedAt: new Date(),
      createdById: context.userId,
      createdByName: context.userName,
    });

    return {
      lead: convertResult.data,
      client,
      deal,
    };
  }

  /**
   * Normalize phone number for comparison
   */
  private normalizePhone(phone: string): string {
    return phone.replace(/\D/g, '');
  }
}

// ============================================
// Singleton Export
// ============================================

let leadConversionServiceInstance: LeadConversionService | null = null;

export function getLeadConversionService(): LeadConversionService {
  if (!leadConversionServiceInstance) {
    leadConversionServiceInstance = new LeadConversionService();
  }
  return leadConversionServiceInstance;
}
