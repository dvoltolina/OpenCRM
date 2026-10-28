/**
 * ChartContainer Component
 * Shared wrapper for chart components with loading and empty states
 *
 * Agent CRM-19 Implementation
 */

import React from 'react';
import './charts.css';

// ============================================
// Types
// ============================================

export interface ChartContainerProps {
  /** Chart title */
  title: string;
  /** Optional subtitle */
  subtitle?: string;
  /** Whether data is loading */
  isLoading: boolean;
  /** Whether data is empty */
  isEmpty: boolean;
  /** Chart height in pixels */
  height?: number;
  /** Empty state message */
  emptyMessage?: string;
  /** Chart content */
  children: React.ReactNode;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * ChartContainer - Wrapper component for charts
 *
 * @example
 * ```tsx
 * <ChartContainer
 *   title="Pipeline Overview"
 *   subtitle="Deals by stage"
 *   isLoading={isLoading}
 *   isEmpty={data.length === 0}
 *   height={300}
 * >
 *   <BarChart data={data}>...</BarChart>
 * </ChartContainer>
 * ```
 */
export function ChartContainer({
  title,
  subtitle,
  isLoading,
  isEmpty,
  height = 300,
  emptyMessage = 'No data available',
  children,
  className = '',
}: ChartContainerProps) {
  return (
    <div className={`chart-container ${className}`}>
      <div className="chart-container__header">
        <h3 className="chart-container__title">{title}</h3>
        {subtitle && <p className="chart-container__subtitle">{subtitle}</p>}
      </div>

      <div className="chart-container__content" style={{ height }}>
        {isLoading ? (
          <div className="chart-container__loading">
            <div className="chart-container__spinner" />
            <p>Loading chart...</p>
          </div>
        ) : isEmpty ? (
          <div className="chart-container__empty">
            <svg
              className="chart-container__empty-icon"
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <path d="M3 3v18h18" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M7 16l4-4 4 4 6-6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            <p>{emptyMessage}</p>
          </div>
        ) : (
          children
        )}
      </div>
    </div>
  );
}

export default ChartContainer;
