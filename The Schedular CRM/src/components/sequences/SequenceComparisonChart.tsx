/**
 * SequenceComparisonChart Component
 * Compare multiple sequences side by side on key metrics.
 * Bar chart or radar chart visualization with winner highlighting.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect, useMemo } from 'react';
import type { SecurityContext } from '../../data/repositories/repository-types';
import {
  getSequenceAnalyticsService,
  type SequenceComparison,
  type DateRange,
} from '../../services/sequence-analytics-service';
import { getSequenceRepository } from '../../data/repositories/sequence-repository';
import type { Sequence } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

export interface SequenceComparisonChartProps {
  securityContext: SecurityContext;
  dateRange?: DateRange;
  initialSequenceIds?: string[];
  maxSequences?: number;
}

type MetricKey = 'completionRate' | 'replyRate' | 'meetingRate' | 'enrollmentCount' | 'avgTimeToComplete';

interface MetricConfig {
  key: MetricKey;
  label: string;
  format: (value: number) => string;
  higherIsBetter: boolean;
  color: string;
}

// ============================================
// Constants
// ============================================

const METRIC_CONFIGS: MetricConfig[] = [
  {
    key: 'completionRate',
    label: 'Completion Rate',
    format: (v) => `${v.toFixed(1)}%`,
    higherIsBetter: true,
    color: 'var(--color-primary)',
  },
  {
    key: 'replyRate',
    label: 'Reply Rate',
    format: (v) => `${v.toFixed(1)}%`,
    higherIsBetter: true,
    color: 'var(--color-success)',
  },
  {
    key: 'meetingRate',
    label: 'Meeting Rate',
    format: (v) => `${v.toFixed(1)}%`,
    higherIsBetter: true,
    color: 'var(--color-warning)',
  },
  {
    key: 'enrollmentCount',
    label: 'Enrollments',
    format: (v) => v.toString(),
    higherIsBetter: true,
    color: 'var(--color-info)',
  },
  {
    key: 'avgTimeToComplete',
    label: 'Avg Time (days)',
    format: (v) => v.toFixed(1),
    higherIsBetter: false,
    color: 'var(--color-secondary)',
  },
];

const SEQUENCE_COLORS = [
  'var(--color-chart-1)',
  'var(--color-chart-2)',
  'var(--color-chart-3)',
  'var(--color-chart-4)',
  'var(--color-chart-5)',
];

// ============================================
// Component
// ============================================

export function SequenceComparisonChart({
  securityContext,
  dateRange,
  initialSequenceIds = [],
  maxSequences = 5,
}: SequenceComparisonChartProps) {
  const [sequences, setSequences] = useState<Sequence[]>([]);
  const [selectedIds, setSelectedIds] = useState<string[]>(initialSequenceIds);
  const [comparisons, setComparisons] = useState<SequenceComparison[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isComparing, setIsComparing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load available sequences
  useEffect(() => {
    const loadSequences = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const sequenceRepo = getSequenceRepository();
        const result = await sequenceRepo.list(securityContext, {});
        if (result.success && result.data) {
          setSequences(result.data);
          // Auto-select first few if none selected
          if (selectedIds.length === 0 && result.data.length > 0) {
            setSelectedIds(result.data.slice(0, Math.min(3, result.data.length)).map((s) => s.id));
          }
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load sequences');
      } finally {
        setIsLoading(false);
      }
    };

    loadSequences();
  }, [securityContext, selectedIds.length]);

  // Load comparison data when selection changes
  useEffect(() => {
    if (selectedIds.length === 0) {
      setComparisons([]);
      return;
    }

    const loadComparisons = async () => {
      setIsComparing(true);
      try {
        const analyticsService = getSequenceAnalyticsService();
        const data = await analyticsService.compareSequences(
          securityContext,
          selectedIds,
          dateRange
        );
        setComparisons(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to compare sequences');
      } finally {
        setIsComparing(false);
      }
    };

    loadComparisons();
  }, [securityContext, selectedIds, dateRange]);

  const handleSequenceToggle = (sequenceId: string) => {
    setSelectedIds((prev) => {
      if (prev.includes(sequenceId)) {
        return prev.filter((id) => id !== sequenceId);
      }
      if (prev.length >= maxSequences) {
        return prev; // Max reached
      }
      return [...prev, sequenceId];
    });
  };

  // Find winners for each metric
  const winners = useMemo(() => {
    const result: Record<MetricKey, string | null> = {
      completionRate: null,
      replyRate: null,
      meetingRate: null,
      enrollmentCount: null,
      avgTimeToComplete: null,
    };

    if (comparisons.length < 2) return result;

    METRIC_CONFIGS.forEach((metric) => {
      const sorted = [...comparisons].sort((a, b) => {
        const diff = a[metric.key] - b[metric.key];
        return metric.higherIsBetter ? -diff : diff;
      });
      if (sorted[0]) {
        result[metric.key] = sorted[0].sequenceId;
      }
    });

    return result;
  }, [comparisons]);

  // Calculate max values for bar scaling
  const maxValues = useMemo(() => {
    const result: Record<MetricKey, number> = {
      completionRate: 100,
      replyRate: Math.max(...comparisons.map((c) => c.replyRate), 1),
      meetingRate: Math.max(...comparisons.map((c) => c.meetingRate), 1),
      enrollmentCount: Math.max(...comparisons.map((c) => c.enrollmentCount), 1),
      avgTimeToComplete: Math.max(...comparisons.map((c) => c.avgTimeToComplete), 1),
    };
    return result;
  }, [comparisons]);

  if (isLoading) {
    return (
      <div className="sequence-comparison">
        <div className="sequence-comparison__loading">
          <div className="sequence-comparison__spinner" />
          <p>Loading sequences...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="sequence-comparison">
        <div className="sequence-comparison__error">
          <p>Error: {error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="sequence-comparison">
      <div className="sequence-comparison__header">
        <h2>Sequence Comparison</h2>
        <p className="sequence-comparison__subtitle">
          Select up to {maxSequences} sequences to compare their performance metrics.
        </p>
      </div>

      {/* Sequence Selector */}
      <div className="sequence-comparison__selector">
        <div className="sequence-comparison__selector-label">
          Select sequences ({selectedIds.length}/{maxSequences}):
        </div>
        <div className="sequence-comparison__sequence-list">
          {sequences.map((seq) => {
            const isSelected = selectedIds.includes(seq.id);
            const colorIndex = selectedIds.indexOf(seq.id);

            return (
              <label
                key={seq.id}
                className={`sequence-comparison__sequence-item ${
                  isSelected ? 'sequence-comparison__sequence-item--selected' : ''
                }`}
                style={
                  isSelected
                    ? { borderColor: SEQUENCE_COLORS[colorIndex] || SEQUENCE_COLORS[0] }
                    : undefined
                }
              >
                <input
                  type="checkbox"
                  checked={isSelected}
                  onChange={() => handleSequenceToggle(seq.id)}
                  disabled={!isSelected && selectedIds.length >= maxSequences}
                />
                {isSelected && (
                  <span
                    className="sequence-comparison__color-dot"
                    style={{ backgroundColor: SEQUENCE_COLORS[colorIndex] || SEQUENCE_COLORS[0] }}
                  />
                )}
                <span className="sequence-comparison__sequence-name">{seq.name}</span>
                <span
                  className={`sequence-comparison__sequence-status sequence-comparison__sequence-status--${seq.status}`}
                >
                  {seq.status}
                </span>
              </label>
            );
          })}
        </div>
      </div>

      {/* Comparison Charts */}
      {isComparing ? (
        <div className="sequence-comparison__loading">
          <div className="sequence-comparison__spinner" />
          <p>Comparing sequences...</p>
        </div>
      ) : comparisons.length === 0 ? (
        <div className="sequence-comparison__empty">
          <p>Select at least one sequence to view comparison</p>
        </div>
      ) : (
        <div className="sequence-comparison__charts">
          {/* Legend */}
          <div className="sequence-comparison__legend">
            {comparisons.map((comp, index) => (
              <div key={comp.sequenceId} className="sequence-comparison__legend-item">
                <span
                  className="sequence-comparison__legend-color"
                  style={{ backgroundColor: SEQUENCE_COLORS[index] || SEQUENCE_COLORS[0] }}
                />
                <span className="sequence-comparison__legend-name">{comp.sequenceName}</span>
              </div>
            ))}
          </div>

          {/* Bar Charts for Each Metric */}
          {METRIC_CONFIGS.map((metric) => {
            const winnerId = winners[metric.key];

            return (
              <div key={metric.key} className="sequence-comparison__metric">
                <div className="sequence-comparison__metric-header">
                  <span className="sequence-comparison__metric-label">{metric.label}</span>
                  {winnerId && comparisons.length > 1 && (
                    <span className="sequence-comparison__winner">
                      <svg viewBox="0 0 24 24" width="14" height="14" fill="currentColor">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                      </svg>
                      {comparisons.find((c) => c.sequenceId === winnerId)?.sequenceName}
                    </span>
                  )}
                </div>
                <div className="sequence-comparison__bars">
                  {comparisons.map((comp, index) => {
                    const value = comp[metric.key];
                    const maxValue = maxValues[metric.key];
                    const widthPercent = (value / maxValue) * 100;
                    const isWinner = comp.sequenceId === winnerId;

                    return (
                      <div
                        key={comp.sequenceId}
                        className={`sequence-comparison__bar-row ${
                          isWinner ? 'sequence-comparison__bar-row--winner' : ''
                        }`}
                      >
                        <span className="sequence-comparison__bar-name" title={comp.sequenceName}>
                          {comp.sequenceName}
                        </span>
                        <div className="sequence-comparison__bar-container">
                          <div
                            className="sequence-comparison__bar"
                            style={{
                              width: `${Math.max(widthPercent, 2)}%`,
                              backgroundColor: SEQUENCE_COLORS[index] || SEQUENCE_COLORS[0],
                            }}
                          />
                        </div>
                        <span className="sequence-comparison__bar-value">
                          {metric.format(value)}
                          {isWinner && comparisons.length > 1 && (
                            <span className="sequence-comparison__trophy">
                              <svg viewBox="0 0 24 24" width="12" height="12" fill="currentColor">
                                <path d="M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94.63 1.5 1.98 2.63 3.61 2.96V19H7v2h10v-2h-4v-3.1c1.63-.33 2.98-1.46 3.61-2.96C19.08 12.63 21 10.55 21 8V7c0-1.1-.9-2-2-2zM5 8V7h2v3.82C5.84 10.4 5 9.3 5 8zm14 0c0 1.3-.84 2.4-2 2.82V7h2v1z" />
                              </svg>
                            </span>
                          )}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Summary Table */}
      {comparisons.length > 0 && (
        <div className="sequence-comparison__table-container">
          <h3>Summary Table</h3>
          <table className="sequence-comparison__table">
            <thead>
              <tr>
                <th>Sequence</th>
                {METRIC_CONFIGS.map((m) => (
                  <th key={m.key}>{m.label}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {comparisons.map((comp, index) => (
                <tr key={comp.sequenceId}>
                  <td>
                    <span
                      className="sequence-comparison__table-color"
                      style={{ backgroundColor: SEQUENCE_COLORS[index] || SEQUENCE_COLORS[0] }}
                    />
                    {comp.sequenceName}
                  </td>
                  {METRIC_CONFIGS.map((m) => {
                    const isWinner = winners[m.key] === comp.sequenceId && comparisons.length > 1;
                    return (
                      <td
                        key={m.key}
                        className={isWinner ? 'sequence-comparison__cell--winner' : ''}
                      >
                        {m.format(comp[m.key])}
                        {isWinner && ' ★'}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Export */}
      {comparisons.length > 0 && (
        <div className="sequence-comparison__actions">
          <button
            className="btn btn-secondary"
            onClick={() => {
              const headers = ['Sequence', ...METRIC_CONFIGS.map((m) => m.label)];
              const rows = comparisons.map((comp) => [
                comp.sequenceName,
                ...METRIC_CONFIGS.map((m) => m.format(comp[m.key])),
              ]);
              const csv = [headers, ...rows].map((row) => row.join(',')).join('\n');
              const blob = new Blob([csv], { type: 'text/csv' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = 'sequence_comparison.csv';
              a.click();
              URL.revokeObjectURL(url);
            }}
          >
            Export Comparison
          </button>
        </div>
      )}
    </div>
  );
}

export default SequenceComparisonChart;
