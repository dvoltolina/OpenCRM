/**
 * Email Tracking Service
 * Generates tracking pixels/link wrappers and records open/click events.
 *
 * HIPAA: IP addresses must be hashed before storage; no PHI in logs or metadata.
 * Tenant isolation: all writes scoped by businessId via SecurityContext.
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getEmailMessageRepository } from '../data/repositories/email-message-repository';
import { getEmailTrackingEventRepository } from '../data/repositories/email-tracking-event-repository';
import type { EmailMessage } from '../types/email-integration';
import { generateId } from '../data/repositories/firestore-utils';
import { getFunctionsBaseUrl } from './functions-base-url';

export interface TrackingPrepareOptions {
  trackOpens: boolean;
  trackClicks: boolean;
}

export interface TrackingStats {
  opens: number;
  clicks: number;
  firstOpenedAt?: Date;
  lastOpenedAt?: Date;
}

export interface TrackingEventMetadata {
  businessId?: string;
  messageId?: string;
  ipHash?: string; // Already hashed upstream
  userAgent?: string;
  occurredAt?: Date;
}

type TrackingEventType = 'open' | 'click';

const TRACK_PIXEL_STYLE =
  'display:block;width:1px;height:1px;max-width:1px;max-height:1px;border:0;line-height:0;';

export class EmailTrackingService {
  private messages = getEmailMessageRepository();
  private trackingEvents = getEmailTrackingEventRepository();

  /**
   * Prepare outbound HTML with tracking pixel and link wrappers.
   * Persists/reset tracking metadata on the email message when available.
   */
  async prepareEmailForTracking(
    context: SecurityContext,
    messageId: string,
    bodyHtml: string,
    options: TrackingPrepareOptions
  ): Promise<string> {
    if (!options.trackOpens && !options.trackClicks) {
      return bodyHtml;
    }

    const baseUrl = this.normalizeBaseUrl(
      getFunctionsBaseUrl() || (typeof process !== 'undefined' && process.env?.VITEST ? 'https://functions.test' : '')
    );
    if (!baseUrl) {
      throw new Error('Tracking requires a resolved Functions base URL');
    }

    const trackingId = await this.ensureTrackingId(context, messageId);
    const encodedTid = encodeURIComponent(trackingId);
    const encodedBid = encodeURIComponent(context.businessId);
    const encodedMid = encodeURIComponent(messageId);

    let modifiedHtml = bodyHtml || '';

    if (options.trackClicks) {
      modifiedHtml = this.wrapLinks(
        modifiedHtml,
        `${baseUrl}/trackEmailClick?tid=${encodedTid}&bid=${encodedBid}&mid=${encodedMid}&url=`
      );
    }

    if (options.trackOpens) {
      const pixelUrl = `${baseUrl}/trackEmailOpen?tid=${encodedTid}&bid=${encodedBid}&mid=${encodedMid}`;
      modifiedHtml = `${modifiedHtml}<img src="${pixelUrl}" alt="" width="1" height="1" style="${TRACK_PIXEL_STYLE}" />`;
    }

    await this.messages.update(context, messageId, {
      trackingId,
      opens: 0,
      clicks: 0,
      firstOpenedAt: undefined,
      lastOpenedAt: undefined,
      updatedAt: new Date(),
    });

    return modifiedHtml;
  }

  /**
   * Record an open event (called by tracking pixel webhook).
   * Requires businessId for tenant scoping; messageId is optional but preferred.
   */
  async recordOpen(trackingId: string, metadata?: TrackingEventMetadata): Promise<void> {
    const context = this.buildSystemContext(metadata?.businessId);
    if (!context) return;

    const resolved = await this.resolveMessage(context, trackingId, metadata?.messageId);
    if (!resolved) return;

    const occurredAt = metadata?.occurredAt || new Date();
    const recorded = await this.recordTrackingEvent(context, {
      trackingId,
      messageId: resolved.id,
      eventType: 'open',
      occurredAt,
      ipHash: metadata?.ipHash,
      userAgent: metadata?.userAgent,
    });

    if (recorded) {
      await this.incrementMessageStats(context, resolved, 'open', occurredAt);
    }
  }

  /**
   * Record a click event (called by click redirect webhook).
   * Requires businessId for tenant scoping; messageId is optional but preferred.
   */
  async recordClick(
    trackingId: string,
    linkUrl?: string,
    metadata?: TrackingEventMetadata
  ): Promise<void> {
    const context = this.buildSystemContext(metadata?.businessId);
    if (!context) return;

    const resolved = await this.resolveMessage(context, trackingId, metadata?.messageId);
    if (!resolved) return;

    const occurredAt = metadata?.occurredAt || new Date();
    const recorded = await this.recordTrackingEvent(context, {
      trackingId,
      messageId: resolved.id,
      eventType: 'click',
      occurredAt,
      linkUrl,
    });

    if (recorded) {
      await this.incrementMessageStats(context, resolved, 'click', occurredAt);
    }
  }

  /**
   * Return cached tracking stats for an email.
   */
  async getTrackingStats(context: SecurityContext, messageId: string): Promise<TrackingStats> {
    const result = await this.messages.getById(context, messageId);
    if (!result.success || !result.data) {
      return { opens: 0, clicks: 0 };
    }

    return {
      opens: result.data.opens || 0,
      clicks: result.data.clicks || 0,
      firstOpenedAt: result.data.firstOpenedAt,
      lastOpenedAt: result.data.lastOpenedAt,
    };
  }

  // ============================================================
  // Internal helpers
  // ============================================================

  private normalizeBaseUrl(baseUrl: string): string {
    return baseUrl.replace(/\/+$/, '');
  }

  private wrapLinks(html: string, trackingPrefix: string): string {
    const linkRegex = /<a\s+[^>]*href="([^"]+)"[^>]*>/gi;
    return html.replace(linkRegex, (match, href) => {
      const normalized = href.trim();
      const lowerHref = normalized.toLowerCase();
      const isSafe =
        lowerHref.startsWith('http://') || lowerHref.startsWith('https://');

      const alreadyWrapped = lowerHref.includes('/trackemailclick');
      const isDisallowed =
        !isSafe ||
        lowerHref.startsWith('#') ||
        lowerHref.startsWith('mailto:') ||
        lowerHref.startsWith('tel:') ||
        lowerHref.startsWith('javascript:') ||
        lowerHref.startsWith('data:');

      if (isDisallowed || alreadyWrapped) {
        return match;
      }

      const wrapped = `${trackingPrefix}${encodeURIComponent(normalized)}`;
      return match.replace(`href="${href}"`, `href="${wrapped}"`);
    });
  }

  private async ensureTrackingId(context: SecurityContext, messageId: string): Promise<string> {
    const existing = await this.messages.getById(context, messageId);
    if (existing.success && existing.data?.trackingId) {
      return existing.data.trackingId;
    }
    return generateId();
  }

  private buildSystemContext(businessId?: string): SecurityContext | null {
    if (!businessId) return null;
    return {
      businessId,
      userId: 'system-email-tracker',
      userName: 'System Email Tracker',
      userRole: 'system',
      teamIds: [],
      managedTeamIds: [],
    };
  }

  private async resolveMessage(
    context: SecurityContext,
    trackingId: string,
    messageId?: string
  ): Promise<EmailMessage | null> {
    if (messageId) {
      const result = await this.messages.getById(context, messageId);
      if (result.success && result.data?.businessId === context.businessId) {
        return result.data;
      }
    }

    const lookup = await this.messages.getByTrackingId(context, trackingId);
    return lookup.success && lookup.data?.businessId === context.businessId
      ? lookup.data
      : null;
  }

  private async recordTrackingEvent(
    context: SecurityContext,
    payload: {
      trackingId: string;
      messageId: string;
      eventType: TrackingEventType;
      occurredAt: Date;
      linkUrl?: string;
      ipHash?: string;
      userAgent?: string;
    }
  ): Promise<boolean> {
    const existing = await this.trackingEvents.getByTrackingId(context, payload.trackingId);
    if (existing.success && existing.data) {
      const duplicateOpen =
        payload.eventType === 'open' &&
        existing.data.data.some((event) => {
          if (event.eventType !== 'open') return false;
          const ipMatch =
            payload.ipHash && event.ipAddress
              ? payload.ipHash === event.ipAddress
              : false;
          const uaMatch =
            payload.userAgent && event.userAgent
              ? payload.userAgent === event.userAgent
              : false;

          if (payload.ipHash && payload.userAgent) {
            return ipMatch && uaMatch;
          }

          return ipMatch || uaMatch;
        });

      if (duplicateOpen) {
        return false;
      }
    }

    await this.trackingEvents.create(context, {
      businessId: context.businessId,
      messageId: payload.messageId,
      trackingId: payload.trackingId,
      eventType: payload.eventType,
      linkUrl: payload.linkUrl,
      ipAddress: payload.ipHash,
      userAgent: payload.userAgent,
      occurredAt: payload.occurredAt,
    });

    return true;
  }

  private async incrementMessageStats(
    context: SecurityContext,
    message: EmailMessage,
    kind: TrackingEventType,
    occurredAt: Date
  ): Promise<void> {
    const updates: Partial<EmailMessage> = {
      updatedAt: new Date(),
    };

    if (kind === 'open') {
      const opens = message.opens || 0;
      updates.opens = opens + 1;
      updates.firstOpenedAt = message.firstOpenedAt || occurredAt;
      updates.lastOpenedAt = occurredAt;
    } else {
      const clicks = message.clicks || 0;
      updates.clicks = clicks + 1;
    }

    await this.messages.update(context, message.id, updates);
  }
}

// ============================================================
// Singleton
// ============================================================

let serviceInstance: EmailTrackingService | null = null;

export function getEmailTrackingService(): EmailTrackingService {
  if (!serviceInstance) {
    serviceInstance = new EmailTrackingService();
  }
  return serviceInstance;
}
