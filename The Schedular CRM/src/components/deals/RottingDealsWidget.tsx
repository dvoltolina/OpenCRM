/**
 * RottingDealsWidget Component
 * Dashboard widget showing deals without recent activity
 *
 * Agent CRM-41 Implementation
 * Dependencies: CRM-41 (Deal Rotting Service, useDealRotting)
 */

import React, { useState } from 'react';
import { useDealRotting } from '../../hooks/useDealRotting';
import { DealRottingBadge } from './DealRottingBadge';
import type { DealWithRottingStatus } from '../../services/deal-rotting-service';
import './RottingDealsWidget.css';

// ============================================
// Types
// ============================================

export interface RottingDealsWidgetProps {
  /** Maximum number of deals to show */
  limit?: number;
  /** Callback when a deal is clicked */
  onDealClick?: (dealId: string) => void;
  /** Callback when log activity is clicked */
  onLogActivity?: (dealId: string) => void;
  /** Additional CSS class */
  className?: string;
}

// ============================================
// Helper Functions
// ============================================

/**
 * Format currency value (cents to dollars)
 */
function formatCurrency(cents: number, currency: string = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(cents / 100);
}

/**
 * Format date for display
 */
function formatDate(date: Date | null): string {
  if (!date) return 'Never';

  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ============================================
// Component
// ============================================

/**
 * RottingDealsWidget - Dashboard widget for at-risk deals
 *
 * Displays deals that are:
 * - Rotting (past threshold)
 * - At risk (in warning zone)
 *
 * @example
 * ```tsx
 * <RottingDealsWidget
 *   limit={10}
 *   onDealClick={(id) => navigate(`/deals/${id}`)}
 *   onLogActivity={(id) => openActivityModal(id)}
 * />
 * ```
 */
export function RottingDealsWidget({
  limit = 10,
  onDealClick,
  onLogActivity,
  className = '',
}: RottingDealsWidgetProps) {
  const { config, rottingDeals, atRiskDeals, totalStaleCount, isLoading } = useDealRotting();
  const [showAtRisk, setShowAtRisk] = useState(true);

  // If rotting is disabled, don't show the widget
  if (!config?.enabled) {
    return null;
  }

  // Combine rotting and at-risk deals
  const allStaleDeals = showAtRisk
    ? [...rottingDeals, ...atRiskDeals]
    : rottingDeals;

  // Apply limit
  const displayDeals = allStaleDeals.slice(0, limit);

  const handleDealClick = (dealId: string) => {
    onDealClick?.(dealId);
  };

  const handleLogActivity = (e: React.MouseEvent, dealId: string) => {
    e.stopPropagation();
    onLogActivity?.(dealId);
  };

  return (
    <div className={`rotting-deals-widget ${className}`} data-testid="rotting-deals-widget">
      {/* Header */}
      <div className="rotting-deals-widget__header">
        <div className="rotting-deals-widget__title-row">
          <h3 className="rotting-deals-widget__title">Stale Deals</h3>
          {totalStaleCount > 0 && (
            <span className="rotting-deals-widget__badge">{totalStaleCount}</span>
          )}
        </div>
        <button
          className="rotting-deals-widget__toggle"
          onClick={() => setShowAtRisk(!showAtRisk)}
          title={showAtRisk ? 'Hide at-risk deals' : 'Show at-risk deals'}
        >
          {showAtRisk ? 'Rotting Only' : 'Show All'}
        </button>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="rotting-deals-widget__loading">
          <div className="rotting-deals-widget__spinner" />
          <p>Loading stale deals...</p>
        </div>
      )}

      {/* Empty State */}
      {!isLoading && displayDeals.length === 0 && (
        <div className="rotting-deals-widget__empty">
          <p className="rotting-deals-widget__empty-icon">&#127881;</p>
          <p className="rotting-deals-widget__empty-text">
            No stale deals! All your deals have recent activity.
          </p>
        </div>
      )}

      {/* Deals List */}
      {!isLoading && displayDeals.length > 0 && (
        <div className="rotting-deals-widget__list">
          {displayDeals.map((deal) => (
            <DealRow
              key={deal.id}
              deal={deal}
              onClick={handleDealClick}
              onLogActivity={handleLogActivity}
            />
          ))}
        </div>
      )}

      {/* Footer */}
      {!isLoading && displayDeals.length > 0 && totalStaleCount > limit && (
        <div className="rotting-deals-widget__footer">
          <p className="rotting-deals-widget__footer-text">
            Showing {displayDeals.length} of {totalStaleCount} stale deals
          </p>
        </div>
      )}
    </div>
  );
}

// ============================================
// Deal Row Component
// ============================================

interface DealRowProps {
  deal: DealWithRottingStatus;
  onClick: (dealId: string) => void;
  onLogActivity: (e: React.MouseEvent, dealId: string) => void;
}

function DealRow({ deal, onClick, onLogActivity }: DealRowProps) {
  return (
    <div
      className="rotting-deal-row"
      onClick={() => onClick(deal.id)}
      data-testid={`rotting-deal-${deal.id}`}
    >
      <div className="rotting-deal-row__main">
        <div className="rotting-deal-row__header">
          <h4 className="rotting-deal-row__title">{deal.title}</h4>
          <DealRottingBadge status={deal.rottingStatus} compact />
        </div>

        <div className="rotting-deal-row__details">
          <span className="rotting-deal-row__value">
            {formatCurrency(deal.valueCents, deal.currency)}
          </span>
          {deal.clientName && (
            <>
              <span className="rotting-deal-row__separator">•</span>
              <span className="rotting-deal-row__client">{deal.clientName}</span>
            </>
          )}
        </div>

        <div className="rotting-deal-row__meta">
          <span className="rotting-deal-row__last-activity">
            Last activity: {formatDate(deal.rottingStatus.lastActivityDate)}
          </span>
        </div>
      </div>

      <div className="rotting-deal-row__actions">
        <button
          className="rotting-deal-row__action-btn"
          onClick={(e) => onLogActivity(e, deal.id)}
          title="Log activity"
        >
          <span className="rotting-deal-row__action-icon">+</span>
          <span className="rotting-deal-row__action-text">Activity</span>
        </button>
      </div>
    </div>
  );
}

export default RottingDealsWidget;
