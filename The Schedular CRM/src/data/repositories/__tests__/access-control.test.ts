import { describe, expect, it } from 'vitest';

import {
  applyOwnershipDefaults,
  canReadShareable,
  canDeleteShareable,
  canWriteShareable,
  getShareableAccessMeta,
  sanitizeSensitiveFields,
  stripUnauthorizedOwnershipUpdates,
  type ShareableEntity,
} from '../access-control';
import type { SecurityContext } from '../repository-types';
import { getShareableAccessSummary } from '../../../lib/security-context';

const staffContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-staff',
  userName: 'Staff User',
  userRole: 'staff',
  teamIds: ['team-a'],
  managedTeamIds: [],
};

const managerContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-manager',
  userName: 'Manager User',
  userRole: 'manager',
  teamIds: [],
  managedTeamIds: ['team-b'],
};

const adminContext: SecurityContext = {
  businessId: 'biz-1',
  userId: 'user-admin',
  userName: 'Admin User',
  userRole: 'admin',
  teamIds: [],
  managedTeamIds: [],
};

const shareableEntity: ShareableEntity & { valueCents: number; notes: string } = {
  ownerId: 'owner-1',
  ownerName: 'Owner',
  teamIds: ['team-b'],
  visibility: 'team',
  valueCents: 5000,
  notes: 'sensitive',
};

describe('access-control shareable permissions', () => {
  it('denies read/write to staff outside teams unless org-visible', () => {
    expect(canReadShareable(staffContext, shareableEntity)).toBe(false);
    expect(canWriteShareable(staffContext, shareableEntity)).toBe(false);

    expect(
      canReadShareable(staffContext, { ...shareableEntity, visibility: 'org' })
    ).toBe(true);
  });

  it('strips sensitive fields for non-privileged team members', () => {
    const entity = { ...shareableEntity, teamIds: ['team-a'] };
    const sanitized = sanitizeSensitiveFields(staffContext, entity, ['valueCents', 'notes']);

    expect(sanitized.valueCents).toBeUndefined();
    expect(sanitized.notes).toBeUndefined();
  });

  it('allows managers with managed team access to view sensitive fields', () => {
    const sanitized = sanitizeSensitiveFields(managerContext, shareableEntity, ['valueCents', 'notes']);

    expect(sanitized.valueCents).toBe(5000);
    expect(sanitized.notes).toBe('sensitive');
    expect(canReadShareable(managerContext, shareableEntity)).toBe(true);
    expect(canWriteShareable(managerContext, shareableEntity)).toBe(true);
  });

  it('prevents managers from deleting shareable entities', () => {
    expect(canDeleteShareable(managerContext, shareableEntity)).toBe(false);
    expect(canDeleteShareable(adminContext, shareableEntity)).toBe(true);
  });

  it('applies ownership defaults for staff when overriding is not allowed', () => {
    const result = applyOwnershipDefaults(staffContext, {
      ...shareableEntity,
      ownerId: 'other-owner',
      teamIds: ['team-x'],
      visibility: 'org',
    });

    expect(result.ownerId).toBe(staffContext.userId);
    expect(result.ownerName).toBe(staffContext.userName);
    expect(result.teamIds).toContain('team-a');
    expect(result.teamIds).not.toContain('team-x');
    expect(result.visibility).toBe('team');
  });

  it('honors explicit ownership/sharing for org-privileged users', () => {
    const result = applyOwnershipDefaults(adminContext, {
      ...shareableEntity,
      ownerId: 'delegate-owner',
      ownerName: 'Delegate',
      teamIds: ['team-x'],
      visibility: 'org',
    });

    expect(result.ownerId).toBe('delegate-owner');
    expect(result.ownerName).toBe('Delegate');
    expect(result.teamIds).toContain('team-x');
    expect(result.visibility).toBe('org');
  });

  it('returns consolidated access metadata for managers with managed teams', () => {
    const meta = getShareableAccessMeta(managerContext, shareableEntity);

    expect(meta.canRead).toBe(true);
    expect(meta.canWrite).toBe(true);
    expect(meta.canDelete).toBe(false);
    expect(meta.canChangeOwnership).toBe(false);
    expect(meta.hasManagerAccess).toBe(true);
    expect(meta.effectiveTeams).toContain('team-b');
  });

  it('surfaces read-only org visibility for staff outside team scope', () => {
    const meta = getShareableAccessMeta(staffContext, { ...shareableEntity, visibility: 'org' });

    expect(meta.canRead).toBe(true);
    expect(meta.canWrite).toBe(false);
    expect(meta.canDelete).toBe(false);
    expect(meta.hasTeamAccess).toBe(false);
  });

  it('strips ownership reassignment for non-admin users while preserving manager sharing', () => {
    const updates = {
      ownerId: 'new-owner',
      ownerName: 'New Owner',
      teamIds: ['team-c'],
      visibility: 'org' as const,
    };

    const managerSanitized = stripUnauthorizedOwnershipUpdates(managerContext, updates, shareableEntity);
    expect(managerSanitized.ownerId).toBeUndefined();
    expect(managerSanitized.ownerName).toBeUndefined();
    expect(managerSanitized.teamIds).toEqual(updates.teamIds);
    expect(managerSanitized.visibility).toBe(updates.visibility);

    const staffSanitized = stripUnauthorizedOwnershipUpdates(staffContext, updates, shareableEntity);
    expect(staffSanitized.ownerId).toBeUndefined();
    expect(staffSanitized.ownerName).toBeUndefined();
    expect(staffSanitized.teamIds).toBeUndefined();
    expect(staffSanitized.visibility).toBeUndefined();
  });

  it('summarizes access metadata for org-visible records for staff outside teams', () => {
    const summary = getShareableAccessSummary(staffContext, {
      ...shareableEntity,
      visibility: 'org',
    });

    expect(summary.visibility).toBe('org');
    expect(summary.canRead).toBe(true);
    expect(summary.canWrite).toBe(false);
    expect(summary.canDelete).toBe(false);
    expect(summary.isOwner).toBe(false);
    expect(summary.hasTeamAccess).toBe(false);
  });

  it('redacts sensitive fields for staff outside teams but preserves for managers', () => {
    const entity = { ...shareableEntity, teamIds: ['team-b'] };
    const staffSanitized = sanitizeSensitiveFields(staffContext, entity, ['valueCents', 'notes']);
    expect(staffSanitized.valueCents).toBeUndefined();
    expect(staffSanitized.notes).toBeUndefined();

    const managerSanitized = sanitizeSensitiveFields(managerContext, entity, ['valueCents', 'notes']);
    expect(managerSanitized.valueCents).toBe(5000);
    expect(managerSanitized.notes).toBe('sensitive');
  });
});
