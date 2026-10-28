/**
 * Sequence Analytics Service Tests
 * Tests for metrics calculation, funnel data, trends, and comparisons.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  Sequence,
  SequenceEnrollment,
  SequenceExecution,
  SequenceStep,
} from '../../types/sequences';

// Mock repositories
const mockSequenceRepo = {
  getById: vi.fn(),
  list: vi.fn(),
};

const mockEnrollmentRepo = {
  getBySequence: vi.fn(),
};

const mockExecutionRepo = {
  getByEnrollment: vi.fn(),
  getByStep: vi.fn(),
};

const mockAuditService = {
  logAction: vi.fn(),
};

vi.mock('../../data/repositories/sequence-repository', () => ({
  getSequenceRepository: () => mockSequenceRepo,
}));

vi.mock('../../data/repositories/sequence-enrollment-repository', () => ({
  getSequenceEnrollmentRepository: () => mockEnrollmentRepo,
}));

vi.mock('../../data/repositories/sequence-execution-repository', () => ({
  getSequenceExecutionRepository: () => mockExecutionRepo,
}));

vi.mock('../AuditLogService', () => ({
  getAuditLogService: () => mockAuditService,
}));

// Import after mocks are set up
import { SequenceAnalyticsService } from '../sequence-analytics-service';

// ============================================
// Test Fixtures
// ============================================

const mockContext: SecurityContext = {
  businessId: 'business-1',
  userId: 'user-1',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const createMockStep = (index: number, type: 'email' | 'task' | 'wait' = 'email'): SequenceStep => ({
  id: `step-${index}`,
  order: index,
  type,
  delayDays: index,
  isActive: true,
  emailConfig: type === 'email' ? { subject: `Email ${index}`, body: 'Test body' } : undefined,
  taskConfig: type === 'task' ? { title: `Task ${index}`, assignToOwner: true, dueDays: 0 } : undefined,
});

const createMockSequence = (id: string, steps: SequenceStep[]): Sequence => ({
  id,
  name: `Sequence ${id}`,
  status: 'active',
  steps,
  settings: {
    sendingSchedule: {
      timezone: 'America/New_York',
      businessHoursOnly: true,
      startHour: 9,
      endHour: 17,
      excludeDays: [0, 6],
    },
    pauseOnReply: true,
    pauseOnOpen: false,
    pauseOnMeetingBooked: true,
    removeOnUnsubscribe: true,
    threadEmails: false,
  },
  stats: {
    totalEnrolled: 100,
    activeEnrollments: 20,
    completedCount: 50,
    exitedCount: 30,
  },
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: [],
  visibility: 'team',
  createdAt: new Date('2025-01-01'),
});

const createMockEnrollment = (
  id: string,
  sequenceId: string,
  status: 'active' | 'completed' | 'exited' = 'active',
  stats: Partial<SequenceEnrollment> = {}
): SequenceEnrollment => ({
  id,
  sequenceId,
  sequenceName: `Sequence ${sequenceId}`,
  entityType: 'lead',
  entityId: `entity-${id}`,
  entityName: `Entity ${id}`,
  entityEmail: `entity${id}@test.com`,
  status,
  currentStepIndex: 0,
  stepsCompleted: stats.stepsCompleted || 0,
  totalSteps: 3,
  emailsSent: stats.emailsSent || 0,
  emailsOpened: stats.emailsOpened || 0,
  emailsClicked: stats.emailsClicked || 0,
  tasksCreated: stats.tasksCreated || 0,
  repliesReceived: stats.repliesReceived || 0,
  enrolledById: 'user-1',
  enrolledByName: 'User 1',
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: [],
  visibility: 'team',
  createdAt: new Date('2025-01-15'),
  exitReason: status === 'exited' ? 'manual' : undefined,
  exitedAt: status === 'exited' ? new Date('2025-01-20') : undefined,
  completedAt: status === 'completed' ? new Date('2025-01-25') : undefined,
});

const createMockExecution = (
  id: string,
  enrollmentId: string,
  stepIndex: number,
  status: 'completed' | 'failed' = 'completed'
): SequenceExecution => ({
  id,
  enrollmentId,
  sequenceId: 'seq-1',
  stepId: `step-${stepIndex}`,
  stepIndex,
  stepType: 'email',
  status,
  scheduledAt: new Date('2025-01-15'),
  executedAt: new Date('2025-01-15'),
  idempotencyKey: `${enrollmentId}:step-${stepIndex}`,
  emailMetrics: {
    delivered: true,
    deliveredAt: new Date('2025-01-15'),
    opened: stepIndex < 2,
    openedAt: stepIndex < 2 ? new Date('2025-01-15') : undefined,
    clicked: stepIndex === 0,
    clickedAt: stepIndex === 0 ? new Date('2025-01-15') : undefined,
    replied: stepIndex === 0,
    repliedAt: stepIndex === 0 ? new Date('2025-01-16') : undefined,
    bounced: false,
  },
  createdAt: new Date('2025-01-15'),
});

// ============================================
// Tests
// ============================================

describe('SequenceAnalyticsService', () => {
  let service: SequenceAnalyticsService;

  beforeEach(() => {
    vi.clearAllMocks();
    service = new SequenceAnalyticsService();
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  describe('calculateSequenceMetrics', () => {
    it('should return null when sequence not found', async () => {
      mockSequenceRepo.getById.mockResolvedValue({ success: false });

      const result = await service.calculateSequenceMetrics(mockContext, 'non-existent');

      expect(result).toBeNull();
    });

    it('should return empty metrics when no enrollments', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: [] });

      const result = await service.calculateSequenceMetrics(mockContext, 'seq-1');

      expect(result).not.toBeNull();
      expect(result!.totalEnrolled).toBe(0);
      expect(result!.completionRate).toBe(0);
    });

    it('should calculate correct enrollment metrics', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0), createMockStep(1)]);
      const enrollments = [
        createMockEnrollment('e1', 'seq-1', 'completed', { emailsSent: 2, emailsOpened: 1 }),
        createMockEnrollment('e2', 'seq-1', 'completed', { emailsSent: 2, emailsOpened: 2 }),
        createMockEnrollment('e3', 'seq-1', 'exited', { emailsSent: 1, emailsOpened: 0 }),
        createMockEnrollment('e4', 'seq-1', 'active', { emailsSent: 1, emailsOpened: 1 }),
      ];

      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.calculateSequenceMetrics(mockContext, 'seq-1');

      expect(result).not.toBeNull();
      expect(result!.totalEnrolled).toBe(4);
      expect(result!.activeEnrollments).toBe(1);
      expect(result!.completedCount).toBe(2);
      expect(result!.exitedCount).toBe(1);
      // Completion rate: 2 completed / (2 completed + 1 exited) = 66.67%
      expect(result!.completionRate).toBeCloseTo(66.67, 1);
      expect(result!.emailsSent).toBe(6); // 2+2+1+1
      expect(result!.emailsOpened).toBe(4); // 1+2+0+1
    });

    it('should calculate correct exit reason breakdown', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      const enrollments = [
        { ...createMockEnrollment('e1', 'seq-1', 'exited'), exitReason: 'replied' as const },
        { ...createMockEnrollment('e2', 'seq-1', 'exited'), exitReason: 'replied' as const },
        { ...createMockEnrollment('e3', 'seq-1', 'exited'), exitReason: 'manual' as const },
        { ...createMockEnrollment('e4', 'seq-1', 'exited'), exitReason: 'bounced' as const },
      ];

      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.calculateSequenceMetrics(mockContext, 'seq-1');

      expect(result).not.toBeNull();
      expect(result!.exitReasons).toEqual({
        replied: 2,
        manual: 1,
        bounced: 1,
      });
    });

    it('should filter by date range', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      const enrollments = [
        { ...createMockEnrollment('e1', 'seq-1', 'completed'), createdAt: new Date('2025-01-01') },
        { ...createMockEnrollment('e2', 'seq-1', 'completed'), createdAt: new Date('2025-01-15') },
        { ...createMockEnrollment('e3', 'seq-1', 'active'), createdAt: new Date('2025-02-01') },
      ];

      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.calculateSequenceMetrics(mockContext, 'seq-1', {
        start: new Date('2025-01-10'),
        end: new Date('2025-01-31'),
      });

      expect(result).not.toBeNull();
      expect(result!.totalEnrolled).toBe(1); // Only e2 is in range
    });

    it('should audit log the metrics calculation', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: [] });

      await service.calculateSequenceMetrics(mockContext, 'seq-1');

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          entityId: 'seq-1',
        })
      );
    });
  });

  describe('calculateStepMetrics', () => {
    it('should return null when sequence not found', async () => {
      mockSequenceRepo.getById.mockResolvedValue({ success: false });

      const result = await service.calculateStepMetrics(mockContext, 'seq-1', 'step-0');

      expect(result).toBeNull();
    });

    it('should return null when step not found', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });

      const result = await service.calculateStepMetrics(mockContext, 'seq-1', 'non-existent-step');

      expect(result).toBeNull();
    });

    it('should calculate step metrics correctly', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0), createMockStep(1)]);
      const enrollments = [
        createMockEnrollment('e1', 'seq-1', 'completed', { stepsCompleted: 2 }),
        createMockEnrollment('e2', 'seq-1', 'active', { stepsCompleted: 1 }),
      ];

      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });
      mockExecutionRepo.getByStep.mockImplementation((_ctx, enrollmentId, stepId) => {
        if (stepId === 'step-0') {
          return Promise.resolve({
            success: true,
            data: createMockExecution(`exec-${enrollmentId}`, enrollmentId, 0),
          });
        }
        return Promise.resolve({ success: true, data: null });
      });

      const result = await service.calculateStepMetrics(mockContext, 'seq-1', 'step-0');

      expect(result).not.toBeNull();
      expect(result!.stepId).toBe('step-0');
      expect(result!.stepIndex).toBe(0);
      expect(result!.stepType).toBe('email');
    });
  });

  describe('getEnrollmentFunnel', () => {
    it('should return empty funnel when sequence not found', async () => {
      mockSequenceRepo.getById.mockResolvedValue({ success: false });

      const result = await service.getEnrollmentFunnel(mockContext, 'seq-1');

      expect(result.steps).toHaveLength(0);
      expect(result.overallConversionRate).toBe(0);
    });

    it('should calculate funnel steps correctly', async () => {
      const sequence = createMockSequence('seq-1', [
        createMockStep(0),
        createMockStep(1),
        createMockStep(2),
      ]);
      const enrollments = [
        createMockEnrollment('e1', 'seq-1', 'completed', { stepsCompleted: 3, currentStepIndex: 3 }),
        createMockEnrollment('e2', 'seq-1', 'completed', { stepsCompleted: 3, currentStepIndex: 3 }),
        { ...createMockEnrollment('e3', 'seq-1', 'exited', { stepsCompleted: 1 }), currentStepIndex: 1 },
        createMockEnrollment('e4', 'seq-1', 'active', { stepsCompleted: 0, currentStepIndex: 0 }),
      ];

      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });

      const result = await service.getEnrollmentFunnel(mockContext, 'seq-1');

      expect(result.steps).toHaveLength(3);
      // Overall: 2 completed out of 4 = 50%
      expect(result.overallConversionRate).toBe(50);
    });

    it('should audit log funnel access', async () => {
      const sequence = createMockSequence('seq-1', [createMockStep(0)]);
      mockSequenceRepo.getById.mockResolvedValue({ success: true, data: sequence });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: [] });

      await service.getEnrollmentFunnel(mockContext, 'seq-1');

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          metadata: expect.objectContaining({ action: 'getEnrollmentFunnel' }),
        })
      );
    });
  });

  describe('getEnrollmentTrends', () => {
    it('should return empty array when no enrollments', async () => {
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: [] });

      const result = await service.getEnrollmentTrends(mockContext, 'seq-1', 'daily');

      expect(result).toHaveLength(0);
    });

    it('should group enrollments by daily bucket', async () => {
      // Use explicit times to avoid timezone issues
      const enrollments = [
        { ...createMockEnrollment('e1', 'seq-1', 'completed'), createdAt: new Date('2025-01-15T12:00:00') },
        { ...createMockEnrollment('e2', 'seq-1', 'active'), createdAt: new Date('2025-01-15T14:00:00') },
        { ...createMockEnrollment('e3', 'seq-1', 'active'), createdAt: new Date('2025-01-16T10:00:00') },
      ];

      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });

      const result = await service.getEnrollmentTrends(mockContext, 'seq-1', 'daily');

      expect(result).toHaveLength(2);
      // First day should have 2 enrollments, second day should have 1
      expect(result[0].enrolled).toBe(2);
      expect(result[1].enrolled).toBe(1);
    });

    it('should group enrollments by weekly bucket', async () => {
      const enrollments = [
        { ...createMockEnrollment('e1', 'seq-1', 'active'), createdAt: new Date('2025-01-06') }, // Week 2
        { ...createMockEnrollment('e2', 'seq-1', 'active'), createdAt: new Date('2025-01-07') }, // Week 2
        { ...createMockEnrollment('e3', 'seq-1', 'active'), createdAt: new Date('2025-01-13') }, // Week 3
      ];

      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });

      const result = await service.getEnrollmentTrends(mockContext, 'seq-1', 'weekly');

      expect(result.length).toBeGreaterThan(0);
    });

    it('should group enrollments by monthly bucket', async () => {
      const enrollments = [
        { ...createMockEnrollment('e1', 'seq-1', 'active'), createdAt: new Date('2025-01-15') },
        { ...createMockEnrollment('e2', 'seq-1', 'active'), createdAt: new Date('2025-01-20') },
        { ...createMockEnrollment('e3', 'seq-1', 'active'), createdAt: new Date('2025-02-05') },
      ];

      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: enrollments });

      const result = await service.getEnrollmentTrends(mockContext, 'seq-1', 'monthly');

      expect(result).toHaveLength(2);
      expect(result[0].date).toBe('2025-01');
      expect(result[0].enrolled).toBe(2);
      expect(result[1].date).toBe('2025-02');
      expect(result[1].enrolled).toBe(1);
    });
  });

  describe('compareSequences', () => {
    it('should return empty array for no sequence IDs', async () => {
      const result = await service.compareSequences(mockContext, []);

      expect(result).toHaveLength(0);
    });

    it('should compare multiple sequences', async () => {
      const sequence1 = createMockSequence('seq-1', [createMockStep(0)]);
      const sequence2 = createMockSequence('seq-2', [createMockStep(0)]);

      mockSequenceRepo.getById.mockImplementation((_ctx, id) => {
        if (id === 'seq-1') return Promise.resolve({ success: true, data: sequence1 });
        if (id === 'seq-2') return Promise.resolve({ success: true, data: sequence2 });
        return Promise.resolve({ success: false });
      });

      mockEnrollmentRepo.getBySequence.mockResolvedValue({
        success: true,
        data: [createMockEnrollment('e1', 'seq-1', 'completed')],
      });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.compareSequences(mockContext, ['seq-1', 'seq-2']);

      expect(result).toHaveLength(2);
      expect(result[0].sequenceId).toBe('seq-1');
      expect(result[1].sequenceId).toBe('seq-2');
    });

    it('should audit log the comparison', async () => {
      mockSequenceRepo.getById.mockResolvedValue({ success: false });

      await service.compareSequences(mockContext, ['seq-1', 'seq-2']);

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          metadata: expect.objectContaining({
            action: 'compareSequences',
            sequenceIds: ['seq-1', 'seq-2'],
          }),
        })
      );
    });
  });

  describe('getOptimalSendTimes', () => {
    it('should return send time analysis', async () => {
      const result = await service.getOptimalSendTimes(mockContext);

      expect(result).toHaveProperty('bestDays');
      expect(result).toHaveProperty('bestHours');
      expect(result).toHaveProperty('recommendation');
      expect(Array.isArray(result.bestDays)).toBe(true);
      expect(Array.isArray(result.bestHours)).toBe(true);
    });

    it('should audit log the analysis', async () => {
      await service.getOptimalSendTimes(mockContext, 'seq-1');

      expect(mockAuditService.logAction).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          action: 'read',
          entityType: 'report',
          metadata: expect.objectContaining({
            action: 'getOptimalSendTimes',
            sequenceId: 'seq-1',
          }),
        })
      );
    });
  });

  describe('getDashboardSummary', () => {
    it('should return summary with all fields', async () => {
      mockSequenceRepo.list.mockResolvedValue({
        success: true,
        data: [createMockSequence('seq-1', [createMockStep(0)])],
      });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({
        success: true,
        data: [
          createMockEnrollment('e1', 'seq-1', 'active', { emailsSent: 5, repliesReceived: 1 }),
        ],
      });

      const result = await service.getDashboardSummary(mockContext);

      expect(result).toHaveProperty('totalSequences');
      expect(result).toHaveProperty('activeSequences');
      expect(result).toHaveProperty('totalEnrollments');
      expect(result).toHaveProperty('activeEnrollments');
      expect(result).toHaveProperty('emailsSentLast30Days');
      expect(result).toHaveProperty('overallReplyRate');
      expect(result.totalSequences).toBe(1);
      expect(result.activeSequences).toBe(1);
      expect(result.totalEnrollments).toBe(1);
      expect(result.activeEnrollments).toBe(1);
    });

    it('should handle empty sequences list', async () => {
      mockSequenceRepo.list.mockResolvedValue({ success: true, data: [] });

      const result = await service.getDashboardSummary(mockContext);

      expect(result.totalSequences).toBe(0);
      expect(result.activeSequences).toBe(0);
      expect(result.totalEnrollments).toBe(0);
    });
  });

  describe('getTopPerformers', () => {
    it('should return empty array when no active sequences', async () => {
      mockSequenceRepo.list.mockResolvedValue({ success: true, data: [] });

      const result = await service.getTopPerformers(mockContext, 5, 'replyRate');

      expect(result).toHaveLength(0);
    });

    it('should sort by reply rate by default', async () => {
      const sequences = [
        createMockSequence('seq-1', [createMockStep(0)]),
        createMockSequence('seq-2', [createMockStep(0)]),
      ];

      mockSequenceRepo.list.mockResolvedValue({ success: true, data: sequences });
      mockSequenceRepo.getById.mockImplementation((_ctx, id) => {
        return Promise.resolve({ success: true, data: sequences.find((s) => s.id === id) });
      });

      // Different reply rates
      mockEnrollmentRepo.getBySequence.mockImplementation((_ctx, seqId) => {
        if (seqId === 'seq-1') {
          return Promise.resolve({
            success: true,
            data: [createMockEnrollment('e1', 'seq-1', 'active', { emailsSent: 10, repliesReceived: 5 })],
          });
        }
        return Promise.resolve({
          success: true,
          data: [createMockEnrollment('e2', 'seq-2', 'active', { emailsSent: 10, repliesReceived: 1 })],
        });
      });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.getTopPerformers(mockContext, 2, 'replyRate');

      expect(result).toHaveLength(2);
      // Higher reply rate should be first
      expect(result[0].replyRate).toBeGreaterThanOrEqual(result[1].replyRate);
    });

    it('should respect limit parameter', async () => {
      const sequences = Array.from({ length: 10 }, (_, i) =>
        createMockSequence(`seq-${i}`, [createMockStep(0)])
      );

      mockSequenceRepo.list.mockResolvedValue({ success: true, data: sequences });
      mockSequenceRepo.getById.mockImplementation((_ctx, id) => {
        return Promise.resolve({ success: true, data: sequences.find((s) => s.id === id) });
      });
      mockEnrollmentRepo.getBySequence.mockResolvedValue({ success: true, data: [] });
      mockExecutionRepo.getByEnrollment.mockResolvedValue({ success: true, data: [] });

      const result = await service.getTopPerformers(mockContext, 3);

      expect(result.length).toBeLessThanOrEqual(3);
    });
  });
});
