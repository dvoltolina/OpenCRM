/**
 * PipelinePage Component
 * Main pipeline view with kanban board for deal management
 *
 * Agent CRM-25 Implementation
 * Dependencies: CRM-16 (kanban components), CRM-12 (deal stage service), CRM-23 (pages wired)
 */

import { useCallback, useMemo, useState } from 'react';
import type { FormEvent } from 'react';
import { usePipelineWithStages } from '../hooks/usePipelineWithStages';
import { KanbanBoard } from '../components/pipeline/KanbanBoard';
import type { Deal } from '../types/models';
import { useModal, useTeamMembers } from '../hooks';
import { CreateDealModal } from '../components/modals';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { createSecurityContextFromParams, getShareableAccessSummary, type ShareableAccessSummary } from '../lib/security-context';
import { useActivityLog } from '../hooks/useActivityLog';
import { applyTaskTemplate, getDefaultTaskTemplate, getTaskTemplates } from '../config/taskTemplates';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';

/**
 * PipelinePage - Main pipeline kanban view
 *
 * Features:
 * - Displays opportunities grouped by stage in a kanban board
 * - Supports drag-and-drop to move opportunities between stages
 * - Shows pipeline metrics (total opportunities, total value)
 * - Handles loading and error states
 *
 * @example
 * ```tsx
 * // In App.tsx routing
 * <Route path="/pipeline" element={<PipelinePage />} />
 * ```
 */
export function PipelinePage() {
  const [boardRefreshKey, setBoardRefreshKey] = useState(0);
  const createDealModal = useModal<{ stageId?: string }>();
  const editDealModal = useModal<Deal>();
  const navigate = useNavigate();
  const { crmUser } = useAuth();

  // Rep filter for Pipeline view
  // Staff users see only their own deals, managers can filter or see all
  const { members: teamMembers, isLoading: isLoadingTeam } = useTeamMembers();
  const [selectedRepUid, setSelectedRepUid] = useState<string>('');

  // Determine if user is a manager or above (can see all reps)
  const isManager = useMemo(() => {
    const role = crmUser?.role;
    return role === 'owner' || role === 'admin' || role === 'manager';
  }, [crmUser?.role]);

  // Get the effective rep filter:
  // - Staff users: always filter by their own UID
  // - Managers: use selectedRepUid (empty means all)
  const effectiveRepFilter = useMemo(() => {
    if (!isManager) {
      // Staff sees only their own opportunities
      return crmUser?.id || '';
    }
    return selectedRepUid; // Empty string means no filter (all)
  }, [isManager, crmUser?.id, selectedRepUid]);
  const selectedRepLabel = useMemo(() => {
    if (!selectedRepUid) return 'All active reps';
    const selectedMember = teamMembers.find((member) => member.id === selectedRepUid);
    if (!selectedMember) return 'Selected rep';
    return `${selectedMember.firstName} ${selectedMember.lastName}`;
  }, [selectedRepUid, teamMembers]);

  // Fetch default pipeline with stages
  const {
    pipeline,
    stages,
    isLoading,
    error,
    refresh,
    canCreatePipeline,
    createDefaultPipeline,
  } = usePipelineWithStages();
  const [isCreatingPipeline, setIsCreatingPipeline] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);
  const [quickNoteTarget, setQuickNoteTarget] = useState<{ deal: Deal; stageId: string } | null>(null);
  const [quickNoteText, setQuickNoteText] = useState('');
  const [quickNoteError, setQuickNoteError] = useState<string | null>(null);
  const { createTask, logNote, isLoading: isLoggingActivity } = useActivityLog();
  const dealContext = useMemo(
    () => {
      if (!crmUser || !crmUser.businessId) return null;
      try {
        return createSecurityContextFromParams(
          crmUser.businessId,
          crmUser.id,
          crmUser.displayName || crmUser.email || 'Unknown User',
          crmUser.role,
          crmUser.teamIds,
          crmUser.managedTeamIds,
          crmUser.managerId
        );
      } catch {
        return null;
      }
    },
    [crmUser]
  );
  const pipelineAccess: ShareableAccessSummary | null = useMemo(() => {
    if (!pipeline || !dealContext) return null;
    try {
      return getShareableAccessSummary(dealContext, pipeline);
    } catch {
      return null;
    }
  }, [pipeline, dealContext]);
  const canCreateDeals = pipelineAccess ? pipelineAccess.canWrite : true;
  const canMoveDeal = useCallback(
    (deal: Deal) => {
      if (!dealContext) return false;
      const summary = getShareableAccessSummary(dealContext, deal);
      return summary?.canWrite ?? false;
    },
    [dealContext]
  );

  const pipelinesForModal = useMemo(() => (pipeline ? [pipeline] : []), [pipeline]);
  const getStageName = useCallback(
    (stageId: string) => stages.find((stage) => stage.id === stageId)?.name,
    [stages]
  );

  // Modal state for deal interactions
  // const [selectedDealId, setSelectedDealId] = useState<string | null>(null);

  // Handle deal card click
  const handleDealClick = useCallback((deal: Deal) => {
    editDealModal.open(deal);
  }, [editDealModal]);

  const handleViewDeals = useCallback(() => {
    navigate('/deals');
  }, [navigate]);

  // Handle add deal button click
  const handleAddDeal = useCallback((stageId: string) => {
    if (!canCreateDeals) return;
    createDealModal.open({ stageId });
  }, [createDealModal, canCreateDeals]);

  const handleDealSaved = useCallback(() => {
    setBoardRefreshKey((prev) => prev + 1);
    createDealModal.close();
    editDealModal.close();
  }, [createDealModal, editDealModal]);

  const handleQuickTask = useCallback(
    async (deal: Deal, stageId: string) => {
      if (isLoggingActivity) return;
      const stageName = getStageName(stageId);
      const templates = getTaskTemplates(stageName, pipeline?.id);
      const templateId = getDefaultTaskTemplate(stageName, pipeline?.id)?.id || templates[0]?.id;
      const selectedTemplate = templates.find((t) => t.id === templateId);
      const applied = selectedTemplate ? applyTaskTemplate(selectedTemplate) : undefined;

      const dueDate =
        applied?.dueDate || new Date(Date.now() + 24 * 60 * 60 * 1000);

      const created = await createTask({
        title: applied?.title || `Follow up: ${deal.title}`,
        dealId: deal.id,
        clientId: deal.clientId,
        companyId: deal.companyId,
        dueDate,
        assigneeId: deal.assigneeId,
        assigneeName: deal.assigneeName,
        templateId: applied?.templateId,
        slaMinutes: applied?.slaMinutes,
        slaAt: applied?.slaAt,
        reminderAt: applied?.reminderAt,
      });
      if (created) {
        setBoardRefreshKey((prev) => prev + 1);
      }
    },
    [createTask, getStageName, isLoggingActivity, pipeline?.id]
  );

  const handleQuickNote = useCallback(
    (deal: Deal, stageId: string) => {
      if (isLoggingActivity) return;
      setQuickNoteTarget({ deal, stageId });
      setQuickNoteText('');
      setQuickNoteError(null);
    },
    [isLoggingActivity]
  );

  const submitQuickNote = useCallback(
    async (e: FormEvent) => {
      e.preventDefault();
      if (!quickNoteTarget) return;
      const trimmed = quickNoteText.trim();
      if (!trimmed) {
        setQuickNoteError('Add a short note before saving');
        return;
      }

      const created = await logNote(quickNoteTarget.deal.id, 'deal', trimmed);
      if (created) {
        setBoardRefreshKey((prev) => prev + 1);
        setQuickNoteTarget(null);
        setQuickNoteText('');
        setQuickNoteError(null);
      } else {
        setQuickNoteError('Unable to save note right now');
      }
    },
    [logNote, quickNoteTarget, quickNoteText]
  );

  // Loading state
  if (isLoading) {
    return (
      <PageLayout width="wide" className="pipeline-page">
        <PageHeader
          eyebrow="Revenue operations"
          title="Pipeline"
          subtitle="Review stage movement, coach rep execution, and keep forecast visibility current."
          actions={(
            <>
              <Button variant="secondary" onClick={handleViewDeals}>
                Opportunity list
              </Button>
              <Button disabled>
                New Opportunity
              </Button>
            </>
          )}
        />
        <Card className="loading-state">
          <p>Loading pipeline...</p>
        </Card>
      </PageLayout>
    );
  }

  // Error state
  if (error) {
    return (
      <PageLayout width="wide" className="pipeline-page">
        <PageHeader
          eyebrow="Revenue operations"
          title="Pipeline"
          subtitle="Review stage movement, coach rep execution, and keep forecast visibility current."
          actions={(
            <>
              <Button variant="secondary" onClick={handleViewDeals}>
                Opportunity list
              </Button>
              <Button disabled>
                New Opportunity
              </Button>
            </>
          )}
        />
        <Card className="error-state">
          <p>Unable to load the pipeline board.</p>
          <p>{error.message}</p>
          <Button onClick={refresh}>
            Try Again
          </Button>
        </Card>
      </PageLayout>
    );
  }

  // No pipeline state
  if (!pipeline) {
    const handleCreatePipeline = async () => {
      if (!canCreatePipeline) {
        navigate('/settings?tab=pipeline');
        return;
      }
      setIsCreatingPipeline(true);
      setCreateError(null);
      try {
        await createDefaultPipeline();
        setBoardRefreshKey((prev) => prev + 1);
      } catch (err) {
        setCreateError(err instanceof Error ? err.message : 'Failed to create pipeline');
      } finally {
        setIsCreatingPipeline(false);
      }
    };

    return (
      <PageLayout width="wide" className="pipeline-page">
        <PageHeader
          eyebrow="Revenue operations"
          title="Pipeline"
          subtitle="Review stage movement, coach rep execution, and keep forecast visibility current."
          actions={(
            <Button variant="secondary" onClick={handleViewDeals}>
              Opportunity list
            </Button>
          )}
        />
        <Card>
          <EmptyState
            eyebrow="Pipeline setup"
            title="No pipeline is configured yet"
            description="Create the default pipeline to start tracking opportunities by stage and give managers a clean board view."
            actions={(
              <Button onClick={handleCreatePipeline} disabled={isCreatingPipeline}>
                {canCreatePipeline
                  ? (isCreatingPipeline ? 'Creating...' : 'Create Pipeline')
                  : 'Go to Settings'}
              </Button>
            )}
          >
            <p>
              {canCreatePipeline
                ? 'You can create the initial pipeline from here.'
                : 'You need pipeline access. Ask an admin to create it or open settings to review access.'}
            </p>
            {createError ? <p className="error-text">{createError}</p> : null}
          </EmptyState>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="pipeline-page">
      <PageHeader
        eyebrow="Revenue operations"
        title="Pipeline"
        subtitle="Monitor deal flow, review weighted revenue, and intervene quickly when stages stall."
        actions={(
          <>
            <Button variant="secondary" onClick={handleViewDeals}>
              Opportunity list
            </Button>
            <Button
              onClick={() => handleAddDeal(pipeline.id)}
              disabled={!canCreateDeals}
              title={
                !canCreateDeals
                  ? 'Read-only: pipeline not shared to you or your teams'
                  : undefined
              }
            >
              New Opportunity
            </Button>
          </>
        )}
      />

      {pipelineAccess && !pipelineAccess.canWrite && (
        <div className="alert alert-warning" role="status" data-testid="pipeline-readonly-banner">
          Read-only pipeline: you can view opportunities but cannot create or move them (not shared to your teams).
        </div>
      )}

      {isManager && (
        <Toolbar
          className="page-filters pipeline-page__filters"
          start={(
            <div className="pipeline-filter-group">
              <label htmlFor="rep-filter" className="pipeline-filter-label">
                Assigned rep
              </label>
              <select
                id="rep-filter"
                className="filter-select"
                value={selectedRepUid}
                onChange={(e) => setSelectedRepUid(e.target.value)}
                disabled={isLoadingTeam}
              >
                <option value="">All Reps</option>
                {teamMembers.filter((member) => member.isActive).map((member) => (
                  <option key={member.id} value={member.id}>
                    {member.firstName} {member.lastName}
                    {member.role !== 'staff' ? ` (${member.role})` : ''}
                  </option>
                ))}
              </select>
            </div>
          )}
          end={<span className="ui-results-count">Showing {selectedRepLabel}</span>}
        />
      )}

      <div className="pipeline-content">
        <KanbanBoard
          key={`${boardRefreshKey}-${effectiveRepFilter}`}
          pipeline={pipeline}
          onDealClick={handleDealClick}
          onAddDeal={canCreateDeals ? handleAddDeal : undefined}
          onQuickTask={canCreateDeals ? handleQuickTask : undefined}
          onQuickNote={canCreateDeals ? handleQuickNote : undefined}
          canMoveDeal={canMoveDeal}
          readOnlyReason={
            pipelineAccess && !pipelineAccess.canWrite
              ? 'Read-only: pipeline not shared to you or your teams'
              : undefined
          }
          currency="USD"
          assignedRepUid={effectiveRepFilter || undefined}
        />
      </div>

      {quickNoteTarget && (
        <div className="inline-note-composer" data-testid="pipeline-quick-note">
          <div className="inline-note-composer__header">
            <div>
              <strong>Quick note</strong> for <span>{quickNoteTarget.deal.title}</span>
              {quickNoteTarget.stageId && (
                <span className="inline-note-composer__meta">
                  {' '}
                  ({getStageName(quickNoteTarget.stageId) || 'Selected stage'})
                </span>
              )}
            </div>
            <Button
              variant="ghost"
              onClick={() => {
                setQuickNoteTarget(null);
                setQuickNoteText('');
                setQuickNoteError(null);
              }}
              disabled={isLoggingActivity}
            >
              Cancel
            </Button>
          </div>
          <form onSubmit={submitQuickNote} className="inline-note-composer__form">
            <label className="sr-only" htmlFor="pipeline-quick-note-input">
              Quick note text
            </label>
            <textarea
              id="pipeline-quick-note-input"
              value={quickNoteText}
              onChange={(e) => {
                setQuickNoteText(e.target.value);
                if (quickNoteError) setQuickNoteError(null);
              }}
              placeholder="Capture a quick update without leaving the board"
              rows={3}
              onKeyDown={(e) => {
                if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                  submitQuickNote(e);
                }
              }}
              disabled={isLoggingActivity}
            />
            {quickNoteError && <div className="form-error">{quickNoteError}</div>}
            <div className="inline-note-composer__actions">
              <Button type="submit" disabled={isLoggingActivity}>
                Save note
              </Button>
              <span className="inline-note-composer__hint">Ctrl/Cmd + Enter to save</span>
            </div>
          </form>
        </div>
      )}

      <CreateDealModal
        isOpen={createDealModal.isOpen || editDealModal.isOpen}
        onClose={() => {
          createDealModal.close();
          editDealModal.close();
        }}
        initialData={
          editDealModal.data
            ? editDealModal.data
            : pipeline && createDealModal.data?.stageId
              ? { stageId: createDealModal.data.stageId, pipelineId: pipeline.id }
              : undefined
        }
        pipelines={pipelinesForModal}
        stages={stages}
        onSuccess={handleDealSaved}
      />
    </PageLayout>
  );
}
