/**
 * StageEditor Component
 * Form for creating and editing pipeline stages
 *
 * Agent CRM-20 Implementation
 */

import { useState, useEffect } from 'react';
import type { Stage } from '../../types/models';
import './settings.css';

// ============================================
// Types
// ============================================

export interface StageEditorProps {
  /** Stage to edit (undefined for create) */
  stage?: Stage;
  /** Pipeline ID for new stages */
  pipelineId: string;
  /** Order for new stage */
  order?: number;
  /** Called when save is clicked */
  onSave: (data: StageFormData) => Promise<void>;
  /** Called when cancel is clicked */
  onCancel: () => void;
  /** Whether the form is submitting */
  isSubmitting?: boolean;
}

export interface StageFormData {
  name: string;
  colorHex: string;
  probability: number;
  order: number;
  [key: string]: unknown;
}

// ============================================
// Color Presets
// ============================================

const COLOR_PRESETS = [
  '#6366f1', // Indigo
  '#3b82f6', // Blue
  '#06b6d4', // Cyan
  '#10b981', // Emerald
  '#84cc16', // Lime
  '#eab308', // Yellow
  '#f97316', // Orange
  '#ef4444', // Red
  '#ec4899', // Pink
  '#8b5cf6', // Violet
  '#64748b', // Slate
  '#171717', // Black
];

// ============================================
// Component
// ============================================

/**
 * StageEditor - Form for stage creation/editing
 *
 * @example
 * ```tsx
 * <StageEditor
 *   pipelineId="pipeline-123"
 *   order={3}
 *   onSave={handleCreateStage}
 *   onCancel={closeEditor}
 * />
 *
 * // Edit mode
 * <StageEditor
 *   stage={existingStage}
 *   pipelineId={existingStage.pipelineId}
 *   onSave={handleUpdateStage}
 *   onCancel={closeEditor}
 * />
 * ```
 */
export function StageEditor({
  stage,
  pipelineId: _pipelineId,
  order = 0,
  onSave,
  onCancel,
  isSubmitting = false,
}: StageEditorProps) {
  const [name, setName] = useState(stage?.name || '');
  const [colorHex, setColorHex] = useState(stage?.colorHex || COLOR_PRESETS[0]);
  const [probability, setProbability] = useState(stage?.probability ?? 50);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(stage?.id);

  // Reset form when stage changes
  useEffect(() => {
    if (stage) {
      setName(stage.name);
      setColorHex(stage.colorHex);
      setProbability(stage.probability);
    } else {
      setName('');
      setColorHex(COLOR_PRESETS[0]);
      setProbability(50);
    }
    setError(null);
  }, [stage]);

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validate
    if (!name.trim()) {
      setError('Stage name is required');
      return;
    }

    if (probability < 0 || probability > 100) {
      setError('Probability must be between 0 and 100');
      return;
    }

    try {
      await onSave({
        name: name.trim(),
        colorHex,
        probability,
        order: stage?.order ?? order,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save stage');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="stage-editor" data-testid="stage-editor">
      <div className="stage-editor__header">
        <h3 className="stage-editor__title">
          {isEditing ? 'Edit Stage' : 'New Stage'}
        </h3>
      </div>

      {error && (
        <div className="stage-editor__error" role="alert">
          {error}
        </div>
      )}

      <div className="stage-editor__field">
        <label htmlFor="stageName" className="stage-editor__label">
          Stage Name *
        </label>
        <input
          id="stageName"
          type="text"
          className="stage-editor__input"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="e.g., Qualified"
          disabled={isSubmitting}
          autoFocus
        />
      </div>

      <div className="stage-editor__field">
        <label className="stage-editor__label">Color</label>
        <div className="stage-editor__colors" data-testid="color-picker">
          {COLOR_PRESETS.map((color) => (
            <button
              key={color}
              type="button"
              className={`stage-editor__color-btn ${colorHex === color ? 'stage-editor__color-btn--selected' : ''}`}
              style={{ backgroundColor: color }}
              onClick={() => setColorHex(color)}
              disabled={isSubmitting}
              aria-label={`Select color ${color}`}
              aria-pressed={colorHex === color}
            />
          ))}
        </div>
        <div className="stage-editor__custom-color">
          <label htmlFor="customColor" className="stage-editor__label-small">
            Custom:
          </label>
          <input
            id="customColor"
            type="color"
            className="stage-editor__color-input"
            value={colorHex}
            onChange={(e) => setColorHex(e.target.value)}
            disabled={isSubmitting}
          />
          <span className="stage-editor__color-value">{colorHex}</span>
        </div>
      </div>

      <div className="stage-editor__field">
        <label htmlFor="probability" className="stage-editor__label">
          Win Probability (%)
        </label>
        <div className="stage-editor__probability">
          <input
            id="probability"
            type="range"
            className="stage-editor__slider"
            min="0"
            max="100"
            step="5"
            value={probability}
            onChange={(e) => setProbability(Number(e.target.value))}
            disabled={isSubmitting}
          />
          <input
            type="number"
            className="stage-editor__probability-input"
            min="0"
            max="100"
            value={probability}
            onChange={(e) => setProbability(Math.min(100, Math.max(0, Number(e.target.value))))}
            disabled={isSubmitting}
          />
          <span className="stage-editor__probability-label">%</span>
        </div>
        <p className="stage-editor__help">
          Estimated likelihood of winning deals at this stage
        </p>
      </div>

      <div className="stage-editor__actions">
        <button
          type="button"
          className="stage-editor__btn stage-editor__btn--secondary"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          Cancel
        </button>
        <button
          type="submit"
          className="stage-editor__btn stage-editor__btn--primary"
          disabled={isSubmitting}
        >
          {isSubmitting ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Stage'}
        </button>
      </div>
    </form>
  );
}

export default StageEditor;
