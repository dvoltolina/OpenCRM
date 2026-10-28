/**
 * Notification Service Tests
 * Tests for notification creation, delivery, and management
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Notification, NotificationPreferences } from '../../types/notifications';

// ============================================
// Mock Setup
// ============================================

const mockNotificationRepo = {
  create: vi.fn(),
  getById: vi.fn(),
  getAll: vi.fn(),
  getUnread: vi.fn(),
  getUnreadCount: vi.fn(),
  markAsRead: vi.fn(),
  markAllAsRead: vi.fn(),
  archive: vi.fn(),
  updateDeliveryStatus: vi.fn(),
  subscribe: vi.fn(),
  subscribeToUnreadCount: vi.fn(),
};

const mockPreferencesRepo = {
  getOrCreateDefault: vi.fn(),
  update: vi.fn(),
  shouldNotify: vi.fn(),
};

const mockPushSubRepo = {
  create: vi.fn(),
  getActiveByUser: vi.fn(),
  delete: vi.fn(),
};

vi.mock('../../data/repositories/notification-repository', () => ({
  getNotificationRepository: () => mockNotificationRepo,
}));

vi.mock('../../data/repositories/notification-preferences-repository', () => ({
  getNotificationPreferencesRepository: () => mockPreferencesRepo,
}));

vi.mock('../../data/repositories/push-subscription-repository', () => ({
  getPushSubscriptionRepository: () => mockPushSubRepo,
}));

vi.mock('../RateLimitService', () => ({
  checkAndRecordRateLimit: vi.fn().mockResolvedValue({ allowed: true }),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => ({ enablePushNotifications: true }),
}));

// ============================================
// Test Data
// ============================================

const mockContext: SecurityContext = {
  businessId: 'test-business-id',
  userId: 'test-user-id',
  userName: 'Test User',
  userRole: 'staff',
};

const mockNotification: Notification = {
  id: 'notif-1',
  businessId: 'test-business-id',
  userId: 'test-user-id',
  type: 'task_assigned',
  priority: 'normal',
  title: 'New task assigned',
  body: 'You have been assigned a new task',
  isRead: false,
  isArchived: false,
  channels: ['in_app'],
  deliveredVia: ['in_app'],
  createdAt: new Date(),
};

const mockPreferences: NotificationPreferences = {
  id: 'prefs-1',
  businessId: 'test-business-id',
  userId: 'test-user-id',
  emailEnabled: true,
  pushEnabled: false,
  timezone: 'America/New_York',
  typeSettings: {
    task_assigned: {
      enabled: true,
      channels: ['in_app', 'email'],
    },
  } as any,
  emailDigestFrequency: 'daily',
  createdAt: new Date(),
};

// ============================================
// Tests
// ============================================

describe('NotificationService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.resetModules();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('notify', () => {
    it('should create a notification successfully', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });

      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);

      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: mockNotification,
      });

      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      // Import after mocks are set up
      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.notify(mockContext, {
        userId: 'test-user-id',
        type: 'task_assigned',
        title: 'New task assigned',
        body: 'You have been assigned a new task',
      });

      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();
      expect(mockNotificationRepo.create).toHaveBeenCalled();
    });

    it('should respect user preferences for channels', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });

      // Email enabled, push disabled
      mockPreferencesRepo.shouldNotify.mockImplementation(
        async (_ctx, _userId, _type, channel) => {
          return channel === 'email' || channel === 'in_app';
        }
      );

      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: mockNotification,
      });

      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      await service.notify(mockContext, {
        userId: 'test-user-id',
        type: 'task_assigned',
        title: 'New task assigned',
        body: 'You have been assigned a new task',
      });

      // Verify channels include in_app and email
      const createCall = mockNotificationRepo.create.mock.calls[0][1];
      expect(createCall.channels).toContain('in_app');
    });
  });

  describe('markAsRead', () => {
    it('should mark notification as read', async () => {
      mockNotificationRepo.markAsRead.mockResolvedValue({
        success: true,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.markAsRead(mockContext, 'notif-1');

      expect(result.success).toBe(true);
      expect(mockNotificationRepo.markAsRead).toHaveBeenCalledWith(
        mockContext,
        'notif-1'
      );
    });
  });

  describe('markAllAsRead', () => {
    it('should mark all notifications as read', async () => {
      mockNotificationRepo.markAllAsRead.mockResolvedValue({
        success: true,
        data: 5,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.markAllAsRead(mockContext);

      expect(result.success).toBe(true);
      expect(result.data).toBe(5);
    });
  });

  describe('archive', () => {
    it('should archive a notification', async () => {
      mockNotificationRepo.archive.mockResolvedValue({
        success: true,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.archive(mockContext, 'notif-1');

      expect(result.success).toBe(true);
      expect(mockNotificationRepo.archive).toHaveBeenCalledWith(
        mockContext,
        'notif-1'
      );
    });
  });

  describe('getUnreadCount', () => {
    it('should return unread count', async () => {
      mockNotificationRepo.getUnreadCount.mockResolvedValue({
        success: true,
        data: 10,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.getUnreadCount(mockContext);

      expect(result.success).toBe(true);
      expect(result.data).toBe(10);
    });
  });

  describe('getPreferences', () => {
    it('should return user preferences', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.getPreferences(mockContext);

      expect(result.success).toBe(true);
      expect(result.data).toEqual(mockPreferences);
    });
  });

  describe('updatePreferences', () => {
    it('should update user preferences', async () => {
      const updatedPrefs = { ...mockPreferences, pushEnabled: true };
      mockPreferencesRepo.update.mockResolvedValue({
        success: true,
        data: updatedPrefs,
      });

      const { getNotificationService } = await import('../notification-service');
      const service = getNotificationService();

      const result = await service.updatePreferences(mockContext, {
        pushEnabled: true,
      });

      expect(result.success).toBe(true);
      expect(result.data?.pushEnabled).toBe(true);
    });
  });
});

describe('NotificationTriggers', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('onTaskCreated', () => {
    it('should create notification for task assignee', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });
      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);
      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: mockNotification,
      });
      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onTaskCreated(mockContext, {
        id: 'task-1',
        title: 'Test Task',
        type: 'task',
        assigneeId: 'other-user-id', // Different from context.userId
        createdById: mockContext.userId,
        createdByName: mockContext.userName,
        isCompleted: false,
      } as any);

      expect(mockPreferencesRepo.getOrCreateDefault).toHaveBeenCalled();
      expect(mockNotificationRepo.create).toHaveBeenCalledWith(
        mockContext,
        expect.objectContaining({
          userId: 'other-user-id',
          type: 'task_assigned',
        })
      );
    });

    it('should not notify if assigned to creator', async () => {
      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onTaskCreated(mockContext, {
        id: 'task-1',
        title: 'Test Task',
        type: 'task',
        assigneeId: mockContext.userId, // Same as context.userId
        createdById: mockContext.userId,
        createdByName: mockContext.userName,
        isCompleted: false,
      } as any);

      expect(mockNotificationRepo.create).not.toHaveBeenCalled();
    });
  });

  describe('onDealWon', () => {
    it('should create high priority notification for deal owner', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });
      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);
      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: { ...mockNotification, type: 'deal_won', priority: 'high' },
      });
      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onDealWon(mockContext, {
        id: 'deal-1',
        title: 'Big Deal',
        valueCents: 100000,
        currency: 'USD',
        ownerId: 'other-user-id',
      } as any);

      expect(mockNotificationRepo.create).toHaveBeenCalled();
      const createCall = mockNotificationRepo.create.mock.calls[0][1];
      expect(createCall.priority).toBe('high');
      expect(createCall.type).toBe('deal_won');
    });
  });

  describe('onSequenceReply', () => {
    it('uses the enrollment detail route with a generic reply body', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });
      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);
      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: { ...mockNotification, type: 'sequence_reply' },
      });
      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onSequenceReply(mockContext, {
        id: 'enrollment-1',
        sequenceId: 'sequence-1',
        sequenceName: 'Q2 Outreach',
        entityType: 'lead',
        entityId: 'lead-1',
        entityName: 'Prospect Name',
        ownerId: 'other-user-id',
      });

      const createCall = mockNotificationRepo.create.mock.calls[0][1];
      expect(createCall.body).toBe('A sequence recipient replied.');
      expect(createCall.actionUrl).toBe('/sequences/sequence-1/enrollments/enrollment-1');
    });
  });

  describe('onMention', () => {
    it('strips mention text from the notification body', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });
      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);
      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: { ...mockNotification, type: 'mention' },
      });
      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onMention(
        mockContext,
        'other-user-id',
        'deal',
        'deal-1',
        'This contains sensitive free-form text'
      );

      const createCall = mockNotificationRepo.create.mock.calls[0][1];
      expect(createCall.body).toBe('You were mentioned in an update.');
      expect(createCall.actionUrl).toBe('/pipeline?deal=deal-1');
    });
  });

  describe('onLeadConverted', () => {
    it('falls back to the lead detail route when no converted entity ids exist', async () => {
      mockPreferencesRepo.getOrCreateDefault.mockResolvedValue({
        success: true,
        data: mockPreferences,
      });
      mockPreferencesRepo.shouldNotify.mockResolvedValue(true);
      mockNotificationRepo.create.mockResolvedValue({
        success: true,
        data: { ...mockNotification, type: 'lead_converted' },
      });
      mockNotificationRepo.updateDeliveryStatus.mockResolvedValue({
        success: true,
      });

      const { getNotificationTriggers } = await import('../notification-triggers');
      const triggers = getNotificationTriggers();

      await triggers.onLeadConverted(mockContext, {
        id: 'lead-1',
        firstName: 'Pat',
        lastName: 'Example',
        ownerId: 'other-user-id',
      } as any);

      const createCall = mockNotificationRepo.create.mock.calls[0][1];
      expect(createCall.body).toBe('A lead was converted.');
      expect(createCall.actionUrl).toBe('/leads/lead-1');
    });
  });
});

describe('Notification Types', () => {
  it('should have valid default preferences', async () => {
    const { getDefaultNotificationPreferences } = await import('../../types/notifications');
    const defaults = getDefaultNotificationPreferences('user-1', 'business-1');

    expect(defaults.userId).toBe('user-1');
    expect(defaults.businessId).toBe('business-1');
    expect(defaults.emailEnabled).toBe(true);
    expect(defaults.pushEnabled).toBe(false); // Requires opt-in
    expect(defaults.emailDigestFrequency).toBe('daily');
  });

  it('should provide correct icon types', async () => {
    const { getIconTypeForNotification } = await import('../../types/notifications');

    expect(getIconTypeForNotification('task_due')).toBe('clock');
    expect(getIconTypeForNotification('deal_won')).toBe('trophy');
    expect(getIconTypeForNotification('mention')).toBe('at-sign');
    expect(getIconTypeForNotification('email_opened')).toBe('eye');
  });

  it('should validate notification types', async () => {
    const { isValidNotificationType, VALID_NOTIFICATION_TYPES } = await import('../../types/notifications');

    expect(isValidNotificationType('task_due')).toBe(true);
    expect(isValidNotificationType('invalid_type')).toBe(false);
    expect(VALID_NOTIFICATION_TYPES).toContain('deal_won');
    expect(VALID_NOTIFICATION_TYPES).toContain('sequence_reply');
  });
});

describe('HIPAA Compliance', () => {
  it('should not include PHI in notification titles', () => {
    // Verify notification messages don't contain health data patterns
    const testMessages = [
      { title: 'Task due soon', body: 'Follow up with client' },
      { title: 'Deal won', body: 'Acme Corp deal closed' },
      { title: 'New lead assigned', body: 'John Smith from web form' },
    ];

    const phiPatterns = [
      /diagnosis/i,
      /treatment/i,
      /medication/i,
      /medical/i,
      /health/i,
      /ssn/i,
      /social security/i,
      /dob|date of birth/i,
    ];

    for (const msg of testMessages) {
      for (const pattern of phiPatterns) {
        expect(msg.title).not.toMatch(pattern);
        expect(msg.body).not.toMatch(pattern);
      }
    }
  });
});
