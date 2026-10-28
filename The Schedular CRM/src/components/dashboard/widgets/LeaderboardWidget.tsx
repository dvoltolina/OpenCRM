/**
 * LeaderboardWidget Component
 * Displays a ranked leaderboard of team members or entities.
 *
 * HIPAA Compliance:
 * - Displays aggregated performance metrics only
 * - No PHI exposed - only names and numerical metrics
 * - All access logged via parent components
 *
 * Agent CRM - Task 7 Implementation
 */

import { useMemo } from 'react';
import type { LeaderboardConfig } from '../../../types/reporting';

// ============================================
// Types
// ============================================

export interface LeaderboardEntry {
  id: string;
  name: string;
  value: number;
  rank: number;
  avatarUrl?: string;
  subtitle?: string;
}

export interface LeaderboardWidgetProps {
  /** Widget title */
  title: string;
  /** Leaderboard configuration */
  config?: LeaderboardConfig;
  /** Leaderboard entries */
  entries: LeaderboardEntry[];
  /** Whether data is loading */
  isLoading?: boolean;
  /** Error message */
  error?: string | null;
  /** Value format */
  format?: 'number' | 'currency' | 'percent';
  /** Currency for value formatting */
  currency?: string;
  /** Maximum entries to show */
  limit?: number;
  /** Click handler for entry */
  onEntryClick?: (entry: LeaderboardEntry) => void;
}

// ============================================
// Helper Functions
// ============================================

function formatValue(
  value: number,
  format: 'number' | 'currency' | 'percent' | undefined,
  currency: string
): string {
  switch (format) {
    case 'currency':
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      }).format(value / 100);

    case 'percent':
      return `${value.toFixed(1)}%`;

    case 'number':
    default:
      if (value >= 1000000) {
        return `${(value / 1000000).toFixed(1)}M`;
      }
      if (value >= 1000) {
        return `${(value / 1000).toFixed(1)}K`;
      }
      return new Intl.NumberFormat('en-US').format(value);
  }
}

function getRankBadge(rank: number): string {
  switch (rank) {
    case 1:
      return '🥇';
    case 2:
      return '🥈';
    case 3:
      return '🥉';
    default:
      return `#${rank}`;
  }
}

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .substring(0, 2);
}

// ============================================
// Avatar Component
// ============================================

interface AvatarProps {
  name: string;
  avatarUrl?: string;
}

function Avatar({ name, avatarUrl }: AvatarProps) {
  const colors = [
    '#3b82f6', // blue
    '#10b981', // emerald
    '#f59e0b', // amber
    '#ef4444', // red
    '#8b5cf6', // violet
    '#ec4899', // pink
  ];

  const colorIndex = name.charCodeAt(0) % colors.length;
  const bgColor = colors[colorIndex];

  if (avatarUrl) {
    return (
      <div className="leaderboard-widget__avatar">
        <img src={avatarUrl} alt={name} className="leaderboard-widget__avatar-img" />
      </div>
    );
  }

  return (
    <div
      className="leaderboard-widget__avatar leaderboard-widget__avatar--initials"
      style={{ backgroundColor: bgColor }}
    >
      {getInitials(name)}
    </div>
  );
}

// ============================================
// Main Component
// ============================================

/**
 * LeaderboardWidget - Ranked leaderboard display
 *
 * Features:
 * - Displays ranked list of performers
 * - Medal badges for top 3
 * - Progress bar relative to leader
 * - Avatar or initials display
 * - Click to view details
 *
 * @example
 * ```tsx
 * <LeaderboardWidget
 *   title="Top Sales This Month"
 *   entries={salesLeaderboard}
 *   format="currency"
 *   currency="USD"
 *   limit={5}
 *   onEntryClick={(entry) => navigate(`/team/${entry.id}`)}
 * />
 * ```
 */
export function LeaderboardWidget({
  title,
  config,
  entries,
  isLoading = false,
  error = null,
  format = 'number',
  currency = 'USD',
  limit = 5,
  onEntryClick,
}: LeaderboardWidgetProps) {
  // Sort and limit entries
  const displayEntries = useMemo(() => {
    return [...entries]
      .sort((a, b) => a.rank - b.rank)
      .slice(0, limit);
  }, [entries, limit]);

  // Calculate max value for progress bars
  const maxValue = useMemo(() => {
    return Math.max(...displayEntries.map((e) => e.value), 1);
  }, [displayEntries]);

  // Loading state
  if (isLoading) {
    return (
      <div className="leaderboard-widget leaderboard-widget--loading">
        <div className="leaderboard-widget__header">
          <h3 className="leaderboard-widget__title">{title}</h3>
        </div>
        <div className="leaderboard-widget__content">
          {Array.from({ length: limit }).map((_, i) => (
            <div key={i} className="leaderboard-widget__entry-skeleton" />
          ))}
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="leaderboard-widget leaderboard-widget--error">
        <div className="leaderboard-widget__header">
          <h3 className="leaderboard-widget__title">{title}</h3>
        </div>
        <div className="leaderboard-widget__content">
          <p className="leaderboard-widget__error">{error}</p>
        </div>
      </div>
    );
  }

  // Empty state
  if (displayEntries.length === 0) {
    return (
      <div className="leaderboard-widget leaderboard-widget--empty">
        <div className="leaderboard-widget__header">
          <h3 className="leaderboard-widget__title">{title}</h3>
        </div>
        <div className="leaderboard-widget__content">
          <p>No data available</p>
        </div>
      </div>
    );
  }

  return (
    <div className="leaderboard-widget">
      <div className="leaderboard-widget__header">
        <h3 className="leaderboard-widget__title">{title}</h3>
        {config?.dateRange && (
          <span className="leaderboard-widget__period">{config.dateRange}</span>
        )}
      </div>

      <div className="leaderboard-widget__content">
        <ul className="leaderboard-widget__list">
          {displayEntries.map((entry) => {
            const progressWidth = (entry.value / maxValue) * 100;

            return (
              <li
                key={entry.id}
                className={`leaderboard-widget__entry ${
                  onEntryClick ? 'leaderboard-widget__entry--clickable' : ''
                }`}
                onClick={onEntryClick ? () => onEntryClick(entry) : undefined}
              >
                <div className="leaderboard-widget__rank">
                  {getRankBadge(entry.rank)}
                </div>

                <Avatar
                  name={entry.name}
                  avatarUrl={entry.avatarUrl}
                />

                <div className="leaderboard-widget__info">
                  <span className="leaderboard-widget__name">{entry.name}</span>
                  {entry.subtitle && (
                    <span className="leaderboard-widget__subtitle">{entry.subtitle}</span>
                  )}
                  <div className="leaderboard-widget__progress">
                    <div
                      className="leaderboard-widget__progress-bar"
                      style={{ width: `${progressWidth}%` }}
                    />
                  </div>
                </div>

                <div className="leaderboard-widget__value">
                  {formatValue(entry.value, format, currency)}
                </div>
              </li>
            );
          })}
        </ul>
      </div>

      {entries.length > limit && (
        <div className="leaderboard-widget__footer">
          <span className="leaderboard-widget__more">
            +{entries.length - limit} more
          </span>
        </div>
      )}
    </div>
  );
}

export default LeaderboardWidget;
