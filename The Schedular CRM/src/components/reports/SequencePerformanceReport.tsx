/**
 * SequencePerformanceReport Component
 * Report component for sequence performance with filters, table view, and export.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import {
  getSequenceAnalyticsService,
  type SequenceMetrics,
  type DateRange,
} from '../../services/sequence-analytics-service';
import { getSequenceRepository } from '../../data/repositories/sequence-repository';
import type { Sequence, SequenceStatus } from '../../types/sequences';
import './reports.css';

// ============================================
// Types
// ============================================

export interface SequencePerformanceReportProps {
  onExport?: () => void;
}

interface FilterState {
  sequenceId: string; // 'all' or specific ID
  status: SequenceStatus | 'all';
  startDate: string;
  endDate: string;
}

type SortField =
  | 'sequenceName'
  | 'totalEnrolled'
  | 'completionRate'
  | 'replyRate'
  | 'openRate'
  | 'meetingBookingRate';

type SortDirection = 'asc' | 'desc';

// ============================================
// Constants
// ============================================

const DEFAULT_FILTERS: FilterState = {
  sequenceId: 'all',
  status: 'all',
  startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  endDate: new Date().toISOString().split('T')[0],
};

// ============================================
// Helper Functions
// ============================================

function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}

function formatNumber(value: number): string {
  return value.toLocaleString();
}

function formatDays(days: number): string {
  if (days < 1) {
    const hours = Math.round(days * 24);
    return `${hours}h`;
  }
  return `${days.toFixed(1)}d`;
}

// ============================================
// Component
// ============================================

export function SequencePerformanceReport({ onExport }: SequencePerformanceReportProps) {
  const navigate = useNavigate();
  const { crmUser, businessId } = useAuth();

  const [sequences, setSequences] = useState<Sequence[]>([]);
  const [metricsData, setMetricsData] = useState<SequenceMetrics[]>([]);
  const [filters, setFilters] = useState<FilterState>(DEFAULT_FILTERS);
  const [sortField, setSortField] = useState<SortField>('totalEnrolled');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const securityContext = useMemo(() => {
    if (!crmUser || !businessId) return null;
    const teamIds = sanitizeTeamIds(crmUser.teamIds || []);
    const managedTeamIds = sanitizeTeamIds(crmUser.managedTeamIds || []);
    return createSecurityContextFromParams(
      businessId,
      crmUser.id,
      crmUser.displayName,
      crmUser.role,
      teamIds,
      managedTeamIds,
      crmUser.managerId
    );
  }, [businessId, crmUser]);

  const dateRange: DateRange | undefined = useMemo(() => {
    if (!filters.startDate || !filters.endDate) return undefined;
    return {
      start: new Date(filters.startDate),
      end: new Date(filters.endDate),
    };
  }, [filters.startDate, filters.endDate]);

  // Load sequences
  useEffect(() => {
    if (!securityContext) return;

    const loadSequences = async () => {
      try {
        const sequenceRepo = getSequenceRepository();
        const result = await sequenceRepo.list(securityContext, {});
        if (result.success && result.data) {
          setSequences(result.data);
        }
      } catch (err) {
        // Ignore - sequences list is optional
      }
    };

    loadSequences();
  }, [securityContext]);

  // Load metrics
  useEffect(() => {
    if (!securityContext) return;

    const loadMetrics = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const sequenceRepo = getSequenceRepository();

        // Get sequences to report on
        let sequencesToReport: Sequence[] = [];

        if (filters.sequenceId === 'all') {
          const result = await sequenceRepo.list(securityContext, {
            status: filters.status === 'all' ? undefined : filters.status,
          });
          if (result.success && result.data) {
            sequencesToReport = result.data;
          }
        } else {
          const result = await sequenceRepo.getById(securityContext, filters.sequenceId);
          if (result.success && result.data) {
            sequencesToReport = [result.data];
          }
        }

        // Calculate metrics for each sequence
        const metrics: SequenceMetrics[] = [];
        for (const seq of sequencesToReport) {
          const seqMetrics = await analyticsService.calculateSequenceMetrics(
            securityContext,
            seq.id,
            dateRange
          );
          if (seqMetrics) {
            metrics.push(seqMetrics);
          }
        }

        setMetricsData(metrics);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load report data');
      } finally {
        setIsLoading(false);
      }
    };

    loadMetrics();
  }, [securityContext, filters.sequenceId, filters.status, dateRange]);

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  const sortedMetrics = useMemo(() => {
    return [...metricsData].sort((a, b) => {
      let aValue: number | string;
      let bValue: number | string;

      if (sortField === 'sequenceName') {
        aValue = a.sequenceName.toLowerCase();
        bValue = b.sequenceName.toLowerCase();
        return sortDirection === 'asc'
          ? aValue.localeCompare(bValue as string)
          : bValue.localeCompare(aValue as string);
      }

      aValue = a[sortField];
      bValue = b[sortField];
      const direction = sortDirection === 'asc' ? 1 : -1;
      return ((aValue as number) - (bValue as number)) * direction;
    });
  }, [metricsData, sortField, sortDirection]);

  const getSortIndicator = (field: SortField) => {
    if (sortField !== field) return null;
    return sortDirection === 'asc' ? ' ↑' : ' ↓';
  };

  const handleExportCSV = useCallback(() => {
    const headers = [
      'Sequence',
      'Enrolled',
      'Active',
      'Completed',
      'Exited',
      'Completion Rate',
      'Emails Sent',
      'Open Rate',
      'Click Rate',
      'Reply Rate',
      'Bounce Rate',
      'Meetings',
      'Meeting Rate',
      'Avg Time to Complete',
    ];

    const rows = sortedMetrics.map((m) => [
      m.sequenceName,
      m.totalEnrolled,
      m.activeEnrollments,
      m.completedCount,
      m.exitedCount,
      formatPercent(m.completionRate),
      m.emailsSent,
      formatPercent(m.openRate),
      formatPercent(m.clickRate),
      formatPercent(m.replyRate),
      formatPercent(m.bounceRate),
      m.meetingsBooked,
      formatPercent(m.meetingBookingRate),
      formatDays(m.avgTimeToComplete),
    ]);

    const csv = [headers, ...rows].map((row) => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `sequence_performance_${filters.startDate}_to_${filters.endDate}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    onExport?.();
  }, [sortedMetrics, filters.startDate, filters.endDate, onExport]);

  // Calculate totals
  const totals = useMemo(() => {
    return {
      totalEnrolled: metricsData.reduce((sum, m) => sum + m.totalEnrolled, 0),
      activeEnrollments: metricsData.reduce((sum, m) => sum + m.activeEnrollments, 0),
      completedCount: metricsData.reduce((sum, m) => sum + m.completedCount, 0),
      exitedCount: metricsData.reduce((sum, m) => sum + m.exitedCount, 0),
      emailsSent: metricsData.reduce((sum, m) => sum + m.emailsSent, 0),
      emailsOpened: metricsData.reduce((sum, m) => sum + m.emailsOpened, 0),
      emailsReplied: metricsData.reduce((sum, m) => sum + m.emailsReplied, 0),
      meetingsBooked: metricsData.reduce((sum, m) => sum + m.meetingsBooked, 0),
    };
  }, [metricsData]);

  if (!securityContext) {
    return (
      <div className="sequence-report">
        <div className="sequence-report__error">
          <p>Please log in to view sequence reports.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="sequence-report">
      <div className="sequence-report__header">
        <h2>Sequence Performance Report</h2>
        <div className="sequence-report__actions">
          <button className="btn btn-secondary" onClick={handleExportCSV} disabled={isLoading}>
            Export CSV
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="sequence-report__filters">
        <div className="sequence-report__filter">
          <label>Sequence</label>
          <select
            value={filters.sequenceId}
            onChange={(e) => setFilters((prev) => ({ ...prev, sequenceId: e.target.value }))}
          >
            <option value="all">All Sequences</option>
            {sequences.map((seq) => (
              <option key={seq.id} value={seq.id}>
                {seq.name}
              </option>
            ))}
          </select>
        </div>

        <div className="sequence-report__filter">
          <label>Status</label>
          <select
            value={filters.status}
            onChange={(e) =>
              setFilters((prev) => ({ ...prev, status: e.target.value as SequenceStatus | 'all' }))
            }
          >
            <option value="all">All Statuses</option>
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="draft">Draft</option>
            <option value="archived">Archived</option>
          </select>
        </div>

        <div className="sequence-report__filter">
          <label>Start Date</label>
          <input
            type="date"
            value={filters.startDate}
            onChange={(e) => setFilters((prev) => ({ ...prev, startDate: e.target.value }))}
          />
        </div>

        <div className="sequence-report__filter">
          <label>End Date</label>
          <input
            type="date"
            value={filters.endDate}
            onChange={(e) => setFilters((prev) => ({ ...prev, endDate: e.target.value }))}
          />
        </div>

        <button
          className="btn btn-link"
          onClick={() => setFilters(DEFAULT_FILTERS)}
        >
          Reset Filters
        </button>
      </div>

      {/* Summary Cards */}
      <div className="sequence-report__summary">
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">{formatNumber(totals.totalEnrolled)}</span>
          <span className="sequence-report__summary-label">Total Enrolled</span>
        </div>
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">{formatNumber(totals.activeEnrollments)}</span>
          <span className="sequence-report__summary-label">Active</span>
        </div>
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">{formatNumber(totals.completedCount)}</span>
          <span className="sequence-report__summary-label">Completed</span>
        </div>
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">{formatNumber(totals.emailsSent)}</span>
          <span className="sequence-report__summary-label">Emails Sent</span>
        </div>
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">
            {totals.emailsSent > 0
              ? formatPercent((totals.emailsReplied / totals.emailsSent) * 100)
              : '0%'}
          </span>
          <span className="sequence-report__summary-label">Reply Rate</span>
        </div>
        <div className="sequence-report__summary-card">
          <span className="sequence-report__summary-value">{formatNumber(totals.meetingsBooked)}</span>
          <span className="sequence-report__summary-label">Meetings</span>
        </div>
      </div>

      {/* Table */}
      {isLoading ? (
        <div className="sequence-report__loading">
          <div className="sequence-report__spinner" />
          <p>Loading report data...</p>
        </div>
      ) : error ? (
        <div className="sequence-report__error">
          <p>Error: {error}</p>
        </div>
      ) : sortedMetrics.length === 0 ? (
        <div className="sequence-report__empty">
          <p>No sequence data found for the selected filters.</p>
        </div>
      ) : (
        <div className="sequence-report__table-container">
          <table className="sequence-report__table">
            <thead>
              <tr>
                <th
                  className="sequence-report__th sequence-report__th--sortable"
                  onClick={() => handleSort('sequenceName')}
                >
                  Sequence{getSortIndicator('sequenceName')}
                </th>
                <th
                  className="sequence-report__th sequence-report__th--sortable sequence-report__th--number"
                  onClick={() => handleSort('totalEnrolled')}
                >
                  Enrolled{getSortIndicator('totalEnrolled')}
                </th>
                <th className="sequence-report__th sequence-report__th--number">Active</th>
                <th
                  className="sequence-report__th sequence-report__th--sortable sequence-report__th--number"
                  onClick={() => handleSort('completionRate')}
                >
                  Completion{getSortIndicator('completionRate')}
                </th>
                <th
                  className="sequence-report__th sequence-report__th--sortable sequence-report__th--number"
                  onClick={() => handleSort('openRate')}
                >
                  Open Rate{getSortIndicator('openRate')}
                </th>
                <th
                  className="sequence-report__th sequence-report__th--sortable sequence-report__th--number"
                  onClick={() => handleSort('replyRate')}
                >
                  Reply Rate{getSortIndicator('replyRate')}
                </th>
                <th
                  className="sequence-report__th sequence-report__th--sortable sequence-report__th--number"
                  onClick={() => handleSort('meetingBookingRate')}
                >
                  Meeting Rate{getSortIndicator('meetingBookingRate')}
                </th>
                <th className="sequence-report__th sequence-report__th--number">Avg Time</th>
                <th className="sequence-report__th">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sortedMetrics.map((m) => (
                <tr key={m.sequenceId} className="sequence-report__row">
                  <td className="sequence-report__cell sequence-report__cell--name">
                    {m.sequenceName}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    {formatNumber(m.totalEnrolled)}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    {formatNumber(m.activeEnrollments)}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    <span
                      className={
                        m.completionRate >= 50
                          ? 'sequence-report__value--success'
                          : m.completionRate >= 25
                          ? 'sequence-report__value--warning'
                          : 'sequence-report__value--danger'
                      }
                    >
                      {formatPercent(m.completionRate)}
                    </span>
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    {formatPercent(m.openRate)}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    <span
                      className={
                        m.replyRate >= 10
                          ? 'sequence-report__value--success'
                          : m.replyRate >= 5
                          ? 'sequence-report__value--warning'
                          : ''
                      }
                    >
                      {formatPercent(m.replyRate)}
                    </span>
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    {formatPercent(m.meetingBookingRate)}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--number">
                    {formatDays(m.avgTimeToComplete)}
                  </td>
                  <td className="sequence-report__cell sequence-report__cell--actions">
                    <button
                      className="btn btn-link"
                      onClick={() => navigate(`/sequences/${m.sequenceId}/analytics`)}
                    >
                      View Details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default SequencePerformanceReport;
