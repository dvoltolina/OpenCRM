import { useMemo, useState } from 'react';
import type { FeatureFlags } from '../../config/features';
import type {
  ReportExportFormat,
  ReportExportFrequency,
  ReportExportStatus,
  ReportingAggregationFilters,
} from '../../types/reporting';
import { useReportExports } from '../../hooks/useReportExports';
import { useAuth } from '../../context/AuthContext';
import { downloadExportContent } from '../../services/export-download';
import '../../pages/styles/reports.css';

interface ReportExportPanelProps {
  filters: ReportingAggregationFilters;
  featureFlags: FeatureFlags;
  disabledReason?: string;
}

const cadenceOptions: Array<{ value: ReportExportFrequency; label: string }> = [
  { value: 'once', label: 'One-time' },
  { value: 'daily', label: 'Daily' },
  { value: 'weekly', label: 'Weekly' },
];

const formatOptions: Array<{ value: ReportExportFormat; label: string }> = [
  { value: 'csv', label: 'CSV' },
  { value: 'pdf', label: 'PDF' },
];

function formatStatus(status: ReportExportStatus): string {
  switch (status) {
    case 'running':
      return 'Running';
    case 'completed':
      return 'Completed';
    case 'failed':
      return 'Failed';
    case 'paused':
      return 'Paused';
    default:
      return 'Scheduled';
  }
}

export function ReportExportPanel({ filters, featureFlags, disabledReason }: ReportExportPanelProps) {
  const { crmUser } = useAuth();
  const { exports, isLoading, error, schedule, runNow } = useReportExports();
  const [format, setFormat] = useState<ReportExportFormat>('csv');
  const [cadence, setCadence] = useState<ReportExportFrequency>('once');
  const [deliveryMethod, setDeliveryMethod] = useState<'link' | 'email'>('link');
  const [targetEmail, setTargetEmail] = useState(crmUser?.email || '');
  const [startDate, setStartDate] = useState('');
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const disabled =
    !featureFlags.enableImportExport || featureFlags.enableAdvancedReporting === false || Boolean(disabledReason);

  const delivery = useMemo(
    () => ({
      method: deliveryMethod,
      targetEmail: deliveryMethod === 'email' ? targetEmail : undefined,
    }),
    [deliveryMethod, targetEmail]
  );

  const handleRunNow = async () => {
    setStatusMessage(null);
    try {
      const result = await runNow({
        format,
        filters,
        delivery,
      });

      if (deliveryMethod === 'link') {
        downloadExportContent(
          result.content,
          result.contentType,
          `report-${Date.now()}.${format}`
        );
      }

      setStatusMessage(`Export ready (${result.contentType}); expires at ${result.expiresAt.toLocaleString()}`);
    } catch (err) {
      setStatusMessage((err as Error).message);
    }
  };

  const handleSchedule = async () => {
    setStatusMessage(null);
    try {
      await schedule({
        name: 'Reporting export',
        format,
        cadence,
        startAt: startDate ? new Date(startDate) : undefined,
        filters,
        delivery,
        description: 'Scheduled reporting export',
      });
      setStatusMessage('Export scheduled');
    } catch (err) {
      setStatusMessage((err as Error).message);
    }
  };

  return (
    <div className="reports-section">
      <div className="reports-section__header">
        <div>
          <h2 className="reports-section__title">Scheduled Exports</h2>
          <p className="reports-section__subtitle">
            CSV/PDF exports respect current filters. Run-now downloads are generated from live report aggregates.
          </p>
        </div>
      </div>

      {disabled && (
        <div className="reports-alert reports-alert--warning">
          <span className="reports-alert__icon">!</span>
          <span className="reports-alert__content">
            {disabledReason || 'Reporting exports are disabled. Enable feature flags for testing.'}
          </span>
        </div>
      )}

      <div className="reports-export-grid">
        <div className="reports-export-card">
          <h3 className="reports-export-card__title">Create Export</h3>
          <div className="reports-export-form">
            <div className="reports-filter-group">
              <label htmlFor="export-format">Format</label>
              <select
                id="export-format"
                value={format}
                onChange={(e) => setFormat(e.target.value as ReportExportFormat)}
                disabled={disabled}
              >
                {formatOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="reports-filter-group">
              <label htmlFor="export-cadence">Cadence</label>
              <select
                id="export-cadence"
                value={cadence}
                onChange={(e) => setCadence(e.target.value as ReportExportFrequency)}
                disabled={disabled}
              >
                {cadenceOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="reports-filter-group">
              <label htmlFor="export-start-date">First run date (optional)</label>
              <input
                id="export-start-date"
                type="datetime-local"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={disabled}
              />
            </div>

            <div className="reports-filter-group">
              <label htmlFor="export-delivery">Delivery</label>
              <select
                id="export-delivery"
                value={deliveryMethod}
                onChange={(e) => setDeliveryMethod(e.target.value as 'link' | 'email')}
                disabled={disabled}
              >
                <option value="link">Signed link</option>
                <option value="email">Email link</option>
              </select>
            </div>

            {deliveryMethod === 'email' && (
              <div className="reports-filter-group">
                <label htmlFor="export-email">Target email</label>
                <input
                  id="export-email"
                  type="email"
                  value={targetEmail}
                  onChange={(e) => setTargetEmail(e.target.value)}
                  disabled={disabled}
                />
              </div>
            )}

            <div className="reports-export-actions">
              <button className="btn btn-primary" type="button" onClick={handleRunNow} disabled={disabled}>
                Run now
              </button>
              <button className="btn btn-secondary" type="button" onClick={handleSchedule} disabled={disabled}>
                Schedule
              </button>
            </div>
            {statusMessage && (
              <p className="reports-timestamp" style={{ marginTop: 8 }}>
                {statusMessage}
              </p>
            )}
          </div>
        </div>

        <div className="reports-export-card">
          <h3 className="reports-export-card__title">Scheduled Exports</h3>
          {isLoading ? (
            <div className="reports-loading">
              <div className="reports-loading__spinner" />
            </div>
          ) : error ? (
            <div className="reports-alert reports-alert--error">
              <span className="reports-alert__content">{error.message}</span>
            </div>
          ) : exports.length === 0 ? (
            <div className="reports-empty">
              <div className="reports-empty__title">No scheduled exports</div>
              <p className="reports-empty__description">Create an export to see it here.</p>
            </div>
          ) : (
            <div className="reports-scheduled-list">
              {exports.map((exportDef) => (
                <div key={exportDef.id} className="reports-scheduled-item">
                  <div className="reports-scheduled-item__info">
                    <span className="reports-scheduled-item__name">{exportDef.name}</span>
                    <span className="reports-scheduled-item__meta">
                      {exportDef.format.toUpperCase()} | {formatStatus(exportDef.status)} | Next: {exportDef.nextRunAt.toLocaleDateString()}
                    </span>
                  </div>
                  <div className="reports-scheduled-item__meta">
                    {exportDef.cadence}
                    {exportDef.lastRunAt && (
                      <span> | Last: {exportDef.lastRunAt.toLocaleDateString()}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default ReportExportPanel;
