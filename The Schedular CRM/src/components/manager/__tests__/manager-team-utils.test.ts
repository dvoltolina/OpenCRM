import { describe, expect, it } from 'vitest';
import { buildBulkReassignAuditEntries } from '../manager-team-utils';

describe('buildBulkReassignAuditEntries', () => {
  it('creates audit entries per entity type with sanitized scope', () => {
    const entries = buildBulkReassignAuditEntries({
      deals: 2,
      leads: 1,
      activities: 0,
      targetAssigneeId: 'user-123',
      targetTeamId: ' team-1 ',
      scopedTeams: ['team-1', 'team-1', ' team-2 '],
      maxPerEntity: 50,
    });

    expect(entries).toHaveLength(2);

    const dealEntry = entries.find((entry) => entry.entityType === 'deal');
    expect(dealEntry?.metadata).toMatchObject({
      category: 'managerBulkReassign',
      updatedCount: 2,
      targetAssigneeId: 'user-123',
      targetTeamId: 'team-1',
      scopedTeamIds: ['team-1', 'team-2'],
      maxPerEntity: 50,
      source: 'managerTeamPanel',
    });

    const leadEntry = entries.find((entry) => entry.entityType === 'lead');
    expect(leadEntry?.metadata).toMatchObject({
      updatedCount: 1,
    });
  });

  it('omits optional targets and returns empty when nothing updated', () => {
    const empty = buildBulkReassignAuditEntries({
      deals: 0,
      leads: 0,
      activities: 0,
      scopedTeams: [],
      maxPerEntity: 25,
    });
    expect(empty).toHaveLength(0);

    const activityOnly = buildBulkReassignAuditEntries({
      deals: 0,
      leads: 0,
      activities: 3,
      scopedTeams: ['team-a'],
      maxPerEntity: 25,
    });

    expect(activityOnly).toHaveLength(1);
    expect(activityOnly[0].entityType).toBe('activity');
    expect(activityOnly[0].metadata).not.toHaveProperty('targetAssigneeId');
    expect(activityOnly[0].metadata).not.toHaveProperty('targetTeamId');
    expect(activityOnly[0].metadata).toMatchObject({
      scopedTeamIds: ['team-a'],
    });
  });
});
