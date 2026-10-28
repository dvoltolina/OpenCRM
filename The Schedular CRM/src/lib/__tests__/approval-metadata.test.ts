import { describe, expect, it } from 'vitest';
import { buildApprovalMetadata } from '../approval-metadata';

describe('buildApprovalMetadata', () => {
  it('merges context team scopes and normalizes fields', () => {
    const meta = buildApprovalMetadata({
      requestType: 'discount override',
      decision: 'approved',
      sourceAuditId: 'abc',
      teamIds: ['team-a'],
      contextTeamIds: ['team-a', 'team-b'],
      managedTeamIds: ['team-m1'],
      contextManagedTeamIds: ['team-m2'],
    });

    expect(meta.approvalType).toBe('discount override');
    expect(meta.requestType).toBe('discount override');
    expect(meta.status).toBe('approved');
    expect(meta.teamIds).toEqual(['team-a', 'team-b']);
    expect(meta.managedTeamIds).toEqual(['team-m1', 'team-m2']);
    expect(meta.sourceAuditId).toBe('abc');
  });

  it('falls back to approval defaults when request type is missing', () => {
    const meta = buildApprovalMetadata({});
    expect(meta.approvalType).toBe('approval');
    expect(meta.requestType).toBe('approval');
    expect(meta.status).toBe('pending');
  });
});
