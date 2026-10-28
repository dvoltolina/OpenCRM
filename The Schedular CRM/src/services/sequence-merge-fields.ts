/**
 * Merge Field Processor
 * Handles template personalization for sequence emails/SMS
 *
 * HIPAA Compliance:
 * - Merge fields are replaced at send time
 * - No PHI stored in templates
 * - Only entity IDs logged, not merged content
 *
 * Phase 4 Implementation - Sequences Execution Engine
 */

// ============================================
// Types
// ============================================

export interface MergeFieldContext {
  contact: {
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
    title?: string;
  };
  company: {
    name?: string;
    industry?: string;
    website?: string;
  };
  sender: {
    name: string;
    email: string;
    phone?: string;
  };
  business: {
    name: string;
    phone?: string;
    website?: string;
    address?: string;
  };
  custom: Record<string, unknown>;
}

export interface MergeFieldDefinition {
  key: string;
  label: string;
  category: 'contact' | 'company' | 'sender' | 'business' | 'custom';
  example: string;
}

export interface ValidationResult {
  valid: boolean;
  unknownFields: string[];
  warnings?: string[];
}

// ============================================
// Merge Field Definitions
// ============================================

/**
 * Available merge fields by category.
 */
export const MERGE_FIELD_DEFINITIONS: MergeFieldDefinition[] = [
  // Contact fields
  { key: 'firstName', label: 'First Name', category: 'contact', example: 'John' },
  { key: 'lastName', label: 'Last Name', category: 'contact', example: 'Smith' },
  { key: 'fullName', label: 'Full Name', category: 'contact', example: 'John Smith' },
  { key: 'email', label: 'Email', category: 'contact', example: 'john@example.com' },
  { key: 'phone', label: 'Phone', category: 'contact', example: '(555) 123-4567' },
  { key: 'title', label: 'Title', category: 'contact', example: 'Marketing Director' },

  // Company fields
  { key: 'companyName', label: 'Company Name', category: 'company', example: 'Acme Corp' },
  { key: 'industry', label: 'Industry', category: 'company', example: 'Technology' },
  { key: 'website', label: 'Website', category: 'company', example: 'www.acme.com' },

  // Sender fields
  { key: 'senderName', label: 'Sender Name', category: 'sender', example: 'Jane Doe' },
  { key: 'senderEmail', label: 'Sender Email', category: 'sender', example: 'jane@example.com' },
  { key: 'senderPhone', label: 'Sender Phone', category: 'sender', example: '(555) 987-6543' },

  // Business fields
  { key: 'businessName', label: 'Business Name', category: 'business', example: 'My Company' },
  { key: 'businessPhone', label: 'Business Phone', category: 'business', example: '(555) 000-0000' },
  { key: 'businessWebsite', label: 'Business Website', category: 'business', example: 'www.mycompany.com' },
  { key: 'businessAddress', label: 'Business Address', category: 'business', example: '123 Main St' },
];

/**
 * Get all valid merge field keys.
 */
export function getValidMergeFieldKeys(): string[] {
  return MERGE_FIELD_DEFINITIONS.map((f) => f.key);
}

// ============================================
// Merge Field Processor
// ============================================

export class MergeFieldProcessor {
  private static readonly FIELD_PATTERN = /\{\{(\w+)\}\}/g;

  /**
   * Replace merge fields in template with values.
   * Uses {{fieldName}} syntax.
   */
  async process(template: string, context: MergeFieldContext): Promise<string> {
    const values = this.buildValueMap(context);

    return template.replace(MergeFieldProcessor.FIELD_PATTERN, (_match, fieldName) => {
      const value = values[fieldName];
      if (value !== undefined && value !== null && value !== '') {
        return String(value);
      }
      // Return empty string for missing values (don't leave {{field}})
      return '';
    });
  }

  /**
   * Process template synchronously.
   */
  processSync(template: string, context: MergeFieldContext): string {
    const values = this.buildValueMap(context);

    return template.replace(MergeFieldProcessor.FIELD_PATTERN, (_match, fieldName) => {
      const value = values[fieldName];
      if (value !== undefined && value !== null && value !== '') {
        return String(value);
      }
      return '';
    });
  }

  /**
   * Extract all merge fields from a template.
   */
  extractFields(template: string): string[] {
    const fields: string[] = [];
    let match;
    const pattern = new RegExp(MergeFieldProcessor.FIELD_PATTERN);

    while ((match = pattern.exec(template)) !== null) {
      if (!fields.includes(match[1])) {
        fields.push(match[1]);
      }
    }

    return fields;
  }

  /**
   * Validate template has valid merge fields.
   */
  validate(template: string): ValidationResult {
    const usedFields = this.extractFields(template);
    const validKeys = getValidMergeFieldKeys();
    const unknownFields: string[] = [];
    const warnings: string[] = [];

    for (const field of usedFields) {
      // Check if it's a known field or a custom field
      if (!validKeys.includes(field) && !field.startsWith('custom_')) {
        unknownFields.push(field);
      }
    }

    // Add warnings for potentially problematic patterns
    if (template.includes('{{') && !template.includes('}}')) {
      warnings.push('Template contains unclosed merge field brackets');
    }

    return {
      valid: unknownFields.length === 0,
      unknownFields,
      warnings: warnings.length > 0 ? warnings : undefined,
    };
  }

  /**
   * Preview template with sample data.
   */
  preview(template: string): string {
    const sampleContext = this.getSampleContext();
    return this.processSync(template, sampleContext);
  }

  /**
   * Get field definitions grouped by category.
   */
  getFieldsByCategory(): Record<string, MergeFieldDefinition[]> {
    return MERGE_FIELD_DEFINITIONS.reduce(
      (acc, field) => {
        if (!acc[field.category]) {
          acc[field.category] = [];
        }
        acc[field.category].push(field);
        return acc;
      },
      {} as Record<string, MergeFieldDefinition[]>
    );
  }

  /**
   * Build a flat value map from context.
   */
  private buildValueMap(context: MergeFieldContext): Record<string, unknown> {
    const values: Record<string, unknown> = {};

    // Contact fields
    if (context.contact) {
      values.firstName = context.contact.firstName;
      values.lastName = context.contact.lastName;
      values.fullName = [context.contact.firstName, context.contact.lastName]
        .filter(Boolean)
        .join(' ');
      values.email = context.contact.email;
      values.phone = context.contact.phone;
      values.title = context.contact.title;
    }

    // Company fields
    if (context.company) {
      values.companyName = context.company.name;
      values.industry = context.company.industry;
      values.website = context.company.website;
    }

    // Sender fields
    if (context.sender) {
      values.senderName = context.sender.name;
      values.senderEmail = context.sender.email;
      values.senderPhone = context.sender.phone;
    }

    // Business fields
    if (context.business) {
      values.businessName = context.business.name;
      values.businessPhone = context.business.phone;
      values.businessWebsite = context.business.website;
      values.businessAddress = context.business.address;
    }

    // Custom fields (prefixed with custom_)
    if (context.custom) {
      for (const [key, value] of Object.entries(context.custom)) {
        values[`custom_${key}`] = value;
        // Also allow without prefix for convenience
        values[key] = value;
      }
    }

    return values;
  }

  /**
   * Get sample context for previews.
   */
  private getSampleContext(): MergeFieldContext {
    return {
      contact: {
        firstName: 'John',
        lastName: 'Smith',
        email: 'john.smith@example.com',
        phone: '(555) 123-4567',
        title: 'Marketing Director',
      },
      company: {
        name: 'Acme Corporation',
        industry: 'Technology',
        website: 'www.acme.com',
      },
      sender: {
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '(555) 987-6543',
      },
      business: {
        name: 'Your Company',
        phone: '(555) 000-0000',
        website: 'www.yourcompany.com',
        address: '123 Business Ave, Suite 100',
      },
      custom: {},
    };
  }
}

// ============================================
// Singleton Instance
// ============================================

let processorInstance: MergeFieldProcessor | null = null;

export function getMergeFieldProcessor(): MergeFieldProcessor {
  if (!processorInstance) {
    processorInstance = new MergeFieldProcessor();
  }
  return processorInstance;
}

// ============================================
// Context Builders
// ============================================

/**
 * Build merge field context from lead data.
 */
export function buildContextFromLead(
  lead: {
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
    title?: string;
    companyName?: string;
  },
  sender: { name: string; email: string; phone?: string },
  business: { name: string; phone?: string; website?: string; address?: string }
): MergeFieldContext {
  return {
    contact: {
      firstName: lead.firstName,
      lastName: lead.lastName,
      email: lead.email,
      phone: lead.phone,
      title: lead.title,
    },
    company: {
      name: lead.companyName,
    },
    sender,
    business,
    custom: {},
  };
}

/**
 * Build merge field context from client data.
 */
export function buildContextFromClient(
  client: {
    firstName?: string;
    lastName?: string;
    email: string;
    phone?: string;
    title?: string;
    companyName?: string;
  },
  company: { name?: string; industry?: string; website?: string } | undefined,
  sender: { name: string; email: string; phone?: string },
  business: { name: string; phone?: string; website?: string; address?: string }
): MergeFieldContext {
  return {
    contact: {
      firstName: client.firstName,
      lastName: client.lastName,
      email: client.email,
      phone: client.phone,
      title: client.title,
    },
    company: {
      name: company?.name || client.companyName,
      industry: company?.industry,
      website: company?.website,
    },
    sender,
    business,
    custom: {},
  };
}
