import { sanitizeTeamIds } from '../../lib/security-context';
import type { AuditEntityType } from '../../types/audit';

export interface BulkReassignCounts {
  deals: number;
  leads: number;
  activities: number;
}

export interface BulkReassignAuditEntry {
  entityType: AuditEntityType;
  metadata: Record<string, unknown>;
}

interface BuildAuditEntriesParams extends BulkReassignCounts {
  targetAssigneeId?: string;
  targetTeamId?: string;
  scopedTeams: string[];
  maxPerEntity: number;
}

const ENTITY_MAP: Array<{ key: keyof BulkReassignCounts; type: AuditEntityType }> = [
  { key: 'deals', type: 'deal' },
  { key: 'leads', type: 'lead' },
  { key: 'activities', type: 'activity' },
];

/**
 * Build audit entries for bulk manager reassign actions without logging PHI.
 * Counts are recorded per entity type with scoped team IDs and target metadata.
 */
export function buildBulkReassignAuditEntries(
  params: BuildAuditEntriesParams
): BulkReassignAuditEntry[] {
  const scopedTeamIds = sanitizeTeamIds(params.scopedTeams);
  const targetTeamId = sanitizeTeamIds(
    params.targetTeamId ? [params.targetTeamId] : []
  )[0];

  const entries: BulkReassignAuditEntry[] = [];

  ENTITY_MAP.forEach(({ key, type }) => {
    const count = params[key];
    if (!count) return;

    const metadata: Record<string, unknown> = {
      category: 'managerBulkReassign',
      updatedCount: count,
      scopedTeamIds,
      maxPerEntity: params.maxPerEntity,
      source: 'managerTeamPanel',
    };

    if (params.targetAssigneeId) {
      metadata.targetAssigneeId = params.targetAssigneeId;
    }
    if (targetTeamId) {
      metadata.targetTeamId = targetTeamId;
    }

    entries.push({
      entityType: type,
      metadata,
    });
  });

  return entries;
}
