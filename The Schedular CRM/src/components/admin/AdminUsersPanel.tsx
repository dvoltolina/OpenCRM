/**
 * AdminUsersPanel Component
 * User search and table for admin - view all employees and their data
 *
 * Per AGENT_RULES: Components should be under 600 lines
 */

import { useState, useMemo } from 'react';
import { useTeamMembers } from '../../hooks/useTeamMembers';
import { useTeams } from '../../hooks/useTeams';
import type { TeamMember } from '../../hooks/useTeamMembers';
import './admin.css';

interface AdminUsersPanelProps {
  onUserSelect: (user: TeamMember) => void;
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

export function AdminUsersPanel({ onUserSelect }: AdminUsersPanelProps) {
  const { members, isLoading, error } = useTeamMembers();
  const { teams } = useTeams();
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [teamFilter, setTeamFilter] = useState<string>('');

  // Create a map of team IDs to team names
  const teamMap = useMemo(() => {
    const map: Record<string, string> = {};
    teams.forEach((team) => {
      map[team.id] = team.name;
    });
    return map;
  }, [teams]);

  // Filter members by search query and role
  const filteredMembers = useMemo(() => {
    return members.filter((member) => {
      const matchesSearch =
        member.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        member.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        member.firstName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        member.lastName.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesRole = !roleFilter || member.role === roleFilter;

      const matchesTeam = !teamFilter || member.teamIds?.includes(teamFilter);

      return matchesSearch && matchesRole && matchesTeam;
    });
  }, [members, searchQuery, roleFilter, teamFilter]);

  // Group members by role for stats
  const memberStats = useMemo(() => {
    const stats = {
      total: members.length,
      owners: members.filter((m) => m.role === 'owner').length,
      admins: members.filter((m) => m.role === 'admin').length,
      managers: members.filter((m) => m.role === 'manager').length,
      sales: members.filter((m) => m.role === 'sales').length,
      staff: members.filter((m) => m.role === 'staff').length,
      providers: members.filter((m) => m.role === 'provider').length,
      frontDesk: members.filter((m) => m.role === 'frontDesk').length,
    };
    return stats;
  }, [members]);

  // Get team names for a member
  const getTeamNames = (teamIds?: string[]): string => {
    if (!teamIds || teamIds.length === 0) return '-';
    return teamIds.map((id) => teamMap[id] || id).join(', ');
  };

  // Get manager name for a member
  const getManagerName = (managerId?: string): string => {
    if (!managerId) return '-';
    const manager = members.find((m) => m.id === managerId);
    return manager?.displayName || '-';
  };

  if (isLoading) {
    return <div className="admin-loading">Loading users...</div>;
  }

  if (error) {
    return (
      <div className="admin-empty-state">
        <div className="admin-empty-state-title">Error loading users</div>
        <p>{error.message}</p>
      </div>
    );
  }

  return (
    <div className="admin-panel">
      <div className="admin-stats-grid">
        <div className="admin-stat-card admin-stat-card--accent">
          <div className="admin-stat-label">Total Users</div>
          <div className="admin-stat-value">{memberStats.total}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--subtle">
          <div className="admin-stat-label">Owners</div>
          <div className="admin-stat-value">{memberStats.owners}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--subtle">
          <div className="admin-stat-label">Admins</div>
          <div className="admin-stat-value">{memberStats.admins}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--warm">
          <div className="admin-stat-label">Managers</div>
          <div className="admin-stat-value">{memberStats.managers}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Staff</div>
          <div className="admin-stat-value">{memberStats.staff}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Sales</div>
          <div className="admin-stat-value">{memberStats.sales}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Providers</div>
          <div className="admin-stat-value">{memberStats.providers}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Front Desk</div>
          <div className="admin-stat-value">{memberStats.frontDesk}</div>
        </div>
      </div>

      <div className="admin-panel-surface">
        <div className="admin-panel-header">
          <div className="admin-panel-title-group">
            <p className="admin-panel-eyebrow">User Directory</p>
            <h2 className="admin-panel-title">
              All Users
              <span className="admin-panel-title__count">({filteredMembers.length})</span>
            </h2>
            <p className="admin-panel-description">
              Search, filter, and inspect role coverage across every team in the workspace.
            </p>
          </div>
        </div>

        <div className="admin-filter-bar admin-filter-bar--users">
          <label className="admin-field">
            <span className="admin-field-label">Search</span>
            <input
              type="text"
              className="admin-search-input"
              placeholder="Search by name or email..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </label>
          <label className="admin-field">
            <span className="admin-field-label">Role</span>
            <select
              className="admin-filter-select"
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
            >
              <option value="">All Roles</option>
              <option value="owner">Owner</option>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="sales">Sales</option>
              <option value="staff">Staff</option>
              <option value="provider">Provider</option>
              <option value="frontDesk">Front Desk</option>
            </select>
          </label>
          <label className="admin-field">
            <span className="admin-field-label">Team</span>
            <select
              className="admin-filter-select"
              value={teamFilter}
              onChange={(e) => setTeamFilter(e.target.value)}
            >
              <option value="">All Teams</option>
              {teams.map((team) => (
                <option key={team.id} value={team.id}>
                  {team.name}
                </option>
              ))}
            </select>
          </label>
        </div>

        {filteredMembers.length === 0 ? (
          <div className="admin-empty-state">
            <div className="admin-empty-state-icon">👤</div>
            <div className="admin-empty-state-title">No users found</div>
            <p>Try adjusting your search or filters.</p>
          </div>
        ) : (
          <div className="admin-table-shell">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Team(s)</th>
                  <th>Manager</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {filteredMembers.map((member) => (
                  <tr
                    key={member.id}
                    className="admin-table-row-clickable"
                    onClick={() => onUserSelect(member)}
                  >
                    <td>
                      <div className="admin-cell-stack">
                        <span className="admin-cell-title">{member.displayName}</span>
                        <span className="admin-cell-meta">
                          {member.firstName} {member.lastName}
                        </span>
                      </div>
                    </td>
                    <td>
                      <span className="admin-cell-muted">{member.email}</span>
                    </td>
                    <td>
                      <span className={`admin-status-badge ${getRoleBadgeClassName(member.role)}`}>
                        {ROLE_LABELS[member.role] || member.role}
                      </span>
                    </td>
                    <td>
                      <span className="admin-cell-muted">{getTeamNames(member.teamIds)}</span>
                    </td>
                    <td>
                      <span className="admin-cell-muted">{getManagerName(member.managerId)}</span>
                    </td>
                    <td>
                      <span className={`admin-status-badge ${member.isActive ? 'active' : 'inactive'}`}>
                        {member.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default AdminUsersPanel;
