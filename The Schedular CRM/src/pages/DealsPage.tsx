import { useEffect, useMemo, useState } from 'react';
import type { Deal, DealStatus } from '../types/models';
import {
  useDeals,
  useDealMutations,
  usePipelines,
  useStages,
  useModal,
  type DealFilters,
} from '../hooks';
import { formatCurrency } from '../utils/formatting';
import { CreateDealModal } from '../components/modals';
import { CSVImportModal } from '../components/import';
import PayNowButton from '../components/payments/PayNowButton';
import { DealDetail } from '../components/details';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  canWriteShareableEntity,
  createSecurityContext,
  type ShareableAccessSummary,
} from '../lib/security-context';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';

const statusOptions: { value: DealStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All Opportunities' },
  { value: 'open', label: 'Open' },
  { value: 'won', label: 'Won' },
  { value: 'lost', label: 'Lost' },
];

export function DealsPage() {
  const [statusFilter, setStatusFilter] = useState<DealStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const createModal = useModal();
  const editModal = useModal<Deal>();
  const lostModal = useModal<Deal>();
  const importModal = useModal();
  const [lostReason, setLostReason] = useState('');
  const [lostReasonError, setLostReasonError] = useState<string | null>(null);
  const { pipelines } = usePipelines();
  const [pipelineForStages, setPipelineForStages] = useState<string>('');
  const { stages } = useStages(pipelineForStages || pipelines[0]?.id);
  const payNowEnabled = import.meta.env?.VITE_ENABLE_PAY_NOW === 'true';
  const navigate = useNavigate();
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );
  const canCreate = Boolean(securityContext);
  const createDisabledReason =
    !canCreate ? 'You do not have permission to create opportunities' : undefined;
  const getDealAccess = (deal: Deal): ShareableAccessSummary | null =>
    getAccessSummary ? getAccessSummary(deal) : null;
  const canWriteDeal = (deal: Deal) => {
    const summary = getDealAccess(deal);
    if (summary) return summary.canWrite;
    return Boolean(securityContext && canWriteShareableEntity(securityContext, deal));
  };
  const readOnlyReason = (deal: Deal) => {
    const summary = getDealAccess(deal);
    if (!summary || summary.canWrite) return undefined;
    if (summary.visibility === 'org' && !summary.hasTeamAccess) return 'Read-only: org-visible only';
    return 'Read-only: not shared to you or your teams';
  };

  const MAX_LOSS_REASON = 180;
  const payNowWarning =
    !payNowEnabled ?
      'Pay Now is disabled until the shared Scheduler payment confirmation flow is validated for this environment. Set VITE_ENABLE_PAY_NOW=true only after that verification.' :
      '';
  const filters: DealFilters = {
    status: statusFilter !== 'all' ? statusFilter : undefined,
    search: searchQuery || undefined,
  };

  const {
    deals,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
    getAccessSummary,
  } = useDeals(filters);
  const dealCountLabel = deals.length === 1 ? '1 opportunity' : `${deals.length} opportunities`;

  const {
    isLoading: isMutating,
    markWon,
    markLost,
  } = useDealMutations();
  const detailModal = useModal<Deal>();

  useEffect(() => {
    if (!pipelineForStages && pipelines.length > 0) {
      setPipelineForStages(pipelines[0].id);
    }
  }, [pipelineForStages, pipelines]);

  const handleCreateClick = () => {
    if (!canCreate) return;
    if (pipelines[0]) {
      setPipelineForStages(pipelines[0].id);
    }
    createModal.open();
  };

  const handleEditClick = (deal: Deal) => {
    setPipelineForStages(deal.pipelineId);
    editModal.open(deal);
  };

  const handleViewClick = (deal: Deal) => {
    navigate(`/deals/${deal.id}`);
  };

  const handleMarkWon = async (deal: Deal) => {
    if (!canWriteDeal(deal)) return;
    await markWon(deal.id, 'Won from dashboard');
    refresh();
  };

  const handleMarkLost = async (deal: Deal) => {
    if (!canWriteDeal(deal)) return;
    setLostReason('');
    setLostReasonError(null);
    lostModal.open(deal);
  };

  if (isLoading) {
    return (
      <PageLayout className="deals-page">
        <PageHeader
          eyebrow="Pipeline"
          title="Opportunities"
          subtitle="Track active revenue, monitor stage movement, and keep close dates realistic."
          actions={(
            <Button disabled={isMutating || !canCreate} onClick={handleCreateClick} title={createDisabledReason}>
              New Opportunity
            </Button>
          )}
        />
        <Card className="loading-state">
          <p>Loading opportunities...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error) {
    return (
      <PageLayout className="deals-page">
        <PageHeader
          eyebrow="Pipeline"
          title="Opportunities"
          subtitle="Track active revenue, monitor stage movement, and keep close dates realistic."
          actions={(
            <Button disabled={isMutating || !canCreate} onClick={handleCreateClick} title={createDisabledReason}>
              New Opportunity
            </Button>
          )}
        />
        <Card className="error-state">
          <p>Error loading opportunities: {error.message}</p>
          <Button onClick={refresh}>
            Retry
          </Button>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout className="deals-page">
      <PageHeader
        eyebrow="Pipeline"
        title="Opportunities"
        subtitle="Review active deals, update outcomes, and keep revenue forecasting current."
        actions={(
          <>
            <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
              Import CSV
            </Button>
            <Button
              disabled={isMutating || !canCreate}
              onClick={handleCreateClick}
              title={createDisabledReason}
            >
              New Opportunity
            </Button>
          </>
        )}
      />

      {!payNowEnabled && (
        <div className="alert alert-warning" role="status">
          {payNowWarning}
        </div>
      )}

      <Toolbar
        className="page-filters"
        start={(
          <>
            <input
              type="text"
              placeholder="Search opportunities..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as DealStatus | 'all')}
              className="filter-select"
            >
              {statusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </>
        )}
        end={<span className="ui-results-count">{dealCountLabel}</span>}
      />

      <div className="data-table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Opportunity Name</th>
              <th>Value</th>
              <th>Contact</th>
              <th>Stage</th>
              <th>Status</th>
              <th>Expected Close</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {deals.length === 0 ? (
              <tr>
                <td colSpan={7} className="empty-state">
                  <EmptyState
                    eyebrow="Revenue tracking"
                    title="No opportunities yet"
                    description="Import existing pipeline data or create the first opportunity manually to start stage-based tracking."
                    actions={(
                      <>
                        <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
                          Import CSV
                        </Button>
                        <Button
                          disabled={isMutating || !canCreate}
                          onClick={handleCreateClick}
                          title={createDisabledReason}
                        >
                          New Opportunity
                        </Button>
                      </>
                    )}
                  />
                </td>
              </tr>
            ) : (
              deals.map((deal) => (
                <tr key={deal.id}>
                  <td>
                    <button
                      className="link-button"
                      type="button"
                      onClick={() => navigate(`/deals/${deal.id}`)}
                    >
                      {deal.title}
                    </button>
                  </td>
                  <td>
                    {deal.valueCents != null
                      ? formatCurrency(deal.valueCents, deal.currency)
                      : '—'}
                  </td>
                  <td>{deal.clientName || '-'}</td>
                  <td>{deal.stageId}</td>
                  <td>
                    <span className={`status-badge status-${deal.status}`}>
                      {deal.status}
                    </span>
                  </td>
                  <td>
                    {deal.expectedCloseDate
                      ? deal.expectedCloseDate.toLocaleDateString()
                      : '-'}
                  </td>
                  <td>
                    <div className="table-actions">
                      <button
                        className="btn btn-ghost btn-sm"
                        onClick={() => handleViewClick(deal)}
                        disabled={isMutating}
                      >
                        View
                      </button>
                      <button
                        className="btn btn-ghost btn-sm"
                        disabled={isMutating || !canWriteDeal(deal)}
                        onClick={() => handleEditClick(deal)}
                        title={readOnlyReason(deal)}
                      >
                        Edit
                      </button>
                      {deal.status === 'open' && (
                        <>
                          <button
                            className="btn btn-ghost btn-sm"
                            disabled={isMutating || !canWriteDeal(deal)}
                            onClick={() => handleMarkWon(deal)}
                            title={readOnlyReason(deal)}
                          >
                            Mark Won
                          </button>
                          <button
                            className="btn btn-ghost btn-sm"
                            disabled={isMutating || !canWriteDeal(deal)}
                            onClick={() => handleMarkLost(deal)}
                            title={readOnlyReason(deal)}
                          >
                            Mark Lost
                          </button>
                        </>
                      )}
                      {payNowEnabled && deal.clientId && (
                        <PayNowButton
                          clientId={deal.clientId}
                          clientName={deal.clientName || 'Client'}
                          dealId={deal.id}
                          dealTitle={deal.title}
                          amount={deal.valueCents}
                          currency={deal.currency}
                          variant="outline"
                          size="sm"
                          label="Pay Now"
                          disabled={isMutating || !canWriteDeal(deal)}
                          className="pay-now-inline"
                          onSuccess={() => refresh()}
                        />
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
        {hasMore && (
          <div className="load-more">
            <Button variant="secondary" onClick={loadMore}>
              Load More
            </Button>
          </div>
        )}
      </div>

      <CreateDealModal
        isOpen={createModal.isOpen || editModal.isOpen}
        onClose={() => {
          createModal.close();
          editModal.close();
        }}
        initialData={editModal.data || undefined}
        pipelines={pipelines}
        stages={stages}
        onSuccess={() => {
          createModal.close();
          editModal.close();
          refresh();
        }}
      />

      {detailModal.data && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <DealDetail
              dealId={detailModal.data.id}
              onBack={detailModal.close}
              onClientClick={(clientId) => {
                detailModal.close();
                navigate(`/contacts/${clientId}`);
              }}
              onEdit={() => {
                detailModal.close();
                handleEditClick(detailModal.data!);
              }}
              onMarkWon={handleMarkWon}
              onMarkLost={handleMarkLost}
              onLogActivity={() => {
                detailModal.close();
              }}
            />
            <Button variant="ghost" onClick={detailModal.close}>
              Close
            </Button>
          </div>
        </div>
      )}

      {lostModal.data && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <h3>Mark Opportunity Lost</h3>
            <p className="section-description">
              Provide a brief reason. Do not include PHI, emails, or phone numbers.
            </p>
            <textarea
              value={lostReason}
              onChange={(e) => setLostReason(e.target.value)}
              className="input"
              placeholder="Lost reason (e.g., chose competitor)"
              rows={3}
            />
            <div className="input-hint">
              <span>{lostReason.trim().length}/{MAX_LOSS_REASON} chars</span>
              {lostReasonError && <span className="error-text">{lostReasonError}</span>}
            </div>
            <div className="modal-actions">
              <Button variant="secondary" onClick={lostModal.close}>
                Cancel
              </Button>
              <Button
                disabled={isMutating}
                onClick={async () => {
                  const reason = lostReason.trim();
                  if (!reason) {
                    setLostReasonError('Reason is required (no PHI, no contact info)');
                    return;
                  }
                  if (reason.length > MAX_LOSS_REASON) {
                    setLostReasonError(`Keep reason under ${MAX_LOSS_REASON} characters.`);
                    return;
                  }
                  if (/@|\d[\d\-\s().]{4,}/.test(reason)) {
                    setLostReasonError('Remove emails/phone numbers and any PHI-like details.');
                    return;
                  }
                  setLostReasonError(null);
                  if (!lostModal.data || !canWriteDeal(lostModal.data)) {
                    setLostReasonError('Read-only: you cannot modify this opportunity.');
                    return;
                  }
                  await markLost(lostModal.data.id, reason);
                  setLostReason('');
                  lostModal.close();
                  refresh();
                }}
              >
                Confirm Loss
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* CSV Import Modal */}
      <CSVImportModal
        entityType="deal"
        isOpen={importModal.isOpen}
        onClose={importModal.close}
        onSuccess={refresh}
      />
    </PageLayout>
  );
}
