/**
 * Staff Assignment Panel
 * Assign staff members to territories with priority
 */

import { useState, useCallback, useMemo } from 'react';
import type { TerritoryAssignment } from '../../types/models';
import type { TeamMember } from '../../hooks/useTeamMembers';

interface StaffAssignmentPanelProps {
  assignments: TerritoryAssignment[];
  teamMembers: TeamMember[];
  onChange: (assignments: TerritoryAssignment[]) => void;
  disabled?: boolean;
}

export function StaffAssignmentPanel({
  assignments,
  teamMembers,
  onChange,
  disabled = false,
}: StaffAssignmentPanelProps) {
  const [selectedStaffId, setSelectedStaffId] = useState('');

  // Get available staff (not already assigned)
  const availableStaff = useMemo(() => {
    const assignedIds = new Set(assignments.map((a) => a.staffId));
    return teamMembers.filter((m) => !assignedIds.has(m.id));
  }, [assignments, teamMembers]);

  // Add staff assignment
  const addAssignment = useCallback(() => {
    if (!selectedStaffId) return;

    const member = teamMembers.find((m) => m.id === selectedStaffId);
    if (!member) return;

    const newAssignment: TerritoryAssignment = {
      staffId: member.id,
      staffName: member.displayName,
      isPrimary: assignments.length === 0, // First assignment is primary
      priority: assignments.length + 1,
    };

    onChange([...assignments, newAssignment]);
    setSelectedStaffId('');
  }, [selectedStaffId, teamMembers, assignments, onChange]);

  // Remove assignment
  const removeAssignment = useCallback(
    (staffId: string) => {
      const remaining = assignments.filter((a) => a.staffId !== staffId);
      // Re-assign priorities
      const updated = remaining.map((a, idx) => ({
        ...a,
        priority: idx + 1,
        isPrimary: idx === 0, // First remaining becomes primary
      }));
      onChange(updated);
    },
    [assignments, onChange]
  );

  // Set primary
  const setPrimary = useCallback(
    (staffId: string) => {
      const updated = assignments.map((a) => ({
        ...a,
        isPrimary: a.staffId === staffId,
      }));
      onChange(updated);
    },
    [assignments, onChange]
  );

  // Move priority up/down
  const movePriority = useCallback(
    (staffId: string, direction: 'up' | 'down') => {
      const index = assignments.findIndex((a) => a.staffId === staffId);
      if (index < 0) return;

      const newIndex = direction === 'up' ? index - 1 : index + 1;
      if (newIndex < 0 || newIndex >= assignments.length) return;

      const updated = [...assignments];
      [updated[index], updated[newIndex]] = [updated[newIndex], updated[index]];

      // Re-assign priorities
      const withPriorities = updated.map((a, idx) => ({
        ...a,
        priority: idx + 1,
      }));
      onChange(withPriorities);
    },
    [assignments, onChange]
  );

  return (
    <div className="staff-assignment-panel">
      <div className="staff-assignment-header">
        <h4>Staff Assignments</h4>
        <span className="assignment-count">
          {assignments.length} assigned
        </span>
      </div>

      {/* Add new assignment */}
      <div className="add-assignment-row">
        <select
          value={selectedStaffId}
          onChange={(e) => setSelectedStaffId(e.target.value)}
          disabled={disabled || availableStaff.length === 0}
          className="staff-select"
        >
          <option value="">Select staff member...</option>
          {availableStaff.map((member) => (
            <option key={member.id} value={member.id}>
              {member.displayName}
            </option>
          ))}
        </select>
        <button
          type="button"
          className="btn btn-sm btn-primary"
          onClick={addAssignment}
          disabled={disabled || !selectedStaffId}
        >
          Add
        </button>
      </div>

      {availableStaff.length === 0 && assignments.length > 0 && (
        <p className="all-assigned-note">All team members are assigned to this territory.</p>
      )}

      {/* Assignment list */}
      <div className="assignment-list">
        {assignments.length === 0 ? (
          <div className="assignment-list-empty">
            No staff assigned yet. Add team members to handle contacts in this territory.
          </div>
        ) : (
          assignments.map((assignment, index) => (
            <div key={assignment.staffId} className="assignment-item">
              <div className="assignment-priority">
                <button
                  type="button"
                  className="priority-btn"
                  onClick={() => movePriority(assignment.staffId, 'up')}
                  disabled={disabled || index === 0}
                  title="Move up"
                >
                  ↑
                </button>
                <span className="priority-number">{assignment.priority}</span>
                <button
                  type="button"
                  className="priority-btn"
                  onClick={() => movePriority(assignment.staffId, 'down')}
                  disabled={disabled || index === assignments.length - 1}
                  title="Move down"
                >
                  ↓
                </button>
              </div>

              <div className="assignment-info">
                <div className="assignment-name">
                  {assignment.staffName}
                  {assignment.isPrimary && (
                    <span className="primary-badge">Primary</span>
                  )}
                </div>
              </div>

              <div className="assignment-actions">
                {!assignment.isPrimary && (
                  <button
                    type="button"
                    className="btn btn-xs btn-ghost"
                    onClick={() => setPrimary(assignment.staffId)}
                    disabled={disabled}
                  >
                    Set Primary
                  </button>
                )}
                <button
                  type="button"
                  className="assignment-remove"
                  onClick={() => removeAssignment(assignment.staffId)}
                  disabled={disabled}
                >
                  &times;
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      <p className="assignment-hint">
        The primary staff member gets contact assignments first. Others are used as backups based on priority.
      </p>
    </div>
  );
}

export default StaffAssignmentPanel;
