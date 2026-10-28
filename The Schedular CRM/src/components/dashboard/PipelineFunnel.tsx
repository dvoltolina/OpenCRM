/**
 * PipelineFunnel Component
 * Visual funnel showing deals by stage
 *
 * Agent CRM-18 Implementation
 */

import type { DashboardKPIs } from '../../hooks/useDashboardKPIs';
import type { Stage } from '../../types/models';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface PipelineFunnelProps {
  /** Deals grouped by stage */
  dealsByStage: DashboardKPIs['dealsByStage'];
  /** Pipeline stages (for colors and ordering) */
  stages: Stage[];
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format currency value (cents to dollars)
 */
function formatCurrency(cents: number): string {
  return `$${(cents / 100).toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })}`;
}

// ============================================
// Component
// ============================================

/**
 * PipelineFunnel - Visual funnel showing deals by stage
 *
 * @example
 * ```tsx
 * const { kpis, stages } = useDashboardData();
 *
 * return (
 *   <PipelineFunnel
 *     dealsByStage={kpis.dealsByStage}
 *     stages={stages}
 *   />
 * );
 * ```
 */
export function PipelineFunnel({
  dealsByStage,
  stages,
  className = '',
}: PipelineFunnelProps) {
  // Create a map of stage colors
  const stageColorMap = new Map<string, string>();
  stages.forEach((stage) => {
    stageColorMap.set(stage.id, stage.colorHex);
  });

  // Sort stages by order
  const orderedStages = [...stages].sort((a, b) => a.order - b.order);

  // Map deals by stage to ordered stages
  const orderedDealsByStage = orderedStages.map((stage) => {
    const stageData = dealsByStage.find((d) => d.stageId === stage.id);
    return {
      stageId: stage.id,
      stageName: stage.name,
      count: stageData?.count || 0,
      value: stageData?.value || 0,
      color: stage.colorHex,
    };
  });

  // Calculate max value for sizing funnel bars
  const maxValue = Math.max(...orderedDealsByStage.map((s) => s.value), 1);

  return (
    <div className={`pipeline-funnel ${className}`}>
      <div className="pipeline-funnel__header">
        <h2>Pipeline Funnel</h2>
        <p className="pipeline-funnel__subtitle">Deals by stage</p>
      </div>

      <div className="pipeline-funnel__stages">
        {orderedDealsByStage.map((stage) => {
          const widthPercent = maxValue > 0 ? (stage.value / maxValue) * 100 : 0;

          return (
            <div key={stage.stageId} className="funnel-stage">
              <div className="funnel-stage__header">
                <div className="funnel-stage__name-row">
                  <span
                    className="funnel-stage__color"
                    style={{ backgroundColor: stage.color }}
                  />
                  <span className="funnel-stage__name">{stage.stageName}</span>
                </div>
                <div className="funnel-stage__stats">
                  <span className="funnel-stage__count">{stage.count} deals</span>
                  <span className="funnel-stage__value">
                    {formatCurrency(stage.value)}
                  </span>
                </div>
              </div>

              <div className="funnel-stage__bar-container">
                <div
                  className="funnel-stage__bar"
                  style={{
                    width: `${widthPercent}%`,
                    backgroundColor: stage.color,
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {orderedDealsByStage.length === 0 && (
        <div className="pipeline-funnel__empty">
          <p>No pipeline data available</p>
        </div>
      )}
    </div>
  );
}

export default PipelineFunnel;
