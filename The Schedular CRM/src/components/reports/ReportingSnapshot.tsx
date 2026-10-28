import type { ReportingAggregationResult } from '../../types/reporting';

interface ReportingSnapshotProps {
  data: ReportingAggregationResult | null | undefined;
  isLoading: boolean;
  error: Error | null;
}

export function ReportingSnapshot({ data, isLoading, error }: ReportingSnapshotProps) {
  if (isLoading) {
    return (
      <section className="report-section">
        <h2>Backend Snapshot (aggregated)</h2>
        <p>Loading reporting metrics...</p>
      </section>
    );
  }

  if (error) {
    return (
      <section className="report-section">
        <h2>Backend Snapshot (aggregated)</h2>
        <p className="error-state">Reporting unavailable: {error.message}</p>
      </section>
    );
  }

  if (!data) {
    return (
      <section className="report-section">
        <h2>Backend Snapshot (aggregated)</h2>
        <p>No reporting data available.</p>
      </section>
    );
  }

  const cards = [
    { label: 'Won', value: data.summary.wonCount, className: 'stat-success' },
    { label: 'Lost', value: data.summary.lostCount, className: 'stat-danger' },
    {
      label: 'Win Rate',
      value: `${data.velocity ? data.velocity.winRate.toFixed(1) : '0'}%`,
    },
    {
      label: 'Avg Cycle Days',
      value: data.velocity ? data.velocity.averageCycleDays.toFixed(1) : '0',
    },
  ];

  return (
    <section className="report-section">
      <h2>Backend Snapshot (aggregated)</h2>
      <div className="report-stats">
        {cards.map((item) => (
          <div key={item.label} className="stat-item">
            <span className="stat-label">{item.label}</span>
            <span className={`stat-value${item.className ? ` ${item.className}` : ''}`}>
              {item.value}
            </span>
          </div>
        ))}
      </div>
      <p className="text-muted">
        Generated at {data.generatedAt.toLocaleString()}
      </p>
    </section>
  );
}

export default ReportingSnapshot;
