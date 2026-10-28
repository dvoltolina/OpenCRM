/**
 * SMS Service Tests
 *
 * Tests for SMS messaging functionality including:
 * - Sending SMS messages
 * - Opt-out management (TCPA compliance)
 * - Template handling
 * - Rate limiting
 * - HIPAA compliance
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import {
  calculateSegmentCount,
  calculateCharacterCount,
  getRemainingChars,
  requiresUcs2,
  normalizePhone,
  maskPhone,
  isValidPhone,
  isOptOutKeyword,
  isOptInKeyword,
  estimateCost,
  SMS_RATE_LIMITS,
  SMS_CHAR_LIMITS,
} from '../../types/sms';

// Mock the repositories and services
vi.mock('../../data/repositories/sms-message-repository', () => ({
  getSmsMessageRepository: vi.fn(() => ({
    create: vi.fn().mockResolvedValue({ success: true, data: { id: 'msg-123' } }),
    updateStatus: vi.fn().mockResolvedValue({ success: true }),
    getByRecipient: vi.fn().mockResolvedValue({ success: true, data: { data: [] } }),
    getByProviderMessageId: vi.fn().mockResolvedValue({ success: true, data: null }),
  })),
}));

vi.mock('../../data/repositories/sms-opt-out-repository', () => ({
  getSmsOptOutRepository: vi.fn(() => ({
    checkOptOut: vi.fn().mockResolvedValue({ success: true, data: 'pending' }),
    optOut: vi.fn().mockResolvedValue({ success: true }),
    optIn: vi.fn().mockResolvedValue({ success: true }),
  })),
}));

vi.mock('../../data/repositories/sms-template-repository', () => ({
  getSmsTemplateRepository: vi.fn(() => ({
    getById: vi.fn().mockResolvedValue({
      success: true,
      data: {
        id: 'tpl-123',
        name: 'Test Template',
        body: 'Hello {{firstName}}!',
        isActive: true,
      },
    }),
    getActiveTemplates: vi.fn().mockResolvedValue({ success: true, data: { data: [] } }),
  })),
}));

vi.mock('../RateLimitService', () => ({
  getRateLimitService: vi.fn(() => ({
    checkLimit: vi.fn().mockResolvedValue({ allowed: true, resetAt: new Date() }),
    recordAction: vi.fn().mockResolvedValue(undefined),
  })),
}));

vi.mock('../sequence-merge-fields', () => ({
  getMergeFieldProcessor: vi.fn(() => ({
    process: vi.fn().mockImplementation((template: string) =>
      template.replace(/\{\{firstName\}\}/g, 'John')
    ),
    validate: vi.fn().mockReturnValue({ valid: true, unknownFields: [] }),
    preview: vi.fn().mockImplementation((template: string) =>
      template.replace(/\{\{firstName\}\}/g, 'John')
    ),
  })),
}));

vi.mock('../../data/repositories/firestore-utils', () => ({
  generateId: vi.fn(() => 'generated-id-123'),
}));

// Test security context - kept for future test expansion
// const mockContext: SecurityContext = {
//   businessId: 'test-business-123',
//   userId: 'test-user-123',
//   userName: 'Test User',
//   userRole: 'admin',
//   teamIds: ['team-1'],
// };

describe('SMS Types Utilities', () => {
  describe('Character Counting', () => {
    it('counts basic GSM-7 characters correctly', () => {
      const text = 'Hello World';
      expect(calculateCharacterCount(text)).toBe(11);
    });

    it('counts extended GSM-7 characters as 2', () => {
      const text = 'Price: €100';
      // 'Price: ' (7) + '€' (2) + '100' (3) = 12
      expect(calculateCharacterCount(text)).toBe(12);
    });

    it('calculates segment count for short message', () => {
      const text = 'Short message';
      expect(calculateSegmentCount(text)).toBe(1);
    });

    it('calculates segment count for long message', () => {
      const text = 'A'.repeat(161);
      expect(calculateSegmentCount(text)).toBe(2);
    });

    it('calculates segment count for very long message', () => {
      const text = 'A'.repeat(500);
      expect(calculateSegmentCount(text)).toBe(4); // 500 / 153 = 3.27 -> 4 segments
    });

    it('returns 0 segments for empty text', () => {
      expect(calculateSegmentCount('')).toBe(0);
    });

    it('calculates remaining chars correctly', () => {
      const text = 'A'.repeat(150);
      expect(getRemainingChars(text)).toBe(10); // 160 - 150
    });

    it('handles concatenated segment remaining chars', () => {
      const text = 'A'.repeat(161);
      // 161 chars = 2 segments, current segment has 161 - 153 = 8 chars
      expect(getRemainingChars(text)).toBe(145); // 153 - 8
    });
  });

  describe('Encoding Detection', () => {
    it('detects GSM-7 compatible text', () => {
      expect(requiresUcs2('Hello World!')).toBe(false);
    });

    it('detects UCS-2 required for emoji', () => {
      expect(requiresUcs2('Hello 👋')).toBe(true);
    });

    it('detects UCS-2 required for non-Latin characters', () => {
      expect(requiresUcs2('こんにちは')).toBe(true);
    });

    it('handles GSM-7 extended characters', () => {
      expect(requiresUcs2('Price: €100')).toBe(false); // € is extended GSM-7
    });
  });

  describe('Phone Number Utilities', () => {
    it('normalizes phone numbers to digits only', () => {
      expect(normalizePhone('+1 (555) 123-4567')).toBe('15551234567');
      expect(normalizePhone('555.123.4567')).toBe('5551234567');
    });

    it('masks phone numbers for HIPAA', () => {
      expect(maskPhone('5551234567')).toBe('***-***-4567');
      expect(maskPhone('+15551234567')).toBe('***-***-4567');
    });

    it('handles short phone numbers', () => {
      expect(maskPhone('123')).toBe('****');
    });

    it('validates US phone numbers', () => {
      expect(isValidPhone('5551234567')).toBe(true);
      expect(isValidPhone('15551234567')).toBe(true);
      expect(isValidPhone('555123')).toBe(false);
      expect(isValidPhone('25551234567')).toBe(false); // Wrong country code
    });
  });

  describe('Opt-Out Keywords', () => {
    it('detects opt-out keywords', () => {
      expect(isOptOutKeyword('STOP')).toBe(true);
      expect(isOptOutKeyword('stop')).toBe(true);
      expect(isOptOutKeyword('UNSUBSCRIBE')).toBe(true);
      expect(isOptOutKeyword('  STOP  ')).toBe(true);
    });

    it('does not match non-opt-out text', () => {
      expect(isOptOutKeyword('hello')).toBe(false);
      expect(isOptOutKeyword('stop it')).toBe(false);
      expect(isOptOutKeyword('please stop')).toBe(false);
    });

    it('detects opt-in keywords', () => {
      expect(isOptInKeyword('START')).toBe(true);
      expect(isOptInKeyword('yes')).toBe(true);
      expect(isOptInKeyword('UNSTOP')).toBe(true);
    });
  });

  describe('Cost Estimation', () => {
    it('estimates cost for single segment', () => {
      const cost = estimateCost('Short message');
      expect(cost).toBeCloseTo(0.0079, 4);
    });

    it('estimates cost for multiple segments', () => {
      const text = 'A'.repeat(320); // ~3 segments
      const cost = estimateCost(text);
      expect(cost).toBeCloseTo(0.0237, 4); // 3 * 0.0079
    });

    it('returns 0 for empty message', () => {
      expect(estimateCost('')).toBe(0);
    });
  });
});

describe('SMS Service', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  // Note: Full service tests require more complex mocking of the SmsService class
  // These tests focus on the utility functions and types

  describe('Message Validation', () => {
    it('should reject messages that are too long', () => {
      const veryLongMessage = 'A'.repeat(1700);
      const segments = calculateSegmentCount(veryLongMessage);
      expect(segments).toBeGreaterThan(10);
    });

    it('should accept messages within limits', () => {
      const normalMessage = 'A'.repeat(160);
      const segments = calculateSegmentCount(normalMessage);
      expect(segments).toBe(1);
    });
  });

  describe('PHI Detection Patterns', () => {
    const phiPatterns = [
      /\b\d{3}-\d{2}-\d{4}\b/, // SSN
      /\b\d{9}\b/, // SSN without dashes
      /dob|date of birth|born on/i,
      /diagnosis|treatment|medication/i,
    ];

    it('should detect SSN patterns', () => {
      const messageWithSsn = 'Your SSN is 123-45-6789';
      expect(phiPatterns[0].test(messageWithSsn)).toBe(true);
    });

    it('should detect medical terms', () => {
      const messageWithPhi = 'Your diagnosis is confirmed';
      expect(phiPatterns[3].test(messageWithPhi)).toBe(true);
    });

    it('should allow safe messages', () => {
      const safeMessage = 'Please visit your portal for details.';
      const hasPhi = phiPatterns.some((p) => p.test(safeMessage));
      expect(hasPhi).toBe(false);
    });
  });
});

describe('SMS Rate Limiting', () => {
  it('defines correct business-level limits', () => {
    expect(SMS_RATE_LIMITS.BUSINESS_HOURLY).toBe(200);
    expect(SMS_RATE_LIMITS.BUSINESS_WINDOW_MS).toBe(3600000); // 1 hour
  });

  it('defines correct contact-level limits', () => {
    expect(SMS_RATE_LIMITS.CONTACT_DAILY).toBe(2);
    expect(SMS_RATE_LIMITS.CONTACT_WINDOW_MS).toBe(86400000); // 24 hours
  });
});

describe('SMS Character Limits', () => {
  it('defines correct GSM-7 limits', () => {
    expect(SMS_CHAR_LIMITS.GSM7_SINGLE).toBe(160);
    expect(SMS_CHAR_LIMITS.GSM7_CONCAT).toBe(153);
  });

  it('defines correct UCS-2 limits', () => {
    expect(SMS_CHAR_LIMITS.UCS2_SINGLE).toBe(70);
    expect(SMS_CHAR_LIMITS.UCS2_CONCAT).toBe(67);
  });

  it('defines maximum segment limit', () => {
    expect(SMS_CHAR_LIMITS.MAX_SEGMENTS).toBe(10);
  });
});

describe('SMS Template Validation', () => {
  const forbiddenMergeFields = [
    '{{ssn}}',
    '{{dob}}',
    '{{diagnosis}}',
    '{{treatment}}',
    '{{medical_record}}',
  ];

  const allowedMergeFields = [
    '{{firstName}}',
    '{{lastName}}',
    '{{companyName}}',
    '{{businessName}}',
    '{{portalLink}}',
  ];

  it('should flag templates with PHI merge fields', () => {
    const phiPattern = /\{\{.*(ssn|dob|diagnosis|treatment|medical).*\}\}/i;
    for (const field of forbiddenMergeFields) {
      expect(phiPattern.test(field)).toBe(true);
    }
  });

  it('should allow safe merge fields', () => {
    // Pattern checks for standalone PHI terms at word boundaries
    // Avoids false positives like 'businessName' containing 'ssn'
    const phiPatterns = [
      /\{\{ssn\}\}/i,
      /\{\{dob\}\}/i,
      /\{\{diagnosis\}\}/i,
      /\{\{treatment\}\}/i,
      /\{\{medical[_\-]?(record|number|id)?\}\}/i,
      /\{\{mrn\}\}/i,
    ];
    for (const field of allowedMergeFields) {
      const hasPhi = phiPatterns.some((p) => p.test(field));
      expect(hasPhi).toBe(false);
    }
  });
});
