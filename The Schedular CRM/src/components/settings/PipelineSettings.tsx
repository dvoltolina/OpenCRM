/**
 * PipelineSettings Component
 * Pipeline and stage configuration UI
 *
 * Agent CRM-20 Implementation
 * Dependencies: Agent CRM-07 (usePipelines, useStages)
 */

import { useState, useCallback, useEffect, useMemo } from 'react';
import type { KeyboardEvent } from 'react';
import { usePipelines } from '../../hooks/usePipelines';
import { useStages } from '../../hooks/useStages';
import { useSettings } from '../../hooks/useSettings';
import { useAuth } from '../../context/AuthContext';
import { StageList } from './StageList';
import { StageEditor, type StageFormData } from './StageEditor';
import type { Pipeline, Stage } from '../../types/models';
import { sanitizeTeamIds } from '../../lib/security-context';
import './settings.css';

interface TeamMultiSelectProps {
  label?: string;
  value: string[];
  onChange: (next: string[]) => void;
  availableOptions: string[];
  disabled?: boolean;
  placeholder?: string;
  helperText?: string;
  testId?: string;
}

const uniqTeams = (ids: string[]) => Array.from(new Set(sanitizeTeamIds(ids)));

function TeamMultiSelect({
  label,
  value,
  onChange,
  availableOptions,
  disabled,
  placeholder,
  helperText,
  testId,
}: TeamMultiSelectProps) {
  const [inputValue, setInputValue] = useState('');

  const handleAdd = (teamId: string) => {
    const normalized = teamId.trim();
    if (!normalized) return;
    onChange(uniqTeams([...value, normalized]));
    setInputValue('');
  };

  const handleRemove = (teamId: string) => {
    onChange(value.filter((id) => id !== teamId));
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault();
      handleAdd(inputValue);
    }
  };

  return (
    <div data-testid={testId}>
      {label && (
        <label className="pipeline-settings__subtitle" htmlFor={testId}>
          {label}
        </label>
      )}
      <div className="pipeline-settings__chip-input">
        {value.map((teamId) => (
          <span key={teamId} className="pipeline-settings__chip">
            {teamId}
            <button
              type="button"
              className="pipeline-settings__chip-remove"
              onClick={() => handleRemove(teamId)}
              disabled={disabled}
              aria-label={`Remove ${teamId}`}
            >
              ×
            </button>
          </span>
        ))}
        <input
          id={testId}
          type="text"
          className="pipeline-settings__input"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={disabled}
        />
      </div>
      {availableOptions.length > 0 && (
        <div className="pipeline-settings__options">
          {availableOptions.map((option) => {
            const isSelected = value.includes(option);
            return (
              <button
                key={option}
                type="button"
                className={`pipeline-settings__option ${isSelected ? 'pipeline-settings__option--selected' : ''}`}
                onClick={() => handleAdd(option)}
                disabled={disabled}
              >
                {option}
              </button>
            );
          })}
        </div>
      )}
      {helperText && <p className="pipeline-settings__helper">{helperText}</p>}
    </div>
  );
}

// ============================================
// Types
// ============================================

export interface PipelineSettingsProps {
  /** Called when pipeline is selected */
  onPipelineSelect?: (pipeline: Pipeline) => void;
}

// ============================================
// Component
// ============================================

/**
 * PipelineSettings - Pipeline and stage configuration
 *
 * @example
 * ```tsx
 * <PipelineSettings
 *   onPipelineSelect={(pipeline) => console.log('Selected:', pipeline.name)}
 * />
 * ```
 */
export function PipelineSettings({ onPipelineSelect }: PipelineSettingsProps) {
  const { crmUser } = useAuth();
  const { pipelines, createPipeline, updatePipeline, isLoading: pipelinesLoading } = usePipelines();
  const { setDefaultPipeline } = useSettings();

  const [selectedPipelineId, setSelectedPipelineId] = useState<string | null>(null);
  const [editingStage, setEditingStage] = useState<Stage | null>(null);
  const [isCreatingStage, setIsCreatingStage] = useState(false);
  const [isCreatingPipeline, setIsCreatingPipeline] = useState(false);
  const [newPipelineName, setNewPipelineName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [sharedTeamIds, setSharedTeamIds] = useState<string[]>([]);
  const [newPipelineTeams, setNewPipelineTeams] = useState<string[]>(crmUser?.teamIds || []);

  const availableTeamOptions = useMemo(
    () =>
      uniqTeams([
        ...(crmUser?.teamIds || []),
        ...pipelines.flatMap((p) => p.teamIds || []),
      ]),
    [crmUser?.teamIds, pipelines]
  );

  // RBAC: Only owner and admin can modify pipelines/stages
  const isAdminOrOwnerRole = crmUser?.role === 'owner' || crmUser?.role === 'admin';
  const userTeamIds = crmUser?.teamIds || [];
  const canCreatePipeline = crmUser
    ? crmUser.role !== 'frontDesk' && crmUser.role !== 'client'
    : false;
  const canManagePipeline = (pipeline?: Pipeline | null) =>
    !!pipeline &&
    (isAdminOrOwnerRole ||
      pipeline.ownerId === crmUser?.id ||
      (pipeline.teamIds || []).some((id) => userTeamIds.includes(id)));

  // Get selected pipeline
  const selectedPipeline = selectedPipelineId
    ? pipelines.find((p) => p.id === selectedPipelineId)
    : pipelines.find((p) => p.isDefault) || pipelines[0];

  // Get stages for selected pipeline
  const {
    stages,
    createStage,
    updateStage,
    reorderStages,
    isLoading: stagesLoading,
  } = useStages(selectedPipeline?.id);

  useEffect(() => {
    if (selectedPipeline) {
      setSharedTeamIds(uniqTeams(selectedPipeline.teamIds || []));
    } else {
      setSharedTeamIds([]);
    }
  }, [selectedPipeline]);

  // Handle pipeline selection
  const handlePipelineSelect = useCallback((pipelineId: string) => {
    setSelectedPipelineId(pipelineId);
    setEditingStage(null);
    setIsCreatingStage(false);
    const pipeline = pipelines.find((p) => p.id === pipelineId);
    if (pipeline) {
      onPipelineSelect?.(pipeline);
    }
  }, [pipelines, onPipelineSelect]);

  // Create new pipeline
  const handleCreatePipeline = async () => {
    if (!newPipelineName.trim()) {
      setError('Pipeline name is required');
      return;
    }

    setError(null);
    try {
      const pipeline = await createPipeline({
        name: newPipelineName.trim(),
        isDefault: pipelines.length === 0,
        isActive: true,
        teamIds: newPipelineTeams,
      });
      setNewPipelineName('');
      setIsCreatingPipeline(false);
      setSelectedPipelineId(pipeline.id);
      setNewPipelineTeams(crmUser?.teamIds || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create pipeline');
    }
  };

  // Set as default pipeline
  const handleSetDefault = async (pipelineId: string) => {
    try {
      await setDefaultPipeline(pipelineId);
      // Update the pipeline's isDefault field
      await updatePipeline(pipelineId, { isDefault: true });
      // Clear default on others
      for (const p of pipelines) {
        if (p.id !== pipelineId && p.isDefault) {
          await updatePipeline(p.id, { isDefault: false });
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to set default');
    }
  };

  // Archive/restore pipeline
  const handleArchivePipeline = async (pipeline: Pipeline) => {
    try {
      await updatePipeline(pipeline.id, { isActive: !pipeline.isActive });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update pipeline');
    }
  };

  // Save stage (create or update)
  const handleSaveStage = async (data: StageFormData) => {
    if (!selectedPipeline) return;

    if (editingStage) {
      await updateStage(editingStage.id, data);
    } else {
      await createStage({
        ...data,
        pipelineId: selectedPipeline.id,
        isActive: true,
      });
    }
    setEditingStage(null);
    setIsCreatingStage(false);
  };

  // Archive stage
  const handleArchiveStage = async (stage: Stage) => {
    await updateStage(stage.id, { isActive: !stage.isActive });
  };

  const handleSaveTeamIds = async () => {
    if (!selectedPipeline || !canManagePipeline(selectedPipeline)) return;

    try {
      await updatePipeline(selectedPipeline.id, { teamIds: sharedTeamIds });
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update sharing settings');
    }
  };

  // Reorder stages
  const handleReorderStages = async (stageIds: string[]) => {
    await reorderStages(stageIds);
  };

  // Cancel stage editing
  const handleCancelStageEdit = () => {
    setEditingStage(null);
    setIsCreatingStage(false);
  };

  const isLoading = pipelinesLoading || stagesLoading;
  const activeStages = stages.filter((s) => s.isActive);
  const archivedStages = stages.filter((s) => !s.isActive);
  const viewOnlyPipeline = selectedPipeline ? !canManagePipeline(selectedPipeline) : !isAdminOrOwnerRole;

  return (
    <div className="pipeline-settings" data-testid="pipeline-settings">
      {/* RBAC Warning */}
      {viewOnlyPipeline && (
        <div className="pipeline-settings__rbac-warning" role="alert">
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
            You have view-only access to pipeline settings. Contact an administrator to make changes.
          </span>
        </div>
      )}

      {/* Pipeline Selection */}
      <div className="pipeline-settings__section">
        <div className="pipeline-settings__header">
          <h3 className="pipeline-settings__title">Pipelines</h3>
          <button
            type="button"
            className="pipeline-settings__add-btn"
            onClick={() => setIsCreatingPipeline(true)}
            disabled={isCreatingPipeline || !canCreatePipeline}
            title={
              !canCreatePipeline
                ? 'Only authenticated users with access can create pipelines'
                : undefined
            }
          >
            + New Pipeline
          </button>
        </div>

        {error && (
          <div className="pipeline-settings__error" role="alert">
            {error}
          </div>
        )}

        {isCreatingPipeline && (
          <div className="pipeline-settings__create-form">
            <input
              type="text"
              className="pipeline-settings__input"
              placeholder="Pipeline name"
              value={newPipelineName}
              onChange={(e) => setNewPipelineName(e.target.value)}
              autoFocus
            />
            <button
              type="button"
              className="pipeline-settings__btn pipeline-settings__btn--primary"
              onClick={handleCreatePipeline}
            >
              Create
            </button>
            <button
              type="button"
              className="pipeline-settings__btn"
              onClick={() => {
                setIsCreatingPipeline(false);
                setNewPipelineName('');
              }}
            >
              Cancel
            </button>
            <TeamMultiSelect
              label="Share with team IDs (optional)"
              value={newPipelineTeams}
              onChange={setNewPipelineTeams}
              availableOptions={availableTeamOptions}
              disabled={!canCreatePipeline}
              placeholder="Add team and press Enter"
              helperText="Team access can be edited later."
              testId="new-pipeline-team-select"
            />
          </div>
        )}

        <div className="pipeline-settings__list" data-testid="pipeline-list">
          {pipelines.map((pipeline) => (
            <div
              key={pipeline.id}
              className={`pipeline-settings__item ${selectedPipeline?.id === pipeline.id ? 'pipeline-settings__item--selected' : ''} ${!pipeline.isActive ? 'pipeline-settings__item--archived' : ''}`}
              onClick={() => handlePipelineSelect(pipeline.id)}
              data-testid={`pipeline-item-${pipeline.id}`}
            >
              <div className="pipeline-settings__item-info">
                <span className="pipeline-settings__item-name">{pipeline.name}</span>
                <span className="pipeline-settings__item-owner">Owner: {pipeline.ownerName}</span>
                {pipeline.isDefault && (
                  <span className="pipeline-settings__badge">Default</span>
                )}
                {!pipeline.isActive && (
                  <span className="pipeline-settings__badge pipeline-settings__badge--archived">
                    Archived
                  </span>
                )}
              </div>
              <div className="pipeline-settings__item-actions">
                {isAdminOrOwnerRole && !pipeline.isDefault && pipeline.isActive && (
                  <button
                    type="button"
                    className="pipeline-settings__item-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleSetDefault(pipeline.id);
                    }}
                    disabled={!isAdminOrOwnerRole}
                    title={!isAdminOrOwnerRole ? 'Only owners and admins can set default pipeline' : 'Set as default'}
                  >
                    Set Default
                  </button>
                )}
                <button
                  type="button"
                  className="pipeline-settings__item-btn"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleArchivePipeline(pipeline);
                  }}
                  disabled={!canManagePipeline(pipeline)}
                  title={
                    !canManagePipeline(pipeline)
                      ? 'You need access to manage this pipeline'
                      : (pipeline.isActive ? 'Archive' : 'Restore')
                  }
                >
                  {pipeline.isActive ? 'Archive' : 'Restore'}
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {selectedPipeline && (
        <div className="pipeline-settings__section">
          <div className="pipeline-settings__header">
            <h3 className="pipeline-settings__title">Ownership & Sharing</h3>
          </div>
          <div className="pipeline-settings__owner-row">
            <strong>Owner:</strong> <span>{selectedPipeline.ownerName}</span>
          </div>
          <div className="pipeline-settings__sharing">
            <TeamMultiSelect
              label="Shared team IDs"
              value={sharedTeamIds}
              onChange={setSharedTeamIds}
              availableOptions={availableTeamOptions}
              disabled={!canManagePipeline(selectedPipeline)}
              placeholder="Add team ID and press Enter"
              helperText="Pipelines are visible/editable to the owner and any matching team IDs."
              testId="pipeline-team-select"
            />
            <div className="pipeline-settings__sharing-controls">
              <button
                type="button"
                className="pipeline-settings__btn pipeline-settings__btn--primary"
                onClick={handleSaveTeamIds}
                disabled={!canManagePipeline(selectedPipeline)}
              >
                Save Sharing
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Stage Configuration */}
      {selectedPipeline && (
        <div className="pipeline-settings__section">
          <div className="pipeline-settings__header">
            <h3 className="pipeline-settings__title">
              Stages for "{selectedPipeline.name}"
            </h3>
            <button
              type="button"
              className="pipeline-settings__add-btn"
              onClick={() => {
                setIsCreatingStage(true);
                setEditingStage(null);
              }}
              disabled={isCreatingStage || !!editingStage || !canManagePipeline(selectedPipeline)}
              title={
                !canManagePipeline(selectedPipeline)
                  ? 'You need edit access to add stages'
                  : undefined
              }
            >
              + Add Stage
            </button>
          </div>

          {/* Stage Editor */}
          {(isCreatingStage || editingStage) && (
            <div className="pipeline-settings__editor">
              <StageEditor
                stage={editingStage || undefined}
                pipelineId={selectedPipeline.id}
                order={activeStages.length}
                onSave={handleSaveStage}
                onCancel={handleCancelStageEdit}
              />
            </div>
          )}

          {/* Active Stages */}
          {!isCreatingStage && !editingStage && (
            <>
              <StageList
                stages={activeStages}
                onReorder={handleReorderStages}
                onEdit={setEditingStage}
                onArchive={handleArchiveStage}
                disabled={isLoading || !canManagePipeline(selectedPipeline)}
                canModify={canManagePipeline(selectedPipeline)}
              />

              {/* Archived Stages */}
              {archivedStages.length > 0 && (
                <div className="pipeline-settings__archived">
                  <h4 className="pipeline-settings__subtitle">Archived Stages</h4>
                  <StageList
                    stages={archivedStages}
                    onReorder={async () => {}}
                    onEdit={setEditingStage}
                    onArchive={handleArchiveStage}
                    disabled={true}
                    canModify={canManagePipeline(selectedPipeline)}
                  />
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}

export default PipelineSettings;
