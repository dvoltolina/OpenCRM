/**
 * Web Form Submission Service Tests
 * Agent Web Forms Implementation
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock dependencies before imports
const mockFormRepo = {
  getPublicForm: vi.fn(),
  getById: vi.fn(),
  incrementSubmissionCount: vi.fn(),
};

const mockLeadRepo = {
  create: vi.fn(),
};

const mockDuplicateService = {
  findDuplicates: vi.fn().mockResolvedValue([]),
};

const mockRateLimitService = {
  checkLimit: vi.fn().mockResolvedValue({ allowed: true, remaining: 10 }),
  recordAction: vi.fn(),
};

const mockAuditLogService = {
  logAction: vi.fn(),
};

vi.mock('../../data/repositories/web-form-repository', () => ({
  getWebFormRepository: vi.fn(() => mockFormRepo),
}));

vi.mock('../../data/repositories/lead-repository', () => ({
  getLeadRepository: vi.fn(() => mockLeadRepo),
}));

vi.mock('../DuplicateDetectionService', () => ({
  getDuplicateDetectionService: vi.fn(() => mockDuplicateService),
}));

vi.mock('../RateLimitService', () => ({
  getRateLimitService: vi.fn(() => mockRateLimitService),
}));

vi.mock('../AuditLogService', () => ({
  getAuditLogService: vi.fn(() => mockAuditLogService),
}));

import { WebFormSubmissionService, getWebFormSubmissionService } from '../web-form-submission-service';
import { getWebFormRepository } from '../../data/repositories/web-form-repository';
import { getLeadRepository } from '../../data/repositories/lead-repository';
import { getRateLimitService } from '../RateLimitService';
import type { WebFormSubmissionData } from '../../types/web-forms';

describe('WebFormSubmissionService', () => {
  let service: WebFormSubmissionService;

  const mockBusinessId = 'test-business-123';
  const mockFormId = 'test-form-456';
  const mockIpAddress = '192.168.1.1';

  const mockForm = {
    id: mockFormId,
    name: 'Contact Form',
    status: 'active',
    fields: [
      { id: 'firstName', type: 'text', label: 'First Name', required: true, mapToField: 'firstName' },
      { id: 'lastName', type: 'text', label: 'Last Name', required: true, mapToField: 'lastName' },
      { id: 'email', type: 'email', label: 'Email', required: true, mapToField: 'email' },
      { id: 'phone', type: 'phone', label: 'Phone', required: false, mapToField: 'phone' },
    ],
    settings: {
      submitButtonText: 'Submit',
      successMessage: 'Thank you!',
      defaultTags: ['web-form'],
      defaultLeadSource: 'website',
    },
    spamProtection: {
      honeypot: true,
      rateLimit: 10,
      recaptchaEnabled: false,
    },
    styling: { theme: 'light' },
    stats: { totalSubmissions: 0, submissionsThisMonth: 0 },
    ownerId: 'owner-123',
    ownerName: 'Test Owner',
    teamIds: ['team-1'],
    visibility: 'team',
    createdAt: new Date(),
  };

  const mockSubmission: WebFormSubmissionData = {
    formId: mockFormId,
    fieldValues: {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      phone: '555-123-4567',
    },
    metadata: {
      referrerUrl: 'https://example.com',
      utmSource: 'google',
      utmMedium: 'cpc',
      submittedAt: new Date(),
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
    service = new WebFormSubmissionService();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe('submitForm', () => {
    it('should successfully submit a valid form', async () => {
      const formRepo = getWebFormRepository();
      const leadRepo = getLeadRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Contact Form', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: true, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: mockForm as any,
        error: null,
      });

      vi.mocked(leadRepo.create).mockResolvedValue({
        success: true,
        data: { id: 'lead-123', ...mockSubmission.fieldValues } as any,
        error: null,
      });

      vi.mocked(formRepo.incrementSubmissionCount).mockResolvedValue({
        success: true,
        data: undefined,
        error: null,
      });

      const result = await service.submitForm(mockBusinessId, mockSubmission, mockIpAddress);

      expect(result.success).toBe(true);
      expect(result.leadId).toBe('lead-123');
      expect(leadRepo.create).toHaveBeenCalled();
      expect(formRepo.incrementSubmissionCount).toHaveBeenCalledWith(
        expect.any(Object),
        mockFormId
      );
    });

    it('should reject submission when form is not found', async () => {
      const formRepo = getWebFormRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: false,
        data: null,
        error: { message: 'Not found' } as any,
      });

      const result = await service.submitForm(mockBusinessId, mockSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('FORM_NOT_FOUND');
    });

    it('should reject submission when form is inactive', async () => {
      const formRepo = getWebFormRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Test', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: false, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: { ...mockForm, status: 'inactive' } as any,
        error: null,
      });

      const result = await service.submitForm(mockBusinessId, mockSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('FORM_INACTIVE');
    });

    it('should detect honeypot spam', async () => {
      const formRepo = getWebFormRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Test', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: true, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: mockForm as any,
        error: null,
      });

      const spamSubmission = {
        ...mockSubmission,
        honeypotValue: 'spam content', // Honeypot filled = bot
      };

      const result = await service.submitForm(mockBusinessId, spamSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('SPAM_DETECTED');
    });

    it('should enforce rate limiting', async () => {
      const formRepo = getWebFormRepository();
      const rateLimitService = getRateLimitService();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Test', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: false, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: mockForm as any,
        error: null,
      });

      vi.mocked(rateLimitService.checkLimit).mockResolvedValue({
        allowed: false,
        remaining: 0,
        resetAt: new Date(),
        message: 'Rate limit exceeded',
      });

      const result = await service.submitForm(mockBusinessId, mockSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('RATE_LIMITED');
    });

    it('should validate required fields', async () => {
      const formRepo = getWebFormRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Test', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: false, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: mockForm as any,
        error: null,
      });

      const incompleteSubmission: WebFormSubmissionData = {
        ...mockSubmission,
        fieldValues: {
          firstName: 'John',
          // Missing required lastName and email
        },
      };

      const result = await service.submitForm(mockBusinessId, incompleteSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('VALIDATION_ERROR');
    });

    it('should validate email format', async () => {
      const formRepo = getWebFormRepository();

      vi.mocked(formRepo.getPublicForm).mockResolvedValue({
        success: true,
        data: { id: mockFormId, name: 'Test', fields: [], submitButtonText: 'Submit', successMessage: 'Thanks', honeypotEnabled: false, recaptchaEnabled: false, styling: { theme: 'light' } },
        error: null,
      });

      vi.mocked(formRepo.getById).mockResolvedValue({
        success: true,
        data: mockForm as any,
        error: null,
      });

      const badEmailSubmission: WebFormSubmissionData = {
        ...mockSubmission,
        fieldValues: {
          ...mockSubmission.fieldValues,
          email: 'invalid-email',
        },
      };

      const result = await service.submitForm(mockBusinessId, badEmailSubmission, mockIpAddress);

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('VALIDATION_ERROR');
    });
  });

  describe('getWebFormSubmissionService', () => {
    it('should return singleton instance', () => {
      const instance1 = getWebFormSubmissionService();
      const instance2 = getWebFormSubmissionService();
      expect(instance1).toBe(instance2);
    });
  });
});
