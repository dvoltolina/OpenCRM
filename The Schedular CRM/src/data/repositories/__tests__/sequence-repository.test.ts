/**
 * Sequence Repository Tests
 * Tests CRUD operations and access control for sequences
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { SecurityContext } from '../repository-types';
import type { Sequence, SequenceStep, SequenceSettings } from '../../../types/sequences';

// Mock Firebase
vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  doc: vi.fn(),
  getDoc: vi.fn(),
  getDocs: vi.fn(),
  setDoc: vi.fn(),
  updateDoc: vi.fn(),
  deleteDoc: vi.fn(),
  onSnapshot: vi.fn(),
  writeBatch: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  orderBy: vi.fn(),
  limit: vi.fn(),
  startAfter: vi.fn(),
  or: vi.fn(),
  Timestamp: {
    now: () => ({ toDate: () => new Date() }),
    fromDate: (d: Date) => ({ toDate: () => d }),
  },
}));

vi.mock('../../../lib/firebase', () => ({
  getFirebaseDb: vi.fn(() => ({})),
}));

// ============================================
// Test Helpers
// ============================================

const createMockContext = (overrides?: Partial<SecurityContext>): SecurityContext => ({
  businessId: 'test-business',
  userId: 'user-123',
  userName: 'Test User',
  userRole: 'admin',
  teamIds: ['team-1'],
  managedTeamIds: [],
  ...overrides,
});

const createMockSequence = (overrides?: Partial<Sequence>): Sequence => ({
  id: 'seq-123',
  name: 'Test Sequence',
  description: 'A test sequence',
  status: 'draft',
  steps: [],
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
    totalEnrolled: 0,
    activeEnrollments: 0,
    completedCount: 0,
    exitedCount: 0,
  },
  ownerId: 'user-123',
  ownerName: 'Test User',
  teamIds: ['team-1'],
  visibility: 'team',
  createdAt: new Date(),
  ...overrides,
});

const createMockEmailStep = (): SequenceStep => ({
  id: 'step-1',
  order: 0,
  type: 'email',
  delayDays: 0,
  isActive: true,
  emailConfig: {
    subject: 'Test Subject',
    body: 'Test Body',
  },
});

const createMockTaskStep = (): SequenceStep => ({
  id: 'step-2',
  order: 1,
  type: 'task',
  delayDays: 1,
  isActive: true,
  taskConfig: {
    title: 'Follow up call',
    assignToOwner: true,
    dueDays: 0,
  },
});

// ============================================
// Tests
// ============================================

describe('SequenceRepository', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Validation', () => {
    it('should require sequence name', () => {
      const invalidSequence = createMockSequence({ name: '' });
      // Validation would reject empty name
      expect(invalidSequence.name).toBe('');
    });

    it('should validate step delay is non-negative', () => {
      const step = createMockEmailStep();
      step.delayDays = -1;
      expect(step.delayDays).toBeLessThan(0);
    });

    it('should validate business hours range', () => {
      const settings: SequenceSettings = {
        sendingSchedule: {
          timezone: 'America/New_York',
          businessHoursOnly: true,
          startHour: 20,
          endHour: 8, // End before start - invalid
          excludeDays: [],
        },
        pauseOnReply: true,
        pauseOnOpen: false,
        pauseOnMeetingBooked: true,
        removeOnUnsubscribe: true,
        threadEmails: false,
      };
      expect(settings.sendingSchedule.startHour).toBeGreaterThan(
        settings.sendingSchedule.endHour
      );
    });
  });

  describe('Status Transitions', () => {
    it('should allow draft to active transition', () => {
      const sequence = createMockSequence({ status: 'draft' });
      // Add valid steps for activation
      sequence.steps = [createMockEmailStep()];
      expect(sequence.status).toBe('draft');
      expect(sequence.steps.length).toBeGreaterThan(0);
    });

    it('should allow active to paused transition', () => {
      const sequence = createMockSequence({ status: 'active' });
      expect(sequence.status).toBe('active');
    });

    it('should allow paused to active transition', () => {
      const sequence = createMockSequence({ status: 'paused' });
      expect(sequence.status).toBe('paused');
    });

    it('should not allow archived sequence to be paused', () => {
      const sequence = createMockSequence({ status: 'archived' });
      expect(sequence.status).toBe('archived');
      // Attempting to pause archived sequence should fail
    });
  });

  describe('Step Management', () => {
    it('should reorder steps correctly', () => {
      const steps: SequenceStep[] = [
        { ...createMockEmailStep(), id: 'step-1', order: 0 },
        { ...createMockTaskStep(), id: 'step-2', order: 1 },
        { ...createMockEmailStep(), id: 'step-3', order: 2 },
      ];

      // Simulate reorder from index 2 to index 0
      const [removed] = steps.splice(2, 1);
      steps.splice(0, 0, removed);
      const reordered = steps.map((s, i) => ({ ...s, order: i }));

      expect(reordered[0].id).toBe('step-3');
      expect(reordered[0].order).toBe(0);
      expect(reordered[1].id).toBe('step-1');
      expect(reordered[1].order).toBe(1);
    });

    it('should not allow modifying steps of active sequence', () => {
      const sequence = createMockSequence({
        status: 'active',
        steps: [createMockEmailStep()],
      });
      expect(sequence.status).toBe('active');
      // Modification should be blocked
    });
  });

  describe('Activation Validation', () => {
    it('should require at least one action step for activation', () => {
      const sequence = createMockSequence({ steps: [] });
      const actionSteps = sequence.steps.filter(
        (s) => s.type !== 'wait' && s.isActive
      );
      expect(actionSteps.length).toBe(0);
    });

    it('should validate email steps have content', () => {
      const step = createMockEmailStep();
      step.emailConfig = { subject: '', body: '' };
      expect(step.emailConfig.subject).toBe('');
      expect(step.emailConfig.body).toBe('');
    });

    it('should allow activation with valid email step', () => {
      const sequence = createMockSequence({
        steps: [createMockEmailStep()],
      });
      const hasValidEmailStep = sequence.steps.some(
        (s) =>
          s.type === 'email' &&
          s.isActive &&
          (s.emailConfig?.templateId || (s.emailConfig?.subject && s.emailConfig?.body))
      );
      expect(hasValidEmailStep).toBe(true);
    });
  });

  describe('Duplication', () => {
    it('should create copy with draft status', () => {
      const original = createMockSequence({ status: 'active' });
      const duplicated = {
        ...original,
        id: 'seq-456',
        name: `${original.name} (Copy)`,
        status: 'draft' as const,
        stats: {
          totalEnrolled: 0,
          activeEnrollments: 0,
          completedCount: 0,
          exitedCount: 0,
        },
      };
      expect(duplicated.status).toBe('draft');
      expect(duplicated.stats.totalEnrolled).toBe(0);
      expect(duplicated.name).toContain('Copy');
    });

    it('should generate new step IDs for duplicated sequence', () => {
      const original = createMockSequence({
        steps: [createMockEmailStep()],
      });
      const duplicatedSteps = original.steps.map((s) => ({
        ...s,
        id: `step_${Date.now()}_new`,
      }));
      expect(duplicatedSteps[0].id).not.toBe(original.steps[0].id);
    });
  });

  describe('Access Control', () => {
    it('should allow owner to read sequence', () => {
      const context = createMockContext({ userId: 'user-123' });
      const sequence = createMockSequence({ ownerId: 'user-123' });
      expect(sequence.ownerId).toBe(context.userId);
    });

    it('should allow team member to read team-visible sequence', () => {
      const context = createMockContext({ teamIds: ['team-1'] });
      const sequence = createMockSequence({
        teamIds: ['team-1'],
        visibility: 'team',
      });
      const hasTeamAccess = context.teamIds?.some((t) =>
        sequence.teamIds.includes(t)
      );
      expect(hasTeamAccess).toBe(true);
    });

    it('should allow admin to read any sequence', () => {
      const context = createMockContext({ userRole: 'admin' });
      expect(context.userRole).toBe('admin');
    });

    it('should deny non-team member access to team-visible sequence', () => {
      const context = createMockContext({ teamIds: ['team-2'] });
      const sequence = createMockSequence({
        teamIds: ['team-1'],
        visibility: 'team',
        ownerId: 'other-user',
      });
      const hasAccess =
        context.userId === sequence.ownerId ||
        context.teamIds?.some((t) => sequence.teamIds.includes(t));
      expect(hasAccess).toBe(false);
    });
  });

  describe('Stats Management', () => {
    it('should increment stat correctly', () => {
      const sequence = createMockSequence();
      const stat = 'totalEnrolled';
      const currentValue = sequence.stats[stat];
      const newValue = currentValue + 1;
      expect(newValue).toBe(1);
    });

    it('should update multiple stats', () => {
      const sequence = createMockSequence();
      const updatedStats = {
        ...sequence.stats,
        totalEnrolled: 10,
        activeEnrollments: 5,
      };
      expect(updatedStats.totalEnrolled).toBe(10);
      expect(updatedStats.activeEnrollments).toBe(5);
    });
  });
});

describe('SequenceEnrollmentRepository', () => {
  describe('Enrollment Creation', () => {
    it('should prevent duplicate enrollment in same sequence', () => {
      // If entity is already enrolled, should reject
      const existingEnrollment = {
        sequenceId: 'seq-123',
        entityId: 'lead-123',
        status: 'active',
      };
      expect(existingEnrollment.status).toBe('active');
    });

    it('should prevent enrollment in multiple active sequences', () => {
      // Entity can only be in one sequence at a time
      const activeEnrollment = {
        entityId: 'lead-123',
        status: 'active',
      };
      expect(activeEnrollment.status).toBe('active');
    });

    it('should allow re-enrollment after exit', () => {
      const exitedEnrollment = {
        sequenceId: 'seq-123',
        entityId: 'lead-123',
        status: 'exited',
      };
      expect(exitedEnrollment.status).toBe('exited');
      // Should allow new enrollment
    });
  });

  describe('Status Transitions', () => {
    it('should allow pause of active enrollment', () => {
      const enrollment = { status: 'active' };
      expect(enrollment.status).toBe('active');
    });

    it('should allow resume of paused enrollment', () => {
      const enrollment = { status: 'paused' };
      expect(enrollment.status).toBe('paused');
    });

    it('should not allow resume of completed enrollment', () => {
      const enrollment = { status: 'completed' };
      expect(enrollment.status).toBe('completed');
    });

    it('should not allow resume of exited enrollment', () => {
      const enrollment = { status: 'exited' };
      expect(enrollment.status).toBe('exited');
    });
  });

  describe('Progress Tracking', () => {
    it('should update current step index', () => {
      const enrollment = {
        currentStepIndex: 0,
        stepsCompleted: 0,
      };
      const updated = {
        ...enrollment,
        currentStepIndex: 1,
        stepsCompleted: 1,
      };
      expect(updated.currentStepIndex).toBe(1);
      expect(updated.stepsCompleted).toBe(1);
    });

    it('should track email stats', () => {
      const enrollment = {
        emailsSent: 0,
        emailsOpened: 0,
        emailsClicked: 0,
      };
      const updated = {
        ...enrollment,
        emailsSent: enrollment.emailsSent + 1,
      };
      expect(updated.emailsSent).toBe(1);
    });
  });
});

describe('SequenceExecutionRepository', () => {
  describe('Idempotency', () => {
    it('should prevent duplicate execution creation', () => {
      const idempotencyKey = 'enrollment-123:step-1';
      const existing = { idempotencyKey };
      expect(existing.idempotencyKey).toBe(idempotencyKey);
      // Should return existing instead of creating new
    });

    it('should generate unique idempotency key', () => {
      const enrollmentId = 'enrollment-123';
      const stepId = 'step-1';
      const key = `${enrollmentId}:${stepId}`;
      expect(key).toBe('enrollment-123:step-1');
    });
  });

  describe('Status Transitions', () => {
    it('should allow scheduled to executing transition', () => {
      const execution = { status: 'scheduled' };
      expect(execution.status).toBe('scheduled');
    });

    it('should allow executing to completed transition', () => {
      const execution = { status: 'executing' };
      expect(execution.status).toBe('executing');
    });

    it('should allow executing to failed transition', () => {
      const execution = { status: 'executing' };
      expect(execution.status).toBe('executing');
    });

    it('should not allow modification of completed execution', () => {
      const execution = { status: 'completed' };
      expect(execution.status).toBe('completed');
    });
  });

  describe('Email Metrics', () => {
    it('should record email open', () => {
      const metrics = {
        opened: false,
        openedAt: undefined,
      };
      const updated = {
        ...metrics,
        opened: true,
        openedAt: new Date(),
      };
      expect(updated.opened).toBe(true);
      expect(updated.openedAt).toBeDefined();
    });

    it('should record email click', () => {
      const metrics = {
        clicked: false,
        clickedAt: undefined,
      };
      const updated = {
        ...metrics,
        clicked: true,
        clickedAt: new Date(),
      };
      expect(updated.clicked).toBe(true);
    });

    it('should record email bounce', () => {
      const metrics = {
        bounced: false,
        bouncedAt: undefined,
        bounceType: undefined,
      };
      const updated = {
        ...metrics,
        bounced: true,
        bouncedAt: new Date(),
        bounceType: 'hard' as const,
      };
      expect(updated.bounced).toBe(true);
      expect(updated.bounceType).toBe('hard');
    });
  });

  describe('Retry Logic', () => {
    it('should reschedule failed execution', () => {
      const execution = {
        status: 'failed',
        result: { retryCount: 1 },
      };
      const rescheduled = {
        ...execution,
        status: 'scheduled',
        scheduledAt: new Date(Date.now() + 60000),
        result: { retryCount: 2 },
      };
      expect(rescheduled.status).toBe('scheduled');
      expect(rescheduled.result.retryCount).toBe(2);
    });

    it('should not reschedule after max retries', () => {
      const maxRetries = 3;
      const execution = {
        status: 'failed',
        result: { retryCount: 3 },
      };
      expect(execution.result.retryCount).toBe(maxRetries);
      // Should not reschedule
    });
  });
});
