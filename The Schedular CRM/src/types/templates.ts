/**
 * Template Types
 * Types for form templates, e-signatures, and secure document sharing
 *
 * Agent CRM-30 Implementation
 * Dependencies: CRM-05 (clients), CRM-06 (activities)
 *
 * HIPAA Compliance:
 * - All templates scoped by businessId
 * - Signature metadata stored securely (no plain text signature images)
 * - Expiring links with access logging
 * - Audit trail for all document access
 */

// ============================================
// Template Types
// ============================================

export type TemplateCategory = 'therapy' | 'real_estate' | 'accounting' | 'custom';

export type TemplateFieldType = 'text' | 'number' | 'date' | 'signature' | 'checkbox' | 'select' | 'textarea' | 'email' | 'phone';

export interface TemplateField {
  id: string;
  type: TemplateFieldType;
  label: string;
  placeholder?: string;
  required: boolean;
  options?: string[]; // For select fields
  defaultValue?: string | number | boolean;
  validation?: {
    min?: number;
    max?: number;
    pattern?: string;
    message?: string;
  };
  order: number;
  helpText?: string;
}

export interface FormTemplate {
  id: string;
  businessId: string;
  name: string;
  description?: string;
  category: TemplateCategory;
  fields: TemplateField[];

  // Metadata
  isSystem: boolean; // System/seed templates (cannot be deleted)
  isActive: boolean;
  tags: string[];

  // Usage tracking
  usageCount: number;
  lastUsedAt?: Date;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName: string;
}

// ============================================
// Template Instance (filled form)
// ============================================

export interface TemplateFieldValue {
  fieldId: string;
  value: string | number | boolean | null;
  signatureId?: string; // Reference to signature metadata if field type is signature
}

export interface TemplateInstance {
  id: string;
  businessId: string;
  templateId: string;
  templateName: string;

  // Associated entities
  clientId?: string;
  clientName?: string;
  dealId?: string;
  dealName?: string;
  leadId?: string;

  // Form data
  fieldValues: TemplateFieldValue[];

  // Status
  status: 'draft' | 'pending_signature' | 'completed' | 'expired';
  completedAt?: Date;
  expiresAt?: Date;

  // Signatures
  signatures: SignatureMetadata[];

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName: string;
}

// ============================================
// E-Signature Types
// ============================================

export interface SignatureMetadata {
  id: string;
  businessId: string;

  // Signer info
  signerId: string; // User ID or client ID
  signerEmail: string;
  signerName: string;
  signerRole?: string; // e.g., 'client', 'therapist', 'agent'

  // Document reference
  documentId: string; // Template instance ID
  documentType: 'template_instance' | 'deal_document' | 'client_document';
  fieldId?: string; // Specific field in template if applicable

  // Signature details
  signedAt: Date;
  ipAddress?: string; // Optional for extra security
  userAgent?: string; // Browser/device info

  // Verification
  verificationCode?: string; // Email verification code if used
  isVerified: boolean;

  // IMPORTANT: Actual signature image should be stored encrypted in secure storage
  // This metadata only contains reference, timestamp, and verification info
  signatureStoragePath?: string; // Reference to encrypted storage location

  // Audit
  createdAt: Date;
}

// ============================================
// Secure File Link Types
// ============================================

export interface SecureFileLink {
  id: string;
  businessId: string;

  // File reference
  fileId: string; // Reference to the actual file/document
  fileName: string;
  fileType: string; // MIME type
  fileSize: number; // Bytes

  // Associated entities
  clientId?: string;
  dealId?: string;
  templateInstanceId?: string;

  // Link configuration
  token: string; // Unique token for accessing the file
  expiresAt: Date;
  maxAccessCount?: number; // Optional limit on number of accesses
  currentAccessCount: number;

  // Security
  requiresPassword?: boolean;
  passwordHash?: string; // Hashed password if required
  allowedIpAddresses?: string[]; // Optional IP whitelist

  // Status
  isActive: boolean;
  isRevoked: boolean;
  revokedAt?: Date;
  revokedBy?: string;
  revokedReason?: string;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName: string;
}

export interface FileLinkAccessLog {
  id: string;
  businessId: string;
  linkId: string;

  // Access details
  accessedAt: Date;
  ipAddress?: string;
  userAgent?: string;

  // Result
  wasSuccessful: boolean;
  failureReason?: string; // 'expired', 'max_access_reached', 'invalid_password', 'ip_blocked'

  // User info (if authenticated)
  userId?: string;
  userName?: string;

  // BaseEntity fields
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Template Library Types
// ============================================

export interface TemplateFilter {
  category?: TemplateCategory;
  isSystem?: boolean;
  isActive?: boolean;
  searchTerm?: string;
  tags?: string[];
}

export interface TemplateSummary {
  id: string;
  name: string;
  description?: string;
  category: TemplateCategory;
  fieldCount: number;
  usageCount: number;
  isSystem: boolean;
  tags: string[];
  lastUsedAt?: Date;
}

// ============================================
// Seed Templates
// ============================================

export interface SeedTemplateDefinition {
  name: string;
  description: string;
  category: TemplateCategory;
  tags: string[];
  fields: Omit<TemplateField, 'id'>[];
}

// Pre-defined seed templates for common use cases
export const SEED_TEMPLATES: Record<string, SeedTemplateDefinition> = {
  // Therapy Templates
  THERAPY_INTAKE: {
    name: 'Client Intake Form',
    description: 'Initial client information and consent form for therapy practice',
    category: 'therapy',
    tags: ['intake', 'consent', 'hipaa'],
    fields: [
      {
        type: 'text',
        label: 'Full Name',
        required: true,
        order: 1,
      },
      {
        type: 'date',
        label: 'Date of Birth',
        required: true,
        order: 2,
      },
      {
        type: 'email',
        label: 'Email Address',
        required: true,
        order: 3,
      },
      {
        type: 'phone',
        label: 'Phone Number',
        required: true,
        order: 4,
      },
      {
        type: 'textarea',
        label: 'Emergency Contact Information',
        required: true,
        order: 5,
        helpText: 'Name, relationship, and phone number',
      },
      {
        type: 'textarea',
        label: 'Reason for Seeking Therapy',
        required: true,
        order: 6,
      },
      {
        type: 'checkbox',
        label: 'I consent to treatment and privacy practices',
        required: true,
        order: 7,
      },
      {
        type: 'signature',
        label: 'Client Signature',
        required: true,
        order: 8,
      },
      {
        type: 'date',
        label: 'Date Signed',
        required: true,
        order: 9,
      },
    ],
  },

  THERAPY_PROGRESS_NOTE: {
    name: 'Progress Note',
    description: 'Session progress note for therapy documentation',
    category: 'therapy',
    tags: ['progress', 'session', 'documentation'],
    fields: [
      {
        type: 'date',
        label: 'Session Date',
        required: true,
        order: 1,
      },
      {
        type: 'text',
        label: 'Session Duration (minutes)',
        required: true,
        order: 2,
      },
      {
        type: 'textarea',
        label: 'Presenting Issues',
        required: true,
        order: 3,
      },
      {
        type: 'textarea',
        label: 'Interventions Used',
        required: true,
        order: 4,
      },
      {
        type: 'textarea',
        label: 'Client Response',
        required: true,
        order: 5,
      },
      {
        type: 'textarea',
        label: 'Plan for Next Session',
        required: false,
        order: 6,
      },
      {
        type: 'signature',
        label: 'Therapist Signature',
        required: true,
        order: 7,
      },
    ],
  },

  // Real Estate Templates
  REAL_ESTATE_BUYER_AGREEMENT: {
    name: 'Buyer Representation Agreement',
    description: 'Exclusive buyer representation agreement for real estate',
    category: 'real_estate',
    tags: ['buyer', 'agreement', 'contract'],
    fields: [
      {
        type: 'text',
        label: 'Buyer Full Name',
        required: true,
        order: 1,
      },
      {
        type: 'text',
        label: 'Property Address or Description',
        required: true,
        order: 2,
      },
      {
        type: 'number',
        label: 'Maximum Purchase Price',
        required: true,
        order: 3,
      },
      {
        type: 'date',
        label: 'Agreement Start Date',
        required: true,
        order: 4,
      },
      {
        type: 'date',
        label: 'Agreement End Date',
        required: true,
        order: 5,
      },
      {
        type: 'text',
        label: 'Commission Percentage',
        required: true,
        order: 6,
      },
      {
        type: 'checkbox',
        label: 'I agree to work exclusively with this agent',
        required: true,
        order: 7,
      },
      {
        type: 'signature',
        label: 'Buyer Signature',
        required: true,
        order: 8,
      },
      {
        type: 'signature',
        label: 'Agent Signature',
        required: true,
        order: 9,
      },
      {
        type: 'date',
        label: 'Date Signed',
        required: true,
        order: 10,
      },
    ],
  },

  REAL_ESTATE_PROPERTY_DISCLOSURE: {
    name: 'Property Disclosure Form',
    description: 'Seller property disclosure statement',
    category: 'real_estate',
    tags: ['disclosure', 'seller', 'property'],
    fields: [
      {
        type: 'text',
        label: 'Property Address',
        required: true,
        order: 1,
      },
      {
        type: 'text',
        label: 'Seller Full Name',
        required: true,
        order: 2,
      },
      {
        type: 'checkbox',
        label: 'Are there any known structural issues?',
        required: true,
        order: 3,
      },
      {
        type: 'textarea',
        label: 'Structural Issues Details (if any)',
        required: false,
        order: 4,
      },
      {
        type: 'checkbox',
        label: 'Are there any known water damage or leaks?',
        required: true,
        order: 5,
      },
      {
        type: 'textarea',
        label: 'Water Damage Details (if any)',
        required: false,
        order: 6,
      },
      {
        type: 'checkbox',
        label: 'Are all major systems functioning properly?',
        required: true,
        order: 7,
      },
      {
        type: 'textarea',
        label: 'Additional Disclosures',
        required: false,
        order: 8,
      },
      {
        type: 'signature',
        label: 'Seller Signature',
        required: true,
        order: 9,
      },
      {
        type: 'date',
        label: 'Date Signed',
        required: true,
        order: 10,
      },
    ],
  },

  // Accounting Templates
  ACCOUNTING_ENGAGEMENT_LETTER: {
    name: 'Client Engagement Letter',
    description: 'Accounting services engagement agreement',
    category: 'accounting',
    tags: ['engagement', 'agreement', 'services'],
    fields: [
      {
        type: 'text',
        label: 'Client/Company Name',
        required: true,
        order: 1,
      },
      {
        type: 'text',
        label: 'Contact Person',
        required: true,
        order: 2,
      },
      {
        type: 'email',
        label: 'Email Address',
        required: true,
        order: 3,
      },
      {
        type: 'select',
        label: 'Type of Service',
        required: true,
        order: 4,
        options: ['Tax Preparation', 'Bookkeeping', 'Audit', 'Consulting', 'Other'],
      },
      {
        type: 'textarea',
        label: 'Scope of Services',
        required: true,
        order: 5,
      },
      {
        type: 'text',
        label: 'Service Fee',
        required: true,
        order: 6,
      },
      {
        type: 'date',
        label: 'Engagement Period Start',
        required: true,
        order: 7,
      },
      {
        type: 'date',
        label: 'Engagement Period End',
        required: true,
        order: 8,
      },
      {
        type: 'checkbox',
        label: 'I agree to the terms and conditions',
        required: true,
        order: 9,
      },
      {
        type: 'signature',
        label: 'Client Signature',
        required: true,
        order: 10,
      },
      {
        type: 'signature',
        label: 'Accountant Signature',
        required: true,
        order: 11,
      },
      {
        type: 'date',
        label: 'Date Signed',
        required: true,
        order: 12,
      },
    ],
  },

  ACCOUNTING_DOCUMENT_REQUEST: {
    name: 'Tax Document Request Form',
    description: 'Request for client tax documentation',
    category: 'accounting',
    tags: ['tax', 'documents', 'checklist'],
    fields: [
      {
        type: 'text',
        label: 'Tax Year',
        required: true,
        order: 1,
      },
      {
        type: 'text',
        label: 'Client Name',
        required: true,
        order: 2,
      },
      {
        type: 'checkbox',
        label: 'W-2 Forms',
        required: false,
        order: 3,
      },
      {
        type: 'checkbox',
        label: '1099 Forms',
        required: false,
        order: 4,
      },
      {
        type: 'checkbox',
        label: 'Mortgage Interest Statement (1098)',
        required: false,
        order: 5,
      },
      {
        type: 'checkbox',
        label: 'Investment Income Statements',
        required: false,
        order: 6,
      },
      {
        type: 'checkbox',
        label: 'Business Expense Records',
        required: false,
        order: 7,
      },
      {
        type: 'textarea',
        label: 'Additional Documents Needed',
        required: false,
        order: 8,
      },
      {
        type: 'date',
        label: 'Documents Due Date',
        required: true,
        order: 9,
      },
      {
        type: 'signature',
        label: 'Client Acknowledgment',
        required: true,
        order: 10,
      },
    ],
  },
};

// ============================================
// Template Validation
// ============================================

export interface TemplateValidationError {
  field: string;
  message: string;
}

export interface TemplateValidationResult {
  isValid: boolean;
  errors: TemplateValidationError[];
}
