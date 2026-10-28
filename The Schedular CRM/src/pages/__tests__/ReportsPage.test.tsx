import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { ReportsPage } from '../ReportsPage';

const { runExportNowMock, downloadExportContentMock } = vi.hoisted(() => ({
  runExportNowMock: vi.fn(),
  downloadExportContentMock: vi.fn(),
}));
let mockFeatures = {
  enableReports: true,
  enableAdvancedReporting: true,
  enableReportSavedViews: true,
  enableSequences: true,
  enableImportExport: true,
};

vi.mock('../../context/AuthContext', () => ({
  useAuth: () => ({
    crmUser: {
      id: 'user-1',
      displayName: 'Admin User',
      role: 'admin',
      teamIds: [],
      managedTeamIds: [],
      managerId: undefined,
    },
    businessId: 'biz-1',
  }),
}));

vi.mock('../../config/features', () => ({
  getFeatureFlags: () => mockFeatures,
}));

vi.mock('../../hooks', () => ({
  useDashboardData: () => ({
    deals: [],
    leads: [],
    recentActivities: [],
    stages: [],
    isLoading: false,
    error: null,
    refresh: vi.fn(),
  }),
  useReportViews: () => ({
    views: [],
    isLoading: false,
    error: null,
    createView: vi.fn(),
    deleteView: vi.fn(),
    refresh: vi.fn(),
    canManage: true,
  }),
  usePipelines: () => ({
    pipelines: [],
    isLoading: false,
    error: null,
  }),
  useReportingAggregations: () => ({
    data: undefined,
    isLoading: false,
    error: null,
    isUnauthorized: false,
  }),
}));

vi.mock('../../hooks/useDashboardKPIs', () => ({
  useDashboardKPIs: () => ({
    dealsByStage: [],
  }),
}));

vi.mock('../../services/AuditLogService', () => ({
  AuditLogService: vi.fn().mockImplementation(() => ({
    logAction: vi.fn(),
  })),
}));

vi.mock('../../services/report-export-service', () => ({
  getReportExportService: () => ({
    runExportNow: runExportNowMock,
  }),
}));

vi.mock('../../services/export-download', () => ({
  downloadExportContent: downloadExportContentMock,
}));

vi.mock('../../lib/security-context', () => ({
  createSecurityContextFromParams: vi.fn(() => ({
    businessId: 'biz-1',
    userId: 'user-1',
    userName: 'Admin User',
    userRole: 'admin',
    teamIds: [],
    managedTeamIds: [],
    managerId: undefined,
  })),
  sanitizeTeamIds: vi.fn((teamIds?: string[]) => teamIds || []),
}));

vi.mock('../../components/reports/ReportExportPanel', () => ({
  ReportExportPanel: () => <div>Report Export Panel</div>,
}));

vi.mock('../../components/reports/SequencePerformanceReport', () => ({
  SequencePerformanceReport: () => <div>Sequence Performance Report</div>,
}));

function LocationDisplay() {
  const location = useLocation();
  return <div data-testid="location-search">{location.search}</div>;
}

describe('ReportsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockFeatures = {
      enableReports: true,
      enableAdvancedReporting: true,
      enableReportSavedViews: true,
      enableSequences: true,
      enableImportExport: true,
    };
    runExportNowMock.mockResolvedValue({
      content: 'bucket,pipelineId\nmonthly,pipe-1',
      contentType: 'text/csv',
      expiresAt: new Date('2026-03-08T12:00:00Z'),
      delivery: { method: 'link' },
    });
  });

  it('opens the sequences tab from the URL query string', () => {
    render(
      <MemoryRouter initialEntries={['/reports?tab=sequences']}>
        <LocationDisplay />
        <ReportsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Sequence Performance Report')).toBeInTheDocument();
    expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=sequences');
  });

  it('falls back to overview for unknown report tabs and normalizes the URL', async () => {
    render(
      <MemoryRouter initialEntries={['/reports?tab=unknown']}>
        <LocationDisplay />
        <ReportsPage />
      </MemoryRouter>
    );

    expect(screen.getByText('Pipeline Overview')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=overview');
    });
  });

  it('updates the query string when switching report tabs', async () => {
    render(
      <MemoryRouter initialEntries={['/reports']}>
        <LocationDisplay />
        <ReportsPage />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Scheduled Exports' }));

    expect(screen.getByText('Report Export Panel')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('location-search')).toHaveTextContent('?tab=exports');
    });
  });

  it('hides the exports tab when import/export is disabled', () => {
    mockFeatures = {
      ...mockFeatures,
      enableImportExport: false,
    };

    render(
      <MemoryRouter initialEntries={['/reports']}>
        <ReportsPage />
      </MemoryRouter>
    );

    expect(screen.queryByRole('button', { name: 'Scheduled Exports' })).not.toBeInTheDocument();
  });

  it('routes header exports through the live report export service', async () => {
    render(
      <MemoryRouter initialEntries={['/reports']}>
        <ReportsPage />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByRole('button', { name: 'Export CSV' }));

    await waitFor(() => {
      expect(runExportNowMock).toHaveBeenCalledWith(
        expect.objectContaining({
          businessId: 'biz-1',
          userId: 'user-1',
        }),
        expect.objectContaining({
          format: 'csv',
          delivery: { method: 'link' },
        })
      );
    });

    expect(downloadExportContentMock).toHaveBeenCalledWith(
      'bucket,pipelineId\nmonthly,pipe-1',
      'text/csv',
      'reporting_aggregates.csv'
    );
  });
});
