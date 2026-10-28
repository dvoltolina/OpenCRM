/**
 * SequenceBuilder Component
 * Main visual editor for creating and editing sequences
 */

import { useState, useCallback, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  DndContext,
  DragOverlay,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { useSequenceBuilder } from '../../hooks/useSequenceBuilder';
import { useSequenceMutations } from '../../hooks/useSequences';
import { SequenceStepCard } from './SequenceStepCard';
import { SequenceStepEditor } from './SequenceStepEditor';
import { SequenceSettings } from './SequenceSettings';
import { SequencePreview } from './SequencePreview';
import { StepTypeSelector } from './StepTypeSelector';
import { Card, EmptyState } from '../ui';
import type { SequenceStep, SequenceStepType } from '../../types/sequences';
import './sequences.css';

// ============================================
// Types
// ============================================

type TabType = 'steps' | 'settings' | 'preview';

interface AddStepState {
  isOpen: boolean;
  afterIndex?: number;
}

// ============================================
// Component
// ============================================

export function SequenceBuilder() {
  const navigate = useNavigate();
  const { id: sequenceId } = useParams<{ id: string }>();
  const isNew = !sequenceId || sequenceId === 'new';

  // Builder state from hook
  const {
    sequence,
    steps,
    settings,
    name,
    description,
    isLoading,
    isSaving,
    hasChanges,
    validation,
    durationDays,
    setName,
    setDescription,
    addStep,
    updateStep,
    removeStep,
    reorderSteps,
    duplicateStep,
    updateSettings,
    save,
  } = useSequenceBuilder(isNew ? undefined : sequenceId);

  const { activateSequence, pauseSequence } = useSequenceMutations();

  // Local UI state
  const [activeTab, setActiveTab] = useState<TabType>('steps');
  const [editingStep, setEditingStep] = useState<SequenceStep | null>(null);
  const [addStepState, setAddStepState] = useState<AddStepState>({ isOpen: false });
  const [activeStepId, setActiveStepId] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  // DnD sensors
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Reset confirm delete when clicking elsewhere
  useEffect(() => {
    if (confirmDelete) {
      const timer = setTimeout(() => setConfirmDelete(null), 3000);
      return () => clearTimeout(timer);
    }
  }, [confirmDelete]);

  // Handlers
  const handleBack = useCallback(() => {
    navigate('/sequences');
  }, [navigate]);

  const handleSave = useCallback(async () => {
    try {
      const saved = await save();
      if (isNew && saved.id) {
        navigate(`/sequences/${saved.id}`, { replace: true });
      }
    } catch {
      // Error handled by hook
    }
  }, [save, isNew, navigate]);

  const handleActivate = useCallback(async () => {
    if (!sequence) return;
    try {
      if (sequence.status === 'active') {
        await pauseSequence(sequence.id);
      } else {
        await activateSequence(sequence.id);
      }
      // Refresh will happen automatically
    } catch {
      // Error handled by hook
    }
  }, [sequence, activateSequence, pauseSequence]);

  const handleAddStepClick = useCallback((afterIndex?: number) => {
    setAddStepState({ isOpen: true, afterIndex });
  }, []);

  const handleSelectStepType = useCallback((type: SequenceStepType) => {
    addStep(type, addStepState.afterIndex);
    setAddStepState({ isOpen: false });
    // Open editor for the new step - it will be at the correct position
    const newStepIndex = addStepState.afterIndex !== undefined
      ? addStepState.afterIndex + 1
      : steps.length;
    // Small delay to allow state to update
    setTimeout(() => {
      const newStep = steps[newStepIndex];
      if (newStep) {
        setEditingStep(newStep);
      }
    }, 50);
  }, [addStep, addStepState.afterIndex, steps]);

  const handleCancelAddStep = useCallback(() => {
    setAddStepState({ isOpen: false });
  }, []);

  const handleEditStep = useCallback((step: SequenceStep) => {
    setEditingStep(step);
  }, []);

  const handleSaveStep = useCallback((updatedStep: SequenceStep) => {
    updateStep(updatedStep.id, updatedStep);
    setEditingStep(null);
  }, [updateStep]);

  const handleCancelEditStep = useCallback(() => {
    setEditingStep(null);
  }, []);

  const handleDeleteStep = useCallback((stepId: string) => {
    if (confirmDelete === stepId) {
      removeStep(stepId);
      setConfirmDelete(null);
    } else {
      setConfirmDelete(stepId);
    }
  }, [confirmDelete, removeStep]);

  const handleDuplicateStep = useCallback((stepId: string) => {
    duplicateStep(stepId);
  }, [duplicateStep]);

  // Drag and drop handlers
  const handleDragStart = useCallback((event: DragStartEvent) => {
    setActiveStepId(event.active.id as string);
  }, []);

  const handleDragEnd = useCallback((event: DragEndEvent) => {
    const { active, over } = event;
    setActiveStepId(null);

    if (over && active.id !== over.id) {
      const oldIndex = steps.findIndex((s) => s.id === active.id);
      const newIndex = steps.findIndex((s) => s.id === over.id);
      if (oldIndex !== -1 && newIndex !== -1) {
        reorderSteps(oldIndex, newIndex);
      }
    }
  }, [steps, reorderSteps]);

  // Loading state
  if (isLoading) {
    return (
      <div className="sequence-builder" data-testid="sequence-builder-loading">
        <div className="sequence-builder__loading">
          <div className="sequences-page__spinner" />
          <span>Loading sequence...</span>
        </div>
      </div>
    );
  }

  const isActive = sequence?.status === 'active';
  const canActivate = validation.isValid && steps.length > 0;
  const statusLabel = sequence?.status || 'draft';
  const activeStep = activeStepId ? steps.find((s) => s.id === activeStepId) : null;
  const statusSummary = validation.isValid
    ? 'Ready to activate'
    : `${validation.errors.length} issue${validation.errors.length === 1 ? '' : 's'} to fix`;

  return (
    <div className="sequence-builder" data-testid="sequence-builder">
      <div className="sequence-builder__header">
        <div className="sequence-builder__header-main">
          <div className="sequence-builder__header-left">
            <button
              type="button"
              className="sequence-builder__back-btn"
              onClick={handleBack}
              aria-label="Back to sequences"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M19 12H5M12 19l-7-7 7-7" />
              </svg>
            </button>
            <div className="sequence-builder__title-group">
              <div className="sequence-builder__title-row">
                <input
                  type="text"
                  className="sequence-builder__name-input"
                  placeholder="Untitled Sequence"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  data-testid="sequence-name-input"
                />
                <span className={`sequence-list__badge sequence-list__badge--${statusLabel}`}>
                  {statusLabel}
                </span>
              </div>
              <p className="sequence-builder__subtitle">
                Build the touch pattern, pacing, and activation rules from one workspace.
              </p>
            </div>
          </div>

          <div className="sequence-builder__summary">
            <div className="sequence-builder__summary-card">
              <span>Steps</span>
              <strong>{steps.length}</strong>
            </div>
            <div className="sequence-builder__summary-card">
              <span>Duration</span>
              <strong>{durationDays}d</strong>
            </div>
            <div className="sequence-builder__summary-card">
              <span>Status</span>
              <strong>{statusSummary}</strong>
            </div>
          </div>
        </div>

        <div className="sequence-builder__header-actions">
          {hasChanges && (
            <span className="sequence-builder__status">Unsaved changes</span>
          )}
          <button
            type="button"
            className="sequence-builder__save-btn"
            onClick={handleSave}
            disabled={isSaving || !hasChanges}
            data-testid="save-sequence-btn"
          >
            {isSaving ? 'Saving...' : 'Save'}
          </button>
          {sequence && !isNew && (
            <button
              type="button"
              className="sequence-builder__activate-btn"
              onClick={handleActivate}
              disabled={!canActivate && !isActive}
              data-testid="activate-sequence-btn"
            >
              {isActive ? 'Pause' : 'Activate'}
            </button>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="sequence-builder__content">
        <div className="sequence-builder__main">
          {!validation.isValid && (
            <div className="sequence-builder__errors" role="alert">
              <h4 className="sequence-builder__errors-title">
                Please fix the following issues:
              </h4>
              <ul className="sequence-builder__errors-list">
                {validation.errors.map((error, index) => (
                  <li key={index}>{error.message}</li>
                ))}
              </ul>
            </div>
          )}

          <Card className="sequence-builder__overview-card" padding="lg">
            <div className="sequence-builder__timeline-header">
              <div>
                <p className="sequence-builder__section-eyebrow">Sequence Overview</p>
                <h3>Description & cadence</h3>
              </div>
              <p>
                Give the sequence clear internal context so teammates understand the intent before they edit steps.
              </p>
            </div>

            <div className="sequence-builder__description-field">
              <label className="step-editor__label" htmlFor="sequence-description">
                Description (optional)
              </label>
              <input
                id="sequence-description"
                type="text"
                className="step-editor__input"
                placeholder="Brief description of this sequence..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </Card>

          <Card className="sequence-builder__timeline-card" padding="lg">
            <div className="sequence-builder__timeline-header">
              <div>
                <p className="sequence-builder__section-eyebrow">Touch Flow</p>
                <h3>Sequence timeline</h3>
              </div>
              <p>Arrange steps in order, then insert waits and follow-ups between touches.</p>
            </div>

            <DndContext
              sensors={sensors}
              collisionDetection={closestCenter}
              onDragStart={handleDragStart}
              onDragEnd={handleDragEnd}
            >
              <SortableContext
                items={steps.map((s) => s.id)}
                strategy={verticalListSortingStrategy}
              >
                {steps.length === 0 ? (
                  <EmptyState
                    className="sequence-builder__empty-state"
                    eyebrow="No Steps"
                    title="This sequence has no steps yet"
                    description="Start with the first touchpoint, then build the rest of the cadence around it."
                    actions={(
                      <button
                        type="button"
                        className="sequence-add-step__btn"
                        onClick={() => handleAddStepClick()}
                        data-testid="add-first-step-btn"
                      >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M12 5v14M5 12h14" />
                        </svg>
                        Add your first step
                      </button>
                    )}
                  />
                ) : (
                  <>
                    {steps.map((step, index) => (
                      <div key={step.id}>
                        <SequenceStepCard
                          step={step}
                          index={index}
                          totalSteps={steps.length}
                          hasError={validation.errors.some((e) => e.stepId === step.id)}
                          isConfirmingDelete={confirmDelete === step.id}
                          onEdit={() => handleEditStep(step)}
                          onDelete={() => handleDeleteStep(step.id)}
                          onDuplicate={() => handleDuplicateStep(step.id)}
                          disabled={isActive}
                        />
                        {index < steps.length - 1 && (
                          <div className="sequence-add-step">
                            <div className="sequence-add-step__connector" />
                            <button
                              type="button"
                              className="sequence-add-step__btn"
                              onClick={() => handleAddStepClick(index)}
                              disabled={isActive}
                            >
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="M12 5v14M5 12h14" />
                              </svg>
                              Add step
                            </button>
                          </div>
                        )}
                      </div>
                    ))}
                    <div className="sequence-add-step">
                      <div className="sequence-add-step__connector" />
                      <button
                        type="button"
                        className="sequence-add-step__btn"
                        onClick={() => handleAddStepClick()}
                        disabled={isActive}
                        data-testid="add-step-btn"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M12 5v14M5 12h14" />
                        </svg>
                        Add step
                      </button>
                    </div>
                  </>
                )}
              </SortableContext>

              <DragOverlay>
                {activeStep && (
                  <SequenceStepCard
                    step={activeStep}
                    index={steps.findIndex((s) => s.id === activeStep.id)}
                    totalSteps={steps.length}
                    isDragging
                  />
                )}
              </DragOverlay>
            </DndContext>
          </Card>
        </div>

        <div className="sequence-builder__sidebar">
          <Card className="sequence-builder__sidebar-panel" padding="md">
            <div className="sequence-builder__tabs">
              <button
                type="button"
                className={`sequence-builder__tab ${activeTab === 'steps' ? 'sequence-builder__tab--active' : ''}`}
                onClick={() => setActiveTab('steps')}
              >
                Duration
              </button>
              <button
                type="button"
                className={`sequence-builder__tab ${activeTab === 'settings' ? 'sequence-builder__tab--active' : ''}`}
                onClick={() => setActiveTab('settings')}
              >
                Settings
              </button>
              <button
                type="button"
                className={`sequence-builder__tab ${activeTab === 'preview' ? 'sequence-builder__tab--active' : ''}`}
                onClick={() => setActiveTab('preview')}
              >
                Preview
              </button>
            </div>

            <div className="sequence-builder__sidebar-body">
              {activeTab === 'steps' && (
                <div className="sequence-builder__duration-card">
                  <p className="sequence-builder__section-eyebrow">Cadence Snapshot</p>
                  <div className="sequence-builder__duration-value">{durationDays}</div>
                  <div className="sequence-builder__duration-label">
                    day{durationDays !== 1 ? 's' : ''} total
                  </div>
                  <div className="sequence-builder__duration-meta">
                    {steps.length} step{steps.length !== 1 ? 's' : ''} in this flow
                  </div>
                </div>
              )}

              {activeTab === 'settings' && (
                <SequenceSettings
                  settings={settings}
                  onUpdate={updateSettings}
                  disabled={isActive}
                />
              )}

              {activeTab === 'preview' && (
                <SequencePreview
                  steps={steps}
                  settings={settings}
                />
              )}
            </div>
          </Card>
        </div>
      </div>

      {addStepState.isOpen && (
        <div className="step-editor-overlay" onClick={handleCancelAddStep}>
          <div className="step-editor" onClick={(e) => e.stopPropagation()}>
            <div className="step-editor__header">
              <h3 className="step-editor__title">Select Step Type</h3>
              <button
                type="button"
                className="step-editor__close-btn"
                onClick={handleCancelAddStep}
                aria-label="Close"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M18 6L6 18M6 6l12 12" />
                </svg>
              </button>
            </div>
            <StepTypeSelector
              onSelect={handleSelectStepType}
              onCancel={handleCancelAddStep}
            />
          </div>
        </div>
      )}

      {editingStep && (
        <SequenceStepEditor
          step={editingStep}
          onSave={handleSaveStep}
          onCancel={handleCancelEditStep}
          disabled={isActive}
        />
      )}
    </div>
  );
}

export default SequenceBuilder;
