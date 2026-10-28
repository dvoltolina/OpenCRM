import { describe, it, expect, vi, type Mock } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ReportingSnapshot } from '../ReportingSnapshot';
import { ReportFiltersPanel } from '../ReportFiltersPanel';
import { ReportingBreakdowns } from '../ReportingBreakdowns';
import { ReportingPerformance } from '../ReportingPerformance';
import { ReportingCohorts } from '../ReportingCohorts';
import type { ReportingAggregationResult } from '../../../types/reporting';
import type { ReportView } from '../../../types/models';
import { DEFAULT_FILTERS } from '../../../pages/report-utils';
import { ReportExportPanel } from '../ReportExportPanel';
import type { FeatureFlags } from '../../../config/features';
import { useReportExports } from '../../../hooks/useReportExports';
import { useAuth } from '../../../context/AuthContext';

vi.mock('../../../hooks/useReportExports', () => ({
  useReportExports: vi.fn(),
}));
vi.mock('../../../context/AuthContext', () => ({
  useAuth: vi.fn(),
}));

describe('ReportingSnapshot', () => {
  const sample: ReportingAggregationResult = {
    generatedAt: new Date(),
    filters: {},
    summary: {
      openCount: 1,
      wonCount: 2,
      lostCount: 0,
      openValueCents: 1000,
      wonValueCents: 2000,
      lostValueCents: 0,
      averageCycleDays: 5,
    },
    pipelines: [],
    timeBuckets: [],
    stageConversions: [],
    velocity: {
      averageCycleDays: 5,
      averageOpenDays: 1,
      throughputPerDay: 0.1,
      winRate: 100,
    },
    ownerPerformance: [],
    teamPerformance: [],
    lostReasons: [],
    cohorts: [],
  };

  it('renders summary metrics', () => {
    render(<ReportingSnapshot data={sample} isLoading={false} error={null} />);
    expect(screen.getByText('Won')).toBeInTheDocument();
    expect(screen.getByText('2')).toBeInTheDocument();
    expect(screen.getByText(/Win Rate/)).toBeInTheDocument();
  });
});

describe('ReportingBreakdowns', () => {
  it('renders stage names when provided', () => {
    const data: ReportingAggregationResult = {
      generatedAt: new Date(),
      filters: {},
      summary: {
        openCount: 0,
        wonCount: 0,
        lostCount: 0,
        openValueCents: 0,
        wonValueCents: 0,
        lostValueCents: 0,
        averageCycleDays: 0,
      },
      pipelines: [],
      timeBuckets: [],
      stageConversions: [{ stageId: 'stage-1', entered: 5, won: 2, lost: 1, conversionRate: 40 }],
      velocity: {
        averageCycleDays: 0,
        averageOpenDays: 0,
        throughputPerDay: 0,
        winRate: 0,
      },
      ownerPerformance: [],
      teamPerformance: [],
      lostReasons: [],
      cohorts: [],
    };

    render(<ReportingBreakdowns data={data} stageNames={new Map([['stage-1', 'Discovery']])} />);

    expect(screen.getByText(/Discovery/)).toBeInTheDocument();
  });
});

describe('ReportingPerformance', () => {
  it('shows owner performance rows', () => {
    render(
      <ReportingPerformance
        owners={[
          {
            ownerOrTeamId: 'owner-1',
            ownerOrTeamName: 'Owner One',
            pipelineIds: ['pipe-1'],
            metrics: {
              openCount: 0,
              wonCount: 2,
              lostCount: 1,
              openValueCents: 0,
              wonValueCents: 15000,
              lostValueCents: 0,
              averageCycleDays: 5,
            },
            winRate: 66.6,
            averageCycleDays: 5,
          },
        ]}
        teams={[]}
      />
    );

    expect(screen.getByText('Owner One')).toBeInTheDocument();
    expect(screen.getByText(/66\.6%/)).toBeInTheDocument();
  });
});

describe('ReportingCohorts', () => {
  it('shows cohort rows with conversion rate', () => {
    const cohort = {
      source: 'referral',
      periodStart: new Date('2024-01-01'),
      periodEnd: new Date('2024-01-31'),
      leadCount: 5,
      convertedCount: 2,
      conversionRate: 40,
      wonValueCents: 10000,
    };

    render(<ReportingCohorts cohorts={[cohort]} />);

    expect(screen.getByText('referral')).toBeInTheDocument();
    expect(screen.getByText(/40\.0%/)).toBeInTheDocument();
  });
});

describe('ReportFiltersPanel', () => {
  const baseFilters = { ...DEFAULT_FILTERS };
  const pipelines = [{ id: 'pipe-1', name: 'Pipeline 1', isDefault: false, isActive: true, ownerId: '', ownerName: '', teamIds: [], createdAt: new Date() }];
  const stages = [{ id: 'stage-1', name: 'Stage 1', pipelineId: 'pipe-1' }];
  const views: ReportView[] = [];

  it('invokes clear and my-deals toggles', () => {
    const setFilters = vi.fn();
    const onClearFilters = vi.fn();
    const onClearViewSelection = vi.fn();
    const onToggleMyDeals = vi.fn();

    render(
      <ReportFiltersPanel
        filters={baseFilters}
        setFilters={setFilters as any}
        pipelines={pipelines as any}
        pipelinesLoading={false}
        stages={stages}
        handleStatusToggle={vi.fn()}
        myDealsOnly={false}
        onToggleMyDeals={onToggleMyDeals}
        views={views}
        viewsLoading={false}
        selectedViewId={null}
        applyView={vi.fn()}
        canManage={() => false}
        savedViewsEnabled
        onDeleteView={vi.fn()}
        onSaveView={vi.fn()}
        newViewName=""
        setNewViewName={vi.fn()}
        shareTeams=""
        setShareTeams={vi.fn()}
        actionError={null}
        onClearFilters={onClearFilters}
        onClearViewSelection={onClearViewSelection}
      />
    );

    fireEvent.click(screen.getByText('Clear filters'));
    expect(onClearFilters).toHaveBeenCalled();

    fireEvent.click(screen.getByText('Clear selection'));
    expect(onClearViewSelection).toHaveBeenCalled();

    fireEvent.click(screen.getByLabelText('My deals only'));
    expect(onToggleMyDeals).toHaveBeenCalled();
  });

  it('shows saved views disabled messaging when feature flag is off', () => {
    const setFilters = vi.fn();

    render(
      <ReportFiltersPanel
        filters={baseFilters}
        setFilters={setFilters as any}
        pipelines={pipelines as any}
        pipelinesLoading={false}
        stages={stages}
        handleStatusToggle={vi.fn()}
        myDealsOnly={false}
        onToggleMyDeals={vi.fn()}
        views={views}
        viewsLoading={false}
        selectedViewId={null}
        applyView={vi.fn()}
        canManage={() => false}
        savedViewsEnabled={false}
        onDeleteView={vi.fn()}
        onSaveView={vi.fn()}
        newViewName=""
        setNewViewName={vi.fn()}
        shareTeams=""
        setShareTeams={vi.fn()}
        actionError={null}
        onClearFilters={vi.fn()}
        onClearViewSelection={vi.fn()}
      />
    );

    expect(screen.getByText(/disabled/i)).toBeInTheDocument();
  });
});

describe('ReportExportPanel', () => {
  const baseFeatures: FeatureFlags = {
    enableDocuments: true,
    enableESignature: false,
    enableAutoWinOnSignedProposal: false,
    enableCompanies: true,
    enableLeadScoring: true,
    enableReports: true,
    enableTaskReminders: true,
    enableEmailIntegration: false,
    enableCalendarSync: false,
    enableCustomFields: true,
    enableImportExport: true,
    enableAdvancedReporting: true,
    enableReportSavedViews: true,
    enableDuplicatePrevention: true,
    enableAutomation: true,
    enableSequences: true,
    enableGoals: true,
    enableForecasting: true,
    enableWebForms: true,
    enableSms: false,
    enablePushNotifications: false,
    enableRoutePlanning: true,
    enableDashboards: true,
    enableScheduledReports: true,
    enableApi: false,
    enableWebhooks: false,
  };

  it('triggers run and schedule handlers', async () => {
    (useAuth as unknown as Mock).mockReturnValue({
      crmUser: { id: 'user-1', email: 'test@example.com', displayName: 'Tester', role: 'admin', teamIds: [], managedTeamIds: [] },
      businessId: 'biz-1',
    });
    const runNow = vi.fn().mockResolvedValue({
      content: '',
      contentType: 'text/csv',
      expiresAt: new Date(),
      delivery: { method: 'link', downloadUrl: 'data:text/csv,' },
    });
    const schedule = vi.fn().mockResolvedValue(undefined);

    (useReportExports as unknown as Mock).mockReturnValue({
      exports: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      schedule,
      runNow,
    });

    const originalCreate = document.createElement.bind(document);
    const mockLink = originalCreate('a');
    const clickSpy = vi.spyOn(mockLink, 'click').mockImplementation(() => {});
    const createElementSpy = vi
      .spyOn(document, 'createElement')
      .mockImplementation((tagName: string, options?: any) => {
        if (tagName === 'a') {
          return mockLink;
        }
        return originalCreate(tagName as any, options);
      });

    render(<ReportExportPanel filters={{}} featureFlags={baseFeatures} />);

    fireEvent.click(screen.getByText('Run now'));
    fireEvent.click(screen.getByText('Schedule'));

    await waitFor(() => expect(runNow).toHaveBeenCalled());
    await waitFor(() => expect(schedule).toHaveBeenCalled());
    createElementSpy.mockRestore();
    clickSpy.mockRestore();
  });

  it('shows disabled message when feature flag is off', () => {
    (useAuth as unknown as Mock).mockReturnValue({
      crmUser: { id: 'user-1', email: 'test@example.com', displayName: 'Tester', role: 'admin', teamIds: [], managedTeamIds: [] },
      businessId: 'biz-1',
    });
    (useReportExports as unknown as Mock).mockReturnValue({
      exports: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      schedule: vi.fn(),
      runNow: vi.fn(),
    });

    render(
      <ReportExportPanel
        filters={{}}
        featureFlags={{ ...baseFeatures, enableImportExport: false }}
      />
    );

    expect(screen.getByText(/Reporting exports are disabled/i)).toBeInTheDocument();
  });

  it('disables exports when a disabledReason is provided', () => {
    (useAuth as unknown as Mock).mockReturnValue({
      crmUser: { id: 'user-1', email: 'test@example.com', displayName: 'Tester', role: 'admin', teamIds: [], managedTeamIds: [] },
      businessId: 'biz-1',
    });
    (useReportExports as unknown as Mock).mockReturnValue({
      exports: [],
      isLoading: false,
      error: null,
      refresh: vi.fn(),
      schedule: vi.fn(),
      runNow: vi.fn(),
    });

    render(
      <ReportExportPanel
        filters={{}}
        featureFlags={baseFeatures}
        disabledReason="RBAC blocked"
      />
    );

    expect(screen.getByText(/RBAC blocked/)).toBeInTheDocument();
    expect(screen.getByText('Run now')).toBeDisabled();
    expect(screen.getByText('Schedule')).toBeDisabled();
  });
});
