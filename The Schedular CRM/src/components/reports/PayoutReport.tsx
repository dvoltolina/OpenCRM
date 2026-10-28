/**
 * PayoutReport Component
 * Per-business payout totals with date range filtering and CSV export
 *
 * Agent CRM-31 Implementation
 */

import { useState } from 'react';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { ChartContainer } from '../charts/ChartContainer';
import type { PayoutData } from '../../hooks/useAdvancedAnalytics';
import './reports.css';

// ============================================
// Types
// ============================================

export interface PayoutReportProps {
  /** Payout data over time */
  data: PayoutData[];
  /** Currency for formatting */
  currency?: string;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Current granularity */
  granularity?: 'daily' | 'weekly' | 'monthly';
  /** Granularity change callback */
  onGranularityChange?: (granularity: 'daily' | 'weekly' | 'monthly') => void;
}

// ============================================
// Helper Functions
// ============================================

function formatCurrency(cents: number, currency: string): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(cents / 100);
}

/**
 * Export data to CSV
 */
function exportToCSV(data: PayoutData[], currency: string): void {
  const headers = [
    'Date',
    'Total',
    'Appointments',
    'Invoices',
    'Subscriptions',
    'Transaction Count',
  ];

  const rows = data.map(row => [
    row.date,
    formatCurrency(row.totalCents, currency),
    formatCurrency(row.appointmentsCents, currency),
    formatCurrency(row.invoicesCents, currency),
    formatCurrency(row.subscriptionsCents, currency),
    row.count,
  ]);

  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.join(',')),
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `payout-report-${new Date().toISOString().split('T')[0]}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

// ============================================
// Component
// ============================================

/**
 * PayoutReport - Shows payout totals with breakdown by payment type
 *
 * @example
 * ```tsx
 * const payoutData = analytics.getPayouts(dateRange, 'monthly');
 *
 * <PayoutReport
 *   data={payoutData}
 *   currency="USD"
 *   granularity="monthly"
 *   onGranularityChange={setGranularity}
 * />
 * ```
 */
export function PayoutReport({
  data,
  currency = 'USD',
  isLoading = false,
  granularity = 'monthly',
  onGranularityChange,
}: PayoutReportProps) {
  const [chartType, setChartType] = useState<'bar' | 'line'>('bar');
  const [view, setView] = useState<'table' | 'chart'>('chart');

  // Calculate totals
  const totalPayoutCents = data.reduce((sum, d) => sum + d.totalCents, 0);
  const totalAppointmentsCents = data.reduce((sum, d) => sum + d.appointmentsCents, 0);
  const totalInvoicesCents = data.reduce((sum, d) => sum + d.invoicesCents, 0);
  const totalSubscriptionsCents = data.reduce((sum, d) => sum + d.subscriptionsCents, 0);
  const totalTransactions = data.reduce((sum, d) => sum + d.count, 0);

  const handleExport = () => {
    exportToCSV(data, currency);
  };

  const chartData = data.map(d => ({
    date: d.date,
    appointments: d.appointmentsCents / 100,
    invoices: d.invoicesCents / 100,
    subscriptions: d.subscriptionsCents / 100,
    total: d.totalCents / 100,
  }));

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (!active || !payload || !payload.length) return null;

    const dataPoint = payload[0]?.payload;
    if (!dataPoint) return null;

    return (
      <div className="recharts-default-tooltip">
        <p className="recharts-tooltip-label">{label}</p>
        <p className="recharts-tooltip-item">
          <strong>Total: {formatCurrency(dataPoint.total * 100, currency)}</strong>
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-primary)' }}>
          Appointments: {formatCurrency(dataPoint.appointments * 100, currency)}
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-success)' }}>
          Invoices: {formatCurrency(dataPoint.invoices * 100, currency)}
        </p>
        <p className="recharts-tooltip-item" style={{ color: 'var(--color-info)' }}>
          Subscriptions: {formatCurrency(dataPoint.subscriptions * 100, currency)}
        </p>
      </div>
    );
  };

  const renderChart = () => {
    if (chartType === 'bar') {
      return (
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
            <XAxis
              dataKey="date"
              stroke="var(--color-text-muted)"
              fontSize={12}
              tickLine={false}
            />
            <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
            <Tooltip content={<CustomTooltip />} />
            <Legend />
            <Bar dataKey="appointments" name="Appointments" stackId="a" fill="var(--color-primary)" />
            <Bar dataKey="invoices" name="Invoices" stackId="a" fill="var(--color-success)" />
            <Bar dataKey="subscriptions" name="Subscriptions" stackId="a" fill="var(--color-info)" />
          </BarChart>
        </ResponsiveContainer>
      );
    }

    return (
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={chartData} margin={{ top: 10, right: 30, left: 20, bottom: 10 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
          <XAxis
            dataKey="date"
            stroke="var(--color-text-muted)"
            fontSize={12}
            tickLine={false}
          />
          <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          <Line
            type="monotone"
            dataKey="total"
            name="Total"
            stroke="var(--color-text)"
            strokeWidth={3}
            dot={{ r: 4 }}
          />
          <Line
            type="monotone"
            dataKey="appointments"
            name="Appointments"
            stroke="var(--color-primary)"
            strokeWidth={2}
            dot={{ r: 3 }}
          />
          <Line
            type="monotone"
            dataKey="invoices"
            name="Invoices"
            stroke="var(--color-success)"
            strokeWidth={2}
            dot={{ r: 3 }}
          />
          <Line
            type="monotone"
            dataKey="subscriptions"
            name="Subscriptions"
            stroke="var(--color-info)"
            strokeWidth={2}
            dot={{ r: 3 }}
          />
        </LineChart>
      </ResponsiveContainer>
    );
  };

  return (
    <div className="payout-report">
      <div className="payout-report__header">
        <h2 className="payout-report__title">Payout Report</h2>
        <div className="payout-report__actions">
          <div className="payout-report__view-toggle">
            <button
              className={`payout-report__view-btn ${view === 'chart' ? 'payout-report__view-btn--active' : ''}`}
              onClick={() => setView('chart')}
            >
              Chart
            </button>
            <button
              className={`payout-report__view-btn ${view === 'table' ? 'payout-report__view-btn--active' : ''}`}
              onClick={() => setView('table')}
            >
              Table
            </button>
          </div>
          <button
            className="payout-report__export-btn"
            onClick={handleExport}
            disabled={isLoading || data.length === 0}
          >
            Export CSV
          </button>
        </div>
      </div>

      <div className="payout-report__stats">
        <div className="payout-report__stat payout-report__stat--primary">
          <span className="payout-report__stat-label">Total Payouts</span>
          <span className="payout-report__stat-value">
            {formatCurrency(totalPayoutCents, currency)}
          </span>
        </div>
        <div className="payout-report__stat">
          <span className="payout-report__stat-label">Appointments</span>
          <span className="payout-report__stat-value">
            {formatCurrency(totalAppointmentsCents, currency)}
          </span>
        </div>
        <div className="payout-report__stat">
          <span className="payout-report__stat-label">Invoices</span>
          <span className="payout-report__stat-value">
            {formatCurrency(totalInvoicesCents, currency)}
          </span>
        </div>
        <div className="payout-report__stat">
          <span className="payout-report__stat-label">Subscriptions</span>
          <span className="payout-report__stat-value">
            {formatCurrency(totalSubscriptionsCents, currency)}
          </span>
        </div>
        <div className="payout-report__stat">
          <span className="payout-report__stat-label">Transactions</span>
          <span className="payout-report__stat-value">{totalTransactions}</span>
        </div>
      </div>

      {view === 'chart' ? (
        <>
          <div className="payout-report__controls">
            {onGranularityChange && (
              <div className="payout-report__control-group">
                <label>Time Period:</label>
                <div className="payout-report__button-group">
                  <button
                    className={`payout-report__btn ${granularity === 'daily' ? 'payout-report__btn--active' : ''}`}
                    onClick={() => onGranularityChange('daily')}
                  >
                    Daily
                  </button>
                  <button
                    className={`payout-report__btn ${granularity === 'weekly' ? 'payout-report__btn--active' : ''}`}
                    onClick={() => onGranularityChange('weekly')}
                  >
                    Weekly
                  </button>
                  <button
                    className={`payout-report__btn ${granularity === 'monthly' ? 'payout-report__btn--active' : ''}`}
                    onClick={() => onGranularityChange('monthly')}
                  >
                    Monthly
                  </button>
                </div>
              </div>
            )}

            <div className="payout-report__control-group">
              <label>Chart Type:</label>
              <div className="payout-report__button-group">
                <button
                  className={`payout-report__btn ${chartType === 'bar' ? 'payout-report__btn--active' : ''}`}
                  onClick={() => setChartType('bar')}
                >
                  Stacked Bar
                </button>
                <button
                  className={`payout-report__btn ${chartType === 'line' ? 'payout-report__btn--active' : ''}`}
                  onClick={() => setChartType('line')}
                >
                  Line
                </button>
              </div>
            </div>
          </div>

          <ChartContainer
            title="Payout Trends"
            subtitle="Payment totals by type over time"
            isLoading={isLoading}
            isEmpty={data.length === 0}
            height={400}
            emptyMessage="No payout data available for this period"
          >
            {renderChart()}
          </ChartContainer>
        </>
      ) : (
        <div className="payout-report__table-container">
          <table className="payout-report__table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Total</th>
                <th>Appointments</th>
                <th>Invoices</th>
                <th>Subscriptions</th>
                <th>Count</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row, index) => (
                <tr key={index}>
                  <td><strong>{row.date}</strong></td>
                  <td><strong>{formatCurrency(row.totalCents, currency)}</strong></td>
                  <td>{formatCurrency(row.appointmentsCents, currency)}</td>
                  <td>{formatCurrency(row.invoicesCents, currency)}</td>
                  <td>{formatCurrency(row.subscriptionsCents, currency)}</td>
                  <td>{row.count}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td><strong>TOTAL</strong></td>
                <td><strong>{formatCurrency(totalPayoutCents, currency)}</strong></td>
                <td><strong>{formatCurrency(totalAppointmentsCents, currency)}</strong></td>
                <td><strong>{formatCurrency(totalInvoicesCents, currency)}</strong></td>
                <td><strong>{formatCurrency(totalSubscriptionsCents, currency)}</strong></td>
                <td><strong>{totalTransactions}</strong></td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}
    </div>
  );
}

export default PayoutReport;
