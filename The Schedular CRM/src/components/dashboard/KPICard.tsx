/**
 * KPICard Component
 * Single KPI display card with value, change indicator, and trend
 *
 * Agent CRM-18 Implementation
 */

import React from 'react';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface KPICardProps {
  /** Card title */
  title: string;
  /** Main value to display */
  value: string | number;
  /** Change indicator (e.g., +15% vs last month) */
  change?: { value: number; period: string };
  /** Icon to display */
  icon?: React.ReactNode;
  /** Trend direction */
  trend?: 'up' | 'down' | 'neutral';
  /** Value format */
  format?: 'number' | 'currency' | 'percent';
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format value based on type
 */
function formatValue(value: string | number, format?: 'number' | 'currency' | 'percent'): string {
  if (typeof value === 'string') {
    return value;
  }

  switch (format) {
    case 'currency':
      // Value is in cents, convert to dollars
      return `$${(value / 100).toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      })}`;
    case 'percent':
      return `${value.toFixed(1)}%`;
    case 'number':
    default:
      return value.toLocaleString('en-US');
  }
}

/**
 * Get trend icon
 */
function getTrendIcon(trend?: 'up' | 'down' | 'neutral'): string {
  switch (trend) {
    case 'up':
      return '↑';
    case 'down':
      return '↓';
    case 'neutral':
    default:
      return '→';
  }
}

/**
 * Get trend color class
 */
function getTrendClass(trend?: 'up' | 'down' | 'neutral'): string {
  switch (trend) {
    case 'up':
      return 'kpi-card__trend--up';
    case 'down':
      return 'kpi-card__trend--down';
    case 'neutral':
    default:
      return 'kpi-card__trend--neutral';
  }
}

// ============================================
// Component
// ============================================

/**
 * KPICard - Display a single KPI metric
 *
 * @example
 * ```tsx
 * <KPICard
 *   title="Total Pipeline Value"
 *   value={totalPipelineValue}
 *   format="currency"
 *   change={{ value: 15, period: 'vs last month' }}
 *   trend="up"
 *   icon={<DollarIcon />}
 * />
 * ```
 */
export function KPICard({
  title,
  value,
  change,
  icon,
  trend,
  format,
  className = '',
}: KPICardProps) {
  const formattedValue = formatValue(value, format);
  const trendIcon = getTrendIcon(trend);
  const trendClass = getTrendClass(trend);

  return (
    <div className={`kpi-card ${className}`}>
      <div className="kpi-card__header">
        <span className="kpi-card__title">{title}</span>
        {icon && <span className="kpi-card__icon">{icon}</span>}
      </div>

      <div className="kpi-card__value">{formattedValue}</div>

      {change && (
        <div className="kpi-card__footer">
          <span className={`kpi-card__trend ${trendClass}`}>
            {trendIcon} {change.value > 0 ? '+' : ''}
            {change.value}%
          </span>
          <span className="kpi-card__period">{change.period}</span>
        </div>
      )}
    </div>
  );
}

export default KPICard;
