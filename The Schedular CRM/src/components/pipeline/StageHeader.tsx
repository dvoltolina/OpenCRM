/**
 * StageHeader Component
 * Header for kanban column showing stage name, count, and total value
 *
 * Agent CRM-16 Implementation
 */

import type { Stage } from '../../types/models';
import './pipeline.css';

// ============================================
// Types
// ============================================

export interface StageHeaderProps {
  /** The stage data */
  stage: Stage;
  /** Number of deals in this stage */
  count: number;
  /** Total value of deals in cents */
  totalValue: number;
  /** Currency code for formatting */
  currency?: string;
}

// ============================================
// Helpers
// ============================================

/**
 * Format cents to currency display
 */
function formatCurrency(cents: number, currency: string = 'USD'): string {
  const amount = cents / 100;
  if (amount >= 1000000) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
      notation: 'compact',
      maximumFractionDigits: 1,
    }).format(amount);
  }
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// ============================================
// Component
// ============================================

/**
 * StageHeader - Column header with stage info and metrics
 *
 * @example
 * ```tsx
 * <StageHeader
 *   stage={stage}
 *   count={5}
 *   totalValue={150000}
 *   currency="USD"
 * />
 * ```
 */
export function StageHeader({ stage, count, totalValue, currency = 'USD' }: StageHeaderProps) {
  return (
    <div className="stage-header" data-testid={`stage-header-${stage.id}`}>
      <div className="stage-header__top">
        <div className="stage-header__name-row">
          <div
            className="stage-header__color"
            style={{ backgroundColor: stage.colorHex }}
            aria-hidden="true"
          />
          <span className="stage-header__name">{stage.name}</span>
        </div>
        <span className="stage-header__count" aria-label={`${count} deals`}>
          {count}
        </span>
      </div>
      <div className="stage-header__value">
        {formatCurrency(totalValue, currency)}
      </div>
      <div className="stage-header__probability">
        {stage.probability}% win likelihood
      </div>
    </div>
  );
}

export default StageHeader;
