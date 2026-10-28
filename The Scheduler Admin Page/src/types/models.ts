import type { UserRole } from './auth';
export type { UserRole };

// Workspace/Business Profile
export type WorkspaceInfo = {
  id: string; // businessId
  name: string;
  slug?: string; // URL-safe identifier for public booking page
  publicBookingUrl?: string; // Full public booking URL
  inviteCode?: string; // Staff invite code for onboarding
  email?: string;
  phone?: string;
  address?: string;
  timezone?: string;
  logo?: string;
  requiresHipaaCompliance?: boolean;
  mfaEnabled?: boolean;
};

export type AppointmentStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed' | 'noShow';

export type Appointment = {
  id: string;
  businessId: string;
  clientId: string;
  providerId: string;
  serviceId: string;
  locationId?: string;
  startTime: string; // ISO per shared contract
  endTime: string; // ISO per shared contract
  date?: string; // yyyy-mm-dd convenience field
  status: AppointmentStatus;
  isGroupSession?: boolean;
  capacity?: number;
  attendeeIds?: string[];
  createdAt?: string;
  updatedAt?: string;
  // Legacy fields (kept for backward compatibility during rollout)
  staffId?: string;
  start?: string;
  end?: string;
};

export type GroupSessionVisibility = 'internal' | 'public';

export type GroupSession = {
  id: string;
  businessId: string;
  title: string;
  serviceId: string;
  providerIds: string[];
  locationId?: string;
  start: string;
  end: string;
  capacity: number;
  attendeeIds: string[];
  waitlistIds?: string[];
  visibility: GroupSessionVisibility;
  registrationDeadline?: string;
  allowWaitlist?: boolean;
  notes?: string;
  requiredResourceIds?: string[];
};

export type GroupSessionAttendee = {
  id: string;
  sessionId: string;
  clientId: string;
  status: 'confirmed' | 'waitlisted' | 'cancelled';
  joinedAt: string;
  checkedInAt?: string;
};

export type CampaignChannel = 'email' | 'sms';

export type CampaignStatus = 'draft' | 'scheduled' | 'sending' | 'sent' | 'failed' | 'cancelled';

export type CampaignAudienceFilters = {
  tags: string[];
  lastVisitMode: 'any' | 'within' | 'overdue';
  lastVisitDays: number;
  upcomingMode: 'any' | 'within' | 'none';
  upcomingDays: number;
};

export type CampaignAudiencePreview = {
  matching: number;
  optedOut: number;
  rateLimited: number;
  finalSendable: number;
};

export type CampaignSchedule = {
  sendAt?: string;
  timezone?: string;
};

export type MarketingCampaign = {
  id: string;
  businessId: string;
  name: string;
  description?: string;
  channels: CampaignChannel[];
  templateIds: {
    email?: string;
    sms?: string;
  };
  subjectLine?: string;
  smsBodyPreview?: string;
  template?: string;
  emailSubjectTemplate?: string;
  emailBodyTemplate?: string;
  smsBodyTemplate?: string;
  filters: CampaignAudienceFilters;
  status: CampaignStatus;
  createdAt: string;
  updatedAt?: string;
  scheduledFor?: string;
  sentAt?: string;
  audienceStats?: CampaignAudiencePreview;
};

export type MarketingRateLimitWindow = {
  maxRecipientsPerHour: number;
  windowHours: number;
};

export type Client = {
  id: string;
  businessId: string;
  name?: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  lifecycle?: string;
  tags?: string[];
  createdAt?: string;
  lastVisitAt?: string;
  nextAppointmentAt?: string;
  marketingOptOutChannels?: CampaignChannel[];
};

export type Service = {
  id: string;
  businessId: string;
  name: string;
  durationMinutes: number;
  price?: number;
  colorHex?: string;
  category?: string;
  bufferMinutes?: number;
  providerIds?: string[];
  resourceIds?: string[];
  isActive?: boolean;
  waitlistEnabled?: boolean;
};

export type StaffPermissions = {
  id?: string;
  userId?: string;
  email?: string;
  role: UserRole;
  moduleAccess: ModuleAccess;
  locationIds?: string[];
  serviceIds?: string[];
  createdAt?: string;
  updatedAt?: string;
};

export type PaymentStatus =
  | 'pending'
  | 'completed'
  | 'failed'
  | 'refunded'
  | 'partially_refunded'
  | 'none';

export type PaymentType =
  | 'deposit'
  | 'full'
  | 'subscription'
  | 'reschedule_fee'
  | 'cancellation_fee'
  | 'refund';

export type Payment = {
  id: string;
  businessId: string;
  amountCents: number;
  currency: string;
  type: PaymentType;
  status: PaymentStatus;
  appointmentId?: string;
  clientId?: string;
  createdAt: string;
  updatedAt?: string;
  // Optional legacy/read-model fields
  receiptUrl?: string;
  providerId?: string;
  description?: string;
};

export type WaitlistEntryStatus = 'active' | 'notified' | 'expired' | 'converted';
export type WaitlistPriority = 'standard' | 'vip';

export type WaitlistEntry = {
  id: string;
  businessId: string;
  clientId: string;
  serviceId: string;
  providerId?: string;
  locationId?: string;
  earliestDate?: string;
  latestDate?: string;
  preferredStart?: string;
  preferredEnd?: string;
  preferredDaysOfWeek?: string[];
  timeOfDayPreferences?: string[];
  preferredDays?: string[];
  notes?: string;
  notificationPreference?: 'sms' | 'email' | 'both';
  notificationChannel?: 'sms' | 'email' | 'both';
  notificationCount?: number;
  priority?: WaitlistPriority;
  priorityScore?: number;
  expiresAt?: string;
  createdAt?: string;
  updatedAt?: string;
  status: WaitlistEntryStatus;
};

export type CalendarIntegrationProvider = 'googleCalendar' | 'outlookCalendar';
export type TelehealthProvider = 'zoom' | 'googleMeet';
export type TelehealthFallbackOption = 'phone' | 'in_person';

export type IntegrationAccount = {
  id: string;
  businessId: string;
  provider: CalendarIntegrationProvider | TelehealthProvider;
  status: 'disconnected' | 'connecting' | 'connected' | 'error';
  connectedEmail?: string;
  lastSyncAt?: string;
};

export type StaffIntegrationPreference = {
  staffId: string;
  calendarProvider: CalendarIntegrationProvider | 'none';
  telehealthProvider: TelehealthProvider | 'default' | TelehealthFallbackOption;
};

export type TelehealthSettings = {
  defaultProvider: TelehealthProvider;
  fallbackProvider: TelehealthFallbackOption;
  requireLink: boolean;
  perServiceProviders: Record<string, TelehealthProvider>;
};

export type FeatureFlags = {
  enableCalendarSync: boolean;
  enableTelehealth: boolean;
  enableAutomatedReminders: boolean;
  enablePayments: boolean;
  enableReporting: boolean;
  enableImportExport: boolean;
  enableAutomation: boolean;
  enableWaitlist: boolean;
  enableLocations: boolean;
  enableResources: boolean;
  enableResourceConflicts: boolean;
  enableClientPortal: boolean;
  enableSessionNotes: boolean;
  enableMarketing: boolean;
  enableIntakeBuilder: boolean;
  waitlistNotifyChannels: Array<'sms' | 'email'>;
};

export type BillingStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'incomplete';

export type BillingEntitlement = {
  id: string;
  label: string;
  enabled: boolean;
  source: 'plan' | 'addon' | 'trial';
};

export type BillingProfile = {
  businessId: string;
  subscriptionId?: string;
  stripeCustomerId?: string;
  planId?: string;
  planName?: string;
  status: BillingStatus;
  seats: number;
  addonIds: string[];
  addOnIds?: string[];
  unknownAddOns?: string[];
  renewalDate?: string;
  trialEndsAt?: string;
  cancelAt?: string;
  currentPeriodEnd?: string;
  lastInvoiceStatus?: 'paid' | 'open' | 'past_due';
  lastEventType?: string;
  entitlements?: BillingEntitlement[];
};

export type SelfBookingAccess = 'disabled' | 'existing_only' | 'all_customers';

export type OnboardingStepId =
  | 'business'
  | 'scheduling'
  | 'locations'
  | 'team'
  | 'compliance'
  | 'billing'
  | 'integrations'
  | 'review';

export type OnboardingServiceInput = {
  name: string;
  durationMinutes?: number;
  price?: number;
  description?: string;
  category?: string;
  bufferBefore?: number;
  bufferAfter?: number;
};

export type OnboardingLocationInput = {
  name: string;
  address?: string;
  timezone?: string;
  notes?: string;
};

export type AppAccess = {
  scheduler: boolean;
  crm: boolean;
  admin: boolean;
};

export type AccessLevel = 'none' | 'view_own' | 'view_all' | 'manage_all';

export type ModuleAccess = {
  // Scheduler
  calendar?: AccessLevel;
  clients?: AccessLevel;
  // CRM
  leads?: AccessLevel;
  deals?: AccessLevel;
  marketing?: 'none' | 'view' | 'manage';
  // Admin
  billing?: 'none' | 'view' | 'manage';
  settings?: 'none' | 'view' | 'manage';
  staff?: 'none' | 'view' | 'manage';
};

export type StaffMember = {
  id: string;
  businessId: string;
  firstName?: string;
  lastName?: string;
  displayName: string;
  role: UserRole;
  email?: string;
  status: 'active' | 'inactive';
  serviceIds?: string[];
  locationIds?: string[];
  telehealthLink?: string;
  colorHex?: string;
  
  // Access Control
  appAccess?: AppAccess;
  moduleAccess?: ModuleAccess;
};

export type OperatingHoursBlock = { start: string; end: string };

export type OperatingHoursDay = {
  day: string;
  isOpen: boolean;
  blocks: OperatingHoursBlock[];
};

export type OnboardingTeamInvite = {
  email: string;
  role: UserRole;
  isProvider?: boolean;
  /** Whether this invite should grant CRM access/claims */
  crmAccess?: boolean;
  /** Per-module access toggles for the staff member */
  moduleAccess?: ModuleAccess;
  /** Location scope for this staff member */
  locationIds?: string[];
  /** Service scope for providers */
  serviceIds?: string[];
};

export type OnboardingState = {
  status: 'not_started' | 'in_progress' | 'completed';
  currentStep: OnboardingStepId;
  completedSteps: OnboardingStepId[];
  businessBasics: {
    businessName: string;
    industry: string;
    legalEntityType: string;
    timezone: string;
    primaryLocation: string;
    primaryLocationAddress: {
      street: string;
      city: string;
      state: string;
      zip: string;
      country: string;
    };
    contactEmail: string;
    contactPhone?: string;
    website?: string;
    logoUrl?: string;
    tagline: string;
  };
  scheduling: {
    operatingDays: string[];
    selfBookingAccess: SelfBookingAccess;
    requireDeposit: boolean;
    depositType?: 'amount' | 'percent';
    depositAmount?: number;
    services: OnboardingServiceInput[];
    emailReminders: boolean;
    smsReminders: boolean;
    reminderLeadTimeHours: number;
    communicationNotes?: string;
    hours?: OperatingHoursDay[];
  };
  locations: OnboardingLocationInput[];
  team: {
    invites: OnboardingTeamInvite[];
    skipped?: boolean;
  };
  compliance: {
    hipaaAcknowledged: boolean;
    mfaReminderAcknowledged: boolean;
    allowedDomains?: string[];
    dataRetentionMonths?: number;
    phiLoggingSafeguards: boolean;
  };
  billing: {
    planId?: string;
    seats: number;
    addons: string[];
    lastCheckoutUrl?: string;
    status?: BillingStatus;
  };
  integrations: {
    importPreference?: 'none' | 'csv' | 'api';
    calendarSyncPlanned?: boolean;
    paymentsReady?: boolean;
  };
  reviewConfirmed: boolean;
  updatedAt?: string;
  completedAt?: string;
};

export type MessageTemplate = {
  id: string;
  businessId: string;
  channel: 'email' | 'sms';
  type: string; // e.g., confirmation, reminder_24h
  subject?: string;
  body: string;
};

export type AutomationRule = {
  id: string;
  businessId: string;
  type: 'booking_confirmation' | 'reminder_24h' | 'reminder_1h' | 'cancellation' | 'waitlist_notification' | 'payment_receipt' | 'follow_up';
  enabled: boolean;
  emailEnabled: boolean;
  smsEnabled: boolean;
  timingMinutes?: number; // for reminders
  templateId?: string;
};

export type MessageHistory = {
  id: string;
  businessId: string;
  clientId?: string;
  appointmentId?: string;
  channel: 'email' | 'sms';
  type: string;
  recipient: string;
  status: 'sent' | 'failed' | 'pending';
  sentAt: string;
  subject?: string;
  body?: string;
};

export type StaffMemberSummary = {
  id: string;
  name: string;
  role: UserRole;
  color?: string;
};

export type LocationStatus = 'active' | 'inactive';

export type Location = {
  id: string;
  businessId: string;
  name: string;
  address: string;
  timezone: string;
  hours: string | OperatingHoursDay[];
  operatingHours?: OperatingHoursDay[];
  staffIds: string[];
  resourceIds?: string[];
  notes?: string;
  phone?: string;
  email?: string;
  status?: LocationStatus;
  tags?: string[];
  capacity?: number;
  parkingInfo?: string;
  createdAt?: string;
  updatedAt?: string;
};

export type LocationInput = Omit<Location, 'id' | 'businessId'>;

export type ResourceStatus = 'available' | 'in_use' | 'maintenance';

export type Resource = {
  id: string;
  businessId: string;
  locationId: string;
  name: string;
  type: 'room' | 'equipment';
  status: ResourceStatus;
  assignedStaffIds?: string[];
  tags?: string[];
  maintenanceNote?: string;
  maintenanceSince?: string;
  capacity?: number;
  colorHex?: string;
  isShared?: boolean;
  serviceIds?: string[];
};

export type ResourceInput = Omit<Resource, 'id' | 'businessId'>;

export type ResourceMaintenanceLog = {
  id: string;
  resourceId: string;
  note: string;
  status: ResourceStatus;
  createdBy: string;
  createdAt: string;
};

export type ResourceConflict = {
  id: string;
  resourceId: string;
  locationId: string;
  description: string;
  time: string;
  severity?: 'info' | 'warning' | 'critical';
  appointmentIds?: string[];
  resolvedAt?: string;
  resolutionNote?: string;
};

// Intake Forms
export type IntakeFormFieldType =
  | 'text'
  | 'textarea'
  | 'dropdown'
  | 'checkbox'
  | 'radio'
  | 'file'
  | 'signature'
  | 'date';

export type IntakeFieldConditionOperator = 'equals' | 'not_equals' | 'contains' | 'includes';

export type IntakeFieldCondition = {
  id: string;
  fieldId: string;
  operator: IntakeFieldConditionOperator;
  value: string;
};

export type IntakeFieldConditionalLogic = {
  id: string;
  action: 'show' | 'hide' | 'require';
  matchType: 'all' | 'any';
  conditions: IntakeFieldCondition[];
};

export type IntakeFormField = {
  id: string;
  type: IntakeFormFieldType;
  label: string;
  required: boolean;
  placeholder?: string;
  helperText?: string;
  defaultValue?: string;
  width?: 'full' | 'half';
  options?: string[]; // for dropdown/radio/checkbox
  conditionalLogic?: IntakeFieldConditionalLogic;
};

export type IntakeForm = {
  id: string;
  businessId: string;
  name: string;
  description?: string;
  fields: IntakeFormField[];
  serviceIds?: string[]; // linked services
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
};

export type IntakeFormInput = Omit<IntakeForm, 'id' | 'businessId' | 'createdAt' | 'updatedAt'>;

export type IntakeFormSubmission = {
  id: string;
  businessId: string;
  formId: string;
  clientId: string;
  appointmentId?: string;
  responses: Record<string, string | string[]>; // fieldId -> response
  status: 'draft' | 'submitted';
  submittedAt?: string;
  createdAt: string;
  updatedAt: string;
};

export type IntakeFormDraft = IntakeFormSubmission & {
  status: 'draft';
};

// Session Notes (encrypted, provider-only)
export type SessionNoteAudit = {
  id: string;
  action: string; // created|updated|viewed|locked|unlocked
  userId: string;
  userFullName: string;
  timestamp: string;
  changesSummary?: string;
};

export type SessionNote = {
  id: string;
  businessId: string;
  appointmentId: string;
  clientId: string;
  providerId: string; // staff member who created note
  noteType:
    | 'soap'
    | 'progressNote'
    | 'treatmentPlan'
    | 'procedureLog'
    | 'adjustmentNote'
    | 'intakeAssessment'
    | 'dischargeNote'
    | 'psychNote'
    | 'custom';
  visibility: 'providerOnly' | 'businessOnly' | 'shared';
  encryptedContent: string; // encrypted note content
  title?: string;
  tags?: string[];
  isLocked: boolean;
  createdAt: string;
  updatedAt?: string;
  createdBy: string;
  createdByName: string;
  lastEditedBy?: string;
  lastEditedByName?: string;
  auditLog: SessionNoteAudit[];
  retainIndefinitely?: boolean;
  isPsychotherapyNote?: boolean;
  // Legacy/admin-only fields
  providerName?: string;
  date?: string;
};

// File Attachments
export type FileAttachment = {
  id: string;
  businessId: string;
  clientId: string;
  name: string;
  contentType: string;
  sizeBytes: number;
  storagePath: string;
  storageUrl?: string;
  downloadUrl?: string;
  uploadedAt: string;
  uploaderId: string;
  accessLevel?: string;
  isSensitive?: boolean;
  metadata?: Record<string, unknown>;
  category?: string;
  appointmentId?: string;
  intakeFormId?: string;
  intakeSubmissionId?: string;
  notes?: string;
  // Legacy/admin-only fields
  fileName?: string;
  fileType?: string;
  fileSize?: number;
  uploadedBy?: string;
};

// MFA Backup Codes
export type BackupCode = {
  id: string;
  codeHash: string; // SHA-256 hash, NEVER plaintext
  usedAt: { seconds: number; nanoseconds: number } | null; // Firestore Timestamp
  createdAt: { seconds: number; nanoseconds: number }; // Firestore Timestamp
};
