import { describe, expect, it } from 'vitest';

import { filterAuditEntriesForContext } from '../audit-repository';
import type { SecurityContext } from '../repository-types';
import type { AuditEntry } from '../../../types/audit';

function buildEntry(
  id: string,
  overrides: Partial<AuditEntry> = {}
): AuditEntry {
  return {
    id,
    businessId: 'biz-1',
    userId: 'user-1',
    userName: 'User One',
    action: 'update',
    entityType: 'deal',
    entityId: 'deal-1',
    timestamp: new Date('2025-01-01T00:00:00Z'),
    createdAt: new Date('2025-01-01T00:00:00Z'),
    ...overrides,
  };
}

const managerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'manager-1',
  userName: 'Manager',
  userRole: 'manager',
  teamIds: [],
  managedTeamIds: ['team-a'],
};

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'admin-1',
  userName: 'Admin',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'staff-1',
  userName: 'Staff',
  userRole: 'staff',
  teamIds: ['team-b'],
  managedTeamIds: [],
};

describe('filterAuditEntriesForContext', () => {
  it('allows org-privileged roles to see all entries', () => {
    const entries = [
      buildEntry('1', { metadata: { teamIds: ['team-a'] } }),
      buildEntry('2', { metadata: { teamIds: ['team-b'] }, userId: 'user-2' }),
      buildEntry('3', { metadata: {} }),
    ];

    const result = filterAuditEntriesForContext(adminContext, entries);
    expect(result).toHaveLength(3);
  });

  it('scopes managers to managedTeamIds and fails closed without metadata', () => {
    const entries = [
      buildEntry('1', { metadata: { teamIds: ['team-a'] }, userId: managerContext.userId }),
      buildEntry('2', { metadata: { teamIds: ['team-b'] }, userId: 'user-2' }),
      buildEntry('3', { metadata: {}, userId: 'user-3' }),
    ];

    const result = filterAuditEntriesForContext(managerContext, entries);
    expect(result.map((e) => e.id)).toEqual(['1']);
  });

  it('returns empty set for managers missing managed team claims', () => {
    const missingTeamsContext: SecurityContext = { ...managerContext, managedTeamIds: [] };
    const entries = [buildEntry('1', { metadata: { teamIds: ['team-a'] } })];

    const result = filterAuditEntriesForContext(missingTeamsContext, entries);
    expect(result).toHaveLength(0);
  });

  it('limits staff to their own entries only', () => {
    const entries = [
      buildEntry('1', { metadata: { teamIds: ['team-b'] }, userId: staffContext.userId }),
      buildEntry('2', { metadata: { teamIds: ['team-b'] }, userId: 'other-user' }),
      buildEntry('3', { metadata: { teamIds: ['team-a'] }, userId: 'other-user' }),
    ];

    const result = filterAuditEntriesForContext(staffContext, entries);
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('1');
  });
});

