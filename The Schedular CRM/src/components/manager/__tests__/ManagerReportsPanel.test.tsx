import { render, screen } from '@testing-library/react';
import { describe, expect, it, beforeEach, vi } from 'vitest';

let lastExportProps: any = null;

vi.mock('../../../context/AuthContext', () => ({
  __esModule: true,
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Manager One',
      role: 'manager',
      teamIds: ['team-a'],
      managedTeamIds: ['team-a'],
      managerId: 'mgr-1',
      businessId: 'biz-1',
    },
    businessId: 'biz-1',
  }),
}));

vi.mock('../../../hooks/usePipelines', () => ({
  usePipelines: () => ({
    pipelines: [{ id: 'p1', name: 'Pipeline 1' }],
    isLoading: false,
  }),
}));

vi.mock('../../../hooks/useReportingAggregations', () => ({
  useReportingAggregations: () => ({
    data: {
      summary: {
        openCount: 1,
        wonCount: 1,
        lostCount: 0,
        openValueCents: 1000,
        wonValueCents: 1000,
        lostValueCents: 0,
        averageCycleDays: 5,
      },
      velocity: {
        winRate: 50,
        throughputPerDay: 1,
        averageOpenDays: 2,
      },
      pipelines: [
        {
          pipelineId: 'p1',
          metrics: {
            openCount: 1,
            wonCount: 1,
            lostCount: 0,
            openValueCents: 1000,
            wonValueCents: 1000,
            lostValueCents: 0,
          },
          velocity: { winRate: 50 },
        },
      ],
      teamPerformance: [],
      stageConversions: [],
    },
    isLoading: false,
    error: null,
    refresh: vi.fn(),
  }),
}));

vi.mock('../../../services/AuditLogService', () => ({
  AuditLogService: vi.fn().mockImplementation(() => ({
    logAction: vi.fn(),
  })),
}));

vi.mock('../../../config/features', () => ({
  getFeatureFlags: () => ({
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
  }),
}));

vi.mock('../../reports/ReportExportPanel', () => ({
  __esModule: true,
  default: (props: any) => {
    lastExportProps = props;
    return <div data-testid="manager-export-panel" />;
  },
}));

describe('ManagerReportsPanel', () => {
  beforeEach(() => {
    lastExportProps = null;
  });

  it('renders export panel with managed team scoping and feature flags', async () => {
    const { ManagerReportsPanel } = await import('../ManagerReportsPanel');

    render(
      <ManagerReportsPanel
        managedTeams={['team-a']}
        userTeams={['team-a', 'team-b']}
        enforceTeamScope
      />
    );

    expect(screen.getByText(/Exports \(CSV\/PDF\)/i)).toBeInTheDocument();
    expect(screen.getByTestId('manager-export-panel')).toBeInTheDocument();
    expect(lastExportProps?.featureFlags.enableImportExport).toBe(true);
    expect(lastExportProps?.filters.teamIds).toEqual(['team-a']);
  });
});
