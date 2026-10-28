/**
 * EmptyStage Component
 * Empty state placeholder for stages with no deals
 *
 * Agent CRM-16 Implementation
 */

import './pipeline.css';

// ============================================
// Types
// ============================================

export interface EmptyStageProps {
  /** Stage name for context */
  stageName?: string;
  /** Custom message to display */
  message?: string;
  /** Hint text for drag and drop */
  hint?: string;
}

// ============================================
// Component
// ============================================

/**
 * EmptyStage - Placeholder shown when a stage has no deals
 *
 * @example
 * ```tsx
 * <EmptyStage
 *   stageName="Qualified"
 *   hint="Drag deals here to qualify them"
 * />
 * ```
 */
export function EmptyStage({
  stageName: _stageName,
  message = 'No deals yet',
  hint = 'Drag deals here or create a new one',
}: EmptyStageProps) {
  return (
    <div className="empty-stage" data-testid="empty-stage">
      <div className="empty-stage__icon">
        <svg
          width="40"
          height="40"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
          <line x1="12" y1="8" x2="12" y2="16" />
          <line x1="8" y1="12" x2="16" y2="12" />
        </svg>
      </div>
      <div className="empty-stage__text">{message}</div>
      <div className="empty-stage__hint">{hint}</div>
    </div>
  );
}

export default EmptyStage;
