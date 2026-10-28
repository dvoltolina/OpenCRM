/**
 * TeamLeaderboard Component
 * Shows sales rep rankings by revenue (Empire View)
 */

import { useMemo } from 'react';

export interface LeaderboardEntry {
  id: string;
  name: string;
  wonCount: number;
  wonValue: number;
  openCount: number;
  openValue: number;
  rank?: number;
}

export interface TeamLeaderboardProps {
  /** Leaderboard entries */
  entries: LeaderboardEntry[];
  /** Maximum entries to show */
  limit?: number;
  /** Title for the leaderboard */
  title?: string;
  /** Currency code */
  currency?: string;
  /** Called when an entry is clicked */
  onEntryClick?: (entry: LeaderboardEntry) => void;
}

function formatCurrency(cents: number, currency: string = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(
    cents / 100
  );
}

export function TeamLeaderboard({
  entries,
  limit = 10,
  title = 'Sales Leaderboard',
  currency = 'USD',
  onEntryClick,
}: TeamLeaderboardProps) {
  const rankedEntries = useMemo(() => {
    return entries
      .sort((a, b) => b.wonValue - a.wonValue)
      .slice(0, limit)
      .map((entry, index) => ({ ...entry, rank: index + 1 }));
  }, [entries, limit]);

  const getMedalEmoji = (rank: number) => {
    if (rank === 1) return '🥇';
    if (rank === 2) return '🥈';
    if (rank === 3) return '🥉';
    return `#${rank}`;
  };

  if (rankedEntries.length === 0) {
    return (
      <div className="team-leaderboard team-leaderboard--empty">
        <h3 className="team-leaderboard__title">{title}</h3>
        <p className="empty-message">No sales data yet this period</p>
      </div>
    );
  }

  return (
    <div className="team-leaderboard">
      <h3 className="team-leaderboard__title">{title}</h3>
      <div className="team-leaderboard__list">
        {rankedEntries.map((entry) => (
          <button
            key={entry.id}
            className={`team-leaderboard__entry ${entry.rank && entry.rank <= 3 ? 'team-leaderboard__entry--top' : ''}`}
            onClick={() => onEntryClick?.(entry)}
            type="button"
          >
            <span className="team-leaderboard__rank">
              {getMedalEmoji(entry.rank || 0)}
            </span>
            <div className="team-leaderboard__info">
              <span className="team-leaderboard__name">{entry.name}</span>
              <span className="team-leaderboard__stats">
                {entry.wonCount} deal{entry.wonCount !== 1 ? 's' : ''} won
              </span>
            </div>
            <div className="team-leaderboard__value">
              <span className="team-leaderboard__revenue">
                {formatCurrency(entry.wonValue, currency)}
              </span>
              {entry.openValue > 0 && (
                <span className="team-leaderboard__pipeline">
                  +{formatCurrency(entry.openValue, currency)} pipeline
                </span>
              )}
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

export default TeamLeaderboard;
