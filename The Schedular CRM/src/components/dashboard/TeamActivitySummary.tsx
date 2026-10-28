/**
 * TeamActivitySummary Component
 * Shows team activity metrics (calls/emails today) for Manager View
 */

import type { SalesActivity } from '../../types/models';
import { useMemo } from 'react';

export interface TeamActivitySummaryProps {
  /** Activities from the team */
  activities: SalesActivity[];
  /** Title for the section */
  title?: string;
}

interface ActivityCount {
  assigneeId: string;
  assigneeName: string;
  calls: number;
  emails: number;
  meetings: number;
  tasks: number;
  total: number;
}

export function TeamActivitySummary({
  activities,
  title = "Team Activity Today",
}: TeamActivitySummaryProps) {
  // Get today's start
  const todayStart = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return today;
  }, []);

  // Filter to today's activities and count by type per rep
  const activityByRep = useMemo(() => {
    const todayActivities = activities.filter(
      (a) => a.createdAt && a.createdAt >= todayStart
    );

    const repMap = new Map<string, ActivityCount>();

    todayActivities.forEach((activity) => {
      const assigneeId = activity.assigneeId || activity.createdById || 'unknown';
      const assigneeName = activity.assigneeName || activity.createdByName || 'Unknown';

      const existing = repMap.get(assigneeId) || {
        assigneeId,
        assigneeName,
        calls: 0,
        emails: 0,
        meetings: 0,
        tasks: 0,
        total: 0,
      };

      if (activity.type === 'call') existing.calls++;
      else if (activity.type === 'email') existing.emails++;
      else if (activity.type === 'meeting') existing.meetings++;
      else existing.tasks++;

      existing.total++;
      repMap.set(assigneeId, existing);
    });

    return Array.from(repMap.values()).sort((a, b) => b.total - a.total);
  }, [activities, todayStart]);

  // Calculate totals
  const totals = useMemo(() => {
    return activityByRep.reduce(
      (acc, rep) => ({
        calls: acc.calls + rep.calls,
        emails: acc.emails + rep.emails,
        meetings: acc.meetings + rep.meetings,
        tasks: acc.tasks + rep.tasks,
        total: acc.total + rep.total,
      }),
      { calls: 0, emails: 0, meetings: 0, tasks: 0, total: 0 }
    );
  }, [activityByRep]);

  return (
    <div className="team-activity-summary">
      <h3 className="team-activity-summary__title">{title}</h3>

      {/* Summary Cards */}
      <div className="team-activity-summary__totals">
        <div className="team-activity-stat">
          <span className="team-activity-stat__icon">📞</span>
          <span className="team-activity-stat__value">{totals.calls}</span>
          <span className="team-activity-stat__label">Calls</span>
        </div>
        <div className="team-activity-stat">
          <span className="team-activity-stat__icon">📧</span>
          <span className="team-activity-stat__value">{totals.emails}</span>
          <span className="team-activity-stat__label">Emails</span>
        </div>
        <div className="team-activity-stat">
          <span className="team-activity-stat__icon">📅</span>
          <span className="team-activity-stat__value">{totals.meetings}</span>
          <span className="team-activity-stat__label">Meetings</span>
        </div>
        <div className="team-activity-stat">
          <span className="team-activity-stat__icon">✅</span>
          <span className="team-activity-stat__value">{totals.tasks}</span>
          <span className="team-activity-stat__label">Tasks</span>
        </div>
      </div>

      {/* By Rep Breakdown */}
      {activityByRep.length > 0 ? (
        <div className="team-activity-summary__breakdown">
          <table className="mini-table">
            <thead>
              <tr>
                <th>Rep</th>
                <th>📞</th>
                <th>📧</th>
                <th>📅</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {activityByRep.slice(0, 5).map((rep) => (
                <tr key={rep.assigneeId}>
                  <td>{rep.assigneeName}</td>
                  <td>{rep.calls}</td>
                  <td>{rep.emails}</td>
                  <td>{rep.meetings}</td>
                  <td><strong>{rep.total}</strong></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="empty-message">No activity logged today yet</p>
      )}
    </div>
  );
}

export default TeamActivitySummary;
