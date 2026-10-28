/**
 * WebFormsPage Component
 * List and manage embeddable lead capture forms
 *
 * Agent Web Forms Implementation
 *
 * Features:
 * - List all web forms with status and stats
 * - Create new forms
 * - Quick actions: edit, duplicate, toggle status, get embed code
 */

import { useState, useMemo, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { useWebForms } from '../hooks/useWebForms';
import { useModal } from '../hooks';
import { createSecurityContextFromParams } from '../lib/security-context';
import { useFeatureFlags } from '../hooks/useFeatureFlags';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';
import type { WebForm, WebFormStatus } from '../types/web-forms';
import { FormBuilder } from '../components/web-forms/FormBuilder';
import { EmbedCodeModal } from '../components/web-forms/EmbedCodeModal';
import './styles/web-forms.css';

/**
 * WebFormsPage - List and manage web forms
 */
export function WebFormsPage() {
  const { crmUser } = useAuth();
  const { isEnabled } = useFeatureFlags();
  const [statusFilter, setStatusFilter] = useState<WebFormStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const formBuilderModal = useModal<WebForm | null>();
  const embedCodeModal = useModal<WebForm>();

  // Security context
  const context = useMemo(() => {
    if (!crmUser?.businessId) return null;
    try {
      return createSecurityContextFromParams(
        crmUser.businessId,
        crmUser.id,
        crmUser.displayName || crmUser.email || 'Unknown User',
        crmUser.role,
        crmUser.teamIds || [],
        crmUser.managedTeamIds || [],
        crmUser.managerId
      );
    } catch {
      return null;
    }
  }, [crmUser]);

  // Fetch forms
  const { forms, isLoading, error, refetch, updateForm, deleteForm } = useWebForms(context);

  // Filter forms
  const filteredForms = useMemo(() => {
    let result = forms;

    if (statusFilter !== 'all') {
      result = result.filter((f) => f.status === statusFilter);
    }

    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      result = result.filter(
        (f) =>
          f.name.toLowerCase().includes(query) ||
          f.description?.toLowerCase().includes(query)
      );
    }

    return result;
  }, [forms, statusFilter, searchQuery]);

  // Handlers
  const handleCreateForm = useCallback(() => {
    formBuilderModal.open(null);
  }, [formBuilderModal]);

  const handleEditForm = useCallback(
    (form: WebForm) => {
      formBuilderModal.open(form);
    },
    [formBuilderModal]
  );

  const handleGetEmbedCode = useCallback(
    (form: WebForm) => {
      embedCodeModal.open(form);
    },
    [embedCodeModal]
  );

  const handleToggleStatus = useCallback(
    async (form: WebForm) => {
      const newStatus: WebFormStatus = form.status === 'active' ? 'inactive' : 'active';
      await updateForm(form.id, { status: newStatus });
    },
    [updateForm]
  );

  const handleDeleteForm = useCallback(
    async (form: WebForm) => {
      if (window.confirm(`Are you sure you want to delete "${form.name}"?`)) {
        await deleteForm(form.id);
      }
    },
    [deleteForm]
  );

  const handleFormSaved = useCallback(() => {
    formBuilderModal.close();
    refetch();
  }, [formBuilderModal, refetch]);

  // Feature flag check
  if (!isEnabled('enableWebForms')) {
    return (
      <PageLayout width="wide" className="web-forms-page">
        <PageHeader
          eyebrow="Acquisition"
          title="Web Forms"
          subtitle="Manage embeddable forms, lead capture, and follow-up enrollment rules."
        />
        <Card padding="lg" className="web-forms-page__state-card">
          <EmptyState
            tone="warning"
            title="Web forms are disabled"
            description="This feature is not enabled for your account. Contact an administrator to turn it on."
          />
        </Card>
      </PageLayout>
    );
  }

  if (isLoading) {
    return (
      <PageLayout width="wide" className="web-forms-page">
        <PageHeader
          eyebrow="Acquisition"
          title="Web Forms"
          subtitle="Manage embeddable forms, lead capture, and follow-up enrollment rules."
        />
        <Card padding="lg" className="web-forms-page__state-card">
          <p>Loading forms...</p>
        </Card>
      </PageLayout>
    );
  }

  if (error) {
    return (
      <PageLayout width="wide" className="web-forms-page">
        <PageHeader
          eyebrow="Acquisition"
          title="Web Forms"
          subtitle="Manage embeddable forms, lead capture, and follow-up enrollment rules."
        />
        <Card padding="lg" className="web-forms-page__state-card">
          <EmptyState
            tone="danger"
            title="Unable to load forms"
            description={`Failed to load forms: ${error.message}`}
            actions={(
              <Button variant="secondary" onClick={() => refetch()}>
                Retry
              </Button>
            )}
          />
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout width="wide" className="web-forms-page">
      <PageHeader
        eyebrow="Acquisition"
        title="Web Forms"
        subtitle="Create embeddable lead-capture forms, monitor conversion volume, and manage active intake surfaces."
        actions={(
          <Button onClick={handleCreateForm}>
            Create Form
          </Button>
        )}
      />

      <Card tone="accent" className="web-forms-page__hero">
        <div className="web-forms-page__hero-copy">
          <h2>Capture demand without losing routing and follow-up context.</h2>
          <p>
            Keep form inventory, embed delivery, and auto-enrollment behavior visible
            from one workspace instead of scattered modal flows.
          </p>
        </div>
        <div className="web-forms-page__hero-stats" aria-label="Web form summary">
          <div>
            <span>Total forms</span>
            <strong>{forms.length}</strong>
          </div>
          <div>
            <span>Active forms</span>
            <strong>{forms.filter((form) => form.status === 'active').length}</strong>
          </div>
          <div>
            <span>Visible results</span>
            <strong>{filteredForms.length}</strong>
          </div>
        </div>
      </Card>

      <Card className="web-forms-page__filters-card">
        <Toolbar
          className="web-forms-page__toolbar"
          start={(
            <div className="web-forms-page__filter-group web-forms-page__filter-group--search">
              <label htmlFor="web-forms-search">Search</label>
              <input
                id="web-forms-search"
                type="text"
                placeholder="Search forms..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          )}
          end={(
            <div className="web-forms-page__filter-group">
              <label htmlFor="web-forms-status">Status</label>
              <select
                id="web-forms-status"
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as WebFormStatus | 'all')}
              >
                <option value="all">All Status</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
          )}
        />
      </Card>

      {filteredForms.length === 0 ? (
        <Card padding="lg" className="web-forms-page__state-card">
          {forms.length === 0 ? (
            <EmptyState
              title="No forms yet"
              description="Create your first form to start capturing leads from your website."
              actions={(
                <Button onClick={handleCreateForm}>
                  Create Your First Form
                </Button>
              )}
            />
          ) : (
            <EmptyState
              title="No forms match these filters"
              description="Adjust the status filter or search query to widen the current view."
            />
          )}
        </Card>
      ) : (
        <div className="web-forms-list">
          {filteredForms.map((form) => (
            <WebFormCard
              key={form.id}
              form={form}
              onEdit={handleEditForm}
              onGetEmbedCode={handleGetEmbedCode}
              onToggleStatus={handleToggleStatus}
              onDelete={handleDeleteForm}
            />
          ))}
        </div>
      )}

      {formBuilderModal.isOpen && (
        <FormBuilder
          form={formBuilderModal.data}
          context={context}
          onSave={handleFormSaved}
          onClose={formBuilderModal.close}
        />
      )}

      {embedCodeModal.isOpen && embedCodeModal.data && (
        <EmbedCodeModal
          form={embedCodeModal.data}
          businessId={crmUser?.businessId || ''}
          onClose={embedCodeModal.close}
        />
      )}
    </PageLayout>
  );
}

/**
 * WebFormCard - Individual form card in the list
 */
interface WebFormCardProps {
  form: WebForm;
  onEdit: (form: WebForm) => void;
  onGetEmbedCode: (form: WebForm) => void;
  onToggleStatus: (form: WebForm) => void;
  onDelete: (form: WebForm) => void;
}

function WebFormCard({
  form,
  onEdit,
  onGetEmbedCode,
  onToggleStatus,
  onDelete,
}: WebFormCardProps) {
  return (
    <div className={`web-form-card ${form.status === 'inactive' ? 'inactive' : ''}`}>
      <div className="web-form-card-header">
        <div className="web-form-card-title">
          <h3>{form.name}</h3>
          <span className={`status-badge ${form.status}`}>
            {form.status === 'active' ? 'Active' : 'Inactive'}
          </span>
        </div>
        <div className="web-form-card-actions">
          <button
            className="btn-icon"
            title="Get Embed Code"
            onClick={() => onGetEmbedCode(form)}
            disabled={form.status !== 'active'}
          >
            {'</>'}
          </button>
          <button className="btn-icon" title="Edit" onClick={() => onEdit(form)}>
            ✏️
          </button>
          <button
            className="btn-icon"
            title={form.status === 'active' ? 'Deactivate' : 'Activate'}
            onClick={() => onToggleStatus(form)}
          >
            {form.status === 'active' ? '⏸️' : '▶️'}
          </button>
          <button
            className="btn-icon btn-danger"
            title="Delete"
            onClick={() => onDelete(form)}
          >
            🗑️
          </button>
        </div>
      </div>

      {form.description && (
        <p className="web-form-card-description">{form.description}</p>
      )}

      <div className="web-form-card-meta">
        <div className="web-form-card-stat">
          <span className="stat-label">Fields</span>
          <span className="stat-value">{form.fields.length}</span>
        </div>
        <div className="web-form-card-stat">
          <span className="stat-label">Total Submissions</span>
          <span className="stat-value">{form.stats.totalSubmissions}</span>
        </div>
        <div className="web-form-card-stat">
          <span className="stat-label">This Month</span>
          <span className="stat-value">{form.stats.submissionsThisMonth}</span>
        </div>
      </div>

      <div className="web-form-card-footer">
        <span className="web-form-card-created">
          Created {new Date(form.createdAt).toLocaleDateString()}
        </span>
        {form.settings.sequenceId && (
          <span className="web-form-card-sequence">Auto-enrolls in sequence</span>
        )}
      </div>
    </div>
  );
}

export default WebFormsPage;
