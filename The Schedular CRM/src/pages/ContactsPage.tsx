import { useState, useMemo } from 'react';
import {
  useContacts,
  useContactMutations,
  useModal,
  type ContactFilters,
} from '../hooks';
import { CreateContactModal, ContactDetailModal, ConfirmDialog } from '../components/modals';
import { CSVImportModal } from '../components/import';
import { BulkEmailModal, type BulkEmailContact } from '../components/email/BulkEmailModal';
import type { Client } from '../types/models';
import { useAuth } from '../context/AuthContext';
import { Button, Card, EmptyState, PageHeader, PageLayout, Toolbar } from '../components/ui';

export function ContactsPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const createModal = useModal();
  const viewModal = useModal<Client>();
  const editModal = useModal<Client>();
  const deleteModal = useModal<Client>();
  const importModal = useModal();
  const bulkEmailModal = useModal();
  const { crmUser } = useAuth();

  // Build filters for the hook
  const filters: ContactFilters = {
    search: searchQuery || undefined,
  };

  // Use the contacts hook
  const {
    contacts,
    isLoading,
    error,
    hasMore,
    loadMore,
    refresh,
  } = useContacts(filters);

  const {
    deleteContact,
    isLoading: isMutating,
  } = useContactMutations();

  // RBAC: Check permissions
  const canDelete = crmUser?.role === 'owner' || crmUser?.role === 'admin';
  const canEdit = crmUser?.role === 'owner' || crmUser?.role === 'admin' || crmUser?.role === 'staff';

  // Selection helpers
  const allSelected = contacts.length > 0 && contacts.every((c) => selectedIds.has(c.id));
  const someSelected = selectedIds.size > 0;
  const contactCountLabel = contacts.length === 1 ? '1 contact' : `${contacts.length} contacts`;
  const hasSearchQuery = searchQuery.trim().length > 0;

  const toggleSelectAll = () => {
    if (allSelected) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(contacts.map((c) => c.id)));
    }
  };

  const toggleSelect = (id: string) => {
    const newSet = new Set(selectedIds);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    setSelectedIds(newSet);
  };

  // Convert selected contacts for bulk email modal
  const selectedContacts = useMemo((): BulkEmailContact[] => {
    return contacts
      .filter((c) => selectedIds.has(c.id))
      .map((c) => ({
        id: c.id,
        name: `${c.firstName} ${c.lastName}`.trim(),
        email: c.email || '',
        hasOptedOut: c.emailOptOut === true,
      }));
  }, [contacts, selectedIds]);

  const handleCreateClick = () => createModal.open();
  const handleViewClick = (contact: Client) => viewModal.open(contact);
  const handleEditClick = (contact: Client) => editModal.open(contact);
  const handleDeleteClick = (contact: Client) => deleteModal.open(contact);

  // Show loading state
  if (isLoading) {
    return (
      <PageLayout className="contacts-page">
        <PageHeader
          eyebrow="People"
          title="Contacts"
          subtitle="Maintain a clean directory of buyers, stakeholders, and active relationships."
          actions={<Button disabled>New Contact</Button>}
        />
        <Card className="loading-state">
          <p>Loading contacts...</p>
        </Card>
      </PageLayout>
    );
  }

  // Show error state
  if (error) {
    return (
      <PageLayout className="contacts-page">
        <PageHeader
          eyebrow="People"
          title="Contacts"
          subtitle="Maintain a clean directory of buyers, stakeholders, and active relationships."
          actions={<Button onClick={handleCreateClick}>New Contact</Button>}
        />
        <Card className="error-state">
          <p>Unable to load contacts. Please try again or contact support.</p>
          <Button onClick={refresh}>
            Retry
          </Button>
        </Card>
      </PageLayout>
    );
  }

  return (
    <PageLayout className="contacts-page">
      <PageHeader
        eyebrow="People"
        title="Contacts"
        subtitle="Keep the shared contact directory organized so teams can route outreach, ownership, and follow-up cleanly."
        actions={(
          <>
            {someSelected && (
              <Button disabled={isMutating} onClick={() => bulkEmailModal.open()}>
                Email {selectedIds.size} Contact{selectedIds.size !== 1 ? 's' : ''}
              </Button>
            )}
            <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
              Import CSV
            </Button>
            <Button disabled={isMutating} onClick={handleCreateClick}>
              New Contact
            </Button>
          </>
        )}
      />

      <Toolbar
        className="page-filters"
        start={(
          <input
            type="text"
            placeholder="Search contacts..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="search-input"
          />
        )}
        end={<span className="ui-results-count">{contactCountLabel}</span>}
      />

      <div className="data-table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th className="checkbox-column">
                <input
                  type="checkbox"
                  checked={allSelected}
                  onChange={toggleSelectAll}
                  disabled={contacts.length === 0}
                  aria-label="Select all contacts"
                />
              </th>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Company</th>
              <th>Title</th>
              <th>Last Contact</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {contacts.length === 0 ? (
              <tr>
                <td colSpan={8} className="empty-state">
                  <EmptyState
                    eyebrow="Directory"
                    title={hasSearchQuery ? 'No contacts match this search' : 'No contacts yet'}
                    description={
                      hasSearchQuery
                        ? 'Try a different search term or clear the current filter to broaden the directory view.'
                        : 'Import your existing contact list or create the first person record manually to centralize outreach.'
                    }
                    actions={(
                      <>
                        {hasSearchQuery ? (
                          <Button variant="secondary" onClick={() => setSearchQuery('')}>
                            Clear Search
                          </Button>
                        ) : (
                          <Button variant="secondary" disabled={isMutating} onClick={() => importModal.open()}>
                            Import CSV
                          </Button>
                        )}
                        <Button disabled={isMutating} onClick={handleCreateClick}>
                          New Contact
                        </Button>
                      </>
                    )}
                  />
                </td>
              </tr>
            ) : (
              contacts.map((contact) => (
                <tr key={contact.id} className={selectedIds.has(contact.id) ? 'selected-row' : ''}>
                  <td className="checkbox-column">
                    <input
                      type="checkbox"
                      checked={selectedIds.has(contact.id)}
                      onChange={() => toggleSelect(contact.id)}
                      aria-label={`Select ${contact.firstName} ${contact.lastName}`}
                    />
                  </td>
                  <td>
                    <button
                      className="link-button"
                      type="button"
                      onClick={() => handleViewClick(contact)}
                    >
                      {contact.firstName} {contact.lastName}
                    </button>
                  </td>
                  <td>{contact.email || '-'}</td>
                  <td>{contact.phone || '-'}</td>
                  <td>{contact.companyName || '-'}</td>
                  <td>{contact.title || '-'}</td>
                  <td>
                    {contact.lastContactedAt
                      ? contact.lastContactedAt.toLocaleDateString()
                      : 'Never'}
                  </td>
                  <td>
                    <div className="table-actions">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleViewClick(contact)}
                        disabled={isMutating}
                      >
                        View
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={isMutating || !canEdit}
                        onClick={() => handleEditClick(contact)}
                        title={!canEdit ? 'Insufficient permissions to edit contacts' : ''}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={isMutating || !canDelete}
                        onClick={() => handleDeleteClick(contact)}
                        title={!canDelete ? 'Only administrators can delete contacts' : ''}
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

      <CreateContactModal
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
        <ContactDetailModal
          isOpen={viewModal.isOpen}
          onClose={viewModal.close}
          contact={viewModal.data}
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
            if (deleteModal.data) {
              await deleteContact(deleteModal.data.id);
              refresh();
            }
            deleteModal.close();
          };
          void run();
        }}
        title="Delete Contact"
        message="Are you sure you want to delete this contact? This action cannot be undone."
        confirmText="Delete"
        variant="danger"
      />

      {/* CSV Import Modal */}
      <CSVImportModal
        entityType="contact"
        isOpen={importModal.isOpen}
        onClose={importModal.close}
        onSuccess={refresh}
      />

      {/* Bulk Email Modal */}
      <BulkEmailModal
        isOpen={bulkEmailModal.isOpen}
        onClose={() => {
          bulkEmailModal.close();
          setSelectedIds(new Set()); // Clear selection after closing
        }}
        contacts={selectedContacts}
        onComplete={() => {
          refresh();
        }}
      />
    </PageLayout>
  );
}
