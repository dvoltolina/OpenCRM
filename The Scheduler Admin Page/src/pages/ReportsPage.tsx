import type { CSSProperties } from 'react';

import { isDemoMode } from '../config/demo';
import type { ReportType } from '../data/reports';
import { useBusinessContext } from '../hooks/useBusinessContext';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import {
  formatUpdatedTimestamp,
  type ReportsPreset,
  useReports,
} from '../hooks/useReports';
import { THEME, SPACING } from './dashboard/DashboardComponents';

const PRESET_OPTIONS: Array<{ value: ReportsPreset; label: string }> = [
  { value: '7d', label: 'Last 7 days' },
  { value: '30d', label: 'Last 30 days' },
  { value: '90d', label: 'Last 90 days' },
  { value: 'custom', label: 'Custom range' },
];

const REPORT_TYPE_OPTIONS: Array<{ value: ReportType; label: string }> = [
  { value: 'appointments', label: 'Appointments export' },
  { value: 'payments', label: 'Payments export' },
  { value: 'clients', label: 'Clients export' },
];

const currencyFormatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
  maximumFractionDigits: 0,
});

export function ReportsPage() {
  const { businessId } = useBusinessContext({ minRole: 'admin' });
  const {
    flags,
    loading: flagsLoading,
    error: flagsError,
    refresh: refreshFlags,
  } = useFeatureFlags(businessId);
  const reportingEnabled = flags.enableReporting;
  const {
    filters,
    reportType,
    setReportType,
    data,
    loading,
    error,
    exporting,
    lastUpdatedAt,
    setPresetRange,
    setCustomRange,
    refresh,
    exportCsv,
    exportPdf,
  } = useReports({ enabled: reportingEnabled });

  const updatedLabel = formatUpdatedTimestamp(lastUpdatedAt);
  const cancellationRate =
    data && data.totalAppointments > 0 ?
      (data.cancelledAppointments / data.totalAppointments) * 100 :
      0;

  const styles = {
    pageContainer: {
      minHeight: '100vh',
      background: `linear-gradient(180deg, ${THEME.colorBgGradientStart} 0%, ${THEME.colorBgGradientEnd} 100%)`,
      padding: SPACING.xl,
    } as CSSProperties,
    pageHeader: { marginBottom: SPACING.xl } as CSSProperties,
    eyebrow: {
      fontSize: 11,
      fontWeight: 600,
      color: THEME.colorAccent,
      textTransform: 'uppercase',
      letterSpacing: '0.1em',
      margin: 0,
    } as CSSProperties,
    title: {
      fontSize: 26,
      fontWeight: 700,
      color: THEME.colorText,
      margin: `${SPACING.sm}px 0 0`,
      lineHeight: 1.2,
    } as CSSProperties,
    muted: {
      fontSize: 14,
      color: THEME.colorTextMuted,
      margin: `${SPACING.xs}px 0 0`,
      lineHeight: 1.5,
    } as CSSProperties,
    panel: {
      background: THEME.colorBgPanelGradient,
      borderRadius: THEME.radius,
      boxShadow: THEME.shadow,
      border: `1px solid ${THEME.colorBorder}`,
      padding: SPACING.lg,
    } as CSSProperties,
  };

  if (flagsLoading) {
    return (
      <section style={styles.pageContainer}>
        <header style={styles.pageHeader}>
          <div>
            <p style={styles.eyebrow}>Analytics</p>
            <h1 style={styles.title}>Reports</h1>
            <p style={styles.muted}>Loading tenant configuration…</p>
          </div>
        </header>
        <div style={styles.panel}>
          <p style={styles.muted}>Fetching feature flags for this business.</p>
        </div>
      </section>
    );
  }

  if (flagsError) {
    return (
      <section style={styles.pageContainer}>
        <header style={styles.pageHeader}>
          <div>
            <p style={styles.eyebrow}>Analytics</p>
            <h1 style={styles.title}>Reports</h1>
            <p style={styles.muted}>Unable to load feature flags.</p>
          </div>
        </header>
        <div style={styles.panel}>
          <p style={{ ...styles.title, fontSize: 16, margin: 0 }}>Feature flags unavailable</p>
          <p style={{ ...styles.muted, marginTop: SPACING.sm }}>{flagsError}</p>
          <div style={{ marginTop: SPACING.md }}>
            <button className="button button--ghost" onClick={() => void refreshFlags()}>
              Retry
            </button>
          </div>
        </div>
      </section>
    );
  }

  if (!reportingEnabled) {
    return (
      <section style={styles.pageContainer}>
        <header style={styles.pageHeader}>
          <div>
            <p style={styles.eyebrow}>Analytics</p>
            <h1 style={styles.title}>Reports</h1>
            <p style={styles.muted}>Reporting is disabled for this business.</p>
          </div>
        </header>
        <div style={styles.panel}>
          <p style={{ ...styles.title, fontSize: 16, margin: 0 }}>Reporting module disabled</p>
          <p style={{ ...styles.muted, marginTop: SPACING.sm }}>
            Toggle `enableReporting` in feature flags to expose metrics and exports for this tenant.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section style={styles.pageContainer}>
      <header style={styles.pageHeader}>
        <div>
          <p style={styles.eyebrow}>Analytics</p>
          <h1 style={styles.title}>Reports</h1>
          <p style={styles.muted}>
            The Admin app now consumes the shared Scheduler reporting endpoints directly. Metrics are live; advanced
            chart packs and saved views are not yet part of the shared contract.
          </p>
        </div>
      </header>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: SPACING.md,
          marginBottom: SPACING.lg,
          ...styles.panel,
        }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
          <label htmlFor="reports-range" style={{ fontSize: 13, fontWeight: 500, color: THEME.colorText }}>
            Range
          </label>
          <select
            id="reports-range"
            value={filters.preset}
            onChange={(event) => setPresetRange(event.target.value as ReportsPreset)}
          >
            {PRESET_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
          <label htmlFor="reports-type" style={{ fontSize: 13, fontWeight: 500, color: THEME.colorText }}>
            Export dataset
          </label>
          <select
            id="reports-type"
            value={reportType}
            onChange={(event) => setReportType(event.target.value as ReportType)}
          >
            {REPORT_TYPE_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        {filters.preset === 'custom' && (
          <>
            <div style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
              <label htmlFor="reports-start" style={{ fontSize: 13, fontWeight: 500, color: THEME.colorText }}>
                Start
              </label>
              <input
                id="reports-start"
                type="date"
                value={filters.startDate}
                onChange={(event) => setCustomRange({ startDate: event.target.value })}
                max={filters.endDate}
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: SPACING.xs }}>
              <label htmlFor="reports-end" style={{ fontSize: 13, fontWeight: 500, color: THEME.colorText }}>
                End
              </label>
              <input
                id="reports-end"
                type="date"
                value={filters.endDate}
                onChange={(event) => setCustomRange({ endDate: event.target.value })}
                min={filters.startDate}
              />
            </div>
          </>
        )}

        <div style={{ display: 'flex', gap: SPACING.sm, flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <button className="button button--ghost" type="button" onClick={refresh} disabled={loading}>
            {loading ? 'Refreshing…' : 'Refresh'}
          </button>
          <button
            className="button button--primary"
            type="button"
            onClick={exportCsv}
            disabled={!data || exporting.csv || isDemoMode}
            title={isDemoMode ? 'Exports are disabled in demo mode.' : undefined}
          >
            {exporting.csv ? 'Exporting…' : 'Export CSV'}
          </button>
          <button
            className="button"
            type="button"
            onClick={exportPdf}
            disabled={!data || exporting.pdf || isDemoMode}
            title={isDemoMode ? 'Exports are disabled in demo mode.' : undefined}
          >
            {exporting.pdf ? 'Preparing…' : 'Export PDF'}
          </button>
        </div>
      </div>

      {updatedLabel && <p style={{ ...styles.muted, marginBottom: SPACING.md }}>Updated {updatedLabel}</p>}

      {error && (
        <div
          style={{
            ...styles.panel,
            borderColor: THEME.colorDanger,
            color: THEME.colorDanger,
            marginBottom: SPACING.lg,
          }}
        >
          {error}
        </div>
      )}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: SPACING.lg,
          marginBottom: SPACING.lg,
        }}
      >
        <MetricCard label="Total appointments" value={formatNumber(data?.totalAppointments)} note="Within selected range" />
        <MetricCard label="Completed" value={formatNumber(data?.completedAppointments)} note={formatPercentValue(data?.completionRate)} />
        <MetricCard label="Cancelled" value={formatNumber(data?.cancelledAppointments)} note={`${formatPercentValue(cancellationRate)} cancellation rate`} />
        <MetricCard label="Revenue" value={formatCurrency(data?.totalRevenue)} note="Completed payments only" />
        <MetricCard label="New clients" value={formatNumber(data?.newClients)} note="Created during selected range" />
        <MetricCard
          label="Avg revenue / appt"
          value={formatCurrency(data?.averageRevenuePerAppointment)}
          note={`Export type: ${reportType}`}
        />
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: SPACING.lg,
        }}
      >
        <div style={styles.panel}>
          <p className="panel__title">Shared reporting contract</p>
          <p style={styles.muted}>
            Metrics come from `POST /getReportMetrics` and exports come from `POST /exportReportCsv` and
            `POST /exportReportPdf`. The selected export dataset controls the CSV/PDF payload only.
          </p>
          <ul style={{ margin: `${SPACING.md}px 0 0`, paddingLeft: SPACING.lg, color: THEME.colorTextMuted }}>
            <li>Appointments exports include appointment rows and status/payment metadata.</li>
            <li>Payments exports include completed payment rows for the selected range.</li>
            <li>Clients exports include newly created client rows for the selected range.</li>
          </ul>
        </div>

        <div style={styles.panel}>
          <p className="panel__title">Remaining limits</p>
          <p style={styles.muted}>
            Saved report views, richer chart packs, and custom drill-down analytics are still outside the current
            shared Scheduler backend contract. This page only shows metrics the shared backend actually returns.
          </p>
          <p style={{ ...styles.muted, marginTop: SPACING.md }}>
            Demo mode keeps exports disabled, but live tenants can export the selected dataset as CSV or PDF from the
            shared functions layer.
          </p>
        </div>
      </div>
    </section>
  );
}

function MetricCard({ label, value, note }: { label: string; value: string; note?: string }) {
  const cardStyle: CSSProperties = {
    display: 'flex',
    flexDirection: 'column',
    gap: SPACING.sm,
    padding: SPACING.lg,
    background: THEME.colorBgPanelGradient,
    borderRadius: THEME.radius,
    boxShadow: THEME.shadow,
    border: `1px solid ${THEME.colorBorder}`,
    minHeight: 120,
  };

  return (
    <div style={cardStyle}>
      <p
        style={{
          fontSize: 13,
          fontWeight: 500,
          color: THEME.colorTextMuted,
          margin: 0,
          textTransform: 'uppercase',
          letterSpacing: '0.02em',
        }}
      >
        {label}
      </p>
      <p style={{ fontSize: 28, fontWeight: 700, color: THEME.colorText, margin: 0, lineHeight: 1.1 }}>{value}</p>
      {note && <p style={{ fontSize: 13, color: THEME.colorTextMuted, margin: 0, lineHeight: 1.4 }}>{note}</p>}
    </div>
  );
}

function formatCurrency(value?: number) {
  if (typeof value !== 'number') {
    return '—';
  }
  return currencyFormatter.format(value);
}

function formatNumber(value?: number) {
  if (typeof value !== 'number') {
    return '—';
  }
  return new Intl.NumberFormat().format(value);
}

function formatPercentValue(value?: number) {
  if (typeof value !== 'number') {
    return '—';
  }
  return `${value.toFixed(1)}%`;
}
