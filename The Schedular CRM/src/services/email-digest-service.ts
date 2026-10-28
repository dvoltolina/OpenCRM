/**
 * Email Digest Service
 * Generates and sends digest emails with notification summaries
 *
 * HIPAA Compliance:
 * - NO PHI in email content - summaries reference entities only
 * - Sent to authenticated email only
 * - Audit logging for email sends
 *
 * Note: Actual email sending is handled by Cloud Functions
 * This service provides client-side utilities and formatting
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getNotificationRepository } from '../data/repositories/notification-repository';
import type {
  Notification,
  NotificationType,
  DigestFrequency,
  DigestNotificationGroup,
  DigestEmailContent,
} from '../types/notifications';

// ============================================
// Types
// ============================================

export interface DigestServiceResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// ============================================
// Configuration
// ============================================

/**
 * Human-readable labels for notification types
 */
const NOTIFICATION_TYPE_LABELS: Record<NotificationType, string> = {
  task_due: 'Tasks Due',
  task_assigned: 'New Tasks',
  task_completed: 'Completed Tasks',
  deal_stage_changed: 'Deal Updates',
  deal_won: 'Deals Won',
  deal_lost: 'Deals Lost',
  lead_assigned: 'New Leads',
  lead_converted: 'Converted Leads',
  sequence_reply: 'Sequence Replies',
  sequence_completed: 'Completed Sequences',
  email_opened: 'Email Opens',
  email_clicked: 'Email Clicks',
  meeting_scheduled: 'New Meetings',
  mention: 'Mentions',
  comment: 'Comments',
  goal_achieved: 'Goals Achieved',
  goal_at_risk: 'Goals at Risk',
  system_announcement: 'Announcements',
};

/**
 * Priority order for digest sections
 */
const TYPE_PRIORITY: NotificationType[] = [
  'task_due',
  'deal_won',
  'goal_achieved',
  'sequence_reply',
  'lead_assigned',
  'task_assigned',
  'mention',
  'email_clicked',
  'email_opened',
  'deal_stage_changed',
  'goal_at_risk',
  'meeting_scheduled',
  'task_completed',
  'lead_converted',
  'sequence_completed',
  'deal_lost',
  'comment',
  'system_announcement',
];

// ============================================
// Email Digest Service
// ============================================

export class EmailDigestService {
  private notificationRepo = getNotificationRepository();

  // ============================================
  // Digest Generation
  // ============================================

  /**
   * Get notifications for a digest period
   */
  async getDigestNotifications(
    context: SecurityContext,
    userId: string,
    periodStart: Date,
    periodEnd: Date
  ): Promise<DigestServiceResult<Notification[]>> {
    try {
      const result = await this.notificationRepo.getForDigest(
        context,
        userId,
        periodStart,
        periodEnd
      );

      if (!result.success) {
        return {
          success: false,
          error: {
            code: 'FETCH_ERROR',
            message: result.error?.message || 'Failed to fetch notifications',
          },
        };
      }

      return {
        success: true,
        data: result.data,
      };
    } catch (error) {
      return {
        success: false,
        error: {
          code: 'FETCH_ERROR',
          message: error instanceof Error ? error.message : 'Failed to fetch notifications',
        },
      };
    }
  }

  /**
   * Format digest email content
   */
  formatDigestEmail(
    notifications: Notification[],
    periodStart: Date,
    periodEnd: Date,
    frequency: DigestFrequency
  ): DigestEmailContent {
    // Group notifications by type
    const groups = this.groupNotifications(notifications);

    // Generate subject line
    const subject = this.generateSubject(notifications.length, frequency);

    // Generate HTML content
    const html = this.generateHtml(groups, periodStart, periodEnd, frequency);

    return {
      subject,
      html,
      groups,
      totalCount: notifications.length,
      periodStart,
      periodEnd,
    };
  }

  // ============================================
  // Grouping
  // ============================================

  /**
   * Group notifications by type
   */
  private groupNotifications(notifications: Notification[]): DigestNotificationGroup[] {
    const grouped = new Map<NotificationType, Notification[]>();

    // Group by type
    for (const notification of notifications) {
      const existing = grouped.get(notification.type) || [];
      existing.push(notification);
      grouped.set(notification.type, existing);
    }

    // Convert to array and sort by priority
    const groups: DigestNotificationGroup[] = [];
    for (const type of TYPE_PRIORITY) {
      const typeNotifications = grouped.get(type);
      if (typeNotifications && typeNotifications.length > 0) {
        groups.push({
          type,
          notifications: typeNotifications,
          count: typeNotifications.length,
        });
      }
    }

    return groups;
  }

  // ============================================
  // Subject Generation
  // ============================================

  /**
   * Generate email subject line
   */
  private generateSubject(count: number, frequency: DigestFrequency): string {
    const frequencyLabel = this.getFrequencyLabel(frequency);

    if (count === 0) {
      return `Your ${frequencyLabel} CRM Digest - All caught up!`;
    }

    if (count === 1) {
      return `Your ${frequencyLabel} CRM Digest - 1 notification`;
    }

    return `Your ${frequencyLabel} CRM Digest - ${count} notifications`;
  }

  /**
   * Get human-readable frequency label
   */
  private getFrequencyLabel(frequency: DigestFrequency): string {
    switch (frequency) {
      case 'hourly':
        return 'Hourly';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      default:
        return '';
    }
  }

  // ============================================
  // HTML Generation
  // ============================================

  /**
   * Generate HTML email content
   * Note: Keep simple for email client compatibility
   */
  private generateHtml(
    groups: DigestNotificationGroup[],
    periodStart: Date,
    periodEnd: Date,
    frequency: DigestFrequency
  ): string {
    const periodText = this.formatPeriod(periodStart, periodEnd, frequency);

    if (groups.length === 0) {
      return this.generateEmptyDigestHtml(periodText);
    }

    return this.generateDigestHtml(groups, periodText);
  }

  /**
   * Generate HTML for empty digest
   */
  private generateEmptyDigestHtml(periodText: string): string {
    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CRM Digest</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <tr>
      <td style="padding: 40px 30px; text-align: center;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin: 0 0 10px 0;">All caught up!</h1>
        <p style="color: #666666; font-size: 16px; margin: 0;">
          No new notifications ${periodText}.
        </p>
        <a href="${this.getAppUrl()}" style="display: inline-block; margin-top: 20px; padding: 12px 24px; background-color: #2563eb; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 500;">
          Open CRM
        </a>
      </td>
    </tr>
  </table>
</body>
</html>
    `.trim();
  }

  /**
   * Generate HTML for digest with notifications
   */
  private generateDigestHtml(groups: DigestNotificationGroup[], periodText: string): string {
    const totalCount = groups.reduce((sum, g) => sum + g.count, 0);
    const sectionsHtml = groups.map((group) => this.generateGroupHtml(group)).join('');

    return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CRM Digest</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <!-- Header -->
    <tr>
      <td style="padding: 30px 30px 20px 30px; border-bottom: 1px solid #e5e5e5;">
        <h1 style="color: #1a1a1a; font-size: 24px; margin: 0 0 5px 0;">Your CRM Digest</h1>
        <p style="color: #666666; font-size: 14px; margin: 0;">
          ${totalCount} notification${totalCount !== 1 ? 's' : ''} ${periodText}
        </p>
      </td>
    </tr>

    <!-- Notification Groups -->
    ${sectionsHtml}

    <!-- Footer -->
    <tr>
      <td style="padding: 30px; background-color: #f9fafb; text-align: center;">
        <a href="${this.getAppUrl()}" style="display: inline-block; padding: 12px 24px; background-color: #2563eb; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 500;">
          View All in CRM
        </a>
        <p style="color: #9ca3af; font-size: 12px; margin: 20px 0 0 0;">
          <a href="${this.getAppUrl()}/settings?tab=notifications" style="color: #6b7280;">
            Manage notification preferences
          </a>
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
    `.trim();
  }

  /**
   * Generate HTML for a notification group
   */
  private generateGroupHtml(group: DigestNotificationGroup): string {
    const label = NOTIFICATION_TYPE_LABELS[group.type] || group.type;
    const maxItems = 5;
    const itemsToShow = group.notifications.slice(0, maxItems);
    const remaining = group.notifications.length - maxItems;

    const itemsHtml = itemsToShow
      .map((notification) => this.generateNotificationItemHtml(notification))
      .join('');

    const remainingHtml =
      remaining > 0
        ? `<p style="color: #9ca3af; font-size: 13px; margin: 10px 0 0 0;">+ ${remaining} more</p>`
        : '';

    return `
    <tr>
      <td style="padding: 20px 30px; border-bottom: 1px solid #f0f0f0;">
        <h2 style="color: #374151; font-size: 16px; margin: 0 0 15px 0; font-weight: 600;">
          ${label} (${group.count})
        </h2>
        ${itemsHtml}
        ${remainingHtml}
      </td>
    </tr>
    `;
  }

  /**
   * Generate HTML for a single notification item
   */
  private generateNotificationItemHtml(notification: Notification): string {
    const actionUrl = notification.actionUrl
      ? `${this.getAppUrl()}${notification.actionUrl}`
      : this.getAppUrl();

    return `
    <div style="margin-bottom: 12px; padding-bottom: 12px; border-bottom: 1px solid #f3f4f6;">
      <a href="${actionUrl}" style="color: #111827; text-decoration: none; font-size: 14px; font-weight: 500;">
        ${this.escapeHtml(notification.title)}
      </a>
      <p style="color: #6b7280; font-size: 13px; margin: 4px 0 0 0;">
        ${this.escapeHtml(notification.body)}
      </p>
    </div>
    `;
  }

  // ============================================
  // Helpers
  // ============================================

  /**
   * Format period for display
   */
  private formatPeriod(
    periodStart: Date,
    _periodEnd: Date,
    frequency: DigestFrequency
  ): string {
    const options: Intl.DateTimeFormatOptions = {
      month: 'short',
      day: 'numeric',
    };

    switch (frequency) {
      case 'hourly':
        return `in the last hour`;
      case 'daily':
        return `on ${periodStart.toLocaleDateString('en-US', options)}`;
      case 'weekly':
        return `this week`;
      default:
        return `recently`;
    }
  }

  /**
   * Get app base URL
   */
  private getAppUrl(): string {
    return import.meta.env.VITE_APP_URL || 'https://app.example.com/crm';
  }

  /**
   * Escape HTML entities
   */
  private escapeHtml(text: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;',
    };

    return text.replace(/[&<>"']/g, (char) => map[char] || char);
  }

  // ============================================
  // Period Calculation
  // ============================================

  /**
   * Calculate digest period based on frequency
   */
  static calculatePeriod(
    frequency: DigestFrequency,
    referenceTime: Date = new Date()
  ): { periodStart: Date; periodEnd: Date } {
    const periodEnd = new Date(referenceTime);
    const periodStart = new Date(referenceTime);

    switch (frequency) {
      case 'hourly':
        periodStart.setHours(periodStart.getHours() - 1);
        break;
      case 'daily':
        periodStart.setDate(periodStart.getDate() - 1);
        break;
      case 'weekly':
        periodStart.setDate(periodStart.getDate() - 7);
        break;
      default:
        periodStart.setDate(periodStart.getDate() - 1);
    }

    return { periodStart, periodEnd };
  }
}

// ============================================
// Singleton Instance
// ============================================

let emailDigestServiceInstance: EmailDigestService | null = null;

export function getEmailDigestService(): EmailDigestService {
  if (!emailDigestServiceInstance) {
    emailDigestServiceInstance = new EmailDigestService();
  }
  return emailDigestServiceInstance;
}
