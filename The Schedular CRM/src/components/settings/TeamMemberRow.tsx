/**
 * TeamMemberRow Component
 * Individual row for team member display with role management
 *
 * Agent CRM-20 Implementation
 */

import React, { useState } from 'react';
import type { TeamMember } from '../../hooks/useTeamMembers';
import './settings.css';

// ============================================
// Types
// ============================================

export interface TeamMemberRowProps {
  /** Team member data */
  member: TeamMember;
  /** Called when role is changed */
  onRoleChange: (memberId: string, role: TeamMember['role']) => Promise<void>;
  /** Whether actions are disabled */
  disabled?: boolean;
  /** Whether current user can edit this member */
  canEdit?: boolean;
}

// ============================================
// Role Options
// ============================================

const ROLE_OPTIONS: { value: TeamMember['role']; label: string }[] = [
  { value: 'owner', label: 'Owner' },
  { value: 'admin', label: 'Admin' },
  { value: 'manager', label: 'Manager' },
  { value: 'sales', label: 'Sales' },
  { value: 'staff', label: 'Staff' },
  { value: 'provider', label: 'Provider' },
  { value: 'frontDesk', label: 'Front Desk' },
];

// ============================================
// Component
// ============================================

/**
 * TeamMemberRow - Individual team member row
 *
 * @example
 * ```tsx
 * <TeamMemberRow
 *   member={member}
 *   onRoleChange={handleRoleChange}
 *   canEdit={isAdmin}
 * />
 * ```
 */
export function TeamMemberRow({
  member,
  onRoleChange,
  disabled = false,
  canEdit = false,
}: TeamMemberRowProps) {
  const [isUpdating, setIsUpdating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Generate initials for avatar
  const initials = `${member.firstName.charAt(0)}${member.lastName.charAt(0)}`.toUpperCase();

  // Format full name
  const fullName = `${member.firstName} ${member.lastName}`.trim() || 'Unknown';

  // Handle role change
  const handleRoleChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newRole = e.target.value as TeamMember['role'];

    if (newRole === member.role) return;

    setIsUpdating(true);
    setError(null);

    try {
      await onRoleChange(member.id, newRole);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update role');
    } finally {
      setIsUpdating(false);
    }
  };

  return (
    <div
      className={`team-member-row ${!member.isActive ? 'team-member-row--inactive' : ''}`}
      data-testid={`team-member-${member.id}`}
    >
      {/* Avatar */}
      <div className="team-member-row__avatar">
        {member.avatarUrl ? (
          <img
            src={member.avatarUrl}
            alt={fullName}
            className="team-member-row__avatar-img"
          />
        ) : (
          <span className="team-member-row__avatar-initials">{initials}</span>
        )}
      </div>

      {/* Info */}
      <div className="team-member-row__info">
        <span className="team-member-row__name">{fullName}</span>
        <span className="team-member-row__email">{member.email}</span>
        {member.phone && (
          <span className="team-member-row__phone">{member.phone}</span>
        )}
      </div>

      {/* Role */}
      <div className="team-member-row__role">
        {canEdit && member.role !== 'owner' ? (
          <select
            className="team-member-row__role-select"
            value={member.role}
            onChange={handleRoleChange}
            disabled={disabled || isUpdating}
            aria-label={`Role for ${fullName}`}
          >
            {ROLE_OPTIONS.filter((opt) => opt.value !== 'owner').map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        ) : (
          <span className="team-member-row__role-badge">
            {ROLE_OPTIONS.find((opt) => opt.value === member.role)?.label || member.role}
          </span>
        )}
        {isUpdating && <span className="team-member-row__updating">Updating...</span>}
      </div>

      {/* Status */}
      {!member.isActive && (
        <span className="team-member-row__status team-member-row__status--inactive">
          Inactive
        </span>
      )}

      {/* Error */}
      {error && (
        <span className="team-member-row__error" role="alert">
          {error}
        </span>
      )}
    </div>
  );
}

export default TeamMemberRow;
