export type OwnerOnboardingStep =
  | 'business'
  | 'compliance'
  | 'mfa'
  | 'location'
  | 'hours'
  | 'services'
  | 'preferences'
  | 'billing'
  | 'review'
  | 'complete';

export type OperatingHoursBlock = {
  start: string;
  end: string;
};

export type OperatingHoursDay = {
  day: string;
  isOpen: boolean;
  blocks: OperatingHoursBlock[];
};

export type OwnerOnboardingService = {
  name: string;
  description?: string;
  durationMinutes: number;
  price: number;
  category?: string;
  bufferBefore?: number;
  bufferAfter?: number;
};

export type OwnerOnboardingLocation = {
  name: string;
  address1: string;
  address2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  timezone: string;
  phone?: string;
  email?: string;
};

export type OwnerOnboardingDraft = {
  status: 'in_progress' | 'completed';
  currentStep: OwnerOnboardingStep;
  business: {
    name: string;
    industry: string;
    description?: string;
    contactEmail: string;
    contactPhone?: string;
    slug?: string;
    requiresHipaaCompliance: boolean;
    mfaEnabled: boolean;
  };
  compliance: {
    hipaaAcknowledged: boolean;
    mfaAcknowledged: boolean;
    phiNoticeAcknowledged?: boolean;
  };
  mfa: {
    method?: 'sms' | 'totp';
    phoneNumber?: string;
    enrolled: boolean;
  };
  location: OwnerOnboardingLocation;
  hours: OperatingHoursDay[];
  services: OwnerOnboardingService[];
  preferences: {
    selfBookingAccess: 'anyone' | 'existing_clients' | 'disabled';
    requireDeposit: boolean;
    depositType?: 'amount' | 'percent';
    depositValue?: number;
    emailReminders: boolean;
    smsReminders: boolean;
    reminderLeadTimeHours: number;
  };
  billing: {
    planId?: string;
    requirePaymentMethod: boolean;
    checkoutUrl?: string;
    stripeCustomerId?: string;
  };
  workspace?: {
    businessId?: string;
    inviteCode?: string;
    publicSlug?: string;
    publicBookingUrl?: string;
  };
  updatedAt?: string;
};
