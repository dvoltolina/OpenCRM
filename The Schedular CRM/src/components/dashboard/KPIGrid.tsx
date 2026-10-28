/**
 * KPIGrid Component
 * Grid layout for displaying multiple KPI cards
 *
 * Agent CRM-18 Implementation
 */

import { KPICard } from './KPICard';
import type { DashboardKPIs } from '../../hooks/useDashboardKPIs';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface KPIGridProps {
  /** KPI data to display */
  kpis: DashboardKPIs;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * KPIGrid - Display dashboard KPIs in a grid layout
 *
 * @example
 * ```tsx
 * const kpis = useDashboardKPIs({ deals, leads, stages });
 *
 * return <KPIGrid kpis={kpis} />;
 * ```
 */
export function KPIGrid({ kpis, className = '' }: KPIGridProps) {
  return (
    <div className={`kpi-grid ${className}`}>
      <KPICard
        title="Total Pipeline Value"
        value={kpis.totalPipelineValue}
        format="currency"
        icon={<span>💰</span>}
      />

      <KPICard
        title="Opportunities Won This Month"
        value={kpis.dealsWonThisMonth}
        format="number"
        icon={<span>🎯</span>}
      />

      <KPICard
        title="Revenue This Month"
        value={kpis.dealsWonValue}
        format="currency"
        icon={<span>💵</span>}
      />

      <KPICard
        title="Conversion Rate"
        value={kpis.conversionRate}
        format="percent"
        icon={<span>📈</span>}
      />

      <KPICard
        title="Average Opportunity Size"
        value={kpis.averageDealSize}
        format="currency"
        icon={<span>📊</span>}
      />

      <KPICard
        title="New Leads This Month"
        value={kpis.leadsThisMonth}
        format="number"
        icon={<span>👥</span>}
      />

      <KPICard
        title="Leads Converted"
        value={kpis.leadsConverted}
        format="number"
        icon={<span>✅</span>}
      />
    </div>
  );
}

export default KPIGrid;
