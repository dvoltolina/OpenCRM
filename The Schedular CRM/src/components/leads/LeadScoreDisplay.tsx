/**
 * LeadScoreDisplay Component
 * Visual display of lead score with color coding and breakdown
 *
 * Agent CRM-40 Implementation
 * Dependencies: CRM-08 (Lead hooks), CRM-20 (Settings)
 */

import { useState } from 'react';
import { getScoreTier } from '../../types/lead-scoring';
import type { LeadScore } from '../../types/lead-scoring';

// ============================================
// Types
// ============================================

export interface LeadScoreDisplayProps {
  /** The score value (0-100) or full score object */
  score: number | LeadScore;
  /** Optional: Display in compact mode (badge only, no label) */
  compact?: boolean;
  /** Optional: Show score breakdown on hover */
  showBreakdown?: boolean;
  /** Optional: Custom class name */
  className?: string;
}

// ============================================
// Component
// ============================================

/**
 * LeadScoreDisplay - Visual score badge/indicator
 *
 * Displays a color-coded score badge:
 * - Green (70-100): Hot Lead
 * - Yellow (40-69): Warm Lead
 * - Red (0-39): Cold Lead
 *
 * @example
 * ```tsx
 * // Simple display
 * <LeadScoreDisplay score={85} />
 *
 * // Compact mode
 * <LeadScoreDisplay score={45} compact />
 *
 * // With breakdown tooltip
 * <LeadScoreDisplay
 *   score={scoreObject}
 *   showBreakdown
 * />
 * ```
 */
export function LeadScoreDisplay({
  score,
  compact = false,
  showBreakdown = false,
  className = '',
}: LeadScoreDisplayProps) {
  const [showTooltip, setShowTooltip] = useState(false);

  // Extract score value and breakdown
  const scoreValue = typeof score === 'number' ? score : score.score;
  const scoreBreakdown = typeof score === 'object' ? score.factors : undefined;

  // Get tier info
  const tier = getScoreTier(scoreValue);

  // Determine if we can show breakdown
  const canShowBreakdown = showBreakdown && scoreBreakdown && scoreBreakdown.length > 0;

  return (
    <div
      className={`lead-score-display ${compact ? 'lead-score-compact' : ''} ${className}`}
      onMouseEnter={() => canShowBreakdown && setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
      style={{ position: 'relative', display: 'inline-block' }}
    >
      {/* Score Badge */}
      <div
        className="lead-score-badge"
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: compact ? '4px' : '8px',
          padding: compact ? '4px 8px' : '6px 12px',
          borderRadius: '12px',
          backgroundColor: `${tier.color}20`,
          border: `1.5px solid ${tier.color}`,
          fontSize: compact ? '12px' : '14px',
          fontWeight: 600,
          color: tier.color,
        }}
      >
        {/* Score Circle */}
        <div
          className="score-circle"
          style={{
            width: compact ? '20px' : '24px',
            height: compact ? '20px' : '24px',
            borderRadius: '50%',
            backgroundColor: tier.color,
            color: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: compact ? '10px' : '12px',
            fontWeight: 700,
          }}
        >
          {Math.round(scoreValue)}
        </div>

        {/* Label (hidden in compact mode) */}
        {!compact && <span>{tier.label}</span>}
      </div>

      {/* Tooltip with Breakdown */}
      {canShowBreakdown && showTooltip && scoreBreakdown && (
        <div
          className="lead-score-tooltip"
          style={{
            position: 'absolute',
            top: '100%',
            left: '50%',
            transform: 'translateX(-50%)',
            marginTop: '8px',
            padding: '12px',
            backgroundColor: '#1f2937',
            color: 'white',
            borderRadius: '8px',
            boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
            zIndex: 1000,
            minWidth: '200px',
            maxWidth: '300px',
            fontSize: '13px',
            whiteSpace: 'nowrap',
          }}
        >
          {/* Arrow */}
          <div
            style={{
              position: 'absolute',
              top: '-6px',
              left: '50%',
              transform: 'translateX(-50%)',
              width: 0,
              height: 0,
              borderLeft: '6px solid transparent',
              borderRight: '6px solid transparent',
              borderBottom: '6px solid #1f2937',
            }}
          />

          {/* Title */}
          <div
            style={{
              fontWeight: 600,
              marginBottom: '8px',
              paddingBottom: '8px',
              borderBottom: '1px solid rgba(255, 255, 255, 0.2)',
            }}
          >
            Score Breakdown
          </div>

          {/* Factors */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            {scoreBreakdown.map((factor, index) => (
              <div
                key={index}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  gap: '12px',
                }}
              >
                <span style={{ opacity: 0.9 }}>{factor.rule}</span>
                <span
                  style={{
                    fontWeight: 600,
                    color: factor.points >= 0 ? '#22c55e' : '#ef4444',
                  }}
                >
                  {factor.points >= 0 ? '+' : ''}
                  {factor.points}
                </span>
              </div>
            ))}
          </div>

          {/* Total */}
          <div
            style={{
              marginTop: '8px',
              paddingTop: '8px',
              borderTop: '1px solid rgba(255, 255, 255, 0.2)',
              display: 'flex',
              justifyContent: 'space-between',
              fontWeight: 600,
            }}
          >
            <span>Total Score</span>
            <span>{Math.round(scoreValue)}</span>
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================
// Simplified Score Badge (for lists)
// ============================================

export interface ScoreBadgeProps {
  score: number;
  size?: 'sm' | 'md' | 'lg';
}

/**
 * ScoreBadge - Minimal score indicator for use in lists
 *
 * @example
 * ```tsx
 * <ScoreBadge score={85} size="sm" />
 * ```
 */
export function ScoreBadge({ score, size = 'md' }: ScoreBadgeProps) {
  const tier = getScoreTier(score);

  const sizeStyles = {
    sm: { width: '20px', height: '20px', fontSize: '10px' },
    md: { width: '28px', height: '28px', fontSize: '12px' },
    lg: { width: '36px', height: '36px', fontSize: '14px' },
  };

  const styles = sizeStyles[size];

  return (
    <div
      className="score-badge"
      style={{
        width: styles.width,
        height: styles.height,
        borderRadius: '50%',
        backgroundColor: tier.color,
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: styles.fontSize,
        fontWeight: 700,
      }}
      title={`${tier.label} (${Math.round(score)})`}
    >
      {Math.round(score)}
    </div>
  );
}

export default LeadScoreDisplay;
