import { useEffect, useState } from 'react';

import {
  addResourceMaintenanceLog,
  listResourceMaintenanceLogs,
} from '../../data/locations';
import { useAuth } from '../../context/AuthContext';
import type {
  Resource,
  ResourceMaintenanceLog,
  ResourceStatus,
} from '../../types/models';

type ResourceMaintenanceDrawerProps = {
  businessId?: string;
  resource: Resource;
  canManage: boolean;
  onClose: () => void;
};

export function ResourceMaintenanceDrawer({
  businessId,
  resource,
  canManage,
  onClose,
}: ResourceMaintenanceDrawerProps) {
  const { state } = useAuth();
  const [logs, setLogs] = useState<ResourceMaintenanceLog[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [note, setNote] = useState('');
  const [status, setStatus] = useState<ResourceStatus>(resource.status);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!businessId) return;
    setLoading(true);
    setError(null);
    void listResourceMaintenanceLogs(businessId, resource.id)
      .then((rows) => setLogs(rows))
      .catch((err) => {
        console.error('Failed to fetch maintenance logs', err);
        setError('Failed to load maintenance log.');
      })
      .finally(() => setLoading(false));
  }, [businessId, resource.id]);

  const handleAddLog = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!businessId || !note.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const createdBy =
        state.status === 'signed_in'
          ? state.user.displayName ?? state.user.email ?? 'unknown'
          : 'unknown';
      await addResourceMaintenanceLog(businessId, resource.id, {
        note: note.trim(),
        status,
        createdBy,
      });
      const rows = await listResourceMaintenanceLogs(businessId, resource.id);
      setLogs(rows);
      setNote('');
    } catch (err) {
      console.error('Failed to append maintenance log', err);
      setError('Failed to save maintenance note.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="drawer-overlay" onClick={onClose}>
      <div className="drawer" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <div>
            <p className="eyebrow">Maintenance log</p>
            <h2>{resource.name}</h2>
            <p className="muted">Track upkeep notes and status changes for this resource.</p>
          </div>
          <button className="button button--ghost" type="button" onClick={onClose}>
            Close
          </button>
        </div>

        <div className="drawer-content">
          {loading ? (
            <p className="muted">Loading history…</p>
          ) : logs.length === 0 ? (
            <p className="muted">No maintenance entries yet.</p>
          ) : (
            <ul className="list">
              {logs
                .slice()
                .sort(
                  (a, b) =>
                    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
                )
                .map((log) => (
                  <li key={log.id}>
                    <div className="meta-row">
                      <span className="badge badge--neutral">
                        {new Date(log.createdAt).toLocaleString()}
                      </span>
                      <span className="badge badge--ghost">{log.status}</span>
                    </div>
                    <p className="muted">{log.note}</p>
                    <p className="muted">By {log.createdBy}</p>
                  </li>
                ))}
            </ul>
          )}

          {error && (
            <div className="panel panel--alert">
              <p className="muted">{error}</p>
            </div>
          )}

          {canManage && businessId ? (
            <form className="stack" onSubmit={handleAddLog}>
              <label>
                Status
                <select
                  value={status}
                  onChange={(event) =>
                    setStatus(event.target.value as ResourceStatus)
                  }
                >
                  <option value="available">Available</option>
                  <option value="in_use">In use</option>
                  <option value="maintenance">Maintenance</option>
                </select>
              </label>
              <label>
                Note
                <textarea
                  rows={3}
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                  placeholder="Describe maintenance work, who to notify, etc."
                />
              </label>
              <div className="dialog-actions">
                <button
                  className="button button--primary"
                  type="submit"
                  disabled={saving || !note.trim()}
                >
                  {saving ? 'Saving…' : 'Add entry'}
                </button>
              </div>
            </form>
          ) : (
            <p className="muted">Maintenance editing is only available to admins.</p>
          )}
        </div>
      </div>
    </div>
  );
}


