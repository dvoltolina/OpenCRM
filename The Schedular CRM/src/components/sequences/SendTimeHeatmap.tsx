/**
 * SendTimeHeatmap Component
 * Heatmap showing optimal send times based on open/reply rates.
 * X-axis: Hour of day, Y-axis: Day of week
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import {
  getSequenceAnalyticsService,
  type SendTimeAnalysis,
} from '../../services/sequence-analytics-service';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SendTimeHeatmapProps {
  sequenceId?: string;
  securityContext: SecurityContext;
}

type MetricView = 'openRate' | 'replyRate';

// ============================================
// Constants
// ============================================

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const DAYS_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const HOURS = Array.from({ length: 24 }, (_, i) => i);

const BUSINESS_HOURS = { start: 6, end: 22 };

// ============================================
// Helper Functions
// ============================================

function formatHour(hour: number): string {
  if (hour === 0) return '12am';
  if (hour === 12) return '12pm';
  if (hour < 12) return `${hour}am`;
  return `${hour - 12}pm`;
}

function getHeatmapColor(value: number, max: number): string {
  if (value === 0 || max === 0) return 'var(--color-bg-secondary)';

  const intensity = Math.min(value / max, 1);

  if (intensity < 0.2) return 'var(--color-heatmap-1)';
  if (intensity < 0.4) return 'var(--color-heatmap-2)';
  if (intensity < 0.6) return 'var(--color-heatmap-3)';
  if (intensity < 0.8) return 'var(--color-heatmap-4)';
  return 'var(--color-heatmap-5)';
}

function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}

// ============================================
// Component
// ============================================

export function SendTimeHeatmap({ sequenceId, securityContext }: SendTimeHeatmapProps) {
  const [analysis, setAnalysis] = useState<SendTimeAnalysis | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [metricView, setMetricView] = useState<MetricView>('openRate');
  const [hoveredCell, setHoveredCell] = useState<{ day: number; hour: number } | null>(null);

  useEffect(() => {
    const loadAnalysis = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const data = await analyticsService.getOptimalSendTimes(securityContext, sequenceId);
        setAnalysis(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load send time analysis');
      } finally {
        setIsLoading(false);
      }
    };

    loadAnalysis();
  }, [securityContext, sequenceId]);

  // Generate heatmap data (7 days x 24 hours)
  const heatmapData: number[][] = [];
  const maxValue = { current: 0 };

  if (analysis) {
    // Initialize with day and hour data
    for (let day = 0; day < 7; day++) {
      heatmapData[day] = [];
      for (let hour = 0; hour < 24; hour++) {
        // Find matching hour data
        const hourData = analysis.bestHours.find((h) => h.hour === hour);
        const dayData = analysis.bestDays.find((d) => d.day === DAYS[day]);

        // Calculate combined rate (weighted average of day and hour)
        const hourRate = hourData ? hourData[metricView] : 0;
        const dayRate = dayData ? dayData[metricView] : 0;
        const combinedRate = (hourRate + dayRate) / 2;

        heatmapData[day][hour] = combinedRate;
        if (combinedRate > maxValue.current) {
          maxValue.current = combinedRate;
        }
      }
    }
  }

  // Find best times
  const bestTimeSlots: { day: number; hour: number; rate: number }[] = [];
  heatmapData.forEach((dayData, day) => {
    dayData.forEach((rate, hour) => {
      if (rate > 0) {
        bestTimeSlots.push({ day, hour, rate });
      }
    });
  });
  bestTimeSlots.sort((a, b) => b.rate - a.rate);
  const topSlots = bestTimeSlots.slice(0, 5);

  if (isLoading) {
    return (
      <div className="send-time-heatmap">
        <div className="send-time-heatmap__loading">
          <div className="send-time-heatmap__spinner" />
          <p>Analyzing send times...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="send-time-heatmap">
        <div className="send-time-heatmap__error">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="send-time-heatmap">
      <div className="send-time-heatmap__header">
        <div className="send-time-heatmap__title-group">
          <h2>Optimal Send Times</h2>
          <p className="send-time-heatmap__subtitle">
            {sequenceId ? 'Based on this sequence\'s email performance' : 'Based on all sequence email performance'}
          </p>
        </div>
        <div className="send-time-heatmap__controls">
          <label className="send-time-heatmap__toggle">
            <span className={metricView === 'openRate' ? 'send-time-heatmap__toggle--active' : ''}>
              Open Rate
            </span>
            <input
              type="checkbox"
              checked={metricView === 'replyRate'}
              onChange={(e) => setMetricView(e.target.checked ? 'replyRate' : 'openRate')}
            />
            <span className={metricView === 'replyRate' ? 'send-time-heatmap__toggle--active' : ''}>
              Reply Rate
            </span>
          </label>
        </div>
      </div>

      {/* Recommendation */}
      {analysis?.recommendation && (
        <div className="send-time-heatmap__recommendation">
          <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
          </svg>
          <span>{analysis.recommendation}</span>
        </div>
      )}

      {/* Heatmap Grid */}
      <div className="send-time-heatmap__container">
        <div className="send-time-heatmap__grid">
          {/* Hour labels */}
          <div className="send-time-heatmap__hour-labels">
            <div className="send-time-heatmap__corner" />
            {HOURS.filter((h) => h >= BUSINESS_HOURS.start && h < BUSINESS_HOURS.end).map((hour) => (
              <div key={hour} className="send-time-heatmap__hour-label">
                {formatHour(hour)}
              </div>
            ))}
          </div>

          {/* Rows for each day */}
          {DAYS.map((day, dayIndex) => (
            <div key={day} className="send-time-heatmap__row">
              <div className="send-time-heatmap__day-label">{DAYS_SHORT[dayIndex]}</div>
              {HOURS.filter((h) => h >= BUSINESS_HOURS.start && h < BUSINESS_HOURS.end).map((hour) => {
                const value = heatmapData[dayIndex]?.[hour] || 0;
                const isHovered = hoveredCell?.day === dayIndex && hoveredCell?.hour === hour;
                const isTop = topSlots.some((s) => s.day === dayIndex && s.hour === hour);

                return (
                  <div
                    key={hour}
                    className={`send-time-heatmap__cell ${isHovered ? 'send-time-heatmap__cell--hovered' : ''} ${
                      isTop ? 'send-time-heatmap__cell--top' : ''
                    }`}
                    style={{ backgroundColor: getHeatmapColor(value, maxValue.current) }}
                    onMouseEnter={() => setHoveredCell({ day: dayIndex, hour })}
                    onMouseLeave={() => setHoveredCell(null)}
                    title={`${day} ${formatHour(hour)}: ${formatPercent(value)} ${metricView === 'openRate' ? 'open rate' : 'reply rate'}`}
                  >
                    {isTop && (
                      <span className="send-time-heatmap__star">★</span>
                    )}
                  </div>
                );
              })}
            </div>
          ))}
        </div>

        {/* Tooltip */}
        {hoveredCell && (
          <div className="send-time-heatmap__tooltip">
            <strong>{DAYS[hoveredCell.day]} at {formatHour(hoveredCell.hour)}</strong>
            <div className="send-time-heatmap__tooltip-metrics">
              <span>
                {metricView === 'openRate' ? 'Open Rate' : 'Reply Rate'}:{' '}
                {formatPercent(heatmapData[hoveredCell.day]?.[hoveredCell.hour] || 0)}
              </span>
            </div>
          </div>
        )}
      </div>

      {/* Legend */}
      <div className="send-time-heatmap__legend">
        <span className="send-time-heatmap__legend-label">Performance:</span>
        <div className="send-time-heatmap__legend-scale">
          <div className="send-time-heatmap__legend-item">
            <div
              className="send-time-heatmap__legend-color"
              style={{ backgroundColor: 'var(--color-bg-secondary)' }}
            />
            <span>No data</span>
          </div>
          <div className="send-time-heatmap__legend-item">
            <div
              className="send-time-heatmap__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-1)' }}
            />
            <span>Low</span>
          </div>
          <div className="send-time-heatmap__legend-item">
            <div
              className="send-time-heatmap__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-3)' }}
            />
            <span>Medium</span>
          </div>
          <div className="send-time-heatmap__legend-item">
            <div
              className="send-time-heatmap__legend-color"
              style={{ backgroundColor: 'var(--color-heatmap-5)' }}
            />
            <span>High</span>
          </div>
          <div className="send-time-heatmap__legend-item">
            <span className="send-time-heatmap__legend-star">★</span>
            <span>Top 5</span>
          </div>
        </div>
      </div>

      {/* Best Times Summary */}
      <div className="send-time-heatmap__summary">
        <h3>Best Times to Send</h3>
        {topSlots.length === 0 ? (
          <p className="send-time-heatmap__no-data">
            Not enough data to determine optimal send times. More email sends are needed.
          </p>
        ) : (
          <div className="send-time-heatmap__best-times">
            {topSlots.map((slot, index) => (
              <div key={`${slot.day}-${slot.hour}`} className="send-time-heatmap__best-time">
                <span className="send-time-heatmap__best-time-rank">#{index + 1}</span>
                <span className="send-time-heatmap__best-time-slot">
                  {DAYS[slot.day]} at {formatHour(slot.hour)}
                </span>
                <span className="send-time-heatmap__best-time-rate">
                  {formatPercent(slot.rate)} {metricView === 'openRate' ? 'open' : 'reply'}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Day Performance */}
      {analysis && analysis.bestDays.length > 0 && (
        <div className="send-time-heatmap__day-summary">
          <h3>Performance by Day</h3>
          <div className="send-time-heatmap__day-bars">
            {analysis.bestDays.map((dayData) => {
              const rate = dayData[metricView];
              const maxRate = Math.max(...analysis.bestDays.map((d) => d[metricView]), 1);
              const widthPercent = (rate / maxRate) * 100;

              return (
                <div key={dayData.day} className="send-time-heatmap__day-bar-row">
                  <span className="send-time-heatmap__day-bar-label">{dayData.day}</span>
                  <div className="send-time-heatmap__day-bar-container">
                    <div
                      className="send-time-heatmap__day-bar"
                      style={{ width: `${Math.max(widthPercent, 2)}%` }}
                    />
                  </div>
                  <span className="send-time-heatmap__day-bar-value">{formatPercent(rate)}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Tips */}
      <div className="send-time-heatmap__tips">
        <h3>Tips for Better Engagement</h3>
        <ul className="send-time-heatmap__tips-list">
          <li>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
            </svg>
            Schedule emails during your recipient's business hours
          </li>
          <li>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
            </svg>
            Tuesday through Thursday typically see higher engagement
          </li>
          <li>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
            </svg>
            Avoid early morning and late night sends for B2B
          </li>
          <li>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
              <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
            </svg>
            Consider time zones when sending to different regions
          </li>
        </ul>
      </div>
    </div>
  );
}

export default SendTimeHeatmap;
