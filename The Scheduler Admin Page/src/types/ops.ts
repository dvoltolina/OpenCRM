/**
 * Ops Portal Types
 * Types for the internal ops/support portal (super-admin only)
 */

import type { BillingStatus } from './models';

// Tenant summary for list view
export type TenantSummary = {
  id: string; // businessId
  name: string;
  slug?: string;
  email?: string;
  createdAt?: string;
  lastActiveAt?: string;

  // Billing info
  planId?: string;
  planName?: string;
  status: BillingStatus;
  seats: number;
  addonIds: string[];
  renewalDate?: string;

  // Entitlements summary
  hasCrm?: boolean;
  hasAi?: boolean;

  // Feature flags summary
  flagsEnabled: number;
  flagsTotal: number;
};

// Ops support note
export type OpsNoteCategory = 'support' | 'billing' | 'technical' | 'escalation' | 'general';
export type OpsNotePriority = 'low' | 'normal' | 'high' | 'urgent';

export type OpsNote = {
  id: string;
  businessId: string;
  content: string;
  createdBy: string;
  createdByEmail: string;
  createdAt: string;
  updatedAt?: string;
  category?: OpsNoteCategory;
  priority?: OpsNotePriority;
};

export type OpsNoteInput = Omit<OpsNote, 'id' | 'createdAt' | 'updatedAt'>;

// Ops audit log entry
export type OpsAuditAction =
  | 'tenant_viewed'
  | 'plan_changed'
  | 'addon_added'
  | 'addon_removed'
  | 'flag_toggled'
  | 'owner_invite_created'
  | 'note_added'
  | 'impersonation_started'
  | 'impersonation_ended';

export type OpsAuditLog = {
  id: string;
  timestamp: string;
  operatorId: string;
  operatorEmail: string;
  action: OpsAuditAction;
  businessId: string;
  businessName?: string;
  metadata?: Record<string, unknown>;
};

// Owner invite created by ops
export type OpsOwnerInviteStatus = 'pending' | 'accepted' | 'expired' | 'revoked';

export type OpsOwnerInvite = {
  id: string;
  businessId: string;
  email: string;
  createdBy: string;
  createdAt: string;
  expiresAt: string;
  status: OpsOwnerInviteStatus;
  claimedAt?: string;
};

// Plan/addon configuration options
export type PlanOption = {
  id: string;
  name: string;
  description?: string;
  baseSeats: number;
  features: string[];
};

export type AddonOption = {
  id: string;
  name: string;
  description?: string;
  category: 'crm' | 'ai' | 'integration' | 'compliance';
};

// Available plans and addons (hardcoded for now, could be fetched from config)
export const AVAILABLE_PLANS: PlanOption[] = [
  { id: 'starter', name: 'Starter', baseSeats: 1, features: ['scheduling', 'clients'] },
  { id: 'professional', name: 'Professional', baseSeats: 3, features: ['scheduling', 'clients', 'payments', 'reminders'] },
  { id: 'business', name: 'Business', baseSeats: 10, features: ['scheduling', 'clients', 'payments', 'reminders', 'reporting', 'marketing'] },
  { id: 'enterprise', name: 'Enterprise', baseSeats: 50, features: ['all'] },
];

export const AVAILABLE_ADDONS: AddonOption[] = [
  { id: 'crm', name: 'CRM Module', description: 'Sales pipeline and contact management', category: 'crm' },
  { id: 'ai', name: 'AI Assistant', description: 'AI-powered scheduling and insights', category: 'ai' },
  { id: 'telehealth', name: 'Telehealth', description: 'Video conferencing integration', category: 'integration' },
  { id: 'hipaa', name: 'HIPAA Compliance', description: 'Enhanced security and compliance features', category: 'compliance' },
];
