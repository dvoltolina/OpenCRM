import { useState, useCallback, useMemo } from 'react';
import type { Lead, LeadStatus, Client, Deal } from '../types/models';
import {
  useLeads,
  useLeadMutations,
  usePipelines,
  useStages,
  useModal,
  type LeadFilters,
} from '../hooks';
import { useAuth } from '../context/AuthContext';
import { LeadActions, LeadStatusBadge } from '../components/leads';
import {
  ConvertLeadModal,
  ConfirmDialog,
  CreateLeadModal,
  AssignRepModal,
} from '../components/modals';
import { CSVImportModal } from '../components/import';
import { useNavigate } from 'react-router-dom';
import { LeadDetail } from '../components/details';
import PayNowButton from '../components/payments/PayNowButton';
import {
  canDeleteShareableEntity,
  canWriteShareableEntity,
  createSecurityContextFromParams,
  getUserManagedTeamIds,
  getUserTeamIds,
  type ShareableAccessSummary,
} from '../lib/security-context';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';

const statusOptions: { value: LeadStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All Statuses' },
  { value: 'new', label: 'New' },
  { value: 'contacted', label: 'Contacted' },
  { value: 'qualified', label: 'Qualified' },
  { value: 'unqualified', label: 'Unqualified' },
  { value: 'converted', label: 'Converted' },
];

type SortField = 'name' | 'email' | 'companyName' | 'status' | 'source' | 'createdAt';
type SortDir = 'asc' | 'desc';

function compareLead(a: Lead, b: Lead, field: SortField, dir: SortDir): number {
  let aVal: string | number;
  let bVal: string | number;
  switch (field) {
    case 'name':
      aVal = `${a.firstName} ${a.lastName}`.toLowerCase();
      bVal = `${b.firstName} ${b.lastName}`.toLowerCase();
      break;
    case 'createdAt':
      aVal = a.createdAt?.getTime?.() ?? 0;
      bVal = b.createdAt?.getTime?.() ?? 0;
      break;
    default:
      aVal = (String((a as any)[field] ?? '')).toLowerCase();
      bVal = (String((b as any)[field] ?? '')).toLowerCase();
  }
  const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
  return dir === 'asc' ? cmp : -cmp;
}

export function LeadsPage() {
  const [statusFilter, setStatusFilter] = useState<LeadStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortField, setSortField] = useState<SortField>('createdAt');
  const [sortDir, setSortDir] = useState<SortDir>('desc');
  const [pageSize, setPageSize] = useState(50);
  const navigate = useNavigate();
  const { crmUser, businessId } = useAuth();

  const shareableContext = useMemo(
    () =>
      crmUser && businessId
        ? createSecurityContextFromParams(
            businessId,
            crmUser.id,
            crmUser.displayName || crmUser.email || 'Unknown User',
            crmUser.role,
            getUserTeamIds(crmUser),
            getUserManagedTeamIds(crmUser),
            crmUser.managerId
          )
        : null,
    [businessId, crmUser]
  );

  const convertModal = useModal<Lead>();
  const deleteModal = useModal<Lead>();
  const createModal = useModal();
  const editModal = useModal<Lead>();
  const detailModal = useModal<Lead>();
  const importModal = useModal();
  const assignModal = useModal<Lead>(); // For assigning lead to rep

  const [selectedPipelineId, setSelectedPipelineId] = useState<string>('');

  const filters: LeadFilters = {
    status: statusFilter !== 'all' ? statusFilter : undefined,
    search: searchQuery || undefined,
  };

  const {
    leads,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
    getAccessSummary,
  } = useLeads(filters, pageSize);

  const {
    deleteLead: deleteLeadMutation,
    updateStatus: updateStatusMutation,
    assignLead: assignLeadMutation,
    isLoading: isMutating,
  } = useLeadMutations();

  const canAssignLeads = useMemo(() => {
    const role = crmUser?.role;
    return role === 'owner' || role === 'admin' || role === 'manager';
  }, [crmUser?.role]);

  const getLeadAccess = useCallback(
    (lead: Lead): ShareableAccessSummary | null => (getAccessSummary ? getAccessSummary(lead) : null),
    [getAccessSummary]
  );

  const canWriteLead = useCallback(
    (lead: Lead) => {
      const summary = getLeadAccess(lead);
      if (summary) return summary.canWrite;
      if (!shareableContext) return false;
      return canWriteShareableEntity(shareableContext, lead);
    },
    [getLeadAccess, shareableContext]
  );
  const canDeleteLead = useCallback(
    (lead: Lead) => {
      const summary = getLeadAccess(lead);
      if (summary) return summary.canDelete;
      if (!shareableContext) return false;
      return canDeleteShareableEntity(shareableContext, lead);
    },
    [getLeadAccess, shareableContext]
  );
  const readOnlyReason = useCallback(
    (lead: Lead) => {
      const summary = getLeadAccess(lead);
      if (!summary || summary.canWrite) return undefined;
      if (summary.visibility === 'org' && !summary.hasTeamAccess) return 'Read-only: org-visible only';
      return 'Read-only: not shared to you or your teams';
    },
    [getLeadAccess]
  );

  const { pipelines } = usePipelines();
  const { stages } = useStages(selectedPipelineId || pipelines[0]?.id);
  const convertEnabled = import.meta.env?.VITE_ENABLE_LEAD_CONVERT !== 'false';
  const payNowEnabled = import.meta.env?.VITE_ENABLE_PAY_NOW === 'true';
  const payNowWarning =
    !payNowEnabled ?
      'Pay Now is disabled until the shared Scheduler payment confirmation flow is validated for this environment. Set VITE_ENABLE_PAY_NOW=true only after that verification.' :
      '';

  const [conversionResult, setConversionResult] = useState<{
    client: Client;
    deal?: Deal;
  } | null>(null);
  const sortedLeads = useMemo(
    () => [...leads].sort((a, b) => compareLead(a, b, sortField, sortDir)),
    [leads, sortField, sortDir]
  );

  const toggleSort = useCallback((field: SortField) => {
    if (field === sortField) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDir('asc');
    }
  }, [sortField, sortDir]);

  const sortIndicator = (field: SortField) =>
    sortField === field
      ? (sortDir === 'asc' ? ' ▲' : ' ▼')
      : ' ⇅';

  const leadCountLabel = leads.length === 1 ? '1 lead' : `${leads.length} leads`;

  const handleConvertClick = useCallback((lead: Lead) => {
    setConversionResult(null);
    if (pipelines.length > 0) {
      setSelectedPipelineId(pipelines[0].id);
    }
    convertModal.open(lead);
  }, [convertModal, pipelines]);

  const handleViewClick = useCallback((lead: Lead) => {
    detailModal.open(lead);
  }, [detailModal]);

  const handlePipelineChange = useCallback((pipelineId: string) => {
    setSelectedPipelineId(pipelineId);
  }, []);

  const handleConvertRequest = useCallback((lead: Lead) => {
    convertModal.open(lead);
  }, [convertModal]);

  const handleConversionSuccess = useCallback((result: { client: Client; deal?: Deal }) => {
    setConversionResult(result);
    refresh();
  }, [refresh]);

  const handleEditClick = useCallback((lead: Lead) => {
    editModal.open(lead);
  }, [editModal]);

  const handleDeleteClick = useCallback((lead: Lead) => {
    if (!canDeleteLead(lead)) return;
    deleteModal.open(lead);
  }, [canDeleteLead, deleteModal]);

  const handleDeleteConfirm = useCallback(() => {
    const run = async () => {
      if (deleteModal.data && canDeleteLead(deleteModal.data)) {
        await deleteLeadMutation(deleteModal.data.id);
        refresh();
      }
      deleteModal.close();
    };
    void run();
  }, [canDeleteLead, deleteModal, deleteLeadMutation, refresh]);

  const handleStatusChange = useCallback(
    async (lead: Lead, newStatus: LeadStatus) => {
      try {
        await updateStatusMutation(lead.id, newStatus);
        refresh();
      } catch {}
    },
    [updateStatusMutation, refresh]
  );

  const handleAssignRepClick = useCallback((lead: Lead) => {
    assignModal.open(lead);
  }, [assignModal]);

  const handleAssignRep = useCallback(
    async (assigneeId: string, assigneeName: string) => {
      if (!assignModal.data) return;
      await assignLeadMutation(assignModal.data.id, assigneeId, assigneeName);
      refresh();
    },
    [assignModal.data, assignLeadMutation, refresh]
  );

  if (isLoading) {
    return (
      <PageLayout className="leads-page">
        <PageHeader
          eyebrow="Prospects"
          title="Leads"
          subtitle="Capture and qualify new pipeline before handing it off to sales."
          actions={<Button disabled>New Lead</Button>}
        />
        <Card className="loading-state">
          <p>Loading leads...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error) {
    return (
      <PageLayout className="leads-page">
        <PageHeader
          eyebrow="Prospects"
          title="Leads"
          subtitle="Capture and qualify new pipeline before handing it off to sales."
          actions={<Button onClick={() => createModal.open()}>New Lead</Button>}
        />
        <Card className="error-state">
          <p>Error loading leads: {error.message}</p>
          <Button onClick={refresh}>
            Retry
          </Button>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout className="leads-page">
      <PageHeader
        eyebrow="Prospects"
        title="Leads"
        subtitle="Keep inbound demand organized, assign the right owners, and convert qualified accounts into opportunities."
        actions={(
          <>
            <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
              Import CSV
            </Button>
            <Button disabled={isMutating} onClick={() => createModal.open()}>
              New Lead
            </Button>
          </>
        )}
      />

      {!convertEnabled && (
        <div className="alert alert-warning" role="status">
          Lead conversion is disabled in this environment. Enable VITE_ENABLE_LEAD_CONVERT after validating leads-convert function.
        </div>
      )}

      {!payNowEnabled && (
        <div className="alert alert-warning" role="status">
          {payNowWarning}
        </div>
      )}

      {conversionResult && (
        <div className="page-banner page-banner--success" role="status">
          <div className="page-banner__content">
            <span className="page-banner__title">Lead converted successfully</span>
            <span>
              Created contact {conversionResult.client.firstName} {conversionResult.client.lastName}
              {conversionResult.deal ? ` and opportunity ${conversionResult.deal.title}` : ''}
            </span>
          </div>
          <Button variant="ghost" size="sm" onClick={() => setConversionResult(null)}>
            Dismiss
          </Button>
        </div>
      )}

      <Toolbar
        className="page-filters"
        start={(
          <>
            <input
              type="text"
              placeholder="Search leads..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="search-input"
            />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as LeadStatus | 'all')}
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
        end={(
          <>
            <select
              value={pageSize}
              onChange={(e) => setPageSize(Number(e.target.value))}
              className="filter-select"
            >
              <option value={50}>50 per page</option>
              <option value={100}>100 per page</option>
              <option value={200}>200 per page</option>
              <option value={500}>500 per page</option>
            </select>
            <span className="ui-results-count">{leadCountLabel}</span>
          </>
        )}
      />

      <div className="data-table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th className="sortable-th" onClick={() => toggleSort('name')}>Name{sortIndicator('name')}</th>
              <th className="sortable-th" onClick={() => toggleSort('email')}>Email{sortIndicator('email')}</th>
              <th className="sortable-th" onClick={() => toggleSort('companyName')}>Company{sortIndicator('companyName')}</th>
              <th className="sortable-th" onClick={() => toggleSort('status')}>Status{sortIndicator('status')}</th>
              <th className="sortable-th" onClick={() => toggleSort('source')}>Source{sortIndicator('source')}</th>
              <th className="sortable-th" onClick={() => toggleSort('createdAt')}>Created{sortIndicator('createdAt')}</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {leads.length === 0 ? (
              <tr>
                <td colSpan={7} className="empty-state">
                  <EmptyState
                    eyebrow="Pipeline starts here"
                    title="No leads yet"
                    description="Import your pipeline or create the first lead manually to start qualification and assignment."
                    actions={(
                      <>
                        <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
                          Import CSV
                        </Button>
                        <Button disabled={isMutating} onClick={() => createModal.open()}>
                          New Lead
                        </Button>
                      </>
                    )}
                  />
                </td>
              </tr>
            ) : (
              sortedLeads.map((lead) => (
                <tr key={lead.id}>
                  <td>
                    <button
                      className="link-button"
                      type="button"
                      onClick={() => navigate(`/leads/${lead.id}`)}
                    >
                      {lead.firstName} {lead.lastName}
                    </button>
                  </td>
                  <td>{lead.email}</td>
                  <td>{lead.companyName || '-'}</td>
                  <td>
                    <LeadStatusBadge status={lead.status} />
                  </td>
                  <td>{lead.source}</td>
                  <td>{lead.createdAt?.toLocaleDateString() || '-'}</td>
                  <td>
                    <div className="table-actions">
                      <LeadActions
                        lead={lead}
                        onView={handleViewClick}
                        onEdit={handleEditClick}
                        canEdit={canWriteLead(lead)}
                        onConvert={convertEnabled ? handleConvertRequest : undefined}
                        canConvertOverride={canWriteLead(lead)}
                        onDelete={handleDeleteClick}
                        canDelete={canDeleteLead(lead)}
                        onStatusChange={handleStatusChange}
                        canChangeStatus={canWriteLead(lead)}
                        onAssignRep={handleAssignRepClick}
                        canAssignRep={canAssignLeads}
                        disabled={isMutating}
                        readOnlyReason={readOnlyReason(lead)}
                      />
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

      <ConvertLeadModal
        isOpen={convertModal.isOpen}
        onClose={convertModal.close}
        lead={convertModal.data}
        pipelines={pipelines}
        stages={stages}
        onPipelineChange={handlePipelineChange}
        onSuccess={handleConversionSuccess}
      />

      <CreateLeadModal
        isOpen={createModal.isOpen || editModal.isOpen}
        onClose={() => {
          createModal.close();
          editModal.close();
        }}
        initialData={editModal.data || undefined}
        onSuccess={() => {
          refresh();
          createModal.close();
          editModal.close();
        }}
      />

      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onCancel={deleteModal.close}
        onConfirm={handleDeleteConfirm}
        title="Delete Lead"
        message={`Are you sure you want to delete "${deleteModal.data?.firstName} ${deleteModal.data?.lastName}"? This action cannot be undone.`}
        confirmText="Delete"
        variant="danger"
      />

      {detailModal.data && (
        <div className="modal-backdrop">
          <div className="modal-card">
            <LeadDetail
              leadId={detailModal.data.id}
              onBack={detailModal.close}
              onEdit={
                canWriteLead(detailModal.data)
                  ? () => {
                      detailModal.close();
                      handleEditClick(detailModal.data!);
                    }
                  : undefined
              }
              onConvert={
                canWriteLead(detailModal.data) && convertEnabled ? handleConvertClick : undefined
              }
              onDelete={
                canDeleteLead(detailModal.data)
                  ? () => {
                      detailModal.close();
                      handleDeleteClick(detailModal.data!);
                    }
                  : undefined
              }
            />
            {payNowEnabled && detailModal.data.convertedToClientId && (
              <div className="detail-actions-inline">
                <PayNowButton
                  clientId={detailModal.data.convertedToClientId}
                  clientName={`${detailModal.data.firstName} ${detailModal.data.lastName}`.trim()}
                  dealId={detailModal.data.convertedToDealId}
                  dealTitle={detailModal.data.companyName}
                  variant="outline"
                  size="sm"
                  disabled={isMutating}
                  onSuccess={() => refresh()}
                />
              </div>
            )}
            <Button variant="ghost" onClick={detailModal.close}>
              Close
            </Button>
          </div>
        </div>
      )}

      <CSVImportModal
        entityType="lead"
        isOpen={importModal.isOpen}
        onClose={importModal.close}
        onSuccess={refresh}
      />

      {assignModal.data && (
        <AssignRepModal
          isOpen={assignModal.isOpen}
          onClose={assignModal.close}
          leads={assignModal.data}
          onAssign={handleAssignRep}
          isAssigning={isMutating}
        />
      )}
    </PageLayout>
  );
}
