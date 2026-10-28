import type { SourceCohort } from '../../types/reporting';
import { formatCurrency } from '../../pages/report-utils';

interface ReportingCohortsProps {
  cohorts?: SourceCohort[];
}

function formatPeriod(date: Date) {
  return new Date(date).toISOString().slice(0, 10);
}

export function ReportingCohorts({ cohorts = [] }: ReportingCohortsProps) {
  if (!cohorts.length) return null;

  const recent = [...cohorts]
    .sort((a, b) => b.periodStart.getTime() - a.periodStart.getTime())
    .slice(0, 6);

  return (
    <section className="report-section">
      <h2>Source Cohorts</h2>
      <p className="text-muted">Conversion and revenue by lead source and start period.</p>
      <div className="report-card">
        <table className="table">
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
            {recent.map((cohort) => (
              <tr key={`${cohort.source}-${cohort.periodStart.toISOString()}`}>
                <td>{cohort.source}</td>
                <td>
                  {formatPeriod(cohort.periodStart)} – {formatPeriod(cohort.periodEnd)}
                </td>
                <td>{cohort.leadCount}</td>
                <td>{cohort.convertedCount}</td>
                <td>{cohort.conversionRate.toFixed(1)}%</td>
                <td>{formatCurrency(cohort.wonValueCents)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

export default ReportingCohorts;
