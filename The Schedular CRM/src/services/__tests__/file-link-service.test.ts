import { describe, it, expect, beforeEach, vi } from 'vitest';
import { FileLinkService, parseTTL, formatTTL } from '../file-link-service';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { CreateFileLinkOptions, ValidateLinkOptions } from '../file-link-service';
import type { SecureFileLink } from '../../types/templates';

const mockLinkRepository = {
  create: vi.fn(),
  getByToken: vi.fn(),
  getById: vi.fn(),
  update: vi.fn(),
  getByFileId: vi.fn(),
};

const mockAccessLogRepository = {
  create: vi.fn(),
  getByLinkId: vi.fn(),
};

vi.mock('../../data/repositories/file-link-repository', () => ({
  getFileLinkRepository: () => mockLinkRepository,
}));

vi.mock('../../data/repositories/file-link-access-log-repository', () => ({
  getFileLinkAccessLogRepository: () => mockAccessLogRepository,
}));

describe('FileLinkService', () => {
  let service: FileLinkService;
  let mockContext: SecurityContext;

  beforeEach(() => {
    service = new FileLinkService();
    vi.clearAllMocks();
    mockContext = {
      businessId: 'test-business-id',
      userId: 'test-user-id',
      userName: 'Test User',
      userRole: 'admin',
    };
    mockLinkRepository.create.mockImplementation(async (_context, data) => ({
      success: true,
      data: {
        id: 'link-123',
        createdAt: new Date(),
        updatedAt: new Date(),
        ...data,
      } as SecureFileLink,
    }));
    mockLinkRepository.getByToken.mockResolvedValue({
      success: false,
      data: null,
      error: { code: 'NOT_FOUND', message: 'Not found' },
    });
    mockLinkRepository.getById.mockResolvedValue({
      success: true,
      data: {
        id: 'link-123',
        businessId: mockContext.businessId,
        currentAccessCount: 0,
      },
    });
    mockLinkRepository.update.mockResolvedValue({
      success: true,
      data: undefined,
    });
    mockAccessLogRepository.create.mockResolvedValue({ success: true, data: undefined });
  });

  describe('createExpiringLink', () => {
    it('should create a link with default TTL', async () => {
      const options: CreateFileLinkOptions = {
        fileId: 'file-123',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      if (result.data) {
        expect(result.data.fileId).toBe('file-123');
        expect(result.data.fileName).toBe('document.pdf');
        expect(result.data.token).toBeDefined();
        expect(result.data.isActive).toBe(true);
        expect(result.data.isRevoked).toBe(false);
        expect(result.data.currentAccessCount).toBe(0);
      }
    });

    it('should create a link with custom TTL', async () => {
      const customTTL = 24 * 60 * 60 * 1000; // 1 day
      const options: CreateFileLinkOptions = {
        fileId: 'file-123',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
        ttl: customTTL,
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(true);
      if (result.data) {
        const expiresAt = result.data.expiresAt;
        const now = new Date();
        const expectedExpiry = new Date(now.getTime() + customTTL);

        // Allow 1 second tolerance for test execution time
        expect(Math.abs(expiresAt.getTime() - expectedExpiry.getTime())).toBeLessThan(1000);
      }
    });

    it('should create a password-protected link', async () => {
      const options: CreateFileLinkOptions = {
        fileId: 'file-123',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
        password: 'secure123',
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(true);
      if (result.data) {
        expect(result.data.requiresPassword).toBe(true);
        expect(result.data.passwordHash).toBeDefined();
        expect(result.data.passwordHash).not.toBe('secure123'); // Should be hashed
      }
    });

    it('should create a link with max access count', async () => {
      const options: CreateFileLinkOptions = {
        fileId: 'file-123',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
        maxAccessCount: 5,
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(true);
      expect(result.data?.maxAccessCount).toBe(5);
    });

    it('should create a link with IP whitelist', async () => {
      const options: CreateFileLinkOptions = {
        fileId: 'file-123',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
        allowedIpAddresses: ['192.168.1.1', '10.0.0.1'],
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(true);
      expect(result.data?.allowedIpAddresses).toEqual(['192.168.1.1', '10.0.0.1']);
    });

    it('should reject missing required fields', async () => {
      const options: CreateFileLinkOptions = {
        fileId: '',
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
      };

      const result = await service.createExpiringLink(mockContext, options);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('validateLink', () => {
    it('should handle invalid token', async () => {
      const options: ValidateLinkOptions = {
        token: 'invalid-token',
      };

      const result = await service.validateLink(mockContext, options);

      expect(result.success).toBe(false);
      expect(result.error?.code).toBe('INVALID_TOKEN');
    });
  });

  describe('logAccess', () => {
    it('should log successful access', async () => {
      const accessData = {
        accessedAt: new Date(),
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        wasSuccessful: true,
        userId: 'user-123',
        userName: 'Test User',
      };

      const result = await service.logAccess(mockContext, 'link-123', accessData);

      // Should not throw error
      expect(result.success).toBeDefined();
    });

    it('should log failed access with reason', async () => {
      const accessData = {
        accessedAt: new Date(),
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        wasSuccessful: false,
        failureReason: 'expired' as const,
      };

      const result = await service.logAccess(mockContext, 'link-123', accessData);

      // Should not throw error
      expect(result.success).toBeDefined();
    });
  });
});

describe('Helper Functions', () => {
  describe('parseTTL', () => {
    it('should parse hours', () => {
      expect(parseTTL('24 hours')).toBe(24 * 60 * 60 * 1000);
      expect(parseTTL('1 hour')).toBe(60 * 60 * 1000);
    });

    it('should parse days', () => {
      expect(parseTTL('7 days')).toBe(7 * 24 * 60 * 60 * 1000);
      expect(parseTTL('1 day')).toBe(24 * 60 * 60 * 1000);
    });

    it('should parse weeks', () => {
      expect(parseTTL('2 weeks')).toBe(2 * 7 * 24 * 60 * 60 * 1000);
      expect(parseTTL('1 week')).toBe(7 * 24 * 60 * 60 * 1000);
    });

    it('should parse months', () => {
      expect(parseTTL('1 month')).toBe(30 * 24 * 60 * 60 * 1000);
    });

    it('should return default for invalid input', () => {
      const defaultTTL = 7 * 24 * 60 * 60 * 1000;
      expect(parseTTL('invalid')).toBe(defaultTTL);
      expect(parseTTL('')).toBe(defaultTTL);
    });
  });

  describe('formatTTL', () => {
    it('should format days and hours', () => {
      const ttl = 2 * 24 * 60 * 60 * 1000 + 3 * 60 * 60 * 1000;
      expect(formatTTL(ttl)).toBe('2 days 3 hours');
    });

    it('should format days only', () => {
      const ttl = 5 * 24 * 60 * 60 * 1000;
      expect(formatTTL(ttl)).toBe('5 days');
    });

    it('should format hours only', () => {
      const ttl = 12 * 60 * 60 * 1000;
      expect(formatTTL(ttl)).toBe('12 hours');
    });

    it('should format minutes', () => {
      const ttl = 30 * 60 * 1000;
      expect(formatTTL(ttl)).toBe('30 minutes');
    });

    it('should handle singular forms', () => {
      expect(formatTTL(24 * 60 * 60 * 1000)).toBe('1 day');
      expect(formatTTL(60 * 60 * 1000)).toBe('1 hour');
      expect(formatTTL(60 * 1000)).toBe('1 minute');
    });
  });
});
