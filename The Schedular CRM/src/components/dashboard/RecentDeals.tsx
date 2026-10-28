/**
 * RecentDeals Component
 * List of recently updated deals
 *
 * Agent CRM-18 Implementation
 */

import type { Deal } from '../../types/models';
import './dashboard.css';

// ============================================
// Types
// ============================================

export interface RecentDealsProps {
  /** List of deals to display */
  deals: Deal[];
  /** Maximum number of deals to show */
  limit?: number;
  /** Callback when a deal is clicked */
  onDealClick?: (dealId: string) => void;
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

/**
 * Format relative time
 */
function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

/**
 * Get status badge class
 */
function getStatusClass(status: Deal['status']): string {
  return `status-badge status-${status}`;
}

// ============================================
// Component
// ============================================

/**
 * RecentDeals - List of recently updated deals
 *
 * @example
 * ```tsx
 * const { deals } = useDeals();
 *
 * return (
 *   <RecentDeals
 *     deals={deals}
 *     limit={5}
 *     onDealClick={(id) => navigate(`/deals/${id}`)}
 *   />
 * );
 * ```
 */
export function RecentDeals({
  deals,
  limit = 10,
  onDealClick,
  className = '',
}: RecentDealsProps) {
  // Sort by updatedAt (most recent first) and limit
  const recentDeals = [...deals]
    .sort((a, b) => {
      const dateA = a.updatedAt || a.createdAt;
      const dateB = b.updatedAt || b.createdAt;
      return dateB.getTime() - dateA.getTime();
    })
    .slice(0, limit);

  return (
    <div className={`recent-deals ${className}`}>
      <div className="recent-deals__header">
        <h2>Recent Opportunities</h2>
        <p className="recent-deals__subtitle">Recently updated</p>
      </div>

      <div className="recent-deals__list">
        {recentDeals.map((deal) => {
          const lastUpdate = deal.updatedAt || deal.createdAt;

          return (
            <div
              key={deal.id}
              className="recent-deal-item"
              onClick={() => onDealClick?.(deal.id)}
              role={onDealClick ? 'button' : undefined}
              tabIndex={onDealClick ? 0 : undefined}
            >
              <div className="recent-deal-item__main">
                <div className="recent-deal-item__header">
                  <h3 className="recent-deal-item__title">{deal.title}</h3>
                  <span className="recent-deal-item__value">
                    {formatCurrency(deal.valueCents)}
                  </span>
                </div>

                <div className="recent-deal-item__meta">
                  <span className={getStatusClass(deal.status)}>
                    {deal.status}
                  </span>
                  {deal.clientName && (
                    <span className="recent-deal-item__client">
                      {deal.clientName}
                    </span>
                  )}
                  {deal.assigneeName && (
                    <span className="recent-deal-item__assignee">
                      {deal.assigneeName}
                    </span>
                  )}
                </div>
              </div>

              <div className="recent-deal-item__time">
                {formatRelativeTime(lastUpdate)}
              </div>
            </div>
          );
        })}
      </div>

      {recentDeals.length === 0 && (
        <div className="recent-deals__empty">
          <p>No opportunities found</p>
        </div>
      )}
    </div>
  );
}

export default RecentDeals;
