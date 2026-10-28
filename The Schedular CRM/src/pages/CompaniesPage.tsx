import { useMemo, useState } from 'react';
import type { Company } from '../types/models';
import { useCompanies, useCompanyMutations, useModal } from '../hooks';
import { CreateCompanyModal, CompanyDetailModal, ConfirmDialog } from '../components/modals';
import { useAuth } from '../context/AuthContext';
import {
  canDeleteShareableEntity,
  canWriteShareableEntity,
  createSecurityContext,
  getShareableAccessSummary,
  type ShareableAccessSummary,
} from '../lib/security-context';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';

export function CompaniesPage() {
  const { companies, isLoading, error, hasMore, loadMore, refresh, getAccessSummary } = useCompanies();
  const [searchQuery, setSearchQuery] = useState('');
  const createModal = useModal();
  const viewModal = useModal<Company>();
  const editModal = useModal<Company>();
  const deleteModal = useModal<Company>();
  const { deleteCompany, isLoading: isMutating } = useCompanyMutations();
  const { crmUser } = useAuth();
  const securityContext = useMemo(
    () => (crmUser ? createSecurityContext(crmUser) : null),
    [crmUser]
  );
  const canCreate = Boolean(securityContext);
  const getCompanyAccess = (company: Company): ShareableAccessSummary | null =>
    getAccessSummary ? getAccessSummary(company) : securityContext ? getShareableAccessSummary(securityContext, company) : null;
  const canWriteCompany = (company: Company) => {
    const summary = getCompanyAccess(company);
    if (summary) return summary.canWrite;
    return Boolean(securityContext && canWriteShareableEntity(securityContext, company));
  };
  const canDeleteCompany = (company: Company) => {
    const summary = getCompanyAccess(company);
    if (summary) return summary.canDelete;
    return Boolean(securityContext && canDeleteShareableEntity(securityContext, company));
  };
  const readOnlyReason = (company: Company) => {
    const summary = getCompanyAccess(company);
    if (!summary || summary.canWrite) return undefined;
    if (summary.visibility === 'org' && !summary.hasTeamAccess) return 'Read-only: org-visible only';
    return 'Read-only: not shared to you or your teams';
  };

  const filteredCompanies = companies.filter((company) => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      company.name.toLowerCase().includes(query) ||
      company.industry?.toLowerCase().includes(query)
    );
  });
  const companyCountLabel =
    filteredCompanies.length === 1 ? '1 company' : `${filteredCompanies.length} companies`;
  const hasSearchQuery = searchQuery.trim().length > 0;

  const handleCreateClick = () => {
    if (!canCreate) return;
    createModal.open();
  };
  const handleViewClick = (company: Company) => viewModal.open(company);
  const handleEditClick = (company: Company) => editModal.open(company);
  const handleDeleteClick = (company: Company) => deleteModal.open(company);

  if (isLoading) {
    return (
      <PageLayout className="companies-page">
        <PageHeader
          eyebrow="Accounts"
          title="Companies"
          subtitle="Manage the organizations connected to your contacts, opportunities, and shared account history."
          actions={(
            <Button
              disabled
              title={!canCreate ? 'You do not have permission to create companies' : undefined}
            >
              New Company
            </Button>
          )}
        />
        <Card className="loading-state">
          <p>Loading companies...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error) {
    return (
      <PageLayout className="companies-page">
        <PageHeader
          eyebrow="Accounts"
          title="Companies"
          subtitle="Manage the organizations connected to your contacts, opportunities, and shared account history."
          actions={(
            <Button
              onClick={handleCreateClick}
              disabled={!canCreate}
              title={!canCreate ? 'You do not have permission to create companies' : undefined}
            >
              New Company
            </Button>
          )}
        />
        <Card className="error-state">
          <p>Unable to load companies. Please try again or contact support.</p>
          <Button onClick={refresh}>Retry</Button>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout className="companies-page">
      <PageHeader
        eyebrow="Accounts"
        title="Companies"
        subtitle="Keep account records current so ownership, firmographics, and relationship context stay aligned across the workspace."
        actions={(
          <Button
            disabled={isMutating || !canCreate}
            onClick={handleCreateClick}
            title={!canCreate ? 'You do not have permission to create companies' : undefined}
          >
            New Company
          </Button>
        )}
      />

      <Toolbar
        className="page-filters"
        start={(
          <input
            type="text"
            placeholder="Search companies..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-input"
          />
        )}
        end={<span className="ui-results-count">{companyCountLabel}</span>}
      />

      <div className="data-table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Company Name</th>
              <th>Industry</th>
              <th>Size</th>
              <th>Website</th>
              <th>Contacts</th>
              <th>Deals</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredCompanies.length === 0 ? (
              <tr>
                <td colSpan={7} className="empty-state">
                  <EmptyState
                    eyebrow="Account directory"
                    title={hasSearchQuery ? 'No companies match this search' : 'No companies yet'}
                    description={
                      hasSearchQuery
                        ? 'Try a different company name or industry filter to broaden the result set.'
                        : 'Create the first company record to give teams a shared account view for contacts and opportunities.'
                    }
                    actions={(
                      <>
                        {hasSearchQuery ? (
                          <Button variant="secondary" onClick={() => setSearchQuery('')}>
                            Clear Search
                          </Button>
                        ) : null}
                        <Button
                          disabled={isMutating || !canCreate}
                          onClick={handleCreateClick}
                          title={!canCreate ? 'You do not have permission to create companies' : undefined}
                        >
                          New Company
                        </Button>
                      </>
                    )}
                  />
                </td>
              </tr>
            ) : (
              filteredCompanies.map((company) => (
                <tr key={company.id}>
                  <td>
                    <button
                      className="link-button"
                      type="button"
                      onClick={() => handleViewClick(company)}
                    >
                      {company.name}
                    </button>
                  </td>
                  <td>{company.industry || '-'}</td>
                  <td>{company.size || '-'}</td>
                  <td>
                    {company.website ? (
                      <a href={company.website} target="_blank" rel="noopener noreferrer">
                        {company.website}
                      </a>
                    ) : (
                      '-'
                    )}
                  </td>
                  <td>0</td>
                  <td>0</td>
                  <td>
                    <div className="table-actions">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleViewClick(company)}
                        disabled={isMutating}
                      >
                        View
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEditClick(company)}
                        disabled={isMutating || !canWriteCompany(company)}
                        title={readOnlyReason(company)}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDeleteClick(company)}
                        disabled={isMutating || !canDeleteCompany(company)}
                        title={
                          !canDeleteCompany(company)
                            ? 'Only admins or owners can delete companies'
                            : undefined
                        }
                      >
                        Delete
                      </Button>
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

      <CreateCompanyModal
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

      {viewModal.data && (
        <CompanyDetailModal
          isOpen={viewModal.isOpen}
          onClose={viewModal.close}
          company={viewModal.data}
          onSuccess={() => {
            refresh();
          }}
        />
      )}

      <ConfirmDialog
        isOpen={deleteModal.isOpen}
        onCancel={deleteModal.close}
        onConfirm={() => {
          const run = async () => {
            if (!deleteModal.data || !canDeleteCompany(deleteModal.data)) {
              deleteModal.close();
              return;
            }
            if (deleteModal.data) {
              await deleteCompany(deleteModal.data.id);
              refresh();
            }
            deleteModal.close();
          };
          void run();
        }}
        title="Delete Company"
        message="Are you sure you want to delete this company? This action cannot be undone."
        confirmText="Delete"
        variant="danger"
      />
    </PageLayout>
  );
}
