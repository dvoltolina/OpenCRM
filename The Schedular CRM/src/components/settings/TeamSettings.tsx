/**
 * TeamSettings Component
 * Team member list and role management
 *
 * Agent CRM-20 Implementation
 * Dependencies: useTeamMembers hook
 */

import { useState, useMemo } from 'react';
import { useTeamMembers, type TeamMember } from '../../hooks/useTeamMembers';
import { useAuth } from '../../context/AuthContext';
import { TeamMemberRow } from './TeamMemberRow';
import './settings.css';

// ============================================
// Types
// ============================================

export interface TeamSettingsProps {
  /** Called when a member is selected */
  onMemberSelect?: (member: TeamMember) => void;
}

// ============================================
// Component
// ============================================

/**
 * TeamSettings - Team member management UI
 *
 * @example
 * ```tsx
 * <TeamSettings
 *   onMemberSelect={(member) => console.log('Selected:', member.email)}
 * />
 * ```
 */
export function TeamSettings({ onMemberSelect }: TeamSettingsProps) {
  const { crmUser } = useAuth();
  const { members, isLoading, error, updateMemberRole, refresh } = useTeamMembers();

  const [searchQuery, setSearchQuery] = useState('');
  const [showInviteForm, setShowInviteForm] = useState(false);

  // RBAC: Only owner and admin can edit roles and invite members
  const canEditRoles = crmUser?.role === 'owner' || crmUser?.role === 'admin';
  const canInviteMembers = crmUser?.role === 'owner' || crmUser?.role === 'admin';

  // Filter members by search
  const filteredMembers = useMemo(() => {
    if (!searchQuery.trim()) return members;

    const query = searchQuery.toLowerCase();
    return members.filter(
      (m) =>
        m.firstName.toLowerCase().includes(query) ||
        m.lastName.toLowerCase().includes(query) ||
        m.email.toLowerCase().includes(query)
    );
  }, [members, searchQuery]);

  // Group members by role
  const groupedMembers = useMemo(() => {
    const groups: Record<string, TeamMember[]> = {
      owner: [],
      admin: [],
      manager: [],
      sales: [],
      staff: [],
      provider: [],
      frontDesk: [],
    };

    filteredMembers.forEach((member) => {
      if (groups[member.role]) {
        groups[member.role].push(member);
      } else {
        groups.staff.push(member);
      }
    });

    return groups;
  }, [filteredMembers]);

  // Handle role change
  const handleRoleChange = async (memberId: string, role: TeamMember['role']) => {
    await updateMemberRole(memberId, role);
  };

  // Handle member click
  const handleMemberClick = (member: TeamMember) => {
    onMemberSelect?.(member);
  };

  if (isLoading) {
    return (
      <div className="team-settings team-settings--loading" data-testid="team-settings-loading">
        <div className="team-settings__loader">Loading team members...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="team-settings team-settings--error" data-testid="team-settings-error">
        <div className="team-settings__error-message">
          <p>Failed to load team members</p>
          <p className="team-settings__error-detail">{error.message}</p>
          <button
            type="button"
            className="team-settings__btn team-settings__btn--primary"
            onClick={refresh}
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="team-settings" data-testid="team-settings">
      {/* RBAC Warning */}
      {!canEditRoles && (
        <div className="team-settings__rbac-warning" role="alert">
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
          >
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <span>
            You have view-only access to team settings. Contact an administrator to manage team members.
          </span>
        </div>
      )}

      {/* Header */}
      <div className="team-settings__header">
        <h3 className="team-settings__title">Team Members</h3>
        <div className="team-settings__actions">
          <button
            type="button"
            className="team-settings__btn team-settings__btn--primary"
            onClick={() => setShowInviteForm(true)}
            disabled={showInviteForm || !canInviteMembers}
            title={!canInviteMembers ? 'Only owners and admins can invite members' : undefined}
          >
            + Invite Member
          </button>
        </div>
      </div>

      {/* Invite Form Placeholder */}
      {showInviteForm && (
        <div className="team-settings__invite-form" data-testid="invite-form">
          <div className="team-settings__invite-placeholder">
            <p>Team member invitations will be available in a future update.</p>
            <p className="team-settings__invite-hint">
              For now, team members can be added through The Scheduler's provider management.
            </p>
            <button
              type="button"
              className="team-settings__btn"
              onClick={() => setShowInviteForm(false)}
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Search */}
      <div className="team-settings__search">
        <input
          type="text"
          className="team-settings__search-input"
          placeholder="Search team members..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          aria-label="Search team members"
        />
        {searchQuery && (
          <button
            type="button"
            className="team-settings__search-clear"
            onClick={() => setSearchQuery('')}
            aria-label="Clear search"
          >
            &times;
          </button>
        )}
      </div>

      {/* Member Count */}
      <div className="team-settings__count">
        {filteredMembers.length} member{filteredMembers.length !== 1 ? 's' : ''}
        {searchQuery && ` matching "${searchQuery}"`}
      </div>

      {/* Members List */}
      {filteredMembers.length === 0 ? (
        <div className="team-settings__empty" data-testid="team-settings-empty">
          {searchQuery ? (
            <p>No team members match your search.</p>
          ) : (
            <p>No team members yet.</p>
          )}
        </div>
      ) : (
        <div className="team-settings__list" data-testid="team-list">
          {/* Owners */}
          {groupedMembers.owner.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Owners</h4>
              {groupedMembers.owner.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={false}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Admins */}
          {groupedMembers.admin.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Administrators</h4>
              {groupedMembers.admin.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Managers */}
          {groupedMembers.manager.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Managers</h4>
              {groupedMembers.manager.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Sales */}
          {groupedMembers.sales.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Sales</h4>
              {groupedMembers.sales.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Staff */}
          {groupedMembers.staff.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Staff</h4>
              {groupedMembers.staff.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Providers */}
          {groupedMembers.provider.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Providers</h4>
              {groupedMembers.provider.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}

          {/* Front Desk */}
          {groupedMembers.frontDesk.length > 0 && (
            <div className="team-settings__group">
              <h4 className="team-settings__group-title">Front Desk</h4>
              {groupedMembers.frontDesk.map((member) => (
                <div
                  key={member.id}
                  onClick={() => handleMemberClick(member)}
                  className="team-settings__member-wrapper"
                >
                  <TeamMemberRow
                    member={member}
                    onRoleChange={handleRoleChange}
                    canEdit={canEditRoles}
                    disabled={isLoading}
                  />
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Role Legend */}
      <div className="team-settings__legend">
        <h4 className="team-settings__legend-title">Role Permissions</h4>
        <ul className="team-settings__legend-list">
          <li><strong>Owner:</strong> Full access, cannot be changed</li>
          <li><strong>Admin:</strong> Full access, can manage team</li>
          <li><strong>Manager:</strong> Team oversight with manager-scoped access</li>
          <li><strong>Sales:</strong> CRM pipeline and outreach workflows</li>
          <li><strong>Staff:</strong> Internal business access for shared operational work</li>
          <li><strong>Provider:</strong> Service delivery role synced from Scheduler</li>
          <li><strong>Front Desk:</strong> Read-only and coordination-oriented access</li>
        </ul>
      </div>
    </div>
  );
}

export default TeamSettings;
