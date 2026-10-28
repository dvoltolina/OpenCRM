import { describe, expect, it } from 'vitest';
import type { CRMUser, ReportView } from '../../types/models';
import { filterViewsForClient } from '../useReportViews';

const baseView = (overrides: Partial<ReportView>): ReportView => ({
  id: overrides.id || 'view-1',
  name: overrides.name || 'View',
  description: overrides.description,
  filters: overrides.filters || {},
  ownerId: overrides.ownerId || 'owner-1',
  ownerName: overrides.ownerName || 'Owner',
  teamIds: overrides.teamIds || [],
  visibility: overrides.visibility,
  createdAt: overrides.createdAt || new Date(),
  updatedAt: overrides.updatedAt,
});

const staffUser: CRMUser = {
  id: 'staff-1',
  email: 'staff@example.com',
  displayName: 'Staff',
  role: 'staff',
  businessId: 'biz-1',
  createdAt: new Date(),
  providerId: 'password',
  clientId: 'client',
  crmRole: 'viewer',
  teamIds: ['team-a'],
  managedTeamIds: [],
};

const managerUser: CRMUser = {
  ...staffUser,
  id: 'manager-1',
  displayName: 'Manager',
  role: 'manager',
  teamIds: [],
  managedTeamIds: ['team-b'],
};

const adminUser: CRMUser = {
  ...staffUser,
  id: 'admin-1',
  displayName: 'Admin',
  role: 'admin',
};

describe('filterViewsForClient', () => {
  it('returns only owned or shared views for staff', () => {
    const views = [
      baseView({ id: 'own', ownerId: staffUser.id, teamIds: [] }),
      baseView({ id: 'shared', ownerId: 'teammate', teamIds: ['team-a'] }),
      baseView({ id: 'blocked', ownerId: 'other', teamIds: ['team-b'] }),
    ];

    const filtered = filterViewsForClient(views, staffUser);
    expect(filtered.map((v) => v.id)).toEqual(['own', 'shared']);
  });

  it('allows managers to read views for managed teams even when not direct team members', () => {
    const views = [
      baseView({ id: 'managed', ownerId: 'teammate', teamIds: ['team-b'] }),
      baseView({ id: 'unrelated', ownerId: 'other', teamIds: ['team-c'] }),
    ];

    const filtered = filterViewsForClient(views, managerUser);
    expect(filtered.map((v) => v.id)).toEqual(['managed']);
  });

  it('allows admins to see all views without client-side filtering', () => {
    const views = [
      baseView({ id: 'one', teamIds: ['team-a'] }),
      baseView({ id: 'two', teamIds: [] }),
    ];

    const filtered = filterViewsForClient(views, adminUser);
    expect(filtered).toHaveLength(2);
  });
});
