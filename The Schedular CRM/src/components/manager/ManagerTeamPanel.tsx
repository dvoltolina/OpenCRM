import { useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useDeals, useLeads, usePendingTasks, useTeamMembers } from '../../hooks';
import { useDealMutations } from '../../hooks/useDealMutations';
import { useLeadMutations } from '../../hooks/useLeadMutations';
import { useActivityLog } from '../../hooks/useActivityLog';
import type { SalesActivity } from '../../types/models';
import type { TeamMember } from '../../hooks/useTeamMembers';
import { AuditLogService } from '../../services/AuditLogService';
import {
  filterActivitiesForManager,
  filterDealsForManager,
  filterLeadsForManager,
  type ManagerDashboardFilters,
} from '../../pages/manager-dashboard-utils';
import {
  createSecurityContextFromParams,
  sanitizeTeamIds,
} from '../../lib/security-context';
import { buildBulkReassignAuditEntries } from './manager-team-utils';
import { Button, Card } from '../ui';

interface ManagerTeamPanelProps {
  managedTeams: string[];
  userTeams: string[];
  enforceTeamScope: boolean;
}

const MAX_REASSIGN = 50;

function formatMemberName(member: TeamMember | undefined) {
  if (!member) return 'Unassigned';
  const fullName = `${member.firstName ?? ''} ${member.lastName ?? ''}`.trim();
  return fullName || member.email || member.id;
}

export function ManagerTeamPanel({
  managedTeams,
  userTeams,
  enforceTeamScope,
}: ManagerTeamPanelProps) {
  const { crmUser, businessId } = useAuth();
  const { deals, isLoading: dealsLoading } = useDeals();
  const { leads, isLoading: leadsLoading } = useLeads();
  const { tasks, isLoading: tasksLoading, refresh: refreshTasks } = usePendingTasks(undefined, 150);
  const { members, isLoading: membersLoading } = useTeamMembers();
  const { updateDeal } = useDealMutations();
  const { bulkAssign, updateLead } = useLeadMutations();
  const { updateActivity } = useActivityLog();
  const auditLogService = useMemo(() => new AuditLogService(), []);

  const baseTeams = managedTeams.length > 0 ? managedTeams : userTeams;

  const [teamSelection, setTeamSelection] = useState<string>(
    baseTeams.length > 1 ? 'all' : baseTeams[0] || 'all'
  );
  const [assigneeFilter, setAssigneeFilter] = useState<string>('all');
  const [targetAssigneeId, setTargetAssigneeId] = useState<string>('');
  const [targetTeamId, setTargetTeamId] = useState<string>('');
  const [applyDeals, setApplyDeals] = useState(true);
  const [applyLeads, setApplyLeads] = useState(true);
  const [applyTasks, setApplyTasks] = useState(true);
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const selectedTeams = useMemo(() => {
    if (teamSelection === 'all') return baseTeams;
    return sanitizeTeamIds([teamSelection]);
  }, [baseTeams, teamSelection]);

  const filters: ManagerDashboardFilters = useMemo(
    () => ({
      selectedTeams,
      assigneeId: assigneeFilter === 'all' ? undefined : assigneeFilter,
      enforceTeamScope,
    }),
    [assigneeFilter, enforceTeamScope, selectedTeams]
  );

  const scopedDeals = useMemo(
    () => filterDealsForManager(deals, filters).slice(0, MAX_REASSIGN),
    [deals, filters]
  );
  const scopedLeads = useMemo(
    () => filterLeadsForManager(leads, filters).slice(0, MAX_REASSIGN),
    [filters, leads]
  );
  const scopedTasks = useMemo<SalesActivity[]>(
    () => filterActivitiesForManager(tasks, filters).slice(0, MAX_REASSIGN),
    [filters, tasks]
  );

  const roster = useMemo(() => {
    const scoped = members.filter((member) => {
      if (teamSelection === 'all') return true;
      const memberTeams = sanitizeTeamIds(member.teamIds || []);
      return memberTeams.includes(teamSelection);
    });
    return scoped.length ? scoped : members;
  }, [members, teamSelection]);

  const assigneeOptions = useMemo(
    () =>
      roster.map((member) => ({
        id: member.id,
        label: `${formatMemberName(member)} (${member.role})`,
      })),
    [roster]
  );

  const targetAssignee = useMemo(
    () => members.find((member) => member.id === targetAssigneeId),
    [members, targetAssigneeId]
  );

  const loading = dealsLoading || leadsLoading || tasksLoading || membersLoading;

  const canOperate = !enforceTeamScope || managedTeams.length > 0;

  const onReassign = async () => {
    if (!canOperate) {
      setError('Managed team claims are missing. Cannot perform updates.');
      return;
    }
    if (!applyDeals && !applyLeads && !applyTasks) {
      setError('Select at least one entity type to reassign.');
      return;
    }
    if (!targetAssigneeId && !targetTeamId) {
      setError('Choose a target assignee or team to apply.');
      return;
    }

    const auditContext =
      crmUser && businessId
        ? createSecurityContextFromParams(
            businessId,
            crmUser.id,
            crmUser.displayName || crmUser.email || 'Unknown User',
            crmUser.role,
            sanitizeTeamIds(crmUser.teamIds || []),
            sanitizeTeamIds(crmUser.managedTeamIds || []),
            crmUser.managerId
          )
        : null;

    if (!auditContext) {
      setError('Audit context unavailable. Please refresh and try again.');
      return;
    }

    setStatus(null);
    setError(null);
    setIsSaving(true);

    const assigneeName = formatMemberName(targetAssignee);
    const updated = {
      deals: new Set<string>(),
      leads: new Set<string>(),
      activities: new Set<string>(),
    };

    try {
      if (applyLeads && scopedLeads.length > 0) {
        if (targetTeamId) {
          for (const lead of scopedLeads) {
            await updateLead(lead.id, { teamIds: sanitizeTeamIds([targetTeamId]) });
            updated.leads.add(lead.id);
          }
        }
        if (targetAssigneeId) {
          const result = await bulkAssign(
            scopedLeads.map((lead) => lead.id),
            targetAssigneeId,
            assigneeName
          );
          if (result.successCount > 0) {
            scopedLeads.forEach((lead) => updated.leads.add(lead.id));
          }
        }
      }

      if (applyDeals && scopedDeals.length > 0) {
        for (const deal of scopedDeals) {
          const updates: Record<string, unknown> = {};
          if (targetAssigneeId) {
            updates.assigneeId = targetAssigneeId;
            updates.assigneeName = assigneeName;
          }
          if (targetTeamId) {
            updates.teamIds = sanitizeTeamIds([targetTeamId]);
          }
          if (Object.keys(updates).length === 0) continue;
          await updateDeal(deal.id, updates);
          updated.deals.add(deal.id);
        }
      }

      if (applyTasks && scopedTasks.length > 0) {
        for (const task of scopedTasks) {
          const updates: Partial<SalesActivity> = {};
          if (targetAssigneeId) {
            updates.assigneeId = targetAssigneeId;
            updates.assigneeName = assigneeName;
          }
          if (targetTeamId) {
            updates.teamIds = sanitizeTeamIds([targetTeamId]);
          }
          if (Object.keys(updates).length === 0) continue;
          await updateActivity(task.id, updates);
          updated.activities.add(task.id);
        }
        refreshTasks();
      }

      const auditEntries = buildBulkReassignAuditEntries({
        deals: updated.deals.size,
        leads: updated.leads.size,
        activities: updated.activities.size,
        targetAssigneeId,
        targetTeamId,
        scopedTeams: selectedTeams,
        maxPerEntity: MAX_REASSIGN,
      });

      if (auditEntries.length > 0) {
        try {
          for (const entry of auditEntries) {
            await auditLogService.logAction(auditContext, {
              action: 'update',
              entityType: entry.entityType,
              entityId: 'manager-bulk-reassign',
              metadata: entry.metadata,
            });
          }
        } catch (auditErr) {
          const message =
            auditErr instanceof Error
              ? auditErr.message
              : 'Failed to record audit trail';
          setError(`Updates applied but audit logging failed: ${message}`);
          return;
        }
      }

      setStatus(
        `Reassign complete. Updated ${updated.deals.size} deals, ${updated.leads.size} leads, ${updated.activities.size} activities (max ${MAX_REASSIGN} each).`
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to reassign records';
      setError(message);
    } finally {
      setIsSaving(false);
    }
  };

  if (!canOperate) {
    return (
      <Card className="manager-panel manager-team-panel" padding="lg" tone="subtle">
        <h2>Team Management</h2>
        <p className="error-state">
          Managed team claims are missing. Manager tools are read-only until claims are provisioned.
        </p>
      </Card>
    );
  }

  return (
    <Card className="manager-panel manager-team-panel" padding="lg" tone="subtle">
      <div className="manager-panel__header">
        <div className="manager-panel__copy">
          <p className="manager-panel__eyebrow">Team operations</p>
          <h2>Team Management</h2>
          <p className="page-subtitle">
            Bulk reassign within managed teams. No deletes or owner changes are performed.
          </p>
        </div>
        <div className="manager-field manager-field--compact">
          <label htmlFor="manager-team-scope">Team Scope</label>
          <select
            id="manager-team-scope"
            value={teamSelection}
            onChange={(e) => setTeamSelection(e.target.value)}
          >
            <option value="all">{baseTeams.length ? 'All managed teams' : 'All teams'}</option>
            {baseTeams.map((team) => (
              <option key={team} value={team}>
                {team}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="manager-control-grid manager-control-grid--team">
        <div className="manager-field">
          <label htmlFor="manager-assignee-filter">Current Assignee</label>
          <select
            id="manager-assignee-filter"
            value={assigneeFilter}
            onChange={(e) => setAssigneeFilter(e.target.value)}
          >
            <option value="all">All</option>
            {assigneeOptions.map((option) => (
              <option key={option.id} value={option.id}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
        <div className="manager-field">
          <label htmlFor="target-assignee">Target Assignee</label>
          <select
            id="target-assignee"
            value={targetAssigneeId}
            onChange={(e) => setTargetAssigneeId(e.target.value)}
          >
            <option value="">No change</option>
            {assigneeOptions.map((option) => (
              <option key={option.id} value={option.id}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
        <div className="manager-field">
          <label htmlFor="target-team">Target Team</label>
          <select
            id="target-team"
            value={targetTeamId}
            onChange={(e) => setTargetTeamId(e.target.value)}
          >
            <option value="">No change</option>
            {baseTeams.map((team) => (
              <option key={team} value={team}>
                {team}
              </option>
            ))}
          </select>
        </div>

        <div className="manager-team-panel__actions">
          <div className="manager-toggle-group" role="group" aria-label="Records to update">
            <label className="manager-toggle">
            <input
              type="checkbox"
              checked={applyDeals}
              onChange={(e) => setApplyDeals(e.target.checked)}
              />
              <span>Deals</span>
          </label>
            <label className="manager-toggle">
            <input
              type="checkbox"
              checked={applyLeads}
              onChange={(e) => setApplyLeads(e.target.checked)}
              />
              <span>Leads</span>
          </label>
            <label className="manager-toggle">
            <input
              type="checkbox"
              checked={applyTasks}
              onChange={(e) => setApplyTasks(e.target.checked)}
              />
              <span>Activities</span>
          </label>
          </div>
          <Button onClick={onReassign} disabled={loading || isSaving}>
            {isSaving ? 'Applying...' : 'Apply'}
          </Button>
        </div>
      </div>

      {error ? (
        <div className="error-state manager-panel__message">
          <p className="page-status-title">Unable to apply reassignment</p>
          <p className="page-status-detail">{error}</p>
        </div>
      ) : null}
      {status ? (
        <div className="page-banner page-banner--success manager-panel__message">
          <div className="page-banner__content">
            <span className="page-banner__title">Bulk update complete</span>
            <span>{status}</span>
          </div>
        </div>
      ) : null}

      <div className="manager-summary-grid">
        <Card className="manager-summary-card" padding="md">
          <div className="manager-summary-card__header">
            <div>
              <h3>Roster ({roster.length})</h3>
              <p className="page-subtitle">People currently inside the selected team scope.</p>
            </div>
          </div>
          {membersLoading ? (
            <p>Loading team members…</p>
          ) : roster.length === 0 ? (
            <p>No members in this scope.</p>
          ) : (
            <ul className="activity-list manager-roster-list">
              {roster.map((member) => (
                <li key={member.id} className="activity-item">
                  <div className="activity-title">{formatMemberName(member)}</div>
                  <div className="activity-meta">
                    Role: {member.role} • Teams:{' '}
                    {(member.teamIds && member.teamIds.length) ? member.teamIds.join(', ') : 'unspecified'}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card className="manager-summary-card manager-summary-card--metrics" padding="md">
          <div className="manager-summary-card__header">
            <div>
              <h3>Scoped Records</h3>
              <p className="page-subtitle">Up to {MAX_REASSIGN} records per type are included in one bulk pass.</p>
            </div>
          </div>
          {loading ? (
            <p>Loading scoped records…</p>
          ) : (
            <div className="manager-summary-metrics">
              <div className="manager-summary-metric">
                <span className="manager-summary-metric__label">Deals</span>
                <strong>{scopedDeals.length}</strong>
              </div>
              <div className="manager-summary-metric">
                <span className="manager-summary-metric__label">Leads</span>
                <strong>{scopedLeads.length}</strong>
              </div>
              <div className="manager-summary-metric">
                <span className="manager-summary-metric__label">Activities</span>
                <strong>{scopedTasks.length}</strong>
              </div>
            </div>
          )}
          <p className="manager-summary-note">
            Scope is limited to managed teams for managers. Ownership changes remain admin/owner-only.
          </p>
        </Card>
      </div>
    </Card>
  );
}

export default ManagerTeamPanel;
