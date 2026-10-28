/**
 * ConversionChart Component
 * Funnel visualization showing conversion through stages
 *
 * Agent CRM-19 Implementation
 */

import React from 'react';
import { ChartContainer } from './ChartContainer';
import './charts.css';

// ============================================
// Types
// ============================================

export interface ConversionStage {
  id: string;
  name: string;
  count: number;
  color?: string;
}

export interface ConversionChartProps {
  /** Funnel stages (ordered from top to bottom) */
  stages: ConversionStage[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Chart height */
  height?: number;
}

// ============================================
// Component
// ============================================

/**
 * ConversionChart - Funnel visualization of conversions
 *
 * @example
 * ```tsx
 * <ConversionChart
 *   stages={[
 *     { id: 'leads', name: 'Leads', count: 100, color: '#6366f1' },
 *     { id: 'qualified', name: 'Qualified', count: 60, color: '#8b5cf6' },
 *     { id: 'proposal', name: 'Proposal', count: 30, color: '#a855f7' },
 *     { id: 'won', name: 'Won', count: 15, color: '#22c55e' },
 *   ]}
 * />
 * ```
 */
export function ConversionChart({
  stages,
  isLoading = false,
  height = 300,
}: ConversionChartProps) {
  const isEmpty = stages.length === 0 || stages.every((s) => s.count === 0);
  const maxCount = Math.max(...stages.map((s) => s.count), 1);

  // Calculate conversion rates between stages
  const stagesWithConversion = stages.map((stage, index) => {
    const prevStage = index > 0 ? stages[index - 1] : null;
    const conversionRate = prevStage && prevStage.count > 0
      ? Math.round((stage.count / prevStage.count) * 100)
      : null;

    return {
      ...stage,
      conversionRate,
      widthPercent: Math.max((stage.count / maxCount) * 100, 10),
    };
  });

  const defaultColors = ['#6366f1', '#8b5cf6', '#a855f7', '#d946ef', '#22c55e'];

  return (
    <ChartContainer
      title="Conversion Funnel"
      subtitle="Progression through stages"
      isLoading={isLoading}
      isEmpty={isEmpty}
      height={height}
      emptyMessage="No conversion data available"
    >
      <div className="conversion-chart">
        {stagesWithConversion.map((stage, index) => (
          <React.Fragment key={stage.id}>
            {/* Conversion rate arrow (between stages) */}
            {stage.conversionRate !== null && (
              <div className="conversion-chart__conversion">
                <span className="conversion-chart__arrow">↓</span>
                <span>{stage.conversionRate}% conversion</span>
              </div>
            )}

            {/* Stage bar */}
            <div className="conversion-chart__stage">
              <div className="conversion-chart__label">{stage.name}</div>
              <div className="conversion-chart__bar-wrapper">
                <div
                  className="conversion-chart__bar"
                  style={{
                    width: `${stage.widthPercent}%`,
                    backgroundColor: stage.color || defaultColors[index % defaultColors.length],
                  }}
                >
                  {stage.count}
                </div>
              </div>
              <div className="conversion-chart__stats">
                {index > 0 && stages[0].count > 0 && (
                  <span>{Math.round((stage.count / stages[0].count) * 100)}% of total</span>
                )}
              </div>
            </div>
          </React.Fragment>
        ))}
      </div>
    </ChartContainer>
  );
}

export default ConversionChart;
