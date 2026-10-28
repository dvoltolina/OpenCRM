/**
 * UserDetailDrawer Component
 * Slide-out drawer showing user's leads, deals, and activities
 *
 * Per AGENT_RULES: Components should be under 600 lines
 */

import { useMemo } from 'react';
import { useDeals, useLeads, useRecentActivities } from '../../hooks';
import { useTeams } from '../../hooks/useTeams';
import type { TeamMember } from '../../hooks/useTeamMembers';
import type { SalesActivity } from '../../types/models';
import './admin.css';

interface UserDetailDrawerProps {
  user: TeamMember | null;
  onClose: () => void;
}

const ROLE_LABELS: Record<string, string> = {
  owner: 'Owner',
  admin: 'Admin',
  manager: 'Manager',
  staff: 'Staff',
  sales: 'Sales',
  provider: 'Provider',
  frontDesk: 'Front Desk',
};

function getRoleBadgeClassName(role: string): string {
  if (role === 'owner' || role === 'admin') return 'admin-status-badge--leadership';
  if (role === 'manager') return 'admin-status-badge--manager';
  return 'admin-status-badge--neutral';
}

function getDealStatusClassName(status: string): string {
  if (status === 'won') return 'active';
  if (status === 'lost') return 'inactive';
  return 'admin-status-badge--neutral';
}

function formatCurrency(cents: number, currency: string = 'USD'): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(cents / 100);
}

function formatDate(date?: Date): string {
  if (!date) return '-';
  return date.toLocaleDateString();
}

export function UserDetailDrawer({ user, onClose }: UserDetailDrawerProps) {
  const { deals, isLoading: dealsLoading } = useDeals({});
  const { leads, isLoading: leadsLoading } = useLeads({});
  const { activities, isLoading: activitiesLoading } = useRecentActivities(30, 100);
  const { teams } = useTeams();

  // Create a map of team IDs to team names
  const teamMap = useMemo(() => {
    const map: Record<string, string> = {};
    teams.forEach((team) => {
      map[team.id] = team.name;
    });
    return map;
  }, [teams]);

  // Filter data for this user
  const userDeals = useMemo(() => {
    if (!user) return [];
    return deals.filter(
      (d) => d.assigneeId === user.id || d.ownerId === user.id
    );
  }, [deals, user]);

  const userLeads = useMemo(() => {
    if (!user) return [];
    return leads.filter(
      (l) => l.assigneeId === user.id || l.ownerId === user.id
    );
  }, [leads, user]);

  const userActivities = useMemo(() => {
    if (!user) return [];
    return activities
      .filter((activity: SalesActivity) => activity.assigneeId === user.id || activity.createdById === user.id)
      .slice(0, 10); // Show last 10 activities
  }, [activities, user]);

  // Calculate stats
  const stats = useMemo(() => {
    const openDeals = userDeals.filter((d) => d.status === 'open').length;
    const wonDeals = userDeals.filter((d) => d.status === 'won').length;
    const totalPipeline = userDeals
      .filter((d) => d.status === 'open')
      .reduce((sum, d) => sum + d.valueCents, 0);
    const activeLeads = userLeads.filter((l) => l.status !== 'converted' && l.status !== 'unqualified').length;
    return { openDeals, wonDeals, totalPipeline, activeLeads };
  }, [userDeals, userLeads]);

  // Get team names for user
  const getTeamNames = (teamIds?: string[]): string => {
    if (!teamIds || teamIds.length === 0) return 'No teams assigned';
    return teamIds.map((id) => teamMap[id] || id).join(', ');
  };

  if (!user) return null;

  return (
    <>
      <div
        className={`drawer-overlay ${user ? 'open' : ''}`}
        onClick={onClose}
        aria-hidden="true"
      />
      <aside
        className={`user-detail-drawer ${user ? 'open' : ''}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby="user-detail-drawer-title"
      >
        <div className="drawer-header">
          <div className="drawer-header__copy">
            <p className="admin-panel-eyebrow">User Overview</p>
            <h2 className="drawer-title" id="user-detail-drawer-title">
              {user.displayName}
            </h2>
            <p className="drawer-subtitle">{user.email}</p>
            <div className="drawer-header__meta">
              <span
                className={`admin-status-badge ${getRoleBadgeClassName(user.role)}`}
              >
                {ROLE_LABELS[user.role] || user.role}
              </span>
              <span
                className={`admin-status-badge ${user.isActive ? 'active' : 'inactive'}`}
              >
                {user.isActive ? 'Active' : 'Inactive'}
              </span>
            </div>
          </div>
          <button
            type="button"
            className="drawer-close-btn"
            onClick={onClose}
            aria-label="Close user details"
          >
            ×
          </button>
        </div>

        <div className="drawer-content">
          <section className="drawer-section drawer-section--surface">
            <div className="drawer-section-heading">
              <h3 className="drawer-section-title">Assignment</h3>
            </div>
            <div className="drawer-info-grid">
              <div className="drawer-info-item">
                <span className="drawer-info-label">Role</span>
                <span className="drawer-info-value">
                  {ROLE_LABELS[user.role] || user.role}
                </span>
              </div>
              <div className="drawer-info-item">
                <span className="drawer-info-label">Teams</span>
                <span className="drawer-info-value">{getTeamNames(user.teamIds)}</span>
              </div>
              {user.managedTeamIds && user.managedTeamIds.length > 0 && (
                <div className="drawer-info-item drawer-info-item--full">
                  <span className="drawer-info-label">Managed Teams</span>
                  <span className="drawer-info-value">
                    {getTeamNames(user.managedTeamIds)}
                  </span>
                </div>
              )}
            </div>
          </section>

          <section className="drawer-section drawer-section--surface">
            <div className="drawer-section-heading">
              <h3 className="drawer-section-title">Performance Snapshot</h3>
            </div>
            <div className="admin-stats-grid drawer-stats-grid">
              <div className="admin-stat-card admin-stat-card--subtle">
                <div className="admin-stat-label">Active Leads</div>
                <div className="admin-stat-value">{stats.activeLeads}</div>
              </div>
              <div className="admin-stat-card admin-stat-card--warm">
                <div className="admin-stat-label">Open Deals</div>
                <div className="admin-stat-value">{stats.openDeals}</div>
              </div>
              <div className="admin-stat-card admin-stat-card--success">
                <div className="admin-stat-label">Won Deals</div>
                <div className="admin-stat-value">{stats.wonDeals}</div>
              </div>
              <div className="admin-stat-card admin-stat-card--accent">
                <div className="admin-stat-label">Pipeline Value</div>
                <div className="admin-stat-value admin-stat-value--compact">
                  {formatCurrency(stats.totalPipeline)}
                </div>
              </div>
            </div>
          </section>

          <section className="drawer-section drawer-section--surface">
            <div className="drawer-section-heading">
              <h3 className="drawer-section-title">Assigned Leads</h3>
              <span className="drawer-section-count">{userLeads.length}</span>
            </div>
            {leadsLoading ? (
              <div className="admin-note">Loading leads...</div>
            ) : userLeads.length === 0 ? (
              <div className="admin-empty-state admin-empty-state--compact">
                <div className="admin-empty-state-title">No leads assigned</div>
              </div>
            ) : (
              <div className="admin-table-shell drawer-table-shell">
                <table className="admin-table drawer-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Status</th>
                      <th>Source</th>
                    </tr>
                  </thead>
                  <tbody>
                    {userLeads.slice(0, 5).map((lead) => (
                      <tr key={lead.id}>
                        <td>
                          <div className="admin-cell-stack">
                            <span className="admin-cell-title">
                              {lead.firstName} {lead.lastName}
                            </span>
                            <span className="admin-cell-meta">{lead.email}</span>
                          </div>
                        </td>
                        <td>
                          <span className="admin-status-badge admin-status-badge--neutral">
                            {lead.status}
                          </span>
                        </td>
                        <td>{lead.source}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            {userLeads.length > 5 && (
              <div className="drawer-section-note">
                Showing 5 of {userLeads.length} assigned leads.
              </div>
            )}
          </section>

          <section className="drawer-section drawer-section--surface">
            <div className="drawer-section-heading">
              <h3 className="drawer-section-title">Assigned Deals</h3>
              <span className="drawer-section-count">{userDeals.length}</span>
            </div>
            {dealsLoading ? (
              <div className="admin-note">Loading deals...</div>
            ) : userDeals.length === 0 ? (
              <div className="admin-empty-state admin-empty-state--compact">
                <div className="admin-empty-state-title">No deals assigned</div>
              </div>
            ) : (
              <div className="admin-table-shell drawer-table-shell">
                <table className="admin-table drawer-table">
                  <thead>
                    <tr>
                      <th>Title</th>
                      <th>Value</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {userDeals.slice(0, 5).map((deal) => (
                      <tr key={deal.id}>
                        <td>
                          <div className="admin-cell-stack">
                            <span className="admin-cell-title">{deal.title}</span>
                            <span className="admin-cell-meta">
                              {deal.companyName || deal.clientName || 'No linked account'}
                            </span>
                          </div>
                        </td>
                        <td>{formatCurrency(deal.valueCents, deal.currency)}</td>
                        <td>
                          <span
                            className={`admin-status-badge ${getDealStatusClassName(deal.status)}`}
                          >
                            {deal.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            {userDeals.length > 5 && (
              <div className="drawer-section-note">
                Showing 5 of {userDeals.length} assigned deals.
              </div>
            )}
          </section>

          <section className="drawer-section drawer-section--surface">
            <div className="drawer-section-heading">
              <h3 className="drawer-section-title">Recent Activities</h3>
              <span className="drawer-section-count">{userActivities.length}</span>
            </div>
            {activitiesLoading ? (
              <div className="admin-note">Loading recent activities...</div>
            ) : userActivities.length === 0 ? (
              <div className="admin-empty-state admin-empty-state--compact">
                <div className="admin-empty-state-title">No recent activities</div>
              </div>
            ) : (
              <div className="drawer-activity-list">
                {userActivities.map((activity) => (
                  <article key={activity.id} className="drawer-activity-card">
                    <div className="drawer-activity-title">{activity.title}</div>
                    <div className="drawer-activity-meta">
                      {activity.type} · {formatDate(activity.createdAt)}
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>
        </div>
      </aside>
    </>
  );
}

export default UserDetailDrawer;
