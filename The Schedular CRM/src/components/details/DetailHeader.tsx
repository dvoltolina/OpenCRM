/**
 * DetailHeader Component
 * Shared header for detail views with title, badges, and actions
 *
 * Agent CRM-17 Implementation
 */

import './details.css';

// ============================================
// Types
// ============================================

export interface Badge {
  label: string;
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
}

export interface DetailHeaderAction {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
}

export interface DetailHeaderProps {
  /** Main title */
  title: string;
  /** Subtitle or secondary info */
  subtitle?: string;
  /** Badge list to display */
  badges?: Badge[];
  /** Action buttons */
  actions?: DetailHeaderAction[];
  /** Back button handler */
  onBack?: () => void;
}

// ============================================
// Component
// ============================================

/**
 * DetailHeader - Shared header for detail views
 *
 * @example
 * ```tsx
 * <DetailHeader
 *   title="John Doe"
 *   subtitle="john@example.com"
 *   badges={[
 *     { label: 'New', variant: 'primary' },
 *     { label: 'Website', variant: 'default' }
 *   ]}
 *   actions={[
 *     { label: 'Edit', onClick: handleEdit },
 *     { label: 'Delete', onClick: handleDelete, variant: 'danger' }
 *   ]}
 *   onBack={handleBack}
 * />
 * ```
 */
export function DetailHeader({
  title,
  subtitle,
  badges = [],
  actions = [],
  onBack,
}: DetailHeaderProps) {
  return (
    <div className="detail-header">
      <div className="detail-header__main">
        {onBack && (
          <button
            type="button"
            className="detail-header__back"
            onClick={onBack}
            aria-label="Go back"
          >
            ←
          </button>
        )}
        <div className="detail-header__info">
          <h1 className="detail-header__title">{title}</h1>
          {subtitle && <p className="detail-header__subtitle">{subtitle}</p>}
          {badges.length > 0 && (
            <div className="detail-header__badges">
              {badges.map((badge, index) => (
                <span
                  key={index}
                  className={`detail-badge detail-badge--${badge.variant || 'default'}`}
                >
                  {badge.label}
                </span>
              ))}
            </div>
          )}
        </div>
      </div>
      {actions.length > 0 && (
        <div className="detail-header__actions">
          {actions.map((action, index) => (
            <button
              key={index}
              type="button"
              className={`btn btn--${action.variant || 'secondary'}`}
              onClick={action.onClick}
              disabled={action.disabled}
            >
              {action.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default DetailHeader;
