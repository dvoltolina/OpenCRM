/**
 * Notification Triggers
 * Event handlers that create notifications based on CRM events
 *
 * HIPAA Compliance:
 * - NO PHI in notification titles/bodies - use generic workflow language only
 * - All triggers require SecurityContext
 * - Rate limiting applied via NotificationService
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getNotificationService } from './notification-service';
import type { NotificationEntityType } from '../types/notifications';
import type { SalesActivity, Deal, Lead } from '../types/models';
import type { Goal } from '../types/goals';

// ============================================
// Types
// ============================================

export interface SequenceEnrollment {
  id: string;
  sequenceId: string;
  sequenceName: string;
  entityType: 'lead' | 'client' | 'deal';
  entityId: string;
  entityName: string;
  ownerId?: string;
}

export interface EmailMessage {
  id: string;
  recipientId: string;
  recipientName?: string;
  subject?: string;
  dealId?: string;
  leadId?: string;
  ownerId?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format relative time for notification body
 */
function formatRelativeTime(date: Date | undefined): string {
  if (!date) return 'soon';

  const now = new Date();
  const target = new Date(date);
  const diffMs = target.getTime() - now.getTime();
  const diffMins = Math.round(diffMs / (1000 * 60));
  const diffHours = Math.round(diffMs / (1000 * 60 * 60));
  const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));

  if (diffMins < 0) {
    const absMins = Math.abs(diffMins);
    if (absMins < 60) return `${absMins} minutes ago`;
    const absHours = Math.abs(diffHours);
    if (absHours < 24) return `${absHours} hours ago`;
    return `${Math.abs(diffDays)} days ago`;
  }

  if (diffMins < 60) return `in ${diffMins} minutes`;
  if (diffHours < 24) return `in ${diffHours} hours`;
  if (diffDays === 0) return 'today';
  if (diffDays === 1) return 'tomorrow';
  return `in ${diffDays} days`;
}

// ============================================
// Notification Triggers Class
// ============================================

export class NotificationTriggers {
  private notificationService = getNotificationService();

  // ============================================
  // Task Triggers
  // ============================================

  /**
   * Triggered when a task is created and assigned to someone else
   */
  async onTaskCreated(context: SecurityContext, task: SalesActivity): Promise<void> {
    // Only notify if assigned to someone other than creator
    if (!task.assigneeId || task.assigneeId === context.userId) {
      return;
    }

    await this.notificationService.notify(context, {
      userId: task.assigneeId,
      type: 'task_assigned',
      title: 'New task assigned',
      body: 'A task was assigned to you.',
      entity: { type: 'task', id: task.id },
      actionUrl: `/activities?id=${task.id}`,
      actorId: context.userId,
      actorName: context.userName,
    });
  }

  /**
   * Triggered when a task is due soon (called by scheduled function)
   */
  async onTaskDue(context: SecurityContext, task: SalesActivity): Promise<void> {
    if (!task.assigneeId) return;

    await this.notificationService.notify(context, {
      userId: task.assigneeId,
      type: 'task_due',
      title: 'Task due soon',
      body: `A task is due ${formatRelativeTime(task.dueDate)}.`,
      priority: 'high',
      entity: { type: 'task', id: task.id },
      actionUrl: `/activities?id=${task.id}`,
    });
  }

  /**
   * Triggered when a task is completed
   */
  async onTaskCompleted(context: SecurityContext, task: SalesActivity): Promise<void> {
    // Notify the task creator if different from completer
    if (task.createdById && task.createdById !== context.userId) {
      await this.notificationService.notify(context, {
        userId: task.createdById,
        type: 'task_completed',
        title: 'Task completed',
        body: 'A task you created was completed.',
        entity: { type: 'task', id: task.id },
        actionUrl: `/activities?id=${task.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  // ============================================
  // Deal Triggers
  // ============================================

  /**
   * Triggered when a deal stage changes
   */
  async onDealStageChanged(
    context: SecurityContext,
    deal: Deal,
    _previousStage: string,
    newStageName: string
  ): Promise<void> {
    // Notify deal owner if different from updater
    if (deal.ownerId && deal.ownerId !== context.userId) {
      await this.notificationService.notify(context, {
        userId: deal.ownerId,
        type: 'deal_stage_changed',
        title: 'Deal stage updated',
        body: `A deal moved to ${newStageName}.`,
        entity: { type: 'deal', id: deal.id },
        actionUrl: `/pipeline?deal=${deal.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }

    // Also notify assignee if different
    if (deal.assigneeId && deal.assigneeId !== context.userId && deal.assigneeId !== deal.ownerId) {
      await this.notificationService.notify(context, {
        userId: deal.assigneeId,
        type: 'deal_stage_changed',
        title: 'Deal stage updated',
        body: `A deal moved to ${newStageName}.`,
        entity: { type: 'deal', id: deal.id },
        actionUrl: `/pipeline?deal=${deal.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  /**
   * Triggered when a deal is won
   */
  async onDealWon(context: SecurityContext, deal: Deal): Promise<void> {
    // Notify deal owner
    if (deal.ownerId && deal.ownerId !== context.userId) {
      await this.notificationService.notify(context, {
        userId: deal.ownerId,
        type: 'deal_won',
        title: 'Deal won!',
        body: 'A deal was closed-won.',
        priority: 'high',
        entity: { type: 'deal', id: deal.id },
        actionUrl: `/pipeline?deal=${deal.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }

    // Notify assignee
    if (deal.assigneeId && deal.assigneeId !== context.userId && deal.assigneeId !== deal.ownerId) {
      await this.notificationService.notify(context, {
        userId: deal.assigneeId,
        type: 'deal_won',
        title: 'Deal won!',
        body: 'A deal was closed-won.',
        priority: 'high',
        entity: { type: 'deal', id: deal.id },
        actionUrl: `/pipeline?deal=${deal.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  /**
   * Triggered when a deal is lost
   */
  async onDealLost(context: SecurityContext, deal: Deal): Promise<void> {
    // Notify deal owner
    if (deal.ownerId && deal.ownerId !== context.userId) {
      await this.notificationService.notify(context, {
        userId: deal.ownerId,
        type: 'deal_lost',
        title: 'Deal lost',
        body: 'A deal was closed-lost.',
        entity: { type: 'deal', id: deal.id },
        actionUrl: `/pipeline?deal=${deal.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  // ============================================
  // Lead Triggers
  // ============================================

  /**
   * Triggered when a lead is assigned
   */
  async onLeadAssigned(context: SecurityContext, lead: Lead): Promise<void> {
    if (!lead.assigneeId || lead.assigneeId === context.userId) {
      return;
    }

    await this.notificationService.notify(context, {
      userId: lead.assigneeId,
      type: 'lead_assigned',
      title: 'Lead assigned to you',
      body: 'A lead was assigned to you.',
      entity: { type: 'lead', id: lead.id },
      actionUrl: `/leads/${lead.id}`,
      actorId: context.userId,
      actorName: context.userName,
    });
  }

  /**
   * Triggered when a lead is converted
   */
  async onLeadConverted(context: SecurityContext, lead: Lead): Promise<void> {
    // Notify lead owner if different from converter
    if (lead.ownerId && lead.ownerId !== context.userId) {
      await this.notificationService.notify(context, {
        userId: lead.ownerId,
        type: 'lead_converted',
        title: 'Lead converted',
        body: 'A lead was converted.',
        entity: { type: 'lead', id: lead.id },
        actionUrl: lead.convertedToDealId
          ? `/pipeline?deal=${lead.convertedToDealId}`
          : lead.convertedToClientId
            ? `/contacts/${lead.convertedToClientId}`
            : `/leads/${lead.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  // ============================================
  // Sequence Triggers
  // ============================================

  /**
   * Triggered when someone replies to a sequence email
   */
  async onSequenceReply(
    context: SecurityContext,
    enrollment: SequenceEnrollment
  ): Promise<void> {
    if (!enrollment.ownerId) return;

    await this.notificationService.notify(context, {
      userId: enrollment.ownerId,
      type: 'sequence_reply',
      title: 'Sequence reply received',
      body: 'A sequence recipient replied.',
      priority: 'high',
      entity: { type: 'sequence', id: enrollment.sequenceId },
      actionUrl: `/sequences/${enrollment.sequenceId}/enrollments/${enrollment.id}`,
    });
  }

  /**
   * Triggered when a sequence enrollment completes
   */
  async onSequenceCompleted(
    context: SecurityContext,
    enrollment: SequenceEnrollment
  ): Promise<void> {
    if (!enrollment.ownerId) return;

    await this.notificationService.notify(context, {
      userId: enrollment.ownerId,
      type: 'sequence_completed',
      title: 'Sequence completed',
      body: 'A sequence enrollment completed.',
      entity: { type: 'sequence', id: enrollment.sequenceId },
      actionUrl: `/sequences/${enrollment.sequenceId}/enrollments/${enrollment.id}`,
    });
  }

  // ============================================
  // Email Tracking Triggers
  // ============================================

  /**
   * Triggered when an email is opened
   */
  async onEmailOpened(
    context: SecurityContext,
    email: EmailMessage
  ): Promise<void> {
    if (!email.ownerId) return;

    await this.notificationService.notify(context, {
      userId: email.ownerId,
      type: 'email_opened',
      title: 'Email opened',
      body: 'A tracked email was opened.',
      entity: { type: 'email', id: email.id },
      actionUrl: email.dealId
        ? `/pipeline?deal=${email.dealId}`
        : email.leadId
          ? `/leads/${email.leadId}`
          : undefined,
    });
  }

  /**
   * Triggered when an email link is clicked
   */
  async onEmailClicked(
    context: SecurityContext,
    email: EmailMessage,
    _linkUrl: string
  ): Promise<void> {
    if (!email.ownerId) return;

    await this.notificationService.notify(context, {
      userId: email.ownerId,
      type: 'email_clicked',
      title: 'Email link clicked',
      body: 'A tracked email link was clicked.',
      priority: 'high', // Clicks indicate high engagement
      entity: { type: 'email', id: email.id },
      actionUrl: email.dealId
        ? `/pipeline?deal=${email.dealId}`
        : email.leadId
          ? `/leads/${email.leadId}`
          : undefined,
    });
  }

  // ============================================
  // Meeting Triggers
  // ============================================

  /**
   * Triggered when a meeting is scheduled
   */
  async onMeetingScheduled(
    context: SecurityContext,
    meeting: {
      id: string;
      title: string;
      startTime: Date;
      attendeeIds: string[];
      organizerId?: string;
    }
  ): Promise<void> {
    // Notify all attendees except the organizer
    for (const attendeeId of meeting.attendeeIds) {
      if (attendeeId === context.userId || attendeeId === meeting.organizerId) {
        continue;
      }

      await this.notificationService.notify(context, {
        userId: attendeeId,
        type: 'meeting_scheduled',
        title: 'Meeting scheduled',
        body: `A meeting was scheduled for ${formatRelativeTime(meeting.startTime)}.`,
        entity: { type: 'activity', id: meeting.id },
        actionUrl: `/activities?id=${meeting.id}`,
        actorId: context.userId,
        actorName: context.userName,
      });
    }
  }

  // ============================================
  // Mention Trigger
  // ============================================

  /**
   * Triggered when someone is @mentioned
   */
  async onMention(
    context: SecurityContext,
    mentionedUserId: string,
    entityType: NotificationEntityType,
    entityId: string,
    _text: string
  ): Promise<void> {
    if (mentionedUserId === context.userId) return;

    await this.notificationService.notify(context, {
      userId: mentionedUserId,
      type: 'mention',
      title: 'You were mentioned',
      body: 'You were mentioned in an update.',
      priority: 'high',
      entity: { type: entityType, id: entityId },
      actionUrl: this.getEntityUrl(entityType, entityId),
      actorId: context.userId,
      actorName: context.userName,
    });
  }

  // ============================================
  // Goal Triggers
  // ============================================

  /**
   * Triggered when a goal is achieved
   */
  async onGoalAchieved(context: SecurityContext, goal: Goal): Promise<void> {
    // Notify goal assignee
    if (goal.assigneeId && goal.assigneeId !== context.userId) {
      await this.notificationService.notify(context, {
        userId: goal.assigneeId,
        type: 'goal_achieved',
        title: 'Goal achieved!',
        body: 'One of your tracked goals was achieved.',
        priority: 'high',
        entity: { type: 'goal', id: goal.id },
        actionUrl: `/goals/${goal.id}`,
      });
    }

    // Notify goal creator if different
    if (goal.createdById && goal.createdById !== context.userId && goal.createdById !== goal.assigneeId) {
      await this.notificationService.notify(context, {
        userId: goal.createdById,
        type: 'goal_achieved',
        title: 'Goal achieved',
        body: 'A tracked goal was achieved.',
        entity: { type: 'goal', id: goal.id },
        actionUrl: `/goals/${goal.id}`,
      });
    }
  }

  /**
   * Triggered when a goal is at risk of not being met
   */
  async onGoalAtRisk(context: SecurityContext, goal: Goal): Promise<void> {
    if (!goal.assigneeId) return;

    await this.notificationService.notify(context, {
      userId: goal.assigneeId,
      type: 'goal_at_risk',
      title: 'Goal at risk',
      body: 'One of your tracked goals is at risk.',
      priority: 'high',
      entity: { type: 'goal', id: goal.id },
      actionUrl: `/goals/${goal.id}`,
    });
  }

  // ============================================
  // System Announcements
  // ============================================

  /**
   * Send a system announcement to multiple users
   */
  async sendSystemAnnouncement(
    context: SecurityContext,
    userIds: string[],
    title: string,
    body: string,
    actionUrl?: string
  ): Promise<void> {
    await this.notificationService.notifyMany(context, userIds, {
      type: 'system_announcement',
      title,
      body,
      priority: 'normal',
      actionUrl,
    });
  }

  // ============================================
  // Helpers
  // ============================================

  /**
   * Get URL for entity type
   */
  private getEntityUrl(entityType: NotificationEntityType, entityId: string): string {
    const urlMap: Record<NotificationEntityType, string> = {
      lead: `/leads/${entityId}`,
      client: `/contacts/${entityId}`,
      deal: `/pipeline?deal=${entityId}`,
      task: `/activities?id=${entityId}`,
      sequence: `/sequences/${entityId}`,
      email: `/activities`,
      goal: `/goals/${entityId}`,
      activity: `/activities?id=${entityId}`,
    };

    return urlMap[entityType] || '/';
  }
}

// ============================================
// Singleton Instance
// ============================================

let notificationTriggersInstance: NotificationTriggers | null = null;

export function getNotificationTriggers(): NotificationTriggers {
  if (!notificationTriggersInstance) {
    notificationTriggersInstance = new NotificationTriggers();
  }
  return notificationTriggersInstance;
}
