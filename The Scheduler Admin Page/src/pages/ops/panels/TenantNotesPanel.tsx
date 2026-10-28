/**
 * TenantNotesPanel
 * Support notes for a tenant (read/add).
 */

import { useState } from 'react';
import type { OpsNote, OpsNoteCategory, OpsNotePriority } from '../../../types/ops';

type Props = {
  notes: OpsNote[];
  loading: boolean;
  adding: boolean;
  onAddNote: (input: {
    content: string;
    category?: OpsNoteCategory;
    priority?: OpsNotePriority;
  }) => Promise<void>;
};

const CATEGORIES: { value: OpsNoteCategory; label: string }[] = [
  { value: 'general', label: 'General' },
  { value: 'support', label: 'Support' },
  { value: 'billing', label: 'Billing' },
  { value: 'technical', label: 'Technical' },
  { value: 'escalation', label: 'Escalation' },
];

const PRIORITIES: { value: OpsNotePriority; label: string }[] = [
  { value: 'low', label: 'Low' },
  { value: 'normal', label: 'Normal' },
  { value: 'high', label: 'High' },
  { value: 'urgent', label: 'Urgent' },
];

export function TenantNotesPanel({ notes, loading, adding, onAddNote }: Props) {
  const [content, setContent] = useState('');
  const [category, setCategory] = useState<OpsNoteCategory>('general');
  const [priority, setPriority] = useState<OpsNotePriority>('normal');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!content.trim()) return;

    await onAddNote({ content: content.trim(), category, priority });
    setContent('');
    setCategory('general');
    setPriority('normal');
  };

  return (
    <div className="stack">
      {/* Add Note Form */}
      <div className="panel">
        <h3>Add Note</h3>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="note-content">Note</label>
            <textarea
              id="note-content"
              rows={3}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Enter support note..."
              disabled={adding}
            />
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div className="form-group" style={{ flex: 1 }}>
              <label htmlFor="note-category">Category</label>
              <select
                id="note-category"
                value={category}
                onChange={(e) => setCategory(e.target.value as OpsNoteCategory)}
                disabled={adding}
              >
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>
                    {c.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ flex: 1 }}>
              <label htmlFor="note-priority">Priority</label>
              <select
                id="note-priority"
                value={priority}
                onChange={(e) => setPriority(e.target.value as OpsNotePriority)}
                disabled={adding}
              >
                {PRIORITIES.map((p) => (
                  <option key={p.value} value={p.value}>
                    {p.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <button
            type="submit"
            className="button button--primary"
            disabled={adding || !content.trim()}
          >
            {adding ? 'Adding...' : 'Add Note'}
          </button>
        </form>
      </div>

      {/* Notes List */}
      <div className="panel">
        <h3>Notes History</h3>
        {loading ? (
          <p className="muted">Loading notes...</p>
        ) : notes.length === 0 ? (
          <p className="muted">No notes for this tenant.</p>
        ) : (
          <div className="stack" style={{ gap: 12 }}>
            {notes.map((note) => (
              <div
                key={note.id}
                style={{
                  padding: 12,
                  backgroundColor: 'var(--color-surface)',
                  borderRadius: 8,
                  border: '1px solid var(--color-border)',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: 8,
                  }}
                >
                  <div>
                    <span
                      className={`badge badge--${getCategoryVariant(note.category)}`}
                      style={{ marginRight: 8 }}
                    >
                      {note.category || 'general'}
                    </span>
                    {note.priority && note.priority !== 'normal' && (
                      <span className={`badge badge--${getPriorityVariant(note.priority)}`}>
                        {note.priority}
                      </span>
                    )}
                  </div>
                  <span className="muted" style={{ fontSize: 11 }}>
                    {formatTimestamp(note.createdAt)}
                  </span>
                </div>
                <p style={{ margin: 0, whiteSpace: 'pre-wrap' }}>{note.content}</p>
                <p className="muted" style={{ margin: '8px 0 0', fontSize: 11 }}>
                  — {note.createdByEmail}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function getCategoryVariant(category?: string): string {
  switch (category) {
    case 'support':
      return 'info';
    case 'billing':
      return 'warn';
    case 'technical':
      return 'neutral';
    case 'escalation':
      return 'danger';
    default:
      return 'neutral';
  }
}

function getPriorityVariant(priority?: string): string {
  switch (priority) {
    case 'high':
      return 'warn';
    case 'urgent':
      return 'danger';
    default:
      return 'neutral';
  }
}

function formatTimestamp(ts: string): string {
  try {
    return new Date(ts).toLocaleString();
  } catch {
    return ts;
  }
}
