import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ESignService } from '../esign-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { CaptureSignatureOptions } from '../esign-service';
import type { SignatureMetadata } from '../../types/templates';

const mockSignatureRepository = {
  create: vi.fn(),
  verifySignature: vi.fn(),
  getById: vi.fn(),
  getByDocument: vi.fn(),
  getBySigner: vi.fn(),
  isDocumentFullySigned: vi.fn(),
};

vi.mock('../../data/repositories/signature-repository', () => ({
  getSignatureRepository: () => mockSignatureRepository,
}));

describe('ESignService', () => {
  let service: ESignService;
  let mockContext: SecurityContext;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new ESignService();
    mockContext = {
      businessId: 'test-business-id',
      userId: 'test-user-id',
      userName: 'Test User',
      userRole: 'admin',
    };
    mockSignatureRepository.create.mockImplementation(async (_context, data) => ({
      success: true,
      data: {
        id: 'signature-123',
        createdAt: new Date(),
        ...data,
      } as SignatureMetadata,
    }));
  });

  describe('captureSignature', () => {
    it('should capture signature metadata successfully', async () => {
      const options: CaptureSignatureOptions = {
        signerId: 'client-123',
        signerEmail: 'client@example.com',
        signerName: 'John Doe',
        signerRole: 'client',
        documentId: 'doc-123',
        documentType: 'template_instance',
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
      };

      const result = await service.captureSignature(mockContext, options);

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      if (result.data) {
        expect(result.data.signerId).toBe('client-123');
        expect(result.data.signerEmail).toBe('client@example.com');
        expect(result.data.documentId).toBe('doc-123');
        expect(result.data.isVerified).toBe(true); // No verification required by default
      }
    });

    it('should require verification when specified', async () => {
      const options: CaptureSignatureOptions = {
        signerId: 'client-123',
        signerEmail: 'client@example.com',
        signerName: 'John Doe',
        documentId: 'doc-123',
        documentType: 'template_instance',
        requireVerification: true,
        verificationCode: '123456',
      };

      const result = await service.captureSignature(mockContext, options);

      expect(result.success).toBe(true);
      expect(result.data?.isVerified).toBe(false);
      expect(result.data?.verificationCode).toBe('123456');
    });

    it('should reject missing required fields', async () => {
      const options: CaptureSignatureOptions = {
        signerId: '',
        signerEmail: 'client@example.com',
        signerName: 'John Doe',
        documentId: 'doc-123',
        documentType: 'template_instance',
      };

      const result = await service.captureSignature(mockContext, options);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('validateSignatureMetadata', () => {
    it('should validate correct signature metadata', () => {
      const options: CaptureSignatureOptions = {
        signerId: 'client-123',
        signerEmail: 'client@example.com',
        signerName: 'John Doe',
        documentId: 'doc-123',
        documentType: 'template_instance',
      };

      const result = service.validateSignatureMetadata(options);

      expect(result.isValid).toBe(true);
      expect(result.error).toBeUndefined();
    });

    it('should reject invalid email', () => {
      const options: CaptureSignatureOptions = {
        signerId: 'client-123',
        signerEmail: 'invalid-email',
        signerName: 'John Doe',
        documentId: 'doc-123',
        documentType: 'template_instance',
      };

      const result = service.validateSignatureMetadata(options);

      expect(result.isValid).toBe(false);
      expect(result.error).toContain('email');
    });

    it('should reject missing signer ID', () => {
      const options: CaptureSignatureOptions = {
        signerId: '',
        signerEmail: 'client@example.com',
        signerName: 'John Doe',
        documentId: 'doc-123',
        documentType: 'template_instance',
      };

      const result = service.validateSignatureMetadata(options);

      expect(result.isValid).toBe(false);
      expect(result.error).toContain('Signer ID');
    });
  });

  describe('generateVerificationCode', () => {
    it('should generate a 6-digit code', () => {
      const code = service.generateVerificationCode();

      expect(code).toHaveLength(6);
      expect(parseInt(code, 10)).toBeGreaterThanOrEqual(100000);
      expect(parseInt(code, 10)).toBeLessThan(1000000);
    });

    it('should generate unique codes', () => {
      const codes = new Set<string>();
      for (let i = 0; i < 100; i++) {
        codes.add(service.generateVerificationCode());
      }

      // Should have mostly unique codes (allowing for some collision in 100 tries)
      expect(codes.size).toBeGreaterThan(90);
    });
  });
});
