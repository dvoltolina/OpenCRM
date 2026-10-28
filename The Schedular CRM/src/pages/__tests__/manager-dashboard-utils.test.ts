import { describe, expect, it } from 'vitest';
import type { AuditEntry } from '../../types/audit';
import type { Deal, Lead, SalesActivity, Stage } from '../../types/models';
import {
  buildApprovalRequests,
  buildOverdueSla,
  calculateConversionSummary,
  filterApprovals,
  filterActivitiesForManager,
  filterDealsForManager,
  filterLeadsForManager,
  computeWinLossSummary,
  computeWeightedForecast,
  computeWinRateTrend,
  summarizeStages,
} from '../manager-dashboard-utils';

const baseFilters = {
  selectedTeams: ['team-a'],
  enforceTeamScope: true,
};

describe('manager-dashboard-utils', () => {
  it('filters deals by team and pipeline', () => {
    const deals: Deal[] = [
      {
        id: '1',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Deal A',
        valueCents: 1000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date(),
      },
      {
        id: '2',
        pipelineId: 'p2',
        stageId: 's2',
        title: 'Deal B',
        valueCents: 2000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
        teamIds: ['team-b'],
        createdAt: new Date(),
      },
    ];

    const filtered = filterDealsForManager(deals, { ...baseFilters, pipelineId: 'p1' });
    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe('1');
  });

  it('filters leads by assignee and date range', () => {
    const leads: Lead[] = [
      {
        id: 'l1',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        status: 'new',
        source: 'website',
        tags: [],
        createdAt: new Date('2025-01-01'),
        teamIds: ['team-a'],
      },
      {
        id: 'l2',
        firstName: 'John',
        lastName: 'Smith',
        email: 'john@example.com',
        status: 'converted',
        source: 'referral',
        tags: [],
        createdAt: new Date('2024-01-01'),
        assigneeId: 'assignee-1',
        teamIds: ['team-a'],
      },
    ];

    const range = { start: new Date('2024-12-01'), end: new Date('2025-02-01') };
    const filtered = filterLeadsForManager(leads, {
      ...baseFilters,
      assigneeId: 'assignee-1',
      dateRange: range,
    });

    expect(filtered).toHaveLength(0);

    const conversion = calculateConversionSummary(leads, range);
    expect(conversion.totalLeads).toBe(1);
    expect(conversion.conversionRate).toBe(0);
  });

  it('summarizes stages for open deals', () => {
    const stages: Stage[] = [
      { id: 's1', pipelineId: 'p1', name: 'Stage 1', order: 1, colorHex: '#000', probability: 10, isActive: true, teamIds: [], visibility: 'team', createdAt: new Date() },
    ];
    const deals: Deal[] = [
      {
        id: '1',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Deal A',
        valueCents: 5000,
        currency: 'USD',
        probability: 50,
        status: 'open',
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date(),
      },
    ];

    const summary = summarizeStages(deals, stages);
    expect(summary[0].valueCents).toBe(5000);
    expect(summary[0].count).toBe(1);
  });

  it('builds overdue SLA rows grouped by assignee', () => {
    const now = new Date();
    const tasks: SalesActivity[] = [
      {
        id: 't1',
        type: 'task',
        title: 'Overdue',
        isCompleted: false,
        dueDate: new Date(now.getTime() - 1000),
        teamIds: ['team-a'],
        createdById: 'u1',
        createdByName: 'User',
        createdAt: now,
      },
      {
        id: 't2',
        type: 'task',
        title: 'Future',
        isCompleted: false,
        dueDate: new Date(now.getTime() + 10000),
        teamIds: ['team-a'],
        createdById: 'u1',
        createdByName: 'User',
        createdAt: now,
      },
    ];

    const rows = buildOverdueSla(tasks, baseFilters);
    expect(rows).toHaveLength(1);
    expect(rows[0].overdueCount).toBe(1);
  });

  it('filters activities by team scope and date', () => {
    const now = new Date();
    const activities: SalesActivity[] = [
      {
        id: 'a1',
        type: 'task',
        title: 'Task A',
        isCompleted: false,
        createdAt: now,
        createdById: 'u1',
        createdByName: 'User',
        teamIds: ['team-a'],
      },
      {
        id: 'a2',
        type: 'task',
        title: 'Task B',
        isCompleted: false,
        createdAt: now,
        createdById: 'u1',
        createdByName: 'User',
        teamIds: ['team-b'],
      },
    ];

    const filtered = filterActivitiesForManager(activities, {
      ...baseFilters,
      dateRange: { start: new Date(now.getTime() - 1000), end: new Date(now.getTime() + 1000) },
    });

    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe('a1');
  });

  it('filters approvals and fails closed without team metadata', () => {
    const entries: AuditEntry[] = [
      {
        id: 'a1',
        businessId: 'b1',
        userId: 'u1',
        userName: 'User',
        action: 'update',
        entityType: 'deal',
        entityId: 'd1',
        timestamp: new Date(),
        createdAt: new Date(),
        metadata: { category: 'approval', teamIds: ['team-a'] },
      },
      {
        id: 'a2',
        businessId: 'b1',
        userId: 'u2',
        userName: 'Other',
        action: 'update',
        entityType: 'deal',
        entityId: 'd2',
        timestamp: new Date(),
        createdAt: new Date(),
        metadata: { category: 'approval' },
      },
    ];

    const filtered = filterApprovals(entries, baseFilters);
    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe('a1');
  });

  it('derives approval request metadata from audit entries only', () => {
    const entries: AuditEntry[] = [
      {
        id: 'a1',
        businessId: 'b1',
        userId: 'u1',
        userName: 'User',
        action: 'update',
        entityType: 'deal',
        entityId: 'd1',
        timestamp: new Date(),
        createdAt: new Date(),
        metadata: { approvalType: 'discount', status: 'approved', teamIds: ['team-a'] },
      },
      {
        id: 'a2',
        businessId: 'b1',
        userId: 'u2',
        userName: 'Other',
        action: 'update',
        entityType: 'deal',
        entityId: 'd2',
        timestamp: new Date(),
        createdAt: new Date(),
        metadata: { requestType: 'price override', decision: 'deny', teamIds: ['team-a'] },
      },
      {
        id: 'a3',
        businessId: 'b1',
        userId: 'u3',
        userName: 'Missing Team',
        action: 'update',
        entityType: 'deal',
        entityId: 'd3',
        timestamp: new Date(),
        createdAt: new Date(),
        metadata: { requestType: 'approval-without-team' },
      },
    ];

    const requests = buildApprovalRequests(entries, baseFilters);
    expect(requests).toHaveLength(2);
    expect(requests[0].requestType).toBe('discount');
    expect(requests[0].status).toBe('approved');
    expect(requests[1].status).toBe('denied');
  });

  it('computes win/loss summary within range', () => {
    const deals: Deal[] = [
      {
        id: 'd1',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Won Deal',
        valueCents: 10000,
        currency: 'USD',
        probability: 90,
        status: 'won',
        closedAt: new Date('2025-01-15'),
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date('2024-12-01'),
      },
      {
        id: 'd2',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Lost Deal',
        valueCents: 5000,
        currency: 'USD',
        probability: 20,
        status: 'lost',
        closedAt: new Date('2025-02-01'),
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date('2024-12-01'),
      },
    ];

    const summary = computeWinLossSummary(deals, {
      start: new Date('2025-01-01'),
      end: new Date('2025-01-31'),
    });

    expect(summary.wonCount).toBe(1);
    expect(summary.lostCount).toBe(0);
    expect(summary.winRate).toBe(100);
    expect(summary.wonValueCents).toBe(10000);
    expect(summary.lostValueCents).toBe(0);
  });

  it('computes weighted forecast for open deals', () => {
    const deals: Deal[] = [
      {
        id: 'd1',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Open High Prob',
        valueCents: 20000,
        currency: 'USD',
        probability: 80,
        status: 'open',
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date(),
      },
      {
        id: 'd2',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Open Low Prob',
        valueCents: 10000,
        currency: 'USD',
        probability: 20,
        status: 'open',
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date(),
      },
    ];

    const forecast = computeWeightedForecast(deals);
    expect(forecast).toBeCloseTo(20000 * 0.8 + 10000 * 0.2);
  });

  it('builds win rate trend by month', () => {
    const deals: Deal[] = [
      {
        id: 'd1',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Won Jan',
        valueCents: 1000,
        currency: 'USD',
        probability: 100,
        status: 'won',
        closedAt: new Date('2025-01-15'),
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date('2025-01-01'),
      },
      {
        id: 'd2',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Lost Jan',
        valueCents: 1000,
        currency: 'USD',
        probability: 0,
        status: 'lost',
        closedAt: new Date('2025-01-20'),
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date('2025-01-01'),
      },
      {
        id: 'd3',
        pipelineId: 'p1',
        stageId: 's1',
        title: 'Won Feb',
        valueCents: 1000,
        currency: 'USD',
        probability: 0,
        status: 'won',
        closedAt: new Date('2025-02-05'),
        tags: [],
        teamIds: ['team-a'],
        createdAt: new Date('2025-02-01'),
      },
    ];

    const trend = computeWinRateTrend(deals, undefined, 'month');
    expect(trend).toHaveLength(2);
    const jan = trend.find((t) => t.bucketLabel === '2025-01');
    const feb = trend.find((t) => t.bucketLabel === '2025-02');
    expect(jan?.won).toBe(1);
    expect(jan?.lost).toBe(1);
    expect(jan?.winRate).toBe(50);
    expect(feb?.winRate).toBe(100);
  });
});
