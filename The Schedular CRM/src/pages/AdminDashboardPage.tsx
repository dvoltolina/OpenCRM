/**
 * Admin Dashboard Page
 *
 * Full business-wide analytics for Owner and Admin roles.
 * Shows org-wide metrics without team scoping.
 *
 * Per CRM-A Agent Prompt:
 * - Business Health Card (revenue, appointments, active clients)
 * - Team Activity Feed (all team actions)
 * - Quick Actions Card (common admin tasks)
 * - Alerts Card (pending approvals, issues)
 * - Metrics Grid (KPIs)
 */

import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  useDeals,
  useLeads,
  usePipelines,
  useStages,
  useContacts,
  useModal,
} from '../hooks';
import { useAuditLog } from '../hooks/useAuditLog';
import { useTeamMembers } from '../hooks/useTeamMembers';
import { usePendingApprovals } from '../hooks/useTimeEntries';
import { TeamLeaderboard, ForecastVsGoal } from '../components/dashboard';
import { CreateLeadModal, CreateDealModal } from '../components/modals';
import { Button, Card, EmptyState, PageHeader, PageLayout } from '../components/ui';
import './styles/admin-dashboard-page.css';

// Default monthly goal (can be made configurable later)
const DEFAULT_MONTHLY_GOAL_CENTS = 10000000; // $100,000

const DEFAULT_RANGE_DAYS = 30;

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

export function AdminDashboardPage() {
  const { crmUser } = useAuth();
  const navigate = useNavigate();
  const role = crmUser?.role || 'staff';
  const canViewAdminDashboard = role === 'admin' || role === 'owner';

  const addLeadModal = useModal();
  const addDealModal = useModal();

  const [dateRange, setDateRange] = useState<{ start: Date; end: Date }>({
    start: addDays(new Date(), -DEFAULT_RANGE_DAYS),
    end: new Date(),
  });

  const { pipelines } = usePipelines();
  const [selectedPipelineId, setSelectedPipelineId] = useState<string>('');
  const { stages } = useStages(selectedPipelineId || pipelines[0]?.id);
  const { contacts } = useContacts();

  // Fetch org-wide data (no team filtering)
  const {
    deals,
    isLoading: dealsLoading,
    error: dealsError,
    refresh: refreshDeals,
  } = useDeals({
    dateRange: { start: dateRange.start, end: dateRange.end },
  });

  const {
    leads,
    isLoading: leadsLoading,
    error: leadsError,
    refresh: refreshLeads,
  } = useLeads({
    dateRange: { start: dateRange.start, end: dateRange.end },
  });

  const { members: teamMembers, isLoading: teamLoading } = useTeamMembers();

  const {
    entries: pendingTimesheets,
    isLoading: timesheetsLoading,
    refresh: refreshTimesheets,
  } = usePendingApprovals();

  const {
    entries: auditEntries,
    isLoading: auditLoading,
    error: auditError,
    refresh: refreshAudit,
  } = useAuditLog({
    startDate: dateRange.start,
    endDate: dateRange.end,
    limit: 50,
  });

  useEffect(() => {
    if (pipelines.length && !selectedPipelineId) {
      setSelectedPipelineId(pipelines[0].id);
    }
  }, [pipelines, selectedPipelineId]);

  // Calculate org-wide KPIs
  const kpis = useMemo(() => {
    const openDeals = deals.filter((d) => d.status === 'open');
    const wonDeals = deals.filter((d) => d.status === 'won');
    const lostDeals = deals.filter((d) => d.status === 'lost');

    const totalPipelineValue = openDeals.reduce((sum, d) => sum + d.valueCents, 0);
    const totalWonValue = wonDeals.reduce((sum, d) => sum + d.valueCents, 0);
    const totalLostValue = lostDeals.reduce((sum, d) => sum + d.valueCents, 0);

    const closedDeals = wonDeals.length + lostDeals.length;
    const winRate = closedDeals > 0 ? (wonDeals.length / closedDeals) * 100 : 0;

    const avgDealSize = openDeals.length > 0
      ? totalPipelineValue / openDeals.length
      : 0;

    // Lead conversion
    const convertedLeads = leads.filter((l) => l.status === 'converted').length;
    const totalLeads = leads.length;
    const conversionRate = totalLeads > 0 ? (convertedLeads / totalLeads) * 100 : 0;

    // Calculate weighted forecast
    const weightedForecast = openDeals.reduce((sum, deal) => {
      const stage = stages.find((s) => s.id === deal.stageId);
      const probability = stage?.probability || 50;
      return sum + (deal.valueCents * probability) / 100;
    }, 0);

    return {
      totalPipelineValue,
      totalWonValue,
      totalLostValue,
      wonDealsCount: wonDeals.length,
      lostDealsCount: lostDeals.length,
      openDealsCount: openDeals.length,
      winRate,
      avgDealSize,
      totalLeads,
      convertedLeads,
      conversionRate,
      weightedForecast,
    };
  }, [deals, leads, stages]);

  // Stage summary
  const stageSummaries = useMemo(() => {
    const openDeals = deals.filter((d) => d.status === 'open');
    return stages.map((stage) => {
      const stageDeals = openDeals.filter((d) => d.stageId === stage.id);
      return {
        stageId: stage.id,
        stageName: stage.name,
        count: stageDeals.length,
        valueCents: stageDeals.reduce((sum, d) => sum + d.valueCents, 0),
      };
    }).filter((s) => s.count > 0);
  }, [deals, stages]);

  // Team performance summary
  const teamPerformance = useMemo(() => {
    const performanceMap = new Map<string, { name: string; wonCount: number; wonValue: number; openCount: number; openValue: number }>();

    deals.forEach((deal) => {
      const assigneeId = deal.assigneeId || 'unassigned';
      const assigneeName = deal.assigneeName || 'Unassigned';

      const existing = performanceMap.get(assigneeId) || {
        name: assigneeName,
        wonCount: 0,
        wonValue: 0,
        openCount: 0,
        openValue: 0,
      };

      if (deal.status === 'won') {
        existing.wonCount += 1;
        existing.wonValue += deal.valueCents;
      } else if (deal.status === 'open') {
        existing.openCount += 1;
        existing.openValue += deal.valueCents;
      }

      performanceMap.set(assigneeId, existing);
    });

    return Array.from(performanceMap.entries())
      .map(([id, data]) => ({ id, ...data }))
      .sort((a, b) => b.wonValue - a.wonValue)
      .slice(0, 10);
  }, [deals]);

  const loading = dealsLoading || leadsLoading || teamLoading || timesheetsLoading || auditLoading;
  const error = dealsError || leadsError || auditError;
  const rangeLabel = `${formatDate(dateRange.start)} - ${formatDate(dateRange.end)}`;

  const handleRangeChange = (days: number) => {
    setDateRange({
      start: addDays(new Date(), -days),
      end: new Date(),
    });
  };

  const refreshAll = () => {
    refreshDeals();
    refreshLeads();
    refreshTimesheets();
    refreshAudit();
  };

  if (!canViewAdminDashboard) {
    return (
      <PageLayout width="wide" className="admin-dashboard-page">
        <PageHeader
          eyebrow="Leadership"
          title="Admin Dashboard"
          subtitle="Business-wide health, approvals, and performance metrics."
        />
        <Card padding="lg" className="admin-dashboard-page__state-card">
          <EmptyState
            tone="danger"
            title="Access denied"
            description="Only administrators and owners can view this dashboard."
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="admin-dashboard-page">
      <PageHeader
        eyebrow="Leadership"
        title="Admin Dashboard"
        subtitle="Review business health, team performance, and approvals without team scoping."
        actions={(
          <div className="admin-dashboard-page__header-actions">
            <Button onClick={() => addLeadModal.open()}>
              Add Lead
            </Button>
            <Button variant="secondary" onClick={() => addDealModal.open()}>
              Add Opportunity
            </Button>
            <Button variant="ghost" onClick={refreshAll}>
              Refresh
            </Button>
          </div>
        )}
      />

      <Card tone="accent" className="admin-dashboard-page__hero">
        <div className="admin-dashboard-page__hero-copy">
          <h2>See the whole business, not just a single team slice.</h2>
          <p>
            Track revenue velocity, recent activity, pending approvals, and pipeline
            health from one leadership surface.
          </p>
        </div>
        <div className="admin-dashboard-page__hero-stats" aria-label="Admin dashboard summary">
          <div>
            <span>Team members</span>
            <strong>{teamMembers.length}</strong>
          </div>
          <div>
            <span>Pending approvals</span>
            <strong>{pendingTimesheets.length}</strong>
          </div>
          <div>
            <span>Window</span>
            <strong>{rangeLabel}</strong>
          </div>
        </div>
      </Card>

      <section className="quick-actions-section">
        <div className="quick-actions-bar">
          <button className="quick-action-card" onClick={() => navigate('/settings?tab=team')}>
            <span className="quick-action-label">Manage Team</span>
            <span className="quick-action-count">{teamMembers.length} members</span>
          </button>
          <button className="quick-action-card" onClick={() => navigate('/timesheets')}>
            <span className="quick-action-label">Timesheets</span>
            <span className="quick-action-count">
              {pendingTimesheets.length > 0 ? `${pendingTimesheets.length} pending` : 'All approved'}
            </span>
          </button>
          <button className="quick-action-card" onClick={() => navigate('/reports')}>
            <span className="quick-action-label">Reports</span>
            <span className="quick-action-count">Business analytics</span>
          </button>
          <button className="quick-action-card" onClick={() => navigate('/settings')}>
            <span className="quick-action-label">Settings</span>
            <span className="quick-action-count">System config</span>
          </button>
        </div>
      </section>

      <Card className="admin-dashboard-page__filters-card">
        <section className="filters-bar">
          <div className="filter-group">
            <label>Date Range</label>
            <div className="filter-group-inline">
              <Button
                variant="ghost"
                className={dateRange.start <= addDays(new Date(), -7) && dateRange.start > addDays(new Date(), -8) ? 'admin-dashboard-page__range-button is-active' : 'admin-dashboard-page__range-button'}
                onClick={() => handleRangeChange(7)}
              >
                Last 7 days
              </Button>
              <Button
                variant="ghost"
                className={dateRange.start <= addDays(new Date(), -30) && dateRange.start > addDays(new Date(), -31) ? 'admin-dashboard-page__range-button is-active' : 'admin-dashboard-page__range-button'}
                onClick={() => handleRangeChange(30)}
              >
                Last 30 days
              </Button>
              <Button
                variant="ghost"
                className={dateRange.start <= addDays(new Date(), -90) && dateRange.start > addDays(new Date(), -91) ? 'admin-dashboard-page__range-button is-active' : 'admin-dashboard-page__range-button'}
                onClick={() => handleRangeChange(90)}
              >
                Last 90 days
              </Button>
              <span className="date-range-label">{rangeLabel}</span>
            </div>
          </div>
        </section>
      </Card>

      {loading && (
        <Card padding="lg" className="admin-dashboard-page__state-card">
          <p>Loading admin metrics...</p>
        </Card>
      )}

      {error && (
        <Card padding="lg" className="admin-dashboard-page__state-card">
          <EmptyState
            tone="danger"
            title="Unable to load admin metrics"
            description={error.message}
            actions={(
              <Button variant="secondary" onClick={refreshAll}>
                Retry
              </Button>
            )}
          />
        </Card>
      )}

      {!loading && !error && (
        <>
          {/* Business Health KPIs */}
          <div className="kpi-cards">
            <div className="kpi-card kpi-card-primary">
              <span className="kpi-label">Total Pipeline Value</span>
              <span className="kpi-value">{formatCurrency(kpis.totalPipelineValue)}</span>
              <span className="kpi-sublabel">{kpis.openDealsCount} open opportunities</span>
            </div>
            <div className="kpi-card kpi-card-success">
              <span className="kpi-label">Won Revenue</span>
              <span className="kpi-value">{formatCurrency(kpis.totalWonValue)}</span>
              <span className="kpi-sublabel">{kpis.wonDealsCount} deals won</span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Weighted Forecast</span>
              <span className="kpi-value">{formatCurrency(Math.round(kpis.weightedForecast))}</span>
              <span className="kpi-sublabel">Based on stage probability</span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Win Rate</span>
              <span className="kpi-value">{kpis.winRate.toFixed(1)}%</span>
              <span className="kpi-sublabel">
                {kpis.wonDealsCount} won / {kpis.wonDealsCount + kpis.lostDealsCount} closed
              </span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Conversion Rate</span>
              <span className="kpi-value">{kpis.conversionRate.toFixed(1)}%</span>
              <span className="kpi-sublabel">
                {kpis.convertedLeads} / {kpis.totalLeads} leads
              </span>
            </div>
            <div className="kpi-card">
              <span className="kpi-label">Avg Opportunity Size</span>
              <span className="kpi-value">{formatCurrency(kpis.avgDealSize)}</span>
            </div>
          </div>

          {/* Forecast vs Goal */}
          <div className="dashboard-highlight-row">
            <ForecastVsGoal
              wonRevenueCents={kpis.totalWonValue}
              forecastCents={Math.round(kpis.weightedForecast)}
              goalCents={DEFAULT_MONTHLY_GOAL_CENTS}
              periodLabel="This Month"
            />
          </div>

          <div className="dashboard-grid">
            {/* Pipeline by Stage */}
            <section className="dashboard-section">
              <h2>Pipeline by Stage</h2>
              {stageSummaries.length === 0 ? (
                <p className="empty-message">No deals in pipeline</p>
              ) : (
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Stage</th>
                      <th>Deals</th>
                      <th>Value</th>
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

            {/* Sales Leaderboard */}
            <section className="dashboard-section">
              <TeamLeaderboard
                entries={teamPerformance}
                title="Sales Leaderboard"
                limit={10}
              />
            </section>

            {/* Pending Approvals Alert */}
            {pendingTimesheets.length > 0 && (
              <section className="dashboard-section alert-section">
                <div className="section-header">
                  <h2>Pending Approvals</h2>
                  <Button variant="ghost" size="sm" onClick={() => navigate('/timesheets')}>
                    Review all
                  </Button>
                </div>
                <div className="alert-card alert-warning">
                  <div className="alert-content">
                    <strong>{pendingTimesheets.length} timesheet{pendingTimesheets.length !== 1 ? 's' : ''}</strong> pending approval
                  </div>
                  <Button size="sm" onClick={() => navigate('/timesheets')}>
                    Review
                  </Button>
                </div>
              </section>
            )}

            {/* Recent Activity */}
            <section className="dashboard-section">
              <div className="section-header">
                <h2>Recent Activity</h2>
                <Button variant="ghost" size="sm" onClick={() => navigate('/admin?tab=audit')}>
                  View audit log
                </Button>
              </div>
              {auditEntries.length === 0 ? (
                <p className="empty-message">No recent activity</p>
              ) : (
                <ul className="activity-list">
                  {auditEntries.slice(0, 10).map((entry) => (
                    <li key={entry.id} className="activity-item">
                      <div className="activity-content">
                        <div className="activity-title">
                          {entry.entityType} {entry.action}
                        </div>
                        <div className="activity-meta">
                          {entry.userName} • {formatDate(entry.timestamp)}
                        </div>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </section>

          </div>
        </>
      )}

      {/* Modals */}
      <CreateLeadModal
        isOpen={addLeadModal.isOpen}
        onClose={addLeadModal.close}
        onSuccess={() => {
          refreshLeads();
          addLeadModal.close();
        }}
      />

      <CreateDealModal
        isOpen={addDealModal.isOpen}
        onClose={addDealModal.close}
        pipelines={pipelines}
        stages={stages}
        clients={contacts}
        onSuccess={() => {
          refreshDeals();
          addDealModal.close();
        }}
      />
    </PageLayout>
  );
}

export default AdminDashboardPage;
