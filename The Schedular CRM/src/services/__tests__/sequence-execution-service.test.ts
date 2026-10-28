/**
 * Sequence Execution Service Tests
 *
 * Tests the core execution engine for sequences
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type {
  Sequence,
  SequenceEnrollment,
  SequenceExecution,
} from '../../types/sequences';
import { DEFAULT_SEQUENCE_SETTINGS, DEFAULT_SEQUENCE_STATS, DEFAULT_EXIT_CRITERIA } from '../../types/sequences';

// Create mock functions outside the mock factory
const mockSequenceRepoGetById = vi.fn();
const mockSequenceRepoIncrementStat = vi.fn();
const mockEnrollmentRepoGetById = vi.fn();
const mockEnrollmentRepoUpdateProgress = vi.fn();
const mockEnrollmentRepoComplete = vi.fn();
const mockEnrollmentRepoPause = vi.fn();
const mockEnrollmentRepoIncrementStat = vi.fn();
const mockExecutionRepoGetById = vi.fn();
const mockExecutionRepoGetPending = vi.fn();
const mockExecutionRepoCreateWithIdempotency = vi.fn();
const mockExecutionRepoMarkExecuting = vi.fn();
const mockExecutionRepoMarkCompleted = vi.fn();
const mockExecutionRepoMarkFailed = vi.fn();
const mockExecutionRepoMarkSkipped = vi.fn();
const mockExecutionRepoReschedule = vi.fn();
const mockAuditLogAction = vi.fn();
const mockRateLimitCheckLimit = vi.fn().mockResolvedValue({ allowed: true, remaining: 100, resetAt: new Date() });
const mockRateLimitRecordAction = vi.fn();

// Mock the repositories
vi.mock('../../data/repositories/sequence-repository', () => ({
  getSequenceRepository: () => ({
    getById: mockSequenceRepoGetById,
    incrementStat: mockSequenceRepoIncrementStat,
  }),
}));

vi.mock('../../data/repositories/sequence-enrollment-repository', () => ({
  getSequenceEnrollmentRepository: () => ({
    getById: mockEnrollmentRepoGetById,
    updateProgress: mockEnrollmentRepoUpdateProgress,
    complete: mockEnrollmentRepoComplete,
    pause: mockEnrollmentRepoPause,
    incrementStat: mockEnrollmentRepoIncrementStat,
  }),
}));

vi.mock('../../data/repositories/sequence-execution-repository', () => ({
  getSequenceExecutionRepository: () => ({
    getById: mockExecutionRepoGetById,
    getPending: mockExecutionRepoGetPending,
    createWithIdempotency: mockExecutionRepoCreateWithIdempotency,
    markExecuting: mockExecutionRepoMarkExecuting,
    markCompleted: mockExecutionRepoMarkCompleted,
    markFailed: mockExecutionRepoMarkFailed,
    markSkipped: mockExecutionRepoMarkSkipped,
    reschedule: mockExecutionRepoReschedule,
  }),
}));

vi.mock('../AuditLogService', () => ({
  getAuditLogService: () => ({
    logAction: mockAuditLogAction,
  }),
}));

vi.mock('../RateLimitService', () => ({
  getRateLimitService: () => ({
    checkLimit: mockRateLimitCheckLimit,
    recordAction: mockRateLimitRecordAction,
  }),
}));

// Import after mocks
import { SequenceExecutionService } from '../sequence-execution-service';

describe('SequenceExecutionService', () => {
  let service: SequenceExecutionService;
  let mockContext: SecurityContext;

  const createMockSequence = (overrides?: Partial<Sequence>): Sequence => ({
    id: 'seq-1',
    name: 'Test Sequence',
    status: 'active',
    steps: [
      { id: 'step-1', order: 0, type: 'email', delayDays: 0, isActive: true },
      { id: 'step-2', order: 1, type: 'wait', delayDays: 2, isActive: true },
      { id: 'step-3', order: 2, type: 'email', delayDays: 1, isActive: true },
    ],
    settings: DEFAULT_SEQUENCE_SETTINGS,
    exitCriteria: DEFAULT_EXIT_CRITERIA,
    stats: DEFAULT_SEQUENCE_STATS,
    ownerId: 'user-1',
    ownerName: 'Test User',
    teamIds: [],
    visibility: 'team',
    createdAt: new Date(),
    ...overrides,
  });

  const createMockEnrollment = (overrides?: Partial<SequenceEnrollment>): SequenceEnrollment => ({
    id: 'enroll-1',
    sequenceId: 'seq-1',
    sequenceName: 'Test Sequence',
    entityType: 'lead',
    entityId: 'lead-1',
    entityName: 'John Doe',
    entityEmail: 'john@example.com',
    status: 'active',
    currentStepIndex: 0,
    stepsCompleted: 0,
    totalSteps: 3,
    emailsSent: 0,
    emailsOpened: 0,
    emailsClicked: 0,
    tasksCreated: 0,
    repliesReceived: 0,
    enrolledById: 'user-1',
    enrolledByName: 'Test User',
    ownerId: 'user-1',
    ownerName: 'Test User',
    teamIds: [],
    visibility: 'team',
    createdAt: new Date(),
    ...overrides,
  });

  const createMockExecution = (overrides?: Partial<SequenceExecution>): SequenceExecution => ({
    id: 'exec-1',
    enrollmentId: 'enroll-1',
    sequenceId: 'seq-1',
    stepId: 'step-1',
    stepIndex: 0,
    stepType: 'email',
    status: 'scheduled',
    scheduledAt: new Date(),
    idempotencyKey: 'enroll-1:step-1',
    createdAt: new Date(),
    ...overrides,
  });

  beforeEach(() => {
    vi.clearAllMocks();
    service = new SequenceExecutionService();
    mockContext = {
      businessId: 'business-1',
      userId: 'user-1',
      userName: 'Test User',
      userRole: 'admin',
    };
  });

  describe('processScheduledSteps', () => {
    it('should return empty result when no pending executions', async () => {
      mockExecutionRepoGetPending.mockResolvedValue({
        success: true,
        data: [],
      });

      const result = await service.processScheduledSteps(mockContext);

      expect(result.processed).toBe(0);
      expect(result.succeeded).toBe(0);
      expect(result.failed).toBe(0);
    });

    it('should process pending executions', async () => {
      const mockExecution = createMockExecution();

      mockExecutionRepoGetPending.mockResolvedValue({
        success: true,
        data: [mockExecution],
      });

      mockExecutionRepoGetById.mockResolvedValue({
        success: true,
        data: mockExecution,
      });

      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment(),
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence(),
      });

      const result = await service.processScheduledSteps(mockContext);

      expect(result.processed).toBe(1);
    });
  });

  describe('scheduleNextStep', () => {
    it('should not schedule if enrollment is not active', async () => {
      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment({ status: 'paused' }),
      });

      await service.scheduleNextStep(mockContext, 'enroll-1');

      expect(mockExecutionRepoCreateWithIdempotency).not.toHaveBeenCalled();
    });

    it('should complete enrollment if no more steps', async () => {
      const enrollment = createMockEnrollment({
        currentStepIndex: 2, // Last step
        totalSteps: 3,
      });

      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: enrollment,
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence(),
      });

      await service.scheduleNextStep(mockContext, 'enroll-1');

      expect(mockEnrollmentRepoComplete).toHaveBeenCalled();
    });

    it('should pause enrollment if sequence is not active', async () => {
      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment(),
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence({ status: 'paused' }),
      });

      await service.scheduleNextStep(mockContext, 'enroll-1');

      expect(mockEnrollmentRepoPause).toHaveBeenCalled();
    });
  });

  describe('executeStep', () => {
    it('should skip if execution not found', async () => {
      mockExecutionRepoGetById.mockResolvedValue({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Not found' },
      });

      const result = await service.executeStep(mockContext, 'exec-1');

      expect(result.success).toBe(false);
      expect(result.errorCode).toBe('EXECUTION_NOT_FOUND');
    });

    it('should return success for already completed execution', async () => {
      const completedExecution = createMockExecution({
        status: 'completed',
        result: { success: true },
      });

      mockExecutionRepoGetById.mockResolvedValue({
        success: true,
        data: completedExecution,
      });

      const result = await service.executeStep(mockContext, 'exec-1');

      expect(result.success).toBe(true);
    });

    it('should skip if enrollment is not active', async () => {
      mockExecutionRepoGetById.mockResolvedValue({
        success: true,
        data: createMockExecution(),
      });

      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment({ status: 'paused' }),
      });

      await service.executeStep(mockContext, 'exec-1');

      expect(mockExecutionRepoMarkSkipped).toHaveBeenCalled();
    });

    it('should skip if sequence is not active', async () => {
      mockExecutionRepoGetById.mockResolvedValue({
        success: true,
        data: createMockExecution(),
      });

      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment(),
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence({ status: 'archived' }),
      });

      await service.executeStep(mockContext, 'exec-1');

      expect(mockExecutionRepoMarkSkipped).toHaveBeenCalled();
      expect(mockEnrollmentRepoPause).toHaveBeenCalled();
    });
  });

  describe('checkExitCriteria', () => {
    it('should return shouldExit false for no criteria', async () => {
      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment(),
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence({ exitCriteria: undefined }),
      });

      const result = await service.checkExitCriteria(mockContext, 'enroll-1');

      expect(result.shouldExit).toBe(false);
    });

    it('should return shouldExit true if reply received and onReply enabled', async () => {
      mockEnrollmentRepoGetById.mockResolvedValue({
        success: true,
        data: createMockEnrollment({ repliesReceived: 1 }),
      });

      mockSequenceRepoGetById.mockResolvedValue({
        success: true,
        data: createMockSequence({
          exitCriteria: { ...DEFAULT_EXIT_CRITERIA, onReply: true },
        }),
      });

      const result = await service.checkExitCriteria(mockContext, 'enroll-1');

      expect(result.shouldExit).toBe(true);
      expect(result.reason).toBe('replied');
    });
  });
});

describe('Retry Policy', () => {
  it('should use custom retry policy when provided', () => {
    const customPolicy = {
      maxAttempts: 5,
      initialDelayMs: 30000,
    };

    const service = new SequenceExecutionService(customPolicy);
    expect(service).toBeDefined();
  });
});
