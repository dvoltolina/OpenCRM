import { useEffect, useMemo, useState, type ChangeEvent } from 'react';

import { useBusinessContext } from '../hooks/useBusinessContext';
import { listIntakeSubmissions } from '../data/intakeForms';
import {
  canAccessSessionNotes,
  createSessionNoteFromPlaintext,
  decryptSessionNoteContent,
  listSessionNotes,
  type SessionNoteActor,
} from '../data/sessionNotes';
import { listPayments } from '../data/payments';
import { deleteFile, downloadFile, listFileAttachments, uploadFile } from '../data/fileAttachments';
import { listAppointments } from '../data/appointments';
import type {
  Appointment,
  Client,
  FileAttachment,
  IntakeFormSubmission,
  Payment,
  SessionNote,
} from '../types/models';

type Tab = 'overview' | 'appointments' | 'intake' | 'session-notes' | 'payments' | 'files';

type Props = {
  client: Client | null;
  onClose: () => void;
};

function formatDate(value?: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '—';
  return parsed.toLocaleDateString();
}

function formatDateTime(value?: string): string {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '—';
  return parsed.toLocaleString([], {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function getAppointmentStart(appointment: Appointment): string | undefined {
  return appointment.startTime ?? appointment.start;
}

function getSubmissionFormId(submission: IntakeFormSubmission): string {
  const withTemplate = submission as IntakeFormSubmission & {
    templateId?: string;
    templateName?: string;
  };
  return withTemplate.templateName ?? withTemplate.templateId ?? submission.formId;
}

export function ClientProfileDrawer({ client, onClose }: Props) {
  const { businessId, role, userId, providerId, userDisplayName } = useBusinessContext();
  const [activeTab, setActiveTab] = useState<Tab>('overview');
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [intakeSubmissions, setIntakeSubmissions] = useState<IntakeFormSubmission[]>([]);
  const [sessionNotes, setSessionNotes] = useState<SessionNote[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [files, setFiles] = useState<FileAttachment[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [refreshToken, setRefreshToken] = useState(0);

  const actor = useMemo<SessionNoteActor>(
    () => ({
      role,
      providerId,
      userId,
      userDisplayName,
    }),
    [providerId, role, userDisplayName, userId],
  );

  const canViewSessionNotes = canAccessSessionNotes(role, providerId);
  const canMutateFiles = role === 'owner' || role === 'admin' || role === 'staff';

  useEffect(() => {
    if (!client || !businessId) return;

    let cancelled = false;
    setLoading(true);
    setLoadError(null);

    const sessionNotesPromise = canViewSessionNotes
      ? listSessionNotes(businessId, client.id, actor)
      : Promise.resolve([]);

    Promise.all([
      listAppointments(businessId, { clientId: client.id }, userId),
      listIntakeSubmissions(businessId, client.id, userId),
      sessionNotesPromise,
      listPayments(businessId, { clientId: client.id }, userId),
      listFileAttachments(businessId, client.id, userId),
    ])
      .then(([appts, intakeSubs, notes, pymts, fileRows]) => {
        if (cancelled) return;
        setAppointments(appts);
        setIntakeSubmissions(intakeSubs);
        setSessionNotes(notes);
        setPayments(pymts);
        setFiles(fileRows);
      })
      .catch(() => {
        if (cancelled) return;
        setLoadError('Failed to load client profile data.');
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [actor, businessId, canViewSessionNotes, client, refreshToken, userId]);

  if (!client) return null;

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <div className="drawer" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <div>
            <h2>{client.name ?? 'Unnamed Client'}</h2>
            <p className="muted">
              {client.email} {client.phone && `• ${client.phone}`}
            </p>
          </div>
          <button className="button button--ghost" onClick={onClose} type="button">
            Close
          </button>
        </div>

        <div className="drawer-tabs">
          <button
            className={activeTab === 'overview' ? 'tab-active' : ''}
            onClick={() => setActiveTab('overview')}
            type="button"
          >
            Overview
          </button>
          <button
            className={activeTab === 'appointments' ? 'tab-active' : ''}
            onClick={() => setActiveTab('appointments')}
            type="button"
          >
            Appointments
          </button>
          <button
            className={activeTab === 'intake' ? 'tab-active' : ''}
            onClick={() => setActiveTab('intake')}
            type="button"
          >
            Intake Forms
          </button>
          {canViewSessionNotes && (
            <button
              className={activeTab === 'session-notes' ? 'tab-active' : ''}
              onClick={() => setActiveTab('session-notes')}
              type="button"
            >
              Session Notes
            </button>
          )}
          <button
            className={activeTab === 'payments' ? 'tab-active' : ''}
            onClick={() => setActiveTab('payments')}
            type="button"
          >
            Payments
          </button>
          <button
            className={activeTab === 'files' ? 'tab-active' : ''}
            onClick={() => setActiveTab('files')}
            type="button"
          >
            Files
          </button>
        </div>

        <div className="drawer-content">
          {loading && <p className="muted">Loading...</p>}
          {!loading && loadError && <p className="muted">{loadError}</p>}

          {!loading && !loadError && activeTab === 'overview' && <OverviewTab client={client} />}
          {!loading && !loadError && activeTab === 'appointments' && (
            <AppointmentsTab appointments={appointments} />
          )}
          {!loading && !loadError && activeTab === 'intake' && (
            <IntakeFormsTab submissions={intakeSubmissions} />
          )}
          {!loading && !loadError && activeTab === 'session-notes' && canViewSessionNotes && (
            <SessionNotesTab
              notes={sessionNotes}
              appointments={appointments}
              businessId={businessId}
              clientId={client.id}
              actor={actor}
              onMutated={() => setRefreshToken((token) => token + 1)}
            />
          )}
          {!loading && !loadError && activeTab === 'payments' && (
            <PaymentsHistoryTab payments={payments} />
          )}
          {!loading && !loadError && activeTab === 'files' && (
            <FilesTab
              files={files}
              clientId={client.id}
              businessId={businessId}
              userId={userId}
              canMutateFiles={canMutateFiles}
              onMutated={() => setRefreshToken((token) => token + 1)}
            />
          )}
        </div>
      </div>
    </div>
  );
}

function OverviewTab({ client }: { client: Client }) {
  return (
    <div className="tab-section">
      <h3>Client Information</h3>
      <div className="field-group">
        <div className="field">
          <label>Name</label>
          <p>{client.name ?? '—'}</p>
        </div>
        <div className="field">
          <label>Email</label>
          <p>{client.email || '—'}</p>
        </div>
        <div className="field">
          <label>Phone</label>
          <p>{client.phone || '—'}</p>
        </div>
      </div>
      <p className="muted">Lifecycle: {client.lifecycle ?? 'active'}</p>
    </div>
  );
}

function AppointmentsTab({ appointments }: { appointments: Appointment[] }) {
  if (appointments.length === 0) {
    return (
      <div className="empty-state">
        <p className="muted">No appointment history.</p>
      </div>
    );
  }

  return (
    <div className="tab-section">
      <h3>Appointment History</h3>
      <div className="list">
        {appointments.map((appointment) => {
          const start = getAppointmentStart(appointment);
          return (
            <div key={appointment.id} className="list-item">
              <div>
                <p className="list-item__title">{formatDateTime(start)}</p>
                <p className="muted">
                  Status: {appointment.status} {appointment.serviceId && `• Service: ${appointment.serviceId}`}
                </p>
              </div>
              <span className={`status status--${appointment.status}`}>{appointment.status}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function IntakeFormsTab({ submissions }: { submissions: IntakeFormSubmission[] }) {
  if (submissions.length === 0) {
    return (
      <div className="empty-state">
        <p className="muted">No intake forms submitted yet.</p>
      </div>
    );
  }

  return (
    <div className="tab-section">
      <h3>Intake Form Submissions</h3>
      <div className="list">
        {submissions.map((submission) => (
          <div key={submission.id} className="list-item">
            <div>
              <p className="list-item__title">Template: {getSubmissionFormId(submission)}</p>
              <p className="muted">
                {submission.status === 'draft' ? 'Draft' : 'Submitted'} •{' '}
                {formatDate(submission.submittedAt ?? submission.createdAt)}
              </p>
            </div>
            <button className="button button--ghost" type="button">
              View
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

function SessionNotesTab({
  notes,
  appointments,
  businessId,
  clientId,
  actor,
  onMutated,
}: {
  notes: SessionNote[];
  appointments: Appointment[];
  businessId: string;
  clientId: string;
  actor: SessionNoteActor;
  onMutated: () => void;
}) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [noteType, setNoteType] = useState<SessionNote['noteType']>('progressNote');
  const [visibility, setVisibility] = useState<SessionNote['visibility']>('providerOnly');
  const [appointmentId, setAppointmentId] = useState('');
  const [tagsInput, setTagsInput] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [revealingNoteId, setRevealingNoteId] = useState<string | null>(null);
  const [revealedContent, setRevealedContent] = useState<Record<string, string>>({});

  const canCreateNotes = Boolean(actor.userId && (actor.providerId || actor.role === 'owner' || actor.role === 'admin'));

  const appointmentOptions = appointments
    .filter((appointment) => Boolean(appointment.id))
    .sort((a, b) => {
      const aTime = new Date(getAppointmentStart(a) ?? '').getTime();
      const bTime = new Date(getAppointmentStart(b) ?? '').getTime();
      return bTime - aTime;
    });

  async function handleCreateNote() {
    if (!canCreateNotes || !content.trim()) return;

    setSaving(true);
    setError(null);
    setStatusMessage(null);
    try {
      const tags = tagsInput
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean);

      await createSessionNoteFromPlaintext(
        businessId,
        {
          clientId,
          appointmentId: appointmentId || undefined,
          noteType,
          visibility,
          title: title.trim() || undefined,
          tags,
          plaintextContent: content,
        },
        actor,
      );

      setTitle('');
      setContent('');
      setTagsInput('');
      setAppointmentId('');
      setNoteType('progressNote');
      setVisibility('providerOnly');
      setStatusMessage('Saved encrypted session note.');
      onMutated();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save session note.');
    } finally {
      setSaving(false);
    }
  }

  async function handleRevealNote(note: SessionNote) {
    if (revealedContent[note.id]) {
      setRevealedContent((current) => {
        const next = { ...current };
        delete next[note.id];
        return next;
      });
      return;
    }

    setRevealingNoteId(note.id);
    setError(null);
    try {
      const plaintext = await decryptSessionNoteContent(businessId, note.encryptedContent);
      setRevealedContent((current) => ({
        ...current,
        [note.id]: plaintext,
      }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to decrypt session note.');
    } finally {
      setRevealingNoteId(null);
    }
  }

  return (
    <div className="tab-section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3>Session Notes</h3>
      </div>
      <p className="muted">
        Notes are encrypted through the shared Scheduler backend. Content stays hidden until an authorized user
        explicitly reveals it.
      </p>

      {canCreateNotes ? (
        <div className="card" style={{ marginBottom: 16, padding: 16 }}>
          <div className="field-group">
            <label className="field">
              <span>Title</span>
              <input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Optional note title" />
            </label>
            <label className="field">
              <span>Note type</span>
              <select value={noteType} onChange={(event) => setNoteType(event.target.value as SessionNote['noteType'])}>
                <option value="progressNote">Progress Note</option>
                <option value="soap">SOAP</option>
                <option value="treatmentPlan">Treatment Plan</option>
                <option value="procedureLog">Procedure Log</option>
                <option value="adjustmentNote">Adjustment Note</option>
                <option value="intakeAssessment">Intake Assessment</option>
                <option value="dischargeNote">Discharge Note</option>
                <option value="psychNote">Psych Note</option>
                <option value="custom">Custom</option>
              </select>
            </label>
            <label className="field">
              <span>Visibility</span>
              <select value={visibility} onChange={(event) => setVisibility(event.target.value as SessionNote['visibility'])}>
                <option value="providerOnly">Provider Only</option>
                <option value="businessOnly">Business Only</option>
                <option value="shared">Shared</option>
              </select>
            </label>
            <label className="field">
              <span>Appointment</span>
              <select value={appointmentId} onChange={(event) => setAppointmentId(event.target.value)}>
                <option value="">General client note</option>
                {appointmentOptions.map((appointment) => (
                  <option key={appointment.id} value={appointment.id}>
                    {formatDateTime(getAppointmentStart(appointment))}
                  </option>
                ))}
              </select>
            </label>
            <label className="field">
              <span>Tags</span>
              <input
                value={tagsInput}
                onChange={(event) => setTagsInput(event.target.value)}
                placeholder="Comma-separated tags"
              />
            </label>
          </div>
          <label className="field">
            <span>Encrypted note content</span>
            <textarea
              className="textarea"
              rows={6}
              value={content}
              onChange={(event) => setContent(event.target.value)}
              placeholder="Enter note content. It will be encrypted before storage."
            />
          </label>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
            <p className="muted" style={{ margin: 0 }}>
              Authorized admins can initialize the encryption key on first write. Provider-scoped users can create
              notes once a business key already exists.
            </p>
            <button className="button button--primary" type="button" onClick={handleCreateNote} disabled={saving || !content.trim()}>
              {saving ? 'Saving...' : 'Save Encrypted Note'}
            </button>
          </div>
        </div>
      ) : (
        <p className="muted">This account can view encrypted notes but does not have enough context to create one.</p>
      )}

      {statusMessage && <p className="muted">{statusMessage}</p>}
      {error && <p className="muted">{error}</p>}

      {notes.length === 0 && (
        <div className="empty-state">
          <p className="muted">No session notes available.</p>
        </div>
      )}

      <div className="list">
        {notes.map((note) => (
          <div key={note.id} className="card" style={{ marginTop: 12 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
              <div>
                <p className="list-item__title">{note.title?.trim() || note.createdByName}</p>
                <p className="muted">
                  {note.noteType} • {formatDate(note.createdAt ?? note.date)}
                </p>
              </div>
              {note.tags && note.tags.length > 0 && (
                <div style={{ display: 'flex', gap: 6 }}>
                  {note.tags.map((tag) => (
                    <span key={tag} className="badge">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 8, gap: 12 }}>
              <p style={{ margin: 0, padding: 8, background: '#f6f7fb', borderRadius: 6, flex: 1 }}>
                {revealedContent[note.id] ?? 'Encrypted content is stored for this note.'}
              </p>
              <button
                className="button button--ghost"
                type="button"
                onClick={() => void handleRevealNote(note)}
                disabled={revealingNoteId === note.id}
              >
                {revealingNoteId === note.id ? 'Revealing...' : revealedContent[note.id] ? 'Hide' : 'Reveal'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PaymentsHistoryTab({ payments }: { payments: Payment[] }) {
  if (payments.length === 0) {
    return (
      <div className="empty-state">
        <p className="muted">No payment history.</p>
      </div>
    );
  }

  return (
    <div className="tab-section">
      <h3>Payment History</h3>
      <div className="list">
        {payments.map((payment) => (
          <div key={payment.id} className="list-item">
            <div>
              <p className="list-item__title">
                {(payment.amountCents / 100).toFixed(2)} {payment.currency.toUpperCase()}
              </p>
              <p className="muted">
                {payment.type} • {payment.status} • {formatDate(payment.createdAt)}
              </p>
            </div>
            <button className="button button--ghost" type="button" disabled={!payment.receiptUrl}>
              Receipt
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

function FilesTab({
  files,
  clientId,
  businessId,
  userId,
  canMutateFiles,
  onMutated,
}: {
  files: FileAttachment[];
  clientId: string;
  businessId: string;
  userId?: string;
  canMutateFiles: boolean;
  onMutated: () => void;
}) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleUpload(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file || !canMutateFiles) return;

    setUploading(true);
    setError(null);
    try {
      await uploadFile(businessId, clientId, file, userId ?? 'unknown', '', userId);
      onMutated();
    } catch {
      setError('Failed to upload file.');
    } finally {
      setUploading(false);
      event.target.value = '';
    }
  }

  async function handleDelete(fileId: string) {
    if (!canMutateFiles || !confirm('Delete this file?')) return;
    setError(null);
    try {
      await deleteFile(businessId, clientId, fileId, userId);
      onMutated();
    } catch {
      setError('Failed to delete file.');
    }
  }

  async function handleDownload(file: FileAttachment) {
    setError(null);
    try {
      await downloadFile(businessId, file, userId);
    } catch {
      setError('Failed to download file.');
    }
  }

  return (
    <div className="tab-section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3>Files</h3>
        {canMutateFiles ? (
          <label className="button button--primary">
            {uploading ? 'Uploading...' : '+ Upload File'}
            <input type="file" style={{ display: 'none' }} onChange={handleUpload} disabled={uploading} />
          </label>
        ) : (
          <p className="muted">Your role does not have file upload permission.</p>
        )}
      </div>

      {error && <p className="muted">{error}</p>}

      {files.length === 0 && (
        <div className="empty-state">
          <p className="muted">No files uploaded yet.</p>
        </div>
      )}

      <div className="list">
        {files.map((file) => (
          <div key={file.id} className="list-item">
            <div>
              <p className="list-item__title">{file.name ?? file.fileName ?? 'File'}</p>
              <p className="muted">
                {((file.sizeBytes ?? file.fileSize ?? 0) / 1024).toFixed(2)} KB • {formatDate(file.uploadedAt)}
              </p>
              {file.notes && <p className="muted">{file.notes}</p>}
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="button button--ghost" type="button" onClick={() => handleDownload(file)}>
                Download
              </button>
              {canMutateFiles && (
                <button className="button button--ghost" onClick={() => handleDelete(file.id)} type="button">
                  Delete
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
