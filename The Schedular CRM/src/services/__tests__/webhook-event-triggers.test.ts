/**
 * Webhook Event Triggers Service Tests
 * Tests all event trigger methods and PHI sanitization
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { WebhookEventTriggers } from '../webhook-event-triggers';
import type { SecurityContext } from '../../data/repositories/repository-types';
import type { Lead } from '../../types/leads';
import type { Deal } from '../../types/deals';
import type { Client, SalesActivity } from '../../types/models';
import type { SequenceEnrollment } from '../../types/sequences';
import type { EmailMessage, EmailTrackingEvent } from '../../types/email-integration';

// Mock webhook service
const mockTriggerEvent = vi.fn();
vi.mock('../webhook-endpoint-service', () => ({
  getWebhookEndpointService: vi.fn(() => ({
    triggerEvent: mockTriggerEvent,
  })),
}));

describe('WebhookEventTriggers', () => {
  let service: WebhookEventTriggers;
  let context: SecurityContext;

  beforeEach(() => {
    mockTriggerEvent.mockClear();
    service = new WebhookEventTriggers();
    context = {
      businessId: 'business-123',
      userId: 'user-456',
      userName: 'Test User',
      userRole: 'admin',
    };
  });

  // ============================================
  // Lead Events
  // ============================================

  describe('Lead Events', () => {
    it('should trigger lead.created event', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        companyName: 'Acme Corp',
        title: 'CEO',
        status: 'new',
        source: 'website',
        score: 85,
        assigneeId: 'user-1',
        assigneeName: 'Alice',
        tags: ['hot', 'enterprise'],
        notes: 'Very interested in our product',
        customFields: { industry: 'Tech', budget: 50000 },
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onLeadCreated(context, lead);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'lead.created',
        expect.objectContaining({
          event: 'lead.created',
          timestamp: expect.any(String),
          data: expect.objectContaining({
            id: 'lead-1',
            firstName: '[REDACTED]',
            lastName: '[REDACTED]',
            email: '[REDACTED]',
            phone: '[REDACTED]',
            status: 'new',
            source: 'website',
            hasNotes: true,
            customFieldCount: 2,
          }),
        })
      );

      // Verify sensitive data is removed
      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('businessId');
      expect(payload.data).not.toHaveProperty('notes');
      expect(payload.data).not.toHaveProperty('customFields');
      expect(payload.data.firstName).toBe('[REDACTED]');
    });

    it('should trigger lead.updated event with changes', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        status: 'qualified',
        source: 'referral',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      const changes = [
        { field: 'status', previousValue: 'contacted', newValue: 'qualified' },
        { field: 'score', previousValue: 60, newValue: 85 },
      ];

      await service.onLeadUpdated(context, lead, changes);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'lead.updated',
        expect.objectContaining({
          event: 'lead.updated',
          data: expect.objectContaining({ id: 'lead-1' }),
          changes: ['status', 'score'], // Only field names, not values
        })
      );
    });

    it('should trigger lead.converted event', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        status: 'converted',
        source: 'website',
        tags: [],
        convertedToClientId: 'client-1',
        convertedToDealId: 'deal-1',
        convertedAt: new Date('2025-01-15'),
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onLeadConverted(context, lead, 'client-1', 'deal-1');

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'lead.converted',
        expect.objectContaining({
          event: 'lead.converted',
          data: expect.objectContaining({ id: 'lead-1' }),
          convertedToClientId: 'client-1',
          convertedToDealId: 'deal-1',
        })
      );
    });
  });

  // ============================================
  // Deal Events
  // ============================================

  describe('Deal Events', () => {
    it('should trigger deal.created event', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Acme Corp - Enterprise Deal',
        valueCents: 5000000,
        currency: 'USD',
        probability: 70,
        expectedCloseDate: new Date('2025-03-01'),
        status: 'open',
        clientId: 'client-1',
        clientName: 'John Doe',
        companyId: 'company-1',
        companyName: 'Acme Corp',
        assigneeId: 'user-1',
        assigneeName: 'Alice',
        tags: ['enterprise', 'hot'],
        notes: 'High-value deal, CEO interested',
        customFields: { urgency: 'high' },
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onDealCreated(context, deal);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.created',
        expect.objectContaining({
          event: 'deal.created',
          data: expect.objectContaining({
            id: 'deal-1',
            title: 'Acme Corp - Enterprise Deal',
            valueCents: 5000000,
            clientName: '[REDACTED]',
            companyName: '[REDACTED]',
            hasNotes: true,
            customFieldCount: 1,
          }),
        })
      );
    });

    it('should trigger deal.updated event', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-2',
        title: 'Test Deal',
        valueCents: 3000000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      const changes = [{ field: 'valueCents', previousValue: 2500000, newValue: 3000000 }];

      await service.onDealUpdated(context, deal, changes);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.updated',
        expect.objectContaining({
          event: 'deal.updated',
          changes: ['valueCents'],
        })
      );
    });

    it('should trigger deal.stage_changed event', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-3',
        title: 'Test Deal',
        valueCents: 5000000,
        currency: 'USD',
        probability: 80,
        status: 'open',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onDealStageChanged(context, deal, 'stage-2');

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.stage_changed',
        expect.objectContaining({
          event: 'deal.stage_changed',
          previousStage: 'stage-2',
          newStage: 'stage-3',
        })
      );
    });

    it('should trigger deal.won event when deal is won', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-won',
        title: 'Won Deal',
        valueCents: 5000000,
        currency: 'USD',
        probability: 100,
        status: 'won',
        closedAt: new Date('2025-02-01'),
        wonLostReason: 'Great fit for their needs',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onDealWon(context, deal);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.won',
        expect.objectContaining({
          event: 'deal.won',
          data: expect.objectContaining({
            id: 'deal-1',
            status: 'won',
            hasWonLostReason: true,
          }),
        })
      );

      // Verify wonLostReason is sanitized
      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('wonLostReason');
    });

    it('should trigger deal.lost event', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-lost',
        title: 'Lost Deal',
        valueCents: 3000000,
        currency: 'USD',
        probability: 0,
        status: 'lost',
        closedAt: new Date('2025-02-01'),
        wonLostReason: 'Went with competitor',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onDealLost(context, deal);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.lost',
        expect.objectContaining({
          event: 'deal.lost',
        })
      );
    });

    it('should trigger both stage_changed and won events', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-won',
        title: 'Test Deal',
        valueCents: 5000000,
        currency: 'USD',
        probability: 100,
        status: 'won',
        closedAt: new Date('2025-02-01'),
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onDealStageChanged(context, deal, 'stage-3');

      expect(mockTriggerEvent).toHaveBeenCalledTimes(2);
      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'deal.stage_changed',
        expect.any(Object)
      );
      expect(mockTriggerEvent).toHaveBeenCalledWith(context, 'deal.won', expect.any(Object));
    });
  });

  // ============================================
  // Contact Events
  // ============================================

  describe('Contact Events', () => {
    it('should trigger contact.created event', async () => {
      const contact: Client = {
        id: 'client-1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '+1987654321',
        lifecycle: 'active',
        tags: ['vip'],
        userId: 'auth-user-1',
        companyId: 'company-1',
        companyName: 'Tech Inc',
        title: 'CTO',
        address: {
          street: '123 Main St',
          city: 'San Francisco',
          state: 'CA',
          zipCode: '94105',
        },
        crmNotes: 'Prefers email communication',
        customFields: { tier: 'gold' },
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-01'),
      };

      await service.onContactCreated(context, contact);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'contact.created',
        expect.objectContaining({
          event: 'contact.created',
          data: expect.objectContaining({
            id: 'client-1',
            firstName: '[REDACTED]',
            lastName: '[REDACTED]',
            email: '[REDACTED]',
            phone: '[REDACTED]',
            hasAddress: true,
            hasCrmNotes: true,
            customFieldCount: 1,
            hasUserId: true,
          }),
        })
      );

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('crmNotes');
      expect(payload.data).not.toHaveProperty('address');
      expect(payload.data).not.toHaveProperty('userId');
    });

    it('should trigger contact.updated event', async () => {
      const contact: Client = {
        id: 'client-1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        lifecycle: 'active',
        tags: ['vip', 'enterprise'],
        createdAt: new Date('2025-01-01'),
      };

      const changes = [{ field: 'lifecycle', previousValue: 'prospect', newValue: 'active' }];

      await service.onContactUpdated(context, contact, changes);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'contact.updated',
        expect.objectContaining({
          event: 'contact.updated',
          changes: ['lifecycle'],
        })
      );
    });
  });

  // ============================================
  // Task Events
  // ============================================

  describe('Task Events', () => {
    it('should trigger task.created event', async () => {
      const task: SalesActivity = {
        id: 'task-1',
        type: 'task',
        title: 'Follow up with client',
        description: 'Discuss pricing and timeline',
        dealId: 'deal-1',
        clientId: 'client-1',
        dueDate: new Date('2025-02-01'),
        isCompleted: false,
        assigneeId: 'user-1',
        assigneeName: 'Alice',
        createdById: 'user-2',
        createdByName: 'Bob',
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-15'),
      };

      await service.onTaskCreated(context, task);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'task.created',
        expect.objectContaining({
          event: 'task.created',
          data: expect.objectContaining({
            id: 'task-1',
            type: 'task',
            title: 'Follow up with client',
            hasDescription: true,
          }),
        })
      );

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('description');
    });

    it('should trigger task.completed event', async () => {
      const task: SalesActivity = {
        id: 'task-1',
        type: 'task',
        title: 'Follow up with client',
        isCompleted: true,
        completedAt: new Date('2025-01-20'),
        createdById: 'user-1',
        createdByName: 'Alice',
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-15'),
      };

      await service.onTaskCompleted(context, task);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'task.completed',
        expect.objectContaining({
          event: 'task.completed',
          data: expect.objectContaining({
            id: 'task-1',
            isCompleted: true,
          }),
        })
      );
    });
  });

  // ============================================
  // Email Events
  // ============================================

  describe('Email Events', () => {
    it('should trigger email.sent event', async () => {
      const email: EmailMessage = {
        id: 'email-1',
        businessId: 'business-123',
        accountId: 'account-1',
        providerMessageId: 'provider-msg-123',
        threadId: 'thread-1',
        fromEmail: 'alice@example.com',
        fromName: 'Alice',
        toEmails: ['john@example.com', 'jane@example.com'],
        ccEmails: ['manager@example.com'],
        subject: 'Product Demo',
        bodyText: 'Hi John, I wanted to follow up...',
        bodyHtml: '<p>Hi John...</p>',
        snippet: 'Hi John, I wanted to follow up...',
        direction: 'outbound',
        sentAt: new Date('2025-01-20T10:00:00Z'),
        trackingId: 'track-123',
        opens: 0,
        clicks: 0,
        hasAttachments: false,
        isRead: true,
        isStarred: false,
        createdAt: new Date('2025-01-20T10:00:00Z'),
      };

      await service.onEmailSent(context, email);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'email.sent',
        expect.objectContaining({
          event: 'email.sent',
          data: expect.objectContaining({
            id: 'email-1',
            subject: 'Product Demo',
            fromEmail: '[REDACTED]',
            fromName: '[REDACTED]',
            recipientCount: 2,
            ccCount: 1,
            bccCount: 0,
            hasBody: true,
          }),
        })
      );

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('bodyText');
      expect(payload.data).not.toHaveProperty('bodyHtml');
      expect(payload.data).not.toHaveProperty('toEmails');
    });

    it('should trigger email.opened event', async () => {
      const trackingEvent: EmailTrackingEvent = {
        id: 'event-1',
        businessId: 'business-123',
        messageId: 'email-1',
        trackingId: 'track-123',
        eventType: 'open',
        ipAddress: 'hashed-ip',
        userAgent: 'Mozilla/5.0...',
        occurredAt: new Date('2025-01-20T14:30:00Z'),
        createdAt: new Date('2025-01-20T14:30:00Z'),
      };

      await service.onEmailOpened(context, trackingEvent);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'email.opened',
        expect.objectContaining({
          event: 'email.opened',
          data: {
            messageId: 'email-1',
            trackingId: 'track-123',
            occurredAt: expect.any(String),
          },
        })
      );
    });
  });

  // ============================================
  // Sequence Events
  // ============================================

  describe('Sequence Events', () => {
    it('should trigger sequence.enrolled event', async () => {
      const enrollment: SequenceEnrollment = {
        id: 'enrollment-1',
        sequenceId: 'sequence-1',
        sequenceName: 'Outbound Sales Cadence',
        entityType: 'lead',
        entityId: 'lead-1',
        entityName: 'John Doe',
        entityEmail: 'john@example.com',
        entityPhone: '+1234567890',
        status: 'active',
        currentStepIndex: 0,
        stepsCompleted: 0,
        totalSteps: 5,
        emailsSent: 0,
        emailsOpened: 0,
        emailsClicked: 0,
        tasksCreated: 0,
        repliesReceived: 0,
        enrolledById: 'user-1',
        enrolledByName: 'Alice',
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-20'),
      };

      await service.onSequenceEnrolled(context, enrollment);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'sequence.enrolled',
        expect.objectContaining({
          event: 'sequence.enrolled',
          data: expect.objectContaining({
            id: 'enrollment-1',
            sequenceId: 'sequence-1',
            sequenceName: 'Outbound Sales Cadence',
            entityType: 'lead',
            entityId: 'lead-1',
            hasEntityName: true,
            hasEntityEmail: true,
            hasEntityPhone: true,
            status: 'active',
          }),
        })
      );

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('entityName');
      expect(payload.data).not.toHaveProperty('entityEmail');
      expect(payload.data).not.toHaveProperty('entityPhone');
    });

    it('should trigger sequence.completed event', async () => {
      const enrollment: SequenceEnrollment = {
        id: 'enrollment-1',
        sequenceId: 'sequence-1',
        sequenceName: 'Outbound Sales Cadence',
        entityType: 'lead',
        entityId: 'lead-1',
        entityName: 'John Doe',
        entityEmail: 'john@example.com',
        status: 'completed',
        currentStepIndex: 5,
        stepsCompleted: 5,
        totalSteps: 5,
        emailsSent: 3,
        emailsOpened: 2,
        emailsClicked: 1,
        tasksCreated: 2,
        repliesReceived: 0,
        enrolledById: 'user-1',
        enrolledByName: 'Alice',
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date('2025-01-20'),
        completedAt: new Date('2025-02-05'),
      };

      await service.onSequenceCompleted(context, enrollment);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'sequence.completed',
        expect.objectContaining({
          event: 'sequence.completed',
          data: expect.objectContaining({
            status: 'completed',
            stepsCompleted: 5,
          }),
        })
      );
    });
  });

  // ============================================
  // Form Events
  // ============================================

  describe('Form Events', () => {
    it('should trigger form.submitted event', async () => {
      const submission = {
        formId: 'form-1',
        formName: 'Contact Us',
        submittedAt: new Date('2025-01-20T15:00:00Z'),
        submitterEmail: 'prospect@example.com',
        submitterName: 'New Prospect',
        fields: {
          firstName: 'New',
          lastName: 'Prospect',
          email: 'prospect@example.com',
          phone: '+1555555555',
          company: 'Prospect Corp',
          message: 'Interested in your services',
        },
      };

      await service.onFormSubmitted(context, 'form-1', submission);

      expect(mockTriggerEvent).toHaveBeenCalledWith(
        context,
        'form.submitted',
        expect.objectContaining({
          event: 'form.submitted',
          data: {
            formId: 'form-1',
            formName: 'Contact Us',
            submittedAt: expect.any(String),
            fieldCount: 6, // Field data is NOT included
          },
        })
      );

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('fields');
      expect(payload.data).not.toHaveProperty('submitterEmail');
      expect(payload.data).not.toHaveProperty('submitterName');
    });
  });

  // ============================================
  // PHI Sanitization Tests
  // ============================================

  describe('PHI Sanitization', () => {
    it('should never include businessId in any payload', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date(),
      };

      await service.onLeadCreated(context, lead);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('businessId');
    });

    it('should redact all PII fields in leads', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '+1234567890',
        status: 'new',
        source: 'website',
        tags: [],
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date(),
      };

      await service.onLeadCreated(context, lead);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data.firstName).toBe('[REDACTED]');
      expect(payload.data.lastName).toBe('[REDACTED]');
      expect(payload.data.email).toBe('[REDACTED]');
      expect(payload.data.phone).toBe('[REDACTED]');
    });

    it('should sanitize notes and customFields', async () => {
      const lead: Lead = {
        id: 'lead-1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        notes: 'Patient has diabetes and hypertension',
        customFields: {
          medicalCondition: 'Diabetes',
          ssn: '123-45-6789',
        },
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date(),
      };

      await service.onLeadCreated(context, lead);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('notes');
      expect(payload.data).not.toHaveProperty('customFields');
      expect(payload.data.hasNotes).toBe(true);
      expect(payload.data.customFieldCount).toBe(2);
    });

    it('should sanitize contact addresses', async () => {
      const contact: Client = {
        id: 'client-1',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        address: {
          street: '123 Private St',
          city: 'San Francisco',
          state: 'CA',
          zipCode: '94105',
        },
        tags: [],
        createdAt: new Date(),
      };

      await service.onContactCreated(context, contact);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('address');
      expect(payload.data.hasAddress).toBe(true);
    });

    it('should sanitize email content and participants', async () => {
      const email: EmailMessage = {
        id: 'email-1',
        businessId: 'business-123',
        accountId: 'account-1',
        providerMessageId: 'provider-msg-123',
        fromEmail: 'sender@example.com',
        fromName: 'Sender Name',
        toEmails: ['recipient1@example.com', 'recipient2@example.com'],
        ccEmails: ['cc@example.com'],
        bccEmails: ['bcc@example.com'],
        subject: 'Test Email',
        bodyText: 'Sensitive patient information',
        bodyHtml: '<p>Sensitive patient information</p>',
        snippet: 'Sensitive patient...',
        direction: 'outbound',
        sentAt: new Date(),
        opens: 0,
        clicks: 0,
        hasAttachments: false,
        isRead: false,
        isStarred: false,
        createdAt: new Date(),
      };

      await service.onEmailSent(context, email);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data).not.toHaveProperty('bodyText');
      expect(payload.data).not.toHaveProperty('bodyHtml');
      expect(payload.data).not.toHaveProperty('snippet');
      expect(payload.data).not.toHaveProperty('toEmails');
      expect(payload.data).not.toHaveProperty('ccEmails');
      expect(payload.data).not.toHaveProperty('bccEmails');
      expect(payload.data.recipientCount).toBe(2);
      expect(payload.data.ccCount).toBe(1);
      expect(payload.data.bccCount).toBe(1);
    });

    it('should include structural metadata instead of PHI', async () => {
      const deal: Deal = {
        id: 'deal-1',
        pipelineId: 'pipeline-1',
        stageId: 'stage-1',
        title: 'Test Deal',
        valueCents: 5000000,
        currency: 'USD',
        probability: 70,
        status: 'open',
        tags: [],
        notes: 'Confidential deal notes',
        customFields: { key1: 'value1', key2: 'value2' },
        wonLostReason: 'Lost to competitor',
        ownerId: 'user-1',
        ownerName: 'Alice',
        teamIds: ['team-1'],
        visibility: 'team',
        createdAt: new Date(),
      };

      await service.onDealCreated(context, deal);

      const payload = mockTriggerEvent.mock.calls[0][2];
      expect(payload.data.hasNotes).toBe(true);
      expect(payload.data.customFieldCount).toBe(2);
      expect(payload.data.hasWonLostReason).toBe(true);
      expect(payload.data).not.toHaveProperty('notes');
      expect(payload.data).not.toHaveProperty('customFields');
      expect(payload.data).not.toHaveProperty('wonLostReason');
    });
  });
});
