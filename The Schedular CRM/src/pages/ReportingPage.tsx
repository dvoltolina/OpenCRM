import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { createSecurityContext } from '../hooks/usePipeline';
import { getReportingService } from '../services/reporting-service';
import type { SecurityContext } from '../data/repositories/repository-types';
import { ReportViewer } from '../components/reports/ReportViewer';
import { ReportBuilder } from '../components/reports/ReportBuilder';
import { ReportScheduler } from '../components/reports/ReportScheduler';
import { ReportExporter } from '../components/reports/ReportExporter';
import { Button, Card, PageHeader, PageLayout } from '../components/ui';
import type { ReportBuilderData } from '../components/reports/ReportBuilder';
import type { ScheduleFormData, TeamMemberOption } from '../components/reports/ReportScheduler';
import type { ExportOptions } from '../components/reports/ReportExporter';
import type { ReportDefinition, ReportResult, ReportType } from '../types/reporting';
import { ReportingCatalogView } from '../components/reports/ReportingCatalogView';
import { isDemoMode } from '../config/demo';
import { buildBuilderInitialData } from './reporting-page-config';
import './styles/reporting-page.css';

type ViewState = 'list' | 'view' | 'build' | 'edit';

const DEMO_REPORTS_SEED_MESSAGE =
  'Demo reports are unavailable until the demo tenant is seeded. Run scripts/seed-demo-data.ts against the demo Firebase project.';

export function ReportingPage() {
  const { businessId, crmUser } = useAuth();
  const reportingService = useMemo(() => getReportingService(), []);
  const securityContext = useMemo<SecurityContext | null>(() => {
    if (!businessId || !crmUser) {
      return null;
    }

    return createSecurityContext(businessId, crmUser.id, crmUser.displayName, crmUser.role);
  }, [businessId, crmUser]);

  const teamMemberOptions: TeamMemberOption[] = useMemo(() => {
    if (!crmUser) {
      return [];
    }

    return [
      {
        id: crmUser.id,
        name: crmUser.displayName || crmUser.email || 'Current User',
        email: crmUser.email || '',
      },
    ];
  }, [crmUser]);

  const [viewState, setViewState] = useState<ViewState>('list');
  const [selectedCategory, setSelectedCategory] = useState<ReportType | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [reports, setReports] = useState<ReportDefinition[]>([]);
  const [selectedReport, setSelectedReport] = useState<ReportDefinition | null>(null);
  const [reportResult, setReportResult] = useState<ReportResult | null>(null);
  const [isLoadingReports, setIsLoadingReports] = useState(true);
  const [isRunningReport, setIsRunningReport] = useState(false);
  const [isSavingReport, setIsSavingReport] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [isSavingSchedule, setIsSavingSchedule] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reportError, setReportError] = useState<string | null>(null);
  const [showScheduler, setShowScheduler] = useState(false);
  const [showExporter, setShowExporter] = useState(false);

  const loadReports = useCallback(async () => {
    if (!securityContext) {
      return;
    }

    setIsLoadingReports(true);
    setError(null);

    try {
      const seededResult = await reportingService.areSystemReportsSeeded(securityContext);

      if (seededResult.success && !seededResult.data) {
        if (isDemoMode) {
          setReports([]);
          setError(DEMO_REPORTS_SEED_MESSAGE);
          return;
        }

        await reportingService.seedSystemReports(securityContext);
      }

      const reportsResult = await reportingService.getReports(securityContext, {
        includeSystem: true,
      });

      if (reportsResult.success) {
        setReports(reportsResult.data);
        return;
      }

      setError('Failed to load reports');
    } catch {
      setError('An error occurred while loading reports');
    } finally {
      setIsLoadingReports(false);
    }
  }, [reportingService, securityContext]);

  useEffect(() => {
    void loadReports();
  }, [loadReports]);

  const filteredReports = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();

    return reports.filter((report) => {
      if (selectedCategory !== 'all' && report.reportType !== selectedCategory) {
        return false;
      }

      if (!normalizedQuery) {
        return true;
      }

      return (
        report.name.toLowerCase().includes(normalizedQuery) ||
        report.description?.toLowerCase().includes(normalizedQuery)
      );
    });
  }, [reports, searchQuery, selectedCategory]);

  const systemReports = filteredReports.filter((report) => report.isSystemReport);
  const customReports = filteredReports.filter((report) => !report.isSystemReport);

  const handleSelectReport = useCallback(
    async (report: ReportDefinition) => {
      if (!securityContext) {
        return;
      }

      setSelectedReport(report);
      setViewState('view');
      setIsRunningReport(true);
      setReportError(null);
      setReportResult(null);

      try {
        const result = await reportingService.runReport(securityContext, report.id);

        if (result.success) {
          setReportResult(result.data);
          return;
        }

        setReportError(result.error?.message || 'Failed to run report');
      } catch {
        setReportError('An error occurred while running the report');
      } finally {
        setIsRunningReport(false);
      }
    },
    [reportingService, securityContext]
  );

  const handleRefreshReport = useCallback(async () => {
    if (!selectedReport) {
      return;
    }

    await handleSelectReport(selectedReport);
  }, [handleSelectReport, selectedReport]);

  const handleCreateReport = useCallback(() => {
    setSelectedReport(null);
    setReportResult(null);
    setReportError(null);
    setViewState('build');
  }, []);

  const handleEditReport = useCallback(() => {
    if (!selectedReport) {
      return;
    }

    setViewState('edit');
  }, [selectedReport]);

  const handleSaveReport = useCallback(
    async (data: ReportBuilderData) => {
      if (!securityContext) {
        return;
      }

      setIsSavingReport(true);

      try {
        if (viewState === 'edit' && selectedReport) {
          const result = await reportingService.updateReport(securityContext, selectedReport.id, {
            ...data,
          });

          if (result.success) {
            setReports((previous) =>
              previous.map((report) => (report.id === selectedReport.id ? result.data : report))
            );
            setSelectedReport(result.data);
            await handleSelectReport(result.data);
            return;
          }

          setError('Failed to update report');
          return;
        }

        const result = await reportingService.createReport(
          securityContext,
          data as unknown as Parameters<typeof reportingService.createReport>[1]
        );

        if (result.success) {
          setReports((previous) => [...previous, result.data]);
          setSelectedReport(result.data);
          await handleSelectReport(result.data);
          return;
        }

        setError('Failed to create report');
      } catch {
        setError('An error occurred while saving the report');
      } finally {
        setIsSavingReport(false);
      }
    },
    [handleSelectReport, reportingService, securityContext, selectedReport, viewState]
  );

  const handleDeleteReport = useCallback(
    async (report: ReportDefinition) => {
      if (!securityContext) {
        return;
      }

      if (!window.confirm(`Are you sure you want to delete "${report.name}"?`)) {
        return;
      }

      try {
        const result = await reportingService.deleteReport(securityContext, report.id);

        if (result.success) {
          setReports((previous) => previous.filter((item) => item.id !== report.id));

          if (selectedReport?.id === report.id) {
            setSelectedReport(null);
            setReportResult(null);
            setViewState('list');
          }

          return;
        }

        setError('Failed to delete report');
      } catch {
        setError('An error occurred while deleting the report');
      }
    },
    [reportingService, securityContext, selectedReport]
  );

  const handleSaveSchedule = useCallback(
    async (schedule: ScheduleFormData) => {
      if (!securityContext || !selectedReport) {
        return;
      }

      setIsSavingSchedule(true);

      try {
        const result = await reportingService.scheduleReport(securityContext, {
          reportId: selectedReport.id,
          reportName: selectedReport.name,
          ...schedule,
        });

        if (result.success) {
          setShowScheduler(false);
          return;
        }

        setError('Failed to schedule report');
      } catch {
        setError('An error occurred while scheduling the report');
      } finally {
        setIsSavingSchedule(false);
      }
    },
    [reportingService, securityContext, selectedReport]
  );

  const handleExportReport = useCallback(
    async (options: ExportOptions) => {
      if (!securityContext || !selectedReport) {
        return;
      }

      setIsExporting(true);

      try {
        const result = await reportingService.exportReport(
          securityContext,
          selectedReport.id,
          options.format,
          options.dateRange
        );

        if (result.success && result.data) {
          const link = document.createElement('a');
          link.href = result.data;
          link.download = options.fileName || `${selectedReport.name}.${options.format}`;
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
          setShowExporter(false);
          return;
        }

        setError('Failed to export report');
      } catch {
        setError('An error occurred while exporting the report');
      } finally {
        setIsExporting(false);
      }
    },
    [reportingService, securityContext, selectedReport]
  );

  const handleBackToList = useCallback(() => {
    setViewState('list');
    setSelectedReport(null);
    setReportResult(null);
    setReportError(null);
  }, []);

  const headerTitle =
    viewState === 'build'
      ? 'Create custom report'
      : viewState === 'edit'
        ? `Edit ${selectedReport?.name || 'report'}`
        : viewState === 'view'
          ? selectedReport?.name || 'Report'
          : 'Report Builder';

  const headerSubtitle =
    viewState === 'list'
      ? 'Maintain reusable report definitions for exports, schedules, and deeper reporting workflows. Use the reports dashboard for KPI snapshots and saved filter views.'
      : viewState === 'view'
        ? selectedReport?.description || 'Run, schedule, and export aggregate report definitions.'
        : 'Configure an aggregate-only report definition that remains aligned with the shared CRM design system.';

  const headerActions = (
    <>
      {viewState === 'list' ? (
        <>
          <Link className="ui-button ui-button--secondary ui-button--md" to="/reports">
            Open Reports Dashboard
          </Link>
          <Button onClick={handleCreateReport}>Create report</Button>
        </>
      ) : (
        <>
          <Button variant="secondary" onClick={handleBackToList}>
            Back to library
          </Button>
          <Link className="ui-button ui-button--ghost ui-button--md" to="/reports">
            Dashboard
          </Link>
        </>
      )}
    </>
  );

  if (!securityContext) {
    return (
      <PageLayout width="wide" className="reporting-page reporting-page__error">
        <PageHeader
          eyebrow="Advanced Reporting"
          title="Report Builder"
          subtitle="Workspace context is required before report definitions can be loaded."
        />
        <Card className="reporting-page__status-card" padding="lg">
          <p>Missing workspace context.</p>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="reporting-page">
      <PageHeader
        eyebrow="Advanced Reporting"
        title={headerTitle}
        subtitle={headerSubtitle}
        actions={headerActions}
      />

      {isLoadingReports && reports.length === 0 ? (
        <div className="reporting-page__loading">
          <Card className="reporting-page__status-card" padding="lg">
            <p>Loading report definitions and seeded templates.</p>
          </Card>
        </div>
      ) : null}

      {!isLoadingReports && error && reports.length === 0 ? (
        <div className="reporting-page__error">
          <Card className="reporting-page__status-card" padding="lg">
            <p>{error}</p>
            <Button variant="primary" onClick={() => void loadReports()}>
              Retry
            </Button>
          </Card>
        </div>
      ) : null}

      {!isLoadingReports && !(error && reports.length === 0) ? (
        <>
          {viewState === 'list' ? (
            <ReportingCatalogView
              searchQuery={searchQuery}
              selectedCategory={selectedCategory}
              systemReports={systemReports}
              customReports={customReports}
              totalReports={reports.length}
              onSearchQueryChange={setSearchQuery}
              onSelectedCategoryChange={setSelectedCategory}
              onSelectReport={(report) => void handleSelectReport(report)}
              onDeleteReport={(report) => void handleDeleteReport(report)}
              onCreateReport={handleCreateReport}
            />
          ) : null}

          {viewState === 'view' ? (
            <div className="reporting-page__viewer">
              {isRunningReport && !reportResult ? (
                <Card className="reporting-page__status-card" padding="lg">
                  <p>Running report definition and assembling aggregates.</p>
                </Card>
              ) : null}

              {!isRunningReport && reportError && !reportResult ? (
                <Card className="reporting-page__status-card" padding="lg">
                  <p>{reportError}</p>
                  <Button variant="primary" onClick={() => void handleRefreshReport()}>
                    Retry report
                  </Button>
                </Card>
              ) : null}

              {selectedReport && reportResult ? (
                <ReportViewer
                  report={selectedReport}
                  result={reportResult}
                  isLoading={isRunningReport}
                  error={reportError}
                  onRefresh={handleRefreshReport}
                  onExport={() => setShowExporter(true)}
                  onSchedule={() => setShowScheduler(true)}
                  onEdit={handleEditReport}
                  isExporting={isExporting}
                  canEdit={!selectedReport.isSystemReport && selectedReport.ownerId === securityContext.userId}
                  canSchedule
                />
              ) : null}
            </div>
          ) : null}

          {viewState === 'build' || viewState === 'edit' ? (
            <div className="reporting-page__builder-shell">
              <ReportBuilder
                initialData={viewState === 'edit' ? buildBuilderInitialData(selectedReport) : undefined}
                onSave={handleSaveReport}
                onCancel={handleBackToList}
                isSaving={isSavingReport}
                isEditing={viewState === 'edit'}
              />
            </div>
          ) : null}
        </>
      ) : null}

      {showScheduler && selectedReport ? (
        <div className="modal-overlay" onClick={() => setShowScheduler(false)}>
          <div
            className="modal reporting-page__modal-shell"
            onClick={(event) => event.stopPropagation()}
          >
            <ReportScheduler
              reportId={selectedReport.id}
              reportName={selectedReport.name}
              teamMembers={teamMemberOptions}
              onSave={handleSaveSchedule}
              onCancel={() => setShowScheduler(false)}
              isSaving={isSavingSchedule}
            />
          </div>
        </div>
      ) : null}

      {showExporter && selectedReport ? (
        <ReportExporter
          report={selectedReport}
          result={reportResult || undefined}
          isOpen={showExporter}
          onClose={() => setShowExporter(false)}
          onExport={handleExportReport}
          isExporting={isExporting}
        />
      ) : null}

      {error ? (
        <div className="reporting-page__toast">
          <p>{error}</p>
          <button
            type="button"
            className="reporting-page__toast-close"
            onClick={() => setError(null)}
          >
            Close
          </button>
        </div>
      ) : null}
    </PageLayout>
  );
}

export default ReportingPage;
