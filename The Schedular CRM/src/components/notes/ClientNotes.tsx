/**
 * Client Notes Component
 * Displays and manages client notes with CRUD functionality
 *
 * Features:
 * - View all notes for a client
 * - Add new notes with type selection
 * - Edit own notes
 * - Delete own notes (or admin can delete any)
 * - Notes sync bidirectionally with Flutter
 *
 * Per CRM-A Agent Prompt Task 4
 */

import { useState, useCallback } from 'react';
import {
  useClientNotes,
  useClientNoteMutations,
  type ClientNote,
  type ClientNoteType,
} from '../../hooks/useClientNotes';
import { useAuth } from '../../context/AuthContext';

// ============================================
// Types
// ============================================

interface ClientNotesProps {
  clientId: string;
  limit?: number;
  showAddButton?: boolean;
}

interface AddNoteModalProps {
  clientId: string;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  editNote?: ClientNote;
}

// ============================================
// Note Type Icons & Labels
// ============================================

const NOTE_TYPE_CONFIG: Record<ClientNoteType, { icon: string; label: string; color: string }> = {
  call: { icon: '📞', label: 'Call', color: '#3b82f6' },
  meeting: { icon: '🤝', label: 'Meeting', color: '#8b5cf6' },
  email: { icon: '📧', label: 'Email', color: '#10b981' },
  followUp: { icon: '📋', label: 'Follow-up', color: '#f59e0b' },
  other: { icon: '📝', label: 'Other', color: '#6b7280' },
};

// ============================================
// Helper Functions
// ============================================

function formatRelativeTime(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins} min ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;

  return date.toLocaleDateString();
}

// ============================================
// Add Note Modal
// ============================================

function AddNoteModal({ clientId, isOpen, onClose, onSuccess, editNote }: AddNoteModalProps) {
  const [content, setContent] = useState(editNote?.content || '');
  const [type, setType] = useState<ClientNoteType>(editNote?.type || 'call');
  const [error, setError] = useState<string | null>(null);

  const { createNote, updateNote, isCreating, isUpdating } = useClientNoteMutations();
  const isLoading = isCreating || isUpdating;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!content.trim()) {
      setError('Note content is required');
      return;
    }

    try {
      if (editNote) {
        await updateNote({
          noteId: editNote.id,
          content: content.trim(),
          type,
        });
      } else {
        await createNote({
          clientId,
          content: content.trim(),
          type,
        });
      }
      setContent('');
      setType('call');
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save note');
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{editNote ? 'Edit Note' : 'Add Note'}</h2>
          <button className="btn btn-icon" onClick={onClose} aria-label="Close">
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            {error && (
              <div className="alert alert-error" role="alert">
                {error}
              </div>
            )}

            <div className="form-group">
              <label htmlFor="note-type">Type</label>
              <div className="note-type-selector">
                {(Object.entries(NOTE_TYPE_CONFIG) as [ClientNoteType, typeof NOTE_TYPE_CONFIG[ClientNoteType]][]).map(
                  ([noteType, config]) => (
                    <button
                      key={noteType}
                      type="button"
                      className={`note-type-option ${type === noteType ? 'selected' : ''}`}
                      onClick={() => setType(noteType)}
                      style={{ '--type-color': config.color } as React.CSSProperties}
                    >
                      <span className="note-type-icon">{config.icon}</span>
                      <span className="note-type-label">{config.label}</span>
                    </button>
                  )
                )}
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="note-content">Note *</label>
              <textarea
                id="note-content"
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="Enter note content..."
                rows={5}
                maxLength={10000}
                required
              />
              <span className="char-count">{content.length}/10,000</span>
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" className="btn btn-ghost" onClick={onClose} disabled={isLoading}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={isLoading || !content.trim()}>
              {isLoading ? 'Saving...' : editNote ? 'Update Note' : 'Save Note'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ============================================
// Note Item Component
// ============================================

interface NoteItemProps {
  note: ClientNote;
  canEdit: boolean;
  canDelete: boolean;
  onEdit: () => void;
  onDelete: () => void;
}

function NoteItem({ note, canEdit, canDelete, onEdit, onDelete }: NoteItemProps) {
  const config = NOTE_TYPE_CONFIG[note.type] || NOTE_TYPE_CONFIG.other;

  return (
    <div className="client-note-item">
      <div className="note-header">
        <div className="note-type-badge" style={{ backgroundColor: config.color }}>
          <span className="note-type-icon">{config.icon}</span>
          <span className="note-type-label">{config.label}</span>
        </div>
        <div className="note-meta">
          <span className="note-author">{note.createdByName}</span>
          <span className="note-separator">•</span>
          <span className="note-time">{formatRelativeTime(note.createdAt)}</span>
        </div>
      </div>

      <div className="note-content">
        {note.content}
      </div>

      {(canEdit || canDelete) && (
        <div className="note-actions">
          {canEdit && (
            <button className="btn btn-link btn-sm" onClick={onEdit}>
              Edit
            </button>
          )}
          {canDelete && (
            <button className="btn btn-link btn-sm btn-danger" onClick={onDelete}>
              Delete
            </button>
          )}
        </div>
      )}
    </div>
  );
}

// ============================================
// Client Notes Component
// ============================================

export function ClientNotes({ clientId, limit, showAddButton = true }: ClientNotesProps) {
  const { crmUser } = useAuth();
  const { notes, isLoading, error, refetch } = useClientNotes(clientId, { limit });
  const { deleteNote, isDeleting } = useClientNoteMutations();

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<ClientNote | undefined>();
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const isAdminOrOwner = crmUser?.role === 'admin' || crmUser?.role === 'owner';

  const handleDelete = useCallback(async (noteId: string) => {
    try {
      await deleteNote({ noteId, clientId });
      setDeleteConfirmId(null);
      refetch();
    } catch (err) {
      console.error('Failed to delete note:', err);
    }
  }, [deleteNote, clientId, refetch]);

  const handleEditClick = useCallback((note: ClientNote) => {
    setEditingNote(note);
    setIsAddModalOpen(true);
  }, []);

  const handleModalClose = useCallback(() => {
    setIsAddModalOpen(false);
    setEditingNote(undefined);
  }, []);

  const handleModalSuccess = useCallback(() => {
    refetch();
  }, [refetch]);

  if (isLoading) {
    return (
      <div className="client-notes-section">
        <div className="section-header">
          <h3>Notes</h3>
        </div>
        <div className="loading-state">Loading notes...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="client-notes-section">
        <div className="section-header">
          <h3>Notes</h3>
        </div>
        <div className="error-state">
          Failed to load notes
          <button className="btn btn-link" onClick={() => refetch()}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="client-notes-section">
      <div className="section-header">
        <h3>Notes</h3>
        {showAddButton && (
          <button className="btn btn-primary btn-sm" onClick={() => setIsAddModalOpen(true)}>
            + Add Note
          </button>
        )}
      </div>

      {notes.length === 0 ? (
        <div className="empty-state">
          <p>No notes yet</p>
          {showAddButton && (
            <button className="btn btn-ghost" onClick={() => setIsAddModalOpen(true)}>
              Add the first note
            </button>
          )}
        </div>
      ) : (
        <div className="client-notes-list">
          {notes.map((note) => (
            <div key={note.id}>
              {deleteConfirmId === note.id ? (
                <div className="delete-confirm">
                  <p>Delete this note?</p>
                  <div className="delete-confirm-actions">
                    <button
                      className="btn btn-danger btn-sm"
                      onClick={() => handleDelete(note.id)}
                      disabled={isDeleting}
                    >
                      {isDeleting ? 'Deleting...' : 'Delete'}
                    </button>
                    <button
                      className="btn btn-ghost btn-sm"
                      onClick={() => setDeleteConfirmId(null)}
                      disabled={isDeleting}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <NoteItem
                  note={note}
                  canEdit={note.createdByUserId === crmUser?.id || isAdminOrOwner}
                  canDelete={note.createdByUserId === crmUser?.id || isAdminOrOwner}
                  onEdit={() => handleEditClick(note)}
                  onDelete={() => setDeleteConfirmId(note.id)}
                />
              )}
            </div>
          ))}
        </div>
      )}

      <AddNoteModal
        clientId={clientId}
        isOpen={isAddModalOpen}
        onClose={handleModalClose}
        onSuccess={handleModalSuccess}
        editNote={editingNote}
      />
    </div>
  );
}

export default ClientNotes;
