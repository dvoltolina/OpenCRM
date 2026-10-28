/**
 * SMS Types
 * Types for SMS messaging and sequences
 *
 * Path: businesses/{businessId}/sms_messages/{messageId}
 * Path: businesses/{businessId}/sms_opt_outs/{optOutId}
 * Path: businesses/{businessId}/sms_templates/{templateId}
 *
 * HIPAA Compliance:
 * - No PHI stored in SMS content (use portal links)
 * - Phone numbers masked in logs (last 4 digits only)
 * - Message content encrypted at rest
 * - Audit logging for all operations
 */

// ============================================
// Status Types
// ============================================

export type SmsStatus = 'queued' | 'sent' | 'delivered' | 'failed' | 'undelivered';

export type SmsDirection = 'outbound' | 'inbound';

export type OptOutStatus = 'opted_in' | 'opted_out' | 'pending';

export type OptOutSource = 'reply_stop' | 'manual' | 'import' | 'api';

export type SmsCategory = 'transactional' | 'marketing';

// ============================================
// SMS Message
// ============================================

export interface SmsMessage {
  id: string;
  businessId: string;

  // Recipient (no PHI stored with message)
  recipientId: string; // Lead/Client ID
  recipientPhone: string; // Stored for delivery, masked in logs

  // Sender
  fromNumber: string; // Twilio number
  sentById: string;
  sentByName: string;

  // Content
  body: string; // Max 160 chars for single SMS, up to 1600 for concatenated
  segmentCount: number; // Number of SMS segments

  // Status
  status: SmsStatus;
  direction: SmsDirection;
  providerMessageId?: string; // Twilio SID

  // Delivery tracking
  sentAt?: Date;
  deliveredAt?: Date;
  failedAt?: Date;
  errorCode?: string;
  errorMessage?: string;

  // Context
  relatedEntityType?: 'sequence_enrollment' | 'deal' | 'lead' | 'client';
  relatedEntityId?: string;

  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// SMS Opt-Out Management (TCPA Compliance)
// ============================================

export interface SmsOptOut {
  id: string;
  businessId: string;
  phone: string; // Normalized phone number (digits only)
  status: OptOutStatus;
  optedOutAt?: Date;
  optedInAt?: Date;
  source: OptOutSource;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// SMS Templates
// ============================================

export interface SmsTemplate {
  id: string;
  businessId: string;
  name: string;
  body: string; // With merge fields
  characterCount: number;
  segmentCount: number;
  isActive: boolean;
  category: SmsCategory;
  createdById: string;
  createdByName?: string;
  createdAt: Date;
  updatedAt?: Date;
}

// ============================================
// SMS Step Configuration (for sequences)
// ============================================

export interface SmsStepConfig {
  /** Reference to sms_templates collection */
  templateId?: string;
  /** Inline SMS body with merge fields */
  body?: string;
}

// ============================================
// Service Types
// ============================================

export interface SendSmsOptions {
  recipientId: string;
  recipientPhone: string;
  body: string;
  relatedEntity?: {
    type: 'sequence_enrollment' | 'deal' | 'lead' | 'client';
    id: string;
  };
}

export interface SendSmsResult {
  success: boolean;
  messageId?: string;
  providerMessageId?: string;
  segmentCount?: number;
  errorCode?: string;
  errorMessage?: string;
}

export interface SendTemplatedSmsOptions {
  recipientId: string;
  recipientPhone: string;
  templateId: string;
  mergeData: Record<string, string>;
  relatedEntity?: {
    type: 'sequence_enrollment' | 'deal' | 'lead' | 'client';
    id: string;
  };
}

// ============================================
// Rate Limit Configuration
// ============================================

export const SMS_RATE_LIMITS = {
  // Per-business: 200 SMS per hour
  BUSINESS_HOURLY: 200,
  BUSINESS_WINDOW_MS: 60 * 60 * 1000, // 1 hour

  // Per-contact: 2 SMS per day
  CONTACT_DAILY: 2,
  CONTACT_WINDOW_MS: 24 * 60 * 60 * 1000, // 24 hours
} as const;

// ============================================
// Character & Segment Calculation
// ============================================

/**
 * SMS segment limits:
 * - GSM-7 encoding: 160 chars per segment (or 153 for concatenated)
 * - UCS-2 encoding (Unicode): 70 chars per segment (or 67 for concatenated)
 */
export const SMS_CHAR_LIMITS = {
  GSM7_SINGLE: 160,
  GSM7_CONCAT: 153,
  UCS2_SINGLE: 70,
  UCS2_CONCAT: 67,
  MAX_SEGMENTS: 10, // Maximum 10 segments = ~1530 chars GSM-7
} as const;

/**
 * Characters that require UCS-2 encoding (non-GSM-7)
 */
const GSM7_CHARS = new Set([
  '@', '£', '$', '¥', 'è', 'é', 'ù', 'ì', 'ò', 'Ç', '\n', 'Ø', 'ø', '\r',
  'Å', 'å', 'Δ', '_', 'Φ', 'Γ', 'Λ', 'Ω', 'Π', 'Ψ', 'Σ', 'Θ', 'Ξ', 'Æ',
  'æ', 'ß', 'É', ' ', '!', '"', '#', '¤', '%', '&', "'", '(', ')', '*',
  '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8',
  '9', ':', ';', '<', '=', '>', '?', '¡', 'A', 'B', 'C', 'D', 'E', 'F',
  'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
  'U', 'V', 'W', 'X', 'Y', 'Z', 'Ä', 'Ö', 'Ñ', 'Ü', '§', '¿', 'a', 'b',
  'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
  'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'ä', 'ö', 'ñ', 'ü',
  'à',
]);

// Extended GSM-7 characters (count as 2 characters)
const GSM7_EXTENDED = new Set(['|', '^', '€', '{', '}', '[', ']', '~', '\\']);

/**
 * Check if text requires UCS-2 encoding
 */
export function requiresUcs2(text: string): boolean {
  for (const char of text) {
    if (!GSM7_CHARS.has(char) && !GSM7_EXTENDED.has(char)) {
      return true;
    }
  }
  return false;
}

/**
 * Calculate character count accounting for extended GSM-7 characters
 */
export function calculateCharacterCount(text: string): number {
  let count = 0;
  for (const char of text) {
    if (GSM7_EXTENDED.has(char)) {
      count += 2; // Extended chars count as 2
    } else {
      count += 1;
    }
  }
  return count;
}

/**
 * Calculate the number of SMS segments for a message
 */
export function calculateSegmentCount(text: string): number {
  if (!text || text.length === 0) {
    return 0;
  }

  const isUcs2 = requiresUcs2(text);
  const charCount = isUcs2 ? text.length : calculateCharacterCount(text);

  if (isUcs2) {
    if (charCount <= SMS_CHAR_LIMITS.UCS2_SINGLE) {
      return 1;
    }
    return Math.ceil(charCount / SMS_CHAR_LIMITS.UCS2_CONCAT);
  } else {
    if (charCount <= SMS_CHAR_LIMITS.GSM7_SINGLE) {
      return 1;
    }
    return Math.ceil(charCount / SMS_CHAR_LIMITS.GSM7_CONCAT);
  }
}

/**
 * Get remaining characters for current segment
 */
export function getRemainingChars(text: string): number {
  const isUcs2 = requiresUcs2(text);
  const charCount = isUcs2 ? text.length : calculateCharacterCount(text);
  const segments = calculateSegmentCount(text);

  if (segments <= 1) {
    const limit = isUcs2 ? SMS_CHAR_LIMITS.UCS2_SINGLE : SMS_CHAR_LIMITS.GSM7_SINGLE;
    return limit - charCount;
  }

  const limit = isUcs2 ? SMS_CHAR_LIMITS.UCS2_CONCAT : SMS_CHAR_LIMITS.GSM7_CONCAT;
  const usedInCurrentSegment = charCount % limit;
  return limit - (usedInCurrentSegment || limit);
}

// ============================================
// Phone Number Utilities
// ============================================

/**
 * Normalize a phone number to digits only (for opt-out storage)
 */
export function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, '');
}

/**
 * Mask phone number for logging (HIPAA compliance)
 * Shows only last 4 digits
 */
export function maskPhone(phone: string): string {
  const normalized = normalizePhone(phone);
  if (normalized.length < 4) {
    return '****';
  }
  return '***-***-' + normalized.slice(-4);
}

/**
 * Format phone for display
 */
export function formatPhoneDisplay(phone: string): string {
  const normalized = normalizePhone(phone);
  if (normalized.length === 10) {
    return `(${normalized.slice(0, 3)}) ${normalized.slice(3, 6)}-${normalized.slice(6)}`;
  }
  if (normalized.length === 11 && normalized.startsWith('1')) {
    return `+1 (${normalized.slice(1, 4)}) ${normalized.slice(4, 7)}-${normalized.slice(7)}`;
  }
  return phone;
}

/**
 * Validate phone number format (basic validation)
 */
export function isValidPhone(phone: string): boolean {
  const normalized = normalizePhone(phone);
  // US phone: 10 digits or 11 with country code
  return normalized.length === 10 || (normalized.length === 11 && normalized.startsWith('1'));
}

// ============================================
// Opt-Out Keywords (TCPA Compliance)
// ============================================

export const STOP_KEYWORDS = ['stop', 'stopall', 'unsubscribe', 'cancel', 'end', 'quit'];
export const START_KEYWORDS = ['start', 'yes', 'unstop'];

/**
 * Check if message is an opt-out request
 */
export function isOptOutKeyword(message: string): boolean {
  const normalized = message.toLowerCase().trim();
  return STOP_KEYWORDS.includes(normalized);
}

/**
 * Check if message is an opt-in request
 */
export function isOptInKeyword(message: string): boolean {
  const normalized = message.toLowerCase().trim();
  return START_KEYWORDS.includes(normalized);
}

// ============================================
// Cost Estimation
// ============================================

/** Approximate cost per SMS segment (Twilio pricing varies by carrier) */
export const SMS_COST_PER_SEGMENT = 0.0079;

/**
 * Estimate cost for an SMS message
 */
export function estimateCost(text: string): number {
  const segments = calculateSegmentCount(text);
  return segments * SMS_COST_PER_SEGMENT;
}

/**
 * Format cost for display
 */
export function formatCost(cost: number): string {
  return `$${cost.toFixed(4)}`;
}
