/**
 * DealRottingBadge Component
 * Visual indicator for deals without recent activity
 *
 * Agent CRM-41 Implementation
 * Dependencies: CRM-41 (Deal Rotting Service)
 */

import React from 'react';
import type { DealRottingStatus } from '../../services/deal-rotting-service';
import './DealRottingBadge.css';

// ============================================
// Types
// ============================================

export interface DealRottingBadgeProps {
  /** Rotting status of the deal */
  status: DealRottingStatus;
  /** Called when badge is clicked */
  onClick?: () => void;
  /** Whether to show as compact variant */
  compact?: boolean;
  /** Whether to show tooltip */
  showTooltip?: boolean;
}

// ============================================
// Helpers
// ============================================

/**
 * Get display text for the badge
 */
function getBadgeText(status: DealRottingStatus, compact: boolean): string {
  if (compact) {
    // Compact mode: just show days
    return `${status.daysSinceActivity}d`;
  }

  // Full mode: descriptive text
  const days = status.daysSinceActivity;
  const dayText = days === 1 ? 'day' : 'days';

  if (status.isRotting) {
    return `${days} ${dayText} stale`;
  }

  if (status.isWarning) {
    return `${days} ${dayText} stale`;
  }

  return '';
}

/**
 * Get tooltip text
 */
function getTooltipText(status: DealRottingStatus): string {
  if (status.isRotting) {
    return `No activity for ${status.daysSinceActivity} days. This deal needs attention!`;
  }

  if (status.isWarning) {
    return `No activity for ${status.daysSinceActivity} days. Deal will become stale in ${status.daysUntilRotting} days.`;
  }

  return `Last activity ${status.daysSinceActivity} days ago`;
}

/**
 * Get CSS class for badge variant
 */
function getBadgeClass(status: DealRottingStatus, compact: boolean): string {
  const baseClass = compact ? 'deal-rotting-badge--compact' : 'deal-rotting-badge';

  if (status.isRotting) {
    return `${baseClass} deal-rotting-badge--rotting`;
  }

  if (status.isWarning) {
    return `${baseClass} deal-rotting-badge--warning`;
  }

  return `${baseClass} deal-rotting-badge--normal`;
}

// ============================================
// Component
// ============================================

/**
 * DealRottingBadge - Visual indicator for deal staleness
 *
 * Shows different states:
 * - Normal: No badge (< warning threshold)
 * - Warning: Yellow badge (between warning and rotting threshold)
 * - Rotting: Red badge (past rotting threshold)
 *
 * @example
 * ```tsx
 * <DealRottingBadge
 *   status={rottingStatus}
 *   onClick={() => logActivity(deal.id)}
 *   showTooltip
 * />
 * ```
 */
export function DealRottingBadge({
  status,
  onClick,
  compact = false,
  showTooltip = true,
}: DealRottingBadgeProps) {
  // Don't render if not warning or rotting
  if (!status.isWarning && !status.isRotting) {
    return null;
  }

  const badgeText = getBadgeText(status, compact);
  const tooltipText = getTooltipText(status);
  const badgeClass = getBadgeClass(status, compact);

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    onClick?.();
  };

  return (
    <div
      className={badgeClass}
      onClick={onClick ? handleClick : undefined}
      title={showTooltip ? tooltipText : undefined}
      data-testid="deal-rotting-badge"
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {status.isRotting && <span className="deal-rotting-badge__icon">&#128308;</span>}
      {status.isWarning && <span className="deal-rotting-badge__icon">&#9888;</span>}
      <span className="deal-rotting-badge__text">{badgeText}</span>
    </div>
  );
}

export default DealRottingBadge;
