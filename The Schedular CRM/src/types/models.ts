// Core CRM data models
// All entities are scoped under businesses/{businessId}/ per shared_data_contract.md
// Reuses existing collections where applicable (clients, users)

import type { FeatureFlags } from '../config/features';

// Re-export for convenience
export type { FeatureFlags };

// ============================================
// Business / Workspace Types
// Path: businesses/{businessId} (top-level collection)
// ============================================

export interface Business {
  id: string;
  name: string;
  slug?: string; // URL-friendly workspace identifier
  inviteCode?: string; // Code for team invitations
  publicBookingUrl?: string; // Public booking page URL (if applicable)

  // Security settings
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
  /** Optional override to disable audit logging for non-HIPAA workspaces (defaults to enabled) */
  auditLoggingEnabled?: boolean;

  // Metadata
  createdAt: Date;
  updatedAt?: Date;
  ownerId?: string;
  ownerEmail?: string;
}

// ============================================
// User & Auth Types (aligned with shared contract)
// Path: users/{uid} (top-level collection)
// ============================================

export const CANONICAL_USER_ROLES = [
  'owner',
  'admin',
  'manager',
  'staff',
  'sales',
  'provider',
  'frontDesk',
  'client',
] as const;

export type UserRole = (typeof CANONICAL_USER_ROLES)[number];
export type LegacyUserRole = 'assistant' | 'sales_rep' | 'marketing' | 'user';

export function normalizeUserRole(role: string | null | undefined): UserRole | undefined {
  if (!role) return undefined;
  const trimmed = role.trim();
  if (!trimmed) return undefined;
  if ((CANONICAL_USER_ROLES as readonly string[]).includes(trimmed)) {
    return trimmed as UserRole;
  }
  if (trimmed === 'assistant') return 'frontDesk';
  if (trimmed === 'sales_rep' || trimmed === 'marketing') return 'sales';
  if (trimmed === 'user') return 'staff';
  return undefined;
}

// Matches top-level users/{uid} from shared contract
export interface User {
  id: string;
  businessId: string;
  role: UserRole;
  email: string;
  displayName: string;
  createdAt: Date;
  providerId?: string;
  clientId?: string;
}

// Extended CRM user info (for sales-specific roles)
export type CRMRole = UserRole | 'viewer';

export interface CRMUser extends User {
  crmRole?: CRMRole; // Sales-specific role if different from base role
  lastLoginAt?: Date;
  teamIds?: string[];
  managedTeamIds?: string[];
  managerId?: string;
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
  /** Business-level audit logging toggle; defaults to true unless explicitly disabled */
  auditLoggingEnabled?: boolean;
}

// ============================================
// Teams (CRM-specific)
// Path: businesses/{businessId}/teams/{teamId}
// ============================================

/**
 * Team entity for organizing users
 * Admins can create, edit, and delete teams
 */
export interface Team {
  id: string;
  name: string;
  description?: string;

  // Manager assignment
  managerId?: string;
  managerName?: string;

  // Status
  isActive: boolean;

  // Display
  colorHex?: string;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdById: string;
  createdByName: string;
}

// ============================================
// Ownership / Sharing
// ============================================

export type Visibility = 'private' | 'team' | 'org';

export interface ShareableFields {
  ownerId?: string;
  ownerName?: string;
  teamIds?: string[];
  visibility?: Visibility;
  // Allow repository helpers to work with dynamic fields while keeping required props typed.
  [key: string]: unknown;
}

// ============================================
// Pipelines (CRM-specific)
// Path: businesses/{businessId}/pipelines/{pipelineId}
// ============================================

export interface Pipeline extends ShareableFields {
  id: string;
  name: string;
  isDefault: boolean;
  isActive: boolean;
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  visibility?: Visibility;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Pipeline Stages (CRM-specific)
// Path: businesses/{businessId}/stages/{stageId}
// ============================================

export interface Stage extends ShareableFields {
  id: string;
  pipelineId: string;
  name: string;
  order: number;
  colorHex: string; // Matches convention from providers.colorHex
  probability: number; // 0-100, likelihood of closing at this stage
  isActive: boolean;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Leads (CRM-specific)
// Path: businesses/{businessId}/leads/{leadId}
// ============================================

export type LeadStatus = 'new' | 'contacted' | 'qualified' | 'unqualified' | 'converted';
export type LeadSource = 'website' | 'referral' | 'coldCall' | 'social' | 'event' | 'scheduler' | 'other';

export interface Lead extends ShareableFields {
  id: string;

  // Contact info
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  companyName?: string;
  title?: string;

  // Lead details
  status: LeadStatus;
  source: LeadSource;
  score?: number; // Lead scoring value (0-100)

  // Assignment
  assigneeId?: string; // userId
  assigneeName?: string;

  // Metadata
  tags: string[];
  notes?: string;
  customFields?: Record<string, unknown>;

  // Conversion tracking - links to existing clients collection
  convertedToClientId?: string; // References clients/{clientId}
  convertedToDealId?: string;
  convertedAt?: Date;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Geocoding Types (for Route Planning)
// ============================================

/**
 * Geocoded address information for contacts/locations
 * Used for route planning and map display
 */
export interface GeocodedAddress {
  latitude: number;
  longitude: number;
  formattedAddress?: string;
  placeId?: string;
  accuracy?: 'rooftop' | 'interpolated' | 'approximate';
  /** Timestamp when address was geocoded */
  geocodedAt?: Date;
}

// ============================================
// Clients / Contacts (reuses existing collection)
// Path: businesses/{businessId}/clients/{clientId}
// This is the SAME collection as the scheduler uses
// CRM adds some optional fields for sales tracking
// ============================================

export type ClientLifecycle = 'lead' | 'prospect' | 'active' | 'inactive' | 'churned';

/**
 * Lead status for contacts in the early funnel stages
 * Used to unify Contacts and Leads into a single workflow
 */
export type ContactLeadStatus = 'New' | 'Working' | 'Qualified' | 'Unqualified' | 'Nurturing' | null;

export interface Client extends ShareableFields {
  id: string;

  // Core fields (from shared contract)
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  lifecycle?: ClientLifecycle;
  tags: string[];
  userId?: string; // Auth link

  // CRM extensions (optional fields added by CRM)
  companyId?: string; // Link to companies collection
  companyName?: string;
  title?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
  geocodedAddress?: GeocodedAddress; // Route planning geocode data
  crmNotes?: string; // Sales-specific notes
  lastContactedAt?: Date;
  leadSource?: LeadSource;

  // Unified funnel fields (CRM-refactor)
  // leadStatus: Applied when contact is in early funnel stages (Leads page filters by this)
  leadStatus?: ContactLeadStatus;
  // assignedRepUid: Sales rep assigned to this contact
  assignedRepUid?: string;
  // assignedRepName: Display name for the assigned rep
  assignedRepName?: string;

  // Email opt-out tracking
  emailOptOut?: boolean;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Companies / Organizations (CRM-specific)
// Path: businesses/{businessId}/companies/{companyId}
// ============================================

export type CompanySize = 'small' | 'medium' | 'large' | 'enterprise';

export interface Company extends ShareableFields {
  id: string;

  // Basic info
  name: string;
  industry?: string;
  size?: CompanySize;
  website?: string;
  phone?: string;
  email?: string;

  // Address
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };

  // Metadata
  notes?: string;
  tags: string[];
  customFields?: Record<string, unknown>;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Opportunities (CRM-specific)
// Path: businesses/{businessId}/deals/{dealId}
// Note: Firestore collection remains "deals" for backward compatibility
// ============================================

export type OpportunityStatus = 'open' | 'won' | 'lost';

/** @deprecated Use OpportunityStatus instead */
export type DealStatus = OpportunityStatus;

export interface Opportunity extends ShareableFields {
  id: string;
  pipelineId: string;
  stageId: string;

  // Opportunity info
  title: string;
  valueCents: number; // Store as cents per convention (like payments.amountCents)
  currency: string; // e.g., 'USD'
  probability: number; // 0-100
  expectedCloseDate?: Date;

  // Status
  status: OpportunityStatus;
  wonLostReason?: string;
  closedAt?: Date;

  // Associations - links to existing collections
  // REQUIRED: Every Opportunity must link to a Contact (clientId)
  clientId?: string; // References clients/{clientId}
  clientName?: string;
  clientEmail?: string; // Denormalized client email for quick access
  companyId?: string; // References companies/{companyId}
  companyName?: string;

  // Assignment
  // assigneeId: User who owns this opportunity
  assigneeId?: string; // userId
  assigneeName?: string;
  // assignedRepUid: Inherited from Contact at deal creation, can be overridden
  assignedRepUid?: string;
  assignedRepName?: string;

  // Metadata
  tags: string[];
  notes?: string;
  customFields?: Record<string, unknown>;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

/** @deprecated Use Opportunity instead */
export type Deal = Opportunity;

// ============================================
// Sales Activities (CRM-specific)
// Path: businesses/{businessId}/sales_activities/{activityId}
// Named to avoid conflict with potential future activities collection
// ============================================

export type SalesActivityType = 'call' | 'email' | 'meeting' | 'note' | 'task';

export interface SalesActivity extends ShareableFields {
  id: string;

  // Activity details
  type: SalesActivityType;
  title: string;
  description?: string;

  // Associations (can be linked to multiple entities)
  dealId?: string;
  clientId?: string; // References clients/{clientId}
  leadId?: string;
  companyId?: string;

  // For tasks
  dueDate?: Date;
  /** Optional SLA target (defaults to dueDate) */
  slaAt?: Date;
  /** SLA window length in minutes (used for at-risk thresholds) */
  slaMinutes?: number;
  /** Reminder trigger timestamp (email/calendar hooks use metadata only) */
  reminderAt?: Date;
  /** Template applied when the task was created */
  templateId?: string;
  isCompleted: boolean;
  completedAt?: Date;

  // Assignment
  assigneeId?: string;
  assigneeName?: string;

  // Audit
  createdById: string;
  createdByName: string;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Custom Fields (CRM-specific)
// Path: businesses/{businessId}/crm_custom_fields/{fieldId}
// ============================================

export type CustomFieldType = 'text' | 'number' | 'date' | 'select' | 'multiselect' | 'checkbox';
export type CustomFieldEntity = 'lead' | 'client' | 'deal' | 'company';

export interface CustomField {
  id: string;

  entity: CustomFieldEntity;
  name: string; // Field key (camelCase)
  label: string; // Display label
  type: CustomFieldType;
  options?: string[]; // For select/multiselect
  isRequired: boolean;
  order: number;
  isActive: boolean;

  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// CRM Settings
// Path: businesses/{businessId}/settings/crm
// ============================================

export interface CRMSettings {
  defaultPipelineId?: string;
  defaultCurrency: string;
  leadScoringEnabled: boolean;
  leadScoringRules?: LeadScoringRule[];
  dealRotting?: {
    enabled: boolean;
    thresholdDays: number;
  };
  updatedAt?: Date;
  updatedById?: string;
  updatedByName?: string;
  createdAt?: Date;
  createdById?: string;
  createdByName?: string;
}

export interface LeadScoringRule {
  id: string;
  field: string;
  condition: 'equals' | 'contains' | 'greaterThan' | 'lessThan';
  value: string | number;
  points: number;
}

// ============================================
// Dashboard & Analytics Types
// ============================================

export interface PipelineMetrics {
  totalDeals: number;
  totalValueCents: number;
  avgDealSizeCents: number;
  conversionRate: number;
  dealsByStage: Record<string, { count: number; valueCents: number }>;
}

export interface SalesMetrics {
  dealsWon: number;
  dealsLost: number;
  revenueCents: number;
  avgTimeToCloseDays: number;
}

// ============================================
// Reporting Saved Views
// Path: businesses/{businessId}/report_views/{viewId}
// ============================================

export type ReportStatusFilter = Array<'open' | 'won' | 'lost'>;

export interface ReportViewFilters {
  /** Inclusive start date for deal/lead metrics */
  startDate?: Date;
  /** Inclusive end date for deal/lead metrics */
  endDate?: Date;
  /** Restrict to a pipeline */
  pipelineId?: string | null;
  /** Restrict to specific stage IDs */
  stageIds?: string[];
  /** Deal status filters */
  statuses?: ReportStatusFilter;
  /** Assignee filters (user IDs) */
  assigneeIds?: string[];
  /** Lead source filters */
  leadSources?: string[];
  /** Restrict to owner IDs */
  ownerIds?: string[];
  /** Restrict to team IDs */
  teamIds?: string[];
}

export interface ReportView extends ShareableFields {
  id: string;
  name: string;
  description?: string;
  filters: ReportViewFilters;
  ownerId: string;
  ownerName: string;
  teamIds: string[];
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Payments (reuses existing collection from Scheduler)
// Path: businesses/{businessId}/payments/{paymentId}
// This is the SAME collection as the scheduler uses
// CRM adds payment capture UI and links to deals
// ============================================

export type PaymentStatus =
  | 'pending'
  | 'completed'
  | 'succeeded'
  | 'failed'
  | 'refunded'
  | 'partially_refunded'
  | 'disputed'
  | 'none';
export type PaymentMethod = 'card' | 'cash' | 'check' | 'bank_transfer' | 'other';
export type PaymentType =
  | 'deposit'
  | 'full'
  | 'subscription'
  | 'reschedule_fee'
  | 'cancellation_fee'
  | 'refund';

export interface Payment {
  id: string;

  // Amount in cents (per convention with valueCents)
  amountCents: number;
  currency: string; // e.g., 'USD'

  // Payment details
  status: PaymentStatus;
  method: PaymentMethod;
  type: PaymentType;
  description?: string;

  // Associations - links to CRM entities
  clientId: string; // Required - who paid
  clientName?: string;
  appointmentId?: string;
  dealId?: string; // Optional - which deal this payment is for
  dealTitle?: string;

  // Payment provider details (Stripe, etc.)
  providerId?: string; // External payment provider ID (e.g., Stripe charge ID)
  receiptUrl?: string; // URL to receipt
  last4?: string; // Last 4 digits of card (for display only)
  cardBrand?: string; // e.g., 'visa', 'mastercard'

  // Dispute tracking
  disputeStatus?: 'none' | 'warning_needs_response' | 'warning_under_review' | 'warning_closed' | 'charge_refunded';
  disputeReason?: string;

  // Metadata
  notes?: string;
  customFields?: Record<string, unknown>;

  // Audit
  processedById?: string; // User who initiated the payment
  processedByName?: string;
  processedAt?: Date; // When payment was initiated

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Payment Cards (saved payment methods)
// Path: businesses/{businessId}/clients/{clientId}/paymentMethods/{methodId}
// Stores tokenized card data only - NEVER raw card details
// ============================================

export interface PaymentMethodCard {
  id: string; // Firestore doc ID

  // Card details (all from payment provider - tokenized)
  providerId: string; // Provider's payment method ID (e.g., Stripe pm_xxx)
  last4: string;
  brand: string; // 'visa', 'mastercard', etc.
  expMonth: number;
  expYear: number;

  // Display
  isDefault: boolean;
  nickname?: string; // e.g., "Work Card", "Personal Amex"

  // Metadata
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// Disputes (CRM-specific)
// Path: businesses/{businessId}/disputes/{disputeId}
// ============================================

export interface Dispute {
  id: string;
  paymentId: string;
  amountCents: number;
  status: 'open' | 'resolved' | 'lost';
  reason: string;
  clientId: string;
  clientName?: string;
  createdAt: Date;
  resolvedAt?: Date;
}

// ============================================
// Firestore Timestamp handling
// ============================================

import { Timestamp } from 'firebase/firestore';

// Helper type for Firestore documents that may have Timestamp or Date
export type FirestoreDate = Date | Timestamp;

// Convert Firestore Timestamp to Date
export function toDate(value: FirestoreDate | undefined): Date | undefined {
  if (!value) return undefined;
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  return value;
}

// ============================================
// Route Planning Types (CRM-specific)
// Path: businesses/{businessId}/routes/{routeId}
// ============================================

/**
 * A single stop in a route
 */
export interface RouteStop {
  contactId: string;
  contact: Client;
  order: number;
  estimatedArrival?: Date;
  estimatedDuration?: number; // minutes for the visit
  notes?: string;
  status?: 'pending' | 'completed' | 'skipped';
  completedAt?: Date;

  // Auto-suggestion metadata
  suggestionSource?: 'territory' | 'manual' | 'rebalance';
  originalTerritoryId?: string;

  // Time windows
  preferredArrivalStart?: Date;
  preferredArrivalEnd?: Date;

  // Mobile tracking
  actualArrivalTime?: Date;
  actualDepartureTime?: Date;
  checkInLatitude?: number;
  checkInLongitude?: number;
}

export type RouteStatus = 'draft' | 'planned' | 'in_progress' | 'completed' | 'cancelled';

/**
 * A planned route with multiple stops
 * Follows ShareableFields pattern for access control
 */
export interface Route extends ShareableFields {
  id: string;
  businessId: string;
  name: string;
  date: Date;

  // Assignment
  assigneeId?: string; // Staff member assigned to this route
  assigneeName?: string;

  // Stops
  stops: RouteStop[];

  // Status
  status: RouteStatus;

  // Optimization data
  totalDistanceKm?: number;
  totalDurationMinutes?: number;
  optimizedAt?: Date;

  // Start location (depot/office)
  startLatitude?: number;
  startLongitude?: number;
  startAddress?: string;

  // Territory reference (for auto-assignment)
  territoryId?: string;
  territoryName?: string;

  // Scheduled time window
  scheduledStartTime?: Date;
  scheduledEndTime?: Date;

  // Mobile sync tracking
  mobileAppSyncedAt?: Date;
  mobileAppVersion?: string;
  lastMobileUpdate?: Date;

  // Route completion metrics
  actualStartTime?: Date;
  actualEndTime?: Date;
  actualDistanceKm?: number;

  // Calendar conflict status
  hasCalendarConflicts?: boolean;
  conflictDetails?: string[];

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName?: string;
}

// ============================================
// Time Entry / Punch Clock Types
// Path: businesses/{businessId}/timeEntries/{entryId}
// Synced from mobile staff app
// ============================================

export type TimeEntryStatus = 'active' | 'pending' | 'approved' | 'rejected';
export type BreakType = 'meal' | 'rest';

/**
 * A break period within a time entry
 */
export interface BreakPeriod {
  startTime: Date;
  endTime?: Date;
  type: BreakType;
}

/**
 * A time entry (punch clock record) from the mobile app
 * Staff clock in/out, managers approve/reject in CRM
 */
export interface TimeEntry {
  id: string;
  businessId: string;
  staffId: string;

  // Clock in/out times
  clockInTime: Date;
  clockOutTime?: Date;

  // Clock in location
  clockInLatitude?: number;
  clockInLongitude?: number;
  clockInAddress?: string;
  clockInLocationId?: string;
  clockInOutsideGeofence?: boolean;

  // Clock out location
  clockOutLatitude?: number;
  clockOutLongitude?: number;
  clockOutAddress?: string;
  clockOutLocationId?: string;
  clockOutOutsideGeofence?: boolean;

  // Breaks (inline array)
  breaks: BreakPeriod[];

  // Calculated totals (set on clock out)
  totalMinutes?: number;      // clockOut - clockIn
  breakMinutes?: number;      // sum of breaks
  workedMinutes?: number;     // totalMinutes - breakMinutes

  // Approval workflow
  status: TimeEntryStatus;
  approvedByUserId?: string;
  approvedAt?: Date;
  rejectionReason?: string;

  // Notes
  staffNotes?: string;
  managerNotes?: string;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Summary for a timesheet period (daily/weekly)
 * Computed on-the-fly, not stored
 */
export interface TimesheetSummary {
  staffId: string;
  staffName: string;
  periodStart: Date;
  periodEnd: Date;

  // Totals
  totalWorkedMinutes: number;
  totalBreakMinutes: number;
  regularMinutes: number;      // up to 8h/day or 40h/week
  overtimeMinutes: number;     // beyond threshold at 1.5x

  // Entry counts
  totalEntries: number;
  pendingEntries: number;
  approvedEntries: number;
  rejectedEntries: number;

  // Entries for detail view
  entries: TimeEntry[];
}

// ============================================
// Staff Schedule Types (for Route Planning)
// Path: businesses/{businessId}/staff_schedules/{scheduleId}
// ============================================

export type DayOfWeek = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';

/**
 * Time slot within a schedule (HH:mm format, 24h)
 */
export interface ScheduleTimeSlot {
  startTime: string; // HH:mm format
  endTime: string;   // HH:mm format
}

/**
 * Weekly recurring schedule pattern for a single day
 */
export interface WeeklySchedulePattern {
  dayOfWeek: DayOfWeek;
  isWorkingDay: boolean;
  shifts: ScheduleTimeSlot[]; // Multiple shifts per day (e.g., split shifts)
}

export type ScheduleExceptionType = 'time_off' | 'modified_hours' | 'holiday';

/**
 * Schedule exception (time-off, special hours, holidays)
 */
export interface ScheduleException {
  id: string;
  date: Date;
  type: ScheduleExceptionType;
  reason?: string;
  /** If type is 'modified_hours', these override the weekly pattern */
  shifts?: ScheduleTimeSlot[];
  /** Full day off if true */
  allDay: boolean;
  /** For calendar sync tracking */
  externalEventId?: string;
  calendarProvider?: 'google' | 'outlook';
}

/**
 * Staff schedule with weekly patterns and exceptions
 * Used for route planning to know who is working when
 */
export interface StaffSchedule extends ShareableFields {
  id: string;
  businessId: string;

  // Staff reference (from providers collection)
  staffId: string;
  staffName: string;
  staffEmail?: string;

  // Weekly recurring pattern
  weeklyPatterns: WeeklySchedulePattern[];

  // Exceptions (time-off, modified hours)
  exceptions: ScheduleException[];

  // Timezone for schedule interpretation
  timezone: string; // e.g., 'America/Los_Angeles'

  // Route planning constraints
  maxStopsPerDay?: number;
  maxDrivingMinutesPerDay?: number;

  // Start location for routes (home base)
  homeBaseAddress?: string;
  homeBaseLatitude?: number;
  homeBaseLongitude?: number;

  // Calendar integration
  calendarConnectionId?: string;
  lastCalendarSyncAt?: Date;
  syncExceptionsFromCalendar: boolean;

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName?: string;
}

// ============================================
// Territory Types (for Route Planning)
// Path: businesses/{businessId}/territories/{territoryId}
// ============================================

export type TerritoryBoundaryType = 'zip_codes' | 'polygon' | 'radius';

/**
 * Geographic boundary definition for a territory
 */
export interface TerritoryBoundary {
  type: TerritoryBoundaryType;

  // For zip_codes type
  zipCodes?: string[];

  // For polygon type (GeoJSON-style coordinates)
  polygonCoordinates?: Array<[number, number]>; // [lng, lat] pairs

  // For radius type
  centerLatitude?: number;
  centerLongitude?: number;
  radiusKm?: number;
}

/**
 * Staff assignment to a territory
 */
export interface TerritoryAssignment {
  staffId: string;
  staffName: string;
  isPrimary: boolean; // Primary assignee for auto-suggestion
  priority: number;   // For load balancing (1 = highest)
}

/**
 * Territory for organizing contacts and assigning staff
 */
export interface Territory extends ShareableFields {
  id: string;
  businessId: string;

  // Territory info
  name: string;
  description?: string;
  colorHex: string; // For map visualization

  // Geographic definition
  boundary: TerritoryBoundary;

  // Staff assignments
  assignments: TerritoryAssignment[];

  // Auto-assignment settings
  enableAutoSuggestion: boolean;
  loadBalancingEnabled: boolean;

  // Metadata
  isActive: boolean;
  contactCount?: number; // Cached count of contacts in territory

  // Timestamps
  createdAt: Date;
  updatedAt?: Date;
  createdBy: string;
  createdByName?: string;
}

// ============================================
// Route Sync Queue Types (for Mobile Sync)
// Path: businesses/{businessId}/route_sync_queue/{queueId}
// ============================================

export type RouteSyncAction = 'push' | 'update' | 'delete';
export type RouteSyncStatus = 'pending' | 'processing' | 'completed' | 'failed';

/**
 * Queue item for syncing routes to mobile app
 */
export interface RouteSyncQueueItem {
  id: string;
  businessId: string;
  routeId: string;
  staffId: string;
  action: RouteSyncAction;
  status: RouteSyncStatus;
  deviceTokens: string[];
  payload: Partial<Route>;
  createdAt: Date;
  processedAt?: Date;
  retryCount: number;
  errorMessage?: string;
}

// ============================================
// Calendar Conflict Types (for Route Planning)
// ============================================

/**
 * Busy time slot from external calendar
 * Used for conflict detection in route planning
 */
export interface BusyTimeSlot {
  startTime: Date;
  endTime: Date;
  source: 'google' | 'outlook' | 'internal';
  eventId?: string;
  title?: string; // Sanitized for HIPAA
}
