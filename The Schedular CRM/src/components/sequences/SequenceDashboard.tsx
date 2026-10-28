/**
 * SequenceDashboard Component
 * Overview dashboard for all sequences showing summary metrics,
 * top performers, recent activity, and alerts.
 *
 * Phase 5 Implementation - Sequences Analytics & Reporting
 */

import { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { createSecurityContextFromParams, sanitizeTeamIds } from '../../lib/security-context';
import {
  getSequenceAnalyticsService,
  type SequenceComparison,
} from '../../services/sequence-analytics-service';
import { getSequenceRepository } from '../../data/repositories/sequence-repository';
import './sequences.css';

// ============================================
// Types
// ============================================

interface DashboardSummary {
  totalSequences: number;
  activeSequences: number;
  totalEnrollments: number;
  activeEnrollments: number;
  emailsSentLast30Days: number;
  overallReplyRate: number;
}


interface SequenceAlert {
  id: string;
  type: 'high_bounce' | 'no_activity' | 'low_completion';
  sequenceId: string;
  sequenceName: string;
  message: string;
  severity: 'warning' | 'error';
}

// ============================================
// Component
// ============================================

export function SequenceDashboard() {
  const navigate = useNavigate();
  const { crmUser, businessId } = useAuth();

  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [topPerformers, setTopPerformers] = useState<SequenceComparison[]>([]);
  const [alerts, setAlerts] = useState<SequenceAlert[]>([]);
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

  useEffect(() => {
    if (!securityContext) return;

    const loadDashboard = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const analyticsService = getSequenceAnalyticsService();
        const sequenceRepo = getSequenceRepository();

        // Load summary metrics
        const summaryData = await analyticsService.getDashboardSummary(securityContext);
        setSummary(summaryData);

        // Load top performers
        const performers = await analyticsService.getTopPerformers(securityContext, 5, 'replyRate');
        setTopPerformers(performers);

        // Check for alerts
        const sequencesResult = await sequenceRepo.list(securityContext, { status: 'active' });
        if (sequencesResult.success && sequencesResult.data) {
          const alertsList: SequenceAlert[] = [];

          for (const seq of sequencesResult.data) {
            // Check for high bounce rate
            if (seq.stats.totalEnrolled > 10 && (seq.stats.openRate || 0) < 20) {
              alertsList.push({
                id: `bounce-${seq.id}`,
                type: 'high_bounce',
                sequenceId: seq.id,
                sequenceName: seq.name,
                message: `Low open rate: ${(seq.stats.openRate || 0).toFixed(1)}%`,
                severity: 'warning',
              });
            }

            // Check for no recent activity
            if (seq.stats.activeEnrollments === 0 && seq.stats.totalEnrolled > 0) {
              alertsList.push({
                id: `inactive-${seq.id}`,
                type: 'no_activity',
                sequenceId: seq.id,
                sequenceName: seq.name,
                message: 'No active enrollments',
                severity: 'warning',
              });
            }

            // Check for low completion rate
            const completed = seq.stats.completedCount || 0;
            const exited = seq.stats.exitedCount || 0;
            const completionRate = completed + exited > 0 ? (completed / (completed + exited)) * 100 : 0;
            if (seq.stats.totalEnrolled > 20 && completionRate < 30) {
              alertsList.push({
                id: `completion-${seq.id}`,
                type: 'low_completion',
                sequenceId: seq.id,
                sequenceName: seq.name,
                message: `Low completion rate: ${completionRate.toFixed(1)}%`,
                severity: 'warning',
              });
            }
          }

          setAlerts(alertsList.slice(0, 5)); // Limit to 5 alerts
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load dashboard');
      } finally {
        setIsLoading(false);
      }
    };

    loadDashboard();
  }, [securityContext]);

  const handleSequenceClick = (sequenceId: string) => {
    navigate(`/sequences/${sequenceId}/analytics`);
  };

  if (isLoading) {
    return (
      <div className="sequence-dashboard">
        <div className="sequence-dashboard__loading">
          <div className="sequence-dashboard__spinner" />
          <p>Loading dashboard...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="sequence-dashboard">
        <div className="sequence-dashboard__error">
          <p>Error: {error}</p>
          <button className="btn btn-primary" onClick={() => window.location.reload()}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="sequence-dashboard">
      <header className="sequence-dashboard__header">
        <h1>Sequence Dashboard</h1>
        <div className="sequence-dashboard__actions">
          <button className="btn btn-primary" onClick={() => navigate('/sequences/new')}>
            Create Sequence
          </button>
        </div>
      </header>

      {/* Summary Cards */}
      <section className="sequence-dashboard__summary">
        <div className="sequence-dashboard__card">
          <div className="sequence-dashboard__card-icon sequence-dashboard__card-icon--sequences">
            <svg viewBox="0 0 24 24" fill="currentColor" width="24" height="24">
              <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z" />
            </svg>
          </div>
          <div className="sequence-dashboard__card-content">
            <span className="sequence-dashboard__card-value">{summary?.activeSequences || 0}</span>
            <span className="sequence-dashboard__card-label">Active Sequences</span>
            <span className="sequence-dashboard__card-sublabel">
              {summary?.totalSequences || 0} total
            </span>
          </div>
        </div>

        <div className="sequence-dashboard__card">
          <div className="sequence-dashboard__card-icon sequence-dashboard__card-icon--enrollments">
            <svg viewBox="0 0 24 24" fill="currentColor" width="24" height="24">
              <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
            </svg>
          </div>
          <div className="sequence-dashboard__card-content">
            <span className="sequence-dashboard__card-value">{summary?.activeEnrollments || 0}</span>
            <span className="sequence-dashboard__card-label">Active Enrollments</span>
            <span className="sequence-dashboard__card-sublabel">
              {summary?.totalEnrollments || 0} total
            </span>
          </div>
        </div>

        <div className="sequence-dashboard__card">
          <div className="sequence-dashboard__card-icon sequence-dashboard__card-icon--emails">
            <svg viewBox="0 0 24 24" fill="currentColor" width="24" height="24">
              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
            </svg>
          </div>
          <div className="sequence-dashboard__card-content">
            <span className="sequence-dashboard__card-value">
              {summary?.emailsSentLast30Days || 0}
            </span>
            <span className="sequence-dashboard__card-label">Emails Sent</span>
            <span className="sequence-dashboard__card-sublabel">Last 30 days</span>
          </div>
        </div>

        <div className="sequence-dashboard__card">
          <div className="sequence-dashboard__card-icon sequence-dashboard__card-icon--replies">
            <svg viewBox="0 0 24 24" fill="currentColor" width="24" height="24">
              <path d="M10 9V5l-7 7 7 7v-4.1c5 0 8.5 1.6 11 5.1-1-5-4-10-11-11z" />
            </svg>
          </div>
          <div className="sequence-dashboard__card-content">
            <span className="sequence-dashboard__card-value">
              {(summary?.overallReplyRate || 0).toFixed(1)}%
            </span>
            <span className="sequence-dashboard__card-label">Reply Rate</span>
            <span className="sequence-dashboard__card-sublabel">Overall average</span>
          </div>
        </div>
      </section>

      <div className="sequence-dashboard__grid">
        {/* Top Performers */}
        <section className="sequence-dashboard__section sequence-dashboard__section--performers">
          <h2>Top Performing Sequences</h2>
          {topPerformers.length === 0 ? (
            <div className="sequence-dashboard__empty">
              <p>No sequence data available yet</p>
            </div>
          ) : (
            <table className="sequence-dashboard__table">
              <thead>
                <tr>
                  <th>Sequence</th>
                  <th>Completion</th>
                  <th>Reply Rate</th>
                  <th>Enrollments</th>
                  <th>Trend</th>
                </tr>
              </thead>
              <tbody>
                {topPerformers.map((seq) => (
                  <tr
                    key={seq.sequenceId}
                    onClick={() => handleSequenceClick(seq.sequenceId)}
                    className="sequence-dashboard__table-row--clickable"
                  >
                    <td className="sequence-dashboard__cell--name">{seq.sequenceName}</td>
                    <td>
                      <span
                        className={`sequence-dashboard__metric ${
                          seq.completionRate >= 50
                            ? 'sequence-dashboard__metric--success'
                            : seq.completionRate >= 25
                            ? 'sequence-dashboard__metric--warning'
                            : 'sequence-dashboard__metric--danger'
                        }`}
                      >
                        {seq.completionRate.toFixed(1)}%
                      </span>
                    </td>
                    <td>
                      <span
                        className={`sequence-dashboard__metric ${
                          seq.replyRate >= 10
                            ? 'sequence-dashboard__metric--success'
                            : seq.replyRate >= 5
                            ? 'sequence-dashboard__metric--warning'
                            : ''
                        }`}
                      >
                        {seq.replyRate.toFixed(1)}%
                      </span>
                    </td>
                    <td>{seq.enrollmentCount}</td>
                    <td>
                      <span className="sequence-dashboard__trend sequence-dashboard__trend--up">
                        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor">
                          <path d="M7 14l5-5 5 5z" />
                        </svg>
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <div className="sequence-dashboard__section-footer">
            <button className="btn btn-link" onClick={() => navigate('/sequences')}>
              View all sequences
            </button>
          </div>
        </section>

        {/* Alerts */}
        <section className="sequence-dashboard__section sequence-dashboard__section--alerts">
          <h2>Alerts</h2>
          {alerts.length === 0 ? (
            <div className="sequence-dashboard__empty sequence-dashboard__empty--success">
              <svg viewBox="0 0 24 24" width="32" height="32" fill="currentColor">
                <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
              </svg>
              <p>All sequences are performing well</p>
            </div>
          ) : (
            <ul className="sequence-dashboard__alerts-list">
              {alerts.map((alert) => (
                <li
                  key={alert.id}
                  className={`sequence-dashboard__alert sequence-dashboard__alert--${alert.severity}`}
                  onClick={() => handleSequenceClick(alert.sequenceId)}
                >
                  <div className="sequence-dashboard__alert-icon">
                    {alert.severity === 'error' ? (
                      <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
                      </svg>
                    ) : (
                      <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                        <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z" />
                      </svg>
                    )}
                  </div>
                  <div className="sequence-dashboard__alert-content">
                    <strong>{alert.sequenceName}</strong>
                    <span>{alert.message}</span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>

      {/* Quick Actions */}
      <section className="sequence-dashboard__quick-actions">
        <h2>Quick Actions</h2>
        <div className="sequence-dashboard__action-buttons">
          <button className="btn btn-secondary" onClick={() => navigate('/sequences')}>
            Manage Sequences
          </button>
          <button className="btn btn-secondary" onClick={() => navigate('/reports?tab=sequences')}>
            View Reports
          </button>
          <button className="btn btn-secondary" onClick={() => navigate('/sequences/compare')}>
            Compare Sequences
          </button>
        </div>
      </section>
    </div>
  );
}

export default SequenceDashboard;
