/**
 * Territories Page
 * Manage sales territories and staff assignments
 */

import { useState, useCallback, useMemo } from 'react';
import {
  useTerritories,
  useTerritoryMutations,
  useTeamMembers,
  useModal,
} from '../hooks';
import { BoundaryEditor, StaffAssignmentPanel } from '../components/territories';
import { ConfirmDialog } from '../components/modals';
import { Button, Card, EmptyState, PageHeader, PageLayout } from '../components/ui';
import type { Territory } from '../types/models';
import './styles/territories-page.css';

// Default colors for territories
const TERRITORY_COLORS = [
  '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6',
  '#ec4899', '#06b6d4', '#84cc16', '#f97316', '#6366f1',
];

export function TerritoriesPage() {
  const { territories, isLoading: territoriesLoading, refresh } = useTerritories(false); // Include inactive
  const { members, isLoading: membersLoading } = useTeamMembers();
  const {
    createTerritory,
    updateTerritory,
    deleteTerritory,
    isLoading: mutationLoading,
  } = useTerritoryMutations();

  const [selectedTerritoryId, setSelectedTerritoryId] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [editForm, setEditForm] = useState<Partial<Territory>>({});
  const deleteModal = useModal<string>();

  const isLoading = territoriesLoading || membersLoading;

  // Get selected territory
  const selectedTerritory = useMemo(() => {
    if (!selectedTerritoryId) return null;
    return territories.find((t) => t.id === selectedTerritoryId) ?? null;
  }, [selectedTerritoryId, territories]);

  // Start creating new territory
  const startCreate = useCallback(() => {
    setIsCreating(true);
    setSelectedTerritoryId(null);
    setEditForm({
      name: '',
      description: '',
      colorHex: TERRITORY_COLORS[territories.length % TERRITORY_COLORS.length],
      boundary: { type: 'zip_codes', zipCodes: [] },
      assignments: [],
      enableAutoSuggestion: true,
      loadBalancingEnabled: false,
      isActive: true,
    });
  }, [territories.length]);

  // Cancel create/edit
  const cancelEdit = useCallback(() => {
    setIsCreating(false);
    setEditForm({});
    if (selectedTerritory) {
      setEditForm({
        name: selectedTerritory.name,
        description: selectedTerritory.description,
        colorHex: selectedTerritory.colorHex,
        boundary: selectedTerritory.boundary,
        assignments: selectedTerritory.assignments,
        enableAutoSuggestion: selectedTerritory.enableAutoSuggestion,
        loadBalancingEnabled: selectedTerritory.loadBalancingEnabled,
        isActive: selectedTerritory.isActive,
      });
    }
  }, [selectedTerritory]);

  // Select territory for editing
  const selectTerritory = useCallback((territory: Territory) => {
    setIsCreating(false);
    setSelectedTerritoryId(territory.id);
    setEditForm({
      name: territory.name,
      description: territory.description,
      colorHex: territory.colorHex,
      boundary: territory.boundary,
      assignments: territory.assignments,
      enableAutoSuggestion: territory.enableAutoSuggestion,
      loadBalancingEnabled: territory.loadBalancingEnabled,
      isActive: territory.isActive,
    });
  }, []);

  // Save territory (create or update)
  const handleSave = useCallback(async () => {
    if (!editForm.name?.trim()) return;

    try {
      if (isCreating) {
        const created = await createTerritory(editForm);
        setIsCreating(false);
        setSelectedTerritoryId(created.id);
      } else if (selectedTerritoryId) {
        await updateTerritory(selectedTerritoryId, editForm);
      }
      refresh();
    } catch {
      // Error handled in hook
    }
  }, [isCreating, editForm, selectedTerritoryId, createTerritory, updateTerritory, refresh]);

  // Delete territory
  const handleDelete = useCallback(async () => {
    const territoryId = deleteModal.data;
    if (!territoryId) return;

    try {
      await deleteTerritory(territoryId);
      if (selectedTerritoryId === territoryId) {
        setSelectedTerritoryId(null);
        setEditForm({});
      }
      deleteModal.close();
      refresh();
    } catch {
      // Error handled in hook
    }
  }, [deleteModal, deleteTerritory, selectedTerritoryId, refresh]);

  // Update form field
  const updateField = useCallback(<K extends keyof Territory>(field: K, value: Territory[K]) => {
    setEditForm((prev) => ({ ...prev, [field]: value }));
  }, []);

  // Active vs inactive territories
  const activeTerritories = useMemo(
    () => territories.filter((t) => t.isActive),
    [territories]
  );
  const inactiveTerritories = useMemo(
    () => territories.filter((t) => !t.isActive),
    [territories]
  );

  if (isLoading) {
    return (
      <PageLayout width="wide" className="territories-page">
        <PageHeader
          eyebrow="Routing"
          title="Territories"
          subtitle="Manage territory boundaries, territory assignments, and routing preferences."
        />
        <Card padding="lg">
          <div className="loading-state">
            <p>Loading territories...</p>
          </div>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="territories-page">
      <PageHeader
        eyebrow="Routing"
        title="Territories"
        subtitle="Define staff coverage regions, assignment rules, and boundary logic for route planning and auto-assignment."
        actions={(
          <div className="territories-page__actions">
            <Button variant="secondary" onClick={refresh} disabled={mutationLoading}>
              Refresh
            </Button>
            <Button onClick={startCreate} disabled={mutationLoading}>
              New Territory
            </Button>
          </div>
        )}
      />

      <Card className="territories-page__hero" padding="lg" tone="accent">
        <div className="territories-page__hero-copy">
          <p className="ui-empty-state__eyebrow">Coverage Snapshot</p>
          <h2>{selectedTerritory?.name || (isCreating ? 'New territory draft' : 'Territory workspace')}</h2>
          <p>
            Review active and inactive territory coverage, then adjust boundaries and staff
            assignments from the editor workspace.
          </p>
        </div>
        <div className="territories-page__hero-stats">
          <div>
            <span>Active</span>
            <strong>{activeTerritories.length}</strong>
          </div>
          <div>
            <span>Inactive</span>
            <strong>{inactiveTerritories.length}</strong>
          </div>
          <div>
            <span>Staff</span>
            <strong>{members.length}</strong>
          </div>
        </div>
      </Card>

      <div className="territories-page__layout">
        {/* Territory List */}
        <Card className="territory-list-panel" padding="lg" tone="subtle">
          {activeTerritories.length > 0 && (
            <div className="territory-section">
              <h3 className="territory-section-title">Active Territories</h3>
              <div className="territory-list">
                {activeTerritories.map((territory) => (
                  <div
                    key={territory.id}
                    className={`territory-list-item ${selectedTerritoryId === territory.id ? 'territory-list-item--selected' : ''}`}
                    onClick={() => selectTerritory(territory)}
                  >
                    <div
                      className="territory-color-bar"
                      style={{ backgroundColor: territory.colorHex }}
                    />
                    <div className="territory-list-item__info">
                      <div className="territory-list-item__name">{territory.name}</div>
                      <div className="territory-list-item__meta">
                        {territory.boundary.type === 'zip_codes' &&
                          `${territory.boundary.zipCodes?.length ?? 0} zip codes`}
                        {territory.boundary.type === 'radius' &&
                          `${territory.boundary.radiusKm ?? 0}km radius`}
                        {' • '}
                        {territory.assignments.length} staff
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {inactiveTerritories.length > 0 && (
            <div className="territory-section territory-section--inactive">
              <h3 className="territory-section-title">Inactive</h3>
              <div className="territory-list">
                {inactiveTerritories.map((territory) => (
                  <div
                    key={territory.id}
                    className={`territory-list-item territory-list-item--inactive ${selectedTerritoryId === territory.id ? 'territory-list-item--selected' : ''}`}
                    onClick={() => selectTerritory(territory)}
                  >
                    <div
                      className="territory-color-bar"
                      style={{ backgroundColor: territory.colorHex, opacity: 0.5 }}
                    />
                    <div className="territory-list-item__info">
                      <div className="territory-list-item__name">{territory.name}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {territories.length === 0 && (
            <EmptyState
              eyebrow="Territories"
              title="No territories defined yet"
              description="Create territories to organize sales regions and auto-assign contacts to staff."
              actions={<Button onClick={startCreate}>Create Territory</Button>}
            />
          )}
        </Card>

        {/* Territory Editor */}
        <Card className="territory-editor-panel" padding="lg">
          {!selectedTerritoryId && !isCreating ? (
            <EmptyState
              eyebrow="Editor"
              title="Select a territory"
              description="Choose a territory from the list to edit its boundary and staff assignments, or create a new one."
            />
          ) : (
            <div className="territory-editor">
              <div className="territory-editor__header">
                <h2>{isCreating ? 'New Territory' : 'Edit Territory'}</h2>
                {!isCreating && selectedTerritoryId && (
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => deleteModal.open(selectedTerritoryId)}
                    disabled={mutationLoading}
                  >
                    Delete
                  </Button>
                )}
              </div>

              {/* Basic Info */}
              <section className="territory-section-form">
                <h3>Basic Information</h3>
                <div className="territory-form-grid">
                  <div className="form-group">
                    <label>Territory Name *</label>
                    <input
                      type="text"
                      value={editForm.name ?? ''}
                      onChange={(e) => updateField('name', e.target.value)}
                      placeholder="e.g., North Region"
                      disabled={mutationLoading}
                    />
                  </div>

                  <div className="form-group">
                    <label>Color</label>
                    <div className="color-picker-row">
                      <input
                        type="color"
                        value={editForm.colorHex ?? '#3b82f6'}
                        onChange={(e) => updateField('colorHex', e.target.value)}
                        disabled={mutationLoading}
                        className="color-input"
                      />
                      <div className="color-presets">
                        {TERRITORY_COLORS.map((color) => (
                          <button
                            key={color}
                            type="button"
                            className={`color-preset ${editForm.colorHex === color ? 'color-preset--active' : ''}`}
                            style={{ backgroundColor: color }}
                            onClick={() => updateField('colorHex', color)}
                            disabled={mutationLoading}
                          />
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className="form-group form-group--full">
                    <label>Description</label>
                    <textarea
                      value={editForm.description ?? ''}
                      onChange={(e) => updateField('description', e.target.value)}
                      placeholder="Optional description of this territory"
                      rows={2}
                      disabled={mutationLoading}
                    />
                  </div>

                  <div className="form-group">
                    <label className="checkbox-label">
                      <input
                        type="checkbox"
                        checked={editForm.isActive ?? true}
                        onChange={(e) => updateField('isActive', e.target.checked)}
                        disabled={mutationLoading}
                      />
                      Active
                    </label>
                    <span className="form-hint">Inactive territories won't be used for auto-assignment</span>
                  </div>

                  <div className="form-group">
                    <label className="checkbox-label">
                      <input
                        type="checkbox"
                        checked={editForm.enableAutoSuggestion ?? true}
                        onChange={(e) => updateField('enableAutoSuggestion', e.target.checked)}
                        disabled={mutationLoading}
                      />
                      Enable Auto-Suggestion
                    </label>
                    <span className="form-hint">Automatically suggest staff for contacts in this territory</span>
                  </div>
                </div>
              </section>

              {/* Boundary */}
              <section className="territory-section-form">
                <h3>Territory Boundary</h3>
                <BoundaryEditor
                  boundary={editForm.boundary ?? { type: 'zip_codes', zipCodes: [] }}
                  onChange={(boundary) => updateField('boundary', boundary)}
                  disabled={mutationLoading}
                />
              </section>

              {/* Staff Assignments */}
              <section className="territory-section-form">
                <h3>Staff Assignments</h3>
                <StaffAssignmentPanel
                  assignments={editForm.assignments ?? []}
                  teamMembers={members}
                  onChange={(assignments) => updateField('assignments', assignments)}
                  disabled={mutationLoading}
                />
              </section>

              {/* Actions */}
              <div className="territory-editor__actions">
                <Button
                  variant="secondary"
                  onClick={cancelEdit}
                  disabled={mutationLoading}
                >
                  Cancel
                </Button>
                <Button
                  onClick={handleSave}
                  disabled={mutationLoading || !editForm.name?.trim()}
                >
                  {mutationLoading ? 'Saving...' : isCreating ? 'Create Territory' : 'Save Changes'}
                </Button>
              </div>
            </div>
          )}
        </Card>
      </div>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onCancel={deleteModal.close}
        onConfirm={handleDelete}
        title="Delete Territory"
        message="Are you sure you want to delete this territory? Staff assignments will be removed."
        confirmText={mutationLoading ? 'Deleting...' : 'Delete'}
        variant="danger"
      />
    </PageLayout>
  );
}

export default TerritoriesPage;
