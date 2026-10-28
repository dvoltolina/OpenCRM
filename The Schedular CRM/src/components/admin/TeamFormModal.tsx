/**
 * TeamFormModal Component
 * Modal for creating and editing teams
 */

import { useState, useEffect } from 'react';
import type { Team } from '../../types/models';
import type { TeamMember } from '../../hooks/useTeamMembers';
import './admin.css';

const TEAM_COLORS = [
  '#6366F1', // Indigo
  '#8B5CF6', // Violet
  '#EC4899', // Pink
  '#EF4444', // Red
  '#F97316', // Orange
  '#EAB308', // Yellow
  '#22C55E', // Green
  '#14B8A6', // Teal
  '#06B6D4', // Cyan
  '#3B82F6', // Blue
];

interface TeamFormModalProps {
  team: Team | null;
  managers: TeamMember[];
  onSave: (data: Partial<Team>) => Promise<void>;
  onClose: () => void;
}

export function TeamFormModal({ team, managers, onSave, onClose }: TeamFormModalProps) {
  const [name, setName] = useState(team?.name || '');
  const [description, setDescription] = useState(team?.description || '');
  const [managerId, setManagerId] = useState(team?.managerId || '');
  const [colorHex, setColorHex] = useState(team?.colorHex || TEAM_COLORS[0]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = !!team;

  useEffect(() => {
    if (team) {
      setName(team.name);
      setDescription(team.description || '');
      setManagerId(team.managerId || '');
      setColorHex(team.colorHex || TEAM_COLORS[0]);
    }
  }, [team]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!name.trim()) {
      setError('Team name is required');
      return;
    }

    setSaving(true);
    try {
      const selectedManager = managers.find((m) => m.id === managerId);
      await onSave({
        name: name.trim(),
        description: description.trim() || undefined,
        managerId: managerId || undefined,
        managerName: selectedManager?.displayName || undefined,
        colorHex,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save team');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal team-form-modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="team-form-title"
      >
        <div className="team-form-shell">
          <div className="team-form-header">
            <div className="team-form-header__copy">
              <p className="admin-panel-eyebrow">{isEditing ? 'Edit Team' : 'Create Team'}</p>
              <h2 className="team-form-title" id="team-form-title">
                {isEditing ? 'Update Team Details' : 'Create a New Team'}
              </h2>
              <p className="team-form-description">
                Set ownership, descriptive context, and a color accent that will carry through the admin views.
              </p>
            </div>
            <button
              type="button"
              className="drawer-close-btn"
              onClick={onClose}
              aria-label="Close team form"
            >
              ×
            </button>
          </div>

          {error && <div className="team-form-error">{error}</div>}

          <form className="team-form" onSubmit={handleSubmit}>
            <div className="team-form-grid">
              <div className="team-form-field team-form-field--full">
                <label className="team-form-label">Team Name *</label>
                <input
                  type="text"
                  className="team-form-input"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Sales Team"
                  autoFocus
                />
              </div>

              <div className="team-form-field team-form-field--full">
                <label className="team-form-label">Description</label>
                <textarea
                  className="team-form-input team-form-textarea"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="What this team owns, how it is structured, or where it operates."
                />
              </div>

              <div className="team-form-field">
                <label className="team-form-label">Manager</label>
                <select
                  className="admin-filter-select team-form-select"
                  value={managerId}
                  onChange={(e) => setManagerId(e.target.value)}
                >
                  <option value="">No manager assigned</option>
                  {managers.map((manager) => (
                    <option key={manager.id} value={manager.id}>
                      {manager.displayName} ({manager.role})
                    </option>
                  ))}
                </select>
              </div>

              <div className="team-form-field">
                <label className="team-form-label">Team Color</label>
                <div className="team-form-color-preview">
                  <span
                    className="team-color-swatch"
                    style={{ backgroundColor: colorHex }}
                    aria-hidden="true"
                  />
                  <div className="team-form-preview-copy">
                    <span className="team-form-preview-label">Selected Accent</span>
                    <span className="team-form-preview-value">{colorHex}</span>
                  </div>
                </div>
                <div className="team-color-picker">
                  {TEAM_COLORS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      className={`team-color-option ${colorHex === color ? 'selected' : ''}`}
                      style={{ backgroundColor: color }}
                      onClick={() => setColorHex(color)}
                      aria-label={`Use ${color} as team color`}
                    />
                  ))}
                </div>
              </div>
            </div>

            <div className="team-form-actions">
              <button
                type="button"
                className="btn btn--secondary"
                onClick={onClose}
                disabled={saving}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn btn--primary"
                disabled={saving}
              >
                {saving ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Team'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default TeamFormModal;
