/**
 * Sequence Analytics Service
 * Calculate aggregate metrics for sequences, steps, and enrollments
 *
 * HIPAA Compliance:
 * - No PHI in logs or returned data (entity IDs only)
 * - All operations require SecurityContext for businessId scoping
 * - Audit logging for analytics access
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import type { SecurityContext } from '../data/repositories/repository-types';
import { getSequenceRepository } from '../data/repositories/sequence-repository';
import { getSequenceEnrollmentRepository } from '../data/repositories/sequence-enrollment-repository';
import { getSequenceExecutionRepository } from '../data/repositories/sequence-execution-repository';
import { getAuditLogService } from './AuditLogService';
import type { SequenceEnrollment, SequenceStep } from '../types/sequences';

// ============================================
// Types
// ============================================

export interface DateRange {
  start: Date;
  end: Date;
}

export interface SequenceMetrics {
  sequenceId: string;
  sequenceName: string;
  dateRange: DateRange;

  // Enrollment metrics
  totalEnrolled: number;
  activeEnrollments: number;
  completedCount: number;
  exitedCount: number;
  completionRate: number; // completed / (completed + exited)

  // Exit breakdown
  exitReasons: Record<string, number>;

  // Email metrics (if applicable)
  emailsSent: number;
  emailsDelivered: number;
  deliveryRate: number;
  emailsOpened: number;
  openRate: number;
  emailsClicked: number;
  clickRate: number;
  emailsReplied: number;
  replyRate: number;
  emailsBounced: number;
  bounceRate: number;

  // Task metrics
  tasksCreated: number;
  tasksCompleted: number;
  taskCompletionRate: number;

  // Timing metrics (in days)
  avgTimeToComplete: number;
  avgTimeToReply: number;
  avgTimeToExit: number;

  // Conversion metrics
  meetingsBooked: number;
  meetingBookingRate: number;
  dealsCreated: number;
  dealConversionRate: number;
  revenueInfluenced: number; // sum of deal values in cents

  // Calculated at
  calculatedAt: Date;
}

export interface StepMetrics {
  stepId: string;
  stepIndex: number;
  stepType: string;
  stepName: string;

  // Execution metrics
  executed: number;
  succeeded: number;
  failed: number;
  skipped: number;
  successRate: number;

  // For email steps
  sent: number;
  delivered: number;
  opened: number;
  clicked: number;
  replied: number;
  bounced: number;
  openRate: number;
  clickRate: number;
  replyRate: number;

  // Dropout at this step
  exitedAtStep: number;
  dropoutRate: number;

  // Timing
  avgExecutionDelay: number; // minutes from scheduled
}

export interface FunnelStep {
  stepId: string;
  stepIndex: number;
  stepName: string;
  stepType: string;
  enteredCount: number;
  completedCount: number;
  exitedCount: number;
  conversionRate: number; // completed / entered
  dropoffRate: number; // exited / entered
}

export interface FunnelData {
  sequenceId: string;
  sequenceName: string;
  totalEnrolled: number;
  steps: FunnelStep[];
  overallConversionRate: number;
}

export interface TrendData {
  date: string;
  enrolled: number;
  completed: number;
  exited: number;
  emailsSent: number;
  replies: number;
}

export interface SequenceComparison {
  sequenceId: string;
  sequenceName: string;
  enrollmentCount: number;
  completionRate: number;
  replyRate: number;
  meetingRate: number;
  avgTimeToComplete: number;
}

export interface SendTimeAnalysis {
  bestDays: { day: string; openRate: number; replyRate: number }[];
  bestHours: { hour: number; openRate: number; replyRate: number }[];
  recommendation: string;
}

// ============================================
// Helpers
// ============================================

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

function isInDateRange(date: Date, range?: DateRange): boolean {
  if (!range) return true;
  return date >= range.start && date <= range.end;
}

function daysBetween(start: Date, end: Date): number {
  const diff = end.getTime() - start.getTime();
  return diff / (1000 * 60 * 60 * 24);
}

function formatDateKey(date: Date, bucket: 'daily' | 'weekly' | 'monthly'): string {
  const year = date.getUTCFullYear();
  const month = date.getUTCMonth();
  const day = date.getUTCDate();

  if (bucket === 'daily') {
    return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  }

  if (bucket === 'weekly') {
    const firstDay = new Date(Date.UTC(year, 0, 1));
    const days = Math.floor((date.getTime() - firstDay.getTime()) / (24 * 60 * 60 * 1000));
    const week = Math.ceil((days + firstDay.getUTCDay() + 1) / 7);
    return `${year}-W${String(week).padStart(2, '0')}`;
  }

  // monthly
  return `${year}-${String(month + 1).padStart(2, '0')}`;
}

function getStepName(step: SequenceStep): string {
  switch (step.type) {
    case 'email':
      return step.emailConfig?.subject || `Email Step ${step.order + 1}`;
    case 'task':
      return step.taskConfig?.title || `Task Step ${step.order + 1}`;
    case 'call_reminder':
      return step.callConfig?.title || `Call Step ${step.order + 1}`;
    case 'wait':
      return `Wait ${step.delayDays} day${step.delayDays !== 1 ? 's' : ''}`;
    case 'sms':
      return `SMS Step ${step.order + 1}`;
    default:
      return `Step ${step.order + 1}`;
  }
}

// ============================================
// Sequence Analytics Service
// ============================================

export class SequenceAnalyticsService {
  private sequenceRepo = getSequenceRepository();
  private enrollmentRepo = getSequenceEnrollmentRepository();
  private executionRepo = getSequenceExecutionRepository();
  private auditService = getAuditLogService();

  // ============================================
  // Sequence Metrics
  // ============================================

  /**
   * Calculate aggregate metrics for a sequence.
   * Can be run on-demand or cached.
   */
  async calculateSequenceMetrics(
    context: SecurityContext,
    sequenceId: string,
    dateRange?: DateRange
  ): Promise<SequenceMetrics | null> {
    // 1. Get sequence
    const sequenceResult = await this.sequenceRepo.getById(context, sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return null;
    }
    const sequence = sequenceResult.data;

    // 2. Get all enrollments for this sequence
    const enrollmentsResult = await this.enrollmentRepo.getBySequence(context, sequenceId);
    if (!enrollmentsResult.success || !enrollmentsResult.data) {
      return this.emptySequenceMetrics(sequenceId, sequence.name, dateRange);
    }

    const allEnrollments = enrollmentsResult.data;

    // 3. Filter by date range if provided
    const enrollments = dateRange
      ? allEnrollments.filter((e) => isInDateRange(e.createdAt, dateRange))
      : allEnrollments;

    // 4. Calculate basic enrollment metrics
    const activeEnrollments = enrollments.filter((e) => e.status === 'active').length;
    const completedCount = enrollments.filter((e) => e.status === 'completed').length;
    const exitedEnrollments = enrollments.filter((e) =>
      ['exited', 'bounced', 'unsubscribed'].includes(e.status)
    );
    const exitedCount = exitedEnrollments.length;
    const completionRate =
      completedCount + exitedCount > 0 ? (completedCount / (completedCount + exitedCount)) * 100 : 0;

    // 5. Exit reason breakdown
    const exitReasons: Record<string, number> = {};
    exitedEnrollments.forEach((e) => {
      const reason = e.exitReason || 'unknown';
      exitReasons[reason] = (exitReasons[reason] || 0) + 1;
    });

    // 6. Aggregate email stats from enrollments
    const emailsSent = enrollments.reduce((sum, e) => sum + e.emailsSent, 0);
    const emailsOpened = enrollments.reduce((sum, e) => sum + e.emailsOpened, 0);
    const emailsClicked = enrollments.reduce((sum, e) => sum + e.emailsClicked, 0);
    const repliesReceived = enrollments.reduce((sum, e) => sum + e.repliesReceived, 0);

    // For delivered/bounced we need execution data
    const executionStats = await this.getExecutionStats(context, sequenceId, enrollments);

    const emailsDelivered = executionStats.delivered;
    const emailsBounced = executionStats.bounced;
    const deliveryRate = emailsSent > 0 ? (emailsDelivered / emailsSent) * 100 : 0;
    const openRate = emailsDelivered > 0 ? (emailsOpened / emailsDelivered) * 100 : 0;
    const clickRate = emailsDelivered > 0 ? (emailsClicked / emailsDelivered) * 100 : 0;
    const replyRate = emailsDelivered > 0 ? (repliesReceived / emailsDelivered) * 100 : 0;
    const bounceRate = emailsSent > 0 ? (emailsBounced / emailsSent) * 100 : 0;

    // 7. Task metrics
    const tasksCreated = enrollments.reduce((sum, e) => sum + e.tasksCreated, 0);
    const tasksCompleted = 0; // Would need to query sales_activities for completion status
    const taskCompletionRate = 0;

    // 8. Timing metrics
    const completedEnrollments = enrollments.filter((e) => e.status === 'completed' && e.completedAt);
    const avgTimeToComplete =
      completedEnrollments.length > 0
        ? completedEnrollments.reduce((sum, e) => sum + daysBetween(e.createdAt, e.completedAt!), 0) /
          completedEnrollments.length
        : 0;

    const repliedEnrollments = enrollments.filter((e) => e.repliesReceived > 0);
    const avgTimeToReply =
      repliedEnrollments.length > 0 && executionStats.avgTimeToFirstReply > 0
        ? executionStats.avgTimeToFirstReply
        : 0;

    const avgTimeToExit =
      exitedEnrollments.length > 0
        ? exitedEnrollments
            .filter((e) => e.exitedAt)
            .reduce((sum, e) => sum + daysBetween(e.createdAt, e.exitedAt!), 0) / exitedEnrollments.length
        : 0;

    // 9. Conversion metrics (would need external data integration)
    const meetingsBooked = exitedEnrollments.filter((e) => e.exitReason === 'meeting_booked').length;
    const meetingBookingRate = enrollments.length > 0 ? (meetingsBooked / enrollments.length) * 100 : 0;
    const dealsCreated = exitedEnrollments.filter(
      (e) => e.exitReason === 'deal_won' || e.exitReason === 'converted'
    ).length;
    const dealConversionRate = enrollments.length > 0 ? (dealsCreated / enrollments.length) * 100 : 0;
    const revenueInfluenced = 0; // Would need deals integration

    // 10. Audit log
    await this.auditService.logAction(context, {
      action: 'read',
      entityType: 'report',
      entityId: sequenceId,
      metadata: {
        action: 'calculateSequenceMetrics',
        sequenceId,
        enrollmentCount: enrollments.length,
      },
    });

    return {
      sequenceId,
      sequenceName: sequence.name,
      dateRange: dateRange || { start: new Date(0), end: new Date() },
      totalEnrolled: enrollments.length,
      activeEnrollments,
      completedCount,
      exitedCount,
      completionRate,
      exitReasons,
      emailsSent,
      emailsDelivered,
      deliveryRate,
      emailsOpened,
      openRate,
      emailsClicked,
      clickRate,
      emailsReplied: repliesReceived,
      replyRate,
      emailsBounced,
      bounceRate,
      tasksCreated,
      tasksCompleted,
      taskCompletionRate,
      avgTimeToComplete,
      avgTimeToReply,
      avgTimeToExit,
      meetingsBooked,
      meetingBookingRate,
      dealsCreated,
      dealConversionRate,
      revenueInfluenced,
      calculatedAt: new Date(),
    };
  }

  /**
   * Calculate metrics for a specific step.
   */
  async calculateStepMetrics(
    context: SecurityContext,
    sequenceId: string,
    stepId: string,
    dateRange?: DateRange
  ): Promise<StepMetrics | null> {
    // 1. Get sequence
    const sequenceResult = await this.sequenceRepo.getById(context, sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return null;
    }
    const sequence = sequenceResult.data;

    // 2. Find the step
    const step = sequence.steps.find((s) => s.id === stepId);
    if (!step) {
      return null;
    }

    // 3. Get all enrollments for this sequence
    const enrollmentsResult = await this.enrollmentRepo.getBySequence(context, sequenceId);
    if (!enrollmentsResult.success || !enrollmentsResult.data) {
      return this.emptyStepMetrics(stepId, step);
    }

    const enrollments = enrollmentsResult.data;

    // 4. Get executions for this step across all enrollments
    const allStepMetrics = await this.aggregateStepExecutions(context, enrollments, stepId, dateRange);

    // 5. Calculate dropout at this step
    const exitedAtStep = enrollments.filter(
      (e) =>
        (e.status === 'exited' || e.status === 'bounced' || e.status === 'unsubscribed') &&
        e.currentStepIndex === step.order
    ).length;

    const enteredStep = enrollments.filter((e) => e.currentStepIndex >= step.order || e.stepsCompleted > step.order).length;
    const dropoutRate = enteredStep > 0 ? (exitedAtStep / enteredStep) * 100 : 0;

    return {
      stepId,
      stepIndex: step.order,
      stepType: step.type,
      stepName: getStepName(step),
      executed: allStepMetrics.executed,
      succeeded: allStepMetrics.succeeded,
      failed: allStepMetrics.failed,
      skipped: allStepMetrics.skipped,
      successRate: allStepMetrics.executed > 0 ? (allStepMetrics.succeeded / allStepMetrics.executed) * 100 : 0,
      sent: allStepMetrics.sent,
      delivered: allStepMetrics.delivered,
      opened: allStepMetrics.opened,
      clicked: allStepMetrics.clicked,
      replied: allStepMetrics.replied,
      bounced: allStepMetrics.bounced,
      openRate: allStepMetrics.delivered > 0 ? (allStepMetrics.opened / allStepMetrics.delivered) * 100 : 0,
      clickRate: allStepMetrics.delivered > 0 ? (allStepMetrics.clicked / allStepMetrics.delivered) * 100 : 0,
      replyRate: allStepMetrics.delivered > 0 ? (allStepMetrics.replied / allStepMetrics.delivered) * 100 : 0,
      exitedAtStep,
      dropoutRate,
      avgExecutionDelay: allStepMetrics.avgDelayMinutes,
    };
  }

  /**
   * Get all step metrics for a sequence.
   */
  async calculateAllStepMetrics(
    context: SecurityContext,
    sequenceId: string,
    dateRange?: DateRange
  ): Promise<StepMetrics[]> {
    const sequenceResult = await this.sequenceRepo.getById(context, sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return [];
    }

    const sequence = sequenceResult.data;
    const metrics: StepMetrics[] = [];

    for (const step of sequence.steps) {
      const stepMetric = await this.calculateStepMetrics(context, sequenceId, step.id, dateRange);
      if (stepMetric) {
        metrics.push(stepMetric);
      }
    }

    return metrics.sort((a, b) => a.stepIndex - b.stepIndex);
  }

  /**
   * Get enrollment funnel data.
   */
  async getEnrollmentFunnel(
    context: SecurityContext,
    sequenceId: string,
    dateRange?: DateRange
  ): Promise<FunnelData> {
    const sequenceResult = await this.sequenceRepo.getById(context, sequenceId);
    if (!sequenceResult.success || !sequenceResult.data) {
      return { sequenceId, sequenceName: '', totalEnrolled: 0, steps: [], overallConversionRate: 0 };
    }

    const sequence = sequenceResult.data;
    const enrollmentsResult = await this.enrollmentRepo.getBySequence(context, sequenceId);
    if (!enrollmentsResult.success || !enrollmentsResult.data) {
      return {
        sequenceId,
        sequenceName: sequence.name,
        totalEnrolled: 0,
        steps: [],
        overallConversionRate: 0,
      };
    }

    let enrollments = enrollmentsResult.data;
    if (dateRange) {
      enrollments = enrollments.filter((e) => isInDateRange(e.createdAt, dateRange));
    }

    const totalEnrolled = enrollments.length;
    const completedTotal = enrollments.filter((e) => e.status === 'completed').length;
    const overallConversionRate = totalEnrolled > 0 ? (completedTotal / totalEnrolled) * 100 : 0;

    const funnelSteps: FunnelStep[] = [];

    for (const step of sequence.steps) {
      // Entered = enrollments that reached or passed this step
      const enteredCount = enrollments.filter(
        (e) => e.currentStepIndex >= step.order || e.stepsCompleted > step.order
      ).length;

      // Completed = enrollments that completed this step
      const completedCount = enrollments.filter((e) => e.stepsCompleted > step.order).length;

      // Exited at this step
      const exitedCount = enrollments.filter(
        (e) =>
          (e.status === 'exited' || e.status === 'bounced' || e.status === 'unsubscribed') &&
          e.currentStepIndex === step.order
      ).length;

      const conversionRate = enteredCount > 0 ? (completedCount / enteredCount) * 100 : 0;
      const dropoffRate = enteredCount > 0 ? (exitedCount / enteredCount) * 100 : 0;

      funnelSteps.push({
        stepId: step.id,
        stepIndex: step.order,
        stepName: getStepName(step),
        stepType: step.type,
        enteredCount,
        completedCount,
        exitedCount,
        conversionRate,
        dropoffRate,
      });
    }

    await this.auditService.logAction(context, {
      action: 'read',
      entityType: 'report',
      entityId: sequenceId,
      metadata: {
        action: 'getEnrollmentFunnel',
        sequenceId,
        stepCount: funnelSteps.length,
      },
    });

    return {
      sequenceId,
      sequenceName: sequence.name,
      totalEnrolled,
      steps: funnelSteps.sort((a, b) => a.stepIndex - b.stepIndex),
      overallConversionRate,
    };
  }

  /**
   * Get time-series data for enrollments.
   */
  async getEnrollmentTrends(
    context: SecurityContext,
    sequenceId: string,
    bucket: 'daily' | 'weekly' | 'monthly',
    dateRange?: DateRange
  ): Promise<TrendData[]> {
    const enrollmentsResult = await this.enrollmentRepo.getBySequence(context, sequenceId);
    if (!enrollmentsResult.success || !enrollmentsResult.data) {
      return [];
    }

    let enrollments = enrollmentsResult.data;
    if (dateRange) {
      enrollments = enrollments.filter((e) => isInDateRange(e.createdAt, dateRange));
    }

    // Group by date bucket
    const buckets = new Map<
      string,
      {
        enrolled: number;
        completed: number;
        exited: number;
        emailsSent: number;
        replies: number;
      }
    >();

    enrollments.forEach((e) => {
      const key = formatDateKey(e.createdAt, bucket);
      const existing = buckets.get(key) || {
        enrolled: 0,
        completed: 0,
        exited: 0,
        emailsSent: 0,
        replies: 0,
      };

      existing.enrolled++;
      existing.emailsSent += e.emailsSent;
      existing.replies += e.repliesReceived;

      // Note: completion/exit dates might differ from enrollment date
      if (e.status === 'completed' && e.completedAt) {
        const completedKey = formatDateKey(e.completedAt, bucket);
        if (completedKey === key) {
          existing.completed++;
        }
      }
      if ((e.status === 'exited' || e.status === 'bounced' || e.status === 'unsubscribed') && e.exitedAt) {
        const exitedKey = formatDateKey(e.exitedAt, bucket);
        if (exitedKey === key) {
          existing.exited++;
        }
      }

      buckets.set(key, existing);
    });

    const trends: TrendData[] = [];
    buckets.forEach((data, date) => {
      trends.push({ date, ...data });
    });

    await this.auditService.logAction(context, {
      action: 'read',
      entityType: 'report',
      entityId: sequenceId,
      metadata: {
        action: 'getEnrollmentTrends',
        sequenceId,
        bucket,
        bucketCount: trends.length,
      },
    });

    return trends.sort((a, b) => a.date.localeCompare(b.date));
  }

  /**
   * Compare performance across sequences.
   */
  async compareSequences(
    context: SecurityContext,
    sequenceIds: string[],
    dateRange?: DateRange
  ): Promise<SequenceComparison[]> {
    const comparisons: SequenceComparison[] = [];

    for (const sequenceId of sequenceIds) {
      const metrics = await this.calculateSequenceMetrics(context, sequenceId, dateRange);
      if (metrics) {
        comparisons.push({
          sequenceId: metrics.sequenceId,
          sequenceName: metrics.sequenceName,
          enrollmentCount: metrics.totalEnrolled,
          completionRate: metrics.completionRate,
          replyRate: metrics.replyRate,
          meetingRate: metrics.meetingBookingRate,
          avgTimeToComplete: metrics.avgTimeToComplete,
        });
      }
    }

    await this.auditService.logAction(context, {
      action: 'read',
      entityType: 'report',
      entityId: 'sequence_comparison',
      metadata: {
        action: 'compareSequences',
        sequenceIds,
        resultCount: comparisons.length,
      },
    });

    return comparisons;
  }

  /**
   * Get best performing send times.
   */
  async getOptimalSendTimes(
    context: SecurityContext,
    sequenceId?: string
  ): Promise<SendTimeAnalysis> {
    // This would analyze email execution data to find patterns
    // For now, return placeholder data structure

    const dayStats: Map<number, { opens: number; replies: number; sent: number }> = new Map();
    const hourStats: Map<number, { opens: number; replies: number; sent: number }> = new Map();

    // Initialize maps
    for (let i = 0; i < 7; i++) {
      dayStats.set(i, { opens: 0, replies: 0, sent: 0 });
    }
    for (let i = 0; i < 24; i++) {
      hourStats.set(i, { opens: 0, replies: 0, sent: 0 });
    }

    // Would need to aggregate email execution data by send time
    // This is a simplified implementation

    const bestDays = Array.from(dayStats.entries())
      .map(([day, stats]) => ({
        day: DAYS[day],
        openRate: stats.sent > 0 ? (stats.opens / stats.sent) * 100 : 0,
        replyRate: stats.sent > 0 ? (stats.replies / stats.sent) * 100 : 0,
      }))
      .sort((a, b) => b.openRate - a.openRate);

    const bestHours = Array.from(hourStats.entries())
      .map(([hour, stats]) => ({
        hour,
        openRate: stats.sent > 0 ? (stats.opens / stats.sent) * 100 : 0,
        replyRate: stats.sent > 0 ? (stats.replies / stats.sent) * 100 : 0,
      }))
      .sort((a, b) => b.openRate - a.openRate);

    const topDay = bestDays[0]?.day || 'Tuesday';
    const topHour = bestHours[0]?.hour || 10;
    const recommendation = `Based on historical data, ${topDay} at ${topHour}:00 shows the highest engagement rates.`;

    await this.auditService.logAction(context, {
      action: 'read',
      entityType: 'report',
      entityId: sequenceId || 'all_sequences',
      metadata: {
        action: 'getOptimalSendTimes',
        sequenceId,
      },
    });

    return {
      bestDays,
      bestHours,
      recommendation,
    };
  }

  // ============================================
  // Dashboard Metrics
  // ============================================

  /**
   * Get summary metrics for all sequences (for dashboard).
   */
  async getDashboardSummary(
    context: SecurityContext,
    dateRange?: DateRange
  ): Promise<{
    totalSequences: number;
    activeSequences: number;
    totalEnrollments: number;
    activeEnrollments: number;
    emailsSentLast30Days: number;
    overallReplyRate: number;
  }> {
    const sequencesResult = await this.sequenceRepo.list(context, {});
    const sequences = sequencesResult.success && sequencesResult.data ? sequencesResult.data : [];

    const activeSequences = sequences.filter((s) => s.status === 'active').length;

    let totalEnrollments = 0;
    let activeEnrollments = 0;
    let totalEmailsSent = 0;
    let totalReplies = 0;

    // Get enrollments for each sequence
    for (const sequence of sequences) {
      const enrollmentsResult = await this.enrollmentRepo.getBySequence(context, sequence.id);
      if (enrollmentsResult.success && enrollmentsResult.data) {
        let enrollments = enrollmentsResult.data;
        if (dateRange) {
          enrollments = enrollments.filter((e) => isInDateRange(e.createdAt, dateRange));
        }

        totalEnrollments += enrollments.length;
        activeEnrollments += enrollments.filter((e) => e.status === 'active').length;
        totalEmailsSent += enrollments.reduce((sum, e) => sum + e.emailsSent, 0);
        totalReplies += enrollments.reduce((sum, e) => sum + e.repliesReceived, 0);
      }
    }

    const overallReplyRate = totalEmailsSent > 0 ? (totalReplies / totalEmailsSent) * 100 : 0;

    return {
      totalSequences: sequences.length,
      activeSequences,
      totalEnrollments,
      activeEnrollments,
      emailsSentLast30Days: totalEmailsSent,
      overallReplyRate,
    };
  }

  /**
   * Get top performing sequences.
   */
  async getTopPerformers(
    context: SecurityContext,
    limit: number = 5,
    sortBy: 'completionRate' | 'replyRate' | 'enrollments' = 'replyRate'
  ): Promise<SequenceComparison[]> {
    const sequencesResult = await this.sequenceRepo.list(context, { status: 'active' });
    if (!sequencesResult.success || !sequencesResult.data) {
      return [];
    }

    const sequenceIds = sequencesResult.data.map((s) => s.id);
    const comparisons = await this.compareSequences(context, sequenceIds);

    // Sort by specified metric
    comparisons.sort((a, b) => {
      switch (sortBy) {
        case 'completionRate':
          return b.completionRate - a.completionRate;
        case 'replyRate':
          return b.replyRate - a.replyRate;
        case 'enrollments':
          return b.enrollmentCount - a.enrollmentCount;
        default:
          return 0;
      }
    });

    return comparisons.slice(0, limit);
  }

  // ============================================
  // Private Helpers
  // ============================================

  private emptySequenceMetrics(
    sequenceId: string,
    sequenceName: string,
    dateRange?: DateRange
  ): SequenceMetrics {
    return {
      sequenceId,
      sequenceName,
      dateRange: dateRange || { start: new Date(0), end: new Date() },
      totalEnrolled: 0,
      activeEnrollments: 0,
      completedCount: 0,
      exitedCount: 0,
      completionRate: 0,
      exitReasons: {},
      emailsSent: 0,
      emailsDelivered: 0,
      deliveryRate: 0,
      emailsOpened: 0,
      openRate: 0,
      emailsClicked: 0,
      clickRate: 0,
      emailsReplied: 0,
      replyRate: 0,
      emailsBounced: 0,
      bounceRate: 0,
      tasksCreated: 0,
      tasksCompleted: 0,
      taskCompletionRate: 0,
      avgTimeToComplete: 0,
      avgTimeToReply: 0,
      avgTimeToExit: 0,
      meetingsBooked: 0,
      meetingBookingRate: 0,
      dealsCreated: 0,
      dealConversionRate: 0,
      revenueInfluenced: 0,
      calculatedAt: new Date(),
    };
  }

  private emptyStepMetrics(stepId: string, step: SequenceStep): StepMetrics {
    return {
      stepId,
      stepIndex: step.order,
      stepType: step.type,
      stepName: getStepName(step),
      executed: 0,
      succeeded: 0,
      failed: 0,
      skipped: 0,
      successRate: 0,
      sent: 0,
      delivered: 0,
      opened: 0,
      clicked: 0,
      replied: 0,
      bounced: 0,
      openRate: 0,
      clickRate: 0,
      replyRate: 0,
      exitedAtStep: 0,
      dropoutRate: 0,
      avgExecutionDelay: 0,
    };
  }

  private async getExecutionStats(
    context: SecurityContext,
    _sequenceId: string,
    enrollments: SequenceEnrollment[]
  ): Promise<{
    delivered: number;
    bounced: number;
    avgTimeToFirstReply: number;
  }> {
    let delivered = 0;
    let bounced = 0;
    let totalTimeToReply = 0;
    let replyCount = 0;

    for (const enrollment of enrollments) {
      const executionsResult = await this.executionRepo.getByEnrollment(context, enrollment.id);
      if (executionsResult.success && executionsResult.data) {
        for (const exec of executionsResult.data) {
          if (exec.emailMetrics) {
            if (exec.emailMetrics.delivered) delivered++;
            if (exec.emailMetrics.bounced) bounced++;
            if (exec.emailMetrics.replied && exec.emailMetrics.repliedAt && exec.executedAt) {
              totalTimeToReply += daysBetween(exec.executedAt, exec.emailMetrics.repliedAt);
              replyCount++;
            }
          }
        }
      }
    }

    return {
      delivered,
      bounced,
      avgTimeToFirstReply: replyCount > 0 ? totalTimeToReply / replyCount : 0,
    };
  }

  private async aggregateStepExecutions(
    context: SecurityContext,
    enrollments: SequenceEnrollment[],
    stepId: string,
    dateRange?: DateRange
  ): Promise<{
    executed: number;
    succeeded: number;
    failed: number;
    skipped: number;
    sent: number;
    delivered: number;
    opened: number;
    clicked: number;
    replied: number;
    bounced: number;
    avgDelayMinutes: number;
  }> {
    const result = {
      executed: 0,
      succeeded: 0,
      failed: 0,
      skipped: 0,
      sent: 0,
      delivered: 0,
      opened: 0,
      clicked: 0,
      replied: 0,
      bounced: 0,
      avgDelayMinutes: 0,
    };

    let totalDelayMinutes = 0;
    let delayCount = 0;

    for (const enrollment of enrollments) {
      const execResult = await this.executionRepo.getByStep(context, enrollment.id, stepId);
      if (execResult.success && execResult.data) {
        const exec = execResult.data;

        if (dateRange && !isInDateRange(exec.createdAt, dateRange)) {
          continue;
        }

        result.executed++;

        if (exec.status === 'completed') result.succeeded++;
        else if (exec.status === 'failed') result.failed++;
        else if (exec.status === 'skipped') result.skipped++;

        if (exec.stepType === 'email') {
          result.sent++;
          if (exec.emailMetrics) {
            if (exec.emailMetrics.delivered) result.delivered++;
            if (exec.emailMetrics.opened) result.opened++;
            if (exec.emailMetrics.clicked) result.clicked++;
            if (exec.emailMetrics.replied) result.replied++;
            if (exec.emailMetrics.bounced) result.bounced++;
          }
        }

        if (exec.executedAt && exec.scheduledAt) {
          const delayMs = exec.executedAt.getTime() - exec.scheduledAt.getTime();
          totalDelayMinutes += delayMs / (1000 * 60);
          delayCount++;
        }
      }
    }

    result.avgDelayMinutes = delayCount > 0 ? totalDelayMinutes / delayCount : 0;

    return result;
  }
}

// ============================================
// Singleton Instance
// ============================================

let serviceInstance: SequenceAnalyticsService | null = null;

export function getSequenceAnalyticsService(): SequenceAnalyticsService {
  if (!serviceInstance) {
    serviceInstance = new SequenceAnalyticsService();
  }
  return serviceInstance;
}
