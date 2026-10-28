import { useState, useMemo, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import {
  useDashboardData,
  usePipelines,
  useStages,
  useContacts,
  useModal,
} from '../hooks';
import { UpcomingTasks, ActivityFeed, QuotaProgress, TodaysTasks } from '../components/dashboard';
import {
  CreateLeadModal,
  CreateDealModal,
  LogActivityModal,
} from '../components/modals';
import { useNavigate } from 'react-router-dom';
import type { Deal, SalesActivity } from '../types/models';
import { createSecurityContext, getShareableAccessSummary } from '../lib/security-context';
import { useActivityLog } from '../hooks/useActivityLog';
import { Button, Card, PageHeader, PageLayout } from '../components/ui';

// Default personal quota (can be made configurable per user later)
const DEFAULT_PERSONAL_QUOTA_CENTS = 2500000; // $25,000/month

export function DashboardPage() {
  const { crmUser } = useAuth();
  const welcomeName = crmUser?.displayName || crmUser?.email || 'there';

  // All hooks must be called before any conditional returns (React rules of hooks)
  const navigate = useNavigate();
  const addLeadModal = useModal();
  const addDealModal = useModal();
  const editDealModal = useModal<Deal>();
  const logActivityModal = useModal();
  const { pipelines } = usePipelines();
  const [selectedPipelineId, setSelectedPipelineId] = useState<string>(pipelines[0]?.id || '');
  const { stages } = useStages(selectedPipelineId || pipelines[0]?.id);
  const { contacts } = useContacts();
  const { completeTask, uncompleteTask, isLoading: isTaskMutating } = useActivityLog();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );

  // Fetch dashboard data - filtered by current user for staff role
  // Staff users only see their assigned leads and opportunities
  const {
    kpis,
    deals,
    leads,
    upcomingTasks,
    recentActivities,
    isLoading,
    error,
    refresh,
  } = useDashboardData({ assigneeId: crmUser?.id });

  // All useCallback/useMemo hooks must be before conditional returns
  const canCompleteTask = useCallback(
    (task: SalesActivity) => {
      if (!securityContext) return false;
      const summary = getShareableAccessSummary(securityContext, task);
      return Boolean(summary?.canWrite || task.createdById === securityContext.userId);
    },
    [securityContext]
  );

  const taskReadOnlyReason = useCallback(
    (task: SalesActivity) => {
      if (!securityContext) return 'Read-only: missing scope';
      const summary = getShareableAccessSummary(securityContext, task);
      if (summary?.canWrite) return undefined;
      if (summary?.visibility === 'org' && !summary?.hasTeamAccess) {
        return 'Read-only: org-visible only';
      }
      return 'Read-only: not shared to you or your teams';
    },
    [securityContext]
  );

  // Calculate personal won value for quota
  const personalWonValue = useMemo(() => {
    return deals
      .filter((d) => d.status === 'won')
      .reduce((sum, d) => sum + d.valueCents, 0);
  }, [deals]);

  // Filter today's tasks for the TodaysTasks widget
  const todaysTasks = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return upcomingTasks.filter((task) => {
      if (!task.dueDate) return false;
      return task.dueDate >= today && task.dueDate < tomorrow;
    });
  }, [upcomingTasks]);

  const handleDealClick = (deal: Deal) => {
    setSelectedPipelineId(deal.pipelineId || pipelines[0]?.id || '');
    editDealModal.open(deal);
  };

  const handleTaskClick = () => {
    navigate('/activities');
  };

  const handleTopDealsNavigate = () => {
    navigate('/deals');
  };

  const handleTaskComplete = async (taskId: string) => {
    if (isTaskMutating) return;
    const task = upcomingTasks.find((t) => t.id === taskId);
    if (!task) return;
    if (!canCompleteTask(task)) return;

    if (task.isCompleted) {
      await uncompleteTask(taskId);
    } else {
      await completeTask(taskId);
    }
    refresh();
  };

  // Format currency helper
  const formatCurrency = (cents: number, currency: string = 'USD') => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
    }).format(cents / 100);
  };

  // Show loading state
  if (isLoading) {
    return (
      <PageLayout className="dashboard-page">
        <PageHeader
          eyebrow="Sales workspace"
          title="Sales Dashboard"
          subtitle={`Welcome back, ${welcomeName}.`}
        />
        <Card className="loading-state">
          <p>Loading dashboard...</p>
        </Card>
      </PageLayout>
    );
  }

  // Show error state
  if (error) {
    return (
      <PageLayout className="dashboard-page">
        <PageHeader
          eyebrow="Sales workspace"
          title="Sales Dashboard"
          subtitle={`Welcome back, ${welcomeName}.`}
        />
        <Card className="error-state">
          <p className="page-status-title">Error loading dashboard</p>
          <p className="page-status-detail">{error.message}</p>
          <Button variant="secondary" onClick={refresh}>
            Retry
          </Button>
        </Card>
      </PageLayout>
    );
  }

  // Get top deals (first 5 by value)
  const topDeals = [...deals]
    .filter(deal => deal.status === 'open')
    .sort((a, b) => b.valueCents - a.valueCents)
    .slice(0, 5);

  return (
    <PageLayout className="dashboard-page">
      <PageHeader
        eyebrow="Sales workspace"
        title="Sales Dashboard"
        subtitle="Track pipeline health, recent activity, and today's priorities."
        actions={(
          <>
            <Button onClick={() => addLeadModal.open()}>New Lead</Button>
            <Button variant="secondary" onClick={() => addDealModal.open()}>
              New Opportunity
            </Button>
            <Button variant="ghost" onClick={() => logActivityModal.open()}>
              Log Activity
            </Button>
          </>
        )}
      />

      <div className="dashboard-grid">
        {/* My Quota Progress - Hunter View Exclusive */}
        <div className="dashboard-highlight-row">
          <QuotaProgress
            currentValueCents={personalWonValue}
            targetValueCents={DEFAULT_PERSONAL_QUOTA_CENTS}
            label="My Monthly Quota"
          />
        </div>

        {/* KPI Cards - Personal metrics for staff */}
        <div className="kpi-cards">
          <Card className="kpi-card kpi-card-primary">
            <span className="kpi-label">My Pipeline</span>
            <span className="kpi-value">
              {formatCurrency(kpis.totalPipelineValue)}
            </span>
            <span className="kpi-sublabel">{deals.filter(d => d.status === 'open').length} open deals</span>
          </Card>
          <Card className="kpi-card kpi-card-success">
            <span className="kpi-label">Won This Month</span>
            <span className="kpi-value">{kpis.dealsWonThisMonth}</span>
            <span className="kpi-sublabel">
              {formatCurrency(kpis.dealsWonValue)}
            </span>
          </Card>
          <Card className="kpi-card">
            <span className="kpi-label">Conversion Rate</span>
            <span className="kpi-value">{kpis.conversionRate.toFixed(1)}%</span>
          </Card>
          <Card className="kpi-card">
            <span className="kpi-label">Avg Deal Size</span>
            <span className="kpi-value">
              {formatCurrency(kpis.averageDealSize)}
            </span>
          </Card>
        </div>

        {/* Who Do I Call Today - Hunter View Exclusive */}
        <section className="dashboard-section">
          <TodaysTasks
            tasks={todaysTasks}
            onTaskClick={handleTaskClick}
            onTaskComplete={handleTaskComplete}
            canCompleteTask={canCompleteTask}
            isLoading={isTaskMutating}
          />
        </section>

        {/* Pipeline by Stage - Personal */}
        <section className="dashboard-section pipeline-section">
          <h2>My Pipeline by Stage</h2>
          {kpis.dealsByStage.length === 0 ? (
            <p className="empty-message">No pipeline stages configured</p>
          ) : (
            <div className="pipeline-stage-grid">
              {kpis.dealsByStage.map((stage, index) => (
                <div
                  key={stage.stageId}
                  className={`pipeline-stage-card ${stage.stageName.toLowerCase() === 'won' ? 'stage-won' : ''} ${stage.stageName.toLowerCase() === 'lost' ? 'stage-lost' : ''}`}
                >
                  <div className="stage-indicator" style={{ opacity: 0.4 + (index * 0.1) }} />
                  <div className="stage-content">
                    <span className="stage-label">{stage.stageName}</span>
                    <span className="stage-deal-count">
                      {stage.count} {stage.count === 1 ? 'opportunity' : 'opportunities'}
                    </span>
                    <span className="stage-deal-value">{formatCurrency(stage.value)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>

        {/* Recent Activities */}
        <section className="dashboard-section">
          <ActivityFeed
            activities={recentActivities}
            limit={5}
            onActivityClick={() => navigate('/activities')}
          />
        </section>

        {/* Top Opportunities - Personal */}
        <section className="dashboard-section">
          <div className="section-header">
            <h2>My Top Opportunities</h2>
            <Button variant="ghost" size="sm" onClick={handleTopDealsNavigate}>
              View all
            </Button>
          </div>
          <div className="deals-list">
            {topDeals.length === 0 ? (
              <p>No open opportunities</p>
            ) : (
              topDeals.map((deal) => (
                <button
                  key={deal.id}
                  className="deal-item"
                  onClick={() => handleDealClick(deal)}
                >
                  <div className="deal-title">{deal.title}</div>
                  <div className="deal-value">
                    {formatCurrency(deal.valueCents, deal.currency)}
                  </div>
                </button>
              ))
            )}
          </div>
        </section>

        {/* Upcoming Tasks */}
        <section className="dashboard-section">
          <UpcomingTasks
            tasks={upcomingTasks.slice(0, 8)}
            onTaskComplete={handleTaskComplete}
            canCompleteTask={canCompleteTask}
            getReadOnlyReason={taskReadOnlyReason}
            onTaskClick={handleTaskClick}
          />
        </section>
      </div>

      {/* Quick action modals */}
      <CreateLeadModal
        isOpen={addLeadModal.isOpen}
        onClose={addLeadModal.close}
        onSuccess={() => {
          refresh();
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
          refresh();
          addDealModal.close();
        }}
      />

      <LogActivityModal
        isOpen={logActivityModal.isOpen}
        onClose={logActivityModal.close}
        entityType="deal"
        entityId={deals[0]?.id || ''}
        deals={deals.map((d) => ({ id: d.id, title: d.title }))}
        clients={contacts.map((c) => ({
          id: c.id,
          name: `${c.firstName} ${c.lastName}`.trim(),
        }))}
        leads={leads.map((l) => ({
          id: l.id,
          name: `${l.firstName} ${l.lastName}`.trim(),
        }))}
        onSuccess={() => {
          refresh();
          logActivityModal.close();
        }}
        teamMembers={[]}
      />

      <CreateDealModal
        isOpen={editDealModal.isOpen}
        onClose={() => {
          editDealModal.close();
        }}
        initialData={editDealModal.data || undefined}
        pipelines={pipelines}
        stages={stages}
        clients={contacts}
        onSuccess={() => {
          refresh();
          editDealModal.close();
        }}
      />
    </PageLayout>
  );
}
