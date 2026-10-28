import type { ReportingAggregationResult } from '../../types/reporting';
import { formatCurrency } from '../../pages/report-utils';

interface ReportingBreakdownsProps {
  data: ReportingAggregationResult | null | undefined;
  stageNames?: Map<string, string>;
}

export function ReportingBreakdowns({ data, stageNames }: ReportingBreakdownsProps) {
  if (!data) return null;

  const topLostReasons = (data.lostReasons || []).slice(0, 5);
  const topStages = (data.stageConversions || []).slice(0, 5);
  const recentBuckets = (data.timeBuckets || []).slice(-5);

  return (
    <section className="report-section">
      <h2>Reporting Breakdowns</h2>
      <div className="reports-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 12 }}>
        <div className="report-card">
          <h3>Stage Conversions</h3>
          {topStages.length === 0 ? (
            <p>No stage data</p>
          ) : (
            <ul>
              {topStages.map((stage) => (
                <li key={stage.stageId}>
                  {stageNames?.get(stage.stageId) || stage.stageId}: {stage.conversionRate.toFixed(1)}% ({stage.won}/{stage.entered})
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="report-card">
          <h3>Top Lost Reasons</h3>
          {topLostReasons.length === 0 ? (
            <p>No lost reasons</p>
          ) : (
            <ul>
              {topLostReasons.map((reason) => (
                <li key={reason.reason}>
                  {reason.reason}: {reason.count} ({formatCurrency(reason.valueCents)})
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="report-card">
          <h3>Recent Buckets</h3>
          {recentBuckets.length === 0 ? (
            <p>No time buckets</p>
          ) : (
            <ul>
              {recentBuckets.map((bucket) => (
                <li key={`${bucket.bucket}-${bucket.periodStart.toISOString()}`}>
                  {bucket.bucket} {bucket.periodStart.toISOString().slice(0, 10)}: Won{' '}
                  {formatCurrency(bucket.metrics.wonValueCents)}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </section>
  );
}

export default ReportingBreakdowns;
