import { useMemo, useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { usePipelines } from '../../hooks/usePipelines';
import { useReportingAggregations } from '../../hooks/useReportingAggregations';
import { AuditLogService } from '../../services/AuditLogService';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import type { ReportingAggregationFilters } from '../../types/reporting';
import { formatCurrency } from '../../pages/report-utils';
import { getFeatureFlags } from '../../config/features';
import ReportExportPanel from '../reports/ReportExportPanel';
import { Button, Card } from '../ui';

interface ManagerReportsPanelProps {
  managedTeams: string[];
  userTeams: string[];
  enforceTeamScope: boolean;
}

function addDays(base: Date, days: number) {
  const date = new Date(base);
  date.setDate(date.getDate() + days);
  return date;
}

export function ManagerReportsPanel({
  managedTeams,
  userTeams,
  enforceTeamScope,
}: ManagerReportsPanelProps) {
  const { crmUser, businessId } = useAuth();
  const { pipelines, isLoading: pipelinesLoading } = usePipelines();
  const [pipelineId, setPipelineId] = useState<string>('all');
  const [range, setRange] = useState<{ start: Date; end: Date }>({
    start: addDays(new Date(), -30),
    end: new Date(),
  });
  const auditLogService = useMemo(() => new AuditLogService(), []);
  const featureFlags = useMemo(() => getFeatureFlags(), []);

  const teamScope = useMemo(
    () => (managedTeams.length > 0 ? managedTeams : userTeams),
    [managedTeams, userTeams]
  );

  const filters: ReportingAggregationFilters = useMemo(
    () => ({
      startDate: range.start,
      endDate: range.end,
      pipelineIds: pipelineId === 'all' ? undefined : [pipelineId],
      teamIds: enforceTeamScope ? teamScope : undefined,
      includeStageBreakdown: true,
      bucket: 'monthly',
    }),
    [enforceTeamScope, pipelineId, range.end, range.start, teamScope]
  );

  const { data, isLoading, error, refresh } = useReportingAggregations(filters);

  const summary = data?.summary;
  const velocity = data?.velocity;
  const pipelineNameMap = useMemo(
    () => new Map(pipelines.map((p) => [p.id, p.name])),
    [pipelines]
  );

  const teamPerformance = useMemo(
    () =>
      (data?.teamPerformance || []).filter((row) => {
        if (!enforceTeamScope || teamScope.length === 0) return true;
        return teamScope.includes(row.ownerOrTeamId);
      }),
    [data?.teamPerformance, enforceTeamScope, teamScope]
  );

  const pipelineForecast = useMemo(() => {
    if (!data) return [];
    return data.pipelines
      .map((pipeline) => {
        const winRate = pipeline.velocity?.winRate ?? velocity?.winRate ?? 0;
        const forecastCents = pipeline.metrics.openValueCents * (winRate / 100);
        return {
          pipelineId: pipeline.pipelineId,
          name: pipelineNameMap.get(pipeline.pipelineId) || pipeline.pipelineId,
          openValueCents: pipeline.metrics.openValueCents,
          forecastCents,
          winRate,
        };
      })
      .filter((row) => row.openValueCents > 0 || row.forecastCents > 0);
  }, [data, pipelineNameMap, velocity]);

  const exportReport = async () => {
    if (!crmUser || !businessId) return;
    const context = createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      sanitizeTeamIds(crmUser.teamIds || []),
      sanitizeTeamIds(crmUser.managedTeamIds || []),
      crmUser.managerId
    );
    await auditLogService.logAction(context, {
      action: 'export',
      entityType: 'report',
      entityId: 'manager-report',
      metadata: {
        pipelineId: pipelineId === 'all' ? 'all' : pipelineId,
        startDate: range.start.toISOString(),
        endDate: range.end.toISOString(),
        teamIds: filters.teamIds,
      },
    });
    // Lightweight CSV export of summary metrics
    if (!summary) return;
    const rows = [
      ['Metric', 'Value'],
      ['Open Deals', summary.openCount],
      ['Won Deals', summary.wonCount],
      ['Lost Deals', summary.lostCount],
      ['Open Value (cents)', summary.openValueCents],
      ['Won Value (cents)', summary.wonValueCents],
      ['Lost Value (cents)', summary.lostValueCents],
      ['Average Cycle Days', summary.averageCycleDays],
      ['Win Rate', velocity ? `${velocity.winRate.toFixed(2)}` : '0'],
    ];
    const csv = rows.map((row) => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'manager-report.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  if (enforceTeamScope && managedTeams.length === 0) {
    return (
      <Card className="manager-panel manager-reports-panel" padding="lg" tone="subtle">
        <h2>Manager Reporting</h2>
        <p className="error-state">
          Managed team claims are required to load reporting. Access is read-only until claims are provisioned.
        </p>
      </Card>
    );
  }

  return (
    <Card className="manager-panel manager-reports-panel" padding="lg" tone="subtle">
      <div className="manager-panel__header">
        <div className="manager-panel__copy">
          <p className="manager-panel__eyebrow">Reporting</p>
          <h2>Manager Reporting</h2>
          <p className="page-subtitle">
            Won/lost trends, velocity, and SLA compliance limited to managed teams.
          </p>
        </div>
        <div className="page-actions">
          <Button variant="secondary" onClick={refresh}>
            Refresh
          </Button>
          <Button variant="secondary" onClick={exportReport} disabled={!summary}>
            Export CSV
          </Button>
        </div>
      </div>

      <div className="manager-control-grid manager-control-grid--reports">
        <div className="manager-field">
          <label htmlFor="manager-report-pipeline">Pipeline</label>
          <select
            id="manager-report-pipeline"
            value={pipelineId}
            onChange={(e) => setPipelineId(e.target.value)}
            disabled={pipelinesLoading}
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
              className={`manager-pill ${range.start <= addDays(new Date(), -30) ? 'is-active' : ''}`}
              onClick={() => setRange({ start: addDays(new Date(), -30), end: new Date() })}
            >
              Last 30 days
            </button>
            <button
              type="button"
              className={`manager-pill ${range.start <= addDays(new Date(), -90) ? 'is-active' : ''}`}
              onClick={() => setRange({ start: addDays(new Date(), -90), end: new Date() })}
            >
              Last 90 days
            </button>
            <span className="manager-range-label">
              {range.start.toLocaleDateString()} – {range.end.toLocaleDateString()}
            </span>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="manager-empty-state">
          <p>Loading reporting data…</p>
        </div>
      ) : error ? (
        <div className="error-state manager-panel__message">
          <p className="page-status-title">Unable to load reporting</p>
          <p className="page-status-detail">{error.message}</p>
        </div>
      ) : !data ? (
        <div className="manager-empty-state">
          <p>No reporting data available for this scope.</p>
        </div>
      ) : (
        <div className="manager-report-grid">
          <Card className="manager-summary-card manager-report-card" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>Summary</h3>
                <p className="page-subtitle">Key pipeline and revenue signals for the selected scope.</p>
              </div>
            </div>
            <div className="kpi-cards manager-report-kpis">
              <Card className="kpi-card" padding="md">
                <span className="kpi-label">Open Value</span>
                <span className="kpi-value">{formatCurrency(summary?.openValueCents || 0)}</span>
              </Card>
              <Card className="kpi-card" padding="md">
                <span className="kpi-label">Won Value</span>
                <span className="kpi-value">{formatCurrency(summary?.wonValueCents || 0)}</span>
              </Card>
              <Card className="kpi-card" padding="md">
                <span className="kpi-label">Win Rate</span>
                <span className="kpi-value">
                  {velocity ? velocity.winRate.toFixed(1) : '0.0'}%
                </span>
              </Card>
              <Card className="kpi-card" padding="md">
                <span className="kpi-label">Lost Value</span>
                <span className="kpi-value">{formatCurrency(summary?.lostValueCents || 0)}</span>
              </Card>
            </div>
          </Card>

          <Card className="manager-summary-card manager-report-card" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>SLA & Throughput</h3>
                <p className="page-subtitle">Current pace, open-time drag, and average cycle time.</p>
              </div>
            </div>
            <div className="report-stats">
              <div className="stat-item">
                <span className="stat-label">Velocity / day</span>
                <span className="stat-value">
                  {velocity ? velocity.throughputPerDay.toFixed(2) : '0'}
                </span>
              </div>
              <div className="stat-item">
                <span className="stat-label">Average Open Days</span>
                <span className="stat-value">
                  {velocity ? velocity.averageOpenDays.toFixed(1) : '0'}
                </span>
              </div>
              <div className="stat-item">
                <span className="stat-label">Average Cycle</span>
                <span className="stat-value">
                  {summary?.averageCycleDays ?? 0} days
                </span>
              </div>
            </div>
          </Card>

          <Card className="manager-summary-card manager-report-card manager-report-card--full" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>Team Performance (Won/Lost)</h3>
                <p className="page-subtitle">Outcome quality and average cycle by team.</p>
              </div>
            </div>
            {teamPerformance.length === 0 ? (
              <p>No team performance data in this scope.</p>
            ) : (
              <div className="data-table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Team</th>
                      <th>Won</th>
                      <th>Lost</th>
                      <th>Win Rate</th>
                      <th>Avg Cycle</th>
                    </tr>
                  </thead>
                  <tbody>
                    {teamPerformance.map((team) => (
                      <tr key={team.ownerOrTeamId}>
                        <td>{team.ownerOrTeamName || team.ownerOrTeamId}</td>
                        <td>{team.metrics.wonCount}</td>
                        <td>{team.metrics.lostCount}</td>
                        <td>{team.winRate.toFixed(1)}%</td>
                        <td>{team.averageCycleDays?.toFixed(1) ?? '0'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>

          <Card className="manager-summary-card manager-report-card" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>Pipeline Forecast</h3>
                <p className="page-subtitle">Weighted forecast by pipeline using current win rates.</p>
              </div>
            </div>
            {pipelineForecast.length === 0 ? (
              <p>No pipeline forecast available for this scope.</p>
            ) : (
              <div className="data-table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Pipeline</th>
                      <th>Open Value</th>
                      <th>Weighted Forecast</th>
                      <th>Win Rate</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pipelineForecast.map((pipeline) => (
                      <tr key={pipeline.pipelineId}>
                        <td>{pipeline.name}</td>
                        <td>{formatCurrency(pipeline.openValueCents)}</td>
                        <td>{formatCurrency(Math.round(pipeline.forecastCents))}</td>
                        <td>{pipeline.winRate.toFixed(1)}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>

          <Card className="manager-summary-card manager-report-card" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>Stage Breakdown</h3>
                <p className="page-subtitle">Current conversion efficiency across the top stages.</p>
              </div>
            </div>
            {data.stageConversions.length === 0 ? (
              <p>No stage conversion data.</p>
            ) : (
              <div className="report-stats manager-report-stats-grid">
                {data.stageConversions.slice(0, 6).map((conversion) => (
                  <div key={conversion.stageId} className="stat-item">
                    <span className="stat-label">{conversion.stageName || conversion.stageId}</span>
                    <span className="stat-value">
                      {conversion.conversionRate.toFixed(1)}% win
                    </span>
                    <span className="stat-sublabel">
                      {conversion.won}/{conversion.entered} entered
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Card>

          <Card className="manager-summary-card manager-report-card manager-report-card--full" padding="md">
            <div className="manager-summary-card__header">
              <div>
                <h3>Exports (CSV/PDF)</h3>
                <p className="page-subtitle">
                  Run or schedule exports scoped to your managed teams. Feature flags must allow reporting exports.
                </p>
              </div>
            </div>
            <div className="manager-export-panel">
              <ReportExportPanel filters={filters} featureFlags={featureFlags} />
            </div>
          </Card>
        </div>
      )}
    </Card>
  );
}

export default ManagerReportsPanel;
