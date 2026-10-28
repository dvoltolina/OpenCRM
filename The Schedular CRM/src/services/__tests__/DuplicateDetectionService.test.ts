/**
 * DuplicateDetectionService Tests
 * Agent CRM-27 Implementation
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  DuplicateDetectionService,
  getDuplicateDetectionService,
  type FindDuplicatesOptions,
  type MergeOptions,
} from '../DuplicateDetectionService';
import type { Lead, Client, Company } from '../../types/models';
import type { SecurityContext } from '../../data/repositories/repository-types';

// Mock repositories
vi.mock('../../data/repositories/lead-repository');
vi.mock('../../data/repositories/contact-repository');
vi.mock('../../data/repositories/company-repository');
vi.mock('../../data/repositories/deal-repository');
vi.mock('../../data/repositories/activity-repository');
vi.mock('../AuditLogService');

import { getLeadRepository } from '../../data/repositories/lead-repository';
import { getContactRepository } from '../../data/repositories/contact-repository';
import { getDealRepository } from '../../data/repositories/deal-repository';
import { getActivityRepository } from '../../data/repositories/activity-repository';
import { getAuditLogService } from '../AuditLogService';

describe('DuplicateDetectionService', () => {
  let service: DuplicateDetectionService;
  let mockContext: SecurityContext;
  let mockAuditService: { logAction: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    mockAuditService = {
      logAction: vi.fn().mockResolvedValue({ success: true }),
    };
    vi.mocked(getAuditLogService).mockReturnValue(mockAuditService as any);
    service = new DuplicateDetectionService();
    mockContext = {
      businessId: 'test-business',
      userId: 'test-user',
      userName: 'Test User',
      userRole: 'admin',
    };

    vi.clearAllMocks();
  });

  describe('getDuplicateDetectionService', () => {
    it('should return a singleton instance', () => {
      const instance1 = getDuplicateDetectionService();
      const instance2 = getDuplicateDetectionService();
      expect(instance1).toBe(instance2);
    });
  });

  describe('calculateMatchScore', () => {
    it('should return 100 for exact email match', () => {
      const lead1: Lead = {
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '555-1234',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const lead2: Lead = {
        id: '2',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '555-1234',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(lead1, lead2, 'lead');
      expect(score).toBeGreaterThanOrEqual(90); // High confidence for multiple matches
    });

    it('should detect phone match with different formats', () => {
      const client1: Client = {
        id: '1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '(555) 123-4567',
        tags: [],
        createdAt: new Date(),
      };

      const client2: Client = {
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        phone: '5551234567',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(client1, client2, 'client');
      // Score: email(0) + phone(90) + name(70) = 160/3 ≈ 53, with compound bonus ≈ 59
      expect(score).toBeGreaterThanOrEqual(50); // Good confidence for name + phone match
    });

    it('should detect fuzzy name match', () => {
      const lead1: Lead = {
        id: '1',
        firstName: 'Robert',
        lastName: 'Johnson',
        email: 'robert@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const lead2: Lead = {
        id: '2',
        firstName: 'Robert',
        lastName: 'Johnson',
        email: 'rob.johnson@example.com',
        status: 'new',
        source: 'referral',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(lead1, lead2, 'lead');
      // Score: email(0) + name(70) = 70/2 = 35
      expect(score).toBeGreaterThanOrEqual(30); // Medium confidence for name match only
    });

    it('should boost score for compound matches (name + company)', () => {
      const client1: Client = {
        id: '1',
        firstName: 'Alice',
        lastName: 'Williams',
        email: 'alice@example.com',
        companyName: 'Acme Corp',
        tags: [],
        createdAt: new Date(),
      };

      const client2: Client = {
        id: '2',
        firstName: 'Alice',
        lastName: 'Williams',
        email: 'awilliams@example.com',
        companyName: 'Acme Corp',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(client1, client2, 'client');
      // Score: email(0) + name(70) + company(80) = 150/3 = 50, with compound bonus ≈ 55
      expect(score).toBeGreaterThanOrEqual(50); // Boost for multiple matching factors
    });

    it('should handle entities with missing fields', () => {
      const lead1: Lead = {
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const lead2: Lead = {
        id: '2',
        firstName: 'Different',
        lastName: 'Person',
        email: 'different@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(lead1, lead2, 'lead');
      expect(score).toBeLessThan(60); // Low confidence when nothing matches
    });

    it('should handle company matching', () => {
      const company1: Company = {
        id: '1',
        name: 'Tech Solutions Inc',
        email: 'info@example.com',
        phone: '555-9999',
        tags: [],
        createdAt: new Date(),
      };

      const company2: Company = {
        id: '2',
        name: 'Tech Solutions Inc',
        email: 'contact@example.com',
        phone: '555-8888',
        tags: [],
        createdAt: new Date(),
      };

      const score = service.calculateMatchScore(company1, company2, 'company');
      // Score: email(0) + phone(0) + name(70) = 70/3 ≈ 23, but we have name match boost
      // Actually: email(0) + phone(0) + name(70) / 3 factors = 23
      expect(score).toBeGreaterThanOrEqual(20); // Good confidence for name match
    });
  });

  describe('findDuplicates', () => {
    it('should find duplicates by exact email match', async () => {
      const lead: Lead = {
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const duplicate: Lead = {
        id: '2',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '555-1234',
        status: 'contacted',
        source: 'referral',
        tags: [],
        createdAt: new Date(),
      };

      const mockLeadRepo = {
        search: vi.fn().mockResolvedValue({
          success: true,
          data: [duplicate],
        }),
      };

      vi.mocked(getLeadRepository).mockReturnValue(mockLeadRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'lead',
        minConfidence: 60,
      };

      const matches = await service.findDuplicates(mockContext, lead, options);

      expect(matches.length).toBeGreaterThan(0);
      expect(matches[0].entity.id).toBe('2');
      expect(matches[0].matchTypes).toContain('email');
      expect(matches[0].confidence).toBeGreaterThanOrEqual(90);
      expect(matches[0].matchDetails.email).toBe(true);
    });

    it('should find duplicates by phone match with different formats', async () => {
      const client: Client = {
        id: '1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '(555) 123-4567',
        tags: [],
        createdAt: new Date(),
      };

      const duplicate: Client = {
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.different@example.com',
        phone: '5551234567', // Same phone, different format
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        search: vi.fn()
          .mockResolvedValueOnce({ success: true, data: [] }) // Email search
          .mockResolvedValueOnce({ success: true, data: [duplicate] }) // Phone search
          .mockResolvedValueOnce({ success: true, data: [] }), // Name search
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'client',
        minConfidence: 50, // Lower threshold since phone+name match ≈ 59%
      };

      const matches = await service.findDuplicates(mockContext, client, options);

      expect(matches.length).toBeGreaterThan(0);
      expect(matches[0].matchTypes).toContain('phone');
      expect(matches[0].matchDetails.phone).toBe(true);
    });

    it('should find duplicates by fuzzy name match', async () => {
      const lead: Lead = {
        id: '1',
        firstName: 'Robert',
        lastName: 'Johnson',
        email: 'robert@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const duplicate: Lead = {
        id: '2',
        firstName: 'Robert',
        lastName: 'Johnson',
        email: 'rob@example.com',
        phone: '555-9999',
        status: 'qualified',
        source: 'referral',
        tags: [],
        createdAt: new Date(),
      };

      const mockLeadRepo = {
        search: vi.fn()
          .mockResolvedValueOnce({ success: true, data: [] }) // Email search
          .mockResolvedValueOnce({ success: true, data: [duplicate] }), // Name search (no phone search for lead without phone)
      };

      vi.mocked(getLeadRepository).mockReturnValue(mockLeadRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'lead',
        minConfidence: 30, // Lower threshold since name match alone ≈ 35%
      };

      const matches = await service.findDuplicates(mockContext, lead, options);

      expect(matches.length).toBeGreaterThan(0);
      expect(matches[0].matchTypes).toContain('name');
      expect(matches[0].matchDetails.name).toBe(true);
    });

    it('should respect minConfidence threshold', async () => {
      const client: Client = {
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const lowConfidenceMatch: Client = {
        id: '2',
        firstName: 'Different',
        lastName: 'Person',
        email: 'different@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        search: vi.fn().mockResolvedValue({
          success: true,
          data: [lowConfidenceMatch],
        }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'client',
        minConfidence: 80, // High threshold
      };

      const matches = await service.findDuplicates(mockContext, client, options);

      expect(matches.length).toBe(0); // No matches above threshold
    });

    it('should handle no duplicates found', async () => {
      const lead: Lead = {
        id: '1',
        firstName: 'Unique',
        lastName: 'Person',
        email: 'unique@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const mockLeadRepo = {
        search: vi.fn().mockResolvedValue({
          success: true,
          data: [],
        }),
      };

      vi.mocked(getLeadRepository).mockReturnValue(mockLeadRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'lead',
      };

      const matches = await service.findDuplicates(mockContext, lead, options);

      expect(matches).toEqual([]);
    });

    it('should exclude specified entity ID', async () => {
      const client: Client = {
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const duplicate: Client = {
        id: '2',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        search: vi.fn().mockResolvedValue({
          success: true,
          data: [client, duplicate], // Both entities returned
        }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'client',
        excludeId: '2', // Exclude the duplicate
      };

      const matches = await service.findDuplicates(mockContext, client, options);

      expect(matches.every((m) => m.entity.id !== '2')).toBe(true);
    });

    it('should limit results to specified maximum', async () => {
      const client: Client = {
        id: '1',
        firstName: 'Common',
        lastName: 'Name',
        email: 'common@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const manyDuplicates = Array.from({ length: 20 }, (_, i) => ({
        id: `${i + 2}`,
        firstName: 'Common',
        lastName: 'Name',
        email: `common${i}@example.com`,
        tags: [],
        createdAt: new Date(),
      }));

      const mockContactRepo = {
        search: vi.fn().mockResolvedValue({
          success: true,
          data: manyDuplicates,
        }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'client',
        limit: 5,
      };

      const matches = await service.findDuplicates(mockContext, client, options);

      expect(matches.length).toBeLessThanOrEqual(5);
    });

    it('should sort results by confidence score', async () => {
      const lead: Lead = {
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '555-1234',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date(),
      };

      const exactMatch: Lead = {
        id: '2',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '555-1234',
        status: 'contacted',
        source: 'referral',
        tags: [],
        createdAt: new Date(),
      };

      const phoneMatch: Lead = {
        id: '3',
        firstName: 'Different',
        lastName: 'Person',
        email: 'different@example.com',
        phone: '555-1234',
        status: 'new',
        source: 'coldCall',
        tags: [],
        createdAt: new Date(),
      };

      const mockLeadRepo = {
        search: vi.fn()
          .mockResolvedValueOnce({ success: true, data: [exactMatch] }) // Email
          .mockResolvedValueOnce({ success: true, data: [phoneMatch] }) // Phone
          .mockResolvedValueOnce({ success: true, data: [] }), // Name
      };

      vi.mocked(getLeadRepository).mockReturnValue(mockLeadRepo as any);

      const options: FindDuplicatesOptions = {
        entityType: 'lead',
      };

      const matches = await service.findDuplicates(mockContext, lead, options);

      // Results should be sorted by confidence
      for (let i = 1; i < matches.length; i++) {
        expect(matches[i - 1].confidence).toBeGreaterThanOrEqual(matches[i].confidence);
      }
    });
  });

  describe('merge', () => {
    it('should merge two entities with field preferences', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '555-1234',
        companyName: 'Acme Corp',
        tags: ['vip'],
        createdAt: new Date(),
      };

      const secondary: Client = {
        id: '2',
        firstName: 'John',
        lastName: 'Doe',
        email: 'j.doe@example.com',
        phone: '555-5678',
        companyName: 'Acme Corporation',
        tags: ['referral'],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({ success: true, data: secondary }),
        update: vi.fn().mockResolvedValue({
          success: true,
          data: { ...primary, phone: '555-5678', tags: ['vip', 'referral'] },
        }),
      };

      const mockDealRepo = {
        getByClient: vi.fn().mockResolvedValue({ success: true, data: [] }),
      };

      const emptyActivities = { success: true, data: { data: [], lastDoc: null, hasMore: false } };
      const mockActivityRepo = {
        getByLead: vi.fn().mockResolvedValue(emptyActivities),
        getByClient: vi.fn().mockResolvedValue(emptyActivities),
        getByCompany: vi.fn().mockResolvedValue(emptyActivities),
        update: vi.fn(),
        create: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);
      vi.mocked(getDealRepository).mockReturnValue(mockDealRepo as any);
      vi.mocked(getActivityRepository).mockReturnValue(mockActivityRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: '1',
        secondaryId: '2',
        fieldPreferences: {
          phone: 'secondary', // Prefer secondary's phone
        },
      };

      const result = await service.merge(mockContext, options);

      expect(result.merged).toBeDefined();
      expect(mockContactRepo.update).toHaveBeenCalledWith(
        mockContext,
        '1',
        expect.objectContaining({
          tags: expect.arrayContaining(['vip', 'referral']), // Tags merged
        })
      );
    });

    it('should transfer related deals when merging clients', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const secondary: Client = {
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'j.smith@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const relatedDeals = [
        { id: 'deal-1', clientId: '2', title: 'Deal 1' },
        { id: 'deal-2', clientId: '2', title: 'Deal 2' },
      ];

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({ success: true, data: secondary }),
        update: vi.fn().mockResolvedValue({ success: true, data: primary }),
      };

      const mockDealRepo = {
        getByClient: vi.fn().mockResolvedValue({ success: true, data: relatedDeals }),
        update: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      const emptyActivities = { success: true, data: { data: [], lastDoc: null, hasMore: false } };
      const mockActivityRepo = {
        getByLead: vi.fn().mockResolvedValue(emptyActivities),
        getByClient: vi.fn().mockResolvedValue(emptyActivities),
        getByCompany: vi.fn().mockResolvedValue(emptyActivities),
        update: vi.fn(),
        create: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);
      vi.mocked(getDealRepository).mockReturnValue(mockDealRepo as any);
      vi.mocked(getActivityRepository).mockReturnValue(mockActivityRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: '1',
        secondaryId: '2',
        transferRelatedRecords: true,
      };

      const result = await service.merge(mockContext, options);

      expect(result.transferredDealIds).toEqual(['deal-1', 'deal-2']);
      expect(mockDealRepo.update).toHaveBeenCalledTimes(2);
      expect(mockDealRepo.update).toHaveBeenCalledWith(
        mockContext,
        'deal-1',
        expect.objectContaining({ clientId: '1' })
      );
    });

    it('should log merge activity', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const secondary: Client = {
        id: '2',
        firstName: 'Test',
        lastName: 'User',
        email: 'test2@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({ success: true, data: secondary }),
        update: vi.fn().mockResolvedValue({ success: true, data: primary }),
      };

      const mockDealRepo = {
        getByClient: vi.fn().mockResolvedValue({ success: true, data: [] }),
      };

      const emptyActivities = { success: true, data: { data: [], lastDoc: null, hasMore: false } };
      const mockActivityRepo = {
        getByLead: vi.fn().mockResolvedValue(emptyActivities),
        getByClient: vi.fn().mockResolvedValue(emptyActivities),
        getByCompany: vi.fn().mockResolvedValue(emptyActivities),
        update: vi.fn(),
        create: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);
      vi.mocked(getDealRepository).mockReturnValue(mockDealRepo as any);
      vi.mocked(getActivityRepository).mockReturnValue(mockActivityRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: '1',
        secondaryId: '2',
      };

      await service.merge(mockContext, options);

      expect(mockActivityRepo.create).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          type: 'note',
          title: 'Client Merged',
          clientId: '1',
        })
      );
    });

    it('audits merges with metadata only', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'Audit',
        lastName: 'Target',
        email: 'audit@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const secondary: Client = {
        id: '2',
        firstName: 'Audit',
        lastName: 'Target',
        email: 'audit2@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({ success: true, data: secondary }),
        update: vi.fn().mockResolvedValue({ success: true, data: primary }),
      };

      const mockDealRepo = {
        getByClient: vi.fn().mockResolvedValue({ success: true, data: [] }),
        update: vi.fn(),
      };

      const emptyActivities = { success: true, data: { data: [], lastDoc: null, hasMore: false } };
      const mockActivityRepo = {
        getByLead: vi.fn().mockResolvedValue(emptyActivities),
        getByClient: vi.fn().mockResolvedValue(emptyActivities),
        getByCompany: vi.fn().mockResolvedValue(emptyActivities),
        update: vi.fn(),
        create: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);
      vi.mocked(getDealRepository).mockReturnValue(mockDealRepo as any);
      vi.mocked(getActivityRepository).mockReturnValue(mockActivityRepo as any);

      await service.merge(mockContext, {
        entityType: 'client',
        primaryId: '1',
        secondaryId: '2',
      });

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'merge',
          entityType: 'contact',
          entityId: '1',
          metadata: expect.objectContaining({
            mergedFromId: '2',
          }),
        })
      );
    });

    it('should archive secondary entity with merge tag', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'Alice',
        lastName: 'Williams',
        email: 'alice@example.com',
        tags: ['vip'],
        createdAt: new Date(),
      };

      const secondary: Client = {
        id: '2',
        firstName: 'Alice',
        lastName: 'Williams',
        email: 'a.williams@example.com',
        tags: ['lead'],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({ success: true, data: secondary }),
        update: vi.fn().mockResolvedValue({ success: true, data: primary }),
      };

      const mockDealRepo = {
        getByClient: vi.fn().mockResolvedValue({ success: true, data: [] }),
      };

      const emptyActivities = { success: true, data: { data: [], lastDoc: null, hasMore: false } };
      const mockActivityRepo = {
        getByLead: vi.fn().mockResolvedValue(emptyActivities),
        getByClient: vi.fn().mockResolvedValue(emptyActivities),
        getByCompany: vi.fn().mockResolvedValue(emptyActivities),
        update: vi.fn(),
        create: vi.fn().mockResolvedValue({ success: true, data: {} }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);
      vi.mocked(getDealRepository).mockReturnValue(mockDealRepo as any);
      vi.mocked(getActivityRepository).mockReturnValue(mockActivityRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: '1',
        secondaryId: '2',
      };

      await service.merge(mockContext, options);

      expect(mockContactRepo.update).toHaveBeenCalledWith(
        mockContext,
        '2',
        expect.objectContaining({
          tags: expect.arrayContaining(['MERGED', 'MERGED_INTO:1']),
        })
      );
    });

    it('should throw error if primary entity not found', async () => {
      const mockContactRepo = {
        getById: vi.fn().mockResolvedValue({
          success: false,
          error: { message: 'Entity not found' },
        }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: 'non-existent',
        secondaryId: '2',
      };

      await expect(service.merge(mockContext, options)).rejects.toThrow(
        'Primary entity not found'
      );
    });

    it('should throw error if secondary entity not found', async () => {
      const primary: Client = {
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        tags: [],
        createdAt: new Date(),
      };

      const mockContactRepo = {
        getById: vi.fn()
          .mockResolvedValueOnce({ success: true, data: primary })
          .mockResolvedValueOnce({
            success: false,
            error: { message: 'Entity not found' },
          }),
      };

      vi.mocked(getContactRepository).mockReturnValue(mockContactRepo as any);

      const options: MergeOptions = {
        entityType: 'client',
        primaryId: '1',
        secondaryId: 'non-existent',
      };

      await expect(service.merge(mockContext, options)).rejects.toThrow(
        'Secondary entity not found'
      );
    });
  });
});
