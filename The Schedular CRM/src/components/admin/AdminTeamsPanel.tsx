/**
 * AdminTeamsPanel Component
 * Teams management panel for admins - create, edit, delete teams
 *
 * Per AGENT_RULES: Components should be under 600 lines
 */

import { useState, useMemo } from 'react';
import { useTeams } from '../../hooks/useTeams';
import { useTeamMembers } from '../../hooks/useTeamMembers';
import type { Team } from '../../types/models';
import { TeamFormModal } from './TeamFormModal';
import './admin.css';

interface AdminTeamsPanelProps {
  onTeamSelect?: (team: Team) => void;
}

export function AdminTeamsPanel({ onTeamSelect }: AdminTeamsPanelProps) {
  const { teams, isLoading, error, createTeam, updateTeam, deleteTeam, deactivateTeam, reactivateTeam } = useTeams({ includeInactive: true });
  const { members } = useTeamMembers();
  const [searchQuery, setSearchQuery] = useState('');
  const [showInactive, setShowInactive] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingTeam, setEditingTeam] = useState<Team | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  // Filter teams by search query and active status
  const filteredTeams = useMemo(() => {
    return teams.filter((team) => {
      const matchesSearch =
        team.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        team.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        team.managerName?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesStatus = showInactive || team.isActive;
      return matchesSearch && matchesStatus;
    });
  }, [teams, searchQuery, showInactive]);

  // Count members per team
  const memberCountByTeam = useMemo(() => {
    const counts: Record<string, number> = {};
    members.forEach((member) => {
      member.teamIds?.forEach((teamId) => {
        counts[teamId] = (counts[teamId] || 0) + 1;
      });
    });
    return counts;
  }, [members]);

  // Get managers for assignment
  const managers = useMemo(() => {
    return members.filter((m) => m.role === 'manager' || m.role === 'admin' || m.role === 'owner');
  }, [members]);

  const teamStats = useMemo(() => {
    const active = teams.filter((team) => team.isActive).length;
    const staffed = teams.filter((team) => (memberCountByTeam[team.id] || 0) > 0).length;

    return {
      total: teams.length,
      active,
      inactive: teams.length - active,
      staffed,
    };
  }, [memberCountByTeam, teams]);

  const handleCreateTeam = () => {
    setEditingTeam(null);
    setModalOpen(true);
  };

  const handleEditTeam = (team: Team) => {
    setEditingTeam(team);
    setModalOpen(true);
  };

  const handleSaveTeam = async (data: Partial<Team>) => {
    if (editingTeam) {
      await updateTeam(editingTeam.id, data);
    } else {
      await createTeam({
        name: data.name || 'New Team',
        description: data.description,
        managerId: data.managerId,
        managerName: data.managerName,
        colorHex: data.colorHex || '#6366F1',
        isActive: true,
      });
    }
    setModalOpen(false);
    setEditingTeam(null);
  };

  const handleDeleteConfirm = async (teamId: string) => {
    await deleteTeam(teamId);
    setConfirmDelete(null);
  };

  const handleToggleActive = async (team: Team) => {
    if (team.isActive) {
      await deactivateTeam(team.id);
    } else {
      await reactivateTeam(team.id);
    }
  };

  if (isLoading) {
    return <div className="admin-loading">Loading teams...</div>;
  }

  if (error) {
    return <div className="admin-empty-state">
      <div className="admin-empty-state-title">Error loading teams</div>
      <p>{error.message}</p>
    </div>;
  }

  return (
    <div className="admin-panel">
      <div className="admin-stats-grid">
        <div className="admin-stat-card admin-stat-card--accent">
          <div className="admin-stat-label">Total Teams</div>
          <div className="admin-stat-value">{teamStats.total}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--success">
          <div className="admin-stat-label">Active Teams</div>
          <div className="admin-stat-value">{teamStats.active}</div>
        </div>
        <div className="admin-stat-card admin-stat-card--warm">
          <div className="admin-stat-label">Inactive Teams</div>
          <div className="admin-stat-value">{teamStats.inactive}</div>
        </div>
        <div className="admin-stat-card">
          <div className="admin-stat-label">Staffed Teams</div>
          <div className="admin-stat-value">{teamStats.staffed}</div>
        </div>
      </div>

      <div className="admin-panel-surface">
        <div className="admin-panel-header">
          <div className="admin-panel-title-group">
            <p className="admin-panel-eyebrow">Team Management</p>
            <h2 className="admin-panel-title">
              Teams
              <span className="admin-panel-title__count">({filteredTeams.length})</span>
            </h2>
            <p className="admin-panel-description">
              Maintain active and inactive teams, ownership, and staffing coverage.
            </p>
          </div>
          <button className="btn btn-primary" onClick={handleCreateTeam}>
            Create Team
          </button>
        </div>

        <div className="admin-filter-bar admin-filter-bar--teams">
          <label className="admin-field">
            <span className="admin-field-label">Search</span>
            <input
              type="text"
              className="admin-search-input"
              placeholder="Search teams..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </label>
          <label className="admin-checkbox">
            <input
              type="checkbox"
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
            />
            <span>Include inactive teams</span>
          </label>
        </div>

        {filteredTeams.length === 0 ? (
          <div className="admin-empty-state">
            <div className="admin-empty-state-icon">👥</div>
            <div className="admin-empty-state-title">No teams found</div>
            <p>Create a team to organize your staff members.</p>
          </div>
        ) : (
          <div className="admin-table-shell">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Team</th>
                  <th>Manager</th>
                  <th>Members</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredTeams.map((team) => (
                  <tr
                    key={team.id}
                    className="admin-table-row-clickable"
                    onClick={() => onTeamSelect?.(team)}
                  >
                    <td>
                      <div className="admin-cell-stack">
                        <span className="admin-cell-title admin-cell-title--with-dot">
                          <span
                            className="team-color-dot"
                            style={{ backgroundColor: team.colorHex || '#6366F1' }}
                          />
                          {team.name}
                        </span>
                        {team.description && (
                          <span className="admin-cell-meta">{team.description}</span>
                        )}
                      </div>
                    </td>
                    <td>
                      <span className="admin-cell-muted">{team.managerName || '-'}</span>
                    </td>
                    <td>
                      <span className="admin-cell-muted">{memberCountByTeam[team.id] || 0}</span>
                    </td>
                    <td>
                      <span className={`admin-status-badge ${team.isActive ? 'active' : 'inactive'}`}>
                        {team.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>
                      <div className="admin-actions" onClick={(e) => e.stopPropagation()}>
                        <button
                          className="admin-action-btn"
                          onClick={() => handleEditTeam(team)}
                          title="Edit team"
                        >
                          Edit
                        </button>
                        <button
                          className="admin-action-btn"
                          onClick={() => handleToggleActive(team)}
                          title={team.isActive ? 'Deactivate' : 'Reactivate'}
                        >
                          {team.isActive ? 'Deactivate' : 'Activate'}
                        </button>
                        {confirmDelete === team.id ? (
                          <>
                            <button
                              className="admin-action-btn danger"
                              onClick={() => handleDeleteConfirm(team.id)}
                            >
                              Confirm
                            </button>
                            <button
                              className="admin-action-btn"
                              onClick={() => setConfirmDelete(null)}
                            >
                              Cancel
                            </button>
                          </>
                        ) : (
                          <button
                            className="admin-action-btn danger"
                            onClick={() => setConfirmDelete(team.id)}
                            title="Delete team"
                          >
                            Delete
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modalOpen && (
        <TeamFormModal
          team={editingTeam}
          managers={managers}
          onSave={handleSaveTeam}
          onClose={() => {
            setModalOpen(false);
            setEditingTeam(null);
          }}
        />
      )}
    </div>
  );
}

export default AdminTeamsPanel;
