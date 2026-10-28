import type { Pipeline, ReportView } from '../../types/models';
import type { ReportFilterState } from '../../pages/report-utils';
import { parseCommaSeparated } from '../../pages/report-utils';
import { Button, Card, EmptyState } from '../ui';

interface ReportFiltersPanelProps {
  filters: ReportFilterState;
  setFilters: (updater: (prev: ReportFilterState) => ReportFilterState) => void;
  pipelines: Pipeline[];
  pipelinesLoading: boolean;
  stages: Array<{ id: string; name: string; pipelineId: string }>;
  handleStatusToggle: (status: 'open' | 'won' | 'lost') => void;
  myDealsOnly: boolean;
  onToggleMyDeals: () => void;
  views: ReportView[];
  viewsLoading: boolean;
  selectedViewId: string | null;
  applyView: (view: ReportView) => void;
  canManage: (view: ReportView) => boolean;
  savedViewsEnabled: boolean;
  onDeleteView: (id: string) => Promise<void>;
  onSaveView: () => Promise<void>;
  newViewName: string;
  setNewViewName: (value: string) => void;
  shareTeams: string;
  setShareTeams: (value: string) => void;
  actionError: string | null;
  onClearFilters: () => void;
  onClearViewSelection: () => void;
}

export function ReportFiltersPanel({
  filters,
  setFilters,
  pipelines,
  pipelinesLoading,
  stages,
  handleStatusToggle,
  myDealsOnly,
  onToggleMyDeals,
  views,
  viewsLoading,
  selectedViewId,
  applyView,
  canManage,
  savedViewsEnabled,
  onDeleteView,
  onSaveView,
  newViewName,
  setNewViewName,
  shareTeams,
  setShareTeams,
  actionError,
  onClearFilters,
  onClearViewSelection,
}: ReportFiltersPanelProps) {
  return (
    <section className="report-section reporting-page__filters-shell">
      <div className="reporting-page__section-header">
        <div>
          <h2>Filters & Saved Views</h2>
          <p>Refine the reporting window, then save the setup for later reuse across teams.</p>
        </div>
      </div>

      {actionError ? (
        <div className="reporting-page__error-banner" role="alert">
          <strong>Saved view action failed</strong>
          <p>{actionError}</p>
        </div>
      ) : null}

      <div className="reporting-page__filters-layout">
        <Card className="reporting-page__filter-panel" padding="lg">
          <div className="reporting-page__panel-heading">
            <div>
              <p className="reporting-page__panel-eyebrow">Live Filters</p>
              <h3>Scope the report dataset</h3>
            </div>
            <p>Pipeline, stage, ownership, and source filters update the charts and exports together.</p>
          </div>

          <div className="reporting-page__field-grid">
            <div className="reporting-page__field">
              <label htmlFor="pipeline-filter">Pipeline</label>
              <select
                id="pipeline-filter"
                className="reporting-page__field-control"
                value={filters.pipelineId}
                disabled={pipelinesLoading}
                onChange={(e) => setFilters((prev) => ({ ...prev, pipelineId: e.target.value }))}
              >
                <option value="">All pipelines</option>
                {pipelines.map((pipeline) => (
                  <option key={pipeline.id} value={pipeline.id}>
                    {pipeline.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="reporting-page__field">
              <label>Status</label>
              <div className="reporting-page__status-row">
                {(['open', 'won', 'lost'] as const).map((status) => (
                  <label key={status} className="reporting-page__status-pill">
                    <input
                      type="checkbox"
                      checked={filters.statuses.includes(status)}
                      onChange={() => handleStatusToggle(status)}
                    />
                    <span>{status.toUpperCase()}</span>
                  </label>
                ))}
              </div>
            </div>

            <div className="reporting-page__field">
              <label>Date Range</label>
              <div className="reporting-page__date-grid">
                <input
                  type="date"
                  className="reporting-page__field-control"
                  value={filters.startDate}
                  onChange={(e) => setFilters((prev) => ({ ...prev, startDate: e.target.value }))}
                  aria-label="Start date"
                />
                <input
                  type="date"
                  className="reporting-page__field-control"
                  value={filters.endDate}
                  onChange={(e) => setFilters((prev) => ({ ...prev, endDate: e.target.value }))}
                  aria-label="End date"
                />
              </div>
            </div>

            <div className="reporting-page__field">
              <label htmlFor="stage-filter">Stages</label>
              <select
                id="stage-filter"
                className="reporting-page__field-control reporting-page__field-control--multi"
                multiple
                value={filters.stageIds}
                onChange={(e) =>
                  setFilters((prev) => ({
                    ...prev,
                    stageIds: Array.from(e.target.selectedOptions).map((option) => option.value),
                  }))
                }
              >
                {stages.map((stage) => (
                  <option key={stage.id} value={stage.id}>
                    {stage.name}
                  </option>
                ))}
              </select>
              <small>Hold Cmd/Ctrl to select multiple.</small>
            </div>

            <div className="reporting-page__field">
              <label htmlFor="owner-filter">Owner IDs</label>
              <input
                id="owner-filter"
                type="text"
                className="reporting-page__field-control"
                placeholder="owner-a, owner-b"
                value={filters.ownerIds.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, ownerIds: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>

            <div className="reporting-page__field">
              <label htmlFor="team-filter">Team IDs</label>
              <input
                id="team-filter"
                type="text"
                className="reporting-page__field-control"
                placeholder="team-a, team-b"
                value={filters.teamIds.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, teamIds: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>

            <div className="reporting-page__field">
              <label htmlFor="lead-source-filter">Lead sources</label>
              <input
                id="lead-source-filter"
                type="text"
                className="reporting-page__field-control"
                placeholder="referral, website"
                value={filters.leadSources.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, leadSources: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>

            <div className="reporting-page__field">
              <label htmlFor="assignee-filter">Assignee IDs</label>
              <input
                id="assignee-filter"
                type="text"
                className="reporting-page__field-control"
                placeholder="user-123"
                value={filters.assigneeIds.join(', ')}
                onChange={(e) =>
                  setFilters((prev) => ({ ...prev, assigneeIds: parseCommaSeparated(e.target.value) }))
                }
              />
            </div>
          </div>

          <div className="reporting-page__filters-actions">
            <label className="reporting-page__toggle-pill" htmlFor="my-deals-only">
              <input
                id="my-deals-only"
                type="checkbox"
                checked={myDealsOnly}
                onChange={onToggleMyDeals}
                aria-label="My deals only"
              />
              <span>My deals only</span>
            </label>
            <Button variant="secondary" onClick={onClearFilters}>
              Clear filters
            </Button>
          </div>
        </Card>

        <Card className="reporting-page__saved-views-panel" padding="lg" tone="subtle">
          {savedViewsEnabled ? (
            <>
              <div className="reporting-page__panel-heading reporting-page__panel-heading--saved">
                <div>
                  <p className="reporting-page__panel-eyebrow">Saved Views</p>
                  <h3>Reuse common report setups</h3>
                </div>
                <p>Owners and admins can manage shared views while teams can load them instantly.</p>
              </div>

              <div className="reporting-page__saved-views-actions">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    onClearViewSelection();
                    onClearFilters();
                  }}
                >
                  Clear selection
                </Button>
              </div>

              <div className="reporting-page__saved-views-list">
                {viewsLoading ? (
                  <p className="reporting-page__saved-views-state">Loading saved views...</p>
                ) : views.length === 0 ? (
                  <EmptyState
                    className="reporting-page__saved-views-empty"
                    eyebrow="No Saved Views"
                    title="No saved views yet"
                    description="Save a filter combination to reuse it across exports, dashboards, and team reviews."
                  />
                ) : (
                  <ul className="reporting-page__saved-views-items">
                    {views.map((view) => (
                      <li
                        key={view.id}
                        className={`reporting-page__saved-view-item ${view.id === selectedViewId ? 'is-active' : ''}`}
                      >
                        <div className="reporting-page__saved-view-copy">
                          <button
                            type="button"
                            className="reporting-page__saved-view-button"
                            onClick={() => applyView(view)}
                          >
                            {view.name}
                          </button>
                          <div className="reporting-page__saved-view-meta">
                            {view.ownerName || 'Unknown owner'} · {view.teamIds?.length || 0} teams
                            {view.visibility ? ` · ${view.visibility}` : ''}
                          </div>
                        </div>
                        {canManage(view) ? (
                          <Button
                            variant="ghost"
                            size="sm"
                            aria-label={`Delete ${view.name}`}
                            onClick={() => onDeleteView(view.id)}
                          >
                            Delete
                          </Button>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div className="reporting-page__saved-views-form">
                <div className="reporting-page__field">
                  <label htmlFor="saved-view-name">View name</label>
                  <input
                    id="saved-view-name"
                    type="text"
                    className="reporting-page__field-control"
                    placeholder="View name"
                    value={newViewName}
                    onChange={(e) => setNewViewName(e.target.value)}
                  />
                </div>
                <div className="reporting-page__field">
                  <label htmlFor="saved-view-share-teams">Share with team IDs</label>
                  <input
                    id="saved-view-share-teams"
                    type="text"
                    className="reporting-page__field-control"
                    placeholder="team-alpha, team-beta"
                    value={shareTeams}
                    onChange={(e) => setShareTeams(e.target.value)}
                  />
                </div>
                <Button variant="primary" onClick={onSaveView}>
                  Save view
                </Button>
              </div>
            </>
          ) : (
            <EmptyState
              eyebrow="Saved Views"
              title="Saved views are disabled"
              description="Set VITE_ENABLE_REPORT_SAVED_VIEWS=true to enable saved reports for this environment."
              className="reporting-page__saved-views-empty"
            />
          )}
        </Card>
      </div>
    </section>
  );
}

export default ReportFiltersPanel;
