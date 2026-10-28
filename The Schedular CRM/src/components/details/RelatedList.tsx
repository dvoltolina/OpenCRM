/**
 * RelatedList Component
 * List of related records with links
 *
 * Agent CRM-17 Implementation
 */

import './details.css';

// ============================================
// Types
// ============================================

export interface RelatedItem {
  id: string;
  title: string;
  subtitle?: string;
  metadata?: string;
  onClick?: () => void;
}

export interface RelatedListProps {
  /** List items */
  items: RelatedItem[];
  /** Loading state */
  isLoading?: boolean;
  /** Empty state message */
  emptyMessage?: string;
  /** Action to create new item */
  onCreateNew?: () => void;
  /** Create button label */
  createLabel?: string;
}

// ============================================
// Component
// ============================================

/**
 * RelatedList - List of related records
 *
 * @example
 * ```tsx
 * <RelatedList
 *   items={[
 *     {
 *       id: '1',
 *       title: 'Deal #1',
 *       subtitle: '$10,000',
 *       metadata: 'Negotiation',
 *       onClick: () => navigate('/deals/1')
 *     }
 *   ]}
 *   emptyMessage="No deals found"
 *   onCreateNew={() => setShowModal(true)}
 *   createLabel="Create Deal"
 * />
 * ```
 */
export function RelatedList({
  items,
  isLoading = false,
  emptyMessage = 'No items',
  onCreateNew,
  createLabel = 'Create',
}: RelatedListProps) {
  if (isLoading) {
    return (
      <div className="related-list">
        <div className="related-list__loading">Loading...</div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="related-list">
        <div className="related-list__empty">
          <p>{emptyMessage}</p>
          {onCreateNew && (
            <button type="button" className="btn btn--primary btn--sm" onClick={onCreateNew}>
              {createLabel}
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="related-list">
      <div className="related-list__items">
        {items.map((item) => (
          <div
            key={item.id}
            className={`related-list__item ${item.onClick ? 'related-list__item--clickable' : ''}`}
            onClick={item.onClick}
            role={item.onClick ? 'button' : undefined}
            tabIndex={item.onClick ? 0 : undefined}
            onKeyDown={
              item.onClick
                ? (e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      item.onClick?.();
                    }
                  }
                : undefined
            }
          >
            <div className="related-list__item-content">
              <div className="related-list__item-top">
                <div className="related-list__item-title">{item.title}</div>
                {item.metadata && <div className="related-list__item-meta">{item.metadata}</div>}
              </div>
              {item.subtitle && (
                <div className="related-list__item-subtitle">{item.subtitle}</div>
              )}
            </div>
            {item.onClick && (
              <span className="related-list__item-arrow" aria-hidden="true">
                →
              </span>
            )}
          </div>
        ))}
      </div>
      {onCreateNew && (
        <div className="related-list__footer">
          <button type="button" className="btn btn--secondary btn--sm" onClick={onCreateNew}>
            {createLabel}
          </button>
        </div>
      )}
    </div>
  );
}

export default RelatedList;
