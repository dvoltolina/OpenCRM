/**
 * AuditLogViewer Component
 * Admin UI component for viewing and filtering audit logs
 *
 * Agent CRM-28 Implementation
 * HIPAA Compliance: Provides comprehensive audit log UI for compliance
 */

import { useState } from 'react';
import { Button } from '../ui';
import { useAuditLog } from '../../hooks/useAuditLog';
import type {
  AuditEntry,
  AuditAction,
  AuditEntityType,
  AuditLogFilters,
  AuditLogCSVRow,
} from '../../types/audit';
import './audit-log-viewer.css';

export interface AuditLogViewerProps {
  initialFilters?: AuditLogFilters;
  showFilters?: boolean;
  maxHeight?: string;
}

const ACTION_OPTIONS: AuditAction[] = [
  'create',
  'update',
  'delete',
  'read',
  'convert',
  'merge',
  'export',
  'import',
  'integration',
  'automation',
  'webhook',
  'login_failure',
  'role_changed',
  'staff_deactivated',
  'bulk_delete',
];

const ENTITY_OPTIONS: AuditEntityType[] = [
  'lead',
  'deal',
  'contact',
  'company',
  'activity',
  'pipeline',
  'stage',
  'report',
  'reportView',
  'importJob',
  'exportJob',
  'integration',
  'webhook',
  'automationRule',
  'automationRun',
  'calendar_connection',
  'calendar_mapping',
  'calendar_event',
  'reportExport',
  'reportingAggregate',
  'webhook_endpoint',
  'webhook_delivery',
  'route',
];

function formatTimestamp(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

function formatTokenLabel(value: string): string {
  return value
    .replace(/_/g, ' ')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function getEntityTypeLabel(entityType: AuditEntityType): string {
  const labels: Record<AuditEntityType, string> = {
    lead: 'Lead',
    deal: 'Deal',
    contact: 'Contact',
    company: 'Company',
    activity: 'Activity',
    pipeline: 'Pipeline',
    stage: 'Stage',
    report: 'Report',
    reportView: 'Report View',
    importJob: 'Import Job',
    exportJob: 'Export Job',
    integration: 'Integration',
    webhook: 'Webhook',
    automationRule: 'Automation Rule',
    automationRun: 'Automation Run',
    calendar_connection: 'Calendar Connection',
    calendar_mapping: 'Calendar Mapping',
    calendar_event: 'Calendar Event',
    reportExport: 'Report Export',
    reportingAggregate: 'Reporting Aggregate',
    webhook_endpoint: 'Webhook Endpoint',
    webhook_delivery: 'Webhook Delivery',
    route: 'Route',
  };
  return labels[entityType] || entityType;
}

function getActionTone(action: AuditAction): 'neutral' | 'info' | 'success' | 'warning' | 'danger' {
  switch (action) {
    case 'create':
    case 'import':
      return 'success';
    case 'update':
    case 'read':
    case 'integration':
    case 'automation':
    case 'webhook':
      return 'info';
    case 'convert':
    case 'merge':
    case 'export':
    case 'role_changed':
      return 'warning';
    case 'delete':
    case 'login_failure':
    case 'staff_deactivated':
    case 'bulk_delete':
    case 'webhook_endpoint_deleted':
      return 'danger';
    default:
      return 'neutral';
  }
}

function formatChangeValue(value: unknown): string {
  if (value === null) return 'null';
  if (value === undefined) return 'undefined';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);

  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

function formatChanges(changes?: Record<string, { old: unknown; new: unknown }>): string {
  if (!changes || Object.keys(changes).length === 0) {
    return 'No changes';
  }

  return Object.entries(changes)
    .map(([field, change]) => {
      const oldValue = formatChangeValue(change.old);
      const newValue = formatChangeValue(change.new);
      return `${formatTokenLabel(field)}: ${oldValue} -> ${newValue}`;
    })
    .join(', ');
}

function exportToCSV(entries: AuditEntry[]): void {
  const rows: AuditLogCSVRow[] = entries.map((entry) => ({
    timestamp: formatTimestamp(entry.timestamp),
    user: entry.userName,
    action: formatTokenLabel(entry.action),
    entityType: getEntityTypeLabel(entry.entityType),
    entityId: entry.entityId,
    entityName: entry.entityName || '',
    changes: formatChanges(entry.changes),
  }));

  const headers = ['Timestamp', 'User', 'Action', 'Entity Type', 'Entity ID', 'Entity Name', 'Changes'];
  const csvContent = [
    headers.join(','),
    ...rows.map((row) =>
      [
        row.timestamp,
        row.user,
        row.action,
        row.entityType,
        row.entityId,
        row.entityName,
        `"${row.changes.replace(/"/g, '""')}"`,
      ].join(',')
    ),
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `audit_log_${Date.now()}.csv`);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

function AuditEntryRow({ entry }: { entry: AuditEntry }) {
  const [isExpanded, setIsExpanded] = useState(false);
  const changeEntries = Object.entries(entry.changes ?? {});
  const hasChanges = changeEntries.length > 0;

  return (
    <article className={`audit-entry ${isExpanded ? 'is-expanded' : ''}`}>
      <button
        type="button"
        className={`audit-entry__summary ${hasChanges ? '' : 'audit-entry__summary--static'}`}
        onClick={() => {
          if (hasChanges) setIsExpanded((prev) => !prev);
        }}
        aria-expanded={hasChanges ? isExpanded : undefined}
      >
        <div className="audit-entry__summary-main">
          <div className="audit-entry__primary">
            <span className="audit-entry__time">{formatTimestamp(entry.timestamp)}</span>
            <span className="audit-entry__actor">{entry.userName || 'System'}</span>
          </div>
          <div className="audit-entry__secondary">
            <span className={`audit-entry__pill audit-entry__pill--${getActionTone(entry.action)}`}>
              {formatTokenLabel(entry.action)}
            </span>
            <span className="audit-entry__entity">{getEntityTypeLabel(entry.entityType)}</span>
            <span className="audit-entry__target">{entry.entityName || entry.entityId}</span>
          </div>
        </div>
        {hasChanges ? (
          <span className={`audit-entry__chevron ${isExpanded ? 'is-expanded' : ''}`} aria-hidden="true">
            ▾
          </span>
        ) : (
          <span className="audit-entry__meta">No field diff</span>
        )}
      </button>

      {isExpanded && hasChanges ? (
        <div className="audit-entry__changes">
          <h4>Changes</h4>
          <div className="audit-entry__change-list">
            {changeEntries.map(([field, change]) => (
              <div key={field} className="audit-entry__change">
                <div className="audit-entry__change-field">{formatTokenLabel(field)}</div>
                <div className="audit-entry__change-values">
                  <div className="audit-entry__change-value audit-entry__change-value--old">
                    <span>Old</span>
                    <code>{formatChangeValue(change.old)}</code>
                  </div>
                  <div className="audit-entry__change-value audit-entry__change-value--new">
                    <span>New</span>
                    <code>{formatChangeValue(change.new)}</code>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : null}
    </article>
  );
}

export function AuditLogViewer({
  initialFilters = {},
  showFilters = true,
  maxHeight = '600px',
}: AuditLogViewerProps) {
  const [filters, setFilters] = useState<AuditLogFilters>(initialFilters);
  const { entries, isLoading, error, hasMore, loadMore, totalCount, refresh } = useAuditLog(filters);

  const [filterUserId, setFilterUserId] = useState(filters.userId || '');
  const [filterEntityType, setFilterEntityType] = useState<AuditEntityType | ''>(filters.entityType || '');
  const [filterAction, setFilterAction] = useState<AuditAction | ''>(filters.action || '');
  const [filterEntityId, setFilterEntityId] = useState(filters.entityId || '');
  const [filterStartDate, setFilterStartDate] = useState(
    filters.startDate ? filters.startDate.toISOString().split('T')[0] : ''
  );
  const [filterEndDate, setFilterEndDate] = useState(
    filters.endDate ? filters.endDate.toISOString().split('T')[0] : ''
  );

  const hasActiveFilters = Boolean(
    filterUserId || filterEntityType || filterAction || filterEntityId || filterStartDate || filterEndDate
  );

  const handleApplyFilters = () => {
    setFilters({
      userId: filterUserId || undefined,
      entityType: filterEntityType || undefined,
      action: filterAction || undefined,
      entityId: filterEntityId || undefined,
      startDate: filterStartDate ? new Date(filterStartDate) : undefined,
      endDate: filterEndDate ? new Date(filterEndDate) : undefined,
      limit: 50,
    });
  };

  const handleClearFilters = () => {
    setFilterUserId('');
    setFilterEntityType('');
    setFilterAction('');
    setFilterEntityId('');
    setFilterStartDate('');
    setFilterEndDate('');
    setFilters({});
  };

  return (
    <section className="audit-log-viewer">
      <div className="audit-log-viewer__header">
        <div className="audit-log-viewer__copy">
          <p className="audit-log-viewer__eyebrow">Compliance</p>
          <h2>Audit Log</h2>
          <p>Inspect workspace changes, exports, access changes, and operational history.</p>
        </div>
        <div className="audit-log-viewer__header-actions">
          <Button variant="secondary" size="sm" onClick={refresh}>
            Refresh
          </Button>
          <Button variant="primary" size="sm" onClick={() => exportToCSV(entries)} disabled={entries.length === 0}>
            Export CSV
          </Button>
        </div>
      </div>

      {showFilters ? (
        <div className="audit-log-viewer__filters">
          <div className="audit-log-viewer__filter-grid">
            <label className="audit-log-viewer__field">
              <span>User</span>
              <input
                type="text"
                value={filterUserId}
                onChange={(e) => setFilterUserId(e.target.value)}
                placeholder="Filter by user ID"
              />
            </label>

            <label className="audit-log-viewer__field">
              <span>Entity Type</span>
              <select
                value={filterEntityType}
                onChange={(e) => setFilterEntityType(e.target.value as AuditEntityType | '')}
              >
                <option value="">All entity types</option>
                {ENTITY_OPTIONS.map((option) => (
                  <option key={option} value={option}>
                    {getEntityTypeLabel(option)}
                  </option>
                ))}
              </select>
            </label>

            <label className="audit-log-viewer__field">
              <span>Action</span>
              <select
                value={filterAction}
                onChange={(e) => setFilterAction(e.target.value as AuditAction | '')}
              >
                <option value="">All actions</option>
                {ACTION_OPTIONS.map((option) => (
                  <option key={option} value={option}>
                    {formatTokenLabel(option)}
                  </option>
                ))}
              </select>
            </label>

            <label className="audit-log-viewer__field">
              <span>Entity ID</span>
              <input
                type="text"
                value={filterEntityId}
                onChange={(e) => setFilterEntityId(e.target.value)}
                placeholder="Filter by entity ID"
              />
            </label>

            <label className="audit-log-viewer__field">
              <span>Start Date</span>
              <input
                type="date"
                value={filterStartDate}
                onChange={(e) => setFilterStartDate(e.target.value)}
              />
            </label>

            <label className="audit-log-viewer__field">
              <span>End Date</span>
              <input
                type="date"
                value={filterEndDate}
                onChange={(e) => setFilterEndDate(e.target.value)}
              />
            </label>
          </div>

          <div className="audit-log-viewer__filter-footer">
            <p className="audit-log-viewer__filter-summary">
              {hasActiveFilters
                ? 'Filters are set. Apply them to narrow the audit trail.'
                : 'Showing the latest workspace activity across the CRM.'}
            </p>
            <div className="audit-log-viewer__filter-actions">
              <Button variant="secondary" size="sm" onClick={handleClearFilters}>
                Clear
              </Button>
              <Button variant="primary" size="sm" onClick={handleApplyFilters}>
                Apply Filters
              </Button>
            </div>
          </div>
        </div>
      ) : null}

      <div className="audit-log-viewer__list" style={{ maxHeight }}>
        {isLoading && entries.length === 0 ? (
          <div className="audit-log-viewer__state">Loading audit logs...</div>
        ) : error ? (
          <div className="audit-log-viewer__state audit-log-viewer__state--error">
            Error: {error.message}
          </div>
        ) : entries.length === 0 ? (
          <div className="audit-log-viewer__state">No audit log entries found for the current filters.</div>
        ) : (
          <>
            <div className="audit-log-viewer__entries">
              {entries.map((entry) => (
                <AuditEntryRow key={entry.id} entry={entry} />
              ))}
            </div>

            {hasMore ? (
              <div className="audit-log-viewer__load-more">
                <Button variant="secondary" size="sm" onClick={loadMore} disabled={isLoading}>
                  {isLoading ? 'Loading...' : 'Load More'}
                </Button>
              </div>
            ) : null}
          </>
        )}
      </div>

      <div className="audit-log-viewer__footer">
        <span>
          Showing {totalCount} {totalCount === 1 ? 'entry' : 'entries'}
        </span>
        {hasMore ? <span>More results are available.</span> : null}
      </div>
    </section>
  );
}

export default AuditLogViewer;
