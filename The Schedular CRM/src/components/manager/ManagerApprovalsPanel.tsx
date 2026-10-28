import { useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useAuditLog } from '../../hooks/useAuditLog';
import { AuditLogService } from '../../services/AuditLogService';
import type { AuditEntry } from '../../types/audit';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import { buildApprovalRequests, type ManagerDashboardFilters } from '../../pages/manager-dashboard-utils';
import { buildApprovalMetadata } from '../../lib/approval-metadata';
import { Button, Card } from '../ui';

interface ManagerApprovalsPanelProps {
  managedTeams: string[];
  userTeams: string[];
  enforceTeamScope: boolean;
}

function buildRequestType(entry: AuditEntry) {
  const meta = entry.metadata || {};
  return meta.requestType || meta.category || meta.type || 'approval';
}

function buildStatusTone(status: string) {
  const normalized = status.toLowerCase();
  if (normalized === 'approved') return 'approved';
  if (normalized === 'denied') return 'denied';
  return 'pending';
}

export function ManagerApprovalsPanel({
  managedTeams,
  userTeams,
  enforceTeamScope,
}: ManagerApprovalsPanelProps) {
  const { crmUser, businessId } = useAuth();
  const [decisionMap, setDecisionMap] = useState<Record<string, 'approved' | 'denied'>>({});
  const [actionError, setActionError] = useState<string | null>(null);
  const [teamSelection, setTeamSelection] = useState<string>(
    managedTeams.length > 1 ? 'all' : managedTeams[0] || 'all'
  );
  const [days, setDays] = useState(30);
  const auditService = useMemo(() => new AuditLogService(), []);

  const selectedTeams = useMemo(() => {
    if (teamSelection === 'all') {
      return managedTeams.length > 0 ? managedTeams : userTeams;
    }
    return sanitizeTeamIds([teamSelection]);
  }, [managedTeams, teamSelection, userTeams]);

  const filters: ManagerDashboardFilters = useMemo(
    () => ({
      selectedTeams,
      enforceTeamScope,
    }),
    [enforceTeamScope, selectedTeams]
  );

  const startDate = useMemo(() => {
    const now = new Date();
    now.setDate(now.getDate() - days);
    return now;
  }, [days]);

  const { entries, isLoading, error, refresh } = useAuditLog({
    startDate,
    endDate: new Date(),
    limit: 50,
  });

  const approvalRequests = useMemo(
    () => buildApprovalRequests(entries, filters),
    [entries, filters]
  );

  const buildContext = () => {
    if (!crmUser || !businessId) return null;
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      sanitizeTeamIds(crmUser.teamIds || []),
      sanitizeTeamIds(crmUser.managedTeamIds || []),
      crmUser.managerId
    );
  };

  const handleDecision = async (entry: AuditEntry, requestType: string, decision: 'approved' | 'denied') => {
    setActionError(null);
    const context = buildContext();
    if (!context) {
      setActionError('Unable to create audit entry for this decision.');
      return;
    }

    try {
      const metadata = buildApprovalMetadata({
        approvalType: requestType,
        requestType,
        decision,
        status: decision,
        sourceAuditId: entry.id,
        teamIds: selectedTeams,
        managedTeamIds: enforceTeamScope ? managedTeams : undefined,
        contextTeamIds: context.teamIds,
        contextManagedTeamIds: context.managedTeamIds,
      });

      await auditService.logAction(context, {
        action: 'update',
        entityType: 'report',
        entityId: `approval:${entry.id}`,
        metadata,
      });
      setDecisionMap((prev) => ({ ...prev, [entry.id]: decision }));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to record approval';
      setActionError(message);
    }
  };

  if (enforceTeamScope && managedTeams.length === 0) {
    return (
      <Card className="manager-panel manager-approvals-panel" padding="lg" tone="subtle">
        <h2>Approvals & Overrides</h2>
        <p className="error-state">
          Managed team claims are required to view approval requests. Access is read-only until claims are provisioned.
        </p>
      </Card>
    );
  }

  return (
    <Card className="manager-panel manager-approvals-panel" padding="lg" tone="subtle">
      <div className="manager-panel__header">
        <div className="manager-panel__copy">
          <p className="manager-panel__eyebrow">Approvals</p>
          <h2>Approvals & Overrides</h2>
          <p className="page-subtitle">
            Audit-log driven only (no backend queue). Request types and states come from audit metadata, scoped to managed teams.
          </p>
        </div>
      </div>

      <div className="manager-control-grid manager-control-grid--approvals">
          <div className="manager-field">
            <label htmlFor="approval-team-filter">Team</label>
            <select
              id="approval-team-filter"
              value={teamSelection}
              onChange={(e) => setTeamSelection(e.target.value)}
            >
              <option value="all">
                {managedTeams.length > 0 ? 'All managed teams' : 'All teams'}
              </option>
              {(managedTeams.length > 0 ? managedTeams : userTeams).map((team) => (
                <option key={team} value={team}>
                  {team}
                </option>
              ))}
            </select>
          </div>
          <div className="manager-field">
            <label htmlFor="approval-range">Lookback (days)</label>
            <input
              id="approval-range"
              type="number"
              min={7}
              max={90}
              value={days}
              onChange={(e) => setDays(Number(e.target.value) || 30)}
            />
          </div>
          <div className="manager-inline-actions">
            <Button variant="secondary" onClick={refresh}>
              Refresh
            </Button>
          </div>
      </div>

      {actionError ? (
        <div className="error-state manager-panel__message">
          <p className="page-status-title">Decision not recorded</p>
          <p className="page-status-detail">{actionError}</p>
        </div>
      ) : null}

      {isLoading ? (
        <div className="manager-empty-state">
          <p>Loading approval events…</p>
        </div>
      ) : error ? (
        <div className="error-state manager-panel__message">
          <p className="page-status-title">Unable to load approvals</p>
          <p className="page-status-detail">{error.message}</p>
        </div>
      ) : approvalRequests.length === 0 ? (
        <div className="manager-empty-state">
          <p>No approvals or escalations in this scope.</p>
        </div>
      ) : (
        <div className="data-table-container manager-approvals-panel__table">
          <table className="data-table">
            <thead>
              <tr>
                <th>Request</th>
                <th>Scope</th>
                <th>Timestamp</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {approvalRequests.map((request) => {
                const entry = request.entry;
                const requestType = request.requestType || buildRequestType(entry);
                const resolved = decisionMap[entry.id] || request.status;
                const teamsLabel =
                  request.teamIds.length > 0 ? request.teamIds.join(', ') : 'unspecified';
                return (
                  <tr key={entry.id}>
                    <td>{requestType}</td>
                    <td>{teamsLabel}</td>
                    <td>{entry.timestamp.toLocaleString()}</td>
                    <td>
                      <span className={`manager-status-pill manager-status-pill--${buildStatusTone(String(resolved))}`}>
                        {String(resolved).toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <div className="manager-table-actions">
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => handleDecision(entry, requestType, 'approved')}
                          disabled={Boolean(decisionMap[entry.id])}
                        >
                          Approve
                        </Button>
                        <Button
                          size="sm"
                          variant="secondary"
                          onClick={() => handleDecision(entry, requestType, 'denied')}
                          disabled={Boolean(decisionMap[entry.id])}
                        >
                          Deny
                        </Button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}

export default ManagerApprovalsPanel;
