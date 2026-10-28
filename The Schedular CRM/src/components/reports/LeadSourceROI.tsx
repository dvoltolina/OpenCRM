/**
 * LeadSourceROI Component
 * Table and chart showing ROI by lead source with cost inputs
 *
 * Agent CRM-31 Implementation
 */

import React, { useState, useMemo } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { ChartContainer } from '../charts/ChartContainer';
import type { LeadSourceROIData } from '../../hooks/useAdvancedAnalytics';
import './reports.css';

// ============================================
// Types
// ============================================

export interface LeadSourceROIProps {
  /** ROI data by source */
  data: LeadSourceROIData[];
  /** Currency for formatting */
  currency?: string;
  /** Whether data is loading */
  isLoading?: boolean;
  /** Callback when source costs are updated */
  onCostsChange?: (costs: Map<string, number>) => void;
  /** Initial source costs in cents */
  initialCosts?: Map<string, number>;
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

function formatPercentage(value: number): string {
  return `${value >= 0 ? '+' : ''}${value.toFixed(1)}%`;
}

/**
 * Export data to CSV
 */
function exportToCSV(data: LeadSourceROIData[], currency: string): void {
  const headers = [
    'Lead Source',
    'Leads',
    'Converted',
    'Conversion Rate',
    'Cost',
    'Revenue',
    'ROI',
    'Cost/Lead',
    'Cost/Conversion',
  ];

  const rows = data.map(row => [
    row.source,
    row.leadCount,
    row.convertedCount,
    `${row.conversionRate.toFixed(1)}%`,
    formatCurrency(row.costCents, currency),
    formatCurrency(row.revenueCents, currency),
    formatPercentage(row.roiPercentage),
    formatCurrency(row.costPerLead, currency),
    formatCurrency(row.costPerConversion, currency),
  ]);

  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.join(',')),
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `lead-source-roi-${new Date().toISOString().split('T')[0]}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

// ============================================
// Component
// ============================================

/**
 * LeadSourceROI - Shows ROI analysis by lead source
 *
 * @example
 * ```tsx
 * const roiData = analytics.getLeadSourceROI(dateRange, sourceCosts);
 *
 * <LeadSourceROI
 *   data={roiData}
 *   currency="USD"
 *   initialCosts={sourceCosts}
 *   onCostsChange={setSourceCosts}
 * />
 * ```
 */
export function LeadSourceROI({
  data,
  currency = 'USD',
  isLoading = false,
  onCostsChange,
  initialCosts = new Map(),
}: LeadSourceROIProps) {
  const [editingSource, setEditingSource] = useState<string | null>(null);
  const [costs, setCosts] = useState<Map<string, number>>(initialCosts);
  const [view, setView] = useState<'table' | 'chart'>('table');

  // Update costs when initial costs change
  React.useEffect(() => {
    setCosts(initialCosts);
  }, [initialCosts]);

  const handleCostChange = (source: string, value: string) => {
    const cents = Math.round(parseFloat(value || '0') * 100);
    const newCosts = new Map(costs);
    newCosts.set(source, cents);
    setCosts(newCosts);
    onCostsChange?.(newCosts);
  };

  const handleExport = () => {
    exportToCSV(data, currency);
  };

  // Prepare chart data
  const chartData = useMemo(() => {
    return data.map(row => ({
      source: row.source,
      cost: row.costCents / 100,
      revenue: row.revenueCents / 100,
      roi: row.roiPercentage,
    }));
  }, [data]);

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (!active || !payload || !payload.length) return null;

    return (
      <div className="recharts-default-tooltip">
        <p className="recharts-tooltip-label">{label}</p>
        {payload.map((entry: any, index: number) => (
          <p key={index} className="recharts-tooltip-item" style={{ color: entry.color }}>
            {entry.name}: {
              entry.dataKey === 'roi'
                ? formatPercentage(entry.value)
                : formatCurrency(entry.value * 100, currency)
            }
          </p>
        ))}
      </div>
    );
  };

  return (
    <div className="lead-source-roi">
      <div className="lead-source-roi__header">
        <h2 className="lead-source-roi__title">Lead Source ROI Analysis</h2>
        <div className="lead-source-roi__actions">
          <div className="lead-source-roi__view-toggle">
            <button
              className={`lead-source-roi__view-btn ${view === 'table' ? 'lead-source-roi__view-btn--active' : ''}`}
              onClick={() => setView('table')}
            >
              Table
            </button>
            <button
              className={`lead-source-roi__view-btn ${view === 'chart' ? 'lead-source-roi__view-btn--active' : ''}`}
              onClick={() => setView('chart')}
            >
              Chart
            </button>
          </div>
          <button
            className="lead-source-roi__export-btn"
            onClick={handleExport}
            disabled={isLoading || data.length === 0}
          >
            Export CSV
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="lead-source-roi__loading">
          <div className="lead-source-roi__spinner" />
          <p>Loading ROI data...</p>
        </div>
      ) : data.length === 0 ? (
        <div className="lead-source-roi__empty">
          <p>No lead source data available for this period</p>
        </div>
      ) : view === 'table' ? (
        <div className="lead-source-roi__table-container">
          <table className="lead-source-roi__table">
            <thead>
              <tr>
                <th>Lead Source</th>
                <th>Leads</th>
                <th>Converted</th>
                <th>Conv. Rate</th>
                <th>Cost</th>
                <th>Revenue</th>
                <th>ROI</th>
                <th>Cost/Lead</th>
                <th>Cost/Conv.</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row) => (
                <tr key={row.source}>
                  <td className="lead-source-roi__source">
                    <strong>{row.source}</strong>
                  </td>
                  <td>{row.leadCount}</td>
                  <td>{row.convertedCount}</td>
                  <td>{row.conversionRate.toFixed(1)}%</td>
                  <td
                    className="lead-source-roi__cost-cell"
                    onClick={() => setEditingSource(row.source)}
                  >
                    {editingSource === row.source ? (
                      <input
                        type="number"
                        className="lead-source-roi__cost-input"
                        value={(costs.get(row.source) || 0) / 100}
                        onChange={(e) => handleCostChange(row.source, e.target.value)}
                        onBlur={() => setEditingSource(null)}
                        onKeyDown={(e) => e.key === 'Enter' && setEditingSource(null)}
                        autoFocus
                        step="0.01"
                        min="0"
                      />
                    ) : (
                      <span className="lead-source-roi__cost-value">
                        {formatCurrency(row.costCents, currency)}
                        <span className="lead-source-roi__edit-hint">Click to edit</span>
                      </span>
                    )}
                  </td>
                  <td>{formatCurrency(row.revenueCents, currency)}</td>
                  <td className={row.roiPercentage >= 0 ? 'lead-source-roi__positive' : 'lead-source-roi__negative'}>
                    <strong>{formatPercentage(row.roiPercentage)}</strong>
                  </td>
                  <td>{formatCurrency(row.costPerLead, currency)}</td>
                  <td>{formatCurrency(row.costPerConversion, currency)}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td><strong>TOTAL</strong></td>
                <td><strong>{data.reduce((sum, r) => sum + r.leadCount, 0)}</strong></td>
                <td><strong>{data.reduce((sum, r) => sum + r.convertedCount, 0)}</strong></td>
                <td><strong>
                  {(data.reduce((sum, r) => sum + r.convertedCount, 0) /
                    data.reduce((sum, r) => sum + r.leadCount, 0) * 100).toFixed(1)}%
                </strong></td>
                <td><strong>{formatCurrency(data.reduce((sum, r) => sum + r.costCents, 0), currency)}</strong></td>
                <td><strong>{formatCurrency(data.reduce((sum, r) => sum + r.revenueCents, 0), currency)}</strong></td>
                <td className={
                  ((data.reduce((sum, r) => sum + r.revenueCents, 0) - data.reduce((sum, r) => sum + r.costCents, 0)) /
                    data.reduce((sum, r) => sum + r.costCents, 0) * 100) >= 0
                    ? 'lead-source-roi__positive'
                    : 'lead-source-roi__negative'
                }>
                  <strong>
                    {formatPercentage(
                      (data.reduce((sum, r) => sum + r.revenueCents, 0) - data.reduce((sum, r) => sum + r.costCents, 0)) /
                      data.reduce((sum, r) => sum + r.costCents, 0) * 100
                    )}
                  </strong>
                </td>
                <td colSpan={2}></td>
              </tr>
            </tfoot>
          </table>
        </div>
      ) : (
        <ChartContainer
          title="ROI by Lead Source"
          subtitle="Cost vs Revenue comparison"
          isLoading={false}
          isEmpty={chartData.length === 0}
          height={400}
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 20, right: 30, left: 20, bottom: 60 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
              <XAxis
                dataKey="source"
                stroke="var(--color-text-muted)"
                fontSize={12}
                tickLine={false}
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis stroke="var(--color-text-muted)" fontSize={12} tickLine={false} />
              <Tooltip content={<CustomTooltip />} />
              <Legend />
              <Bar dataKey="cost" name="Cost" fill="var(--color-danger)" />
              <Bar dataKey="revenue" name="Revenue" fill="var(--color-success)" />
            </BarChart>
          </ResponsiveContainer>
        </ChartContainer>
      )}

      <div className="lead-source-roi__info">
        <p>
          <strong>Note:</strong> Click on cost values in the table to edit. ROI is calculated as
          (Revenue - Cost) / Cost × 100%.
        </p>
      </div>
    </div>
  );
}

export default LeadSourceROI;
