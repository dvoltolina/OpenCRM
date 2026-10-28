import { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useDeals, useDealRotting, useLeads, useOverdueTasks, usePipelines, useStages } from '../hooks';
import { useAuditLog } from '../hooks/useAuditLog';
import type { AuditEntry } from '../types/audit';
import type { Deal, Lead, SalesActivity } from '../types/models';
import {
  buildOverdueSla,
  calculateConversionSummary,
  computeWeightedForecast,
  computeWinLossSummary,
  computeWinRateTrend,
  filterApprovals,
  filterDealsForManager,
  filterLeadsForManager,
  summarizeStages,
} from './manager-dashboard-utils';
import type { ManagerDashboardFilters } from './manager-dashboard-utils';
import ManagerWinRateTrend from '../components/manager/ManagerWinRateTrend';
import { sanitizeTeamIds } from '../lib/security-context';
import ManagerTeamPanel from '../components/manager/ManagerTeamPanel';
import ManagerApprovalsPanel from '../components/manager/ManagerApprovalsPanel';
import ManagerReportsPanel from '../components/manager/ManagerReportsPanel';
import { useRecentActivities } from '../hooks/useTimeline';
import { TeamActivitySummary } from '../components/dashboard';
import { Button, Card, PageHeader, PageLayout } from '../components/ui';
import './manager-dashboard.css';

const DEFAULT_RANGE_DAYS = 30;
type ManagerTab = 'dashboard' | 'team' | 'approvals' | 'reports';

function addDays(base: Date, days: number) {
  const date = new Date(base);
  date.setDate(date.getDate() + days);
  return date;
}

function formatCurrency(cents: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(
    cents / 100
  );
}

function formatDate(date?: Date) {
  if (!date) return '-';
  return date.toLocaleDateString();
}

export function ManagerDashboardPage() {
  const { crmUser } = useAuth();
  const role = crmUser?.role || 'staff';
  const managedTeams = sanitizeTeamIds(crmUser?.managedTeamIds || []);
  const userTeams = sanitizeTeamIds(crmUser?.teamIds || []);
  const enforceTeamScope = role === 'manager';
  const canViewManagerSurface = role === 'manager' || role === 'admin' || role === 'owner';

  const initialTeams = enforceTeamScope
    ? managedTeams
    : managedTeams.length > 0
      ? managedTeams
      : userTeams;

  const [teamSelection, setTeamSelection] = useState<string>(
    initialTeams.length > 1 ? 'all' : initialTeams[0] || 'all'
  );
  const [activeTab, setActiveTab] = useState<ManagerTab>('dashboard');
  const [assigneeFilter, setAssigneeFilter] = useState<string>('all');
  const [pipelineFilter, setPipelineFilter] = useState<string>('all');
  const [dateRange, setDateRange] = useState<{ start: Date; end: Date }>({
    start: addDays(new Date(), -DEFAULT_RANGE_DAYS),
    end: new Date(),
  });

  const { pipelines } = usePipelines();
  const activePipelineId =
    pipelineFilter === 'all' ? pipelines[0]?.id : pipelineFilter;
  const { stages, isLoading: stagesLoading } = useStages(activePipelineId);

  const teamScope = useMemo(() => {
    const scopedTeams =
      teamSelection === 'all' ? initialTeams : sanitizeTeamIds([teamSelection]);
    return scopedTeams;
  }, [initialTeams, teamSelection]);

  useEffect(() => {
    if (pipelines.length && pipelineFilter === 'all' && !activePipelineId) {
      setPipelineFilter(pipelines[0].id);
    }
  }, [pipelines, pipelineFilter, activePipelineId]);

  const filters: ManagerDashboardFilters = useMemo(
    () => ({
      selectedTeams: teamScope,
      pipelineId: pipelineFilter === 'all' ? undefined : pipelineFilter,
      assigneeId: assigneeFilter === 'all' ? undefined : assigneeFilter,
      dateRange,
      enforceTeamScope,
    }),
    [assigneeFilter, dateRange, enforceTeamScope, pipelineFilter, teamScope]
  );

  const {
    deals,
    isLoading: dealsLoading,
    error: dealsError,
    refresh: refreshDeals,
  } = useDeals({
    pipelineId: filters.pipelineId,
    assigneeId: filters.assigneeId,
    dateRange: filters.dateRange?.start && filters.dateRange?.end
      ? { start: filters.dateRange.start, end: filters.dateRange.end }
      : undefined,
  });

  const {
    leads,
    isLoading: leadsLoading,
    error: leadsError,
    refresh: refreshLeads,
  } = useLeads({
    assigneeId: filters.assigneeId,
    dateRange: filters.dateRange?.start && filters.dateRange?.end
      ? { start: filters.dateRange.start, end: filters.dateRange.end }
      : undefined,
  });

  const {
    tasks: overdueTasks,
    isLoading: tasksLoading,
    error: tasksError,
    refresh: refreshTasks,
  } = useOverdueTasks(100);

  const {
    atRiskDeals,
    isLoading: rottingLoading,
    error: rottingError,
    refresh: refreshRotting,
  } = useDealRotting();

  const {
    entries: auditEntries,
    isLoading: auditLoading,
    error: auditError,
    refresh: refreshAudit,
  } = useAuditLog({
    startDate: filters.dateRange?.start,
    endDate: filters.dateRange?.end,
    limit: 30,
  });

  // Fetch recent activities for Team Activity Summary
  const {
    activities: recentActivities,
    isLoading: activitiesLoading,
    refresh: refreshActivities,
  } = useRecentActivities(1, 100); // Today's activities

  const filteredDeals = useMemo<Deal[]>(
    () => filterDealsForManager(deals, filters),
    [deals, filters]
  );
  const filteredLeads = useMemo<Lead[]>(
    () => filterLeadsForManager(leads, filters),
    [leads, filters]
  );
  const filteredAtRisk = useMemo(
    () => filterDealsForManager(atRiskDeals as Deal[], filters),
    [atRiskDeals, filters]
  );
  const filteredTasks = useMemo<SalesActivity[]>(
    () => overdueTasks.filter((task) => task.dueDate),
    [overdueTasks]
  );
  const slaRows = useMemo(
    () => buildOverdueSla(filteredTasks, filters),
    [filteredTasks, filters]
  );
  const approvalEntries = useMemo<AuditEntry[]>(
    () => filterApprovals(auditEntries, filters),
    [auditEntries, filters]
  );
  const conversion = useMemo(
    () => calculateConversionSummary(filteredLeads, filters.dateRange),
    [filteredLeads, filters.dateRange]
  );
  const winLoss = useMemo(
    () => computeWinLossSummary(filteredDeals, filters.dateRange),
    [filteredDeals, filters.dateRange]
  );
  const weightedForecast = useMemo(
    () => computeWeightedForecast(filteredDeals),
    [filteredDeals]
  );
  const winRateTrend = useMemo(
    () => computeWinRateTrend(filteredDeals, filters.dateRange, 'month'),
    [filteredDeals, filters.dateRange]
  );
  const stageSummaries = useMemo(
    () => summarizeStages(filteredDeals, stages),
    [filteredDeals, stages]
  );

  const totalPipelineValue = filteredDeals
    .filter((deal) => deal.status === 'open')
    .reduce((sum, deal) => sum + deal.valueCents, 0);

  const loading =
    dealsLoading ||
    leadsLoading ||
    tasksLoading ||
    rottingLoading ||
    auditLoading ||
    activitiesLoading ||
    stagesLoading;

  const [initialLoadDone, setInitialLoadDone] = useState(false);
  useEffect(() => {
    if (!loading && !initialLoadDone) {
      setInitialLoadDone(true);
    }
  }, [loading, initialLoadDone]);

  const error =
    dealsError || leadsError || tasksError || rottingError || auditError;

  const assigneeOptions = useMemo(() => {
    const ids = new Map<string, string>();
    filteredDeals.forEach((deal) => {
      if (deal.assigneeId) {
        ids.set(deal.assigneeId, deal.assigneeName || deal.assigneeId);
      }
    });
    filteredLeads.forEach((lead) => {
      if (lead.assigneeId) {
        ids.set(lead.assigneeId, lead.assigneeName || lead.assigneeId);
      }
    });
    filteredTasks.forEach((task) => {
      if (task.assigneeId) {
        ids.set(task.assigneeId, task.assigneeName || task.assigneeId);
      }
    });
    return Array.from(ids.entries()).map(([id, name]) => ({ id, name }));
  }, [filteredDeals, filteredLeads, filteredTasks]);

  const handleRangeChange = (days: number) => {
    setDateRange({
      start: addDays(new Date(), -days),
      end: new Date(),
    });
  };

  const refreshAll = () => {
    refreshDeals();
    refreshLeads();
    refreshTasks();
    refreshRotting();
    refreshAudit();
    refreshActivities();
  };

  if (!canViewManagerSurface) {
    return (
      <PageLayout width="wide" className="manager-dashboard-page">
        <PageHeader
          eyebrow="Manager workspace"
          title="Team Dashboard"
          subtitle="Unblock your team, rebalance coverage, and keep approvals moving."
        />
        <Card className="error-state" padding="lg">
          <p className="page-status-title">Access unavailable</p>
          <p className="page-status-detail">Only managers and administrators can view this dashboard.</p>
        </Card>
      </PageLayout>
    );
  }

  if (enforceTeamScope && managedTeams.length === 0) {
    return (
      <PageLayout width="wide" className="manager-dashboard-page">
        <PageHeader
          eyebrow="Manager workspace"
          title="Team Dashboard"
          subtitle="Unblock your team, rebalance coverage, and keep approvals moving."
        />
        <Card className="error-state" padding="lg">
          <p className="page-status-title">Managed teams unavailable</p>
          <p className="page-status-detail">
            Managed team claims are missing. Access is read-only until teams are assigned.
          </p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="manager-dashboard-page">
      <PageHeader
        eyebrow="Manager workspace"
        title="Team Dashboard"
        subtitle="Unblock your team, rebalance workload, and move approvals forward without leaving the workspace."
        actions={(
          <Button variant="secondary" onClick={refreshAll}>
            Refresh
          </Button>
        )}
      />

      <section className="manager-dashboard__tabs">
        <div className="manager-dashboard__tab-grid">
          <button
            type="button"
            className={`manager-tab-card ${activeTab === 'team' ? 'active' : ''}`}
            onClick={() => setActiveTab('team')}
          >
            <span className="manager-tab-card__icon" aria-hidden="true">👥</span>
            <div className="manager-tab-card__copy">
              <span className="manager-tab-card__label">Manage Team</span>
              <span className="manager-tab-card__meta">{managedTeams.length} teams</span>
            </div>
          </button>
          <button
            type="button"
            className={`manager-tab-card ${activeTab === 'approvals' ? 'active' : ''}`}
            onClick={() => setActiveTab('approvals')}
          >
            <span className="manager-tab-card__icon" aria-hidden="true">⏱️</span>
            <div className="manager-tab-card__copy">
              <span className="manager-tab-card__label">Approvals</span>
              <span className="manager-tab-card__meta">
                {approvalEntries.length > 0 ? `${approvalEntries.length} pending` : 'All clear'}
              </span>
            </div>
          </button>
          <button
            type="button"
            className={`manager-tab-card ${activeTab === 'reports' ? 'active' : ''}`}
            onClick={() => setActiveTab('reports')}
          >
            <span className="manager-tab-card__icon" aria-hidden="true">📊</span>
            <div className="manager-tab-card__copy">
              <span className="manager-tab-card__label">Reports</span>
              <span className="manager-tab-card__meta">Team analytics</span>
            </div>
          </button>
          <button
            type="button"
            className={`manager-tab-card ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <span className="manager-tab-card__icon" aria-hidden="true">📋</span>
            <div className="manager-tab-card__copy">
              <span className="manager-tab-card__label">Dashboard</span>
              <span className="manager-tab-card__meta">Metrics overview</span>
            </div>
          </button>
        </div>
      </section>

      {activeTab === 'dashboard' && (
        <>
          <Card tone="subtle" padding="md" className="manager-dashboard__filters">
            <div className="manager-control-grid manager-control-grid--dashboard">
              <div className="manager-field">
              <label htmlFor="team-filter">Team</label>
              <select
                id="team-filter"
                value={teamSelection}
                onChange={(e) => setTeamSelection(e.target.value)}
              >
                <option value="all">
                  {initialTeams.length > 0 ? 'All managed teams' : 'All teams'}
                </option>
                {initialTeams.map((teamId) => (
                  <option key={teamId} value={teamId}>
                    {teamId}
                  </option>
                ))}
              </select>
              </div>

              <div className="manager-field">
              <label htmlFor="assignee-filter">Assignee</label>
              <select
                id="assignee-filter"
                value={assigneeFilter}
                onChange={(e) => setAssigneeFilter(e.target.value)}
              >
                <option value="all">All</option>
                {assigneeOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.name}
                  </option>
                ))}
              </select>
              </div>

              <div className="manager-field">
              <label htmlFor="pipeline-filter">Pipeline</label>
              <select
                id="pipeline-filter"
                value={pipelineFilter}
                onChange={(e) => setPipelineFilter(e.target.value)}
              >
                <option value="all">All</option>
                {pipelines.map((pipeline) => (
                  <option key={pipeline.id} value={pipeline.id}>
                    {pipeline.name}
                  </option>
                ))}
              </select>
              </div>

              <div className="manager-field manager-field--span-2">
                <label>Date Range</label>
                <div className="manager-range-row">
                <button
                  type="button"
                  className={`manager-pill ${dateRange.start <= addDays(new Date(), -30) ? 'is-active' : ''}`}
                  onClick={() => handleRangeChange(30)}
                >
                  Last 30 days
                </button>
                <button
                  type="button"
                  className={`manager-pill ${dateRange.start <= addDays(new Date(), -90) ? 'is-active' : ''}`}
                  onClick={() => handleRangeChange(90)}
                >
                  Last 90 days
                </button>
                <span className="manager-range-label">
                  {formatDate(dateRange.start)} – {formatDate(dateRange.end)}
                </span>
                </div>
              </div>
            </div>
          </Card>

          {!initialLoadDone && loading && (
            <Card className="loading-state" padding="lg">
              <p>Loading manager metrics…</p>
            </Card>
          )}

          {error && (
            <Card className="error-state" padding="lg">
              <p className="page-status-title">Error loading manager metrics</p>
              <p className="page-status-detail">{error.message}</p>
            </Card>
          )}

          {initialLoadDone && !error && (
            <>
              {/* Team Activity Summary - Team View Exclusive */}
              <div className="dashboard-highlight-row">
                <TeamActivitySummary
                  activities={recentActivities}
                  title="Team Activity Today"
                />
              </div>

              <div className="kpi-cards">
            <div className="kpi-card">
              <span className="kpi-label">Team Pipeline</span>
              <span className="kpi-value">{formatCurrency(totalPipelineValue)}</span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Team Forecast</span>
              <span className="kpi-value">{formatCurrency(Math.round(weightedForecast))}</span>
              <span className="kpi-sublabel">Open deals × stage probability</span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Team Conversion</span>
              <span className="kpi-value">{conversion.conversionRate.toFixed(1)}%</span>
              <span className="kpi-sublabel">
                {conversion.convertedLeads} / {conversion.totalLeads} leads
              </span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Team Win Rate</span>
              <span className="kpi-value">{winLoss.winRate.toFixed(1)}%</span>
              <span className="kpi-sublabel">
                Won {winLoss.wonCount} · Lost {winLoss.lostCount}
              </span>
            </div>
            <div className="kpi-card kpi-card-warning">
              <span className="kpi-label">⚠️ At-Risk Deals</span>
              <span className="kpi-value">{filteredAtRisk.length}</span>
            </div>
            <div className="kpi-card kpi-card-warning">
              <span className="kpi-label">⏰ Overdue Tasks</span>
              <span className="kpi-value">
                {slaRows.reduce((sum, row) => sum + row.overdueCount, 0)}
              </span>
            </div>
              </div>

              <div className="dashboard-grid">
                <section className="dashboard-section">
                  <h2>Pipeline by Stage</h2>
                  {stageSummaries.length === 0 ? (
                    <p>No stage data available for the selected filters.</p>
                  ) : (
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Stage</th>
                          <th>Open Deals</th>
                          <th>Open Value</th>
                        </tr>
                      </thead>
                      <tbody>
                        {stageSummaries.map((stage) => (
                          <tr key={stage.stageId}>
                            <td>{stage.stageName}</td>
                            <td>{stage.count}</td>
                            <td>{formatCurrency(stage.valueCents)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </section>

                <section className="dashboard-section">
                  <h2>Activity SLA (Overdue by Assignee)</h2>
                  {slaRows.length === 0 ? (
                    <p>No overdue tasks in the current scope.</p>
                  ) : (
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Assignee</th>
                          <th>Overdue Tasks</th>
                          <th>Oldest Due</th>
                        </tr>
                      </thead>
                      <tbody>
                        {slaRows.map((row) => (
                          <tr key={row.assigneeId}>
                            <td>{row.assigneeName}</td>
                            <td>{row.overdueCount}</td>
                            <td>{formatDate(row.oldestDueDate)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                    )}
                  </section>

                <section className="dashboard-section">
                  <h2>Win Rate Trend</h2>
                  <ManagerWinRateTrend trend={winRateTrend} />
                </section>

                <section className="dashboard-section">
                  <h2>At-Risk Deals</h2>
                  {filteredAtRisk.length === 0 ? (
                    <p>No at-risk deals for the selected scope.</p>
                  ) : (
                    <div className="deals-list">
                      {filteredAtRisk.slice(0, 5).map((deal) => (
                        <div key={deal.id} className="deal-item">
                          <div className="deal-title">{deal.title}</div>
                          <div className="deal-value">{formatCurrency(deal.valueCents, deal.currency)}</div>
                          <div className="deal-meta">
                            Stage: {deal.stageId} • Assignee: {deal.assigneeName || 'Unassigned'}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </section>

                <section className="dashboard-section">
                  <h2>Recent Escalations / Approvals</h2>
                  {approvalEntries.length === 0 ? (
                    <p>No escalation or approval events in the selected range.</p>
                  ) : (
                    <ul className="activity-list">
                      {approvalEntries.slice(0, 8).map((entry) => (
                        <li key={entry.id} className="activity-item">
                          <div className="activity-title">
                            {entry.entityType} {entry.action}
                          </div>
                          <div className="activity-meta">
                            {entry.userName} • {formatDate(entry.timestamp)}
                          </div>
                        </li>
                      ))}
                    </ul>
                  )}
                </section>
              </div>
            </>
          )}
        </>
      )}

      {activeTab === 'team' && (
        <ManagerTeamPanel
          managedTeams={managedTeams}
          userTeams={userTeams}
          enforceTeamScope={enforceTeamScope}
        />
      )}
      {activeTab === 'approvals' && (
        <ManagerApprovalsPanel
          managedTeams={managedTeams}
          userTeams={userTeams}
          enforceTeamScope={enforceTeamScope}
        />
      )}
      {activeTab === 'reports' && (
        <ManagerReportsPanel
          managedTeams={managedTeams}
          userTeams={userTeams}
          enforceTeamScope={enforceTeamScope}
        />
      )}
    </PageLayout>
  );
}

export default ManagerDashboardPage;
