import type { PerformanceMetrics } from '../../types/reporting';
import { formatCurrency } from '../../pages/report-utils';

interface ReportingPerformanceProps {
  owners?: PerformanceMetrics[];
  teams?: PerformanceMetrics[];
}

function renderPerformanceTable(
  title: string,
  rows: PerformanceMetrics[],
  labelPrefix: 'Owner' | 'Team'
) {
  if (!rows.length) {
    return (
      <div className="report-card">
        <h3>{title}</h3>
        <p className="text-muted">No data available.</p>
      </div>
    );
  }

  return (
    <div className="report-card">
      <h3>{title}</h3>
      <table className="table">
        <thead>
          <tr>
            <th>{labelPrefix}</th>
            <th>Win Rate</th>
            <th>Avg Cycle (d)</th>
            <th>Won</th>
            <th>Lost</th>
            <th>Won Value</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.ownerOrTeamId}>
              <td>{row.ownerOrTeamName || row.ownerOrTeamId}</td>
              <td>{row.winRate.toFixed(1)}%</td>
              <td>{row.averageCycleDays.toFixed(1)}</td>
              <td>{row.metrics.wonCount}</td>
              <td>{row.metrics.lostCount}</td>
              <td>{formatCurrency(row.metrics.wonValueCents)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function ReportingPerformance({
  owners = [],
  teams = [],
}: ReportingPerformanceProps) {
  if (!owners.length && !teams.length) {
    return null;
  }

  const sortedOwners = [...owners].sort((a, b) => b.winRate - a.winRate).slice(0, 5);
  const sortedTeams = [...teams].sort((a, b) => b.metrics.wonCount - a.metrics.wonCount).slice(0, 5);

  return (
    <section className="report-section">
      <h2>Owner & Team Performance</h2>
      <div
        className="reports-grid"
        style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 12 }}
      >
        {renderPerformanceTable('Top Owners', sortedOwners, 'Owner')}
        {renderPerformanceTable('Top Teams', sortedTeams, 'Team')}
      </div>
    </section>
  );
}

export default ReportingPerformance;
