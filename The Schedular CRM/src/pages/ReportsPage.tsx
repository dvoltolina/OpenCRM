import { useMemo, useCallback, useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { useDashboardData, useReportViews, usePipelines, useReportingAggregations } from '../hooks';
import { useDashboardKPIs } from '../hooks/useDashboardKPIs';
import { useAuth } from '../context/AuthContext';
import { getFeatureFlags } from '../config/features';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import type { ReportViewFilters, ReportView } from '../types/models';
import { AuditLogService } from '../services/AuditLogService';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../lib/security-context';
import { ReportExportPanel } from '../components/reports/ReportExportPanel';
import { SequencePerformanceReport } from '../components/reports/SequencePerformanceReport';
import { getReportExportService } from '../services/report-export-service';
import { downloadExportContent } from '../services/export-download';
import {
  DEFAULT_FILTERS,
  formatCurrency,
  formatDateInput,
  parseDateInput,
  parseCommaSeparated,
  groupRevenueByMonth,
  summarizeLeadSources,
} from './report-utils';
import type { ReportFilterState } from './report-utils';
import './styles/reports.css';

type ReportTab = 'overview' | 'performance' | 'sequences' | 'exports';

const REPORT_TAB_ALIASES: Record<string, ReportTab> = {
  overview: 'overview',
  performance: 'performance',
  sequences: 'sequences',
  sequence: 'sequences',
  exports: 'exports',
  export: 'exports',
};

const REPORT_TAB_META: Record<ReportTab, { label: string; description: string }> = {
  overview: {
    label: 'Overview',
    description: 'Pipeline health, win rates, and revenue trends across the current filter set.',
  },
  performance: {
    label: 'Performance',
    description: 'Owner, team, and source-level performance tables for operational review.',
  },
  sequences: {
    label: 'Sequences',
    description: 'Sequence activity and conversion signals for outbound programs.',
  },
  exports: {
    label: 'Scheduled Exports',
    description: 'Manual and scheduled delivery controls for downstream reporting.',
  },
};

export function ReportsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const features = getFeatureFlags();
  const savedViewsEnabled =
    features.enableAdvancedReporting !== false && features.enableReportSavedViews !== false;
  const { crmUser, businessId } = useAuth();
  const { deals, leads, recentActivities, stages, isLoading, error, refresh } = useDashboardData();
  const { pipelines, isLoading: pipelinesLoading, error: pipelinesError } = usePipelines();
  const {
    views,
    isLoading: viewsLoading,
    error: viewError,
    createView,
    deleteView,
    refresh: refreshViews,
    canManage,
  } = useReportViews(savedViewsEnabled);
  const auditLogService = useMemo(() => new AuditLogService(), []);
  const reportExportService = useMemo(() => getReportExportService(), []);
  const [filters, setFilters] = useState<ReportFilterState>(DEFAULT_FILTERS);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [newViewName, setNewViewName] = useState('');
  const [shareTeams, setShareTeams] = useState('');
  const [selectedViewId, setSelectedViewId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [exportLoading, setExportLoading] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);
  const availableTabs = useMemo<ReportTab[]>(
    () => [
      'overview',
      'performance',
      ...(features.enableSequences ? (['sequences'] as const) : []),
      ...(
        features.enableReports && features.enableAdvancedReporting !== false && features.enableImportExport
          ? (['exports'] as const)
          : []
      ),
    ],
    [features.enableAdvancedReporting, features.enableImportExport, features.enableReports, features.enableSequences]
  );
  const rawTab = searchParams.get('tab');
  const activeTab = useMemo<ReportTab>(() => {
    if (!rawTab) return 'overview';
    const normalized = REPORT_TAB_ALIASES[rawTab.toLowerCase()];
    return normalized && availableTabs.includes(normalized) ? normalized : 'overview';
  }, [availableTabs, rawTab]);
  const activeTabMeta = REPORT_TAB_META[activeTab];

  useEffect(() => {
    if (!rawTab) return;
    if (rawTab !== activeTab) {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', activeTab);
      setSearchParams(nextParams, { replace: true });
    }
  }, [activeTab, rawTab, searchParams, setSearchParams]);

  const handleTabChange = useCallback(
    (tab: ReportTab) => {
      const nextParams = new URLSearchParams(searchParams);
      nextParams.set('tab', tab);
      setSearchParams(nextParams, { replace: true });
    },
    [searchParams, setSearchParams]
  );

  const startDate = useMemo(() => parseDateInput(filters.startDate), [filters.startDate]);
  const endDate = useMemo(() => parseDateInput(filters.endDate), [filters.endDate]);

  const reportingFilters = useMemo(
    () => ({
      startDate: startDate || undefined,
      endDate: endDate || undefined,
      pipelineIds: filters.pipelineId ? [filters.pipelineId] : undefined,
      stageIds: filters.stageIds.length ? filters.stageIds : undefined,
      ownerIds: filters.ownerIds.length ? filters.ownerIds : undefined,
      teamIds: filters.teamIds.length ? filters.teamIds : undefined,
      sources: filters.leadSources.length ? filters.leadSources : undefined,
      includeStageBreakdown: true,
      bucket: 'monthly' as const,
    }),
    [endDate, filters.leadSources, filters.ownerIds, filters.pipelineId, filters.stageIds, filters.teamIds, startDate]
  );

  const stageNameMap = useMemo(
    () => new Map(stages.map((stage) => [stage.id, stage.name])),
    [stages]
  );

  const {
    data: reportingData,
    isLoading: reportingLoading,
    error: _reportingError,
    isUnauthorized: reportingUnauthorized,
  } = useReportingAggregations(reportingFilters);

  const matchesDateRange = useCallback(
    (date?: Date | null) => {
      if (!date) return true;
      const value = date instanceof Date ? date : new Date(date);
      if (startDate && value < startDate) return false;
      if (endDate && value > endDate) return false;
      return true;
    },
    [startDate, endDate]
  );

  const filteredDeals = useMemo(
    () =>
      deals.filter((deal) => {
        const compareDate = (deal.closedAt as Date) || (deal.createdAt as Date) || null;
        if (!matchesDateRange(compareDate)) return false;
        if (filters.pipelineId && deal.pipelineId !== filters.pipelineId) return false;
        if (filters.statuses.length && !filters.statuses.includes(deal.status)) return false;
        if (filters.ownerIds.length) {
          if (!deal.ownerId || !filters.ownerIds.includes(deal.ownerId)) return false;
        }
        if (filters.assigneeIds.length) {
          if (!deal.assigneeId || !filters.assigneeIds.includes(deal.assigneeId)) return false;
        }
        if (filters.teamIds.length) {
          const dealTeams = sanitizeTeamIds((deal as unknown as { teamIds?: string[] }).teamIds || []);
          if (!dealTeams.some((teamId) => filters.teamIds.includes(teamId))) return false;
        }
        return true;
      }),
    [deals, filters.assigneeIds, filters.ownerIds, filters.pipelineId, filters.statuses, filters.teamIds, matchesDateRange]
  );

  const filteredLeads = useMemo(
    () =>
      leads.filter((lead) => {
        const createdAt = lead.createdAt as Date;
        if (!matchesDateRange(createdAt)) return false;
        if (filters.leadSources.length && !filters.leadSources.includes(lead.source)) return false;
        if (filters.ownerIds.length && lead.ownerId && !filters.ownerIds.includes(lead.ownerId)) {
          return false;
        }
        if (filters.teamIds.length) {
          const leadTeams = sanitizeTeamIds(lead.teamIds || []);
          if (!leadTeams.some((teamId) => filters.teamIds.includes(teamId))) return false;
        }
        return true;
      }),
    [filters.leadSources, filters.ownerIds, filters.teamIds, leads, matchesDateRange]
  );

  const filteredActivities = useMemo(
    () =>
      recentActivities.filter((activity) => {
        const createdAt = activity.createdAt as Date | undefined;
        return matchesDateRange(createdAt);
      }),
    [matchesDateRange, recentActivities]
  );

  const filteredKpis = useDashboardKPIs({
    deals: filteredDeals,
    leads: filteredLeads,
    stages,
  });

  const wonDeals = useMemo(() => filteredDeals.filter((d) => d.status === 'won'), [filteredDeals]);
  const lostDeals = useMemo(() => filteredDeals.filter((d) => d.status === 'lost'), [filteredDeals]);
  const winRate = useMemo(() => {
    const total = wonDeals.length + lostDeals.length;
    return total === 0 ? 0 : (wonDeals.length / total) * 100;
  }, [wonDeals, lostDeals]);

  const revenueOverTime = useMemo(() => groupRevenueByMonth(wonDeals), [wonDeals]);
  const leadSourcesData = useMemo(() => summarizeLeadSources(filteredLeads), [filteredLeads]);

  const myDealsOnly = Boolean(crmUser && filters.assigneeIds.includes(crmUser.id));
  const activeFiltersCount = useMemo(() => {
    let count = 0;
    if (filters.pipelineId) count++;
    if (filters.statuses.length) count++;
    if (filters.startDate || filters.endDate) count++;
    if (filters.stageIds.length) count++;
    if (filters.ownerIds.length) count++;
    if (filters.teamIds.length) count++;
    if (filters.leadSources.length) count++;
    if (filters.assigneeIds.length) count++;
    return count;
  }, [filters]);

  const handleStatusToggle = (status: 'open' | 'won' | 'lost') => {
    setFilters((prev) => {
      const next = prev.statuses.includes(status)
        ? prev.statuses.filter((s) => s !== status)
        : [...prev.statuses, status];
      return { ...prev, statuses: next };
    });
  };

  const buildViewFilters = useCallback((): ReportViewFilters => {
    return {
      startDate,
      endDate,
      pipelineId: filters.pipelineId || null,
      stageIds: filters.stageIds.length ? filters.stageIds : undefined,
      statuses: filters.statuses.length ? filters.statuses : undefined,
      assigneeIds: filters.assigneeIds.length ? filters.assigneeIds : undefined,
      leadSources: filters.leadSources.length ? filters.leadSources : undefined,
      ownerIds: filters.ownerIds.length ? filters.ownerIds : undefined,
      teamIds: filters.teamIds.length ? filters.teamIds : undefined,
    };
  }, [endDate, filters, startDate]);

  const buildAuditContext = useCallback(() => {
    if (!crmUser || !businessId) return null;
    const teamIds = sanitizeTeamIds(crmUser.teamIds || []);
    const managedTeamIds = sanitizeTeamIds(crmUser.managedTeamIds || []);
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      teamIds,
      managedTeamIds,
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  const logReportAction = useCallback(
    async (
      action: 'create' | 'delete' | 'export' | 'read',
      entityId: string,
      metadata?: Record<string, unknown>
    ) => {
      const context = buildAuditContext();
      if (!context) return;
      await auditLogService.logAction(context, {
        action,
        entityType: action === 'export' ? 'report' : 'reportView',
        entityId,
        metadata,
      });
    },
    [auditLogService, buildAuditContext]
  );

  const applyView = useCallback(
    (view: ReportView) => {
      setFilters({
        ...DEFAULT_FILTERS,
        startDate: formatDateInput(view.filters.startDate),
        endDate: formatDateInput(view.filters.endDate),
        pipelineId: view.filters.pipelineId || '',
        stageIds: view.filters.stageIds || [],
        statuses: view.filters.statuses || [],
        assigneeIds: view.filters.assigneeIds || [],
        leadSources: view.filters.leadSources || [],
        ownerIds: view.filters.ownerIds || [],
        teamIds: view.filters.teamIds || [],
      });
      setSelectedViewId(view.id);
      setShareTeams((view.teamIds || []).join(', '));
      setActionError(null);
      if (savedViewsEnabled) {
        logReportAction('read', view.id, {
          ownerFilters: view.filters.ownerIds?.length || 0,
          teamFilters: view.filters.teamIds?.length || 0,
        }).catch(() => {});
      }
    },
    [logReportAction, savedViewsEnabled]
  );

  const exportReporting = useCallback(
    async (format: 'csv' | 'pdf') => {
      const context = buildAuditContext();
      if (!context) {
        setExportError('Not authenticated');
        return;
      }

      setExportLoading(true);
      setExportError(null);

      try {
        const result = await reportExportService.runExportNow(context, {
          format,
          filters: reportingFilters,
          delivery: { method: 'link' },
        });

        downloadExportContent(
          result.content,
          result.contentType,
          `reporting_aggregates.${format}`
        );
      } catch (err) {
        setExportError((err as Error).message);
      } finally {
        setExportLoading(false);
      }
    },
    [buildAuditContext, reportExportService, reportingFilters]
  );

  const handleSaveView = useCallback(async () => {
    if (!savedViewsEnabled) {
      setActionError('Saved views are disabled by feature flag');
      return;
    }
    if (!newViewName.trim()) {
      setActionError('View name is required');
      return;
    }

    try {
      const teamIds = parseCommaSeparated(shareTeams);
      const view = await createView({
        name: newViewName.trim(),
        description: undefined,
        filters: buildViewFilters(),
        teamIds,
      });
      setSelectedViewId(view.id);
      setShareTeams(teamIds.join(', '));
      setActionError(null);
      setNewViewName('');
      await logReportAction('create', view.id, { teams: teamIds.length });
    } catch (err) {
      setActionError((err as Error).message);
    }
  }, [buildViewFilters, createView, logReportAction, newViewName, savedViewsEnabled, shareTeams]);

  const handleDeleteView = useCallback(
    async (id: string) => {
      try {
        await deleteView(id);
        if (selectedViewId === id) {
          setSelectedViewId(null);
          setFilters({ ...DEFAULT_FILTERS });
        }
        await logReportAction('delete', id);
      } catch (err) {
        setActionError((err as Error).message);
      }
    },
    [deleteView, logReportAction, selectedViewId]
  );

  const clearFilters = useCallback(() => {
    setFilters({ ...DEFAULT_FILTERS });
    setSelectedViewId(null);
  }, []);

  const combinedLoading = isLoading || viewsLoading || pipelinesLoading || reportingLoading;
  const combinedError = (error as Error | null) || (viewError as Error | null) || (pipelinesError as Error | null);
  const exportsDisabledReason = reportingUnauthorized
    ? 'Reporting access is restricted for the selected pipeline or team filters.'
    : undefined;

  // Loading state
  if (combinedLoading) {
    return (
      <PageLayout width="wide" className="reports-page reports-page--loading">
        <PageHeader
          eyebrow="Reporting"
          title="Reports"
          subtitle="Loading saved views, aggregations, and workspace reporting metrics."
        />
        <Card className="reports-page__status-card" padding="lg">
          <div className="reports-loading">
            <div className="reports-loading__spinner" />
            <p>Loading reports...</p>
          </div>
        </Card>
      </PageLayout>
    );
  }

  // Error state
  if (combinedError) {
    return (
      <PageLayout width="wide" className="reports-page reports-page--error">
        <PageHeader
          eyebrow="Reporting"
          title="Reports"
          subtitle="The reporting workspace could not finish loading the current data set."
        />
        <Card padding="lg">
          <EmptyState
            eyebrow="Load Error"
            title="Reports are unavailable right now"
            description={`Error loading reports: ${combinedError.message}`}
            actions={(
              <Button
                onClick={() => {
                  refresh();
                  refreshViews();
                }}
              >
                Retry
              </Button>
            )}
          />
        </Card>
      </PageLayout>
    );
  }

  const topStages = (reportingData?.stageConversions || []).slice(0, 5);
  const topLostReasons = (reportingData?.lostReasons || []).slice(0, 5);
  const recentBuckets = (reportingData?.timeBuckets || []).slice(-5);

  return (
    <PageLayout width="wide" className="reports-page">
      <PageHeader
        eyebrow="Reporting"
        title="Reports"
        subtitle="Track pipeline health, performance, saved views, and export-ready reporting from one operational surface."
        actions={(
          <div className="reports-page__header-actions">
            {features.enableAdvancedReporting && (
              <Link className="ui-button ui-button--secondary ui-button--md" to="/reports/builder">
                Open Builder
              </Link>
            )}
            <Button
              variant="secondary"
              onClick={() => exportReporting('csv')}
              disabled={!features.enableImportExport || exportLoading || reportingUnauthorized}
            >
              {exportLoading ? 'Exporting...' : 'Export CSV'}
            </Button>
            <Button
              variant="secondary"
              onClick={() => exportReporting('pdf')}
              disabled={!features.enableImportExport || exportLoading || reportingUnauthorized}
            >
              Export PDF
            </Button>
          </div>
        )}
      />

      <Card className="reports-page__hero" padding="lg" tone="accent">
        <div className="reports-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Current View</p>
          <h2>{activeTabMeta.label}</h2>
          <p>{activeTabMeta.description}</p>
        </div>
        <div className="reports-page__hero-stats">
          <div>
            <span>Filters</span>
            <strong>{activeFiltersCount}</strong>
          </div>
          <div>
            <span>Saved views</span>
            <strong>{savedViewsEnabled ? views.length : 'Off'}</strong>
          </div>
          <div>
            <span>Sections</span>
            <strong>{availableTabs.length}</strong>
          </div>
        </div>
      </Card>

      {features.enableAdvancedReporting && (
        <Card className="reports-page__builder-callout" padding="md" tone="subtle">
          <div>
            <p className="ui-empty-state__eyebrow">Builder Workspace</p>
            <h2>Custom report definitions live in Report Builder</h2>
            <p>
              Use the builder for custom report definitions, scheduling, and delivery automation.
              This page remains the KPI, saved-view, and export operations surface.
            </p>
          </div>
          <Link className="ui-button ui-button--ghost ui-button--sm" to="/reports/builder">
            Go to Builder
          </Link>
        </Card>
      )}

      <div className="reports-page__alerts">
        {reportingUnauthorized && (
          <div className="reports-alert reports-alert--warning">
            <span className="reports-alert__content">
              Reporting access is restricted for these filters. Adjust pipeline/team filters to view
              results.
            </span>
            <Button variant="ghost" size="sm" className="reports-alert__action" onClick={clearFilters}>
              Clear filters
            </Button>
          </div>
        )}
        {exportError && (
          <div className="reports-alert reports-alert--error">
            <span className="reports-alert__content">Export failed: {exportError}</span>
          </div>
        )}
      </div>

      <Card className="reports-filters-panel" padding="md" tone="subtle">
        <button
          type="button"
          className="reports-filters-header"
          onClick={() => setFiltersOpen((open) => !open)}
          aria-expanded={filtersOpen}
        >
          <div className="reports-filters-header__left">
            <span className="reports-filters-header__title">
              Filters
              {activeFiltersCount > 0 && (
                <span className="reports-tab__badge">{activeFiltersCount}</span>
              )}
            </span>
            {selectedViewId && (
              <span className="reports-filters-header__count">
                Using saved view: {views.find((v) => v.id === selectedViewId)?.name}
              </span>
            )}
          </div>
          <span className={`reports-filters-header__toggle ${filtersOpen ? 'reports-filters-header__toggle--open' : ''}`}>
            v
          </span>
        </button>
        <div className={`reports-filters-content ${filtersOpen ? 'reports-filters-content--open' : ''}`}>
          <div className="reports-filters-grid">
            <div className="reports-filter-group">
              <label htmlFor="pipeline-filter">Pipeline</label>
              <select
                id="pipeline-filter"
                value={filters.pipelineId}
                disabled={pipelinesLoading}
                onChange={(e) => setFilters((prev) => ({ ...prev, pipelineId: e.target.value }))}
              >
                <option value="">All pipelines</option>
                {pipelines.map((pipeline) => (
                  <option key={pipeline.id} value={pipeline.id}>{pipeline.name}</option>
                ))}
              </select>
            </div>

            <div className="reports-filter-group">
              <label>Status</label>
              <div className="reports-status-filters">
                {(['open', 'won', 'lost'] as const).map((status) => (
                  <label key={status} className="reports-status-checkbox">
                    <input
                      type="checkbox"
                      checked={filters.statuses.includes(status)}
                      onChange={() => handleStatusToggle(status)}
                    />
                    {status.charAt(0).toUpperCase() + status.slice(1)}
                  </label>
                ))}
              </div>
            </div>

            <div className="reports-filter-group">
              <label>Date Range</label>
              <div className="reports-filter-group__date-range">
                <input
                  type="date"
                  value={filters.startDate}
                  onChange={(e) => setFilters((prev) => ({ ...prev, startDate: e.target.value }))}
                  aria-label="Start date"
                />
                <input
                  type="date"
                  value={filters.endDate}
                  onChange={(e) => setFilters((prev) => ({ ...prev, endDate: e.target.value }))}
                  aria-label="End date"
                />
              </div>
            </div>

            <div className="reports-filter-group">
              <label htmlFor="stage-filter">Stages</label>
              <select
                id="stage-filter"
                multiple
                value={filters.stageIds}
                onChange={(e) =>
                  setFilters((prev) => ({
                    ...prev,
                    stageIds: Array.from(e.target.selectedOptions).map((o) => o.value),
                  }))
                }
              >
                {stages.map((stage) => (
                  <option key={stage.id} value={stage.id}>{stage.name}</option>
                ))}
              </select>
              <small>Cmd/Ctrl + click for multiple</small>
            </div>

            <div className="reports-filter-group">
              <label htmlFor="owner-filter">Owner IDs</label>
              <input
                id="owner-filter"
                type="text"
                placeholder="owner-a, owner-b"
                value={filters.ownerIds.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, ownerIds: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>

            <div className="reports-filter-group">
              <label htmlFor="team-filter">Team IDs</label>
              <input
                id="team-filter"
                type="text"
                placeholder="team-a, team-b"
                value={filters.teamIds.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, teamIds: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>

            <div className="reports-filter-group">
              <label>
                <input
                  type="checkbox"
                  checked={myDealsOnly}
                  onChange={() =>
                    setFilters((prev) => ({
                      ...prev,
                      assigneeIds: myDealsOnly ? [] : crmUser ? [crmUser.id] : [],
                    }))
                  }
                />{' '}
                My deals only
              </label>
            </div>
          </div>

          <div className="reports-filters-actions">
            <Button variant="secondary" size="sm" onClick={clearFilters}>
              Clear all filters
            </Button>
          </div>

          {savedViewsEnabled && (
            <div className="reports-saved-views">
              <div className="reports-saved-views__header">
                <span className="reports-saved-views__title">Saved Views</span>
                {selectedViewId && (
                  <Button variant="ghost" size="sm" onClick={() => setSelectedViewId(null)}>
                    Clear selection
                  </Button>
                )}
              </div>
              {actionError ? (
                <div className="reports-alert reports-alert--error reports-alert--inline">
                  <span className="reports-alert__content">{actionError}</span>
                </div>
              ) : null}
              <div className="reports-saved-views__list">
                {viewsLoading ? (
                  <p>Loading...</p>
                ) : views.length === 0 ? (
                  <p className="reports-saved-views__empty">No saved views yet</p>
                ) : (
                  views.map((view) => (
                    <div
                      key={view.id}
                      className={`reports-saved-view-item ${view.id === selectedViewId ? 'reports-saved-view-item--active' : ''}`}
                      onClick={() => applyView(view)}
                    >
                      <div>
                        <span className="reports-saved-view-item__name">{view.name}</span>
                        <div className="reports-saved-view-item__meta">
                          {view.ownerName || 'Unknown'} | {view.teamIds?.length || 0} teams
                        </div>
                      </div>
                      {canManage(view) && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeleteView(view.id);
                          }}
                        >
                          Delete
                        </Button>
                      )}
                    </div>
                  ))
                )}
              </div>
              <div className="reports-saved-views__form">
                <input
                  type="text"
                  placeholder="View name"
                  value={newViewName}
                  onChange={(e) => setNewViewName(e.target.value)}
                />
                <Button size="sm" onClick={handleSaveView}>
                  Save
                </Button>
              </div>
            </div>
          )}
        </div>
      </Card>

      <Card className="reports-page__tabs-card" padding="md">
        <Toolbar
          start={(
            <div className="reports-tabs" role="tablist" aria-label="Report sections">
              <button
                className={`reports-tab ${activeTab === 'overview' ? 'reports-tab--active' : ''}`}
                onClick={() => handleTabChange('overview')}
              >
                Overview
              </button>
              <button
                className={`reports-tab ${activeTab === 'performance' ? 'reports-tab--active' : ''}`}
                onClick={() => handleTabChange('performance')}
              >
                Performance
              </button>
              {features.enableSequences && (
                <button
                  className={`reports-tab ${activeTab === 'sequences' ? 'reports-tab--active' : ''}`}
                  onClick={() => handleTabChange('sequences')}
                >
                  Sequences
                </button>
              )}
              {availableTabs.includes('exports') && (
                <button
                  className={`reports-tab ${activeTab === 'exports' ? 'reports-tab--active' : ''}`}
                  onClick={() => handleTabChange('exports')}
                >
                  Scheduled Exports
                </button>
              )}
            </div>
          )}
          end={<span className="ui-results-count">{availableTabs.length} sections</span>}
        />
      </Card>

      <main className="reports-page__content">
      {/* Tab Content */}
      {activeTab === 'overview' && (
        <>
          {/* KPI Cards */}
          <div className="reports-kpi-grid">
            <div className="reports-kpi-card">
              <div className="reports-kpi-card__label">Opportunities Won</div>
              <div className="reports-kpi-card__value reports-kpi-card__value--success">
                {reportingData?.summary.wonCount ?? wonDeals.length}
              </div>
              <div className="reports-kpi-card__subtitle">
                {formatCurrency(wonDeals.reduce((sum, d) => sum + d.valueCents, 0))}
              </div>
            </div>
            <div className="reports-kpi-card">
              <div className="reports-kpi-card__label">Opportunities Lost</div>
              <div className="reports-kpi-card__value reports-kpi-card__value--danger">
                {reportingData?.summary.lostCount ?? lostDeals.length}
              </div>
            </div>
            <div className="reports-kpi-card">
              <div className="reports-kpi-card__label">Win Rate</div>
              <div className="reports-kpi-card__value">
                {reportingData?.velocity ? reportingData.velocity.winRate.toFixed(1) : winRate.toFixed(1)}%
              </div>
            </div>
            <div className="reports-kpi-card">
              <div className="reports-kpi-card__label">Avg Cycle Days</div>
              <div className="reports-kpi-card__value">
                {reportingData?.velocity ? reportingData.velocity.averageCycleDays.toFixed(1) : '0'}
              </div>
            </div>
            <div className="reports-kpi-card">
              <div className="reports-kpi-card__label">Activities (7d)</div>
              <div className="reports-kpi-card__value">{filteredActivities.length}</div>
              <div className="reports-kpi-card__subtitle">
                {filteredActivities.filter((a) => a.type === 'task').length} tasks,{' '}
                {filteredActivities.filter((a) => a.type === 'meeting').length} meetings
              </div>
            </div>
          </div>

          {/* Pipeline Overview */}
          <div className="reports-section">
            <div className="reports-section__header">
              <div>
                <h2 className="reports-section__title">Pipeline Overview</h2>
                <p className="reports-section__subtitle">Opportunities by stage</p>
              </div>
            </div>
            <div className="reports-pipeline-grid">
              {filteredKpis.dealsByStage.map((stage, index) => {
                const stageClasses = ['lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost'];
                const stageClass = stageClasses[index % stageClasses.length];
                return (
                  <div key={stage.stageId} className={`reports-pipeline-card reports-pipeline-card--${stageClass}`}>
                    <div className="reports-pipeline-card__name">{stage.stageName}</div>
                    <div className="reports-pipeline-card__count">{stage.count}</div>
                    <div className="reports-pipeline-card__value">{formatCurrency(stage.value)}</div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Breakdowns */}
          <div className="reports-section">
            <div className="reports-section__header">
              <h2 className="reports-section__title">Insights</h2>
              {reportingData?.generatedAt && (
                <span className="reports-timestamp">
                  Generated {reportingData.generatedAt.toLocaleString()}
                </span>
              )}
            </div>
            <div className="reports-breakdowns">
              <div className="reports-breakdown-card">
                <h3 className="reports-breakdown-card__title">Stage Conversions</h3>
                {topStages.length === 0 ? (
                  <p className="reports-breakdown-empty">No stage data</p>
                ) : (
                  <ul className="reports-breakdown-card__list">
                    {topStages.map((stage) => (
                      <li key={stage.stageId}>
                        <span>{stageNameMap.get(stage.stageId) || stage.stageId}</span>
                        <span>{stage.conversionRate.toFixed(1)}% ({stage.won}/{stage.entered})</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="reports-breakdown-card">
                <h3 className="reports-breakdown-card__title">Top Lost Reasons</h3>
                {topLostReasons.length === 0 ? (
                  <p className="reports-breakdown-empty">No lost reasons</p>
                ) : (
                  <ul className="reports-breakdown-card__list">
                    {topLostReasons.map((reason) => (
                      <li key={reason.reason}>
                        <span>{reason.reason}</span>
                        <span>{reason.count} ({formatCurrency(reason.valueCents)})</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="reports-breakdown-card">
                <h3 className="reports-breakdown-card__title">Revenue Trend</h3>
                {recentBuckets.length === 0 ? (
                  <p className="reports-breakdown-empty">No time data</p>
                ) : (
                  <ul className="reports-breakdown-card__list">
                    {recentBuckets.map((bucket) => (
                      <li key={`${bucket.bucket}-${bucket.periodStart.toISOString()}`}>
                        <span>{bucket.periodStart.toISOString().slice(0, 10)}</span>
                        <span>{formatCurrency(bucket.metrics.wonValueCents)}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="reports-breakdown-card">
                <h3 className="reports-breakdown-card__title">Lead Sources</h3>
                {leadSourcesData.length === 0 ? (
                  <p className="reports-breakdown-empty">No leads yet</p>
                ) : (
                  <ul className="reports-breakdown-card__list">
                    {leadSourcesData.slice(0, 5).map((entry) => (
                      <li key={entry.source}>
                        <span>{entry.source}</span>
                        <span>{entry.count} leads</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </div>
          </div>

          {/* Revenue Chart Placeholder */}
          <div className="reports-section">
            <div className="reports-section__header">
              <h2 className="reports-section__title">Revenue Over Time</h2>
            </div>
            {revenueOverTime.length === 0 ? (
              <div className="reports-chart-placeholder">No won deals yet</div>
            ) : (
              <div className="reports-breakdowns">
                {revenueOverTime.map((row) => (
                  <div key={row.period} className="reports-breakdown-card" style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 12, color: 'var(--color-text-muted)', marginBottom: 4 }}>{row.period}</div>
                    <div style={{ fontSize: 20, fontWeight: 600 }}>{formatCurrency(row.valueCents)}</div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </>
      )}

      {activeTab === 'performance' && (
        <>
          {/* Owner Performance */}
          <div className="reports-section">
            <div className="reports-section__header">
              <h2 className="reports-section__title">Owner Performance</h2>
            </div>
            {!reportingData?.ownerPerformance?.length ? (
              <div className="reports-empty">
                <div className="reports-empty__title">No owner data available</div>
                <p className="reports-empty__description">Performance data will appear once there are closed deals.</p>
              </div>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table className="reports-table">
                  <thead>
                    <tr>
                      <th>Owner</th>
                      <th>Win Rate</th>
                      <th>Avg Cycle (d)</th>
                      <th>Won</th>
                      <th>Lost</th>
                      <th>Won Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reportingData.ownerPerformance.map((owner) => (
                      <tr key={owner.ownerOrTeamId}>
                        <td>{owner.ownerOrTeamName || owner.ownerOrTeamId}</td>
                        <td>{(owner.winRate ?? 0).toFixed(1)}%</td>
                        <td>{(owner.averageCycleDays ?? 0).toFixed(1)}</td>
                        <td style={{ color: 'var(--color-success)' }}>{owner.metrics?.wonCount ?? 0}</td>
                        <td style={{ color: 'var(--color-danger)' }}>{owner.metrics?.lostCount ?? 0}</td>
                        <td>{formatCurrency(owner.metrics?.wonValueCents ?? 0)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Team Performance */}
          <div className="reports-section">
            <div className="reports-section__header">
              <h2 className="reports-section__title">Team Performance</h2>
            </div>
            {!reportingData?.teamPerformance?.length ? (
              <div className="reports-empty">
                <div className="reports-empty__title">No team data available</div>
              </div>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table className="reports-table">
                  <thead>
                    <tr>
                      <th>Team</th>
                      <th>Win Rate</th>
                      <th>Avg Cycle (d)</th>
                      <th>Won</th>
                      <th>Lost</th>
                      <th>Won Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reportingData.teamPerformance.map((team) => (
                      <tr key={team.ownerOrTeamId}>
                        <td>{team.ownerOrTeamName || team.ownerOrTeamId}</td>
                        <td>{(team.winRate ?? 0).toFixed(1)}%</td>
                        <td>{(team.averageCycleDays ?? 0).toFixed(1)}</td>
                        <td style={{ color: 'var(--color-success)' }}>{team.metrics?.wonCount ?? 0}</td>
                        <td style={{ color: 'var(--color-danger)' }}>{team.metrics?.lostCount ?? 0}</td>
                        <td>{formatCurrency(team.metrics?.wonValueCents ?? 0)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Source Cohorts */}
          <div className="reports-section">
            <div className="reports-section__header">
              <h2 className="reports-section__title">Source Cohorts</h2>
              <p className="reports-section__subtitle">Conversion and revenue by lead source</p>
            </div>
            {!reportingData?.cohorts?.length ? (
              <div className="reports-empty">
                <div className="reports-empty__title">No cohort data available</div>
              </div>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table className="reports-table">
                  <thead>
                    <tr>
                      <th>Source</th>
                      <th>Period</th>
                      <th>Leads</th>
                      <th>Converted</th>
                      <th>Conversion</th>
                      <th>Won Value</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reportingData.cohorts.map((cohort, idx) => (
                      <tr key={`${cohort.source}-${idx}`}>
                        <td>{cohort.source}</td>
                        <td>
                          {cohort.periodStart instanceof Date ? cohort.periodStart.toISOString().slice(0, 10) : String(cohort.periodStart).slice(0, 10)} - {cohort.periodEnd instanceof Date ? cohort.periodEnd.toISOString().slice(0, 10) : String(cohort.periodEnd).slice(0, 10)}
                        </td>
                        <td>{cohort.leadCount ?? 0}</td>
                        <td>{cohort.convertedCount ?? 0}</td>
                        <td>{(cohort.conversionRate ?? 0).toFixed(1)}%</td>
                        <td>{formatCurrency(cohort.wonValueCents ?? 0)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}

      {activeTab === 'sequences' && features.enableSequences && (
        <SequencePerformanceReport />
      )}

      {activeTab === 'exports' && (
        <ReportExportPanel
          filters={reportingFilters}
          featureFlags={features}
          disabledReason={exportsDisabledReason}
        />
      )}
      </main>
    </PageLayout>
  );
}
