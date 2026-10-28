/**
 * DetailSection Component
 * Collapsible section for organizing detail view content
 *
 * Agent CRM-17 Implementation
 */

import React, { useState } from 'react';
import './details.css';

// ============================================
// Types
// ============================================

export interface DetailSectionProps {
  /** Section title */
  title: string;
  /** Section content */
  children: React.ReactNode;
  /** Whether the section is collapsible */
  collapsible?: boolean;
  /** Initial collapsed state (only when collapsible) */
  defaultCollapsed?: boolean;
  /** Action button for the section */
  action?: {
    label: string;
    onClick: () => void;
  };
}

// ============================================
// Component
// ============================================

/**
 * DetailSection - Collapsible section for detail views
 *
 * @example
 * ```tsx
 * <DetailSection title="Contact Information">
 *   <p>Email: john@example.com</p>
 *   <p>Phone: (555) 123-4567</p>
 * </DetailSection>
 *
 * <DetailSection
 *   title="Notes"
 *   collapsible
 *   defaultCollapsed
 *   action={{ label: 'Edit Notes', onClick: handleEdit }}
 * >
 *   <p>Some notes here...</p>
 * </DetailSection>
 * ```
 */
export function DetailSection({
  title,
  children,
  collapsible = false,
  defaultCollapsed = false,
  action,
}: DetailSectionProps) {
  const [isCollapsed, setIsCollapsed] = useState(defaultCollapsed);

  const handleToggle = () => {
    if (collapsible) {
      setIsCollapsed(!isCollapsed);
    }
  };

  return (
    <div className={`detail-section ${isCollapsed ? 'detail-section--collapsed' : ''}`}>
      <div className="detail-section__header">
        <h2
          className="detail-section__title"
          onClick={handleToggle}
          role={collapsible ? 'button' : undefined}
          tabIndex={collapsible ? 0 : undefined}
          onKeyDown={
            collapsible
              ? (e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    handleToggle();
                  }
                }
              : undefined
          }
        >
          {collapsible && (
            <span className="detail-section__toggle" aria-hidden="true">
              {isCollapsed ? '▶' : '▼'}
            </span>
          )}
          {title}
        </h2>
        {action && (
          <button
            type="button"
            className="detail-section__action btn btn--ghost btn--sm"
            onClick={action.onClick}
          >
            {action.label}
          </button>
        )}
      </div>
      {!isCollapsed && <div className="detail-section__content">{children}</div>}
    </div>
  );
}

export default DetailSection;
